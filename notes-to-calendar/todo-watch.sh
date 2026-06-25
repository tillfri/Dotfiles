#!/bin/bash

inotifywait -m /mnt/x6/stuff/obsidian_vault -e create -e modify -e moved_to -e close_write --format '%e %f' |
    while read event file; do
        [ "$file" = "TODO.md" ] && ~/venv/bin/python /mnt/x6/stuff/obsidian_vault/sync_todo_calendar.py
    done
