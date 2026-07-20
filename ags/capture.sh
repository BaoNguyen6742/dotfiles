#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${AGS_CONFIG_DIR:-$HOME/.config/ags}"
dry_run=false

usage() {
    cat <<EOF
Usage: $0 [--dry-run]

Copies the managed AGS configuration from:
  $config_dir
back into this dotfiles directory:
  $script_dir

Generated node_modules/@girs content and installer backup files are ignored.
Review the result with git diff before committing.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            dry_run=true
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

if [[ ! -d "$config_dir" ]]; then
    echo "AGS configuration directory does not exist: $config_dir" >&2
    exit 1
fi

capture_file() {
    local source_file="$1"
    local destination_file="$2"

    if [[ -f "$destination_file" ]] && cmp -s "$source_file" "$destination_file"; then
        echo "Unchanged: $destination_file"
        return
    fi

    if $dry_run; then
        echo "Would capture: $source_file -> $destination_file"
        return
    fi

    mkdir -p "$(dirname -- "$destination_file")"
    cp -p -- "$source_file" "$destination_file"
    echo "Captured: $destination_file"
}

for file in .gitignore app.tsx env.d.ts package.json style.scss tsconfig.json; do
    if [[ -f "$config_dir/$file" ]]; then
        capture_file "$config_dir/$file" "$script_dir/$file"
    else
        echo "Missing managed file, skipped: $config_dir/$file" >&2
    fi
done

for directory in helpers scripts widgets; do
    [[ -d "$config_dir/$directory" ]] || continue
    while IFS= read -r -d '' source_file; do
        relative_path="${source_file#"$config_dir/"}"
        capture_file "$source_file" "$script_dir/$relative_path"
    done < <(find "$config_dir/$directory" -type f ! -name '*.bak-*' -print0 | sort -z)
done

if $dry_run; then
    echo "Dry run complete; no repository files were changed."
else
    echo "Local AGS configuration captured. Review it with:"
    echo "  git -C \"$(dirname -- "$script_dir")\" diff -- ags"
fi
