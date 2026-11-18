local M = {}

-- Extmarks in this namespace keep the references of the word that started the motion.
-- Extmarks follow buffer edits, thus the positions stay correct.
local ns = vim.api.nvim_create_namespace("snacks_words_repeat")

function M.snapshot()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

  for _, word in ipairs(Snacks.words.get()) do
    vim.api.nvim_buf_set_extmark(0, ns, word.from[1] - 1, word.from[2], {
      end_row = word.to[1] - 1,
      end_col = word.to[2],
    })
  end
end

--- @param count integer
local function jump(count)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1

  local marks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })

  local targets = {}
  for _, mark in ipairs(marks) do
    local m_row, m_col, details = mark[2], mark[3], mark[4]

    local after = m_row > row or (m_row == row and m_col > col)
    local before = details.end_row < row or (details.end_row == row and details.end_col <= col)

    if (count > 0 and after) or (count < 0 and before) then
      table.insert(targets, { m_row + 1, m_col })
    end
  end

  local target = count > 0 and targets[count] or targets[#targets + count + 1]
  if not target then
    return
  end

  vim.cmd.normal({ "m`", bang = true })
  vim.api.nvim_win_set_cursor(0, target)
  vim.cmd.normal({ "zv", bang = true })
end

function M.setup_snacks_words()
  if M.next_ref then
    return M.next_ref, M.prev_ref
  end

  local function next_ref()
    jump(vim.v.count1)
  end

  local function prev_ref()
    jump(-vim.v.count1)
  end

  M.next_ref, M.prev_ref = RepeatablePairs.track_pair(next_ref, prev_ref)

  return M.next_ref, M.prev_ref
end

return M
