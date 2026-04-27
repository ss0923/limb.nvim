vim.opt.rtp:prepend(vim.fn.fnamemodify(vim.fn.resolve(debug.getinfo(1).source:sub(2)), ":h:h"))

local failures = {}

---@param msg string
---@param ok boolean
local function check(msg, ok)
  if not ok then
    table.insert(failures, msg)
  end
end

---@param actual any
---@param expected any
---@param msg string
local function eq(msg, actual, expected)
  if not vim.deep_equal(actual, expected) then
    table.insert(
      failures,
      ("%s\n  expected: %s\n  actual:   %s"):format(msg, vim.inspect(expected), vim.inspect(actual))
    )
  end
end

local ORIGINAL_SYSTEM = vim.system
local function mock_system(canned)
  vim.system = function(cmd, _opts, on_done)
    local key = table.concat(cmd, " ")
    local result = canned[key] or { code = 1, stderr = "no mock for: " .. key }
    if on_done then
      vim.schedule(function()
        on_done(result)
      end)
    end
    return {
      wait = function()
        return result
      end,
    }
  end
end

local function restore_system()
  vim.system = ORIGINAL_SYSTEM
end

local ORIGINAL_NOTIFY = vim.notify
local function silence_notify()
  vim.notify = function(_msg, _level, _opts) end
end
local function restore_notify()
  vim.notify = ORIGINAL_NOTIFY
end

local function capture_notify()
  local captured = {}
  vim.notify = function(msg, level, _opts)
    table.insert(captured, { msg = msg, level = level })
  end
  return captured
end

local function run(name, fn)
  local before_fail_count = #failures
  local ok, err = pcall(fn)
  if not ok then
    table.insert(failures, name .. ": " .. tostring(err))
  end
  restore_system()
  restore_notify()
  if #failures == before_fail_count then
    io.stdout:write("ok  " .. name .. "\n")
  else
    io.stdout:write("FAIL " .. name .. "\n")
  end
end

local function require_fresh(name)
  for k, _ in pairs(package.loaded) do
    if k == name or k:find("^" .. name .. "%.") then
      package.loaded[k] = nil
    end
  end
  return require(name)
end

run("module loads", function()
  local limb = require_fresh("limb")
  check("limb is table", type(limb) == "table")
  check("pick", type(limb.pick) == "function")
  check("status", type(limb.status) == "function")
  check("add", type(limb.add) == "function")
  check("remove", type(limb.remove) == "function")
  check("update", type(limb.update) == "function")
  check("clean", type(limb.clean) == "function")
  check("dispatch", type(limb.dispatch) == "function")
  check("complete", type(limb.complete) == "function")
  check("setup", type(limb.setup) == "function")
end)

run("plugin/limb.lua registers commands", function()
  vim.g.loaded_limb = nil
  vim.cmd("runtime plugin/limb.lua")
  local cmds = vim.api.nvim_get_commands({})
  for _, name in ipairs({
    "Limb",
    "LimbPick",
    "LimbStatus",
    "LimbAdd",
    "LimbRemove",
    "LimbUpdate",
    "LimbClean",
  }) do
    check(name .. " registered", cmds[name] ~= nil)
  end
end)

run("setup defaults and merge", function()
  local limb = require_fresh("limb")
  local cfg = require("limb.config")
  limb.setup()
  eq("default binary", cfg.values.binary, "limb")
  eq("default switch_after_add", cfg.values.switch_after_add, true)
  eq("default confirm_destructive", cfg.values.confirm_destructive, true)
  limb.setup({ binary = "/opt/limb", confirm_destructive = false })
  eq("custom binary", cfg.values.binary, "/opt/limb")
  eq("custom confirm_destructive", cfg.values.confirm_destructive, false)
  eq("non-overridden defaults survive", cfg.values.switch_after_add, true)
  limb.setup()
end)

run("setup warns on unknown key", function()
  local limb = require_fresh("limb")
  local notes = capture_notify()
  limb.setup({ unknownKey = true })
  local found = false
  for _, n in ipairs(notes) do
    if n.msg:find("unknown key 'unknownKey'", 1, true) then
      found = true
    end
  end
  check("unknown-key warning emitted", found)
  limb.setup()
end)

run("complete returns subcommands and filters", function()
  local limb = require_fresh("limb")
  local all = limb.complete("", "Limb ")
  check("complete returns >= 5 subcommands", #all >= 5)
  local filtered = limb.complete("lo", "Limb lo")
  eq("prefix 'lo' narrows to 'lock'", filtered, { "lock" })
  local empty = limb.complete("zzzz", "Limb zzzz")
  eq("nonexistent prefix returns empty", empty, {})
end)

run("pick formats rows and filters bare/prunable", function()
  local limb = require_fresh("limb")
  limb.setup()
  silence_notify()
  mock_system({
    ["limb --json list --all"] = {
      code = 0,
      stdout = vim.json.encode({
        { repo = "alpha", path = "/a/b", name = "b1", bare = true },
        { repo = "alpha", path = "/a/b1", name = "b1", branch = "main" },
        { repo = "alpha", path = "/a/long-feature", name = "long-feature", branch = "feat/x" },
        { repo = "beta", path = "/b/dangling", name = "dangling", prunable = true },
        { repo = "beta", path = "/b/locked", name = "locked", branch = "lk", locked = true },
        {
          repo = "beta",
          path = "/b/det",
          name = "det",
          branch = vim.NIL,
          head = "deadbeefcafebabe",
        },
      }),
    },
  })
  local items
  vim.ui.select = function(it, _opts, _cb)
    items = it
  end
  limb.pick()
  vim.wait(500, function()
    return items ~= nil
  end)
  check("pick presented items", items ~= nil)
  if items then
    eq("bare and prunable filtered (4 of 6 remain)", #items, 4)
    local first = items[1] or ""
    check("first row aligned to widest left col", first:match("^alpha/b1%s+main$") ~= nil)
    local detached = items[#items] or ""
    check("detached uses short sha", detached:find("(detached deadbeef)", 1, true) ~= nil)
    local locked_row
    for _, it in ipairs(items) do
      if it:find("[locked]", 1, true) then
        locked_row = it
      end
    end
    check("locked row shows [locked]", locked_row ~= nil)
  end
end)

run("status falls back to --all outside repo", function()
  local limb = require_fresh("limb")
  limb.setup()
  silence_notify()
  local commands = {}
  mock_system({
    ["limb status"] = {
      code = 1,
      stderr = "error: not a git repository at /tmp; try: cd into a repo or pass --repo <path>",
    },
    ["limb status --all"] = { code = 0, stdout = "REPO  NAME  BRANCH\nfoo  main  main\n" },
  })
  local original_system = vim.system
  vim.system = function(cmd, opts, on_done)
    table.insert(commands, table.concat(cmd, " "))
    return original_system(cmd, opts, on_done)
  end
  limb.status()
  vim.wait(500, function()
    return #commands >= 2
  end)
  eq("attempted plain status first", commands[1], "limb status")
  eq("fell back to --all", commands[2], "limb status --all")
end)

run("status bang skips fallback path", function()
  local limb = require_fresh("limb")
  limb.setup()
  silence_notify()
  local commands = {}
  mock_system({
    ["limb status --all"] = { code = 0, stdout = "REPO  NAME\n" },
  })
  local original_system = vim.system
  vim.system = function(cmd, opts, on_done)
    table.insert(commands, table.concat(cmd, " "))
    return original_system(cmd, opts, on_done)
  end
  limb.status({ all = true })
  vim.wait(500, function()
    return #commands >= 1
  end)
  eq("bang ran --all directly", commands[1], "limb status --all")
  eq("bang did not run plain status", commands[2], nil)
end)

run("dispatch shells out and renders", function()
  local limb = require_fresh("limb")
  limb.setup()
  silence_notify()
  mock_system({
    ["limb doctor"] = { code = 0, stdout = "ok\n" },
  })
  limb.dispatch({ "doctor" })
  vim.wait(500, function()
    return vim.bo.filetype == "limboutput"
  end)
  eq("dispatch opened limboutput float", vim.bo.filetype, "limboutput")
end)

if #failures > 0 then
  io.stderr:write("\n")
  for _, f in ipairs(failures) do
    io.stderr:write("FAIL: " .. f .. "\n")
  end
  io.stderr:write(("\n%d failure(s)\n"):format(#failures))
  os.exit(1)
else
  io.stdout:write("\nall tests passed\n")
  os.exit(0)
end
