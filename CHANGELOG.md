# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0](https://github.com/ss0923/limb.nvim/releases/tag/v0.3.0) - 2026-04-28

### Added

- `:LimbPick!` (bang form) runs `limb update --fetch-only --all` before
  opening the picker so ahead/behind counts reflect the latest remote
  state. The picker still opens if the fetch fails (a warning is
  emitted).
- `M.pick({ fetch })`, `M.status({ fetch })`, `M.update({ all })` typed
  options on the Lua API. Mirror limb 0.2.0's new `--fetch` and `--all`
  flags so keymap authors can wire them without dropping to the
  dispatch passthrough.
- Test coverage for the new flag passthroughs in `tests/run.lua`.

### Changed

- Suggested keymaps now include `<leader>gP` for `:LimbPick!`
  (refresh-then-pick) and `<leader>gU` for cross-repo update.

## [0.2.0](https://github.com/ss0923/limb.nvim/releases/tag/v0.2.0) - 2026-04-26

### Added

- Test suite at `tests/run.lua`, runnable via
  `nvim --headless --noplugin -u NONE -l tests/run.lua` with zero
  external dependencies. Mocks `vim.system` so the suite does not
  require the `limb` binary. Wired into CI across Neovim 0.10, stable,
  and nightly.
- `.luarc.json` for lua-language-server (Lua 5.1 runtime, `vim`
  global, runtime + luv libraries).
- `.editorconfig` mirroring the stylua configuration.
- `:LimbAdd[!] [name] [base]`. Create a worktree from inside Neovim;
  prompts for `name` and an optional `base` if not supplied. Bang
  switches into the new worktree on success.
- `:LimbRemove[!] [name]`. Remove a worktree. Without `name`, presents
  a picker of removable worktrees in the current repo. Confirms via
  `vim.ui.input` unless the bang form is used (which also passes
  `--force`).
- `:LimbUpdate[!]`. Fetch + fast-forward worktrees in the current
  repo. Async with start/completion notifications. Bang passes
  `--ff-only`.
- `:LimbClean[!]`. Remove worktrees with gone-upstream branches.
  Without the bang, runs `--dry-run --json` first and shows
  candidates in a floating window with `a` to apply, `q` to dismiss.
- `:Limb <subcommand> [args...]`. Generic passthrough to the `limb`
  CLI for the long tail (lock, unlock, rename, prune, repair, setup,
  doctor, config, migrate). Subcommand completion is provided.
- `setup()` is now a real configuration system. Options: `binary`,
  `on_change_dir`, `switch_after_add`, `confirm_destructive`,
  `notify`, `float`. Defaults work zero-config. Unknown top-level keys
  emit a warning to surface typos.
- `:checkhealth limb` parses `limb --json config` and warns when
  `projects.roots` is empty (otherwise `:LimbPick` silently returns
  nothing).
- `doc/limb.txt`, accessible via `:help limb`.

### Fixed

- `:LimbStatus` no longer errors when Neovim's cwd is outside any
  tracked repo. It now falls back to `limb status --all` so the float
  always renders something useful.

### Changed

- All commands run asynchronously via `vim.system` callbacks. Neovim
  stays responsive while limb walks worktrees (cross-repo
  `limb status --all` is several seconds with a large
  `projects.roots`).
- `:LimbStatus!` (bang form) forces `limb status --all` regardless of
  the editor's cwd.
- `:LimbPick` filters prunable worktrees out of the picker (in
  addition to bare entries) and surfaces `[locked]` next to locked
  worktrees so they remain visible but identifiable.
- Detached HEAD entries display as `(detached <short-sha>)` when a
  head SHA is available, instead of just `(detached)`.
- Column padding in the picker uses `strdisplaywidth`, so multi-byte
  worktree names align correctly.
- Floating-window buffers are wiped on close (were lingering as
  unlisted scratch buffers).
- Internal split: shared helpers in `lua/limb/util.lua`, floating
  windows in `lua/limb/float.lua`, configuration in
  `lua/limb/config.lua`. `lua/limb/init.lua` remains the public API.
- `limb.Entry` Lua type annotations refreshed to match limb 0.1.1's
  list schema (added `head`, `locked`, `locked_reason`, `prunable`,
  `prunable_reason`).
- JSON decoding uses `{ luanil = { object = true, array = true } }`
  so JSON nulls become Lua nil instead of `vim.NIL` sentinels. Removes
  defensive `~= vim.NIL` checks throughout.
- `:Limb` completion is trimmed to the long-tail subcommands
  (`config`, `doctor`, `lock`, `migrate`, `prune`, `rename`, `repair`,
  `setup`, `unlock`). Subcommands with dedicated wrappers
  (`:LimbAdd`, etc.) no longer surface in completion to avoid
  confusion. The dispatcher itself still accepts any subcommand.

## [0.1.0](https://github.com/ss0923/limb.nvim/releases/tag/v0.1.0) - 2026-04-22

Initial release.

### Added

- Two user commands backed by the `limb` binary: `:LimbPick` (fuzzy
  picker over every worktree across configured projects; changes
  directory to the selection) and `:LimbStatus` (opens `limb status` in
  a centered floating window).
- `:checkhealth limb` integration verifying that the `limb` binary is
  reachable, reporting whether the session is inside tmux, and
  surfacing `limb doctor` output.
- Tmux-aware shell propagation. When Neovim runs inside tmux,
  `:LimbPick` writes a `mark-cd` marker that the parent shell's
  `precmd` hook consumes on the next prompt, allowing editor-driven
  worktree switches to outlive the Neovim session.
- Optional [snacks.nvim](https://github.com/folke/snacks.nvim)
  integration: when installed, `:LimbPick` refreshes snacks file
  pickers after changing directory.
- Lazy-load compatible via `cmd = { "LimbPick", "LimbStatus" }`; no
  runtime cost until invoked.
