#!/bin/bash

SESSION_NAME="performance-monitor"

# Start a new tmux session, detach so we can set it up
tmux new-session -d -s $SESSION_NAME

# Window 1: System Overview
tmux rename-window -t $SESSION_NAME:0 "Overview"
tmux send-keys -t $SESSION_NAME:0 "htop" C-m

# Split Pane: CPU Monitoring
tmux split-window -v -t $SESSION_NAME:0
tmux send-keys -t $SESSION_NAME:0.1 "watch -n 1 grep 'cpu ' /proc/stat" C-m

# Split Pane: Memory Usage
tmux split-window -h -t $SESSION_NAME:0
tmux send-keys -t $SESSION_NAME:0.2 "watch -n 1 free -h" C-m

# Window 2: Disk IO
tmux new-window -t $SESSION_NAME -n "Disk IO"
tmux send-keys -t $SESSION_NAME:1 "iotop" C-m

# Window 3: Network
tmux new-window -t $SESSION_NAME -n "Network"
tmux send-keys -t $SESSION_NAME:2 "iftop" C-m

# Window 4: Logs
tmux new-window -t $SESSION_NAME -n "Logs"
tmux send-keys -t $SESSION_NAME:3 "tail -f /var/log/syslog" C-m

# Window 5: Custom Monitoring
tmux new-window -t $SESSION_NAME -n "Custom"
tmux send-keys -t $SESSION_NAME:4 "echo 'Run your custom commands here'" C-m

# Attach to the session
tmux attach-session -t $SESSION_NAME

