local M = {}

function M.setup_buffer_browser()
  if M.bb_next then
    return M.bb_next, M.bb_prev
  end

  local function next_buf()
    require("buffer_browser").next()
  end

  local function prev_buf()
    require("buffer_browser").prev()
  end

  M.bb_next, M.bb_prev = RepeatablePairs.track_pair(next_buf, prev_buf)

  return M.bb_next, M.bb_prev
end

return M
