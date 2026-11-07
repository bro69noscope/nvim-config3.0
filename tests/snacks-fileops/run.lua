-- Headless test of snacks move/rename/copy behaviour with our patches
-- (modules.snacks.rename-debug, move-debug, safe-copy).
--
-- Run from the config root:
--   nvim --headless -c "luafile tests/snacks-fileops/run.lua" -c "qa!"
--
-- A throwaway sandbox is created in the OS temp dir and removed at the end.
-- Every attempt is also written to the Logger file (logs/custom.log).

local results = {}
local function out(s)
  io.stdout:write(s .. "\n")
end

local function check(name, cond, detail)
  results[#results + 1] = { name = name, ok = cond and true or false }
  out(("%s  %s%s"):format(cond and "PASS" or "FAIL", name, detail and ("  -> " .. detail) or ""))
end

local function norm(p)
  return vim.fs.normalize(p)
end

local root = norm(vim.fn.tempname() .. "-snacks-fileops")
local function p(rel)
  return root .. "/" .. rel
end
local function write(rel, text)
  vim.fn.mkdir(vim.fs.dirname(p(rel)), "p")
  local f = assert(io.open(p(rel), "w"))
  f:write(text or rel)
  f:close()
end
local function read(rel)
  local f = io.open(p(rel), "r")
  if not f then
    return nil
  end
  local s = f:read("*a")
  f:close()
  return s
end
local function exists(rel)
  return vim.uv.fs_stat(p(rel)) ~= nil
end

local function build_fixture()
  write("src/a.txt", "A")
  write("src/b.txt", "B")
  write("src/c.lua", "C")
  write("src/sub/deep/d.txt", "D")
  write("src/sub/e.txt", "E")
  write("dst/existing.txt", "EXISTING")
  write("dst/a.txt", "DST-A")
  write("spaced dir/with space.txt", "SPACE")
  vim.fn.mkdir(p("empty"), "p")
end

---@param from string
---@param to string
---@return boolean? ok  result reported through on_rename (nil if callback never fired)
local function move(from, to)
  local res
  local ok, err = pcall(Snacks.rename.rename_file, {
    from = p(from),
    to = p(to),
    on_rename = function(_, _, r)
      res = r
    end,
  })
  if not ok then
    out("      error: " .. tostring(err))
    return false
  end
  vim.wait(500, function()
    return res ~= nil
  end, 10)
  return res
end

local function copy(paths, dir)
  local abs = vim.tbl_map(p, paths)
  return pcall(Snacks.picker.util.copy, abs, p(dir))
end

local function restore_notify()
  -- keep notifier noise out of the headless output
  Snacks.notify.error = function(msg)
    out("      notify.error: " .. tostring(msg):gsub("\n", " | "))
  end
end

local function run()
  restore_notify()
  Logger.info("===== snacks-fileops test start root=" .. root, "test")
  build_fixture()

  out("--- MOVE ---")
  check(
    "move file into existing dir",
    move("src/a.txt", "dst/moved-a.txt") and exists("dst/moved-a.txt") and not exists("src/a.txt")
  )
  check(
    "move file into non-existent nested dir",
    move("src/b.txt", "new/nested/dir/b.txt") and read("new/nested/dir/b.txt") == "B"
  )
  check(
    "move directory (with children)",
    move("src/sub", "dst/sub") and read("dst/sub/deep/d.txt") == "D" and not exists("src/sub")
  )
  check(
    "move onto existing file overwrites",
    move("src/c.lua", "dst/existing.txt") and read("dst/existing.txt") == "C",
    "content=" .. tostring(read("dst/existing.txt"))
  )
  check(
    "move file with spaces in path",
    move("spaced dir/with space.txt", "dst/with space.txt")
      and read("dst/with space.txt") == "SPACE"
  )
  check(
    "move empty directory",
    move("empty", "dst/empty") and exists("dst/empty") and not exists("empty")
  )
  check(
    "move missing source fails cleanly",
    move("nope/missing.txt", "dst/missing.txt") == false and not exists("dst/missing.txt")
  )
  check(
    "move dir into itself fails cleanly",
    move("dst", "dst/inner/dst") == false and exists("dst/existing.txt")
  )

  -- open buffer should follow the move
  write("src/open.txt", "OPEN")
  vim.cmd("edit " .. vim.fn.fnameescape(p("src/open.txt")))
  local old_buf = vim.api.nvim_get_current_buf()
  local moved = move("src/open.txt", "dst/open-moved.txt")
  local cur = norm(vim.api.nvim_buf_get_name(0))
  check(
    "open buffer follows move",
    moved and cur == p("dst/open-moved.txt") and not vim.api.nvim_buf_is_valid(old_buf),
    "buf=" .. cur
  )

  out("--- COPY ---")
  write("src/c1.txt", "C1")
  copy({ "src/c1.txt" }, "dst")
  check("copy file", read("dst/c1.txt") == "C1" and exists("src/c1.txt"))
  copy({ "src/c1.txt" }, "dst")
  check(
    "copy again -> safe-copy suffix _1",
    read("dst/c1_1.txt") == "C1",
    "has c1_1=" .. tostring(exists("dst/c1_1.txt"))
  )
  copy({ "src/c1.txt" }, "dst")
  check("copy third time -> suffix _2", read("dst/c1_2.txt") == "C1")
  write("src/noext", "NOEXT")
  copy({ "src/noext" }, "dst")
  copy({ "src/noext" }, "dst")
  check("copy file w/o extension -> noext_1", read("dst/noext_1") == "NOEXT")
  write("srcdir/x/y/z.txt", "Z")
  write("srcdir/top.txt", "TOP")
  copy({ "srcdir" }, "dst")
  check(
    "copy directory recursively",
    read("dst/srcdir/x/y/z.txt") == "Z" and read("dst/srcdir/top.txt") == "TOP"
  )
  copy({ "srcdir" }, "dst")
  check(
    "copy directory again -> srcdir_1",
    read("dst/srcdir_1/x/y/z.txt") == "Z",
    "has srcdir_1=" .. tostring(exists("dst/srcdir_1"))
  )
  copy({ "src/c1.txt", "srcdir/top.txt" }, "new")
  check("copy multiple files at once", read("new/c1.txt") == "C1" and read("new/top.txt") == "TOP")
  copy({ "does/not/exist.txt" }, "dst")
  check("copy missing source doesn't create target", not exists("dst/exist.txt"))

  out("--- EXPLORER_MOVE ACTION (move-debug wrapper) ---")
  local actions = require("snacks.explorer.actions").actions
  local wrapped = debug.getinfo(actions.explorer_move, "S").source:find("move%-debug") ~= nil
  check(
    "explorer_move is wrapped by move-debug",
    wrapped,
    debug.getinfo(actions.explorer_move, "S").source
  )

  -- fake picker: only what the wrapper and the log need; stub the confirm so the original runs
  write("src/m1.txt", "M1")
  local fake = {
    selected = function()
      return { { file = p("src/m1.txt") } }
    end,
    dir = function()
      return p("dst")
    end,
    current = function()
      return { file = p("src/m1.txt") }
    end,
    list = { set_selected = function() end },
  }
  local orig_confirm = Snacks.picker.util.confirm
  Snacks.picker.util.confirm = function(_, fn)
    fn()
  end
  local ok, err = pcall(actions.explorer_move, fake)
  Snacks.picker.util.confirm = orig_confirm
  -- Tree/M.update may choke on the fake picker; only the file op matters here
  check(
    "explorer_move moved the file (fake picker)",
    exists("dst/m1.txt") and not exists("src/m1.txt"),
    ok and "no error" or ("post-move error ignored: " .. tostring(err))
  )

  Logger.info("===== snacks-fileops test end", "test")
end

local ok, err = pcall(run)
if not ok then
  out("HARNESS ERROR: " .. tostring(err))
end

local failed = 0
for _, r in ipairs(results) do
  if not r.ok then
    failed = failed + 1
  end
end
out(("\n%d checks, %d failed"):format(#results, failed))
out("sandbox: " .. root)
vim.fn.delete(root, "rf")
out("log: " .. Logger.get_log_file())
