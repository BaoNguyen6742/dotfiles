#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(CDPATH= cd -- "$script_dir/../.." && pwd)"
config_dir="${AGS_CONFIG_DIR:-$HOME/.config/ags}"
source_dir="$repo_dir/packages/ags/.config/ags"
generate_types=false
install_rapl_helper=false

usage() {
    cat <<EOF
Usage: $0 [--generate-types] [--install-rapl-helper]

Post-install setup for the stowed AGS configuration at:
  $config_dir

Options:
  --generate-types       Regenerate local Astal TypeScript definitions
  --install-rapl-helper  Install the optional Intel/AMD CPU wattage helper via pkexec
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --generate-types)
            generate_types=true
            ;;
        --install-rapl-helper)
            install_rapl_helper=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if ! $generate_types && ! $install_rapl_helper; then
    usage >&2
    exit 2
fi

if [[ ! -d "$config_dir" ]]; then
    echo "AGS configuration not found at $config_dir; stow the ags package first." >&2
    exit 1
fi

if $generate_types; then
    if ! command -v ags >/dev/null 2>&1; then
        echo "Cannot generate types: ags is not installed." >&2
        exit 1
    fi
    ags types 'Astal*' --ignore Astal3 -d "$config_dir"
fi

if $install_rapl_helper; then
    if ! command -v pkexec >/dev/null 2>&1; then
        echo "Cannot install CPU package-energy helper: pkexec is not installed." >&2
        exit 1
    fi
    pkexec \
        "$source_dir/helpers/install-rapl-helper.sh" \
        "$source_dir/helpers/ags-rapl-read.c"
fi
