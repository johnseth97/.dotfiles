# ~/.zshrc

# Enable Profiler if $ZHS_PROFILE_STARTUP is set to 1
# Must be at the top of the file
if [[ "$ZSH_PROFILE_STARTUP" == "1" ]]; then
	zmodload zsh/zprof
fi

###############
### SOURCES ### 
###############


# Shell integrations ------------------------- {{{

# Ghostty in the shell
# Check if Ghostty is available
if [[ -n "${GHOSTTY_RESOURCES_DIR}" ]]; then
    autoload -Uz -- "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
    
    # Preserve Ghostty Terminfo for sudo
    export GHOSTTY_SHELL_INTEGRATION_FEATURES="sudo"
    export TERMINFO="${GHOSTTY_RESOURCES_DIR}/../terminfo/"

    # Ghostty bin directory
    export PATH=$PATH:$GHOSTTY_BIN_DIR

fi

# Load OS-specific configuration

if [[ "$OSTYPE" == "darwin"* ]]; then
  source "$HOME/.config/zsh/macos.zsh"
elif grep -qi microsoft /proc/version; then
  source "$HOME/.config/zsh/wsl.zsh"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  source "$HOME/.config/zsh/linux.zsh"
else
  echo "❌ Unsupported OSTYPE ($OSTYPE) – No matching zsh config in ~/.config/zsh/. Make it yourself!"
fi

# Set pager and editor to neovim
export EDITOR=nvim
export VISUAL=nvim

# Source antidote 
source ~/.antidote/antidote.zsh 

# Source secrets
source ~/.secrets/.env

# Antidote load(plugins manager) initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
antidote load

# ------------------------- }}}

##############
###  SETUP ### 
############## 

# Preferences ------------------------- {{{

# Dircolors 
export CLICOLOR=1 
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd 
alias ll="ls -alGh" 

# Case sensitive completeion
CASE_SENSITIVE="false"

# Hypen insensitive case completeion
HYPHEN_INSENSITIVE="true"

# Autocorrection
ENABLE_CORRECTION="true"
# ------------------------- }}}

# SCRIPTS -------------------- {{{

export SCRIPTS="$HOME/.scripts"
export PATH="$SCRIPTS:$PATH"

# }}}

# ALIASES -------------------- {{{ 

# Re-enable alias expansion
# setopt aliases

# Edit .zshrc
alias zshedit="nvim ~/.zshrc"

# Edit Neovim init.lua
alias vimedit="vim ~/.config/nvim/init.lua"

# Alias Vim to Neovim
alias vim="nvim"

# Alias to sync dotfiles
alias sync-dotfiles="~/.dotfiles/.bin/sync-dotfiles"

# Alias to sync secrets
alias sync-secrets="~/.dotfiles/.bin/op-sync-secrets.sh"

# Alias for lazygit
alias lg="lazygit"

# Alias to copy over terminfo to remote machine
alias ghostty-setup="infocmp -x | ssh remote-host -- tic -x -":

# Alias ls to la -lah
alias la="ls -lah"

# Aliases for tmux sessions

# IT117
alias tmuxSeshIT117="~/.config/tmux/enviroments/IT117.sh"

# Point pinentry to pinentry-mac
#alias pinentry='pinentry-mac'

# -------------------- }}}

# Init functions ------------------------- {{{

#Starship init
eval "$(starship init zsh)"

# BANNER ------------------------- {{{


# ------------------------- }}}


############
### INIT ###
############


# Call the banner function
source "$HOME/.config/zsh/banner.zsh"

# Disable the profiler for the rest of the session
unset ZSH_PROFILE_STARTUP

if [[ -z "$TMUX" && -z "$SSH_CONNECTION" && -t 0 ]]; then
  if tmux has-session -t default 2>/dev/null; then
    exec tmux attach -t default
  else
    exec tmux new -s default
  fi
fi

# End ZSHRC 

# Vim modeline
# vim:foldmethod=marker:foldlevel=0

# pnpm
export PNPM_HOME="/Users/ejohnson/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
