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
        return jsonpath_toggle.enabled() -- and .. other possible overrides to add here
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

      -- width taken by everything in the statusline except the path (branch, grapple, x/y/z...).
      -- Renders the statusline once with the path segment blanked (guard flag avoids recursion).
      local measuring = false
      local function other_width()
        measuring = true
        local ok, width = pcall(function()
          local stl = require("lualine").statusline()
          return vim.api.nvim_eval_statusline(stl, { maxwidth = 0 }).width
        end)
        measuring = false
        return ok and width or 80
      end

      -- TODO: PRIO4: figure out smthing cleaner for this whole func & its helpers
      local function truncate_path()
        if measuring then
          return ""
        end

        local filename = vim.fn.expand("%:t")
        local relative_path = vim.fn.expand("%:.")
        local dir = vim.fn.fnamemodify(relative_path, ":h")
        local separator = OnWindows and "\\" or "/"

        if dir ~= "." then
          -- budget = free columns after all other segments, the filename and the separator
          local budget = vim.o.columns - other_width() - vim.fn.strdisplaywidth(filename) - 1 - 3
          budget = math.max(budget, 8)

          if vim.fn.strdisplaywidth(dir) > budget then
            -- outside cwd, paths can mix "/" and "\" (or be "~/..."), so split on both
            local parts = vim.split(dir, "[/\\]")
            parts = vim.tbl_filter(function(p)
              return p ~= ""
            end, parts)
            if dir:match("^[/\\]") then
              parts[1] = separator .. (parts[1] or "")
            end
            local parents_kept = 2

            -- 1) shorten leading dirs, progressively harder
            for _, shorten_len in ipairs({ 5, 3, 2, 1 }) do
              for i = 1, #parts - parents_kept do
                parts[i] = parts[i]:sub(1, shorten_len)
              end
              if vim.fn.strdisplaywidth(table.concat(parts, separator)) <= budget then
                break
              end
            end

            -- 2) still too long: drop leading dirs
            local ellipsis = false
            while
              #parts > 1
              and vim.fn.strdisplaywidth(table.concat(parts, separator)) + (ellipsis and 2 or 0)
                > budget
            do
              table.remove(parts, 1)
              ellipsis = true
            end

            dir = table.concat(parts, separator)

            -- 3) single remaining dir still too long: cut from the left
            if vim.fn.strdisplaywidth(dir) + (ellipsis and 2 or 0) > budget then
              dir = dir:sub(-math.max(1, budget - 2))
              ellipsis = true
            end

            dir = (ellipsis and ("…" .. separator) or "") .. dir
          end
        end

        return table.concat({ dir, separator, "%#LualineFilename#", filename, "%*" })
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
          truncate_path,
          cond = function()
            return not status_line_ovverridden()
          end,
        },
        -- {
        --   function()
        --     local buffer_marks = vim.fn.getmarklist(vim.api.nvim_get_current_buf())
        --     local buffer_letters = {}
        --
        --     for _, mark in ipairs(buffer_marks) do
        --       local letter = mark.mark:sub(2, 2)
        --       if letter:match("[a-z]") then
        --         table.insert(buffer_letters, letter)
        --       end
        --     end
        --
        --     return #buffer_letters > 0 and table.concat(buffer_letters, "") or ""
        --   end,
        --   cond = function()
        --     return not status_line_ovverridden()
        --   end,
        -- },
        -- NOTE: local marks turned off for now to make room
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
