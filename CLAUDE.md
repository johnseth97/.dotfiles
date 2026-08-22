# CLAUDE.md

Guidance for AI agents working in this repository.

## ⚠️ Read SECURITY.md first

**This repo is public and has leaked credentials before.**
[`SECURITY.md`](./SECURITY.md) contains binding rules for agents. The
non-negotiables:

- Never stage a file you have not inspected. Prefer explicit paths over
  `git add -A` / `git add .`.
- Run `git status` and review every path before committing.
- Never commit secrets, internal hostnames, private IPs, kubeconfigs, cloud
  token caches, or corporate infrastructure of any kind.
- Never add a whole editor/CLI state directory (`.config/Code/`, `.azure/`).
  That is how an Azure token cache got committed here.
- If you find a committed secret: report it, state that it must be **rotated**,
  and never paste the value anywhere — not even into notes.

## Layout

GNU Stow packages, one per platform target:

| Dir | Stows to `$HOME` on |
|---|---|
| `common/` | every host |
| `macos/` | macOS |
| `wsl/` | WSL |

`dotfiles-stow` picks `common` plus the auto-detected platform package.

## Deploying

```sh
~/.dotfiles/common/.bin/dotfiles-stow --restow          # platform auto-detected
dots deploy                                             # same, via shell fn
dots plan                                               # dry run
```

`dots` / `dotfiles-stow` resolve on `PATH` only because
`common/.config/zsh/00-environment.zsh` adds `~/.bin`. In a shell where the
zsh config has not loaded, call the full path.

**A `git pull` alone does not deploy anything.** New files need a restow to be
symlinked into `$HOME`. Symptom of a missed restow: config appears to be
ignored entirely — e.g. `.zshrc` loads its `[0-9][0-9]-*.zsh` fragments with a
`(N)` null-glob, so if those symlinks are absent the loop silently matches
nothing and you get a bare shell with no error.

## Shell config

`common/.zshrc` is only a loader. It sources
`~/.config/zsh/[0-9][0-9]-*.zsh` in order:

| Fragment | Role |
|---|---|
| `00-environment` | PATH, `$EDITOR`, locale |
| `10-platform` | sources exactly one of `macos.zsh` / `wsl.zsh` / `linux.zsh` |
| `20-completion` | compinit / bashcompinit |
| `30-integrations` | ghostty, antidote, zoxide, sesh, starship |
| `40-aliases`, `50-functions` | interactive conveniences, `dots` |
| `55-completions` | `compdef` completions for `common/.bin` scripts |
| `85-banner`, `90-tmux`, `99-toolchains` | startup banner, tmux autostart, SDKs |

Add new config as a fragment; do not grow `.zshrc`. Guard anything that writes
to stdout with `[[ $- == *i* && -t 1 ]]` — non-interactive and agent-bridge
shells must stay silent or they corrupt their transport stream.

## tmux — known trap

`common/.config/tmux/tmux.conf` pins the theme plugin:

```
set -g @plugin 'fabioluciano/tmux-tokyo-night#v2.16.1'
```

Upstream renamed/rewrote this project to **tmux-powerkit** at v3.0.0, replacing
the entire `@theme_*` option API with `@powerkit_*`. Unpinned, a fresh TPM clone
silently pulls the rewrite and ignores every `@theme_*` option in this config.

Consequences to remember:

- **Do not "modernize" the `@theme_*` options to `@powerkit_*`.** That was
  tried and reverted — PowerKit cannot reproduce the intended floating-capsule
  window style (its separator styles are fixed left/right glyph pairs with no
  independent per-side control).
- **TPM never re-clones an existing plugin directory**, so `prefix + I` will
  not fix a directory already checked out at the wrong ref. Correct it in
  place: `git -C <plugin-dir> fetch --tags origin && git checkout v2.16.1`.
- `prefix + U` (TPM update) would drag it forward again. The detached HEAD
  makes `git pull` fail, which is the desired outcome — do not force past it.
- Verify by entry-point filename: `tmux-tokyo-night.tmux` is correct;
  `tmux-powerkit.tmux` means the wrong code is installed.

## Submodules

`common/.config/nvim` (kickstart.nvim fork) and
`common/.config/tmux/plugins/tpm`. The nvim pointer is frequently ahead of what
is committed; do not commit a submodule bump unless that is the explicit task.

## Conventions

- Branches are transient. `main` is the single source of truth; both machines
  (macOS + WSL) track it directly. Do not create long-lived feature branches.
- Match surrounding style; these are hand-maintained config files, not
  generated ones.
- Never force-push or rewrite history unless the owner explicitly asks.
