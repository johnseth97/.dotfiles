# Security Policy

**This repository is public.** Everything committed here is world-readable,
permanently, and is scraped by automated secret collectors within minutes of
being pushed. Treat every commit as a publication.

This file exists because credentials *have* leaked here before. Read it before
committing, and especially before instructing an AI agent to commit on your
behalf.

---

## Never commit

- Passwords, API keys, tokens, connection strings with embedded credentials
- Private keys (`id_rsa`, `id_ed25519`, `*.pem`, `*.key`, `*.pfx`)
- `kubeconfig` files, cloud credential caches, MSAL/OAuth token caches
- Internal hostnames, private IP addresses, server inventories
- Internal/private repository names, project codenames, customer names
- Anything under an editor or CLI state directory that may cache auth
  (`.config/Code/`, `.config/gh/hosts.yml`, `.azure/`, `.aws/credentials`)

**Config that needs a secret gets the secret from the environment or
1Password at runtime — never inline.** This repo ships
`common/.bin/op-sync-secrets.sh` for exactly that; use it.

## Corporate / work material does not belong here

This is a personal, public dotfiles repo. Work infrastructure — internal
hostnames, cluster names, resource groups, server launch scripts, VPN-only
addresses — must live somewhere else (a private repo, or untracked local
files under `~/.local/share/`). Do not add it here "temporarily."

Untracked-but-on-disk is a fully supported pattern: gitignore the file and
keep using it locally. See the `lazysql` entry in `.gitignore` for an example.

---

## Rules for AI agents

If you are an AI agent operating in this repository, these are binding:

1. **Never stage or commit a file you have not inspected.** A path that looks
   innocuous (`config.toml`, `settings.json`, a cache file) is exactly where
   credentials hide in a dotfiles repo.
2. **Before any `git add`, `git commit -a`, or `git add -A`, run
   `git status` and review every path.** Broad staging is how secrets get
   committed. Prefer explicit paths over `-A` / `.`.
3. **Scan before you push.** At minimum:
   ```sh
   git diff --cached | grep -nEi '(password|passwd|secret|token|api[_-]?key)[[:space:]]*[=:]'
   git diff --cached | grep -nEi '(sqlserver|postgres|mysql|mongodb|redis)://[^[:space:]]*:[^[:space:]]*@'
   ```
   A hit is a stop, not a warning.
4. **Never widen tracking of a whole state directory.** Adding `.config/` or
   an editor config tree wholesale is how the Azure token cache got committed.
   Add individual files.
5. **Do not "fix" a leaked secret by deleting it in a new commit.** That does
   not remove it from history and does not un-publish it. Report it, and say
   plainly that the credential must be rotated.
6. **Never copy a discovered secret into a commit message, PR body, issue,
   chat message, log, or any file — including remediation notes.** Reference
   it by path and line only.
7. **History rewrites and force-pushes are owner-authorized only.** Never
   initiate one to hide a mistake.

---

## If a credential is committed

Order matters. Rewriting history is cleanup, not containment.

1. **Rotate or revoke the credential first.** Assume it is compromised the
   moment it is pushed. A rewrite cannot retract what was already public;
   only rotation ends the exposure.
2. Untrack the file (`git rm --cached <path>`) and add it to `.gitignore`.
   The file can stay on disk.
3. Review access logs for the affected system over the full exposure window.
4. Purge from history (`git filter-repo`) and force-push — coordinating with
   every other clone, since this rewrites shared history.
5. Note that unreferenced blobs stay fetchable by direct SHA on GitHub until
   garbage collected, and forks are unaffected by a rewrite. For a public
   repo, open a GitHub support request for GC.

Active remediation notes are kept outside this repo, in
`~/.agent-info/security/` — deliberately not committed here.

## Recommended repository settings

Enable in **Settings → Code security**:

- **Secret scanning** — alerts on known credential patterns already pushed
- **Push protection** — blocks a push containing a recognized secret before it
  lands, which is the only control here that prevents rather than detects
- **Dependabot alerts**

Push protection is the highest-value item: it makes the common failure mode
(an agent or a hurried commit sweeping in a credential) fail closed.

---

## Reporting

Found a credential or sensitive data in this repo, including in history?
Open an issue **without quoting the secret** — reference the file path,
line, and commit SHA — or contact the owner directly.
