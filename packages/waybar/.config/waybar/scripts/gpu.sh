#!/bin/bash

if [ "$1" == "usage" ]; then
    val=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
    echo "{\"text\": \"${val}%\", \"tooltip\": \"GPU Usage: ${val}%\"}"

elif [ "$1" == "vram" ]; then
    nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | awk -F', ' '{
        pct = ($1 / $2) * 100;
        printf "{\"text\": \"%d%%\", \"tooltip\": \"VRAM: %dMB / %dMB\"}\n", pct, $1, $2;
    }'

elif [ "$1" == "power" ]; then
    # Grab power and round to nearest whole number
    val=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits | awk '{print int($1)}')
    echo "{\"text\": \"${val}W\", \"tooltip\": \"GPU Power: ${val}W\"}"
fi
