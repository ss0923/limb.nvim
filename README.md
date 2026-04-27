# limb.nvim

Neovim integration for [limb](https://github.com/ss0923/limb).

[![CI](https://github.com/ss0923/limb.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/ss0923/limb.nvim/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/ss0923/limb.nvim)](#license)

Six dedicated commands and a generic passthrough, all backed by the
`limb` binary. Every invocation runs asynchronously.

## Commands

### Worktree flow

- `:LimbPick`. Fuzzy picker over every worktree across configured
  projects. Changes directory to the selection and, when installed,
  refreshes [snacks.nvim](https://github.com/folke/snacks.nvim) file
  pickers. Bare and prunable entries are filtered out; locked entries
  are surfaced with a `[locked]` marker.
- `:LimbStatus[!]`. Opens `limb status` in a centered floating window.
  Falls back to `limb status --all` automatically when Neovim's cwd is
  outside any tracked repo. The bang form forces `--all` regardless.
- `:LimbAdd[!] [name] [base]`. Create a worktree. Prompts for `name`
  and an optional `base` if not supplied. Bang switches into the new
  worktree on success.
- `:LimbRemove[!] [name]`. Remove a worktree. Without `name`, presents
  a picker of removable worktrees in the current repo. Confirms via
  `vim.ui.input` unless the bang is used (which also passes
  `--force`).
- `:LimbUpdate[!]`. Fetch + fast-forward worktrees in the current
  repo. Bang passes `--ff-only`.
- `:LimbClean[!]`. Remove worktrees whose upstream branches are gone.
  Without the bang, runs `--dry-run --json` first and shows the
  candidates in a float with `a` to apply.

### Generic passthrough

- `:Limb <subcommand> [args...]`. Runs `limb <subcommand> [args...]`
  and renders output in a floating window. Use this for the long tail
  (`lock`, `unlock`, `rename`, `prune`, `repair`, `setup`, `doctor`,
  `config`, `migrate`). Subcommand completion is provided.

```vim
:Limb lock production --reason "release"
:Limb rename old new
:Limb doctor
:Limb config
```

## tmux integration

When Neovim runs inside tmux, `:LimbPick` and `:LimbAdd` (when
switching) write a `mark-cd` marker. The parent shell's `precmd` hook
(installed by `limb init <shell>`) changes directory on the next
prompt, so editor-driven worktree switches survive `:q`.

## Requirements

- Neovim 0.10 or later.
- The `limb` binary on `$PATH`. See the
  [installation instructions](https://github.com/ss0923/limb#install).

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "ss0923/limb.nvim",
  cmd = {
    "Limb", "LimbPick", "LimbStatus", "LimbAdd",
    "LimbRemove", "LimbUpdate", "LimbClean",
  },
  opts = {},
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { "ss0923/limb.nvim" }
```

Commands register on plugin load via `plugin/limb.lua`.

## Configuration

`setup()` is optional. Defaults work zero-config.

```lua
require("limb").setup({
  binary = "limb",
  on_change_dir = function(path)
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
    width = function() return math.max(60, math.min(120, vim.o.columns - 10)) end,
    height = function(n) return math.max(1, math.min(n + 2, vim.o.lines - 6)) end,
  },
})
```

Set `on_change_dir = false` to disable the post-pick callback. Replace
the function to wire up another picker (telescope, fzf-lua, etc.).

See `:help limb-configuration` for full reference.

## Suggested keymaps

The plugin ships no default keymaps. Wire your own:

```lua
local map = vim.keymap.set
map("n", "<leader>gp", "<cmd>LimbPick<cr>", { desc = "limb pick" })
map("n", "<leader>gs", "<cmd>LimbStatus<cr>", { desc = "limb status" })
map("n", "<leader>gS", "<cmd>LimbStatus!<cr>", { desc = "limb status (all repos)" })
map("n", "<leader>ga", "<cmd>LimbAdd<cr>", { desc = "limb add" })
map("n", "<leader>gr", "<cmd>LimbRemove<cr>", { desc = "limb remove" })
map("n", "<leader>gu", "<cmd>LimbUpdate<cr>", { desc = "limb update" })
map("n", "<leader>gc", "<cmd>LimbClean<cr>", { desc = "limb clean" })
```

## Health check

```
:checkhealth limb
```

Verifies that the `limb` binary is reachable, prints its version,
reports whether the current session is inside tmux, warns if
`projects.roots` is empty, and forwards `limb doctor` output.

## Tests

```
nvim --headless --noplugin -u NONE -l tests/run.lua
```

Zero external dependencies. The suite mocks `vim.system` so it does
not require the `limb` binary.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
  <http://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <http://opensource.org/licenses/MIT>)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in the work by you, as defined in the Apache-2.0
license, shall be dual licensed as above, without any additional terms or
conditions.
