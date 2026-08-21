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
export OP_CONFIG_DIR="$HOME/.dotfiles/common/.config/op"

CASE_SENSITIVE=false
HYPHEN_INSENSITIVE=true
ENABLE_CORRECTION=true
