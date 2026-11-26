#!/bin/bash

LEVEL_FILE="/tmp/shader_level"
HYPR_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"

apply_level() {
    local name="warm_${1}.glsl"
    local shader="$HYPR_CONFIG_DIR/shaders/$name"
    if [[ ! -r "$shader" ]]; then
        shader="$HYPR_CONFIG_DIR/hypr_conf/shaders/$name"
    fi
    if [[ ! -r "$shader" ]]; then
        printf 'Night light: %s not found in either shader directory under %s\n' "$name" "$HYPR_CONFIG_DIR" >&2
        return 1
    fi
    hyprshade on "$shader"
}

# Set default level
if [ ! -f "$LEVEL_FILE" ]; then
    echo "3" >"$LEVEL_FILE"
fi
CURRENT_LEVEL=$(cat "$LEVEL_FILE")

# --- HANDLE ARGUMENTS ---
if [ "$1" == "toggle" ]; then
    if [ "$(hyprshade current)" ]; then # Check if ANY shader is active
        hyprshade off
    else
        apply_level "$CURRENT_LEVEL" || exit $?
    fi
    exit 0

elif [ "$1" == "up" ]; then
    if [ ! "$(hyprshade current)" ]; then exit 0; fi # Do nothing if OFF
    NEW_LEVEL=$((CURRENT_LEVEL - 1))
    if [ "$NEW_LEVEL" -lt 1 ]; then NEW_LEVEL=1; fi
    echo "$NEW_LEVEL" >"$LEVEL_FILE"
    apply_level "$NEW_LEVEL"
    exit $?

elif [ "$1" == "down" ]; then
    if [ ! "$(hyprshade current)" ]; then exit 0; fi # Do nothing if OFF
    NEW_LEVEL=$((CURRENT_LEVEL + 1))
    if [ "$NEW_LEVEL" -gt 5 ]; then NEW_LEVEL=5; fi
    echo "$NEW_LEVEL" >"$LEVEL_FILE"
    apply_level "$NEW_LEVEL"
    exit $?
fi

# --- OUTPUT JSON ---
if [ "$(hyprshade current)" ]; then
    LEVEL=$(hyprshade current | sed 's/warm_//')
    printf '{"text": "WARM %s", "tooltip": "Warm Light: ON (Level %s/5)\\nScroll to change level", "class": "active", "alt": "on"}\n' "$LEVEL" "$LEVEL"
else
    printf '{"text": "OFF", "tooltip": "Warm Light: OFF", "class": "inactive", "alt": "off"}\n'
fi
