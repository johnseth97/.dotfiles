# Zsh completions for the scripts in common/.bin, mirroring the _dots
# completion in 50-functions.zsh. Every entry has an on-disk --help matching
# the descriptions below.

_sync-dotfiles() {
  _arguments -S \
    '(-h --help)'{-h,--help}'[show usage]'
}
compdef _sync-dotfiles sync-dotfiles

_sync-notes() {
  _arguments -S \
    '--dry-run[show pending changes without committing, pulling, or pushing]' \
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
