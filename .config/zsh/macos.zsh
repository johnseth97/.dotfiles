#!/bin/zsh
# macOS-Specific ZSH Configuration

echo "🔹 Loading macOS config..."

# Set 1Password SSH Agent
if [ -S "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ]; then
  export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
fi

# Add Homebrew to PATH
export PATH="/opt/homebrew/bin:$PATH"

# 1Password Git setup (if available)
if command -v op &>/dev/null; then
  export GIT_SSH_COMMAND="ssh"
  export GPG_TTY=$(tty)
  git config --global gpg.format ssh
  git config --global gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
else
  echo "[1Password] Skipping Git integration - 1Password CLI not found."
fi

