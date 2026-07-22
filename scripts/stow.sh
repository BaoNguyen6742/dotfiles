#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(CDPATH= cd -- "$script_dir/.." && pwd)"

usage() {
    cat <<EOF
Usage: $0 [stow options] PACKAGE...

Creates user-level links from:
  $repo_dir/packages
into:
  $HOME

Examples:
  $0 --simulate --verbose bash fish-linux hypr nvim
  $0 --restow bash fish-linux hypr nvim
  $0 --delete fish-linux

See README.md and docs/packages.md for package requirements.
EOF
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    usage
    exit 0
fi

if [[ $# -eq 0 ]]; then
    usage >&2
    exit 2
fi

if ! command -v stow >/dev/null 2>&1; then
    echo "GNU Stow is required but was not found in PATH." >&2
    exit 1
fi

# Avoid linking an entire writable directory such as ~/.pi or ~/.config/ags
# into the repository. Only the managed files should be symlinks.
exec stow \
    --dir="$repo_dir/packages" \
    --target="$HOME" \
    --no-folding \
    "$@"
