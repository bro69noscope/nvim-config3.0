vim.keymap.set("n", "g;", function()
  local word = vim.fn.expand("<cWORD>"):match("%$[%w_:]+") or vim.fn.expand("<cword>")
  local start = vim.fn.search([[^\s*\(function\|filter\)\s]], "bnW")
  if start == 0 then
    start = 1
  end
  vim.fn.cursor(start, 1)
  vim.fn.search([[\V]] .. vim.fn.escape(word, [[\]]) .. [[\>]], "W")
end, { buffer = true, desc = "goto first occurence in function" })
