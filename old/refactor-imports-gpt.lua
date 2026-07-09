local M = {}

local function normalize_separators(path)
  return path:gsub("\\", "/")
end

local function normalize_path(relative_path, is_directory)
  local normalized = normalize_separators(relative_path)

  if is_directory then
    return normalized:gsub("/", ".")
  else
    local without_ext = normalized:gsub("%.py$", "")
    if without_ext:match("/__init__$") then
      without_ext = without_ext:gsub("/__init__$", "")
    end
    return without_ext:gsub("/", ".")
  end
end

local function generate_absolute_template(relative_path, is_directory)
  local dotted_path = normalize_path(relative_path, is_directory)
  local parent_path = dotted_path:match("(.+)%.[^%.]+$") or ""
  local replacement_path = parent_path .. ".GRUGRENAME"

  if is_directory then
    local package_template = require("lang.python.astgrep-rules.templates.package")
    return string.format(
      package_template,
      -- id: package
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: package-as
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: from-package
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: from-package-as
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: submodules
      dotted_path,
      replacement_path,
      -- id: submodules-as
      dotted_path,
      replacement_path,
      -- id: from-submodules
      dotted_path,
      replacement_path,
      -- id: from-submodules-as
      dotted_path,
      replacement_path
    )
  else
    local module_template = require("lang.python.astgrep-rules.templates.module")
    local module_name = dotted_path:match("%.([^%.]+)$") or dotted_path
    return string.format(
      module_template,
      -- id: module
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: module-as
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: from-module
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: from-module-as
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: from-parent
      parent_path,
      module_name,
      parent_path,
      -- id: from-parent-as
      parent_path,
      module_name,
      parent_path,
      -- id: parent-as-()
      parent_path,
      module_name,
      parent_path,
      -- id: parent-a,b,c
      parent_path,
      module_name,
      parent_path
    )
  end
end

local function loud(msg)
  vim.api.nvim_echo({ { "[ELECT] " .. msg, "WarningMsg" } }, true, {})
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function split_yaml_docs(yaml)
  yaml = yaml or ""
  local docs, cur = {}, {}

  local function push()
    local txt = trim(table.concat(cur, "\n"))
    if txt ~= "" then
      local id = txt:match("\n?id:%s*([%w%-%_]+)")
      table.insert(docs, { id = id or "unknown", yaml = txt })
    end
    cur = {}
  end

  for line in (yaml .. "\n"):gmatch("([^\n]*)\n") do
    if trim(line) == "---" then
      push()
    else
      table.insert(cur, line)
    end
  end
  push()

  return docs
end

local function concat_yaml_docs(docs)
  local parts = {}
  for _, d in ipairs(docs or {}) do
    table.insert(parts, trim(d.yaml))
  end
  return table.concat(parts, "\n---\n")
end

local function wait_for_search_terminal(inst, cb)
  local function step()
    if not inst or not inst:is_valid() then
      cb(false, { matches = 0, files = 0 }, "invalid")
      return
    end

    local info = inst:get_status_info() or {}
    local status = info.status
    local stats = info.stats or { matches = 0, files = 0 }

    if status == "progress" then
      vim.defer_fn(step, 20)
      return
    end

    if status == "success" then
      cb(true, stats, "success")
      return
    end

    if status == "error" then
      cb(false, stats, "error")
      return
    end

    -- Unknown state: keep waiting a little, but don't spin forever
    vim.defer_fn(step, 20)
  end

  step()
end

local function get_instance_by_name_safe(grug_far, name)
  local ok, inst = pcall(grug_far.get_instance, name)
  if not ok then
    return nil
  end
  return inst
end

--- Elect relevant rules (absolute imports only) by running docs one-by-one,
--- then open a "real" instance using only winners.
function M.refactor_python_imports_absolute_elect(relative_path, is_directory, opts)
  opts = opts or {}
  local grug_far = require("grug-far")

  local absolute_template = generate_absolute_template(relative_path, is_directory)
  local docs = split_yaml_docs(absolute_template)

  if #docs == 0 then
    vim.notify("No rules generated", vim.log.levels.WARN)
    return
  end

  -- Give this trial instance a unique name so we can always fetch it reliably
  local trial_name = ("py-imports-elect:%d"):format(vim.loop.hrtime())

  grug_far.open({
    instanceName = trial_name,
    engine = "astgrep-rules",
    prefills = {
      rules = docs[1].yaml,
      replacement = "",
    },
  })
  loud("opened trial " .. trial_name)

  -- Wait until the instance exists (registered) before touching it
  local function wait_for_instance(cb)
    local function step()
      loud("polling for instance...")
      local inst = get_instance_by_name_safe(grug_far, trial_name)
      loud("inst? " .. tostring(inst ~= nil))

      if inst and inst:is_valid() then
        cb(inst)
        return
      end
      vim.defer_fn(step, 25)
    end
    step()
  end

  wait_for_instance(function(inst)
    local winners = {}
    local i = 1
    local finished = false

    local function run_next()
      if finished then
        return
      end
      loud("run_next i=" .. i)

      if not inst:is_valid() then
        vim.notify("grug-far instance became invalid during election", vim.log.levels.WARN)
        return
      end

      if i > #docs then
        finished = true
        inst:close()

        if #winners == 0 then
          if opts.notify ~= false then
            vim.notify("No relevant rules matched", vim.log.levels.INFO)
          end
          return
        end

        local final_rules = concat_yaml_docs(winners)

        grug_far.open({
          engine = "astgrep-rules",
          prefills = {
            rules = final_rules,
            replacement = "",
          },
        })
        loud("Opened final instance with rules: " .. (winners[1] and winners[1].id or "none"))

        if opts.notify ~= false then
          vim.notify(("Elected %d/%d rules"):format(#winners, #docs), vim.log.levels.INFO)
        end
        return
      end

      local doc = docs[i]

      inst:update_input_values({ rules = doc.yaml }, false)
      vim.defer_fn(function()
        inst:search()
        loud("calling search for rule:" .. (doc.id or "unknown"))
        wait_for_search_terminal(inst, function(ok, stats, terminal_status)
          loud("search complete for yaml:\n" .. (doc.yaml or "unknown"))
          loud(
            string.format(
              "rule=%s status=%s stats=%s",
              doc.id or "unknown",
              terminal_status,
              vim.inspect(stats)
            )
          )
          if ok and (stats.matches or 0) > 0 then
            table.insert(winners, doc)
            loud("rule " .. (doc.id or "unknown") .. " is a winner")
          end
          i = i + 1
          run_next()
        end)
      end, 0)
    end

    -- Now that we have a real inst, wait until UI is ready before kicking off
    inst:when_ready(run_next)
  end)
end

return M
