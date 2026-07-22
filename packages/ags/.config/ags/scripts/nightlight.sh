#!/usr/bin/env bash
set -euo pipefail

LEVEL_FILE="${XDG_RUNTIME_DIR:-/tmp}/ags-hyprshade-level"
SHADER_DIR="$HOME/.config/hypr/shaders"
DEFAULT_LEVEL=3
MIN_LEVEL=1
MAX_LEVEL=5

if [[ ! -r "$LEVEL_FILE" ]]; then
  printf '%s\n' "$DEFAULT_LEVEL" > "$LEVEL_FILE"
fi

level=$(<"$LEVEL_FILE")
if ! [[ "$level" =~ ^[1-5]$ ]]; then
  level=$DEFAULT_LEVEL
  printf '%s\n' "$level" > "$LEVEL_FILE"
fi

# Hyprshade 5 queries `decoration.screen_shader`, but this Hyprland build now
# expects `decoration:screen_shader` and uses the Lua config parser. Read and
# update the option directly until Hyprshade supports the new API.
current=$(hyprctl -j getoption decoration:screen_shader 2>/dev/null | jq -r '.str // ""')
active=false
if [[ "$current" =~ /warm_([1-5])\.glsl$ ]]; then
  active=true
  level="${BASH_REMATCH[1]}"
  printf '%s\n' "$level" > "$LEVEL_FILE"
fi

set_shader() {
  local shader=${1//\\/\\\\}
  shader=${shader//\'/\\\'}
  hyprctl eval "hl.config({ decoration = { screen_shader = '$shader' } })" >/dev/null
}

apply_level() {
  set_shader "$SHADER_DIR/warm_${level}.glsl"
}

case "${1:-status}" in
  toggle)
    if [[ "$active" == true ]]; then
      set_shader ""
    else
      apply_level
    fi
    ;;
  up)
    if [[ "$active" == true ]]; then
      level=$((level - 1))
      if (( level < MIN_LEVEL )); then level=$MIN_LEVEL; fi
      printf '%s\n' "$level" > "$LEVEL_FILE"
      apply_level
    fi
    ;;
  down)
    if [[ "$active" == true ]]; then
      level=$((level + 1))
      if (( level > MAX_LEVEL )); then level=$MAX_LEVEL; fi
      printf '%s\n' "$level" > "$LEVEL_FILE"
      apply_level
    fi
    ;;
  status)
    printf '{"active":%s,"level":%s}\n' "$active" "$level"
    ;;
  *)
    echo "usage: $0 {status|toggle|up|down}" >&2
    exit 2
    ;;
esac
