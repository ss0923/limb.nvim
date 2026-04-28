local config = require("limb.config")
local float = require("limb.float")
local util = require("limb.util")

local M = {}

---@class limb.Entry
---@field path string
---@field name string
---@field repo? string
---@field branch? string
---@field head? string
---@field bare? boolean
---@field locked? boolean
---@field locked_reason? string
---@field prunable? boolean
---@field prunable_reason? string

---@param e limb.Entry
---@return string
local function repo_name(e)
  return e.repo or ""
end

---@param e limb.Entry
---@return string
local function branch_label(e)
  if e.branch then
    return e.branch
  end
  if e.head then
    return "(detached " .. string.sub(e.head, 1, 8) .. ")"
  end
  return "(detached)"
end

---@param e limb.Entry
---@return string
local function left_label(e)
  local repo = repo_name(e)
  local name = e.name or ""
  if repo ~= "" then
    return repo .. "/" .. name
  end
  return name
end

---@param list limb.Entry[]
---@return limb.Entry[]
local function selectable(list)
  local out = {}
  for _, e in ipairs(list) do
    if not e.bare and not e.prunable then
      table.insert(out, e)
    end
  end
  return out
end

---@param list limb.Entry[]
---@return integer
local function compute_left_width(list)
  local max = 0
  for _, e in ipairs(list) do
    local w = vim.fn.strdisplaywidth(left_label(e))
    if w > max then
      max = w
    end
  end
  return max
end

---@param e limb.Entry
---@param left_width integer
---@return string
local function format_row(e, left_width)
  local left = left_label(e)
  local pad = left_width - vim.fn.strdisplaywidth(left)
  if pad < 0 then
    pad = 0
  end
  local marker = e.locked and "  [locked]" or ""
  return left .. string.rep(" ", pad) .. "  " .. branch_label(e) .. marker
end

---@param all boolean
---@param on_done fun(entries: limb.Entry[]?, err: string?)
local function fetch_entries(all, on_done)
  local args = { "--json", "list" }
  if all then
    table.insert(args, "--all")
  end
  util.run_async(args, function(result)
    if result.code ~= 0 then
      return on_done(nil, util.err_message(result))
    end
    local decoded, err = util.decode_json(result)
    if err then
      return on_done(nil, "limb: " .. err)
    end
    if type(decoded) ~= "table" then
      return on_done(nil, "limb: expected list, got " .. type(decoded))
    end
    on_done(decoded, nil)
  end)
end

---@param path string
local function goto_path(path)
  vim.cmd.cd(path)
  util.run_sync({ "mark-cd", path })
  if config.values.on_change_dir then
    config.values.on_change_dir(path)
  end
end

---@class limb.PickOpts
---@field all? boolean   -- default true; cross-repo
---@field fetch? boolean -- default false; runs `limb update --fetch-only` before picking

---@param opts? limb.PickOpts
function M.pick(opts)
  opts = opts or {}
  local all = opts.all ~= false
  local fetch = opts.fetch == true

  local function open_picker()
    fetch_entries(all, function(decoded, err)
      if err then
        util.notify(err, vim.log.levels.ERROR)
        return
      end
      local list = selectable(decoded or {})
      if #list == 0 then
        util.notify("no selectable worktrees", vim.log.levels.WARN)
        return
      end
      local left_width = compute_left_width(list)
      local items = {}
      local by_display = {}
      for _, e in ipairs(list) do
        local display = format_row(e, left_width)
        table.insert(items, display)
        by_display[display] = e.path
      end
      vim.ui.select(items, { prompt = "worktrees" }, function(choice)
        if choice then
          goto_path(by_display[choice])
        end
      end)
    end)
  end

  if not fetch then
    return open_picker()
  end

  local update_args = { "update", "--fetch-only", "-y", "-q" }
  if all then
    table.insert(update_args, "--all")
  end
  util.notify("fetching remotes...")
  util.run_async(update_args, function(result)
    if result.code ~= 0 then
      util.notify("fetch failed; opening picker with stale data", vim.log.levels.WARN)
    end
    open_picker()
  end)
end

---@class limb.StatusOpts
---@field all? boolean
---@field fetch? boolean -- passes --fetch so `limb status` runs `git fetch` per repo first

---@param opts? limb.StatusOpts
function M.status(opts)
  opts = opts or {}
  local fetch = opts.fetch == true

  local function with_fetch(args)
    if fetch then
      table.insert(args, "--fetch")
    end
    return args
  end

  local function show(stdout)
    float.open({
      lines = float.lines_from(stdout),
      title = "status",
      filetype = "limbstatus",
    })
  end

  if opts.all then
    util.run_async(with_fetch({ "status", "--all" }), function(result)
      if result.code == 0 then
        show(result.stdout or "")
      else
        util.notify_err(result)
      end
    end)
    return
  end

  util.run_async(with_fetch({ "status" }), function(result)
    if result.code == 0 then
      show(result.stdout or "")
      return
    end
    if (result.stderr or ""):match("not a git repository") then
      util.run_async(with_fetch({ "status", "--all" }), function(r2)
        if r2.code == 0 then
          show(r2.stdout or "")
        else
          util.notify_err(r2)
        end
      end)
      return
    end
    util.notify_err(result)
  end)
end

---@class limb.AddOpts
---@field name? string
---@field base? string
---@field switch? boolean

---@param opts? limb.AddOpts
function M.add(opts)
  opts = opts or {}
  local switch = opts.switch
  if switch == nil then
    switch = config.values.switch_after_add
  end

  local function execute(name, base)
    local args = { "--json", "add", name }
    if base and base ~= "" then
      table.insert(args, base)
    end
    util.run_async(args, function(result)
      if result.code ~= 0 then
        util.notify_err(result)
        return
      end
      local decoded, derr = util.decode_json(result)
      if derr or type(decoded) ~= "table" then
        util.notify("added " .. name)
        return
      end
      local path = decoded.path
      util.notify("added " .. (decoded.name or name) .. (path and (" at " .. path) or ""))
      if switch and path then
        goto_path(path)
      end
    end)
  end

  if opts.name and opts.name ~= "" then
    execute(opts.name, opts.base)
    return
  end
  util.input("worktree name: ", nil, function(name)
    if not name or name == "" then
      return
    end
    util.input("base (optional): ", nil, function(base)
      execute(name, base)
    end)
  end)
end

---@param on_done fun(name: string?)
local function pick_local_worktree(on_done)
  fetch_entries(false, function(list, err)
    if err then
      util.notify(err, vim.log.levels.ERROR)
      return on_done(nil)
    end
    local items = {}
    local by_display = {}
    for _, e in ipairs(selectable(list or {})) do
      local display = e.name or ""
      if e.locked then
        display = display .. "  [locked]"
      end
      table.insert(items, display)
      by_display[display] = e.name
    end
    if #items == 0 then
      util.notify("no removable worktrees", vim.log.levels.WARN)
      return on_done(nil)
    end
    vim.ui.select(items, { prompt = "worktree" }, function(choice)
      on_done(choice and by_display[choice] or nil)
    end)
  end)
end

---@class limb.RemoveOpts
---@field name? string
---@field force? boolean

---@param opts? limb.RemoveOpts
function M.remove(opts)
  opts = opts or {}
  local force = opts.force or false

  local function execute(name)
    local args = { "remove", name }
    if force then
      table.insert(args, "--force")
    end
    util.run_async(args, function(result)
      if result.code == 0 then
        util.notify("removed " .. name)
      else
        util.notify_err(result)
      end
    end)
  end

  local function maybe_confirm(name)
    if force or not config.values.confirm_destructive then
      return execute(name)
    end
    util.confirm("remove worktree '" .. name .. "'?", function(yes)
      if yes then
        execute(name)
      end
    end)
  end

  if opts.name and opts.name ~= "" then
    return maybe_confirm(opts.name)
  end
  pick_local_worktree(function(name)
    if name then
      maybe_confirm(name)
    end
  end)
end

---@class limb.UpdateOpts
---@field all? boolean         -- fetch + ff across every repo under projects.roots
---@field ff_only? boolean
---@field fetch_only? boolean

---@param opts? limb.UpdateOpts
function M.update(opts)
  opts = opts or {}
  local args = { "update" }
  if opts.all then
    table.insert(args, "--all")
  end
  if opts.ff_only then
    table.insert(args, "--ff-only")
  end
  if opts.fetch_only then
    table.insert(args, "--fetch-only")
  end
  util.notify("updating worktrees...")
  util.run_async(args, function(result)
    if result.code ~= 0 then
      util.notify_err(result)
      return
    end
    float.open({
      lines = float.lines_from(result.stdout or ""),
      title = "update",
      filetype = "limbupdate",
    })
  end)
end

---@class limb.CleanOpts
---@field force? boolean

---@param opts? limb.CleanOpts
function M.clean(opts)
  opts = opts or {}
  local function apply()
    util.run_async({ "clean", "--yes" }, function(result)
      if result.code == 0 then
        util.notify("clean complete")
        if (result.stdout or "") ~= "" then
          float.open({
            lines = float.lines_from(result.stdout),
            title = "clean",
            filetype = "limbclean",
          })
        end
      else
        util.notify_err(result)
      end
    end)
  end

  if opts.force or not config.values.confirm_destructive then
    return apply()
  end

  util.run_async({ "--json", "clean", "--dry-run" }, function(result)
    if result.code ~= 0 then
      util.notify_err(result)
      return
    end
    local decoded, derr = util.decode_json(result)
    if derr or type(decoded) ~= "table" then
      util.notify("limb: clean dry-run returned malformed json", vim.log.levels.ERROR)
      return
    end
    local candidates = decoded.candidates or {}
    if #candidates == 0 then
      util.notify("nothing to clean")
      return
    end
    local lines = { "would remove " .. #candidates .. " worktree(s):", "" }
    for _, c in ipairs(candidates) do
      local name = type(c) == "table" and (c.name or c.path or vim.inspect(c)) or tostring(c)
      table.insert(lines, "  - " .. name)
    end
    table.insert(lines, "")
    table.insert(lines, "press 'a' to apply, 'q' to dismiss")
    float.open({
      lines = lines,
      title = "clean (dry-run)",
      filetype = "limbclean",
      keymaps = {
        a = function()
          vim.cmd("close")
          apply()
        end,
      },
    })
  end)
end

local PASSTHROUGH_COMPLETIONS = {
  "config",
  "doctor",
  "lock",
  "migrate",
  "prune",
  "rename",
  "repair",
  "setup",
  "unlock",
}

---@param fargs string[]
function M.dispatch(fargs)
  if #fargs == 0 then
    util.notify("usage: :Limb <subcommand> [args...]", vim.log.levels.WARN)
    return
  end
  util.run_async(fargs, function(result)
    local stdout = result.stdout or ""
    local stderr = result.stderr or ""
    if result.code ~= 0 then
      util.notify_err(result)
      return
    end
    local body = stdout
    if body == "" then
      body = stderr
    end
    if body == "" then
      util.notify("limb " .. table.concat(fargs, " ") .. ": ok")
      return
    end
    float.open({
      lines = float.lines_from(body),
      title = "limb " .. fargs[1],
      filetype = "limboutput",
    })
  end)
end

---@param arg_lead string
---@param cmd_line string
---@return string[]
function M.complete(arg_lead, cmd_line)
  local trimmed = cmd_line:gsub("^%s*Limb%s*", "")
  if not trimmed:find(" ") then
    local out = {}
    for _, sub in ipairs(PASSTHROUGH_COMPLETIONS) do
      if sub:find(arg_lead, 1, true) == 1 then
        table.insert(out, sub)
      end
    end
    return out
  end
  return {}
end

---@param opts? table
function M.setup(opts)
  config.setup(opts)
end

return M
