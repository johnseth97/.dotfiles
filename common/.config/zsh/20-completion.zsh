# Native completions must load before Bash compatibility completions.

if [[ -d "$HOME/.local/share/zsh/site-functions" ]]; then
  fpath=("$HOME/.local/share/zsh/site-functions" $fpath)
fi

autoload -Uz compinit
compinit

autoload -U +X bashcompinit && bashcompinit
