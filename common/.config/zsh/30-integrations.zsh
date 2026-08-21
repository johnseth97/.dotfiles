# Terminal and shell integrations.

if [[ -r "${GHOSTTY_RESOURCES_DIR:-}/shell-integration/zsh/ghostty-integration" ]]; then
  source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
  export GHOSTTY_SHELL_INTEGRATION_FEATURES=sudo
  export TERMINFO="${GHOSTTY_RESOURCES_DIR}/../terminfo/"
  export PATH="$PATH:$GHOSTTY_BIN_DIR"
fi

# Prefer a system-package Antidote; retain the historical local checkout only
# for hosts where no package-manager installation is available.
if (( $+commands[brew] )) && [[ -r "$(brew --prefix antidote 2>/dev/null)/share/antidote/antidote.zsh" ]]; then
  source "$(brew --prefix antidote)/share/antidote/antidote.zsh"
elif [[ -r /usr/share/antidote/antidote.zsh ]]; then
  source /usr/share/antidote/antidote.zsh
elif [[ -r /usr/share/zsh-antidote/antidote.zsh ]]; then
  source /usr/share/zsh-antidote/antidote.zsh
elif [[ -r "$HOME/.antidote/antidote.zsh" ]]; then
  source "$HOME/.antidote/antidote.zsh"
else
  print -u2 -- '[antidote] not installed; skipping plugins.'
fi

(( $+functions[antidote] )) && antidote load

# zsh-ai: natural-language -> shell command via Claude (github.com/matheusml/zsh-ai).
# API key is pulled from 1Password (item "Anthropic | personal-zsh-ai", .env vault)
# rather than stored in the dotfiles repo.
#
# Loading the plugin -- and the 1Password prompt that comes with it -- is
# deferred until zsh-ai is actually used, via the `ai`/`zsh-ai` command or the
# inline "# " trigger, instead of on every shell start.
if (( $+commands[brew] )) && (( $+commands[op] )); then
  typeset -g _ZSH_AI_PLUGIN_FILE="$(brew --prefix zsh-ai 2>/dev/null)/share/zsh-ai/zsh-ai.plugin.zsh"
  if [[ -r "$_ZSH_AI_PLUGIN_FILE" ]]; then

    # Preflight: fetch the API key and source the real plugin, once, on
    # first actual use. Cheap no-op on every call after that.
    _zsh_ai_lazy_load() {
      (( ${_zsh_ai_loaded:-0} )) && return 0
      if [[ -z "$ANTHROPIC_API_KEY" ]]; then
        if ! ANTHROPIC_API_KEY="$(op read 'op://.env/5owjgtccqsifinlgue45otzxqy/credential' 2>/dev/null)" || [[ -z "$ANTHROPIC_API_KEY" ]]; then
          print -u2 -- '[zsh-ai] could not read ANTHROPIC_API_KEY from 1Password; skipping.'
          return 1
        fi
        export ANTHROPIC_API_KEY
      fi
      source "$_ZSH_AI_PLUGIN_FILE"
      typeset -g _zsh_ai_loaded=1
    }

    # `ai` / `zsh-ai "..."` explicit invocation: preflight-load, then run for
    # real. The real plugin defines its own `zsh-ai` function on load, which
    # replaces this stub.
    zsh-ai() {
      _zsh_ai_lazy_load || return 1
      zsh-ai "$@"
    }

    # Inline "# query" trigger: preflight-load on first use, then hand off to
    # the real widget. Once loaded, the plugin rebinds `accept-line` itself
    # (via its own precmd hook) so this shim is only ever hit once.
    case "${ZSH_AI_COMMENT_HOOK:l}" in
      false|off|no|0|disabled) ;;
      *)
        _zsh_ai_lazy_accept_line() {
          local trigger="${ZSH_AI_TRIGGER:-# }"
          if [[ "$BUFFER" == "$trigger"* ]] && [[ "$BUFFER" != *$'\n'* ]] \
             && _zsh_ai_lazy_load && (( $+functions[_zsh_ai_accept_line] )); then
            _zsh_ai_accept_line
          else
            zle .accept-line
          fi
        }
        _zsh_ai_bind_lazy_widget() {
          zle -N accept-line _zsh_ai_lazy_accept_line
          add-zsh-hook -d precmd _zsh_ai_bind_lazy_widget
        }
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd _zsh_ai_bind_lazy_widget
        ;;
    esac
  fi
fi

# ToggleTerm sets this only for Neovim-managed terminal jobs. Keep vi keymaps
# in ordinary terminals while making embedded shells use familiar emacs keys.
if [[ -n "${DISABLE_TERM_VIM_MODE:-}" ]]; then
  bindkey -e
fi

if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

if (( $+commands[sesh] )); then
  eval "$(sesh completion zsh)"
fi

# Starship
eval "$(starship init zsh)"

# zoxide
eval "$(zoxide init zsh --cmd cd)"

