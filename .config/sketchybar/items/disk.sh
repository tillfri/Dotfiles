#!/bin/bash

disk=(
    icon=󰋊
    icon.font="$FONT:Bold:16.0"
    label.font="$FONT:Semibold:14.0"
    script="$PLUGIN_DIR/disk.sh"
    update_freq=60
)

sketchybar --add item disk left \
    --set disk "${disk[@]}"
