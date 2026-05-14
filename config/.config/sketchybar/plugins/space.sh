#!/bin/bash

#echo space.sh $'FOCUSED_WORKSPACE': $FOCUSED_WORKSPACE, $'SELECTED': $SELECTED, NAME: $NAME, SENDER: $SENDER  >> ~/aaaa

update() {
    source "$CONFIG_DIR/colors.sh"

    SID="${NAME#space.}"

    if [ "$SID" = "$FOCUSED_WORKSPACE" ]; then
        sketchybar --set $NAME icon.highlight=true \
            label.highlight=true \
            background.border_color=$GREY
    else
        sketchybar --set $NAME icon.highlight=false \
            label.highlight=false \
            background.border_color=$BACKGROUND_2
    fi
}

update_icons() {
    SID="${NAME#space.}"

    apps=$(aerospace list-windows --workspace $SID | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')

    icon_strip=" "
    if [ "${apps}" != "" ]; then
        while read -r app; do
            icon_strip+=" $($CONFIG_DIR/plugins/icon_map.sh "$app")"
        done <<<"${apps}"
    else
        icon_strip=" —"
    fi

    sketchybar --set $NAME label="$icon_strip"
}

set_space_label() {
    sketchybar --set $NAME icon="$@"
}

mouse_clicked() {
    if [ "$BUTTON" = "right" ]; then
        # yabai -m space --destroy $SID
        echo ''
    else
        if [ "$MODIFIER" = "shift" ]; then
            SPACE_LABEL="$(osascript -e "return (text returned of (display dialog \"Give a name to space $NAME:\" default answer \"\" with icon note buttons {\"Cancel\", \"Continue\"} default button \"Continue\"))")"
            if [ $? -eq 0 ]; then
                if [ "$SPACE_LABEL" = "" ]; then
                    set_space_label "${NAME:6}"
                else
                    set_space_label "${NAME:6} ($SPACE_LABEL)"
                fi
            fi
        else
            #yabai -m space --focus $SID 2>/dev/null
            #echo space.sh BUTTON: $BUTTON, $'SELECTED': $SELECTED, MODIFIER: $MODIFIER, NAME: $NAME, SENDER: $SENDER, INFO: $INFO, TEST: ${NAME#*.}, ${NAME:6} >> ~/aaaa
            aerospace workspace ${NAME#*.}
        fi
    fi
}

case "$SENDER" in
"mouse.clicked")
    mouse_clicked
    ;;
"aerospace_workspace_change")
    update
    ;;
"routine")
    update_icons
    ;;
esac
