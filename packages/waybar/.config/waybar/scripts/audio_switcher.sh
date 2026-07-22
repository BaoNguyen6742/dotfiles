#!/bin/bash

# 1. Get the current sound card
SINK=$(pactl get-default-sink)

# 2. Get the real internal names (analog-output-...)
RAW_PORTS=$(pactl list sinks | sed -n "/$SINK/,/^[[:space:]]*$/p" | grep "analog-output" | awk -F': ' '{print $1}' | sed 's/^[[:space:]]*//')

# 3. Create a "Pretty List" for Rofi (Removing 'analog-output-' and Capitalizing)
# Example: analog-output-speaker -> Speaker
PRETTY_LIST=$(echo "$RAW_PORTS" | sed 's/analog-output-//g; s/\b\(.\)/\u\1/g')

# 4. Show the Pretty List in Rofi
SELECTED_PRETTY=$(echo "$PRETTY_LIST" | rofi -dmenu -i -p "󰓃 Audio Output:" -config ~/.config/rofi/config.rasi)

# 5. Logic to convert the Pretty Name back to the Real Name
if [ -n "$SELECTED_PRETTY" ]; then
    # Convert "Speaker" back to "speaker" then add the prefix back
    CLEAN_NAME=$(echo "$SELECTED_PRETTY" | tr '[:upper:]' '[:lower:]')
    REAL_NAME="analog-output-$CLEAN_NAME"

    # Apply the switch using the REAL name
    pactl set-sink-port "$SINK" "$REAL_NAME"

    # Show notification using the PRETTY name
    notify-send "Audio Switch" "Active: $SELECTED_PRETTY" -i audio-speakers -t 2000
fi
