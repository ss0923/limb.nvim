# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
