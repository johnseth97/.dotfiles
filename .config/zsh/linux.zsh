#!/bin/zsh
# Linux-Specific ZSH Configuration

echo "🔹 Loading Linux config..."

# Set 1Password SSH Agent if available
if [ -S "$HOME/.1password/agent.sock" ]; then
  export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
fi

# 1Password Git setup (if available)
if command -v op &>/dev/null && [ -f "/usr/local/bin/op-ssh-sign" ]; then
  export GIT_SSH_COMMAND="ssh"
  git config --global gpg.format ssh
  git config --global gpg.ssh.program "/usr/local/bin/op-ssh-sign"
else
  echo "[1Password] Skipping Git integration - 1Password CLI or op-ssh-sign missing."
fi

