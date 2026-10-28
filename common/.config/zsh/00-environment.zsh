# Portable environment and editor defaults.

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bin:$PATH"
export SCRIPTS="$HOME/.scripts"
export PATH="$SCRIPTS:$PATH"

# `go install` drops binaries in $GOPATH/bin (~/go/bin by default; GOBIN is
# unset). This has to live here rather than in 99-toolchains: 30-integrations
# gates sesh's completion init on `$+commands[sesh]`, so a later PATH edit
# would leave that fragment silently skipping.
export PATH="$HOME/go/bin:$PATH"

export EDITOR=nvim
export VISUAL=nvim
export PAGER='nvim +Man!'
export MANPAGER='nvim +Man!'

export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd

# 1Password CLI refuses to run when its config dir is itself a symlink
# (~/.config/op is Stow-folded into the dotfiles repo). Point it at the
# real path directly instead of the symlinked default.
# Resolve the deployed op dir itself, not its parent: ~/.config/zsh is a real
# directory when a host package (wsl) also contributes to it, so only the
# final component reliably resolves through Stow's fold.
export OP_CONFIG_DIR="${DOTFILES_ZSH_DIR:h}/op"
OP_CONFIG_DIR=${OP_CONFIG_DIR:A}

CASE_SENSITIVE=false
HYPHEN_INSENSITIVE=true
ENABLE_CORRECTION=true

# Load machine-local environment variables
[[ -f "$HOME/.dotfiles/.env.local" ]] &&
  source "$HOME/.dotfiles/.env.local"
