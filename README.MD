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

### Portable PGP messages

`common/.bin/pg.sh` is a standalone POSIX-shell utility using GnuPG, standard
text utilities, and the commonly available `mktemp`. It has no Python dependency.
Read stdin by default or use `--file PATH`. Signing, encryption, and decryption
write only resulting content to stdout; diagnostics go to stderr.

```sh
pg.sh --verify < signed-message.asc
pg.sh --sign < message.txt > signed-message.asc
pg.sh --encrypt --recipient FINGERPRINT < message.txt > encrypted.asc
pg.sh --sign --encrypt --self < message.txt | pg.sh --decrypt
pg.sh --decrypt < encrypted.asc > message.txt
pg.sh --self-test
```

The Zsh clipboard wrappers use your existing `paste` alias or function:

```zsh
pgpaste                    # Detect, verify, or decrypt clipboard PGP blocks
pgsign                     # Clear-sign the clipboard with your default identity
pgencrypt                  # Sign and encrypt clipboard; choose a recipient
pgencrypt FINGERPRINT       # Sign and encrypt; skip the picker
pgencrypt --unsigned        # Explicitly encrypt without signing
pgencrypt --self            # Encrypt to yourself (pghide is another name)
pgsign --encrypt            # Sign and encrypt; recipient picker if needed
pgopen                     # Decrypt clipboard; verify embedded signatures
pgcopy                     # Copy your PUBLIC certificate to share
pgcopy --key FINGERPRINT    # Choose which of your identities to share
pgencrypt --help            # Colored usage and a short PGP explanation
```

The encryption picker lists usable recipient keys with identities/fingerprints.
It also accepts a public key from the clipboard, a path to a key file or directory,
or your own identity. Directory selection inspects immediate files for keys rather
than relying on filename extensions. The message is captured **before** prompting,
so copying a recipient key cannot replace the message. Selecting a fingerprint
chooses a recipient; it does not establish trust in that key's claimed identity.

The standalone script uses `PG_CLIPBOARD_COMMAND` for the clipboard-key picker;
for example `PG_CLIPBOARD_COMMAND='wl-paste --no-newline'`. The wrappers set this
from your existing paste helper. On Linux, clipboard access still needs `wl-paste`,
`xclip`, or `xsel`; the core script has no clipboard dependency. For noninteractive
imports, combine `--recipient-file FILE` with `--recipient FINGERPRINT`.

Encryption signs by default, including the standalone `--encrypt` operation.
Use `--unsigned` to opt out; it conflicts with explicit `--sign`. An unavailable
signing identity causes failure, never a silent downgrade to unsigned encryption.

`pgcopy` selects your default identity (or `--key`) and copies only its armored
public certificate, including public signing/encryption subkeys. It never exports
secret keys. It uses `PG_COPY_COMMAND`, a `copy` alias/function, or an available
`pbcopy`, `wl-copy`, `xclip`, or `xsel` backend. Failed export leaves the clipboard
unchanged. The standalone equivalent is `pg.sh --export-public [--key ID]`, which
writes public armor to stdout. Never share private keys: private encryption keys
can decrypt your messages; private signing keys can impersonate your signatures.
Public signing keys are safe to share and let others verify your messages.

All clipboard wrappers accept `--help` without reading or changing the clipboard.
Help explains PGP and key sharing, uses terminal colors, and respects `NO_COLOR`.

Signing respects GPG's `default-key` or an explicit `--key ID`; without either,
a single usable private identity is required. Private keys and passphrases remain
with your normal GPG agent/pinentry. Decryption buffers its output until GPG has
successfully decrypted and checked any embedded signature. Failed operations
release no plaintext. Unknown signing keys can be retrieved temporarily on retry.

`pgpaste` (standalone `--auto`, also the default) recognizes both clear-signed and
encrypted armored blocks, including mixtures surrounded by other text. Encrypted
blocks are decrypted and embedded signatures checked; signed results show the
signer and plaintext. Unsigned encrypted messages are labeled unsigned with red
`UNVERIFIED` bodies. Decryption/signature failures withhold plaintext and do not
stop later blocks. `pgopen`/`--decrypt` still emits exact plaintext for pipelines.
Use `pgpaste --verify` to restrict processing to clear-signed blocks. `--raw` and
`--repair` apply only to clear-signed armor; encrypted blocks go directly to GPG.

Verification retains trimming, multiple numbered messages, conservative armor
repair, colored summaries, and red `UNVERIFIED` bodies. Body line breaks are never
reconstructed. Incomplete blocks are flagged; every block must verify for success.
`--raw` disables repair, `--repair` tries only the repaired form, `--verbose` shows
GPG diagnostics, and `--quiet` suppresses verification reports and prompts.
`NO_COLOR` disables colors; redirected output is plain text.

Public keys from files, the clipboard, or verification lookups go into a temporary
keyring. By default the script offers to save newly imported keys when a terminal
is available; `--save-keys` explicitly saves them and `--no-save` disables the offer.
Saving imports only public material and does not assign identity trust. Temporary
keys are reused across messages and removed on exit. Without a terminal, keys stay
temporary unless `--save-keys` is supplied.

Missing verification keys are looked up on `hkps://keys.openpgp.org`; this sends
the signing-key identifier to that server. Override with `PG_KEYSERVER`, or use
`--offline` to disable lookup. Failed lookup/import does not prove a key is unknown
everywhere. Some keys on that server lack a verified user ID and cannot be imported
by GPG. A good signature verifies the message against the key, not its owner.

`--self-test` generates a disposable identity and tests signing, encryption,
signed encryption, exact plaintext round trips, repair, multiple/mixed/incomplete
blocks, missing keys, and tamper rejection. It uses no personal keys or network.

After updating these files, reload wrappers in existing Zsh sessions:

```zsh
source ~/.config/zsh/50-functions.zsh
```

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

### Mail in Neovim

`mail [ACCOUNT]` launches a dedicated mode in the shared Neovim configuration
using Himalaya v2 and `knownasnaffy/himalaya.nvim`. See
[mail setup and controls](docs/mail.md) for deployment, private account examples,
iCloud app passwords, Microsoft Graph OAuth and Gmail/Yahoo onboarding.
