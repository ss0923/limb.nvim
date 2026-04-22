# limb.nvim

Neovim integration for [limb](https://github.com/ss0923/limb).

[![CI](https://github.com/ss0923/limb.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/ss0923/limb.nvim/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/ss0923/limb.nvim)](#license)

Two user commands backed by the `limb` binary:

- `:LimbPick`. Fuzzy picker over every worktree across configured
  projects. Changes directory to the selection and, when installed,
  refreshes [snacks.nvim](https://github.com/folke/snacks.nvim) file
  pickers.
- `:LimbStatus`. Opens `limb status` in a centered floating window.

When Neovim runs inside tmux, `:LimbPick` writes a `mark-cd` marker.
The parent shell's `precmd` hook changes directory on the next prompt,
allowing editor-driven worktree switches to outlive the Neovim session.

## Requirements

- Neovim 0.10 or later.
- The `limb` binary on `$PATH`. See the
  [installation instructions](https://github.com/ss0923/limb#install).

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{ "ss0923/limb.nvim", cmd = { "LimbPick", "LimbStatus" } }
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { "ss0923/limb.nvim" }
```

Commands register on plugin load via `plugin/limb.lua`. Calling
`setup()` is optional; the current release exposes no options.

## Health check

```
:checkhealth limb
```

Verifies that the `limb` binary is reachable, prints its version,
reports whether the current session is inside tmux, and forwards
`limb doctor` output for diagnostic context.

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
