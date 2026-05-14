#!/bin/bash

ram=(
    icon=􀫦
    icon.font="$FONT:Bold:16.0"
    label.font="$FONT:Semibold:14.0"
    script="$PLUGIN_DIR/ram.sh"
    update_freq=5
)

sketchybar --add item ram left \
    --set ram "${ram[@]}"
