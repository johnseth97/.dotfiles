#!/bin/zsh

FILE="$1"
SESSION="default"
EDITOR_CMD="${EDITOR:-nvim}"
BASENAME=$(basename "$FILE")
# Create a safe window name by replacing dots with underscores
SAFE_NAME=$(echo "$BASENAME" | sed 's/\./_/g')

[ -z "$FILE" ] && exit 1

if tmux has-session -t "$SESSION" 2>/dev/null; then
    # Check if a window with the safe name exists
    if tmux list-windows -t "$SESSION" -F "#{window_name}" | grep -Fxq "$SAFE_NAME"; then
        # Switch to that window
        tmux switch-client -t "${SESSION}:$SAFE_NAME"
    else
        # Create a new window with the safe name and open the file
        tmux new-window -t "$SESSION" -n "$SAFE_NAME" "$EDITOR_CMD" "$FILE"
        tmux set-window-option -t "${SESSION}:$SAFE_NAME" automatic-rename off
    fi
else
    tmux new-session -d -s "$SESSION" -n "$SAFE_NAME" "$EDITOR_CMD" "$FILE"
    tmux set-window-option -t "${SESSION}:$SAFE_NAME" automatic-rename off
fi
