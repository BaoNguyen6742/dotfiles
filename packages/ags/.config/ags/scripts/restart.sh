#!/usr/bin/env bash
set -euo pipefail

ags quit >/dev/null 2>&1 || true
exec "$(dirname -- "${BASH_SOURCE[0]}")/start.sh"
