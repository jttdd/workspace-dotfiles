local bufnr = vim.api.nvim_get_current_buf()

-- Gitsigns applies its initial width after the FileType event finishes.
vim.schedule(function()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- strdisplaywidth counts repeated breakindent while the pane is still narrow.
  local widths = {}
  for row, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    widths[row] = vim.fn.strwidth(line)
  end

  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(bufnr, -1, 0, -1, { details = true })) do
    local row, details = mark[2] + 1, mark[4]
    if widths[row] and details.virt_text
      and (details.virt_text_pos == "inline" or details.virt_text_pos == "right_align") then
      for _, chunk in ipairs(details.virt_text) do
        widths[row] = widths[row] + vim.fn.strwidth(chunk[1])
      end
      if details.virt_text_pos == "right_align" then
        widths[row] = widths[row] + 1
      end
    end
  end

  local width = 0
  for _, line_width in ipairs(widths) do
    width = math.max(width, line_width)
  end

  local editor_width = math.max(vim.o.winwidth, vim.o.winminwidth, 1)
  local available_width = math.max(1, vim.o.columns - editor_width - 1)
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    vim.api.nvim_win_set_width(winid, math.min(width + 2, available_width))
  end
end)
