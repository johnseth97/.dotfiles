#!/bin/bash

# Define the session name
SESSION_NAME="IT117"

# Change to the target directory
cd ~/src/IT117

# Start a new tmux session
tmux new-session -d -s $SESSION_NAME -c ~/src/IT117

# Rename the first window to 'editor' and run nvim
tmux rename-window -t $SESSION_NAME:0 'editor'
tmux send-keys -t $SESSION_NAME 'nvim' C-m

# Split the window vertically and navigate to ~/src/IT117
tmux split-window -h -c ~/src/IT117

# Run lazygit on the right pane
tmux send-keys 'lazygit' C-m

# Split the right pane horizontally and navigate to ~/src/IT117
tmux split-window -v -c ~/src/IT117

# Run btop on the bottom-right pane
tmux send-keys 'btop' C-m

# Select the left pane (where nvim is running)
tmux select-pane -L

# Attach to the session
tmux attach-session -t $SESSION_NAME

