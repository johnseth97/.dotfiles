# Attach-or-create a local default tmux session for interactive terminals.

should_auto_tmux() {
  command -v tmux >/dev/null 2>&1 || return 1
  [[ -n "$TMUX" ]] && return 1
  [[ -n "$SSH_CONNECTION" ]] && return 1
  [[ -t 1 ]] || return 1
  [[ "${NO_TMUX:-}" == 1 ]] && return 1
  [[ "${AI_AGENT_NO_TMUX:-}" == 1 ]] && return 1
  [[ "${DISABLE_AUTO_TMUX:-}" == 1 ]] && return 1

  case "${TERM_PROGRAM:-}" in
    vscode|zed|Zed) return 1 ;;
  esac
  [[ -n "${VSCODE_INJECTION:-}" ]] && return 1
  return 0
}

if should_auto_tmux; then
  if tmux has-session -t default 2>/dev/null; then
    tmux attach -t default || print -u2 -- '[tmux] attach failed; staying in shell'
  else
    tmux new -s default || print -u2 -- '[tmux] new session failed; staying in shell'
  fi
fi
