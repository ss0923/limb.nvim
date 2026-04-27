local config = require("limb.config")

local M = {}

---@param result vim.SystemCompleted
---@return string
function M.err_message(result)
  local msg = vim.trim(result.stderr or result.stdout or "")
  if msg == "" then
    msg = "unknown error"
  end
  return "limb: " .. msg
end

---@param msg string
---@param level? integer
function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = config.values.notify.title })
end

---@param result vim.SystemCompleted
function M.notify_err(result)
  M.notify(M.err_message(result), vim.log.levels.ERROR)
end

---@param args string[]
---@return string[]
function M.cmd(args)
  local out = { config.values.binary }
  for _, a in ipairs(args) do
    table.insert(out, a)
  end
  return out
end

---@param args string[]
---@param on_done fun(result: vim.SystemCompleted)
function M.run_async(args, on_done)
  vim.system(M.cmd(args), { text = true }, vim.schedule_wrap(on_done))
end

---@param args string[]
---@return vim.SystemCompleted
function M.run_sync(args)
  return vim.system(M.cmd(args), { text = true }):wait()
end

---@param result vim.SystemCompleted
---@return any?, string?
function M.decode_json(result)
  local ok, decoded =
    pcall(vim.json.decode, result.stdout or "", { luanil = { object = true, array = true } })
  if not ok then
    return nil, "json decode failed"
  end
  return decoded, nil
end

---@param prompt string
---@param default? string
---@param on_input fun(value: string?)
function M.input(prompt, default, on_input)
  vim.ui.input({ prompt = prompt, default = default }, on_input)
end

---@param prompt string
---@param on_confirm fun(yes: boolean)
function M.confirm(prompt, on_confirm)
  vim.ui.input({ prompt = prompt .. " [y/N] " }, function(value)
    local v = (value or ""):lower()
    on_confirm(v == "y" or v == "yes")
  end)
end

return M
