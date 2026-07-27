#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

modules=(
    desktop
    gtk
    hypr
    kitty
    nvim
    starship
    thunar
    walker
    waybar
    zsh
)

log "Applying dotfiles with GNU Stow"

if ! command_exists stow; then
    error "GNU Stow is not installed."
    exit 1
fi

for module in "${modules[@]}"; do
    if [[ ! -d "$DOTFILES_DIR/$module" ]]; then
        error "Configured Stow module does not exist: $module"
        exit 1
    fi
done

target_points_to_source() {
    local target="$1"
    local source="$2"
    local target_resolved source_resolved

    target_resolved="$(readlink -f -- "$target" 2>/dev/null || true)"
    source_resolved="$(readlink -f -- "$source" 2>/dev/null || true)"

    [[ -n "$target_resolved" && -n "$source_resolved" && "$target_resolved" == "$source_resolved" ]]
}

source_is_generated_or_ignored() {
    local module="$1"
    local rel="$2"

    case "$module:$rel" in
        hypr:.config/hypr/hyprlock.conf | \
        hypr:.config/hypr/current-wallpaper | \
        gtk:.config/gtk-4.0/assets | \
        gtk:.config/gtk-4.0/gtk.css | \
        gtk:.config/gtk-4.0/gtk-dark.css)
            return 0
            ;;
    esac

    return 1
}

detect_and_backup_conflicts() {
    local module="$1"
    local source rel target

    while IFS= read -r -d '' source; do
        rel="${source#"$DOTFILES_DIR/$module"/}"

        if source_is_generated_or_ignored "$module" "$rel"; then
            continue
        fi

        target="$HOME/$rel"

        if [[ ! -e "$target" && ! -L "$target" ]]; then
            continue
        fi

        if target_points_to_source "$target" "$source"; then
            continue
        fi

        if [[ -L "$target" ]] && path_is_within_dotfiles "$target"; then
            backup_path "$target"
            continue
        fi

        if [[ -f "$target" || -L "$target" ]]; then
            backup_path "$target"
        fi
    done < <(
        find "$DOTFILES_DIR/$module" \( -type f -o -type l \) \
            ! -name '.stow-local-ignore' \
            ! -name '*.tmpl' \
            ! -path "$DOTFILES_DIR/hypr/.config/hypr/hyprlock.conf" \
            -print0
    )
}

for module in "${modules[@]}"; do
    detect_and_backup_conflicts "$module"

    stow \
        --dir="$DOTFILES_DIR" \
        --target="$HOME" \
        --no-folding \
        --restow \
        "$module"

    success "Applied $module"
done

print_backups
