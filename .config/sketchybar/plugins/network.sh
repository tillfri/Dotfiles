#!/usr/bin/env bash

INTERFACE="en0"

BYTES_IN=$(netstat -ib | grep -e "$INTERFACE" -m 1 | awk '{print $7}')
BYTES_OUT=$(netstat -ib | grep -e "$INTERFACE" -m 1 | awk '{print $10}')

CACHE_FILE="/tmp/sketchybar_network_$INTERFACE"

if [[ -f "$CACHE_FILE" ]]; then
    PREV_IN=$(cut -d' ' -f1 "$CACHE_FILE")
    PREV_OUT=$(cut -d' ' -f2 "$CACHE_FILE")
    PREV_TIME=$(cut -d' ' -f3 "$CACHE_FILE")
    
    NOW=$(date +%s)
    ELAPSED=$((NOW - PREV_TIME))
    
    if [[ $ELAPSED -gt 0 ]]; then
        DOWN=$(( (BYTES_IN - PREV_IN) / ELAPSED / 1024 ))
        UP=$(( (BYTES_OUT - PREV_OUT) / ELAPSED / 1024 ))
    else
        DOWN=0
        UP=0
    fi
else
    DOWN=0
    UP=0
fi

echo "$BYTES_IN $BYTES_OUT $(date +%s)" > "$CACHE_FILE"

if [[ $DOWN -gt 1024 ]]; then
    DOWN_FORMAT=$(awk "BEGIN {printf \"%.1f MB/s\", $DOWN/1024}")
else
    DOWN_FORMAT="${DOWN} KB/s"
fi

if [[ $UP -gt 1024 ]]; then
    UP_FORMAT=$(awk "BEGIN {printf \"%.1f MB/s\", $UP/1024}")
else
    UP_FORMAT="${UP} KB/s"
fi

sketchybar --set network.down label="$DOWN_FORMAT" \
           --set network.up label="$UP_FORMAT"
