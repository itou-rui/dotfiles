#!/bin/bash

# Filename: ~/.config/sketchybar/felixkratz-linkarzu/items/custom_text.sh
# ~/.config/sketchybar/felixkratz-linkarzu/items/custom_text.sh

notification=(
  updates=on
  # update_freq=10
  label.drawing=on
  padding_right=3
  label.font="$FONT:Bold:17.0"
  # label.padding_left=3
  script="$PLUGIN_DIR/notification.sh"
)

sketchybar --add item notification right \
  --set notification "${notification[@]}"
