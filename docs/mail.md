# Neovim mail mode

`mail [ACCOUNT]` aliases `nvim-mail`, which launches the existing Neovim
configuration with a process-local mode flag. This shares the theme, Space
leader, `jkl;` navigation and Snacks setup without a second `NVIM_APPNAME`
profile or duplicated plugin installation. Dedicated mail fills the editor and
keeps a mail-only buffer bar and hides editor status lines; it resizes with the terminal. Normal `nvim`
keeps its usual chrome;
`<Space>om` or `:Himalaya` opens mail from an editor session.

The launcher intentionally shadows any system `mail` utility in Zsh. No prior
`mail` alias/function/executable was found on the implementation host. Use
`command mail` or `\mail` to bypass the alias when a system utility is installed.
Arguments are account names, not the system mail utility's send flags.

## Deploy

From any checkout location, use the existing wrappers:

```sh
./common/.bin/bootstrap --dry-run --skip-tmux-plugins --skip-optional-repos
./common/.bin/bootstrap --skip-tmux-plugins --skip-optional-repos
./common/.bin/dotfiles-stow --restow
```

Start a new Zsh, open Neovim and run `:Lazy sync` to install the pinned Lua
plugin and its NUI dependency, then `mail`. Bootstrap declares Neovim, Python 3
(for the OAuth helper) and Himalaya through the existing platform managers.
Linux/WSL falls back to a tagged Cargo build when the distro lacks v2; this
requires Rust >= 1.89, a C toolchain and the platform's OpenSSL development
packages. An old distro Rust must be upgraded through that machine's normal
package/toolchain management before retrying bootstrap. Startup never installs
packages or starts an OAuth flow.

Neovim is an independent submodule. When publishing these changes, commit/push
its mail module, plugin spec and dashboard condition **in the Neovim repo**,
then commit its new pinned revision together with the parent dotfiles changes.
An unchanged parent pin cannot deliver uncommitted submodule files to another
machine. Do not run a branch update that discards existing local Neovim work.

## Account commands

```sh
mail add-account             # Himalaya's native interactive configure wizard
mail list-accounts           # native account list, no server connection
mail check-account ACCOUNT   # native account check (connects/authenticates)
mail delete-account ACCOUNT  # remove local config only, typed confirmation
mail edit-accounts           # $VISUAL / $EDITOR, falling back to nvim
mail login TOKEN_ACCOUNT     # configure our Microsoft helper, then device login
mail open ACCOUNT            # explicit launch, including accounts named like commands
```

Himalaya 2.2.1 already provides `configure`, `account list` and `account check`;
these commands delegate to it. Its wizard discovers providers, tests the
connection, chooses a unique account name and offers to save/append without
reformatting existing accounts. Choose 1Password or a custom secret command,
not a raw password. App passwords must already exist in the selected vault.
For Graph, run `mail login TOKEN_ACCOUNT` first and choose the custom token
command `nvim-mail-token TOKEN_ACCOUNT` in Himalaya's wizard. The helper key
can differ from the account name the wizard generates.

The CLI has no account deletion command. Our wrapper removes the selected
account's TOML table(s), parses the result and verifies every other setting
is identical before writing atomically. It keeps comments/layout and makes a
mode-600 private backup next to the config before edits. Complex inline/dotted
account layouts are left for `mail edit-accounts`; it refuses ambiguous edits.
Deleting an account never deletes server mail or vault credentials, revokes a
provider grant, or removes OAuth helper settings/caches. If you delete the
default, explicitly choose another in the editor or use `mail ACCOUNT`.

Writes are refused inside Git checkouts (including through symlinks), and
mutating commands require an interactive terminal. For colon-separated
`HIMALAYA_CONFIG` overlays, select one private file explicitly before editing;
list/check/open continue to use Himalaya's merged configuration. Account
management needs Python >= 3.11 and has no extra Python packages. Reserved
subcommand names can still be used as account names via `mail open ACCOUNT`.

## Private accounts and secrets

Do not create `common/.config/himalaya`: Stow can fold directories directly
into the public checkout. The directory is ignored by Git and Stow as defense
in depth. Keep all live config and identities outside the checkout.

Start with `mail add-account` for the native wizard. The following is an
optional manual-template path for settings discovery cannot supply:

```sh
umask 077
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/himalaya"
cp docs/examples/himalaya.toml "${XDG_CONFIG_HOME:-$HOME/.config}/himalaya/config.toml"
chmod 600 "${XDG_CONFIG_HOME:-$HOME/.config}/himalaya/config.toml"
```

Edit that **private copy**, remove unused accounts and replace the placeholders.
Set exactly one default account. Change the example 1Password references to your
own vault/items/fields, and unlock/authorize `op` in a terminal first. Each
password command returns just the app password. This follows SECURITY.md's
runtime 1Password convention. Existing `op-sync-secrets.sh -af FILE` can register
private config as a file secret; restore its contents outside the checkout on
other machines. The helper does not automatically restore file secrets.
For dedicated `mail` launches, standard `op read "op://..."` password commands
are resolved at startup using 1Password's native `op run`. IMAP and SMTP reads
of the same reference are deduplicated. A private, temporary TOML overlay makes
Himalaya read the resulting process environment instead of invoking `op` for
every message/action. Your original account config is unchanged. Temporary
files contain references/commands only and are cleaned up when mail exits.

Passwords stay in the mail process environment for that session, including its
child processes; locking 1Password does not clear an already-running mail
session's environment. Quit/reopen mail to clear/reload them after rotation.
This avoids a persistent credential cache. OAuth token commands, OTP/query
references and custom shell logic continue to execute normally so refresh and
short-lived credentials keep working. Account switching can use the configured
password accounts resolved at launch. Opening `:Himalaya` inside an existing
editor does not use this launcher environment; use `mail` for session-scoped
1Password access. Python >= 3.11 and the existing `op` CLI are sufficient.

Environment-based secrets are also possible via a private command; never put
passwords or tokens directly in the tracked examples.

`HIMALAYA_CONFIG` can select a private alternative config (including CLI-supported
colon-separated overlays); the plugin inherits it. Provider-specific role/folder
names vary by locale/account: verify with `himalaya -a ACCOUNT mailbox list
--counts` and correct `mailbox.alias.*` privately before moving/deleting mail.

- **iCloud:** create an app-specific password at Apple Account → Sign-In and
  Security (requires two-factor authentication), store it in 1Password. Use
  IMAPS `imap.mail.me.com:993`, authenticated SMTP STARTTLS
  `smtp.mail.me.com:587`. Use the full iCloud address; Apple notes some IMAP
  accounts use only its name part. Set sent/drafts/trash/archive aliases to
  the actual server folders.
- **Gmail:** enable 2-Step Verification and create an app password, if allowed
  for the account. Use IMAPS `imap.gmail.com:993` and SMTPS
  `smtp.gmail.com:465`. Workspace/Advanced Protection policies may require
  OAuth instead. Gmail's sent copy is automatic; leave `save-copy` unset.
- **Yahoo:** generate a third-party app password, use the full email address
  with IMAPS `imap.mail.yahoo.com:993` and SMTPS `smtp.mail.yahoo.com:465`.
  Verify the Draft/Drafts and Sent folder names before using drafts/sent copies.

## Outlook / Microsoft 365

The tested released CLI, **2.2.1**, reports `+msgraph +imap +smtp`. Prefer its
native **Microsoft Graph** backend: reading, folders, draft creation, movement,
attachments and sending use the same delegated bearer token. No SMTP AUTH
exception is needed. In released 2.2.1, shared `message add` does not support
Graph; draft saves use `msgraph messages create --folder drafts` instead. Check `himalaya --version` for `+msgraph` on each machine;
a distributor's custom build can omit features. Graph automatically files sent
messages, so leave `message.send.save-copy` unset for this account.

The private example uses `nvim-mail-token outlook`. It uses Microsoft's device
flow only when explicitly invoked with `--login`; subsequent backend calls
silently refresh tokens. It never prints tokens during login and never asks
for authentication in a plugin job.

1. Register or obtain a tenant-approved **public client** Entra application.
   Select the appropriate supported account types (personal Outlook.com and/or
   the organization's tenant). Enable **Allow public client flows** for device
   authorization. No application client secret is needed.
2. Grant delegated Graph `Mail.ReadWrite` and `Mail.Send`, and request
   `offline_access` for refresh. Obtain administrator consent where the tenant
   requires it. These are delegated permissions for the signed-in mailbox,
   not app-only access to every mailbox.
3. `mail login outlook` prompts for missing application/tenant settings. To
   prepare them manually instead, copy `docs/examples/himalaya-oauth.json` to the private
   `${XDG_CONFIG_HOME:-$HOME/.config}/himalaya/oauth.json`, mode 600. Replace
   `client_id` and `tenant_id` locally. Use the organization's tenant UUID for
   work/school or `common` for an app registered for personal + organizational
   accounts. Its `outlook` key must match the token command argument.
4. Run `mail login outlook` in a terminal and complete the displayed
   Microsoft verification flow. Sign in to the intended mailbox. Each account
   needs a distinct helper key/cache. An expired/revoked refresh grant requires
   this command again.
5. Run the read-only checks below. Conditional Access, device-code restrictions,
   user-consent policy, mailbox licensing or missing permissions can still block
   access; an administrator must approve an allowed flow/app. This setup does
   not bypass those policies. Shared mailboxes need additional delegated
   permissions/access and a private `msgraph.user-id` override.

Tokens (including refresh tokens) stay in
`${XDG_STATE_HOME:-$HOME/.local/state}/himalaya/oauth-ACCOUNT.json`, directory
mode 700/file mode 600, with locking and atomic refresh updates. Never copy
this directory to the repo. The standard-library Python helper has no pip
installation step. A company-approved token broker can replace it: configure
`msgraph.auth.token.command` to return only a fresh Graph access token.

**IMAP/SMTP alternative:** when Graph isn't available/approved, v2 supports
XOAUTH2. Configure `imap.server = "imaps://outlook.office365.com:993"`,
`imap.sasl.xoauth2.username` and `imap.sasl.xoauth2.token.command`; use
`smtp.server = "smtp://smtp.office365.com:587"`, `smtp.starttls = true`,
`smtp.sasl.xoauth2.username` and `smtp.sasl.xoauth2.token.command`.
The approved token helper must request Exchange-resource delegated scopes
`https://outlook.office.com/IMAP.AccessAsUser.All` and
`https://outlook.office.com/SMTP.Send` plus `offline_access` (a separate helper
key with those scopes works). IMAP and authenticated SMTP must be enabled by
the tenant/mailbox, and SMTP AUTH may remain blocked by policy. A Graph token
cannot authenticate Exchange IMAP. Do not use a Microsoft account password or
an app-password workaround for disabled basic authentication.

## Mail-only plugin set

Dedicated `mail` keeps ten plugin definitions: Lazy, Tokyo Night, Snacks,
Which-key, Himalaya, NUI, Mini, autopairs, Cokeline and its devicons dependency. Mini enables text objects and
surround editing, without Git integration. Composition buffers have native
spell-check; `Space us` toggles spelling and `Space uw` toggles wrapping.
Snacks keeps selectors, notifications/history (`Space un`) and keymap search
(`Space sk`), with the existing picker navigation. Smooth scrolling, scratch,
explorer, profiler, scope/dimming and status-column features are disabled.

The coding/project plugin groups and their keymaps stay inactive: no
LSP/Mason/completion, debugging, AI, Git/project/file tools, database UI, notes,
language tooling, dashboard or editor status lines. Cokeline shows only mail
views, not scratch/sidebar buffers. Lazy retains the excluded
plugins' installations and lock entries for normal Neovim. Normal `nvim` keeps
its complete configuration; these exclusions apply only to the dedicated
launcher, not to an editor session where you later open `:Himalaya`.

Regression check from this checkout after deployment/plugin installation:

```sh
DOTFILES_MAIL=1 nvim --headless '+luafile tests/test_mail_mode.lua'
```

This checks isolation and composition helpers without opening an account.

## Open message tabs

The pinned first buffer-bar entry is **󰇮 Mail** (the folders/message list).
Each opened message gets a separate subject-labeled tab; reopening the same
account/folder/message reuses it. `q` returns to the list while keeping the
message tab, and clicking a tab restores its message and backend account/folder
context. Read content stays in memory until its view closes or Neovim exits.
These message buffers use no swap or persistent undo.

`Ctrl+b` then `1` returns to Mail; `Ctrl+b` then `2`–`9`/`0` selects the
corresponding tab (0 selects the tenth). `Ctrl+b` then `x`, the close icon, or
right/middle-click closes a view without deleting server mail. The Mail tab
has no close action. Draft tabs use their subject as the label, show a modified
marker, and ask before discarding unsaved edits. `:w` still explicitly saves a
server draft; closing a draft view never saves or sends it automatically.

## Controls

The plugin's existing tree sidebar displays folder unread counts where the
backend provides them, and unread rows show a dot. `k`/`l` move down/up as in
this config. The sidebar is focusable and selectable: `Enter` opens the
mailbox under the cursor, while grouping-only parent rows are skipped.

| Key | Action |
| --- | --- |
| `Ctrl+b` then `1`–`9`/`0` | Select a mail buffer tab; 1 is pinned Mail |
| `Ctrl+b` then `x` | Close current view (Mail stays pinned) |
| `Tab` / `Shift+Tab` | Cycle folders, message list and open reader |
| `Ctrl+w j` / `Ctrl+w ;` | Focus folders / message list |
| `Ctrl+w k` / `Ctrl+w l` | Focus reader / message list |
| `]f` / `[f`, `gF`, `<Space>mf` | Next/previous folder, folder picker |
| `gA`, `<Space>ma` | Snacks account picker (close composition buffers first) |
| `<CR>` | Replace the message list with the full-height email; marks it read |
| `q` in reading pane | Return to the message list at the selected row |
| `]]` / `[[` | Next/previous page |
| `R`, `<Space>mr` | Refresh folders/counts and current listing |
| `g/` | Backend search, e.g. `not flag seen` or `subject invoice` |
| `c` / `gw`, `r` / `gr`, `gR`, `gf` | Compose, reply, reply-all, forward |
| `m`, `<Space>mm` | Backend move with Snacks folder selector |
| `<Space>mA` | Archive via the same move selector; choose the archive folder |
| `d` / `gD` | Confirmed backend delete; **permanent when already in Trash** |
| Visual `gFa` | Mark all selected message rows read in one backend request |
| `gC`, `gFa` / `gFr` | Copy, add/remove a flag (`seen` means read) |
| `ga` | Backend attachment download to the configured downloads directory |
| `gE` | Edit a saved draft as raw MIME, preserving threading/attachments |
| `gq` | Close mail; `:qa` exits Neovim |

The composer opens a normal editable tab so the mail UI cannot obscure it. Keep its four headers and blank
separator; edit addresses/subject/body freely. `:MailAttach PATH` adds a file
(with filename completion); `:w` or `<Space>md` saves a new backend draft copy;
`:MailSend` or `<Space>ms` explicitly confirms sending. Released CLI 2.2.1
forwards source text without automatically carrying source attachments; download
them with `ga` first and add the files with `:MailAttach` when forwarding.
Reply-all excludes the configured sender address; review any additional aliases
and group recipients in the editable form. A resumed `gE` draft is
raw MIME: preserve boundaries/encoding and use `:w` / `:MailSend`; adding new
attachments there requires returning to a new form. Saved/original drafts are
retained after sending; remove them explicitly when appropriate. Repeated
saves create copies. Unsaved forms are retained as hidden buffers, with swap
and persistent undo disabled; use `:buffers`/`:buffer` to return to one, or
`:bd!` to discard. Use `:tabclose` to return to the mail tab. Dedicated mail instances disable ShaDa persistence too.

## Compatibility and checks

Reviewed plugin commit `e20f70b51dbb61db4eb33872317e7a8d1f99a0e6`, pinned in
the Lazy spec, against released CLI 2.2.1. Its README still understates the v2
implementation. Do not copy older himalaya-vim/v1 configuration or commands.
Upstream master differs even from the latest release: 2.2.1 lacks `reply --all`
and exposes mail-parser JSON from `message read`. The adapter handles that
shape and the newer decoded-header shape, uses the CLI to preserve threading
and MIME attachments, binds refresh/paging to the selected account, discards
late results from another account, and clears caches on switching. Review
these adapters before upgrading the pin/CLI beyond this tested pair.

Mail opens after `VimEnter`: the plugin's early-start native fullscreen layout
does not wire up its reading pane yet. Its NUI layout does, and supplies the
existing sidebar and message view. Reading reuses the full right-hand window
and retains the hidden list/cursor; `q` restores it. The normal startup dashboard and Lualine are disabled only
for dedicated mail launch. Cokeline uses mail-only labels/navigation there. Arrow keys work normally throughout Neovim; the
existing `jkl;` navigation remaps remain available. Missing dependencies/accounts show onboarding
instructions; no live account or secrets are provisioned automatically.

Safe onboarding checks (network reads/auth checks only):

```sh
himalaya --version
himalaya --json account list
himalaya -a ACCOUNT account check
himalaya -a ACCOUNT mailbox list --counts
himalaya -a ACCOUNT envelope list
mail ACCOUNT
```

Implementation validation used an isolated config/data/state directory and
synthetic Maildir accounts: normal startup/lazy loading, mail layout and
reading, reply-all recipients, threading, attachment MIME, draft append and
account switching. Shell/Lua/Python syntax, example TOML with the released CLI,
launcher argument handling and temporary-home Stow deployment were also
checked. OAuth refresh/cache behavior was tested with synthetic responses. The live-home
Stow dry run also exposed a pre-existing regular file at
`~/.config/ghostty/config` conflicting with the Linux package; it was left
untouched. Clean temporary-home deployments passed for Linux, macOS and WSL.
**No provider login, real mailbox changes or sending has been verified.**

Sources: [1Password op run](https://developer.1password.com/docs/cli/reference/commands/run/),
[Himalaya native account wizard](https://github.com/pimalaya/himalaya/blob/v2.2.1/src/wizard/configure.rs),
[Lua plugin source](https://github.com/knownasnaffy/himalaya.nvim),
[CLI 2.2.1 config](https://github.com/pimalaya/himalaya/blob/v2.2.1/config.sample.toml),
[Apple mail settings](https://support.apple.com/102525),
[Google app passwords](https://support.google.com/mail/answer/185833),
[Yahoo IMAP settings](https://help.yahoo.com/kb/SLN4075.html),
[Graph mail API](https://learn.microsoft.com/en-us/graph/api/resources/mail-api-overview?view=graph-rest-1.0),
[Microsoft device authorization](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-device-code),
[Exchange OAuth](https://learn.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth/).
