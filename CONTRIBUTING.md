# Contributing

## Proposing changes

Open an issue before starting non-trivial work to surface design
feedback and avoid duplicate effort.

## Development

Prerequisites: the [`limb`](https://github.com/ss0923/limb) binary on
`$PATH`, Neovim 0.10 or later.

Point your plugin manager at a local clone:

```lua
{ dir = "/absolute/path/to/limb.nvim", name = "limb" }
```

Test manually inside a git repository that has worktrees:

```
:LimbPick
:LimbStatus
:checkhealth limb
```

Verify formatting and syntax:

```sh
stylua --check .
luac -p lua/limb/init.lua lua/limb/health.lua plugin/limb.lua
```

## Pull requests

The pull request title becomes the commit message on `main` when squash
merged. Format the title as a [Conventional
Commit](https://www.conventionalcommits.org/en/v1.0.0/):

```
feat: add support for <X>
fix: correct <Y> under <Z> condition
```

Individual commits on the feature branch are not required to follow any
format. A CI job validates only the pull request title.

## Licensing

Unless explicitly stated otherwise, contributions are dual-licensed under
MIT and Apache-2.0, matching the project license. See
[LICENSE-MIT](LICENSE-MIT) and [LICENSE-APACHE](LICENSE-APACHE).

## Code of conduct

This project follows the [Contributor Covenant Code of
Conduct](CODE_OF_CONDUCT.md).
