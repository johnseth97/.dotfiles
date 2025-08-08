# ~/.config/zsh/wsl.zsh
# bail if not in WSL
grep -qi microsoft /proc/version || return

echo "🔹 Detected WSL; re-injecting full Windows PATH…"

# 1) pull the Windows PATH string
windows_path=$(
  cmd.exe /C "echo %PATH%" 2>/dev/null \
  | tr -d '\r'
)

# 2) split on ';' and convert each to a POSIX mount
fix_wsl2_interop() {
    for i in $(pstree -np -s $$ | grep -o -E '[0-9]+'); do
        if [[ -e "/run/WSL/${i}_interop" ]]; then
            export WSL_INTEROP=/run/WSL/${i}_interop
        fi
    done
}


# Alias Windows SSH utilities
alias ssh='ssh.exe'
alias ssh-add='ssh-add.exe'
alias clip='clip.exe'

# Set truecolors for windows terminal
export TERM="xterm-256color"
export COLORTERM="truecolor"

export PATH=$PATH:/opt/mssql-tools18/bin

# 1Password Git setup (if available)
if [ -f "$WINHOME/AppData/Local/1Password/app/8/op-ssh-sign-wsl" ]; then
  export GIT_SSH_COMMAND="ssh.exe"
  git config --global gpg.format ssh
  git config --global gpg.ssh.program "$WINHOME/AppData/Local/1Password/app/8/op-ssh-sign-wsl"
else
  echo "[1Password] Skipping Git integration - op-ssh-sign-wsl not found."
fi

