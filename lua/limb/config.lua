local M = {}

---@class limb.FloatOpts
---@field border? string
---@field width? fun(): integer
---@field height? fun(line_count: integer): integer

---@class limb.Config
---@field binary string
---@field on_change_dir false|fun(path: string)
---@field switch_after_add boolean
---@field confirm_destructive boolean
---@field notify { title: string }
---@field float limb.FloatOpts

---@type limb.Config
local defaults = {
  binary = "limb",
  on_change_dir = function(_path)
    local ok, snacks = pcall(require, "snacks")
    if ok and snacks.picker then
      snacks.picker.files()
    end
  end,
  switch_after_add = true,
  confirm_destructive = true,
  notify = { title = "limb" },
  float = {
    border = "rounded",
    width = function()
      return math.max(60, math.min(120, vim.o.columns - 10))
    end,
    height = function(n)
      return math.max(1, math.min(n + 2, vim.o.lines - 6))
    end,
  },
}

---@type limb.Config
M.values = vim.deepcopy(defaults)

local VALID_KEYS = {
  binary = true,
  on_change_dir = true,
  switch_after_add = true,
  confirm_destructive = true,
  notify = true,
  float = true,
}

---@param opts? table
function M.setup(opts)
  opts = opts or {}
  for k, _ in pairs(opts) do
    if not VALID_KEYS[k] then
      vim.notify("limb.setup: unknown key '" .. k .. "'", vim.log.levels.WARN, { title = "limb" })
    end
  end
  M.values = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)
end

return M
