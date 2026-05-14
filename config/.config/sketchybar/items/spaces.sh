#!/bin/bash
#!/bin/sh

#SPACE_ICONS=("1" "2" "3" "4")

# Destroy space on right click, focus space on left click.
# New space by left clicking separator (>)

sketchybar --add event aerospace_workspace_change

for sid in $(aerospace list-workspaces --all); do
    space=(
        space="$sid"
        icon="$sid"
        icon.highlight_color=$RED
        icon.padding_left=10
        icon.padding_right=10
        display=1
        padding_left=2
        padding_right=2
        label.padding_right=20
        label.color=$GREY
        label.highlight_color=$WHITE
        label.font="sketchybar-app-font:Regular:16.0"
        label.y_offset=-1
        background.color=$BACKGROUND_1
        background.border_color=$BACKGROUND_2
        script="$PLUGIN_DIR/space.sh"
        update_freq=2
    )

    sketchybar --add space space.$sid center \
        --set space.$sid "${space[@]}" \
        --subscribe space.$sid aerospace_workspace_change

    apps=$(aerospace list-windows --workspace $sid | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')

    icon_strip=" "
    if [ "${apps}" != "" ]; then
        while read -r app; do
            icon_strip+=" $($CONFIG_DIR/plugins/icon_map.sh "$app")"
        done <<<"${apps}"
    else
        icon_strip=" —"
    fi

    sketchybar --set space.$sid label="$icon_strip"
done
