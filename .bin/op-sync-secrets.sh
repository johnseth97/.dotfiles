#!/usr/bin/env bash
# sync-secrets.sh — pull down all your dotfile‑style secrets from 1Password
set -euo pipefail

# ─────── CONFIG ──────────────────────────────────────────────────────────────
VAULT=".env"              # the 1Password vault where you’ve stored these items
SECRETS_DIR="${HOME}/.secrets"
BIN_DIR="${HOME}/.bin"

# list of “filename|1Password‑item‑title” pairs
ITEMS=(
  "git-config|Git Config"
  "ssh-config|SSH Config"
  "known_hosts|Known Hosts"
  # Add more as needed:
  # "myapp-api-key|MyApp API Key"
  # "sql-conn|string for SQL Connection"
)
# ──────────────────────────────────────────────────────────────────────────────

mkdir -p "$SECRETS_DIR" "$BIN_DIR"

# 1Password sign‑in (will prompt for biometric/MFA if needed)
if ! op vault get "$VAULT" &>/dev/null; then
  echo "🔐 Signing in to 1Password…"
  eval "$(op signin)"   
fi

# fetch each item’s “content” field into a file under ~/.secrets
for entry in "${ITEMS[@]}"; do
  fname="${entry%%|*}"
  title="${entry#*|}"

  echo "⏬ Fetching '$title' → $SECRETS_DIR/$fname"
  # --format raw ensures we get only the field’s value
  op item get "$title" \
    --vault "$VAULT" \
    --field content \
    --format raw \
    > "$SECRETS_DIR/$fname"

  chmod 600 "$SECRETS_DIR/$fname"
done

# create the symlinks where you need them
ln -sf "$SECRETS_DIR/git-config"    "$HOME/.gitconfig"
ln -sf "$SECRETS_DIR/ssh-config"    "$HOME/.ssh/config"
ln -sf "$SECRETS_DIR/known_hosts"   "$HOME/.ssh/known_hosts"
# add your own:
# ln -sf "$SECRETS_DIR/myapp-api-key"   "$HOME/.config/myapp/api_key"
# ln -sf "$SECRETS_DIR/sql-conn"         "$HOME/.db/conn_string"

echo "✅ Secrets synced into $SECRETS_DIR and symlinked."
