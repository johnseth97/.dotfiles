# Suppress the banner in editor-integrated and non-interactive (e.g. agent
# bridge) terminals unless explicitly asked.

if [[ $- == *i* && -t 1 ]]; then
  if [[ "${DOTFILES_SHOW_BANNER:-}" == 1 ]] || \
    { [[ -z "${NVIM:-}" ]] && [[ -z "${VSCODE_INJECTION:-}" ]] && [[ "${TERM_PROGRAM:-}" != vscode ]]; }; then
    source "$DOTFILES_ZSH_DIR/banner.zsh"
  fi
fi

unset ZSH_PROFILE_STARTUP
