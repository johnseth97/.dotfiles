# ~/.zshrc -- ordered loader for portable shell configuration.

# Startup profiling must be enabled before any fragment is sourced.
if [[ "${ZSH_PROFILE_STARTUP:-}" == 1 ]]; then
  zmodload zsh/zprof
fi

typeset -g DOTFILES_ZSH_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
for dotfiles_zsh_fragment in "$DOTFILES_ZSH_DIR"/[0-9][0-9]-*.zsh(N); do
  source "$dotfiles_zsh_fragment"
done
unset dotfiles_zsh_fragment
