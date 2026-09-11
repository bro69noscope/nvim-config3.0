return {
  "hrsh7th/nvim-cmp",
  enabled = false,
  dependencies = {
    "hrsh7th/cmp-cmdline",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "rafamadriz/friendly-snippets",
    "onsails/lspkind-nvim",
  },
  event = { "InsertEnter", "CmdlineEnter" },
  config = function()
    vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { link = "CustomMatch" })
    vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", { link = "CustomMatchFuzzy" })
    local cmp = require("cmp")
    local has_luasnip, luasnip = pcall(require, "luasnip")
    ---@diagnostic disable-next-line: redundant-parameter
    cmp.setup({
      window = {
        completion = {
          winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
          col_offset = -3,
          side_padding = 0,
        },
      },
      formatting = {
        fields = { "kind", "abbr" },
        format = function(entry, vim_item)
          local original_kind = vim_item.kind
          local kind = require("lspkind").cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
          })(entry, vim_item)

          local strings = vim.split(kind.kind, "%s", { trimempty = true })
          kind.kind = " " .. (strings[1] or "") .. " "

          local has_colormenu, colormenu = pcall(require, "colorful-menu")
          if has_colormenu then
            local highlights_info = colormenu.cmp_highlights(entry)
            if highlights_info then
              kind.abbr_hl_group = highlights_info.highlights
              kind.abbr = highlights_info.text
            end
          end

          -- print("DEBUG - Original Kind:", original_kind, "Label:", vim_item.abbr)
          -- Make python keyword argument names yellow
          if original_kind == "Variable" and string.find(vim_item.abbr, "=") then
            kind.abbr_hl_group = "@variable.parameter" -- This should be yellow
          end

          return kind
        end,
      },
      snippet = {
        expand = function(args)
          if has_luasnip then
            luasnip.lsp_expand(args.body)
          end
        end,
      },
      mapping = {
        -- show information on cmp selected entry
        ["<Left>"] = cmp.mapping(function()
          local entry = cmp.get_selected_entry()
          if entry then
            print("Source:", entry.source.name)
            print("Label:", entry.completion_item.label)
            print("Kind:", entry.completion_item.kind)
            print("Detail:", entry.completion_item.detail or "none")
            print("Documentation:", vim.inspect(entry.completion_item.documentation))
          end
        end),
        ["<Up>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
          else
            fallback()
          end
        end),
        ["<Down>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
          else
            fallback()
          end
        end),
        ["<C-f>"] = cmp.mapping.complete(),
        ["<C-f>"] = cmp.mapping.close(),
        ["<CR>"] = cmp.mapping.confirm({
          select = true,
        }),
      },
      completion = {
        completeopt = "menu,menuone,noselect",
      },
      sources = cmp.config.sources({
        { name = "luasnip" },
        { name = "nvim_lsp" },
        { name = "buffer" },
        { name = "path" },
      }),
    })

    -- Setup for cmdline completion
    cmp.setup.cmdline(":", {
      mapping = {
        ["<Tab>"] = cmp.mapping(cmp.mapping.confirm({ select = true }), { "c" }),
        ["<Up>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
          else
            fallback()
          end
        end, { "c" }),
        ["<Down>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
          else
            fallback()
          end
        end, { "c" }),
        ["<CR>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            local entry = cmp.get_selected_entry()
            if entry then
              cmp.confirm({ select = false })
            else
              cmp.close()
              fallback()
            end
          else
            fallback()
          end
        end, { "c" }),
      },
      sources = cmp.config.sources({
        { name = "path" },
      }, {
        { name = "cmdline" },
      }),
    })

    -- Setup for search completion
    cmp.setup.cmdline("/", {
      mapping = {
        ["<Tab>"] = cmp.mapping(cmp.mapping.confirm({ select = true }), { "c" }),
        ["<Up>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
          else
            fallback()
          end
        end, { "c" }),
        ["<Down>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
          else
            fallback()
          end
        end, { "c" }),
        ["<CR>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            local entry = cmp.get_selected_entry()
            if entry then
              cmp.confirm({ select = false })
            else
              cmp.close()
              fallback()
            end
          else
            fallback()
          end
        end, { "c" }),
      },
      sources = {
        { name = "buffer" },
      },
    })
  end,
}
