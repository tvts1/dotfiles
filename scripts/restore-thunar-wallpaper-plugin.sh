#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PLUGIN_PATH="/usr/lib/thunarx-3/thunar-wallpaper-plugin.so"
NOEXTRACT_ENTRY="usr/lib/thunarx-3/thunar-wallpaper-plugin.so"
PACMAN_CONF="/etc/pacman.conf"
BACKUP_DIR="/var/lib/dotfiles/thunar-wallpaper-plugin"
BACKUP_PATH="$BACKUP_DIR/thunar-wallpaper-plugin.so"
DRY_RUN=0

usage() {
    cat <<'EOF'
Usage: restore-thunar-wallpaper-plugin.sh [--dry-run]

Restores Thunar's native wallpaper plugin by removing the managed NoExtract
entry and restoring the backed up plugin file when available.
EOF
}

while (($#)); do
    case "$1" in
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

remove_noextract() {
    local tmp

    if ! pacman_noextract_contains; then
        success "Pacman NoExtract entry is already absent"
        return 0
    fi

    tmp="$(mktemp)"
    awk -v entry="$NOEXTRACT_ENTRY" '
        $1 == "NoExtract" && $2 == "=" {
            count = 0
            for (i = 3; i <= NF; i++) {
                if ($i != entry) {
                    values[++count] = $i
                }
            }
            if (count > 0) {
                printf "NoExtract ="
                for (i = 1; i <= count; i++) {
                    printf " %s", values[i]
                    delete values[i]
                }
                printf "\n"
            }
            next
        }
        { print }
    ' "$PACMAN_CONF" > "$tmp"

    run_admin cp -a "$PACMAN_CONF" "$PACMAN_CONF.dotfiles-restore-backup"
    run_admin install -m 0644 "$tmp" "$PACMAN_CONF"
    rm -f -- "$tmp"

    success "Removed pacman NoExtract entry for Thunar wallpaper plugin"
}

restore_plugin_file() {
    if [[ -e "$PLUGIN_PATH" ]]; then
        success "Native Thunar wallpaper plugin already exists"
        return 0
    fi

    if [[ -e "$BACKUP_PATH" ]]; then
        run_admin cp -a "$BACKUP_PATH" "$PLUGIN_PATH"
        success "Restored Thunar wallpaper plugin from $BACKUP_PATH"
        return 0
    fi

    warning "No backup found at $BACKUP_PATH; reinstalling thunar to restore the plugin"
    run_admin pacman -S --noconfirm thunar
}

quit_thunar() {
    if command_exists thunar; then
        thunar -q >/dev/null 2>&1 || true
    fi
}

log "Restoring native Thunar wallpaper plugin"
remove_noextract
restore_plugin_file
quit_thunar

success "Thunar wallpaper plugin restored"
