#!/bin/bash

# 1. Get arguments and current state
ARG=$1
if [ -z "$ARG" ]; then exit 1; fi

# Get active workspace ID
ACTIVE_WS=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .activeWorkspace.id')
echo -e "active: $ACTIVE_WS\n"

# 2. Logic for Next/Prev/Number
if [ "$ARG" == "next" ] || [ "$ARG" == "prev" ]; then
    mapfile -t WS_LIST < <(hyprctl workspaces -j | jq -r '.[].id' | sort -n)
    echo "${WS_LIST[@]}"
    LEN=${#WS_LIST[@]}
    if [ "$LEN" -le 1 ]; then exit 0; fi

    INDEX=-1
    for i in "${!WS_LIST[@]}"; do
        if [ "${WS_LIST[$i]}" -eq "$ACTIVE_WS" ]; then
            INDEX=$i
            break
        fi
    done

    if [ "$ARG" == "next" ]; then
        TARGET_WS=${WS_LIST[$(((INDEX + 1) % LEN))]}
    else
        TARGET_WS=${WS_LIST[$(((INDEX - 1 + LEN) % LEN))]}
    fi
else
    TARGET_WS=$ARG
fi

# Exit if trying to swap with self
if [ "$ACTIVE_WS" == "$TARGET_WS" ]; then exit 0; fi

echo -e "Target WS: $TARGET_WS\n"
# 3. Collect window addresses for both workspaces
# We filter for only normal windows (ignoring popups/layers)
WINDOWS_ACTIVE=$(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $ACTIVE_WS) | .address")
WINDOWS_TARGET=$(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $TARGET_WS) | .address")

echo "Windows active"
echo -e "$WINDOWS_ACTIVE\n"

echo "Windows target"
echo -e "$WINDOWS_TARGET\n"
# 4. Construct the Batch Command using a NAMED temporary workspace
BATCH_CMD=""

# Move Current -> Temp
for addr in $WINDOWS_ACTIVE; do
    BATCH_CMD+="dispatch movetoworkspacesilent name:swap_temp,address:$addr; "
done

echo -e "$BATCH_CMD\n"
# Move Target -> Current
for addr in $WINDOWS_TARGET; do
    BATCH_CMD+="dispatch movetoworkspacesilent $ACTIVE_WS,address:$addr; "
done

echo -e "$BATCH_CMD\n"
# Move Temp -> Target
# We use a wildcard to grab anything in swap_temp just in case
for addr in $WINDOWS_ACTIVE; do
    BATCH_CMD+="dispatch movetoworkspacesilent $TARGET_WS,address:$addr; "
done

echo -e "$BATCH_CMD\n"
# 5. Execute Moves and then Switch Focus
if [ -n "$BATCH_CMD" ]; then
    # Run the moves in one batch
    hyprctl --batch "$BATCH_CMD"

    # Wait a tiny fraction for the engine to register the new workspace locations
    sleep 0.05

    # Force the view to follow the windows to the target workspace
    hyprctl dispatch workspace "$TARGET_WS"
fi
