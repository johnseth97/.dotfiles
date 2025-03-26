#!/bin/zsh
# WSL-Specific ZSH Configuration

echo "🔹 Loading WSL config..."

# Alias Windows SSH utilities
alias ssh='ssh.exe'
alias ssh-add='ssh-add.exe'

# Detect Windows user home directory
windows_userprofile=$(cmd.exe /C "<nul set /p=%USERPROFILE%" 2>/dev/null | tr -d '\r')
if [[ -n "$windows_userprofile" ]]; then
  export WINHOME=$(wslpath "$windows_userprofile")
else
  echo "⚠️ Could not detect Windows user profile. Is WSL interop enabled?"
fi

# 1Password Git setup (if available)
if [ -f "$WINHOME/AppData/Local/1Password/app/8/op-ssh-sign-wsl" ]; then
  export GIT_SSH_COMMAND="ssh.exe"
  git config --global gpg.format ssh
  git config --global gpg.ssh.program "$WINHOME/AppData/Local/1Password/app/8/op-ssh-sign-wsl"
else
  echo "[1Password] Skipping Git integration - op-ssh-sign-wsl not found."
fi

