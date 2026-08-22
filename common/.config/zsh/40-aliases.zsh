# Interactive convenience aliases. Portable automation should call .bin tools
# directly rather than rely on aliases.

alias ll='ls -alGh'
alias la='ls -lah'
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
