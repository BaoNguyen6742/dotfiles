#!/bin/bash

# 1. Find the active internet interface (Wifi or Ethernet)
IFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)

# If no internet, show disconnected
if [ -z "$IFACE" ]; then
  echo "0 B   0 B "
  exit
fi

# 2. Read current traffic
R1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
T1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)

# 3. Wait 1 second to measure speed
sleep 1

# 4. Read traffic again
R2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
T2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)

# 5. Calculate bytes per second
RB=$((R2 - R1))
TB=$((T2 - T1))

# 6. Format to KB/MB using awk (Matches your "3 digits before, 1 after" request)
awk -v rb=$RB -v tb=$TB '
function human(x) {
    if (x < 1024) return sprintf("%4.0f B", x)   # 0 B to 1023 B
    x/=1024
    if (x < 1024) return sprintf("%4.1f KB", x)  # 1.0 KB to 999.9 KB
    x/=1024
    return sprintf("%4.1f MB", x)                # 1.0 MB ...
}
{ printf "%7s   | %7s \n", human(rb), human(tb) }
' <<<""
