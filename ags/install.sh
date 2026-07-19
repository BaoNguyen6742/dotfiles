#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${AGS_CONFIG_DIR:-$HOME/.config/ags}"
dry_run=false
generate_types=false
install_rapl_helper=false

usage() {
    cat <<EOF
Usage: $0 [--dry-run] [--generate-types] [--install-rapl-helper]

Installs the AGS configuration into:
  $config_dir

Options:
  --dry-run              Show changes without writing files
  --generate-types       Regenerate local Astal TypeScript definitions
  --install-rapl-helper  Install the optional Intel/AMD CPU wattage helper via pkexec
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            dry_run=true
            ;;
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

timestamp="$(date +%Y%m%d-%H%M%S)"

install_file() {
    local source_file="$1"
    local destination_file="$2"

    if [[ -f "$destination_file" ]] && cmp -s "$source_file" "$destination_file"; then
        echo "Unchanged: $destination_file"
        return
    fi

    if $dry_run; then
        [[ -e "$destination_file" ]] && echo "Would back up: $destination_file"
        echo "Would install: $destination_file"
        return
    fi

    mkdir -p "$(dirname -- "$destination_file")"
    if [[ -e "$destination_file" ]]; then
        local backup_file="$destination_file.bak-$timestamp"
        local suffix=1
        while [[ -e "$backup_file" ]]; do
            backup_file="$destination_file.bak-$timestamp-$suffix"
            suffix=$((suffix + 1))
        done
        cp -p -- "$destination_file" "$backup_file"
        echo "Backed up: $backup_file"
    fi

    cp -p -- "$source_file" "$destination_file"
    echo "Installed: $destination_file"
}

for file in .gitignore app.tsx env.d.ts package.json README.md style.scss tsconfig.json; do
    install_file "$script_dir/$file" "$config_dir/$file"
done

for directory in helpers scripts widgets; do
    while IFS= read -r -d '' source_file; do
        relative_path="${source_file#"$script_dir/"}"
        install_file "$source_file" "$config_dir/$relative_path"
    done < <(find "$script_dir/$directory" -type f -print0 | sort -z)
done

if $generate_types; then
    if $dry_run; then
        echo "Would generate Astal types in: $config_dir"
    elif ! command -v ags >/dev/null 2>&1; then
        echo "Cannot generate types: ags is not installed." >&2
        exit 1
    else
        ags types 'Astal*' --ignore Astal3 -d "$config_dir"
    fi
fi

if $install_rapl_helper; then
    helper_installer="$config_dir/helpers/install-rapl-helper.sh"
    helper_source="$config_dir/helpers/ags-rapl-read.c"

    if $dry_run; then
        echo "Would install CPU package-energy helper from: $helper_source"
    elif ! command -v pkexec >/dev/null 2>&1; then
        echo "Cannot install CPU package-energy helper: pkexec is not installed." >&2
        exit 1
    else
        pkexec "$helper_installer" "$helper_source"
    fi
fi

if $dry_run; then
    echo "Dry run complete."
else
    echo "AGS configuration installed in $config_dir"
    echo "Add this to Hyprland startup if needed:"
    echo "  ags run \"$config_dir/app.tsx\" --log-file /tmp/ags.log"
fi
