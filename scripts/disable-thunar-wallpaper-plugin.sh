#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PLUGIN_PATH="/usr/lib/thunarx-3/thunar-wallpaper-plugin.so"
NOEXTRACT_ENTRY="usr/lib/thunarx-3/thunar-wallpaper-plugin.so"
PACMAN_CONF="/etc/pacman.conf"
BACKUP_DIR="/var/lib/dotfiles/thunar-wallpaper-plugin"
BACKUP_PATH="$BACKUP_DIR/thunar-wallpaper-plugin.so"
CHECK_ONLY=0
DRY_RUN=0

usage() {
    cat <<'EOF'
Usage: disable-thunar-wallpaper-plugin.sh [--check] [--dry-run]

Disables Thunar's native wallpaper plugin and keeps it disabled across pacman
updates by adding a NoExtract entry to /etc/pacman.conf.
EOF
}

while (($#)); do
    case "$1" in
        --check)
            CHECK_ONLY=1
            ;;
        --dry-run)
            DRY_RUN=1
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage >&2
            exit 2
            ;;
    esac

    shift
done

run_admin() {
    if ((DRY_RUN)); then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi

    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

pacman_noextract_contains() {
    awk -v entry="$NOEXTRACT_ENTRY" '
        $1 == "NoExtract" && $2 == "=" {
            for (i = 3; i <= NF; i++) {
                if ($i == entry) {
                    found = 1
                }
            }
        }
        END { exit !found }
    ' "$PACMAN_CONF"
}

add_noextract() {
    local tmp

    if pacman_noextract_contains; then
        success "Pacman NoExtract already contains $NOEXTRACT_ENTRY"
        return 0
    fi

    tmp="$(mktemp)"
    awk -v entry="$NOEXTRACT_ENTRY" '
        /^\[options\]$/ {
            print
            print "NoExtract = " entry
            inserted = 1
            next
        }
        { print }
        END {
            if (!inserted) {
                print ""
                print "[options]"
                print "NoExtract = " entry
            }
        }
    ' "$PACMAN_CONF" > "$tmp"

    run_admin cp -a "$PACMAN_CONF" "$PACMAN_CONF.dotfiles-backup"
    run_admin install -m 0644 "$tmp" "$PACMAN_CONF"
    rm -f -- "$tmp"

    success "Added pacman NoExtract entry for Thunar wallpaper plugin"
}

disable_plugin_file() {
    local stamped_backup

    if [[ ! -e "$PLUGIN_PATH" ]]; then
        success "Thunar wallpaper plugin is already absent"
        return 0
    fi

    run_admin mkdir -p "$BACKUP_DIR"

    if [[ -e "$BACKUP_PATH" ]]; then
        stamped_backup="$BACKUP_DIR/thunar-wallpaper-plugin.so.$(date +%Y%m%d-%H%M%S)"
        run_admin mv "$PLUGIN_PATH" "$stamped_backup"
        success "Moved current Thunar wallpaper plugin to $stamped_backup"
    else
        run_admin mv "$PLUGIN_PATH" "$BACKUP_PATH"
        success "Moved Thunar wallpaper plugin to $BACKUP_PATH"
    fi
}

quit_thunar() {
    if command_exists thunar; then
        thunar -q >/dev/null 2>&1 || true
    fi
}

check_state() {
    local failed=0

    if pacman_noextract_contains; then
        success "Pacman NoExtract contains $NOEXTRACT_ENTRY"
    else
        error "Pacman NoExtract is missing $NOEXTRACT_ENTRY"
        failed=1
    fi

    if [[ ! -e "$PLUGIN_PATH" ]]; then
        success "Native Thunar wallpaper plugin is absent"
    else
        error "Native Thunar wallpaper plugin still exists: $PLUGIN_PATH"
        failed=1
    fi

    return "$failed"
}

if ((CHECK_ONLY)); then
    check_state
    exit 0
fi

log "Disabling native Thunar wallpaper plugin"
add_noextract
disable_plugin_file
quit_thunar

if ((DRY_RUN)); then
    success "Thunar wallpaper plugin disable dry run finished"
    exit 0
fi

check_state

success "Thunar wallpaper plugin disabled"
