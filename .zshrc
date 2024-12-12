# ~/.zshrc

# SETTINGS ------------------------- {{{ 
###############
### SOURCES ### 
###############
# Ghostty in the shell

## Enable ghostty shell integration
## Ghostty shell integration for Zsh. This must be at the top of your .zshrc!
## Check if Ghostty is available

if [[ -n "${GHOSTTY_RESOURCES_DIR}" ]]; then
    autoload -Uz -- "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
    ghostty-integration
    unfunction ghostty-integration
fi

# Preserve Ghostty Terminfo for sudo
export GHOSTTY_SHELL_INTEGRATION_FEATURES="sudo"
export TERMINFO="${GHOSTTY_RESOURCES_DIR}/../terminfo"

# Ghostty bin directory
export PATH=$PATH:$GHOSTTY_BIN_DIR


# Path to homebrew export 
PATH="/opt/homebrew/bin:$PATH" 

# Source antidote 
source ~/.antidote/antidote.zsh 

# Source NVM
export PATH="/opt/homebrew/opt/node@20/bin:$PATH"

##############
###  SETUP ### 
############## 

# Dircolors 
export CLICOLOR=1 
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd 
alias ll="ls -alGh" 

# Antidote load(plugins manager) initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
antidote load

# Case sensitive completeion
CASE_SENSITIVE="false"

# Hypen insensitive case completeion
HYPHEN_INSENSITIVE="true"

# Autocorrection
ENABLE_CORRECTION="true"

# ------------------------ }}}


# PLUGINS ------------------------ {{{

# Zsh builtin plugins
plugins=( 
	git
	zsh-autosuggestions
	colored-man-pages
	zsh-syntax-highlighting
	you-should-use
)


# Source oh-my-zsh
#source $ZSH/oh-my-zsh.sh


# Homebrew plugins
# source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# source $(brew --prefix)/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
# source $(brew --prefix)/share/zsh-you-should-use/you-should-use.plugin.zsh
# ------------------------- }}}


# ALIASES -------------------- {{{ 

# Re-enable alias expansion
# setopt aliases

# Edit .zshrc
alias zshedit="nvim ~/.zshrc"

# Edit Neovim init.lua
alias vimedit="vim ~/.config/nvim/init.lua"

# Edit nix flake
alias nixedit="vim ~/nix/flake.nix"

# Rebuild Nix darwin
alias nixrebuild="darwin-rebuild switch --flake ~/nix#MacbookPro"

# Alias Vim to Neovim
alias vim="nvim"

# Alias to sync dotfiles
alias sync-dotfiles="~/.dotfiles/.bin/sync-dotfiles"

# Alias for lazygit
alias lg="lazygit"

# Alias to copy over terminfo to remote machine
alias ghostty-setup="infocmp -x | ssh remote-host -- tic -x -":

# Aliases for tmux sessions
#
# IT117
alias tmuxSeshIT117="~/.config/tmux/enviroments/IT117.sh"

# Point pinentry to pinentry-mac
#alias pinentry='pinentry-mac'
# -------------------- }}}

#Starship init
prompt off
eval "$(starship init zsh)"

# BANNER ------------------------- {{{
display_banner() {
    
    # Colors
    RED=$'\033[31m'       # Red
    GREEN=$'\033[32m'     # Green
    YELLOW=$'\033[33m'    # Yellow
    BLUE=$'\033[34m'      # Blue
    MAGENTA=$'\033[35m'   # Magenta
    CYAN=$'\033[36m'      # Cyan
    RESET=$'\033[0m'      # Reset color
    
    # Gather information
    HOSTNAME=$(hostname)
    IP=$(ipconfig getifaddr en0 2>/dev/null || echo "N/A")
    TIME=$(date "+%H:%M:%S")
    SYSTEM=$(uname -sm)
    ALIASES=$(alias | wc -l | awk '{print $1}')
    PLUGINS=${#plugins[@]:-0}


    # Print banner
    print -P "\n${CYAN}System:${GREEN} ${SYSTEM}${RESET}"
    print -P "${CYAN}Hostname:${YELLOW} ${HOSTNAME}${RESET}"
    print -P "${CYAN}IP Address:${BLUE} ${IP}${RESET}"
    print -P "${CYAN}Terminfo:${MAGENTA} ${TERMINFO}${RESET}"
    print -P "${CYAN}Loaded Plugins:${RED} ${PLUGINS}${RESET}"
    print -P "${CYAN}Aliases:${RED} ${ALIASES}${RESET}"
    print -P "${CYAN}Time:${YELLOW} ${TIME}${RESET}\n"
}
# ------------------------- }}}

# Call the banner function
display_banner

# Vim modeline
# vim:foldmethod=marker:foldlevel=0

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
