#!/usr/bin/env bash
set -uo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/ags-system-stats.state"

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
idle_all=$((idle + iowait))
total=$((user + nice + system + idle + iowait + irq + softirq + steal))
now=$(cut -d' ' -f1 /proc/uptime)

iface=$(ip route show default 2>/dev/null | awk 'NR == 1 { print $5 }')
rx=0
tx=0
if [[ -n "$iface" ]]; then
  rx=$(<"/sys/class/net/$iface/statistics/rx_bytes")
  tx=$(<"/sys/class/net/$iface/statistics/tx_bytes")
fi

prev_total=$total
prev_idle=$idle_all
prev_rx=$rx
prev_tx=$tx
prev_now=$now
prev_rapl=0
if [[ -r "$STATE_FILE" ]]; then
  read -r prev_total prev_idle prev_rx prev_tx prev_now prev_rapl < "$STATE_FILE" || true
fi

cpu_usage=$(awk -v t="$total" -v pt="$prev_total" -v i="$idle_all" -v pi="$prev_idle" '
  BEGIN { dt=t-pt; di=i-pi; if (dt <= 0) print 0; else printf "%.1f", 100*(dt-di)/dt }
')
elapsed=$(awk -v n="$now" -v p="$prev_now" 'BEGIN { d=n-p; if (d <= 0) d=1; print d }')
net_down=$(awk -v n="$rx" -v p="$prev_rx" -v d="$elapsed" 'BEGIN { v=(n-p)/d; if (v<0) v=0; printf "%.0f", v }')
net_up=$(awk -v n="$tx" -v p="$prev_tx" -v d="$elapsed" 'BEGIN { v=(n-p)/d; if (v<0) v=0; printf "%.0f", v }')

mem_total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
mem_available=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
ram_usage=$(awk -v t="$mem_total" -v a="$mem_available" 'BEGIN { printf "%.1f", 100*(t-a)/t }')

read_hwmon() {
  local wanted=$1 file=$2 dir
  for dir in /sys/class/hwmon/hwmon*; do
    [[ "$(cat "$dir/name" 2>/dev/null)" == "$wanted" ]] || continue
    [[ -r "$dir/$file" ]] && cat "$dir/$file" && return 0
  done
  return 1
}

cpu_temp_raw=$(read_hwmon coretemp temp1_input 2>/dev/null || echo 0)
cpu_temp=$(awk -v value="$cpu_temp_raw" 'BEGIN { printf "%.1f", value/1000 }')
gpu_temp_raw=$(read_hwmon amdgpu temp1_input 2>/dev/null || echo 0)
gpu_temp=$(awk -v value="$gpu_temp_raw" 'BEGIN { printf "%.1f", value/1000 }')

gpu_usage=$(timeout 2 radeontop -d - -l 1 2>/dev/null | awk '
  /gpu/ { for (i=1; i<=NF; i++) if ($i=="gpu") { value=$(i+1); gsub(/[%,]/,"",value); print value; exit } }
')
[[ -n "$gpu_usage" ]] || gpu_usage=0

vram_used=0
vram_total=0
for device in /sys/class/drm/card[0-9]*/device; do
  if [[ -r "$device/mem_info_vram_total" ]]; then
    vram_used=$(cat "$device/mem_info_vram_used" 2>/dev/null || echo 0)
    vram_total=$(cat "$device/mem_info_vram_total" 2>/dev/null || echo 0)
    break
  fi
done
vram_usage=$(awk -v used="$vram_used" -v total="$vram_total" 'BEGIN { if (total<=0) print 0; else printf "%.1f", 100*used/total }')

# CPU package power from Intel RAPL. The dedicated helper has one file-read
# capability, opens only the fixed package energy counter, then drops it.
rapl_file="/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj"
rapl_reader="/usr/local/libexec/ags-rapl-read"
cpu_watts=null
rapl_energy=0
if [[ -x "$rapl_reader" ]]; then
  rapl_energy=$("$rapl_reader" 2>/dev/null || echo 0)
elif [[ -r "$rapl_file" ]]; then
  rapl_energy=$(cat "$rapl_file" 2>/dev/null || echo 0)
fi
if (( prev_rapl > 0 && rapl_energy >= prev_rapl )); then
  cpu_watts=$(awk -v e="$rapl_energy" -v p="$prev_rapl" -v d="$elapsed" 'BEGIN { printf "%.2f", (e-p)/1000000/d }')
fi

# Use a native GPU power sensor when the driver provides one.
gpu_watts=null
gpu_power_raw=$(read_hwmon amdgpu power1_average 2>/dev/null || true)
if [[ -n "$gpu_power_raw" ]]; then
  gpu_watts=$(awk -v value="$gpu_power_raw" 'BEGIN { printf "%.2f", value/1000000 }')
fi

# Battery discharge is whole-system draw, not CPU draw. Hide the meaningless
# trickle reading while charging or fully charged.
system_watts=null
battery=/sys/class/power_supply/BAT0
if [[ -r "$battery/status" && "$(<"$battery/status")" == "Discharging" ]]; then
  if [[ -r "$battery/power_now" ]]; then
    raw=$(<"$battery/power_now")
    system_watts=$(awk -v value="$raw" 'BEGIN { printf "%.2f", value/1000000 }')
  elif [[ -r "$battery/current_now" && -r "$battery/voltage_now" ]]; then
    current=$(<"$battery/current_now")
    voltage=$(<"$battery/voltage_now")
    system_watts=$(awk -v c="$current" -v v="$voltage" 'BEGIN { printf "%.2f", c*v/1000000000000 }')
  fi
fi

printf '%s %s %s %s %s %s\n' "$total" "$idle_all" "$rx" "$tx" "$now" "$rapl_energy" > "$STATE_FILE"

jq -cn \
  --argjson cpu "$cpu_usage" \
  --argjson cpuTemp "$cpu_temp" \
  --argjson cpuWatts "$cpu_watts" \
  --argjson gpu "$gpu_usage" \
  --argjson gpuTemp "$gpu_temp" \
  --argjson gpuWatts "$gpu_watts" \
  --argjson vram "$vram_usage" \
  --argjson ram "$ram_usage" \
  --argjson down "$net_down" \
  --argjson up "$net_up" \
  --argjson systemWatts "$system_watts" \
  '{cpu:$cpu,cpuTemp:$cpuTemp,cpuWatts:$cpuWatts,gpu:$gpu,gpuTemp:$gpuTemp,gpuWatts:$gpuWatts,vram:$vram,ram:$ram,down:$down,up:$up,systemWatts:$systemWatts}'
