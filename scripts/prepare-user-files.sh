#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

create_directory() {
    local dir="$1"

    mkdir -p -- "$dir"
    success "Ensured directory: $dir"
}

log "Preparing user files and directories"

create_directory "$SCREENSHOT_DIR"
create_directory "$WALLPAPER_DIR"

success "User files prepared"
