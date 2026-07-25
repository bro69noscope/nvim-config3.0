return {
  {
    "nvim-lualine/lualine.nvim",
    enabled = true,
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- Get default config first
      local lualine = require("lualine")
      local _, navic = pcall(require, "nvim-navic")
      local config = lualine.get_config()

      -- lualine_c_normal = { bg = "#1E2030", fg = "#828BB8", nocombine = true, }
      vim.api.nvim_set_hl(0, "LualineFilename", { fg = "#949fd1", bold = true })

      local jsonpath_toggle = require("modules.snacks.toggle.custom-toggles.jsonpath-statusline")

      local status_line_ovverridden = function()
        return jsonpath_toggle.enabled() -- and .. other possible ovverrides to add here
      end

      local function diff_source()
        local gitsigns = vim.b.gitsigns_status_dict
        if gitsigns then
          return {
            added = gitsigns.added,
            modified = gitsigns.changed,
            removed = gitsigns.removed,
          }
        end
      end

      local function winbar_cfg()
        local excluded_ft = {
          qf = true,
          trouble = true,
          toggleterm = true,
          snacks_terminal = true,
          noice = true,
        }
        local loc = navic.get_location()
        return loc .. (excluded_ft[vim.bo.filetype] and "" or " ")
      end

      config.options.theme = "tokyonight"

      config.sections.lualine_b = {
        -- "branch",
        { "b:gitsigns_head", icon = "" },
        { "diff", source = diff_source },
        "diagnostics",
      }

      config.winbar.lualine_c = {
        {
          function()
            if vim.wo.diff then
              return ""
            end

            if
              vim.bo.filetype == "json"
              or vim.bo.filetype == "jsonc"
              or vim.bo.filetype == "json5"
            then
              return require("jsonpath").get() or ""
            end

            return winbar_cfg()
          end,
        },
      }

      config.sections.lualine_c = {
        {
          function()
            local ok, jp = pcall(require, "jsonpath")
            if ok then
              return jp.get() or ""
            end
            return ""
          end,
          cond = jsonpath_toggle.enabled,
        },
        {
          "grapple",
          cond = function()
            return not status_line_ovverridden()
          end,
        },
        {
          function()
            local filename = vim.fn.expand("%:t")
            local relative_path = vim.fn.expand("%:.")
            local dir = vim.fn.fnamemodify(relative_path, ":h")
            local separator = OnWindows and "\\" or "/"
            local full_path_len = #vim.fn.expand("%:p")

            if full_path_len > 140 then
              dir = vim.fn.pathshorten(dir, 3)
            elseif full_path_len > 100 then
              dir = vim.fn.pathshorten(dir, 5)
            end

            return table.concat({ dir, separator, "%#LualineFilename#", filename, "%*" })
          end,
          cond = function()
            return not status_line_ovverridden()
          end,
        },
        {
          function()
            local buffer_marks = vim.fn.getmarklist(vim.api.nvim_get_current_buf())
            local buffer_letters = {}

            for _, mark in ipairs(buffer_marks) do
              local letter = mark.mark:sub(2, 2)
              if letter:match("[a-z]") then
                table.insert(buffer_letters, letter)
              end
            end

            return #buffer_letters > 0 and table.concat(buffer_letters, "") or ""
          end,
          cond = function()
            return not status_line_ovverridden()
          end,
        },
      }

      table.insert(config.sections.lualine_x, 1, {
        function()
          local global_marks = vim.fn.getmarklist()
          local global_letters = {}

          for _, mark in ipairs(global_marks) do
            local letter = mark.mark:sub(2, 2)
            if letter:match("[A-Z]") then
              table.insert(global_letters, letter)
            end
          end

          return #global_letters > 0 and table.concat(global_letters, "") or ""
        end,
      })

      table.insert(config.sections.lualine_x, 3, {
        function()
          return require("copilot_status").status_string()
        end,
        cnd = function()
          return require("copilot_status").enabled()
        end,
      })

      table.insert(config.sections.lualine_x, 4, {
        "macro",
        fmt = function()
          local reg = vim.fn.reg_recording()
          if reg ~= "" then
            return "Recording @" .. reg
          end
          return nil
        end,
        color = { fg = "#ff9e64" },
        draw_empty = false,
      })

      table.insert(config.sections.lualine_y, 1, {
        function()
          if vim.opt.iminsert:get() > 0 and vim.b.keymap_name then
            return "⌨ " .. vim.b.keymap_name
          end
          return ""
        end,
        color = { fg = "#ff9e64" },
      })

      config.options.globalstatus = true
      lualine.setup(config)
    end,
  },
}
