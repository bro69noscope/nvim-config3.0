return {
  "saghen/blink.cmp",
  enabled = true,
  lazy = true,
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "rafamadriz/friendly-snippets",
    "L3MON4D3/LuaSnip",
  },
  -- test:
  -- lua_ls
  -- blink-cmp-introduction-special-thanks
  version = "*", -- either use a release or use the build command below
  -- build = "cargo build --release",
  config = function()
    local has_luasnip, _ = pcall(require, "luasnip")
    require("blink.cmp").setup({
      keymap = {
        preset = "none",
        [UpWindowBind] = { "select_prev", "fallback" },
        [DownWindowBind] = { "select_next", "fallback" },
        ["<C-e>"] = { "show", "hide" },
        ["<CR>"] = { "accept", "fallback" },
      },

      -- Appearance settings
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },

      sources = {
        default = {
          "snippets",
          "lsp",
          "buffer",
          "path",
        },
        per_filetype = {
          sql = { "snippets", "dadbod", "buffer" },
        },
        -- Define custom providers
        providers = {
          -- vid-dadbord-completion plugin
          dadbod = {
            name = "Dadbod",
            module = "vim_dadbod_completion.blink",
          },
          -- Custom buffer source for current buffer only (text search)
          current_buffer_search = {
            name = "Current Buffer",
            module = "blink.cmp.sources.buffer",
            opts = {
              -- Hight limits for when on powerful machine
              max_sync_buffer_size = 9000000,
              max_async_buffer_size = 10000000,
              max_total_buffer_size = 90000000,
              -- Only get completions from the current buffer
              get_bufnrs = function()
                return { vim.api.nvim_get_current_buf() }
              end,
            },
          },
        },
      },

      fuzzy = {
        implementation = "rust",
        sorts = {
          "exact",
          "score",
          "sort_text",
        },
        frecency = {
          enabled = true,
        },
        use_proximity = true,
        max_typos = function(keyword)
          return math.floor(#keyword / 8)
          -- return 0
        end,
      },

      enabled = function()
        return not vim.list_contains({ "DressingInput", "oil", "gitcommit" }, vim.bo.filetype)
          and vim.bo.buftype ~= "prompt"
          and vim.b.completion ~= false
      end,

      -- Cmdline configuration with buffer search support
      cmdline = {
        enabled = true,
        keymap = {
          preset = "none",
          [UpWindowBind] = { "select_prev", "fallback" },
          [DownWindowBind] = { "select_next", "fallback" },
          ["<C-e>"] = { "show", "hide" },
          ["<Tab>"] = { "accept", "fallback" },
        },
        -- Configure sources for different command line modes
        --- @ type function
        sources = function()
          local type = vim.fn.getcmdtype()
          -- Search forward and backward - show CURRENT buffer completions only
          if type == "/" or type == "?" then
            return { "current_buffer_search" }
          end
          -- Commands - show cmdline completions
          if type == ":" or type == "@" then
            return { "cmdline" } -- NOTE: this doesn't seem customizable
          end
          return {}
        end,
        completion = {
          trigger = {
            show_on_blocked_trigger_characters = {},
            show_on_x_blocked_trigger_characters = {},
          },
          list = {
            selection = {
              preselect = true,
              auto_insert = true,
            },
          },
          menu = { auto_show = true },
          ghost_text = { enabled = false },
        },
      },

      -- Completion settings
      completion = {
        accept = {
          auto_brackets = { enabled = false }, -- Match nvim-cmp behavior
        },
        menu = {
          auto_show = true,
          border = "none",
          draw = {
            treesitter = { "lsp" },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = "none" },
        },
        keyword = {
          range = "full",
        },
      },

      -- Signature help (optional)
      signature = {
        enabled = false,
        window = { border = "none" },
      },

      -- Snippets configuration
      snippets = {
        preset = has_luasnip and "luasnip" or "default",
      },
    })
  end,
}
