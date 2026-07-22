#!/usr/bin/env bash
set -uo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/ags-system-stats.state"

number_or_null() {
  awk -v value="$1" 'BEGIN {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    if (value ~ /^-?[0-9]+([.][0-9]+)?$/) print value+0
    else print "null"
  }'
}

read_hwmon() {
  local wanted=$1 file=$2 dir
  for dir in /sys/class/hwmon/hwmon*; do
    [[ "$(cat "$dir/name" 2>/dev/null)" == "$wanted" ]] || continue
    [[ -r "$dir/$file" ]] && cat "$dir/$file" && return 0
  done
  return 1
}

read_first_file() {
  local file
  for file in "$@"; do
    [[ -r "$file" ]] && cat "$file" && return 0
  done
  return 1
}

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
idle_all=$((idle + iowait))
total=$((user + nice + system + idle + iowait + irq + softirq + steal))
now=$(cut -d' ' -f1 /proc/uptime)

iface=$(ip route show default 2>/dev/null | awk 'NR == 1 { print $5 }')
rx=0
tx=0
if [[ -n "$iface" && -r "/sys/class/net/$iface/statistics/rx_bytes" ]]; then
  rx=$(<"/sys/class/net/$iface/statistics/rx_bytes")
  tx=$(<"/sys/class/net/$iface/statistics/tx_bytes")
fi

prev_total=$total
prev_idle=$idle_all
prev_rx=$rx
prev_tx=$tx
prev_now=$now
prev_energy=0
if [[ -r "$STATE_FILE" ]]; then
  # The trailing placeholder also makes upgrades tolerant of older state files
  # that accidentally stored an additional energy-range field.
  read -r prev_total prev_idle prev_rx prev_tx prev_now prev_energy _ < "$STATE_FILE" || true
fi

cpu_usage=$(awk -v t="$total" -v pt="$prev_total" -v i="$idle_all" -v pi="$prev_idle" '
  BEGIN { dt=t-pt; di=i-pi; if (dt <= 0) print 0; else printf "%.1f", 100*(dt-di)/dt }
')
elapsed=$(awk -v n="$now" -v p="$prev_now" 'BEGIN { d=n-p; if (d <= 0) d=1; print d }')
net_down=$(awk -v n="$rx" -v p="$prev_rx" -v d="$elapsed" 'BEGIN { v=(n-p)/d; if (v<0) v=0; printf "%.0f", v }')
net_up=$(awk -v n="$tx" -v p="$prev_tx" -v d="$elapsed" 'BEGIN { v=(n-p)/d; if (v<0) v=0; printf "%.0f", v }')

mem_total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
mem_available=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
ram_usage=$(awk -v t="$mem_total" -v a="$mem_available" 'BEGIN { if (t<=0) print 0; else printf "%.1f", 100*(t-a)/t }')

# Prefer an explicit path, then the common AMD and Intel package sensors.
cpu_temp_raw=""
if [[ -n "${AGS_CPU_TEMP_PATH:-}" && -r "${AGS_CPU_TEMP_PATH}" ]]; then
  cpu_temp_raw=$(<"${AGS_CPU_TEMP_PATH}")
else
  cpu_temp_raw=$(
    read_hwmon k10temp temp1_input 2>/dev/null ||
      read_hwmon zenpower temp1_input 2>/dev/null ||
      read_hwmon coretemp temp1_input 2>/dev/null ||
      read_hwmon cpu_thermal temp1_input 2>/dev/null ||
      true
  )
fi
cpu_temp=null
if [[ $cpu_temp_raw =~ ^[0-9]+$ ]]; then
  cpu_temp=$(awk -v value="$cpu_temp_raw" 'BEGIN { printf "%.1f", value/1000 }')
fi

# Select the display GPU. boot_vga avoids choosing a sleeping discrete GPU on
# most hybrid laptops. AGS_GPU_CARD=cardN can override the automatic choice.
gpu_card=""
if [[ -n "${AGS_GPU_CARD:-}" && -d "/sys/class/drm/${AGS_GPU_CARD}/device" ]]; then
  gpu_card="/sys/class/drm/${AGS_GPU_CARD}"
else
  for card in /sys/class/drm/card[0-9]*; do
    [[ -r "$card/device/vendor" ]] || continue
    if [[ "$(cat "$card/device/boot_vga" 2>/dev/null)" == 1 ]]; then
      gpu_card=$card
      break
    fi
    [[ -n "$gpu_card" ]] || gpu_card=$card
  done
fi

gpu_device="${gpu_card:+$gpu_card/device}"
gpu_vendor="${AGS_GPU_VENDOR:-}"
if [[ -z "$gpu_vendor" && -r "$gpu_device/vendor" ]]; then
  case "$(<"$gpu_device/vendor")" in
    0x10de) gpu_vendor=nvidia ;;
    0x1002) gpu_vendor=amd ;;
    0x8086) gpu_vendor=intel ;;
  esac
fi

gpu_usage=null
gpu_temp=null
gpu_watts=null
vram_usage=null

read_gpu_hwmon() {
  local pattern=$1 file
  for file in "$gpu_device"/hwmon/hwmon*/$pattern; do
    [[ -r "$file" ]] && cat "$file" && return 0
  done
  return 1
}

# Use card-specific sysfs data first where the DRM driver exposes it.
if [[ -n "$gpu_device" ]]; then
  gpu_busy_raw=$(read_first_file "$gpu_device/gpu_busy_percent" "$gpu_device/gt_busy_percent" 2>/dev/null || true)
  [[ -n "$gpu_busy_raw" ]] && gpu_usage=$(number_or_null "$gpu_busy_raw")

  gpu_temp_raw=$(read_gpu_hwmon 'temp1_input' 2>/dev/null || true)
  [[ -n "$gpu_temp_raw" ]] && gpu_temp=$(awk -v value="$gpu_temp_raw" 'BEGIN { printf "%.1f", value/1000 }')

  gpu_power_raw=$(read_gpu_hwmon 'power1_average' 2>/dev/null || read_gpu_hwmon 'power1_input' 2>/dev/null || true)
  [[ -n "$gpu_power_raw" ]] && gpu_watts=$(awk -v value="$gpu_power_raw" 'BEGIN { printf "%.2f", value/1000000 }')

  if [[ -r "$gpu_device/mem_info_vram_total" ]]; then
    vram_used=$(cat "$gpu_device/mem_info_vram_used" 2>/dev/null || echo 0)
    vram_total=$(cat "$gpu_device/mem_info_vram_total" 2>/dev/null || echo 0)
    vram_usage=$(awk -v used="$vram_used" -v total="$vram_total" 'BEGIN {
      if (total+0 <= 0) print "null"; else printf "%.1f", 100*(used+0)/(total+0)
    }')
  fi
fi

# NVIDIA's proprietary driver exposes metrics through nvidia-smi instead of
# standard hwmon/DRM files. Restrict the query to the selected PCI device.
if [[ "$gpu_vendor" == nvidia ]] && command -v nvidia-smi >/dev/null 2>&1; then
  pci_id=$(basename "$(readlink -f "$gpu_device" 2>/dev/null)" 2>/dev/null)
  nvidia_args=()
  [[ $pci_id =~ ^[0-9a-fA-F]{4}: ]] && nvidia_args+=(--id="$pci_id")
  nvidia_stats=$(timeout 2 nvidia-smi "${nvidia_args[@]}" \
    --query-gpu=utilization.gpu,temperature.gpu,power.draw,memory.used,memory.total \
    --format=csv,noheader,nounits 2>/dev/null | head -n 1)
  if [[ -n "$nvidia_stats" ]]; then
    IFS=, read -r nvidia_usage nvidia_temp nvidia_power nvidia_vram_used nvidia_vram_total <<<"$nvidia_stats"
    gpu_usage=$(number_or_null "$nvidia_usage")
    gpu_temp=$(number_or_null "$nvidia_temp")
    gpu_watts=$(number_or_null "$nvidia_power")
    vram_usage=$(awk -v used="$nvidia_vram_used" -v total="$nvidia_vram_total" 'BEGIN {
      if (total+0 <= 0) print "null"; else printf "%.1f", 100*(used+0)/(total+0)
    }')
  fi
elif [[ "$gpu_vendor" == amd && "$gpu_usage" == null ]] && command -v radeontop >/dev/null 2>&1; then
  gpu_usage=$(timeout 2 radeontop -d - -l 1 2>/dev/null | awk '
    /gpu/ { for (i=1; i<=NF; i++) if ($i=="gpu") { value=$(i+1); gsub(/[%,]/,"",value); print value+0; found=1; exit } }
    END { if (!found) print "null" }
  ')
fi

# CPU package power can come directly from hwmon (for example zenpower), from
# a readable powercap energy counter, or from the optional fixed-purpose helper.
cpu_watts=null
cpu_power_raw=""
if [[ -n "${AGS_CPU_POWER_PATH:-}" && -r "${AGS_CPU_POWER_PATH}" ]]; then
  cpu_power_raw=$(<"${AGS_CPU_POWER_PATH}")
else
  cpu_power_raw=$(
    read_hwmon zenpower power1_average 2>/dev/null ||
      read_hwmon zenpower power1_input 2>/dev/null ||
      read_hwmon fam15h_power power1_average 2>/dev/null ||
      read_hwmon k10temp power1_average 2>/dev/null ||
      true
  )
fi
if [[ $cpu_power_raw =~ ^[0-9]+$ ]]; then
  cpu_watts=$(awk -v value="$cpu_power_raw" 'BEGIN { printf "%.2f", value/1000000 }')
fi

energy=0
energy_max=0
if [[ "$cpu_watts" == null ]]; then
  energy_file=""
  if [[ -n "${AGS_CPU_ENERGY_PATH:-}" && -r "${AGS_CPU_ENERGY_PATH}" ]]; then
    energy_file=${AGS_CPU_ENERGY_PATH}
  elif [[ -d /sys/class/powercap ]]; then
    while IFS= read -r candidate; do
      name=$(cat "${candidate%/*}/name" 2>/dev/null || true)
      if [[ $name == package-* || $name == package ]]; then
        energy_file=$candidate
        break
      fi
      [[ -n "$energy_file" ]] || energy_file=$candidate
    done < <(find -L /sys/class/powercap -name energy_uj -readable -print 2>/dev/null)
  fi

  if [[ -n "$energy_file" ]]; then
    energy=$(cat "$energy_file" 2>/dev/null || echo 0)
    energy_max=$(cat "${energy_file%/*}/max_energy_range_uj" 2>/dev/null || echo 0)
  elif [[ -x /usr/local/libexec/ags-rapl-read ]]; then
    read -r energy energy_max < <(/usr/local/libexec/ags-rapl-read 2>/dev/null || echo "0 0")
  fi

  if [[ $energy =~ ^[0-9]+$ && $energy_max =~ ^[0-9]+$ && $prev_energy =~ ^[0-9]+$ ]] &&
     (( prev_energy > 0 && energy > 0 )); then
    if (( energy >= prev_energy )); then
      energy_delta=$((energy - prev_energy))
    elif (( energy_max > prev_energy )); then
      energy_delta=$((energy_max - prev_energy + energy))
    else
      energy_delta=0
    fi
    cpu_watts=$(awk -v value="$energy_delta" -v seconds="$elapsed" 'BEGIN {
      watts=value/1000000/seconds
      if (watts >= 0 && watts < 10000) printf "%.2f", watts
      else print "null"
    }')
  fi
fi

# Battery discharge is whole-system draw, not CPU package draw.
system_watts=null
for battery in /sys/class/power_supply/BAT*; do
  [[ -r "$battery/status" && "$(<"$battery/status")" == Discharging ]] || continue
  if [[ -r "$battery/power_now" ]]; then
    system_watts=$(awk -v value="$(<"$battery/power_now")" 'BEGIN { printf "%.2f", value/1000000 }')
  elif [[ -r "$battery/current_now" && -r "$battery/voltage_now" ]]; then
    system_watts=$(awk -v c="$(<"$battery/current_now")" -v v="$(<"$battery/voltage_now")" 'BEGIN { printf "%.2f", c*v/1000000000000 }')
  fi
  break
done

printf '%s %s %s %s %s %s\n' "$total" "$idle_all" "$rx" "$tx" "$now" "$energy" > "$STATE_FILE"

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
