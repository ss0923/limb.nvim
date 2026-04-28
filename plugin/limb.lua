if vim.g.loaded_limb == 1 then
  return
end
vim.g.loaded_limb = 1

vim.api.nvim_create_user_command("LimbPick", function(opts)
  require("limb").pick({ fetch = opts.bang })
end, {
  desc = "Pick a git worktree across configured projects. Bang = --fetch first.",
  bang = true,
})

vim.api.nvim_create_user_command("LimbStatus", function(opts)
  require("limb").status({ all = opts.bang })
end, { desc = "Show limb status. Bang forces --all.", bang = true })

vim.api.nvim_create_user_command("LimbAdd", function(opts)
  require("limb").add({
    name = opts.fargs[1],
    base = opts.fargs[2],
    switch = opts.bang or nil,
  })
end, {
  desc = "Add a worktree. :LimbAdd [name] [base]; bang switches into it.",
  nargs = "*",
  bang = true,
})

vim.api.nvim_create_user_command("LimbRemove", function(opts)
  require("limb").remove({ name = opts.fargs[1], force = opts.bang })
end, {
  desc = "Remove a worktree. :LimbRemove [name]; bang skips confirm + uses --force.",
  nargs = "?",
  bang = true,
})

vim.api.nvim_create_user_command("LimbUpdate", function(opts)
  require("limb").update({ ff_only = opts.bang })
end, {
  desc = "Fetch + fast-forward worktrees. Bang = --ff-only (skip fetch).",
  bang = true,
})

vim.api.nvim_create_user_command("LimbClean", function(opts)
  require("limb").clean({ force = opts.bang })
end, {
  desc = "Remove worktrees with gone-upstream branches. Bang skips dry-run preview.",
  bang = true,
})

vim.api.nvim_create_user_command("Limb", function(opts)
  require("limb").dispatch(opts.fargs)
end, {
  desc = "Passthrough to limb. Renders stdout in a floating window.",
  nargs = "+",
  complete = function(arg_lead, cmd_line)
    return require("limb").complete(arg_lead, cmd_line)
  end,
})
