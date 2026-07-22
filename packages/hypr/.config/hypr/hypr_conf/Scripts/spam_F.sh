#!/bin/bash

PIDFILE="/tmp/spam_f.pid"

if [ -e "$PIDFILE" ]; then
  # --- STOP ---
  kill $(cat "$PIDFILE")
  rm "$PIDFILE"
  notify-send -t 1000 "Auto-F" "Stopped"
else
  # --- START ---
  (while true; do
    # ydotool simulates a real hardware key press
    ydotool key 33:1 33:0

    # Adjust delay (0.1 = 100ms)
    sleep 0.1
  done) &

  echo $! >"$PIDFILE"
  notify-send -t 1000 "Auto-F" "Started"
fi
