#!/usr/bin/env python3
"""Recolour the existing Tokyo Night layout after tmux.conf loads it."""

import os
from pathlib import Path
import re
import subprocess
import tomllib


def tmux(*args):
    return subprocess.run(['tmux', *args], check=True, capture_output=True,
                          text=True).stdout.rstrip('\n')


def blend(foreground, alpha, background):
    # Match tokyonight.util.blend's nearest-integer rounding.
    channels = (
        int(alpha * int(foreground[i:i+2], 16)
            + (1-alpha) * int(background[i:i+2], 16) + 0.5)
        for i in (1, 3, 5)
    )
    return '#' + ''.join(f'{channel:02x}' for channel in channels)


def main():
    config = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config'))
    path = config / 'theme/colors.toml'
    if not path.is_file():
        return
    colors = tomllib.loads(path.read_text())
    for key in ('background', 'foreground', *(f'color{i}' for i in range(16))):
        if not re.fullmatch(r'#[0-9a-fA-F]{6}', colors.get(key, '')):
            raise ValueError(f'Invalid or missing palette colour: {key}')
    bg, fg = colors['background'], colors['foreground']
    gutter = blend(fg, 0.15, bg)
    purple = colors.get('magenta', colors['color5'])
    replacements = {
        '#24283b': bg,
        '#1f2335': blend(bg, 0.8, '#000000'),
        '#1e2030': blend(bg, 0.8, '#000000'),
        '#292e42': blend(fg, 0.1, bg),
        '#3b4261': gutter,
        '#414868': gutter,
        '#565f89': colors['color8'],
        '#737aa2': blend(colors['color8'], 0.6, fg),
        '#c0caf5': fg,
        '#a9b1d6': fg,
        '#ffffff': fg,
        '#7aa2f7': colors.get('blue', colors['color4']),
        '#9ece6a': colors.get('green', colors['color2']),
        '#f7768e': colors.get('red', colors['color1']),
        '#e0af68': colors.get('yellow', colors['color3']),
        '#bb9af7': colors.get('bright_magenta', colors['color13']),
        '#9d7cd8': purple,
        '#6f62a0': blend(purple, 0.5, gutter),
    }
    options = (
        'status-style', 'status-left', 'status-right', 'status-left-style',
        'status-right-style', 'message-style', 'message-command-style',
        'pane-active-border-style', 'pane-border-style', 'mode-style',
        'window-status-style', 'window-status-current-style',
        'window-status-format', 'window-status-current-format',
        'window-status-activity-style', 'window-status-bell-style',
    )
    for option in options:
        original = tmux('show-options', '-gv', option)
        updated = re.sub(r'#[0-9a-fA-F]{6}\b',
                         lambda match: replacements.get(match[0].lower(), match[0]),
                         original)
        if updated != original:
            tmux('set-option', '-g', option, updated)


if __name__ == '__main__':
    main()
