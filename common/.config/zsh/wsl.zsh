# ~/.config/zsh/wsl.zsh
# bail if not in WSL
grep -qi microsoft /proc/version || return

# Zed's WSL agent bridge can launch an interactive-flagged shell without a
# terminal. Keep banner/tmux startup away from its transport stream even when
# TERM_PROGRAM is not propagated.
if ps -o comm= -p "$PPID" 2>/dev/null | grep -qi zed || \
   tr '\0' ' ' < "/proc/$PPID/cmdline" 2>/dev/null | grep -qi zed; then
  export AI_AGENT_NO_TMUX=1
fi

# Alias Windows SSH utilities
alias ssh='ssh.exe'
alias ssh-add='ssh-add.exe'
alias clip='clip.exe'

# Set truecolors for windows terminal
export TERM="xterm-256color"
export COLORTERM="truecolor"

export PATH="$PATH:/opt/mssql-tools18/bin"

# 1Password session setup. Persistent Git configuration is handled explicitly
# by ~/.bin/bootstrap-git-signing, not during every interactive shell startup.
windows_home="${WINHOME:-$(cmd.exe /C 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r' | wslpath -u 2>/dev/null)}"
if [ -n "$windows_home" ] && [ -f "$windows_home/AppData/Local/1Password/app/8/op-ssh-sign-wsl" ]; then
  export GIT_SSH_COMMAND="ssh.exe"
else
  [[ $- == *i* && -t 1 ]] && echo "[1Password] Skipping session setup - op-ssh-sign-wsl not found."
fi

# Optional host-folder integration is owned by the WSL Stow package.
[[ -r "$HOME/.config/zsh/sync-windows-folders.zsh" ]] && source "$HOME/.config/zsh/sync-windows-folders.zsh"

# WSL/Fedora development tools.
export PATH="$HOME/.aspire/bin:$PATH"
export SSL_CERT_DIR="$HOME/.aspnet/dev-certs/trust:/etc/pki/tls/certs"
