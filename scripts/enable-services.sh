#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

enable_system_service() {
    local service="$1"

    if systemctl list-unit-files "$service" >/dev/null 2>&1; then
        log "Enabling $service"
        sudo systemctl enable --now "$service"
        success "Enabled $service"
    else
        warning "Service not found: $service"
    fi
}

log "Enabling system services"

enable_system_service "NetworkManager.service"
enable_system_service "bluetooth.service"
enable_system_service "fstrim.timer"

log "Creating standard user directories"

if command_exists xdg-user-dirs-update; then
    xdg-user-dirs-update
    success "User directories created"
else
    warning "xdg-user-dirs-update is not available"
fi

success "Service configuration finished"
