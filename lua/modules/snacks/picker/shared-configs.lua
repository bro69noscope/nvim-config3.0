local M = {}

---@param source string explicit source name, e.g. "grep" or "grep_word"
---@param deps table forwarded modules
M.make_grep_source = function(source, deps)
  return {
    finder = deps.case_aware_grep.wrap(require("modules.snacks.picker.finders.egrepify").egrepify),
    layout = "grep_vertical",

    -- AND search rewrites each space into the regex `.*` (see egrepify.lua). With
    -- `regex = false` rg runs with --fixed-strings, so `.*` is matched literally and
    -- multi-word searches find nothing. grep_word defaults AND off either way, so a
    -- selected phrase is matched as-is (also keeps regex = true callers exact, e.g.
    -- "Grep bounded word" which wraps the word in \b).
    and_search = source ~= "grep_word",
    win = {
      input = {
        keys = deps.setup_picker_keys.setup_grep_input_keys(nil, nil, source),
      },
    },
    actions = {
      toggle_and_search = deps.toggle_and_search,
      toggle_smartcase = deps.toggle_smartcase,
      grep_globs_input = deps.input_grep_globs.make_action(nil, nil, source),
    },
  }
end

return M
