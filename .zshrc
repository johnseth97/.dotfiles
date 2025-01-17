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
fi

# Preserve Ghostty Terminfo for sudo
export GHOSTTY_SHELL_INTEGRATION_FEATURES="sudo"
export TERMINFO="${GHOSTTY_RESOURCES_DIR}/../terminfo/"

# Ghostty bin directory
export PATH=$PATH:$GHOSTTY_BIN_DIR

# Path to homebrew export 
export PATH="/opt/homebrew/bin:$PATH" 

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/ejohnson/.lmstudio/bin"

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
    BANNER_TERMINFO=${TERMINFO_DIRS:-$TERMINFO}


    # Check if profiling is enabled
    if [[ "$ZSH_PROFILE_STARTUP" == "1" ]]; then
	PROFILER_DATA=$(zmodload zsh/zprof; zprof)

	# Ensure profiler output file exists
	PROFILER_FILE="$HOME/.zsh_profiler_data.txt"
	: > "$PROFILER_FILE"  # Truncate or create the file safely

	# Write profiler data to the file
	if [[ -n "$PROFILER_DATA" ]]; then
	    echo "$PROFILER_DATA" > "$PROFILER_FILE"
	else
	    echo "No profiler data available." > "$PROFILER_FILE"
	fi	

        # Initialize sums
        TOTAL_TIME=0
        TOTAL_SELF_TIME=0

        # Process zprof output
        if [[ -n "$PROFILER_DATA" ]]; then
            while IFS= read -r line; do
                if echo "$line" | grep -Eq '^[[:space:]]*[0-9]+\)'; then
                    TIME=$(echo "$line" | awk '{print $3}')
                    SELF_TIME=$(echo "$line" | awk '{print $6}')
                    if [[ "$TIME" =~ ^[0-9.]+$ ]] && [[ "$SELF_TIME" =~ ^[0-9.]+$ ]]; then
                        TOTAL_TIME=$(awk "BEGIN {print $TOTAL_TIME + $TIME}")
                        TOTAL_SELF_TIME=$(awk "BEGIN {print $TOTAL_SELF_TIME + $SELF_TIME}")
                    fi
                fi
            done <<< "$PROFILER_DATA"

            # Format totals
            TOTAL_TIME=$(printf "%.2fms" "$TOTAL_TIME")
            TOTAL_SELF_TIME=$(printf "%.2fms" "$TOTAL_SELF_TIME")
            PROFILER_SUMMARY="  spent: $TOTAL_TIME\n  self-time: $TOTAL_SELF_TIME"
        else
            PROFILER_SUMMARY="No profiler data available."
        fi
    fi

    # Print banner
    print -P "\n${CYAN}System:${GREEN} ${SYSTEM}${RESET}"
    print -P "${CYAN}Hostname:${YELLOW} ${HOSTNAME}${RESET}"
    print -P "${CYAN}IP Address:${BLUE} ${IP}${RESET}"
    print -P "${CYAN}Terminfo:${MAGENTA} ${BANNER_TERMINFO}${RESET}"
    print -P "${CYAN}Loaded Plugins:${RED} ${PLUGINS}${RESET}"
    print -P "${CYAN}Aliases:${RED} ${ALIASES}${RESET}"
    print -P "${CYAN}Time:${YELLOW} ${TIME}${RESET}"

    # Print profiler summary if zprof is enabled
    if [[ "$ZSH_PROFILE_STARTUP" == "1" ]]; then
	print -P "\n${CYAN}Profiler Summary:${RESET}"
	print -P "${YELLOW}${PROFILER_SUMMARY}${RESET}\n"
    fi
}

# ------------------------- }}}

# Call the banner function
display_banner

# Disable the profiler for the rest of the session
unset ZSH_PROFILE_STARTUP

# Start tmux if not in a tmux session or SSH connection
if [[ -z "$TMUX" && -z "$SSH_CONNECTION" ]]; then
  tmux attach || tmux new
fi

# End ZSHRC 

# Vim modeline
# vim:foldmethod=marker:foldlevel=0
