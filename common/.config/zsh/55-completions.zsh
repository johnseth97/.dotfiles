# Zsh completions for the scripts in common/.bin, mirroring the _dots
# completion in 50-functions.zsh. Every entry has an on-disk --help matching
# the descriptions below.

_sync-dotfiles() {
  _arguments -S \
    '--check[report local drift for this checkout and optional repos, no network]' \
    '(-h --help)'{-h,--help}'[show usage]'
}
compdef _sync-dotfiles sync-dotfiles

_sync-notes() {
  _arguments -S \
    '--dry-run[show pending changes without committing, pulling, or pushing]' \
    '--check[report local drift, no network]' \
    '(-h --help)'{-h,--help}'[show usage]'
}
compdef _sync-notes sync-notes

_dotfiles-stow() {
  _arguments -S \
    '--platform=[target platform]:platform:(auto macos linux wsl)' \
    '--dry-run[preview the Stow operation without changing HOME]' \
    '--restow[restow the selected packages]' \
    '(-h --help)'{-h,--help}'[show usage]'
}
compdef _dotfiles-stow dotfiles-stow

_bootstrap() {
  _arguments -S \
    '--platform=[target platform]:platform:(auto macos linux wsl)' \
    '--dry-run[show work without changing the host]' \
    '--skip-packages[do not install system dependencies]' \
    '--skip-tmux-plugins[defer TPM plugin installation]' \
    '--skip-optional-repos[do not clone optional companion repos]' \
    '(-h --help)'{-h,--help}'[show usage]'
}
compdef _bootstrap bootstrap

_bootstrap-git-signing() {
  _arguments -S \
    '(-h --help)'{-h,--help}'[show usage]'
}
compdef _bootstrap-git-signing bootstrap-git-signing

_op_sync_secrets() {
  _arguments -S \
    '-af[add a file-based secret]:secret file:_files' \
    '-ae[add an env-var secret]:environment variable name' \
    '(-h --help)'{-h,--help}'[show usage]'
}
compdef _op_sync_secrets op-sync-secrets.sh

_sesh-add-current-dir() {
  _arguments -S \
    '(-h --help)'{-h,--help}'[show usage]'
}
compdef _sesh-add-current-dir sesh-add-current-dir

_setup_github_integration() {
  _arguments -S \
    '(-h --help)'{-h,--help}'[show usage]'
}
compdef _setup_github_integration setup_github_integration.sh

# Do not run network/auth checks while completing; account list is config-only.
_nvim_mail_accounts() {
  local -a account_names
  account_names=("${(@f)$(himalaya --json account list 2>/dev/null | python3 -c 'import json,sys; print("\n".join(a["name"] for a in json.load(sys.stdin).get("accounts", [])))' 2>/dev/null)}")
  (( ${#account_names} )) && compadd -- "${account_names[@]}"
}

_nvim-mail() {
  local -a actions
  actions=(
    'open:open mail, optionally naming an account'
    'add-account:launch the native Himalaya setup wizard'
    'delete-account:remove a local account entry with confirmation'
    'list-accounts:list configured accounts'
    'check-account:check account authentication and connection'
    'edit-accounts:edit private account configuration'
    'login:configure/sign in with the Microsoft OAuth helper'
  )
  if (( CURRENT == 2 )); then
    _describe 'mail action' actions
    _nvim_mail_accounts
  elif (( CURRENT == 3 )); then
    case "${words[2]}" in
      open|delete-account|check-account|login) _nvim_mail_accounts ;;
    esac
  fi
}
compdef _nvim-mail nvim-mail mail
