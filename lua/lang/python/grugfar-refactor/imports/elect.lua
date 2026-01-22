local log = require("lang.python.grugfar-refactor.imports.log")
local yaml_docs = require("lang.python.grugfar-refactor.imports.yaml_docs")
local grug_inst = require("lang.python.grugfar-refactor.imports.grug_instance")

local M = {}

local function open_final_from_winners(winners, opts)
  opts = opts or {}
  local grug_far = require("grug-far")

  -- Don't open window if no matches
  if #winners == 0 then
    if opts.notify ~= false then
      vim.notify(string.format("No %s import rules matched", opts.type or ""), vim.log.levels.INFO)
    end
    if opts.on_complete then
      opts.on_complete()
    end
    return
  end

  local final_rules = yaml_docs.concat_yaml_docs(winners)

  grug_far.open({
    engine = "astgrep-rules",
    prefills = {
      rules = final_rules,
      replacement = "",
      paths = opts.paths,
    },
  })

  if opts.notify ~= false then
    local scope_msg = opts.paths and (" in " .. opts.paths) or ""
    vim.notify(string.format("Elected %d %s import rules%s", #winners, opts.type or "", scope_msg), vim.log.levels.INFO)
  end

  if opts.on_complete then
    opts.on_complete()
  end
end

--- Elect rules that have matches
--- @param docs table Array of {id=..., yaml=...}
--- @param opts table {type="absolute"|"relative", paths=..., notify=...}
function M.elect_rules(docs, opts)
  local grug_far = require("grug-far")
  opts = opts or {}

  if #docs == 0 then
    vim.notify(string.format("No %s import rules to elect from", opts.type or ""), vim.log.levels.WARN)
    return
  end

  local trial_name = "elect" .. (":%d"):format(vim.loop.hrtime())

  grug_far.open({
    instanceName = trial_name,
    engine = "astgrep-rules",
    prefills = {
      rules = docs[1].yaml,
      replacement = "",
      paths = opts.paths,
    },
  })
  log.info("opened trial: " .. trial_name, "refactor.elect")

  grug_inst.wait_for_instance(grug_far, trial_name, function(inst)
    local winners, i = {}, 1

    local function run_next()
      log.debug("run_next i=" .. i, "refactor.elect")
      if not inst:is_valid() then
        open_final_from_winners(winners, opts)
        return
      end

      if i > #docs then
        inst:close()
        open_final_from_winners(winners, opts)
        return
      end

      local doc = docs[i]
      inst:update_input_values({ rules = doc.yaml }, false)

      vim.defer_fn(function()
        inst:search()
        log.debug("calling search for rule: " .. (doc.id or "unknown"), "refactor.elect")
        log.debug("yaml:\n" .. (doc.yaml or "unknown"), "refactor.elect")
        grug_inst.wait_for_search_terminal(inst, function(ok, stats, terminal_status)
          log.debug(
            string.format(
              "rule=%s status=%s matches=%s files=%s",
              doc.id or "unknown",
              terminal_status or "unknown",
              tostring((stats.matches or 0)),
              tostring((stats.files or 0))
            ),
            "refactor.elect"
          )
          if ok and (stats.matches or 0) > 0 then
            table.insert(winners, doc)
            log.info("rule " .. (doc.id or "unknown") .. " is a winner", "refactor.elect")
          end
          i = i + 1
          run_next()
        end)
      end, 0)
    end

    inst:when_ready(run_next)
  end)

  return trial_name
end

return M
