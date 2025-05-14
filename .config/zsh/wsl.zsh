#!/bin/zsh
# WSL-Specific ZSH Configuration

echo "🔹 Loading WSL config..."

# Source /etc/profile for windows path on non-login shells
source /etc/profile

# Source bash completion for WSL
autoload -U +X bashcompinit && bashcompinit
source /etc/bash_completion.d/azure-cli

# Alias Windows SSH utilities
alias ssh='ssh.exe'
alias ssh-add='ssh-add.exe'

# Set truecolors for windows terminal
export TERM="xterm-256color"
export COLORTERM="truecolor"

# Detect Windows user home directory
windows_userprofile=$(cmd.exe /C "<nul set /p=%USERPROFILE%" 2>/dev/null | tr -d '\r')
if [[ -n "$windows_userprofile" ]]; then
  export WINHOME=$(wslpath "$windows_userprofile")
  export IS_WSL=1
else
  echo "⚠️ Could not detect Windows user profile. Is WSL interop enabled?"
fi

export PATH=$PATH:/opt/mssql-tools18/bin

# 1Password Git setup (if available)
if [ -f "$WINHOME/AppData/Local/1Password/app/8/op-ssh-sign-wsl" ]; then
  export GIT_SSH_COMMAND="ssh.exe"
  git config --global gpg.format ssh
  git config --global gpg.ssh.program "$WINHOME/AppData/Local/1Password/app/8/op-ssh-sign-wsl"
else
  echo "[1Password] Skipping Git integration - op-ssh-sign-wsl not found."
fi

