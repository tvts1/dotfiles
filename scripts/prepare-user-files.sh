#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

HYPR_CONFIG_DIR="$HOME/.config/hypr"
GTK4_CONFIG_DIR="$HOME/.config/gtk-4.0"
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
GTK4_THEME_DIR="/usr/share/themes/Colloid-Purple-Dark/gtk-4.0"
INSTALLED_WALLPAPER=""

create_directory() {
    local dir="$1"

    mkdir -p -- "$dir"
    success "Ensured directory: $dir"
}

find_repo_wallpaper() {
    local dir file
    local search_dirs=(
        "$DOTFILES_DIR/wallpapers"
        "$DOTFILES_DIR/assets/wallpapers"
        "$DOTFILES_DIR/assets"
    )

    for dir in "${search_dirs[@]}"; do
        [[ -d "$dir" ]] || continue

        while IFS= read -r -d '' file; do
            printf '%s\n' "$file"
            return 0
        done < <(
            find "$dir" -maxdepth 2 -type f \
                \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.avif' \) \
                -print0 | sort -z
        )
    done

    return 1
}

install_wallpaper_if_available() {
    local source ext target

    if ! source="$(find_repo_wallpaper)"; then
        warning "No repository wallpaper found; Hyprpaper and Hyprlock will use fallback configuration"
        return 1
    fi

    ext="${source##*.}"
    target="$WALLPAPER_DIR/dotfiles-wallpaper.$ext"

    if [[ ( -e "$target" || -L "$target" ) ]] && ! cmp -s -- "$source" "$target"; then
        backup_path "$target"
    fi

    if [[ ! -e "$target" && ! -L "$target" ]]; then
        cp -p -- "$source" "$target"
        success "Installed wallpaper: $target"
    else
        success "Wallpaper already installed: $target"
    fi

    INSTALLED_WALLPAPER="$target"
}

write_generated_file() {
    local target="$1"
    local content_file="$2"

    if [[ -L "$target" ]] && path_is_within_dotfiles "$target"; then
        unlink -- "$target"
    elif [[ -e "$target" || -L "$target" ]]; then
        if cmp -s -- "$content_file" "$target"; then
            return 0
        fi

        backup_path "$target"
    fi

    install -m 0644 -- "$content_file" "$target"
}

render_hyprpaper_config() {
    local target="$HYPR_CONFIG_DIR/hyprpaper.conf"
    local tmp wallpaper_path="${1:-}"

    tmp="$(mktemp)"
    {
        sed '/{{WALLPAPER_BLOCK}}/q' "$DOTFILES_DIR/hypr/.config/hypr/hyprpaper.conf.tmpl" | sed '$d'

        if [[ -n "$wallpaper_path" && -f "$wallpaper_path" ]]; then
            cat <<EOF
wallpaper {
    monitor =
    path = $wallpaper_path
    fit_mode = cover
}
EOF
        fi
    } > "$tmp"

    write_generated_file "$target" "$tmp"
    rm -f -- "$tmp"
    success "Prepared Hyprpaper config: $target"
}

render_hyprlock_config() {
    local target="$HYPR_CONFIG_DIR/hyprlock.conf"
    local tmp wallpaper_path="${1:-}"

    tmp="$(mktemp)"
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == *"{{BACKGROUND_SOURCE}}"* ]]; then
            if [[ -n "$wallpaper_path" && -f "$wallpaper_path" ]]; then
                printf '    path = %s\n' "$wallpaper_path"
            else
                printf '    color = rgba(24, 25, 38, 1.0)\n'
            fi
        else
            printf '%s\n' "$line"
        fi
    done < "$DOTFILES_DIR/hypr/.config/hypr/hyprlock.conf.tmpl" > "$tmp"

    write_generated_file "$target" "$tmp"
    rm -f -- "$tmp"
    success "Prepared Hyprlock config: $target"
}

configure_gtk4_theme_links() {
    local name source target
    local names=(gtk.css gtk-dark.css assets)

    if [[ -f "$GTK4_THEME_DIR/gtk.css" && -f "$GTK4_THEME_DIR/gtk-dark.css" && -d "$GTK4_THEME_DIR/assets" ]]; then
        for name in "${names[@]}"; do
            source="$GTK4_THEME_DIR/$name"
            target="$GTK4_CONFIG_DIR/$name"

            if [[ -L "$target" ]]; then
                ln -sfn -- "$source" "$target"
            elif [[ -e "$target" ]]; then
                warning "GTK 4 target exists and was left unchanged: $target"
            else
                ln -s -- "$source" "$target"
            fi
        done

        success "GTK 4 Colloid links are configured"
        return 0
    fi

    warning "GTK 4 theme not found: $GTK4_THEME_DIR"

    for name in "${names[@]}"; do
        target="$GTK4_CONFIG_DIR/$name"

        if [[ -L "$target" ]]; then
            source="$(readlink -- "$target")"

            if [[ "$source" == "$GTK4_THEME_DIR/"* || ! -e "$target" ]]; then
                unlink -- "$target"
                warning "Removed unavailable GTK 4 theme link: $target"
            fi
        fi
    done
}

log "Preparing user files and directories"

create_directory "$SCREENSHOT_DIR"
create_directory "$WALLPAPER_DIR"
create_directory "$HYPR_CONFIG_DIR"
create_directory "$GTK4_CONFIG_DIR"

wallpaper_path=""
if install_wallpaper_if_available; then
    wallpaper_path="$INSTALLED_WALLPAPER"
fi

render_hyprpaper_config "$wallpaper_path"
render_hyprlock_config "$wallpaper_path"
configure_gtk4_theme_links
print_backups

success "User files prepared"
