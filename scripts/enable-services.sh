#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

system_service_exists() {
    local service="$1"

    systemctl list-unit-files --no-legend "$service" 2>/dev/null |
        awk -v service="$service" '$1 == service { found = 1 } END { exit !found }'
}

enable_system_service() {
    local service="$1"

    if system_service_exists "$service"; then
        log "Enabling $service"
        sudo systemctl enable --now "$service"
        success "Enabled $service"
    else
        warning "Service not found: $service"
    fi
}

enable_system_service_on_boot() {
    local service="$1"

    if system_service_exists "$service"; then
        log "Enabling $service for the next boot"
        sudo systemctl enable "$service"
        success "Enabled $service without starting it now"
    else
        warning "Service not found: $service"
    fi
}

enable_greetd_service() {
    local competing_service

    for competing_service in gdm.service sddm.service lightdm.service ly.service; do
        if systemctl is-enabled --quiet "$competing_service" 2>/dev/null; then
            warning "Not enabling greetd: competing display manager is enabled: $competing_service"
            return 1
        fi
    done

    enable_system_service_on_boot "greetd.service"
}

log "Enabling system services"

enable_system_service "NetworkManager.service"
enable_system_service "bluetooth.service"
enable_system_service "docker.service"
enable_system_service "fstrim.timer"
enable_greetd_service

log "Creating standard user directories"

if command_exists xdg-user-dirs-update; then
    xdg-user-dirs-update
    success "User directories created"
else
    warning "xdg-user-dirs-update is not available"
fi

success "Service configuration finished"
