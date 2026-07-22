#!/bin/bash

# --- CONFIG ---
# Your specific monitor buses from ddcutil detect
BUSES=(3 4 5)
STEP=5
# File to instantly track state so we don't have to wait for slow DDC reads
STATE_FILE="/tmp/monitor_brightness"

# --- STATE MANAGEMENT ---
# If the state file doesn't exist (e.g., after a reboot), default to 50%
if [ ! -f "$STATE_FILE" ]; then
    echo 75 >"$STATE_FILE"
fi

CURRENT_BRIGHTNESS=$(cat "$STATE_FILE")

# --- LOGIC ---
if [ "$1" == "up" ]; then
    NEW_BRIGHTNESS=$((CURRENT_BRIGHTNESS + STEP))
elif [ "$1" == "down" ]; then
    NEW_BRIGHTNESS=$((CURRENT_BRIGHTNESS - STEP))
else
    # If no argument is passed, output current brightness for Waybar
    echo "${CURRENT_BRIGHTNESS}%"
    exit 0
fi

# Clamp limits so it doesn't go above 100 or below 0
if [ "$NEW_BRIGHTNESS" -gt 100 ]; then
    NEW_BRIGHTNESS=100
elif [ "$NEW_BRIGHTNESS" -lt 0 ]; then
    NEW_BRIGHTNESS=0
fi

# Save the new state instantly
echo "$NEW_BRIGHTNESS" >"$STATE_FILE"

# --- EXECUTION ---
# Loop through all 3 monitors and set brightness simultaneously in the background.
for BUS in "${BUSES[@]}"; do
    ddcutil -b "$BUS" setvcp 10 "$NEW_BRIGHTNESS" --noverify --sleep-multiplier 0.05 &
done

# --- DISPLAY FOR WAYBAR ---
echo "${NEW_BRIGHTNESS}%"
