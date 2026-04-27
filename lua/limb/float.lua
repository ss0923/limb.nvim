local config = require("limb.config")

local M = {}

---@class limb.FloatRequest
---@field lines string[]
---@field title string
---@field filetype? string
---@field keymaps? table<string, string|function>

---@param raw string
---@return string[]
function M.lines_from(raw)
  local lines = vim.split(raw or "", "\n", { trimempty = false })
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end
  if #lines == 0 then
    lines = { "(no output)" }
  end
  return lines
end

---@param req limb.FloatRequest
---@return integer buf, integer win
function M.open(req)
  local lines = req.lines
  if #lines == 0 then
    lines = { "(no output)" }
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  if req.filetype then
    vim.bo[buf].filetype = req.filetype
  end
  local width = config.values.float.width()
  local height = config.values.float.height(#lines)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = config.values.float.border,
    title = " " .. req.title .. " ",
    title_pos = "center",
  })
  local keymaps = req.keymaps or {}
  if keymaps.q == nil then
    keymaps.q = "<cmd>close<cr>"
  end
  if keymaps["<esc>"] == nil then
    keymaps["<esc>"] = "<cmd>close<cr>"
  end
  for lhs, rhs in pairs(keymaps) do
    vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true })
  end
  return buf, win
end

return M
