#!/usr/bin/env bash

set -euo pipefail

info() {
    printf '%s\n' "$*"
}

is_supported_image() {
    local path="$1"

    case "${path,,}" in
        *.jpg | *.jpeg | *.png | *.webp | *.jxl)
            return 0
            ;;
    esac

    return 1
}

find_first_wallpaper() {
    local wallpaper_dir="$HOME/Pictures/Wallpapers"
    local candidate

    [[ -d "$wallpaper_dir" ]] || return 1

    while IFS= read -r -d '' candidate; do
        printf '%s\n' "$candidate"
        return 0
    done < <(
        find "$wallpaper_dir" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.jxl' \) \
            -print0 | sort -z
    )

    return 1
}

main() {
    local script_dir
    local state_file="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/current-wallpaper"
    local wallpaper_path=""

    script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

    if [[ -f "$state_file" ]]; then
        IFS= read -r wallpaper_path < "$state_file" || true

        if [[ -n "$wallpaper_path" && -f "$wallpaper_path" ]] && is_supported_image "$wallpaper_path"; then
            "$script_dir/set-wallpaper.sh" "$wallpaper_path"
            return 0
        fi

        info "Saved wallpaper is unavailable; looking for a fallback"
    fi

    if wallpaper_path="$(find_first_wallpaper)"; then
        "$script_dir/set-wallpaper.sh" "$wallpaper_path"
        return 0
    fi

    info "No wallpaper found in $HOME/Pictures/Wallpapers; keeping the current session unchanged"
}

main "$@"
