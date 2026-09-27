return {
  "nvimdev/dashboard-nvim",
  enabled = function()
    return OnWindows and false -- this dashboard might be better for windows.
    -- Nvim loads slower on WN_NT than on WSL and the delay makes the Snacks dashboard loading noticeable.
    -- This is less fancy but has no noticeable loading period where the inital empty vi buffer would be shown.
  end,
  lazy = false,
  config = function()
    local custom_header = {
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "                                                                              ",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "                                                                              ",
      "       ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗    ",
      "       ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║    ",
      "       ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║    ",
      "       ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║    ",
      "       ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║    ",
      "       ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝    ",
      "                                                                              ",
      "                                                                              ",
      "",
      "",
      "",
      "",
    }

    local snacks = Snacks
      or setmetatable({}, {
        __index = function(_, key)
          return setmetatable({}, {
            __index = function(_, subkey)
              return function()
                vim.notify("Snacks not available: " .. key .. "." .. subkey, vim.log.levels.INFO)
              end
            end,
            __call = function()
              vim.notify("Snacks not available: " .. key, vim.log.levels.INFO)
            end,
          })
        end,
      })

    -- Add an autocmd to rename the buffer when dashboard's filetype is set
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "dashboard",
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_name(bufnr, "Dashboard")
      end,
    })

    require("dashboard").setup({
      theme = "doom",
      hide = {
        statusline = false,
      },
      config = {
        header = custom_header,
        center = {
          {
            action = function()
              snacks.picker.smart()
            end,
            desc = " Smart Find",
            icon = "󰧑",
            key = "s",
          },
          {
            action = function()
              snacks.picker.files()
            end,
            desc = " Find File",
            icon = "󰈞",
            key = "f",
          },
          {
            action = function()
              snacks.picker.grep()
            end,
            desc = " Find Word",
            icon = "",
            key = "/",
          },
          {
            action = function()
              snacks.picker.recent()
            end,
            desc = " Recent Files",
            icon = "",
            key = "r",
          },
          {
            action = 'lua require("persistence").load()',
            desc = " Restore Session",
            icon = "",
            key = "S",
          },
          {
            action = function()
              vim.cmd("Lazy")
            end,
            desc = " Open Lazy",
            icon = "󰒲",
            key = "l",
          },
          {
            action = function()
              vim.cmd("lua StartLazygit()")
            end,
            desc = " Open LazyGit",
            icon = "󰊢",
            key = "g",
          },
          {
            action = function()
              vim.cmd("quit")
            end,
            desc = " Quit Neovim",
            icon = "󰗼",
            key = "q",
          },
          {
            action = require("scripts.utils.delete-temp-shadas").Delete_shada_temp_files,
            desc = " Delete Shada Temp Files",
            icon = "󱕖",
            key = "d",
          },
        },
        footer = function()
          local stats = require("lazy").stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          return {
            "",
            "",
            "",
            "",
            "",
            "⚡ Neovim loaded "
              .. stats.loaded
              .. "/"
              .. stats.count
              .. " plugins in "
              .. ms
              .. "ms",
          }
        end,
      },
    })
  end,
  dependencies = { "nvim-tree/nvim-web-devicons" },
}
