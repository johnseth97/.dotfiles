# Portable environment and editor defaults.

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bin:$PATH"
export SCRIPTS="$HOME/.scripts"
export PATH="$SCRIPTS:$PATH"

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
