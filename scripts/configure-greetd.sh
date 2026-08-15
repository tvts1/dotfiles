#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

TEMPLATE="$DOTFILES_DIR/system/greetd/config.toml"
TARGET_DIR="/etc/greetd"
TARGET="$TARGET_DIR/config.toml"
BACKUP="$TARGET.dotfiles-backup"
MANAGED_MARKER="# Managed by dotfiles configure-greetd.sh"
COMPETING_SERVICES=(gdm.service sddm.service lightdm.service ly.service)

require_command() {
    local command_name="$1"
    local package_name="$2"

    if ! command_exists "$command_name"; then
        error "$command_name is unavailable; install $package_name first."
        exit 1
    fi
}

find_competing_display_manager() {
    local service

    for service in "${COMPETING_SERVICES[@]}"; do
        if systemctl is-enabled --quiet "$service" 2>/dev/null; then
            printf '%s\n' "$service"
        fi
    done
}

if [[ ! -f "$TEMPLATE" ]]; then
    error "greetd template not found: $TEMPLATE"
    exit 1
fi

if ! command_exists pacman || ! pacman -Qq greetd >/dev/null 2>&1; then
    error "greetd is not installed. Install the greetd package first."
    exit 1
fi

require_command tuigreet greetd-tuigreet
require_command niri-session niri

tuigreet_help="$(tuigreet --help 2>&1)"
for required_option in --time --remember --remember-session --user-menu --cmd; do
    if ! grep -Fq -- "$required_option" <<<"$tuigreet_help"; then
        error "The installed tuigreet does not support $required_option."
        exit 1
    fi
done

if ! getent passwd greeter >/dev/null 2>&1 || ! getent group greeter >/dev/null 2>&1; then
    error "The greetd service account 'greeter' is unavailable. Reinstall greetd before retrying."
    exit 1
fi

mapfile -t competing_display_managers < <(find_competing_display_manager)
if (( ${#competing_display_managers[@]} > 0 )); then
    warning "A competing display manager is enabled:"
    printf '  %s\n' "${competing_display_managers[@]}"
    error "greetd was not configured. Disable the competing manager manually, then retry."
    exit 1
fi

tuigreet_path="$(readlink -f -- "$(command -v tuigreet)")"
niri_session_path="$(readlink -f -- "$(command -v niri-session)")"
rendered="$(<"$TEMPLATE")"
rendered="${rendered//\{\{TUIGREET_PATH\}\}/$tuigreet_path}"
rendered="${rendered//\{\{NIRI_SESSION_PATH\}\}/$niri_session_path}"

rendered_config="$(mktemp)"
trap 'rm -f -- "$rendered_config"' EXIT
printf '%s\n' "$rendered" > "$rendered_config"

if [[ -f "$TARGET" ]] && cmp -s -- "$rendered_config" "$TARGET"; then
    success "greetd configuration is already current"
    exit 0
fi

if [[ -f "$TARGET" ]] && ! grep -Fxq -- "$MANAGED_MARKER" "$TARGET"; then
    if [[ -e "$BACKUP" ]]; then
        if ! cmp -s -- "$TARGET" "$BACKUP"; then
            error "Existing greetd configuration differs from its backup: $BACKUP"
            error "Review both files manually; nothing was changed."
            exit 1
        fi
        warning "Existing greetd configuration is already backed up at $BACKUP"
    else
        log "Backing up the existing greetd configuration"
        sudo install -m 0644 -- "$TARGET" "$BACKUP"
        success "Backup created: $BACKUP"
    fi
fi

log "Installing greetd configuration"
sudo install -d -m 0755 -- "$TARGET_DIR"
sudo install -m 0644 -- "$rendered_config" "$TARGET"
sudo install -d -o greeter -g greeter -m 0755 -- /var/cache/tuigreet
success "Configured tuigreet to launch niri-session"
success "greetd will be enabled separately and will not be started in this session"
