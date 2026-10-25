# Render Starship's config through a cache, rebuilt only when its inputs
# change: recoloured with exact Omarchy theme colours when there is a theme,
# and inside tmux without the git branch/status modules, which the tmux
# status bar's git pill already shows. Outside tmux (SSH, editor terminals,
# NO_TMUX) the prompt keeps them. The portable Starship config stays untouched.
_dotfiles_starship_palette() {
  local base="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
  local theme="$HOME/.local/state/omarchy/current/theme/colors.toml"
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/starship"
  local target="$cache/prompt${TMUX:+-tmux}.toml"
  [[ -r $base ]] || return 0
  [[ -r $theme || -n ${TMUX:-} ]] || return 0
  (( $+commands[python3] )) || return 0
  # Respect an explicitly selected alternate Starship configuration. Either
  # cache may arrive inherited, e.g. by a tmux server started from a shell.
  [[ -z ${STARSHIP_CONFIG:-} || $STARSHIP_CONFIG == $base || $STARSHIP_CONFIG == $cache/* ]] || return 0
  zmodload -F zsh/stat b:zstat
  local -A base_stat theme_stat
  zstat -H base_stat "$base" 2>/dev/null || return 0
  [[ -r $theme ]] && zstat -H theme_stat "$theme" 2>/dev/null
  local stamp="${base_stat[inode]}:${base_stat[mtime]}:${base_stat[size]}:${theme_stat[inode]}:${theme_stat[mtime]}:${theme_stat[size]}"
  if [[ $stamp != ${_dotfiles_starship_palette_stamp:-} || ! -f $target ]]; then
    python3 - "$base" "$theme" "$target" "${TMUX:+tmux}" <<'PY'
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import tomllib


def theme_colors(path):
    """colors.toml, plus the named slots Omarchy derives from it.

    Many themes define only color0-15/accent; omarchy-theme-color maps those
    onto names such as blue and magenta (as the tmux palette hook does)."""
    colors = tomllib.loads(path.read_text())
    try:
        derived = subprocess.run(['omarchy-theme-color', '--file', str(path), '--all'],
                                 capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.SubprocessError):
        return colors
    for line in derived.splitlines():
        key, _, value = line.partition('\t')
        if value:
            colors.setdefault(key, value)
    return colors


base, theme, target = map(Path, sys.argv[1:4])
in_tmux = sys.argv[4] == 'tmux'
try:
    source = base.read_text()
    config = tomllib.loads(source)
    palette = config['palettes']['omarchy'].copy()
    if theme.is_file():
        colors = theme_colors(theme)
        for key in palette:
            value = colors.get(key, palette[key])
            if not isinstance(value, str) or not re.fullmatch(r'#[0-9a-fA-F]{6}', value):
                raise ValueError('Invalid theme colour: ' + key)
            palette[key] = value
    # The fallback palette is deliberately the final table in the source.
    source = source.split('[palettes.omarchy]', 1)[0]
    if in_tmux:
        for module in ('git_branch', 'git_status'):
            if 'disabled' in config.get(module, {}):
                continue  # an explicit choice in starship.toml wins
            header = re.compile(r'^\[' + module + r'\][ \t]*$', re.M)
            if header.search(source):
                source = header.sub(lambda m: m.group(0) + '\ndisabled = true', source, count=1)
            else:
                source += f'\n[{module}]\ndisabled = true\n'
    source += '[palettes.omarchy]\n' + ''.join(
        f'{key} = "{value}"\n' for key, value in palette.items())
    tomllib.loads(source)
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode='w', dir=target.parent, delete=False) as output:
        output.write(source)
    os.replace(output.name, target)
except (OSError, ValueError, KeyError) as error:
    print(f'[starship palette] {error}', file=sys.stderr)
    sys.exit(1)
PY
    (( $? == 0 )) || return 0
    typeset -g _dotfiles_starship_palette_stamp=$stamp
  fi
  export STARSHIP_CONFIG="$target"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _dotfiles_starship_palette
_dotfiles_starship_palette
