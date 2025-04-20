#!/usr/bin/env bash
set -euo pipefail

SECRETS_DIR="${HOME}/.secrets"
META="${SECRETS_DIR}/metadata.json"

# ─── BOILERPLATE ──────────────────────────────────────────────────────────
init() {
  mkdir -p "$SECRETS_DIR"
  [[ -f "$META" ]] || echo '{"secrets":[]}' > "$META"
}

# Ensure we're signed into 1Password
sign_in_if_needed() {
  if ! op account list &>/dev/null; then
    echo "🔐 Signing into 1Password…"
    eval "$(op signin)"
  fi
}

# Pick a vault by name (no mapfile, no nulls)
choose_vault() {
  local vaults=()
  while IFS= read -r v; do vaults+=("$v"); done < <(
    op vault list --format=json | jq -r '.[].name'
  )
  if (( ${#vaults[@]} == 1 )); then
    printf '%s' "${vaults[0]}"
    return
  fi
  PS3="Select 1Password vault: "
  select v in "${vaults[@]}"; do
    [[ -n $v ]] && { printf '%s' "$v"; return; }
  done
}

usage() {
  cat <<EOF
Usage: $(basename $0) [-af <file>] [-ae <ENV>]
  -af <file>    Add a file‑based secret
  -ae <VAR>     Add an env‑var secret
  (no flags)    Sync all secrets for this OS/host
EOF
  exit 1
}
# ──────────────────────────────────────────────────────────────────────────

# ─── ADD A FILE SECRET ────────────────────────────────────────────────────
add_file() {
    local src="$1"
  [[ -e $src ]] || { echo "❌ File not found: $src"; exit 1; }

  # 1) make a safe, unique alias
  local alias
  alias=$(echo "$src" \
    | sed -e "s|^$HOME|home|" \
          -e 's|/|__|g' \
          -e 's|[^A-Za-z0-9_]||g')
  echo "Using alias '$alias' for secret"

  # 2) rest of your prompts…
  select scope in universal os host; do [[ -n $scope ]] && break; done
  local os="$(uname -s)" host="$(hostname)"
  read -rp "1Password Item title for '$alias': " item
  vault="$(choose_vault)"
  local content="$(<"$src")"

  # 3) create or skip the 1PW Secure Note
  if ! op item get "$item" --vault "$vault" &>/dev/null; then
    op item create --category secureNote --title "$item" \
      --vault "$vault" additional_information="$content"
  fi

  # 4) record metadata under 'name' = alias
  local tmp=$(mktemp)
  jq --arg type  file      \
     --arg name  "$alias"  \
     --arg path  "$src"    \
     --arg scope "$scope"  \
     --arg os    "$os"     \
     --arg host  "$host"   \
     --arg vault "$vault"  \
     --arg item  "$item"   \
     --arg field "additional_information" \
    '.secrets += [{
       type:  $type,
       name:  $name,
       path:  $path,
       scope: $scope,
       os:    $os,
       host:  $host,
       vault: $vault,
       item:  $item,
       field: $field
    }]' "$META" > "$tmp" && mv "$tmp" "$META"

  # 5) symlink with the alias
  ln -sf "$src" "$SECRETS_DIR/$alias"
  echo "✅ Added file secret '$alias'"
}

# ─── ADD AN ENV‑VAR SECRET ───────────────────────────────────────────────
add_env() {
  local var field="additional_information" item vault scope os host secret_value tmp
  var="$1"
  echo "Registering env var: $var"
  select scope in universal os host; do [[ -n $scope ]] && break; done
  os="$(uname -s)"; host="$(hostname)"
  read -rp "1Password Item title for '$var': " item
  vault="$(choose_vault)"
  read -rsp "Enter value for '$var': " secret_value; echo

  if ! op item get "$item" --vault "$vault" &>/dev/null; then
    echo "➕ Creating Secure Note '$item' in vault '$vault'…"
    op item create \
      --category secureNote \
      --title "$item" \
      --vault "$vault" \
      additional_information="$secret_value"
  else
    echo "ℹ️  '$item' already exists, skipping create."
  fi

  # update or append metadata
  if jq -e --arg n "$var" '.secrets[] | select(.type=="env" and .name==$n)' "$META" &>/dev/null; then
    echo "🔄 Updating metadata for '$var'"
    tmp="$(mktemp)"
    jq --arg n     "$var" \
       --arg scope "$scope"   \
       --arg os    "$os"      \
       --arg host  "$host"    \
       --arg vault "$vault"   \
       --arg item  "$item"    \
       --arg field "$field"   \
      '(.secrets[] | select(.type=="env" and .name==$n)) |= {
         type:  "env",
         name:  $n,
         scope: $scope,
         os:    $os,
         host:  $host,
         vault: $vault,
         item:  $item,
         field: $field
      }' "$META" > "$tmp" && mv "$tmp" "$META"
  else
    echo "🔖 Appending metadata for '$var'"
    tmp="$(mktemp)"
    jq --arg type  env    \
       --arg name  "$var" \
       --arg scope "$scope"\
       --arg os    "$os"   \
       --arg host  "$host" \
       --arg vault "$vault"\
       --arg item  "$item" \
       --arg field "$field"\
      '.secrets += [{
         type:  $type,
         name:  $name,
         scope: $scope,
         os:    $os,
         host:  $host,
         vault: $vault,
         item:  $item,
         field: $field
      }]' "$META" > "$tmp" && mv "$tmp" "$META"
  fi

  echo "✅ Added env secret '$var'"
}

# ─── SYNC ALL SECRETS ─────────────────────────────────────────────────────
sync_all() {
   sign_in_if_needed
  local os host entry type scope vault item field name secret

  os="$(uname -s)"
  host="$(hostname)"
  echo "# autogenerated via op-sync-secrets.sh" > "$SECRETS_DIR/.env"

  jq -c '.secrets[]' "$META" | while read -r entry; do
    type=$(jq -r .type   <<<"$entry")
    scope=$(jq -r .scope <<<"$entry")

    # skip if out of scope
    if [[ "$scope" != "universal" ]] &&
       [[ ! ( "$scope" == "os"   && "$(jq -r .os   <<<"$entry")" == "$os" ) ]] &&
       [[ ! ( "$scope" == "host" && "$(jq -r .host <<<"$entry")" == "$host" ) ]]; then
      continue
    fi

    name=$(jq -r .name   <<<"$entry")
    vault=$(jq -r .vault <<<"$entry")
    item=$(jq -r .item   <<<"$entry")
    field=$(jq -r .field <<<"$entry")

    if [[ "$type" == "env" ]]; then
      echo "⏬ Syncing env '$name' from vault '$vault'"
      secret=$(op read "op://${vault}/${item}/${field}")
      printf 'export %s=%q\n' "$name" "$secret" >> "$SECRETS_DIR/.env"
    else
      echo "🔒 Skipping file secret '$name'"
    fi
  done

  echo "✅ Done. Run → source ~/.secrets/.env"
}

# ─── MAIN ─────────────────────────────────────────────────────────────────
init
case "${1:-}" in
  -af) shift; add_file "$1" ;;
  -ae) shift; add_env  "$1" ;;
   *)  sync_all      ;;
esac
