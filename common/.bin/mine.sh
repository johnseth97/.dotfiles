#!/bin/sh
project=${MINE_TUI_DIR:-"$HOME/src/mine/xmrig-tui"}
binary="$project/target/release/mine-tui"
if [ ! -x "$binary" ]; then
    printf '%s\n' 'mine: release executable is missing.' >&2
    printf '%s\n' "Project: $project" 'Build there with: cargo build --release --locked' >&2
    exit 127
fi
exec "$binary" "$@"
