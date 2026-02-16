if OnWindows then
  local powershell_options = {
    shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell",
    shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command "
      .. "[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
    shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait",
    shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode",
    shellquote = "",
    shellxquote = "",
  }
  for option, value in pairs(powershell_options) do
    vim.opt[option] = value
  end
end

Linelenght_by_ft = {
  lua = 100,
  python = 88,
  autohotkey = 88,
  markdown = "",
  text = "",
}

vim.opt.undofile = true
vim.opt.clipboard = ""
vim.opt.swapfile = false -- Annoying as fuck so testing temporary disable

vim.opt.wrap = true
vim.opt.scrolloff = 14
vim.opt.sessionoptions:remove("blank") -- Don't save empty windows in session (can cause issues with neo-tree)
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,t:block-TermCursor"

vim.g.indent_blankline_show_current_context = false
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars:append("trail:·")

-- vim.opt.timeoutlen = 50 -- uncomment for testing
vim.opt.updatetime = 50

vim.opt.cursorline = true -- Enable highlighting of the current line
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.smartindent = true -- Insert indents automatically
vim.opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
vim.opt.confirm = true -- Confirm to save changes before exiting modified buffer

vim.opt.number = true -- Print line number
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.fillchars:append({ eob = " " })
-- vim.opt.spell = true
vim.opt.spelllang = { "en_us" }
vim.opt.spelloptions = "camel"
vim.opt.spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"

vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.smartindent = true
vim.opt.termguicolors = true

-- In general, tab = 2 spaces
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2

-- Python-specific settings (tab = 4 spaces)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
    vim.bo.shiftwidth = 4
  end,
})

-- Diffing options
vim.opt.fillchars:append({ diff = " " }) -- ╱
