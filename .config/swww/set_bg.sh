#!/bin/bash

swww img ~/.config/swww/wallpapers/$1

pkill waybar
waybar > /dev/null 2>&1 & disown
