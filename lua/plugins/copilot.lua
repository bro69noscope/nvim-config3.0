return {
  "zbirenbaum/copilot.lua",
  enabled = true,
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        debounce = 50,
        keymap = {
          accept = false, -- set contextually
          accept_word = false,
          accept_line = "<M-;>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      copilot_node_command = "node", -- Node.js version must be > 16.x
      server_opts_overrides = {
        settings = {
          advanced = {
            listCount = 10, -- #completions for panel
            inlineSuggestCount = 3, -- #completions for getCompletions
          },
        },
      },
    })

    -- Bind right to accept word if visible in insert mode ( originally was "<M-l>" but changed after my own override of "<M-l>" with "Right" from ahk )
    vim.keymap.set("i", "<Right>", function()
      if require("copilot.suggestion").is_visible() then
        require("copilot.suggestion").accept_word()
      else
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<Right>", true, false, true),
          "n",
          false
        )
      end
    end, {
      silent = true,
    })

    -- Keep tab default behavior in insert mode
    vim.keymap.set("i", "<Tab>", function()
      if require("copilot.suggestion").is_visible() then
        require("copilot.suggestion").accept()
      else
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<Tab>", true, false, true),
          "n",
          false
        )
      end
    end, {
      silent = true,
    })

    -- Force tab insert with S-Tab when suggestion is visible
    vim.keymap.set("i", "<S-Tab>", function()
      if require("copilot.suggestion").is_visible() then
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<Tab>", true, false, true),
          "n",
          false
        )
      else
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true),
          "n",
          false
        )
      end
    end, {
      silent = true,
    })
  end,
}
