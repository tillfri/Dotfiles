#!/bin/bash

# Directory containing the wallpapers
WALLPAPER_DIR="$HOME/.config/swww/wallpapers"
# File to store the index of the current wallpaper
CURRENT_INDEX_FILE="$HOME/.config/swww/.current_wallpaper_index"

# Get the list of wallpapers
shopt -s nullglob
wallpapers=("$WALLPAPER_DIR"/*.{jpg,png})
wallpaper_count=${#wallpapers[@]}

# Exit if no wallpapers found
if [ $wallpaper_count -eq 0 ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Read the current index
if [ -f "$CURRENT_INDEX_FILE" ]; then
    current_index=$(cat "$CURRENT_INDEX_FILE")
else
    echo "Could not find index file"
    current_index=0
fi

# Validate current_index
if ! [[ "$current_index" =~ ^[0-9]+$ ]] || [ "$current_index" -ge "$wallpaper_count" ]; then
    current_index=0
fi

# Set the wallpaper using swww
swww img "${wallpapers[$current_index]}" --transition-fps 60 --transition-type wipe --transition-duration 2
notify-send -h string:x-canonical-private-synchronous:sys-notify -u low "switching to wallpaper $current_index"

# Increment the index
next_index=$(( (current_index + 1) % wallpaper_count ))

# Save the new index to the file
echo "$next_index" > "$CURRENT_INDEX_FILE"

# Restart waybar
pkill waybar
waybar > /dev/null 2>&1 & disown
