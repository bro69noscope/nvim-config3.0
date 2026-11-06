local M = {}

M.setup = function()
  -- For reference, default highlight group values
  -- DiffviewFilePanelInsertions = {
  --   default = true,
  --   link = "diffAdded",
  -- }
  --
  -- diffAdded = {
  --   bg = "#273849",
  --   fg = "#B8DB87",
  -- }
  -- DiffviewFilePanelDeletions = {
  --   default = true,
  --   link = "diffRemoved",
  -- }
  --
  -- diffRemoved = {
  --   bg = "#3A273A",
  --   fg = "#E26A75",
  -- }
  -- DiffviewStatusModified = {
  --   default = true,
  --   link = "diffChanged",
  -- }
  --
  -- DiffviewStatusCopied = {
  --   default = true,
  --   link = "diffChanged",
  -- }
  --
  -- DiffviewStatusRenamed = {
  --   default = true,
  --   link = "diffChanged",
  -- }
  --
  -- diffChanged = {
  --   bg = "#252A3F",
  --   fg = "#7CA1F2",
  -- }

  vim.api.nvim_set_hl(0, "DiffviewFilePanelInsertions", { fg = "#B8DB87", bg = "NONE" })
  vim.api.nvim_set_hl(0, "DiffviewStatusAdded", { fg = "#B8DB87", bg = "NONE" })
  vim.api.nvim_set_hl(0, "DiffviewStatusUntracked", { fg = "#B8DB87", bg = "NONE" })

  vim.api.nvim_set_hl(0, "DiffviewFilePanelDeletions", { fg = "#E26A75", bg = "NONE" })
  vim.api.nvim_set_hl(0, "DiffviewStatusBroken", { fg = "#E26A75", bg = "NONE" })
  vim.api.nvim_set_hl(0, "DiffviewStatusDeleted", { fg = "#E26A75", bg = "NONE" })
  vim.api.nvim_set_hl(0, "DiffviewStatusUnknown", { fg = "#E26A75", bg = "NONE" })

  vim.api.nvim_set_hl(0, "DiffviewStatusModified", { fg = "#7CA1F2", bg = "NONE" })
  vim.api.nvim_set_hl(0, "DiffviewStatusCopied", { fg = "#7CA1F2", bg = "NONE" })
  vim.api.nvim_set_hl(0, "DiffviewStatusRenamed", { fg = "#7CA1F2", bg = "NONE" })
  vim.api.nvim_set_hl(0, "DiffviewStatusUnmerged", { fg = "#7CA1F2", bg = "NONE" })
  vim.api.nvim_set_hl(0, "DiffviewStatusTypeChange", { fg = "#7CA1F2", bg = "NONE" })

  vim.api.nvim_set_hl(0, "DiffviewFilePanelTitle", { link = "@markup.heading.1.markdown" })
  vim.api.nvim_set_hl(0, "DiffviewFilePanelCounter", { link = "@markup.heading.1.markdown" })
  vim.api.nvim_set_hl(0, "DiffviewFilePanelSelected", { link = "@variable.parameter" })
end

return M
