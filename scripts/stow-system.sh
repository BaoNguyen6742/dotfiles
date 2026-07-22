#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(CDPATH= cd -- "$script_dir/.." && pwd)"
target="${STOW_SYSTEM_TARGET:-/}"

usage() {
    cat <<EOF
Usage: sudo $0 [stow options] PACKAGE...

Creates system-level links from:
  $repo_dir/system-packages
into:
  $target

Examples:
  sudo $0 --simulate --verbose sddm
  sudo $0 --verbose sddm
  sudo $0 --restow sddm
  sudo $0 --delete sddm

See docs/sddm.md before installing or activating SDDM.
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

if [[ "$target" == / && EUID -ne 0 ]]; then
    echo "System packages target / and must be managed as root." >&2
    echo "Run: sudo $0 $*" >&2
    exit 1
fi

deleting=false
for argument in "$@"; do
    case "$argument" in
        -D|--delete)
            deleting=true
            ;;
    esac
done

# The SDDM greeter runs as the sddm user and must be able to follow Stow's
# links back into the repository. This commonly needs a traverse-only ACL
# when the repository lives below a mode-0700 home directory.
if [[ "$target" == / && "$deleting" == false ]] && id sddm >/dev/null 2>&1; then
    theme_entry="$repo_dir/system-packages/sddm/usr/local/share/sddm/themes/sugar-candy-dotfiles/Main.qml"
    if command -v runuser >/dev/null 2>&1 && ! runuser -u sddm -- test -r "$theme_entry"; then
        acl_home="/home/YOUR_USER"
        if [[ -n ${SUDO_USER:-} && ${SUDO_USER:-root} != root ]] && command -v getent >/dev/null 2>&1; then
            acl_home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
        fi
        cat >&2 <<EOF
The sddm user cannot read the theme through the repository path:
  $theme_entry

If the repository is inside your private home directory, grant only traverse
access to the sddm user, then retry:
  sudo setfacl -m u:sddm:x "$acl_home"

Alternatively, keep the repository in an sddm-readable location such as
/opt/dotfiles.
EOF
        exit 1
    fi
fi

exec stow \
    --dir="$repo_dir/system-packages" \
    --target="$target" \
    --no-folding \
    "$@"
