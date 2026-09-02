return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  enabled = true,
  event = "VeryLazy",
  branch = "main",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("nvim-treesitter-textobjects").setup({
      move = {
        set_jumps = true,
      },
    })

    local move = require("nvim-treesitter-textobjects.move")

    local function get_lang()
      local ok, lang = pcall(vim.treesitter.language.get_lang, vim.bo.filetype)
      if ok and lang then
        return lang
      end
      return vim.bo.filetype
    end

    local function query_has_capture(query_string)
      local lang = get_lang()
      local ok, query = pcall(vim.treesitter.query.get, lang, "textobjects")

      if not ok or not query then
        vim.notify(
          string.format("[textobjects] no textobjects query for language '%s'", lang),
          vim.log.levels.ERROR
        )
        return false
      end

      local capture_name = query_string:gsub("^@", "")
      for _, name in ipairs(query.captures) do
        if name == capture_name then
          return true
        end
      end

      vim.notify(
        string.format(
          "[textobjects] capture '%s' not defined for language '%s'",
          query_string,
          lang
        ),
        vim.log.levels.ERROR
      )
      return false
    end

    local function map_moves(fn, keys)
      for lhs, spec in pairs(keys) do
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          if not query_has_capture(spec.query) then
            return
          end
          fn(spec.query, "textobjects")
        end, { desc = spec.desc })

        local ok, wk = pcall(require, "which-key")
        if ok then
          wk.add({ { lhs, desc = spec.desc, icon = "🌲" } })
        end
      end
    end

    map_moves(move.goto_next_start, {
      ["]f"] = { query = "@definition.name", desc = "Next definition name" },
      ["]c"] = { query = "@class.outer", desc = "Next class start" },
      ["]a"] = { query = "@parameter.inner", desc = "Next parameter" },
      ["]n"] = { query = "@number.inner", desc = "Next number" },
      ["]w"] = { query = "@call.outer", desc = "Next call" },
      ["]j"] = { query = "@attribute.inner", desc = "Next attribute" },
      -- ["]U"] = { query = "@comment.inner", desc = "Next comment" },
      ["]u"] = { query = "@comment.inner", desc = "Next comment" },
      ["]i"] = { query = "@conditional.outer", desc = "Next conditional" },
      ["]o"] = { query = "@loop.outer", desc = "Next loop" },
      ["]z"] = { query = "@call.function_name", desc = "Next function-call name" },
      ["]x"] = { query = "@call.method_name", desc = "Next method-call name" },
      ["]e"] = { query = "@call.name", desc = "Next call name (any)" },
      ["]h"] = { query = "@definition.return_type", desc = "Next return type" },
      ["]p"] = { query = "@definition.params", desc = "Next params definition" },
      ["]m"] = { query = "@variable.member.inner", desc = "Next member" },
      ["]R"] = { query = "@return.inner", desc = "Next return" },
    })

    map_moves(move.goto_next_end, {
      -- NOTE: commented out to try cutting down on mental overhead

      -- ["]F"] = { query = "@function.outer", desc = "Next function end" },
      -- ["]C"] = { query = "@class.outer", desc = "Next class end" },
      -- ["]A"] = { query = "@parameter.inner", desc = "Next parameter end" },
      -- ["]N"] = { query = "@number.inner", desc = "Next number end" },
      -- ["]W"] = { query = "@call.outer", desc = "Next call end" },
      -- ["]J"] = { query = "@attribute.inner", desc = "Next attribute end" },
      -- ["]u"] = { query = "@comment.inner", desc = "Next comment end" },
      -- ["]I"] = { query = "@conditional.outer", desc = "Next conditional end" },
      -- ["]O"] = { query = "@loop.outer", desc = "Next loop end" },
      -- ["]Z"] = { query = "@call.function_name", desc = "Next function-call name end" },
      -- ["]X"] = { query = "@call.method_name", desc = "Next method-call name end" },
      -- ["]E"] = { query = "@call.name", desc = "Next call name (any) end" },
      -- ["]H"] = { query = "@definition.return_type", desc = "Next return type end" },
      -- ["]P"] = { query = "@definition.params", desc = "Next params definition end" },
    })

    map_moves(move.goto_previous_start, {
      ["[f"] = { query = "@definition.name", desc = "Prev. definition name" },
      ["[c"] = { query = "@class.outer", desc = "Prev. class start" },
      ["[a"] = { query = "@parameter.inner", desc = "Prev. parameter" },
      ["[n"] = { query = "@number.inner", desc = "Prev. number" },
      ["[w"] = { query = "@call.outer", desc = "Prev. call" },
      ["[j"] = { query = "@attribute.inner", desc = "Prev. attribute" },
      -- ["[U"] = { query = "@comment.inner", desc = "Prev. comment" },
      ["[u"] = { query = "@comment.inner", desc = "Prev. comment" },
      ["[i"] = { query = "@conditional.outer", desc = "Prev. conditional" },
      ["[o"] = { query = "@loop.outer", desc = "Prev. loop" },
      ["[z"] = { query = "@call.function_name", desc = "Prev. function-call name" },
      ["[x"] = { query = "@call.method_name", desc = "Prev. method-call name" },
      ["[e"] = { query = "@call.name", desc = "Prev. call name (any)" },
      ["[h"] = { query = "@definition.return_type", desc = "Prev. return type" },
      ["[p"] = { query = "@definition.params", desc = "Prev. params definition" },
      ["[m"] = { query = "@variable.member.inner", desc = "Prev. member" },
      ["[R"] = { query = "@return.inner", desc = "Prev. return" },
    })

    map_moves(move.goto_previous_end, {
      -- ["[F"] = { query = "@function.outer", desc = "Prev. function end" },
      -- ["[C"] = { query = "@class.outer", desc = "Prev. class end" },
      -- ["[A"] = { query = "@parameter.inner", desc = "Prev. parameter end" },
      -- ["[N"] = { query = "@number.inner", desc = "Prev. number end" },
      -- ["[W"] = { query = "@call.outer", desc = "Prev. call end" },
      -- ["[J"] = { query = "@attribute.inner", desc = "Prev. attribute end" },
      -- ["[u"] = { query = "@comment.inner", desc = "Prev. comment end" },
      -- ["[I"] = { query = "@conditional.outer", desc = "Prev. conditional end" },
      -- ["[O"] = { query = "@loop.outer", desc = "Prev. loop end" },
      -- ["[Z"] = { query = "@call.function_name", desc = "Prev. function-call name end" },
      -- ["[X"] = { query = "@call.method_name", desc = "Prev. method-call name end" },
      -- ["[E"] = { query = "@call.name", desc = "Prev. call name (any) end" },
      -- ["[H"] = { query = "@definition.return_type", desc = "Prev. return type end" },
      -- ["[P"] = { query = "@definition.params", desc = "Prev. params definition end" },
    })

    local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
    -- ensure ; goes forward and , goes backward regardless of the last direction
    -- vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
    -- vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)

    -- vim way: ; goes to the direction you were moving.
    vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
    vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

    -- make builtin f, F, t, T also repeatable with ; and ,
    vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })
  end,
}
