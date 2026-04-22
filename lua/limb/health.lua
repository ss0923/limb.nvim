local M = {}

local INSTALL_URL = "https://github.com/ss0923/limb#install"

---@param cmd string[]
---@return vim.SystemCompleted
local function run(cmd)
  return vim.system(cmd, { text = true }):wait()
end

---Entry point for `:checkhealth limb`.
function M.check()
  local health = vim.health
  health.start("limb.nvim")

  if vim.fn.executable("limb") ~= 1 then
    health.error("`limb` binary not found on $PATH", { "Install limb: " .. INSTALL_URL })
    return
  end

  local version = run({ "limb", "--version" })
  if version.code == 0 then
    health.ok("limb: " .. vim.trim(version.stdout or ""))
  else
    health.error("`limb --version` failed: " .. vim.trim(version.stderr or ""))
    return
  end

  if vim.env.TMUX and vim.env.TMUX ~= "" then
    health.ok("inside tmux (TMUX_PANE=" .. (vim.env.TMUX_PANE or "?") .. ")")
  else
    health.info("not inside tmux. Cwd propagation on exit is disabled")
  end

  local doctor = run({ "limb", "doctor" })
  if doctor.code == 0 then
    health.ok("limb doctor:\n" .. vim.trim(doctor.stdout or ""))
  else
    local msg = vim.trim(doctor.stdout or doctor.stderr or "")
    health.warn("limb doctor reported issues:\n" .. msg)
  end
end

return M
