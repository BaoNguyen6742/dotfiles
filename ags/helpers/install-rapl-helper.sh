#!/usr/bin/env bash
set -euo pipefail

SOURCE="${1:-$HOME/.config/ags/helpers/ags-rapl-read.c}"
DESTINATION="/usr/local/libexec/ags-rapl-read"
TEMP_BINARY=$(mktemp /tmp/ags-rapl-read.XXXXXX)
trap 'rm -f "$TEMP_BINARY"' EXIT

if [[ $EUID -ne 0 ]]; then
  echo "This installer must run through sudo or pkexec." >&2
  exit 1
fi

cc -O2 -Wall -Wextra -Werror -D_FORTIFY_SOURCE=3 -fstack-protector-strong \
  -fPIE -pie "$SOURCE" -o "$TEMP_BINARY"

install -d -o root -g root -m 0755 /usr/local/libexec
install -o root -g root -m 0755 "$TEMP_BINARY" "$DESTINATION"
setcap cap_dac_read_search=ep "$DESTINATION"

echo "Installed $DESTINATION"
getcap "$DESTINATION"
