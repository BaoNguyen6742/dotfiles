#!/usr/bin/env bash
set -euo pipefail

config_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
log_file=/tmp/ags.log

# Some Fedora AGS builds hardcode the development symlink. `ags run`
# overwrites LD_PRELOAD, so use its generated launcher with the runtime SONAME.
if [[ ! -e /usr/lib64/libgtk4-layer-shell.so && -e /usr/lib64/libgtk4-layer-shell.so.0 ]]; then
    bundle_dir=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/ags-topbar.XXXXXXXX")
    trap 'rm -rf -- "$bundle_dir"' EXIT
    launcher="$bundle_dir/start"
    ags bundle "$config_dir/app.tsx" "$launcher"

    if grep -qF 'LD_PRELOAD="/usr/lib64/libgtk4-layer-shell.so" ' "$launcher"; then
        sed -i \
            -e 's|^file=.*|file="${0%/*}/app.js"|' \
            -e 's|^LD_PRELOAD="/usr/lib64/libgtk4-layer-shell\.so" |LD_PRELOAD="/usr/lib64/libgtk4-layer-shell.so.0" exec |' \
            "$launcher"
        bash "$launcher" >> "$log_file" 2>&1
        exit
    fi

    # Nothing to patch if the installed AGS build already uses another path.
    rm -rf -- "$bundle_dir"
    trap - EXIT
fi

exec ags run "$config_dir/app.tsx" --log-file "$log_file"
