#!/bin/bash

TEMP_FILE="/tmp/wallpaper_state"

if [[ -f $TEMP_FILE ]]; then
    source $TEMP_FILE
else
    export WALLPAPER_MONITOR_1=0
    export WALLPAPER_MONITOR_2=0
fi

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
WALLPAPERS=("$WALLPAPER_DIR"/*)
NUM_WALLPAPERS=${#WALLPAPERS[@]}

if [[ $NUM_WALLPAPERS -eq 0 ]]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

get_active_monitor() {
    hyprctl activeworkspace -j | jq -r '.monitor'
}

set_wallpaper() {
    local monitor=$1
    local index_var=$2

    local current_index=$(eval echo \$$index_var)
    local next_index=$(( (current_index + 1) % NUM_WALLPAPERS ))

    eval export $index_var=$next_index

    hyprctl hyprpaper reload "$monitor, ${WALLPAPERS[$next_index]}"
}

ACTIVE_MONITOR=$(get_active_monitor)

if [[ "$ACTIVE_MONITOR" == "HDMI-A-1" ]]; then
    INDEX_VAR="WALLPAPER_MONITOR_1"
elif [[ "$ACTIVE_MONITOR" == "HDMI-A-2" ]]; then
    INDEX_VAR="WALLPAPER_MONITOR_2"
else
    echo "Unknown monitor: $ACTIVE_MONITOR"
    exit 1
fi

set_wallpaper "$ACTIVE_MONITOR" "$INDEX_VAR"

declare -p WALLPAPER_MONITOR_1 WALLPAPER_MONITOR_2 > "$TEMP_FILE"
