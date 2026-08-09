local M = {}
---@param source string explicit source name, e.g. "grep" or "grep_word"
M.make_grep_source = function(source)
  return {
    finder = M.case_aware_grep.wrap(require("modules.snacks.picker.finders.egrepify").egrepify),
    layout = "grep_vertical",
    win = {
      input = {
        keys = M.setup_all_keys.setup_grep_input_keys(nil, nil, source),
      },
    },
    actions = {
      toggle_and_search = require("modules.snacks.picker.actions.toggle-grep-and-search"),
      toggle_smartcase = require("modules.snacks.picker.actions.toggle-smartcase"),
      grep_globs_input = require("modules.snacks.picker.actions.input-grep-globs").make_action(
        nil,
        nil,
        source
      ),
    },
  }
end
return M
