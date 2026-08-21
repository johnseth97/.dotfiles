#!/bin/zsh
# Linux-Specific ZSH Configuration

echo "🔹 Loading Linux config..."

# Set 1Password SSH Agent if available
if [ -S "$HOME/.1password/agent.sock" ]; then
  export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
fi



# 1Password session setup. Persistent Git configuration is handled explicitly
# by ~/.bin/bootstrap-git-signing, not during every interactive shell startup.
if command -v op &>/dev/null && [ -f "/opt/1Password/op-ssh-sign" ]; then
  export GIT_SSH_COMMAND="ssh"
else
  echo "[1Password] Skipping session setup - 1Password CLI or op-ssh-sign missing."
fi
