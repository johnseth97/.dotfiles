#!/bin/zsh
# macOS-Specific ZSH Configuration

echo "🔹 Loading macOS config..."

# Alias macos specific commands
alias clip="pbcopy"
alias paste="pbpaste"
alias sync-brewfile="brew bundle --file ~/.dotfiles/macos/Brewfile"

# This is unset by default on macOS, but we want to set it for consistency across systems
export XDG_CONFIG_HOME="$HOME/.config"

# Set 1Password SSH Agent
if [ -S "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ]; then
  export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
fi

# Add Homebrew to PATH
export PATH="/opt/homebrew/bin:$PATH"

# User-installed tools that are specific to this macOS layout.
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
export PATH="$PATH:$HOME/.lmstudio/bin"
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"

# 1Password session setup. Persistent Git configuration is handled explicitly
# by ~/.bin/bootstrap-git-signing, not during every interactive shell startup.
if command -v op &>/dev/null && [ -x "/Applications/1Password.app/Contents/MacOS/op-ssh-sign" ]; then
  export GIT_SSH_COMMAND="ssh"
  [[ -t 1 ]] && export GPG_TTY="$(tty)"
else
  echo "[1Password] Skipping session setup - 1Password CLI or op-ssh-sign missing."
fi

# Dotnet
# export DOTNET_ROOT="$(brew --prefix)/share/dotnet"
# export PATH="$DOTNET_ROOT:$PATH"

export HOMEBREW_AUTO_UPDATE_SECS=86400
