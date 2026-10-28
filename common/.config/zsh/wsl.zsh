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

# Git's SSH client (core.sshCommand) and 1Password signing (gpg.ssh.program,
# via ~/.bin/bootstrap-git-signing) are persistent Git configuration, not set
# during every interactive shell startup.

# Optional host-folder integration is owned by the WSL Stow package.
[[ -r "$HOME/.config/zsh/sync-windows-folders.zsh" ]] && source "$HOME/.config/zsh/sync-windows-folders.zsh"

# WSL/Fedora development tools.
export PATH="$HOME/.aspire/bin:$PATH"
export SSL_CERT_DIR="$HOME/.aspnet/dev-certs/trust:/etc/pki/tls/certs"

# Podman is the container runtime: the Windows Podman machine (rootful, the
# Windows default connection), reached through the socket it publishes to WSL.
# The podman CLI here runs as a remote client; the docker CLI and Docker-API
# tools (e.g. Testcontainers) use the same engine. Aspire ignores shell aliases:
# it needs a real `podman` on PATH plus ASPIRE_CONTAINER_RUNTIME.
export ASPIRE_CONTAINER_RUNTIME=podman
_podman_sock=/mnt/wsl/podman-sockets/podman-machine-default/podman-root.sock
if [[ -S "$_podman_sock" ]]; then
  export CONTAINER_HOST="unix://$_podman_sock"
  export DOCKER_HOST="unix://$_podman_sock"
fi
unset _podman_sock
if command -v podman >/dev/null 2>&1; then
  alias docker='podman'
  alias docker-compose='podman compose'
fi
