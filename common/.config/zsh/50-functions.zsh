# Interactive functions.

ghostty-setup() {
  local host=${1:?usage: ghostty-setup user@host}
  infocmp -x | ssh "$host" -- tic -x -
}

dots() {
  local action=${1:-help}
  shift $(( $# > 0 ? 1 : 0 ))

  case "$action" in
    plan) command dotfiles-stow --dry-run --restow "$@" ;;
    deploy) command dotfiles-stow --restow "$@" ;;
    sync) command sync-dotfiles "$@" ;;
    bootstrap) command bootstrap "$@" ;;
    shell-update)
      if (( $+commands[brew] )); then
        command brew upgrade antidote
      fi
      (( $+functions[antidote] )) || {
        print -u2 -- '[dots] Antidote is not loaded.'
        return 1
      }
      antidote update --bundles "$@"
      ;;
    status)
      command git -C "$HOME/.dotfiles" status --short
      ;;
    help|-h|--help)
      cat <<'EOF'
Usage: dots <action> [arguments]

  plan          preview a restow without changing $HOME
  deploy        restow packages for this platform
  sync          fast-forward dotfiles and pinned submodules, then restow,
                then sync any optional companion repo already cloned locally
  bootstrap     install dependencies and deploy a new host
  shell-update  update Homebrew Antidote, then declared Antidote plugins
  status        show dotfiles worktree state
EOF
      ;;
    *)
      print -u2 -- "[dots] unknown action: $action"
      return 2
      ;;
  esac
}

_dots() {
  local action=${words[2]:-}
  local -a actions
  actions=(
    'plan:preview a restow without changing HOME'
    'deploy:restow packages for this platform'
    'sync:update the root repo and pinned submodules, restow, then sync optional companion repos'
    'bootstrap:prepare a new host, cloning missing optional companion repos'
    'shell-update:update packaged Antidote and declared plugin bundles'
    'status:show dotfiles worktree state'
  )

  if (( CURRENT == 2 )); then
    _describe -t actions 'dots action' actions
    return
  fi

  case "$action" in
    plan|deploy)
      _arguments -S \
        '--platform=[target platform]:platform:(auto macos linux wsl)' \
        '--dry-run[show the Stow operation without changing HOME]' \
        '--restow[restow the selected packages]'
      ;;
    bootstrap)
      _arguments -S \
        '--platform=[target platform]:platform:(auto macos linux wsl)' \
        '--dry-run[show work without changing the host]' \
        '--skip-packages[do not install system dependencies]' \
        '--skip-tmux-plugins[defer TPM plugin installation]' \
        '--skip-optional-repos[do not clone optional companion repos]'
      ;;
    shell-update)
      _arguments -S \
        '(-b --bundles)'{-b,--bundles}'[update bundles only]' \
        '(-n --dry-run)'{-n,--dry-run}'[show bundle updates without applying them]'
      ;;
    sync|status)
      _message 'this action accepts no options'
      ;;
  esac
}

compdef _dots dots
