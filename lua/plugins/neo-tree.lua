return {
  "nvim-neo-tree/neo-tree.nvim",
  enabled = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
    "kwkarlwang/bufresize.nvim", -- for automatic resize support
  },
  lazy = true,
  event = "BufReadPost",
  init = function()
    if false then -- Using snack explorer as main explorer for now
      _G.MainFileExplorer = "neo-tree"
    end
  end,

  config = function()
    -- Create base event handlers
    local event_handlers = {
      {
        event = "neo_tree_popup_input_ready",
        handler = function(args)
          -- map <esc> to enter normal mode (by default closes prompt)
          -- don't forget `opts.buffer` to specify the buffer of the popup.
          vim.keymap.set("i", "<esc>", vim.cmd.stopinsert, { noremap = true, buffer = args.bufnr })
        end,
      },
      {
        event = "neo_tree_popup_input_ready",
        handler = function(args)
          -- Map <CR> in normal mode to confirm/save the input
          vim.keymap.set("n", "<CR>", function()
            vim.cmd.startinsert()
            vim.api.nvim_feedkeys(
              vim.api.nvim_replace_termcodes("<CR>", true, false, true),
              "n",
              false
            )
          end, { buffer = args.bufnr, noremap = true })
        end,
      },
    }

    -- Add bufresize event handlers if the plugin is loaded
    if _G.Bufresize then
      local handlers = {
        {
          event = "neo_tree_window_before_open",
          handler = function()
            _G.Bufresize.register()
            _G.Bufresize.block_register()
          end,
        },
        {
          event = "neo_tree_window_after_open",
          handler = function()
            _G.Bufresize.resize_open()
          end,
        },
        {
          event = "neo_tree_window_before_close",
          handler = function()
            _G.Bufresize.register()
            _G.Bufresize.block_register()
          end,
        },
        {
          event = "neo_tree_window_after_close",
          handler = function()
            _G.Bufresize.resize_close()
          end,
        },
      }

      for _, handler in ipairs(handlers) do
        table.insert(event_handlers, handler)
      end
    end

    require("neo-tree").setup({
      -- popup_border_style = "single",
      close_if_last_window = false,
      enable_git_status = true,
      enable_diagnostics = true,
      filesystem = {
        follow_current_file = {
          enabled = true,
        },
      },
      commands = {
        copy_selector = require("modules.neo-tree.copy-selector").copy_selected_path,
        close_towards_up = require("modules.neo-tree.node-toggler").navigate_up,
        open_towards_down = require("modules.neo-tree.node-toggler").navigate_down,
        grep_for_filename = require("modules.neo-tree.grep-for-filename").grep_for_filename,
        grep_in_directory = require("modules.neo-tree.grep-in-neotree-dir").live_grep_neotree_dir,
      },
      window = {
        mappings = {
          ["s"] = "none", -- unbind to be able to use flash
          ["<space>"] = "none", -- unbind to be able to use leader key
          ["S"] = "open_vsplit",
          ["L"] = "focus_preview",
          ["X"] = "expand_all_subnodes",
          ["Y"] = "copy_selector",
          ["h"] = "close_towards_up", -- Navigate to parent directory / Close current directory
          ["l"] = "open_towards_down", -- Open current directory / Navigate to first child
          ["gf"] = "grep_for_filename", -- Grep for the current node's filename in cwd
          ["gd"] = "grep_in_directory", -- Grep in the parent/selected directory
        },
      },
      event_handlers = event_handlers,
    })
  end,
  keys = {
    {
      vim.g.maplocalleader .. "e",
      function()
        local snacks_explorer_ft = {
          "snacks_picker_list",
          "snacks_picker_input",
        }

        -- Close any snacks explorer buffers
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) then
            local ft = vim.bo[buf].filetype
            for _, snacks_ft in ipairs(snacks_explorer_ft) do
              if ft == snacks_ft then
                -- Find windows displaying this buffer and close them
                local wins = vim.fn.win_findbuf(buf)
                for _, win in ipairs(wins) do
                  if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, false)
                  end
                end
                break
              end
            end
          end
        end

        -- Toggle Neo-tree
        vim.cmd("Neotree toggle")
      end,
      desc = "Toggle Neo-tree",
    },
  },
  cmd = {
    "Neotree",
    "Neotree show",
    "Neotree toggle",
    "Neotree reveal",
  },
}
