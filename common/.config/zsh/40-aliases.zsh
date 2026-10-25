# Interactive convenience aliases. Portable automation should call .bin tools
# directly rather than rely on aliases.

# File listing. Mirrors Omarchy's default eza aliases so the same muscle
# memory works both here and at the OS level; falls back to plain ls on
# hosts without eza.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias ll='eza -lh --group-directories-first --icons=auto'
  alias la='eza -lah --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
else
  alias ll='ls -alGh'
  alias la='ls -lah'
fi
# Intentionally shadows a system mail utility; use `command mail` to bypass.
alias mail='nvim-mail'
alias vim=nvim
alias lg=lazygit
alias zshedit='nvim ~/.zshrc'
alias vimedit='nvim ~/.config/nvim/init.lua'
alias sync-secrets='$HOME/.bin/op-sync-secrets.sh'
alias tcurl='curl --proxy socks5h://127.0.0.1:9050'
alias tmuxSeshIT117='~/.config/tmux/enviroments/IT117.sh'
alias jquaste="pbpaste | nvim -c ':%!jq .' -c 'set filetype=json' -"
alias ai="zsh-ai"
alias notify-host='osc9-notify'

# Dotfiles shortcuts. `dots` is the canonical dispatcher; these are mnemonic
# shortcuts for interactive use.
alias dots-plan='dots plan'
alias dots-deploy='dots deploy'
alias dots-sync='dots sync'
alias dots-bootstrap='dots bootstrap'
alias antidote-update='dots shell-update'
alias notes-sync='sync-notes'

# Other utilities
alias mine='~/.dotfiles/common/.bin/mine.sh'
alias wallet='monero-wallet-cli --wallet-file "${XMR_WALLET_FILE:?Set XMR_WALLET_FILE in ~/.dotfiles/.env.local}" --daemon-address "${XMR_DAEMON_ADDRESS:?Set XMR_DAEMON_ADDRESS in ~/.dotfiles/.env.local}" --daemon-ssl "${XMR_DAEMON_SSL:-enabled}" --daemon-ssl-allowed-fingerprints "${XMR_DAEMON_SSL_FINGERPRINT:?Set XMR_DAEMON_SSL_FINGERPRINT in ~/.dotfiles/.env.local}" --untrusted-daemon'
