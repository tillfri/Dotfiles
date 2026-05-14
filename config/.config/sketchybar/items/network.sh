#!/bin/bash

network_down=(
  icon=􀄩
  icon.font="$FONT:Bold:16.0"
  label.font="$FONT:Semibold:14.0"
  label="0 KB/s"
  update_freq=2
  script="$PLUGIN_DIR/network.sh"
)

network_up=(
  icon=􀄨
  icon.font="$FONT:Bold:16.0"
  label.font="$FONT:Semibold:14.0"
  label="0 KB/s"
)

sketchybar --add item network.down right \
           --set network.down "${network_down[@]}" \
           --add item network.up right \
           --set network.up "${network_up[@]}"
