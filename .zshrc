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
elif [[ -n "$WSL_DISTRO_NAME" ]]; then
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

# lse explains everything about a file, as in ls explain
source ~/.dotfiles/.scripts/lse.sh

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

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
# ------------------------- }}}	

# BANNER ------------------------- {{{


# ------------------------- }}}


############
### INIT ###
############


# Call the banner function
source "$HOME/.config/zsh/banner.zsh"

# Disable the profiler for the rest of the session
unset ZSH_PROFILE_STARTUP

# Start tmux if not in a tmux session or SSH connection
if [[ -z "$TMUX" && -z "$SSH_CONNECTION" ]]; then
  tmux attach || tmux new
fi

# End ZSHRC 

# Vim modeline
# vim:foldmethod=marker:foldlevel=0
