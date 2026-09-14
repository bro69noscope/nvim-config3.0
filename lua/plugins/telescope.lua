return {
  "nvim-telescope/telescope.nvim",
  enabled = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
  },
  event = "VeryLazy",
  keys = {
    {
      "g<Space>",
      function()
        require("telescope").extensions.grapple.tags()
      end,
      desc = "Grapple tags",
    },
  },
  config = function()
    vim.api.nvim_set_hl(0, "TelescopeMatching", { link = "CustomMatch" })
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local focus_keymaps = require("modules.telescope.mappings.focus-keymaps")

    -- Flash setup
    local function flash(prompt_bufnr)
      require("flash").jump({
        pattern = "^",
        label = { after = { 0, 0 } },
        search = {
          mode = "search",
          exclude = {
            function(win)
              return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "TelescopeResults"
            end,
          },
        },
        action = function(match)
          local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
          picker:set_selection(match.pos[1] - 1)
        end,
      })
    end

    -- Configure telescope
    local project_actions = require("telescope._extensions.project.actions")
    telescope.setup({
      defaults = {
        mappings = {
          n = {
            s = flash,
            [RightWindowBind] = focus_keymaps.focus_preview,
            [LeftWindowBind] = focus_keymaps.focus_results,
          },
          i = {
            ["<m-s>"] = flash,
            [RightWindowBind] = focus_keymaps.focus_preview,
            [LeftWindowBind] = focus_keymaps.focus_results,
          },
        },
        sorting_strategy = "ascending",
        layout_config = {
          prompt_position = "top",
        },
      },
      pickers = {
        live_grep = {
          mappings = {
            i = {
              ["<C-g>"] = actions.to_fuzzy_refine,
            },
          },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
        egrepify = {
          results_ts_hl = true,
          -- filename_hl = "EgrepifyFile", -- default, not required, links to `Title`
          filename_hl = "lualine_b_normal",
        },
        project = {
          mappings = {
            n = {
              ["b"] = false,
              ["c"] = false,
              ["C"] = false,
              ["d"] = false,
              ["f"] = false,
              ["r"] = project_actions.recent_project_files,
              ["s"] = false,
              ["w"] = false,

              ["<c-a>"] = project_actions.add_project,
              ["<c-p>"] = project_actions.add_project_cwd,
              ["<c-b>"] = project_actions.browse_project_files,
              ["<c-d>"] = project_actions.delete_project,
              ["<c-f>"] = project_actions.find_project_files,
              ["<c-r>"] = project_actions.rename_project,
              ["<c-s>"] = project_actions.search_in_project_files,
            },
          },
        },
      },
    })

    telescope.load_extension("fzf")
    telescope.load_extension("egrepify")
    telescope.load_extension("grapple")
  end,
}
