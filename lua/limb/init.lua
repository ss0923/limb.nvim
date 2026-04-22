local M = {}

---@class limb.Entry
---@field path string
---@field name string
---@field repo? string
---@field branch? string
---@field bare? boolean

---@return limb.Entry[]? entries
---@return string? err
local function entries()
  local result = vim.system({ "limb", "--json", "list", "--all" }, { text = true }):wait()
  if result.code ~= 0 then
    return nil, "limb: " .. (result.stderr or result.stdout or "unknown error")
  end
  local ok, decoded = pcall(vim.json.decode, result.stdout or "")
  if not ok then
    return nil, "limb: json decode failed"
  end
  return decoded, nil
end

---@param list limb.Entry[]
---@return limb.Entry[]
local function selectable(list)
  local out = {}
  for _, e in ipairs(list) do
    if not e.bare then
      table.insert(out, e)
    end
  end
  return out
end

---@param e limb.Entry
---@return string
local function repo_name(e)
  if e.repo and e.repo ~= vim.NIL then
    return e.repo
  end
  return ""
end

---@param e limb.Entry
---@param widths { left: integer }
---@return string
local function format_row(e, widths)
  local repo = repo_name(e)
  local name = e.name or ""
  local branch = (e.branch and e.branch ~= vim.NIL) and e.branch or "(detached)"
  local left = repo ~= "" and (repo .. "/" .. name) or name
  local pad = widths.left - #left
  if pad < 0 then
    pad = 0
  end
  return left .. string.rep(" ", pad) .. "  " .. branch
end

---@param list limb.Entry[]
---@return { left: integer }
local function compute_widths(list)
  local max_left = 0
  for _, e in ipairs(list) do
    local repo = repo_name(e)
    local left = repo ~= "" and (repo .. "/" .. (e.name or "")) or (e.name or "")
    if #left > max_left then
      max_left = #left
    end
  end
  return { left = max_left }
end

---@param path string
local function goto_path(path)
  vim.cmd.cd(path)
  vim.system({ "limb", "mark-cd", path }):wait()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.picker then
    snacks.picker.files()
  end
end

---Opens a selectable list of every worktree across configured projects.
function M.pick()
  local all, err = entries()
  if err then
    vim.notify(err, vim.log.levels.ERROR, { title = "limb" })
    return
  end
  local list = selectable(all or {})
  if #list == 0 then
    vim.notify("no selectable worktrees", vim.log.levels.WARN, { title = "limb" })
    return
  end

  local widths = compute_widths(list)
  local items = {}
  local by_display = {}
  for _, e in ipairs(list) do
    local display = format_row(e, widths)
    table.insert(items, display)
    by_display[display] = e.path
  end
  vim.ui.select(items, { prompt = "worktrees" }, function(choice)
    if choice then
      goto_path(by_display[choice])
    end
  end)
end

---Opens `limb status` output in a centered floating window.
function M.status()
  local result = vim.system({ "limb", "status" }, { text = true }):wait()
  if result.code ~= 0 then
    local msg = result.stderr or result.stdout or "limb status failed"
    vim.notify(msg, vim.log.levels.ERROR, { title = "limb" })
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = vim.split(result.stdout or "", "\n", { trimempty = false })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "limbstatus"
  local width = math.max(60, math.min(120, vim.o.columns - 10))
  local height = math.min(#lines + 2, vim.o.lines - 6)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = "rounded",
    title = " status ",
    title_pos = "center",
  })
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
end

---@class limb.Opts
---Reserved for future configuration options.

---Optional entry point for plugin-manager setup blocks.
---Commands are registered from `plugin/limb.lua` on load; calling this is not required.
---@param _opts? limb.Opts
function M.setup(_opts) end

return M
