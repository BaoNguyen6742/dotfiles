#!/usr/bin/env bash
set -euo pipefail

ags quit >/dev/null 2>&1 || true
exec ags run "$HOME/.config/ags/app.tsx" --log-file /tmp/ags.log
