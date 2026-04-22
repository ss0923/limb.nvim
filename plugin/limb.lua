if vim.g.loaded_limb == 1 then
  return
end
vim.g.loaded_limb = 1

vim.api.nvim_create_user_command("LimbPick", function()
  require("limb").pick()
end, { desc = "Pick a git worktree across configured projects." })

vim.api.nvim_create_user_command("LimbStatus", function()
  require("limb").status()
end, { desc = "Show limb status in a floating window." })
