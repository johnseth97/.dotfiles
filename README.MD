## Portable dotfiles

This is a portable, GNU Stow-managed shell and terminal environment. It
deploys the `common` package plus a host package when one exists (`macos`,
`linux`, or `wsl`). It is intentionally broad enough to make a new machine
feel like this one, while excluding credentials, generated files, and mutable
application state.

### What you get

- Zsh with platform detection, completions, Antidote plugins, Starship, Ghostty
  integration, zoxide and Sesh completion, optional tmux auto-attach, and a
  `dots` command with native Tab completion.
- A pinned Neovim submodule and pinned TPM submodule. Their known-good commits
  travel with this repository; Neovim remains independently maintainable.
- Portable configuration for terminal tools such as Starship, btop, tmux,
  OpenCode, 1Password CLI aliases, and Stylua.
- On macOS, Homebrew packages and casks declared in
  [`macos/Brewfile`](macos/Brewfile).

It does not deploy secrets, authentication state, plugin caches, game saves,
Raycast, Fish, Zed, Wireshark, or retired SwiftBar state.

### Install

Clone with the pinned Neovim and TPM submodules, then run bootstrap. The
bootstrap script detects the host by default; `--platform macos|linux|wsl`
overrides detection.

```zsh
git clone --recurse-submodules git@github.com:johnseth97/.dotfiles.git ~/.dotfiles
~/.dotfiles/common/.bin/bootstrap
```

On macOS, bootstrap uses Homebrew (installing it after Command Line Tools if
needed) and applies [`macos/Brewfile`](macos/Brewfile). On Linux and WSL it
uses Homebrew when present, otherwise apt, dnf, or pacman to install the core
shell/deployment dependencies. Use `--dry-run` to show the Stow deployment,
`--skip-packages` when dependencies are already installed, or
`--skip-tmux-plugins` to defer TPM's initial plugin installation.

Run `bootstrap-git-signing` separately after installing 1Password if you want
Git SSH signing configured through its agent.

### Deployment policy

Stow and Git solve different problems:

- `.gitignore` controls what is committed.
- `.stow-local-ignore` controls what is deployed to `$HOME`.
- Application-owned caches, secrets, and plugin checkouts stay local even if
  an application writes them below a configuration directory.

Do not invoke `stow .`. Use the wrapper so platform selection and ignore
policy stay consistent:

```zsh
~/.dotfiles/common/.bin/dotfiles-stow --dry-run
~/.dotfiles/common/.bin/dotfiles-stow --restow
```

Neovim is an independently versioned project and remains a pinned submodule.
Bootstrap and sync check out the revision pinned by this repository; they do
not pull its branch. TPM is likewise a pinned submodule, while its installed
plugins are mutable local state managed by TPM.

### Everyday use

The `.bin` tools are the portable interface. Zsh also provides a `dots`
dispatcher and short aliases for interactive use. Type `dots <Tab>` to list
actions, then Tab again for the selected action's options.

```zsh
dots status          # see local changes before syncing
dots plan            # preview a restow; changes nothing
dots deploy          # restow this host's packages
dots sync             # update the root repo and pinned submodules
dots bootstrap        # prepare a new host
dots shell-update     # update Homebrew Antidote and declared plugin bundles

# Equivalent short aliases: dots-plan, dots-deploy, dots-sync,
# dots-bootstrap, and antidote-update.
```

`dots shell-update` is intentionally explicit: it performs package/Git
updates and should not run at every shell startup.

### Tmux and Sesh projects

Zsh initializes zoxide, so directories visited through `z` automatically
become Sesh project candidates. Tmux starts a login Zsh when it is installed,
which ensures that the same shell integrations apply inside every pane.

- `prefix` + `s` opens the Sesh project/session picker.
- `prefix` + `p` adds the current pane directory to zoxide manually, then
  refreshes Sesh's optional cache. This is useful for a project you want in the
  picker before it has accumulated zoxide history.
- `prefix` + `m` prompts for an index and inserts the current window there,
  shifting the intervening windows as needed.
- `prefix` + `M` prompts for an existing tmux/Sesh session target and moves the
  current window to its end. Press Tab for tmux session/window completion.
- `prefix` + `L` switches to Sesh's most recently used session.

Outside tmux, an interactive local Zsh attaches to (or creates) the `default`
tmux session. Set `NO_TMUX=1` or `DISABLE_AUTO_TMUX=1` before starting Zsh to
skip that behavior; SSH, editor-integrated terminals, and existing tmux panes
are already excluded.

### Updates and ownership

`sync-dotfiles` updates only the dotfiles repository and its pinned
submodules, then restows the selected packages. It refuses a dirty worktree
or dirty submodule rather than overwriting local work.

```zsh
sync-dotfiles
```

Package updates remain the responsibility of the platform package manager
(Homebrew and brew-watchtower on macOS). Antidote is loaded from a packaged
installation when one is available; a legacy `~/.antidote` clone is only a
fallback for hosts without one.

### macOS package-update policy

[`macos/.config/brew-watchtower/groups.conf`](macos/.config/brew-watchtower/groups.conf)
classifies every formula and cask in the curated Brewfile. It deliberately
separates unattended, low-risk command-line updates from packages that can
change a runtime, security posture, graphical application, or developer tool.

- `foundation` runs daily at 05:00 and automatically upgrades a small set of
  shell-oriented tools.
- `security` runs daily at 09:30 but remains interactive, so security-sensitive
  packages are reported rather than silently upgraded.
- `runtimes`, `developer-system`, and `desktop-and-creative` are review-only
  interactive groups. They have no schedule by design.

The Python selector is intentionally dynamic: `formula_glob=python@*` applies
to installed versioned Python formulae, while `brew-watchtower groups` prints
the exact packages currently matched. After changing the manifest, inspect it
and apply it to Watchtower's protected runtime:

```zsh
brew-watchtower groups
brew-watchtower groups sync
brew-watchtower status
```

`groups_mode=declarative` prevents `add`, `remove`, and `schedule` from
silently diverging the protected runtime from this Stow-managed manifest. Edit
the manifest and sync it instead. When a group is retired, preview the exact
root policy files and LaunchAgents that would be removed, then apply explicitly:

```zsh
brew-watchtower groups prune
brew-watchtower groups prune --apply
```

Watchtower manages Homebrew formulae and casks, not Mac App Store purchases;
the Brewfile's `mas` entries remain App Store-managed. The `mas` formula itself
is included as an interactive developer-system package.

### Verify safely

Run these before deploying a significant change:

```zsh
dots plan
~/.dotfiles/common/.bin/bootstrap --dry-run --skip-packages --skip-tmux-plugins
git -C ~/.dotfiles diff --check
```

For a full clean-room Stow test without changing `$HOME`, deploy to a temporary
directory instead:

```zsh
test_home="$(mktemp -d)"
stow --dir ~/.dotfiles --target "$test_home" common macos
test -f "$test_home/.config/stylua.toml"
test -d "$test_home/.config/tmux/plugins/tpm"
```

Inspect `"$test_home"` when finished, then remove it explicitly if desired.
