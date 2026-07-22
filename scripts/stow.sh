#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(CDPATH= cd -- "$script_dir/.." && pwd)"

if ! command -v stow >/dev/null 2>&1; then
    echo "GNU Stow is required but was not found in PATH." >&2
    exit 1
fi

if [[ $# -eq 0 ]]; then
    cat >&2 <<EOF
Usage: $0 [stow options] PACKAGE...

Examples:
  $0 --simulate --verbose bash fish-linux ags pi
  $0 --restow bash fish-linux ags pi
  $0 --delete fish-linux
EOF
    exit 2
fi

# Avoid linking an entire writable directory such as ~/.pi or ~/.config/ags
# into the repository. Only the managed files should be symlinks.
exec stow \
    --dir="$repo_dir/packages" \
    --target="$HOME" \
    --no-folding \
    "$@"
