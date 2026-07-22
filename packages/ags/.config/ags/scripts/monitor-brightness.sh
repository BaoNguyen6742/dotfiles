#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 CONNECTOR [PERCENT]" >&2
  exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || usage
connector=$1
[[ $connector =~ ^[A-Za-z0-9-]+$ ]] || usage

backend=${AGS_BRIGHTNESS_BACKEND:-auto}
[[ $backend == auto || $backend == backlight || $backend == ddc ]] || usage

cache_dir="${XDG_RUNTIME_DIR:-/tmp}/ags-brightness"
mkdir -p "$cache_dir"

detect_backlight() {
  local path
  if [[ -n "${AGS_BACKLIGHT_DEVICE:-}" && -d "/sys/class/backlight/${AGS_BACKLIGHT_DEVICE}" ]]; then
    printf '%s\n' "$AGS_BACKLIGHT_DEVICE"
    return 0
  fi
  for path in /sys/class/backlight/*; do
    [[ -r "$path/brightness" && -r "$path/max_brightness" ]] || continue
    command -v brightnessctl >/dev/null 2>&1 || [[ -w "$path/brightness" ]] || continue
    basename "$path"
    return 0
  done
  return 1
}

find_ddc_bus() {
  command -v ddcutil >/dev/null 2>&1 || return 1
  ddcutil detect --brief 2>/dev/null | awk -v connector="$connector" '
    $1 == "I2C" && $2 == "bus:" { bus=$3 }
    $1 == "DRM" && $2 == "connector:" && $3 ~ ("-" connector "$") {
      sub("/dev/i2c-", "", bus)
      print bus
      exit
    }
  '
}

get_ddc_bus() {
  local cache_file="$cache_dir/${connector}.bus" bus=""
  [[ -r "$cache_file" ]] && bus=$(<"$cache_file")
  if [[ ! $bus =~ ^[0-9]+$ || ! -e "/dev/i2c-$bus" ]]; then
    bus=$(find_ddc_bus || true)
    if [[ ! $bus =~ ^[0-9]+$ ]]; then
      rm -f "$cache_file"
      return 1
    fi
    printf '%s\n' "$bus" > "$cache_file"
  fi
  printf '%s\n' "$bus"
}

backlight_device=""
ddc_bus=""

# Internal panels normally use the kernel backlight interface. External
# displays normally use DDC/CI. The explicit backend variables handle unusual
# hardware where that convention is wrong.
if [[ $backend != ddc && $connector =~ ^(eDP|EDP|LVDS|DSI)- ]]; then
  backlight_device=$(detect_backlight || true)
fi
if [[ -z "$backlight_device" && $backend != backlight ]]; then
  ddc_bus=$(get_ddc_bus || true)
fi
if [[ -z "$backlight_device" && -z "$ddc_bus" && $backend != ddc ]]; then
  # Support an unfamiliar internal connector name only on single-display
  # machines. Otherwise an unsupported external display must not control the
  # laptop panel's backlight.
  connected_displays=0
  for status_file in /sys/class/drm/card*-*/status; do
    [[ -r "$status_file" && "$(<"$status_file")" == connected ]] &&
      connected_displays=$((connected_displays + 1))
  done
  if [[ $backend == backlight || $connected_displays -le 1 ]]; then
    backlight_device=$(detect_backlight || true)
  fi
fi

get_backlight() {
  local current maximum
  if command -v brightnessctl >/dev/null 2>&1; then
    current=$(brightnessctl --class backlight --device "$backlight_device" get 2>/dev/null)
    maximum=$(brightnessctl --class backlight --device "$backlight_device" max 2>/dev/null)
  else
    current=$(<"/sys/class/backlight/$backlight_device/brightness")
    maximum=$(<"/sys/class/backlight/$backlight_device/max_brightness")
  fi
  awk -v current="$current" -v maximum="$maximum" 'BEGIN {
    if (maximum+0 <= 0) print -1
    else printf "%.4f\n", (current+0)/(maximum+0)
  }'
}

set_backlight() {
  local percent=$1 maximum target
  if command -v brightnessctl >/dev/null 2>&1; then
    brightnessctl --class backlight --device "$backlight_device" set "${percent}%" >/dev/null
  else
    maximum=$(<"/sys/class/backlight/$backlight_device/max_brightness")
    target=$(( (percent * maximum + 50) / 100 ))
    printf '%s\n' "$target" > "/sys/class/backlight/$backlight_device/brightness"
  fi
}

get_ddc() {
  local output
  output=$(ddcutil --bus "$ddc_bus" getvcp 10 --terse 2>/dev/null) || {
    rm -f "$cache_dir/${connector}.bus"
    return 1
  }
  awk '$1 == "VCP" && $2 == "10" && $3 == "C" && $5 > 0 {
    printf "%.4f\n", $4 / $5
    found=1
  }
  END { if (!found) exit 1 }' <<<"$output"
}

set_ddc() {
  local percent=$1 output maximum target
  output=$(ddcutil --bus "$ddc_bus" getvcp 10 --terse 2>/dev/null)
  maximum=$(awk '$1 == "VCP" && $2 == "10" && $3 == "C" { print $5; exit }' <<<"$output")
  [[ $maximum =~ ^[0-9]+$ && $maximum -gt 0 ]] || return 1
  target=$(( (percent * maximum + 50) / 100 ))
  ddcutil --bus "$ddc_bus" setvcp 10 "$target" --noverify >/dev/null
}

if [[ $# -eq 1 ]]; then
  if [[ -n "$backlight_device" ]]; then
    get_backlight || echo -1
  elif [[ -n "$ddc_bus" ]]; then
    get_ddc || echo -1
  else
    echo -1
  fi
  exit 0
fi

percent=$2
[[ $percent =~ ^[0-9]+$ ]] || usage
(( percent < 1 )) && percent=1
(( percent > 100 )) && percent=100

if [[ -n "$backlight_device" ]]; then
  set_backlight "$percent"
elif [[ -n "$ddc_bus" ]]; then
  set_ddc "$percent"
else
  echo "No usable brightness control found for connector $connector" >&2
  exit 1
fi
