local config = require("limb.config")

local M = {}

local INSTALL_URL = "https://github.com/ss0923/limb#install"

---@param cmd string[]
---@return vim.SystemCompleted
local function run(cmd)
  return vim.system(cmd, { text = true }):wait()
end

---@param args string[]
---@return string[]
local function with_binary(args)
  local out = { config.values.binary }
  for _, a in ipairs(args) do
    table.insert(out, a)
  end
  return out
end

function M.check()
  local health = vim.health
  health.start("limb.nvim")

  local binary = config.values.binary
  if vim.fn.executable(binary) ~= 1 then
    health.error("`" .. binary .. "` not found on $PATH", { "Install limb: " .. INSTALL_URL })
    return
  end

  local version = run(with_binary({ "--version" }))
  if version.code == 0 then
    health.ok("limb: " .. vim.trim(version.stdout or ""))
  else
    health.error("`" .. binary .. " --version` failed: " .. vim.trim(version.stderr or ""))
    return
  end

  if vim.env.TMUX and vim.env.TMUX ~= "" then
    health.ok("inside tmux (TMUX_PANE=" .. (vim.env.TMUX_PANE or "?") .. ")")
  else
    health.info("not inside tmux. Cwd propagation on exit is disabled")
  end

  local cfg = run(with_binary({ "--json", "config" }))
  if cfg.code == 0 then
    local ok, decoded =
      pcall(vim.json.decode, cfg.stdout or "", { luanil = { object = true, array = true } })
    if ok and type(decoded) == "table" and type(decoded.global) == "table" then
      local roots = decoded.global.projects_roots or {}
      if #roots == 0 then
        health.warn("projects.roots is empty. :LimbPick will return no entries.", {
          "Set projects.roots in ~/.config/limb/config.toml.",
        })
      else
        health.ok("projects.roots: " .. #roots .. " configured")
      end
    end
  end

  local doctor = run(with_binary({ "doctor" }))
  if doctor.code == 0 then
    health.ok("limb doctor:\n" .. vim.trim(doctor.stdout or ""))
  else
    health.warn("limb doctor reported issues:\n" .. vim.trim(doctor.stdout or doctor.stderr or ""))
  end
end

return M
