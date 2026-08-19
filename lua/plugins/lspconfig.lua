return {
  {
    "williamboman/mason.nvim",
    event = { "BufReadPre" },
    enabled = true,
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonLog", "MasonUpdate" },
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre" },
    enabled = true,
    opts = {
      automatic_enable = false,
      ensure_installed = {
        -- lua
        "lua_ls",
        -- python
        "pyright",
        "pylsp",
        "basedpyright",
        "ruff",
        -- pwsh
        "powershell_es",
        -- xml
        "lemminx",
        -- web
        "html",
        "cssls",
        "ts_ls",
        "emmet_ls",
        -- misc
        "jsonls",
        -- NOTE: for c#, do ":MasonInstall roslyn / roslyn-nightly". We use lua/plugins/roslyn.lua
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre" },
    enabled = true,
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      { "ray-x/lsp_signature.nvim", enabled = true },
    },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      -- Update lsps after file renames (mainly for import resolutions)
      capabilities.workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = true,
        },
      }

      -- Setup completion capabilities
      local has_cmp_lsp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      local has_cmp, cmp = pcall(require, "cmp")
      local has_blink_cmp, blink_cmp = pcall(require, "blink.cmp")
      if has_blink_cmp then
        capabilities = blink_cmp.get_lsp_capabilities()
      else
        if has_cmp_lsp then
          capabilities = cmp_lsp.default_capabilities(capabilities)
        end
      end

      -- Setup document symbol features capabilities
      local has_navic, navic = pcall(require, "nvim-navic")
      local has_navbuddy, navbuddy = pcall(require, "nvim-navbuddy")

      --- @diagnostic disable-next-line: unused-local
      local function custom_attach(client, bufnr)
        if client.server_capabilities.documentSymbolProvider then
          if has_navic then
            navic.attach(client, bufnr)
          end
          if has_navbuddy then
            navbuddy.attach(client, bufnr)
          end
        end

        -- close completion menu when showing signature help
        vim.keymap.set("i", "<c-s>", function()
          if has_blink_cmp and blink_cmp.is_visible() then
            blink_cmp.hide()
          end
          if has_cmp and cmp.visible() then
            cmp.close()
          end
          vim.lsp.buf.signature_help()
        end, { buffer = bufnr })
      end

      local lua_ls_config = require("lang.lua.lsp.lua-lsp-settings").lua_ls
      vim.lsp.config("lua_ls", {
        settings = lua_ls_config.settings,
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          lua_ls_config.on_attach(client, bufnr)
          custom_attach(client, bufnr)
        end,
      })

      local lemminx_config = require("lang.xml.lsp.xml-lsp-settings").lemminx
      vim.lsp.config("lemminx", {
        settings = lemminx_config.settings,
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          custom_attach(client, bufnr)
        end,
      })

      -- We use Pyright for completions, hover, signatures (it's faster at interactive stuff)
      local pyright_config = require("lang.python.lsp.python-lsp-settings").pyright
      vim.lsp.config("pyright", {
        capabilities = capabilities,
        settings = pyright_config.settings,
        on_attach = function(client, bufnr)
          pyright_config.on_attach(client, bufnr)
          custom_attach(client, bufnr)
        end,
      })

      -- BasedPyright for type checking and diagnostics (the GOAT)
      local basedpyright_config = require("lang.python.lsp.python-lsp-settings").basedpyright
      vim.lsp.config("basedpyright", {
        capabilities = capabilities,
        settings = basedpyright_config.settings,
        on_attach = function(client, bufnr)
          basedpyright_config.on_attach(client, bufnr)
          custom_attach(client, bufnr)
        end,
      })

      -- pylsp for renaming (it's the only one that can rename module symbols properly AFAIK)
      local pylsp_config = require("lang.python.lsp.python-lsp-settings").pylsp
      vim.lsp.config("pylsp", {
        capabilities = capabilities,
        settings = pylsp_config.settings,
        on_attach = function(client, bufnr)
          pylsp_config.on_attach(client, bufnr)
        end,
      })

      -- Ruff for formatting and diagnostics
      local ruff_config = require("lang.python.lsp.python-lsp-settings").ruff
      vim.lsp.config("ruff", {
        capabilities = capabilities,
        init_options = {
          settings = ruff_config.settings,
        },
      })

      local powershell_es_config =
        require("lang.powershell.lsp.powershell-lsp-settings").powershell_es
      vim.lsp.config("powershell_es", {
        cmd = powershell_es_config.cmd,
        settings = powershell_es_config.settings,
        capabilities = capabilities,
        on_attach = powershell_es_config.on_attach,
      })

      local ahk2_config = require("lang.autohotkey.lsp.autohotkey-lsp-settings").ahk2
      vim.lsp.config("ahk2", {
        cmd = ahk2_config.cmd,
        filetypes = ahk2_config.filetypes,
        single_file_support = ahk2_config.single_file_support,
        flags = ahk2_config.flags,
        init_options = ahk2_config.init_options,
        capabilities = capabilities,
        on_attach = custom_attach,
      })

      local servers = {
        lua_ls = true,
        pyright = false,
        basedpyright = true,
        pylsp = true,
        ruff = true,
        roslyn = true, -- custom mason-registry version
        ahk2 = OnWindows,
        powershell_es = OnWindows,
        html = true,
        cssls = true,
        jsonls = true,
        ts_ls = true,
        emmet_ls = true,
        lemminx = true,
      }

      for name, ok in pairs(servers) do
        if ok then
          vim.lsp.enable(name)
        end
      end
    end,
  },
}
