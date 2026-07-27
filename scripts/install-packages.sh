#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PACMAN_FILE="$DOTFILES_DIR/packages/pacman.txt"
AUR_FILE="$DOTFILES_DIR/packages/aur.txt"

read_package_file() {
    local file="$1"

    grep -Ev '^[[:space:]]*(#|$)' "$file" \
        | sed 's/[[:space:]]*#.*$//' \
        | awk 'NF'
}

install_official_packages() {
    if [[ ! -f "$PACMAN_FILE" ]]; then
        error "Package list not found: $PACMAN_FILE"
        return 1
    fi

    mapfile -t packages < <(read_package_file "$PACMAN_FILE")

    if (( ${#packages[@]} == 0 )); then
        warning "No official packages listed"
        return
    fi

    log "Upgrading system and installing official packages"
    sudo pacman -Syu --needed --noconfirm "${packages[@]}"

    success "Official packages installed"
}

install_aur_packages() {
    if [[ ! -f "$AUR_FILE" ]]; then
        error "AUR package list not found: $AUR_FILE"
        return 1
    fi

    if ! command_exists paru; then
        error "Paru is required to install AUR packages"
        exit 1
    fi

    mapfile -t packages < <(read_package_file "$AUR_FILE")

    if (( ${#packages[@]} == 0 )); then
        warning "No AUR packages listed"
        return
    fi

    log "Installing AUR packages"
    paru -S --needed --noconfirm "${packages[@]}"

    success "AUR packages installed"
}

install_official_packages
install_aur_packages
