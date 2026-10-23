# Attach-or-create a local default tmux session for interactive terminals.

should_auto_tmux() {
  command -v tmux >/dev/null 2>&1 || return 1
  [[ -n "$TMUX" ]] && return 1
  [[ -n "$SSH_CONNECTION" ]] && return 1
  [[ -t 1 ]] || return 1
  [[ "${NO_TMUX:-}" == 1 ]] && return 1
  [[ "${AI_AGENT_NO_TMUX:-}" == 1 ]] && return 1
  [[ "${DISABLE_AUTO_TMUX:-}" == 1 ]] && return 1

  # Known AI coding-agent CLIs mark shells they spawn with their own env
  # vars. Treat any of them like AI_AGENT_NO_TMUX so each tool doesn't need
  # its own opt-in -- some (e.g. Codex) hand their commands a real pty, so
  # the `-t 1` check above alone isn't enough to keep them out of `default`.
  # Add more as other agents are identified.
  [[ -n "${CLAUDECODE:-}" ]] && return 1                             # Claude Code
  [[ -n "${CODEX_SANDBOX:-}" || -n "${CODEX_HOME:-}" ]] && return 1  # OpenAI Codex CLI

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
