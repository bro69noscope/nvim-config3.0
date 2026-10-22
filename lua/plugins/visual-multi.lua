return {
  "mg979/vim-visual-multi",
  enabled = true,
  keys = {
    { "<C-Right>", desc = "Add cursor at position" },
    { "<C-Left>", desc = "Toggle cursor mappings" },
    { "<C-Up>", desc = "Add cursor up" },
    { "<C-Down>", desc = "Add cursor down" },
    { "<C-n>", mode = { "n", "v" }, desc = "Select next word" },
  },
  config = function()
    local overwritten_keys = { "<CR>", "<BS>", "<Up>", "<Down>" }
    local debug = false

    local function log_maps(label, keys)
      if not debug then
        return
      end
      for _, lhs in ipairs(keys) do
        local m = vim.fn.maparg(lhs, "i", false, true)
        vim.notify(
          ("%s %s: buffer=%s callback=%s rhs=%s desc=%s"):format(
            label,
            lhs,
            tostring(m.buffer),
            tostring(m.callback ~= nil),
            tostring(m.rhs),
            tostring(m.desc)
          )
        )
      end
    end

    vim.api.nvim_create_autocmd("User", {
      pattern = "visual_multi_start",
      callback = function()
        local buf = vim.api.nvim_get_current_buf()

        vim.schedule(function()
          if not (vim.api.nvim_buf_is_valid(buf) and vim.b[buf].visual_multi) then
            return
          end
          for lhs, action in pairs({ ["<Up>"] = "select_prev", ["<Down>"] = "select_next" }) do
            local vm_map = vim.fn.maparg(lhs, "i", false, true)
            if vm_map.buffer == 1 then
              vim.keymap.set("i", lhs, function()
                local blink = require("blink.cmp")
                if blink.is_menu_visible() then
                  return blink[action]()
                end
                if vm_map.callback then
                  return vm_map.callback()
                end
                vim.api.nvim_feedkeys(vim.keycode(vm_map.rhs), "m", false)
              end, { buffer = buf, silent = true })
            end
          end
        end)

        log_maps("VM start", overwritten_keys)

        local ok, autopairs = pcall(require, "nvim-autopairs")
        if ok then
          autopairs.disable()
        end
      end,
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "visual_multi_exit",
      callback = function()
        local buf = vim.api.nvim_get_current_buf()

        local ok, autopairs = pcall(require, "nvim-autopairs")
        if ok then
          autopairs.force_attach()
          autopairs.enable()
        end

        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(buf) then
            return
          end
          vim.api.nvim_buf_call(buf, function()
            local ok_apply, err = pcall(function()
              local apply = require("blink.cmp.keymap.apply")
              -- apply skips buffers that still hold any blink map, so clear the leftovers
              for _, mode in ipairs({ "i", "s" }) do
                for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
                  if map.desc and vim.startswith(map.desc, apply.DESC_PREFIX) then
                    vim.api.nvim_buf_del_keymap(buf, mode, map.lhs)
                  end
                end
              end
              apply.keymap_to_current_buffer(
                require("blink.cmp.keymap").get_mappings(
                  require("blink.cmp.config").keymap,
                  "default"
                )
              )
            end)
            if not ok_apply then
              vim.notify("VM exit: blink rebind failed: " .. tostring(err), vim.log.levels.ERROR)
            end
          end)
          log_maps("VM exit", overwritten_keys)
        end)
      end,
    })

    vim.g.VM_maps = {
      -- Fix conflict with treesitter-textobjects bindings
      ["Goto Next"] = "]v",
      ["Goto Prev"] = "[v",
    }

    local incsearch_hl = vim.api.nvim_get_hl(0, { name = "IncSearch" })
    vim.api.nvim_set_hl(0, "VMCustom", {
      fg = incsearch_hl.fg, -- black fg text from IncSearch
      bg = "#ff59f4", -- bright pink background that contrasts well with IncSearch's orange
    })
    vim.api.nvim_set_hl(0, "VM_Extend", { link = "VMCustom" })
    vim.api.nvim_set_hl(0, "VM_Insert", { link = "VMCustom" })
    vim.api.nvim_set_hl(0, "VM_Cursor", { link = "VMCustom" })
    vim.api.nvim_set_hl(0, "VM_Mono", { link = "VMCustom" })

    vim.keymap.set(
      "n",
      "<C-Right>",
      "<Plug>(VM-Add-Cursor-At-Pos)",
      { noremap = true, silent = true }
    )
    vim.keymap.set("n", "<C-Left>", "<Plug>(VM-Toggle-Mappings)", { noremap = true, silent = true })
    vim.keymap.set("n", "<C-Up>", "<Plug>(VM-Add-Cursor-Up)", { noremap = true, silent = true })
    vim.keymap.set("n", "<C-Down>", "<Plug>(VM-Add-Cursor-Down)", { noremap = true, silent = true })
  end,
}
