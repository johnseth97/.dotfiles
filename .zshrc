# SETTINGS ------------------------- {{{

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# iTerm2 Plugins
export PATH=$PATH:~/.iterm2

# git GPG support
#GPG_TTY=$(tty)
#export GPG_TTY

# Theme (see https://github.com/ohmyzsh/ohmyzsh/wiki/Themes)
ZSH_THEME="spaceship"

# Case sensitive completeion
CASE_SENSITIVE="false"

# Hypen insensitive case completeion
HYPHEN_INSENSITIVE="true"

# Auto update behavior (disabled | auto | reminder)
zstyle ':omz:update' mode reminder

# Auto-update frequency in days. Default = 13
zstyle ':omz:update' frequency 13

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
source $ZSH/oh-my-zsh.sh


# Homebrew plugins
# source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# source $(brew --prefix)/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
# source $(brew --prefix)/share/zsh-you-should-use/you-should-use.plugin.zsh
# ------------------------- }}}zo


# ALIASES -------------------- {{{ 

# Edit .zshrc
alias zshedit="nvim ~/.zshrc"

# Edit Neovim init.lua
alias vimedit="vim ~/.config/nvim/init.lua"

# Alias Vim to Neovim
alias vim="neovim"

# Point pinentry to pinentry-mac
#alias pinentry='pinentry-mac'
# -------------------- }}}

# Vim modeline
# vim:foldmethod=marker:foldlevel=0
