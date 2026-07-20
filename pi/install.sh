#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
dry_run=false

if [[ ${1:-} == "--dry-run" ]]; then
    dry_run=true
elif [[ $# -ne 0 ]]; then
    echo "Usage: $0 [--dry-run]" >&2
    exit 2
fi

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

install_file "$script_dir/settings.json" "$config_dir/settings.json"

while IFS= read -r -d '' extension; do
    relative_path="${extension#"$script_dir/extensions/"}"
    install_file "$extension" "$config_dir/extensions/$relative_path"
done < <(find "$script_dir/extensions" -type f -print0)

if $dry_run; then
    echo "Dry run complete."
else
    echo "Pi configuration installed. Restart Pi to apply settings changes."
fi
