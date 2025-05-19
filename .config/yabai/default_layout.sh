#!/bin/bash

# Reset layout
yabai -m config layout bsp

# Make sure Mission Control desktops are in known order
# You would manually arrange them once and remember: 1=Ghostty, 2=ChatGPT App, etc.

# Desktop 1: Ghostty
yabai -m space 1 --focus
yabai -m window --focus $(yabai -m query --windows --space | jq '.[] | select(.app=="Ghostty") | .id')
yabai -m window --space 1
yabai -m window --toggle zoom-fullscreen

# Desktop 2: ChatGPT App
yabai -m space 2 --focus
yabai -m window --focus $(yabai -m query --windows --space | jq '.[] | select(.app=="ChatGPT") | .id')
yabai -m window --space 2
yabai -m window --toggle zoom-fullscreen

# Desktop 3: Firefox
yabai -m space 3 --focus
yabai -m window --focus $(rabai -m query --windows --space | jq '.[] | select(.app=="Firefox") | .id')
yabai -m window --space 3
yabai -m window --toggle zoom-fullscreen

# Desktop 4: Discord
yabai -m space 4 --focus
yabai -m window --focus $(yabai -m query --windows --space | jq '.[] | select(.app=="Discord") | .id')
yabai -m window --space 4
yabai -m window --toggle zoom-fullscreen

# Desktop 5 and 6: leave blank

# Desktop 7: Messages left, Mail right
yabai -m space 7 --focus
messages_id=$(yabai -m query --windows --space | jq '.[] | select(.app=="Messages") | .id')
mail_id=$(yabai -m query --windows --space | jq '.[] | select(.app=="Mail") | .id')

# Focus and warp Messages to the left
yabai -m window --focus "$messages_id"
yabai -m window "$messages_id" --move rel:west

# Focus and warp Mail to the right
yabai -m window --focus "$mail_id"
yabai -m window "$mail_id" --move rel:east

# Optional: balance the windows nicely
yabai -m space --balance
