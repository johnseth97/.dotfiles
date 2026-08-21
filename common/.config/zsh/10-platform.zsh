# Load exactly one host-specific fragment.

if [[ "$OSTYPE" == darwin* ]]; then
  source "$DOTFILES_ZSH_DIR/macos.zsh"
elif [[ "$OSTYPE" == linux-gnu* ]] && grep -qi microsoft /proc/version 2>/dev/null; then
  source "$DOTFILES_ZSH_DIR/wsl.zsh"
elif [[ "$OSTYPE" == linux-gnu* ]]; then
  source "$DOTFILES_ZSH_DIR/linux.zsh"
else
  [[ $- == *i* && -t 1 ]] && print -u2 -- "[dotfiles] unsupported OSTYPE: $OSTYPE"
fi
