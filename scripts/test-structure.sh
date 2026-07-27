#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_DIR

PACMAN_FILE="$DOTFILES_DIR/packages/pacman.txt"
AUR_FILE="$DOTFILES_DIR/packages/aur.txt"

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

ok() {
    printf 'OK: %s\n' "$1"
}

package_list_contains() {
    local file="$1"
    local package="$2"

    grep -Ev '^[[:space:]]*(#|$)' "$file" |
        sed 's/[[:space:]]*#.*$//' |
        awk 'NF' |
        grep -Fxq -- "$package"
}

require_pacman_package() {
    local package="$1"

    package_list_contains "$PACMAN_FILE" "$package" || fail "missing pacman package: $package"
}

require_aur_package() {
    local package="$1"

    package_list_contains "$AUR_FILE" "$package" || fail "missing AUR package: $package"
}

assert_file_executable() {
    local path="$1"

    [[ -f "$path" ]] || fail "missing file: $path"
    [[ -x "$path" ]] || fail "file is not executable: $path"
}

assert_no_match() {
    local pattern="$1"
    local message="$2"

    if rg -n --hidden -S "$pattern" --glob '!.git/**' .; then
        fail "$message"
    fi
}

assert_simple_xml() {
    local file="$1"
    local open_actions close_actions raw_ampersand

    [[ -f "$file" ]] || fail "missing XML file: $file"

    open_actions="$(grep -c '<actions>' "$file")"
    close_actions="$(grep -c '</actions>' "$file")"
    [[ "$open_actions" == "1" && "$close_actions" == "1" ]] ||
        fail "invalid Thunar XML root"

    if grep -n '&' "$file" | grep -Ev '&(amp|lt|gt|apos|quot);' >/dev/null; then
        grep -n '&' "$file" | grep -Ev '&(amp|lt|gt|apos|quot);' >&2
        fail "Thunar XML contains an unescaped ampersand"
    fi

    raw_ampersand="$(grep -n '<[^!?/][^>]*[^/]>' "$file" | wc -l)"
    [[ "$raw_ampersand" -gt 0 ]] || fail "Thunar XML has no elements"
}

assert_thunar_wallpaper_actions() {
    local file="$1"

    python - "$file" <<'PY'
import sys
import xml.etree.ElementTree as ET

path = sys.argv[1]
tree = ET.parse(path)
root = tree.getroot()
actions = root.findall("action")

def text(action, name):
    value = action.findtext(name)
    return "" if value is None else value

def has_child(action, name):
    return action.find(name) is not None

def normalized(value):
    return " ".join(value.casefold().split())

wallpaper_names = {"set as wallpaper", "definir como wallpaper"}
wallpaper_actions = [
    action for action in actions
    if normalized(text(action, "name")) in wallpaper_names
    or "set-wallpaper.sh" in text(action, "command")
]

if len(wallpaper_actions) != 1:
    raise SystemExit(f"expected exactly one Thunar wallpaper action, found {len(wallpaper_actions)}")

action = wallpaper_actions[0]
command = text(action, "command")
expected_command = 'sh -c \'"$HOME/.config/hypr/scripts/set-wallpaper.sh" "$1"\' _ %f'

checks = [
    (text(action, "name") == "Set as wallpaper", "wallpaper action must be named exactly 'Set as wallpaper'"),
    ("Definir como wallpaper" not in [text(item, "name") for item in actions], "Portuguese duplicate wallpaper action remains"),
    (sum("set-wallpaper.sh" in text(item, "command") for item in actions) == 1, "multiple Thunar actions call set-wallpaper.sh"),
    (command == expected_command, "wallpaper action command is not the portable sh -c form"),
    ("$HOME/.config/hypr/scripts/set-wallpaper.sh" in command, "wallpaper action does not call the Hyprpaper script through HOME"),
    (("/home/" + "tassio") not in command, "wallpaper action command contains a hard-coded home"),
    (text(action, "range") == "1-1", "wallpaper action must accept exactly one file"),
    (has_child(action, "image-files"), "wallpaper action must be limited to image files"),
    (not has_child(action, "directories"), "wallpaper action must not appear for directories"),
    (text(action, "patterns") != "*", "wallpaper action patterns must not match every file"),
]

for ok, message in checks:
    if not ok:
        raise SystemExit(message)

expected_other_actions = {
    "Open Terminal Here": ("1783989048238571-1", "kitty --directory %f"),
    "Open in Neovim": ("1783993487828022-1", "kitty --directory %f nvim ."),
    "Search Here": ("1783993569751182-2", "catfish --path=%f"),
}

by_name = {text(item, "name"): item for item in actions}
for name, (unique_id, expected_command) in expected_other_actions.items():
    item = by_name.get(name)
    if item is None:
        raise SystemExit(f"missing preserved Thunar action: {name}")
    if text(item, "unique-id") != unique_id:
        raise SystemExit(f"changed unique-id for preserved Thunar action: {name}")
    if text(item, "command") != expected_command:
        raise SystemExit(f"changed command for preserved Thunar action: {name}")
PY
}

assert_walker_config() {
    local file="$1"

    python - "$file" <<'PY'
import sys
import tomllib

path = sys.argv[1]
with open(path, "rb") as handle:
    config = tomllib.load(handle)

providers = config.get("providers", {})
default = providers.get("default", [])
empty = providers.get("empty", [])
prefixes = providers.get("prefixes", [])
actions = providers.get("actions", {})

allowed = {"desktopapplications", "providerlist", "runner"}
referenced = set(default) | set(empty)
referenced.update(item.get("provider", "") for item in prefixes)
referenced.update(key for key in actions if key not in {"fallback", "dmenu"})
referenced.discard("")

checks = [
    ("desktopapplications" in default, "Walker default providers must include desktopapplications"),
    ("desktopapplications" in empty, "Walker empty providers must include desktopapplications"),
    (referenced <= allowed, f"Walker references unavailable providers: {sorted(referenced - allowed)}"),
    ("providerlist" in referenced, "Walker must expose providerlist through a prefix"),
    ("runner" in referenced, "Walker must expose runner through a prefix"),
]

for ok, message in checks:
    if not ok:
        raise SystemExit(message)
PY
}

assert_elephant_autostart() {
    local file="$1"

    if grep -n 'hl\.exec_cmd("elephant' "$file"; then
        fail "Hyprland autostart still starts Elephant directly"
    fi

    [[ "$(grep -c 'systemctl --user start elephant\.service' "$file")" == "1" ]] ||
        fail "Hyprland must ask systemd to start Elephant exactly once"
    [[ "$(grep -c 'walker --gapplication-service' "$file")" == "1" ]] ||
        fail "Walker gapplication service must be started exactly once"
}

cd "$DOTFILES_DIR"

hardcoded_home='/home/''tassio'

assert_no_match "$hardcoded_home" "hard-coded user home remains"
ok "no hard-coded user home paths"

assert_no_match '/home/[[:alnum:]_-]+' "hard-coded user home path remains"
ok "no hard-coded home paths for any user"

forbidden_eval='eval[[:space:]]'
assert_no_match "$forbidden_eval" "forbidden shell evaluation remains"
ok "no forbidden shell evaluation"

assert_no_match 'pacman\s+-Sy(\s|$)' "unsafe pacman sync-only command remains"
ok "no unsafe pacman sync-only usage"

if find . -xtype l -not -path './.git/*' -print | grep -q .; then
    find . -xtype l -not -path './.git/*' -print >&2
    fail "broken symlinks found in repository"
fi
ok "no broken symlinks in repository"

[[ -f hypr/.config/hypr/hyprpaper.conf ]] || fail "missing Hyprpaper config"
[[ ! -e hypr/.config/hypr/hyprpaper.conf.tmpl ]] || fail "obsolete Hyprpaper template remains"
[[ -f hypr/.config/hypr/hyprlock.conf.tmpl ]] || fail "missing Hyprlock template"
if git ls-files --error-unmatch hypr/.config/hypr/hyprlock.conf >/dev/null 2>&1; then
    fail "Hyprlock generated config should not be versioned in the Hypr module"
fi
grep -Fxq 'ipc = true' hypr/.config/hypr/hyprpaper.conf ||
    fail "Hyprpaper IPC is not enabled"
grep -Fxq 'splash = false' hypr/.config/hypr/hyprpaper.conf ||
    fail "Hyprpaper splash is not disabled"
if grep -Eq 'wallpaper[[:space:]]*\{|path[[:space:]]*=' hypr/.config/hypr/hyprpaper.conf; then
    fail "Hyprpaper config contains a fixed wallpaper"
fi
ok "Hyprpaper config is stable and contains no fixed wallpaper"

assert_file_executable hypr/.config/hypr/scripts/set-wallpaper.sh
assert_file_executable hypr/.config/hypr/scripts/restore-wallpaper.sh
assert_file_executable fish/.local/bin/sdk
bash -n hypr/.config/hypr/scripts/set-wallpaper.sh
bash -n hypr/.config/hypr/scripts/restore-wallpaper.sh
bash -n fish/.local/bin/sdk
ok "wallpaper scripts and SDKMAN shim exist, are executable, and have valid Bash syntax"

assert_simple_xml thunar/.config/Thunar/uca.xml
assert_thunar_wallpaper_actions thunar/.config/Thunar/uca.xml
ok "Thunar wallpaper action is present, portable, and unique"

assert_walker_config walker/.config/walker/config.toml
assert_elephant_autostart hypr/.config/hypr/config/autostart.lua
ok "Walker config and Elephant startup are stable"

for script in \
    scripts/configure-elephant.sh \
    scripts/disable-thunar-wallpaper-plugin.sh \
    scripts/restore-thunar-wallpaper-plugin.sh \
    scripts/install-dev-toolchain.sh; do
    assert_file_executable "$script"
    bash -n "$script"
done
grep -Fq 'NoExtract = usr/lib/thunarx-3/thunar-wallpaper-plugin.so' docs/thunar-wallpaper-plugin.md ||
    fail "Thunar plugin NoExtract restoration documentation is missing"
ok "new administrative scripts exist, are executable, and are documented"

require_pacman_package firefox
require_pacman_package kitty
require_pacman_package thunar
require_pacman_package hyprland
require_pacman_package hyprpaper
require_pacman_package hyprlock
require_pacman_package hypridle
require_pacman_package waybar
require_pacman_package swaync
require_pacman_package wl-clipboard
require_pacman_package cliphist
require_pacman_package hyprshot
require_pacman_package brightnessctl
require_pacman_package wireplumber
require_pacman_package networkmanager
require_pacman_package network-manager-applet
require_pacman_package blueman
require_pacman_package polkit-gnome
require_pacman_package gsimplecal
require_pacman_package pavucontrol
require_pacman_package neovim
require_pacman_package bat
require_pacman_package zoxide
require_pacman_package starship
require_pacman_package tar
require_pacman_package gzip
require_pacman_package bzip2
require_pacman_package unzip
require_pacman_package unrar
require_pacman_package 7zip
require_pacman_package stow
require_pacman_package systemd
require_pacman_package xdg-user-dirs
require_aur_package walker-bin
require_aur_package elephant
require_aur_package elephant-desktopapplications
require_aur_package elephant-providerlist
require_aur_package elephant-runner
require_aur_package bibata-cursor-theme
require_aur_package colloid-gtk-theme-git
ok "configured commands have declared packages"

tmp_home="$(mktemp -d)"
trap 'rm -rf -- "$tmp_home"' EXIT

HOME="$tmp_home" \
  DOTFILES_DIR="$DOTFILES_DIR" \
  BACKUP_ROOT="$tmp_home/.dotfiles-backup/test" \
  bash "$DOTFILES_DIR/scripts/prepare-user-files.sh" >/dev/null

[[ -d "$tmp_home/Pictures/Screenshots" ]] || fail "missing generated screenshots directory"
[[ -d "$tmp_home/Pictures/Wallpapers" ]] || fail "missing generated wallpapers directory"
[[ -f "$tmp_home/.config/hypr/hyprlock.conf" ]] || fail "missing generated Hyprlock config"
[[ -d "$tmp_home/.local/state/hypr" ]] || fail "missing generated Hypr state directory"
: > "$tmp_home/Pictures/Wallpapers/mocked wallpaper (test).png"

if rg -n --hidden -S "$hardcoded_home|eDP-1" "$tmp_home/.config/hypr"; then
  fail "generated Hypr config is not portable"
fi
ok "prepare-user-files works against a temporary HOME"

if command -v stow >/dev/null 2>&1; then
    for module in desktop fish gtk hypr kitty nvim starship thunar walker waybar; do
        stow_args=(
            --dir="$DOTFILES_DIR"
            --target="$tmp_home"
            --no-folding
            --simulate
        )

        if [[ "$module" == "hypr" ]]; then
            stow_args+=(--ignore='current-wallpaper')
        fi

        stow "${stow_args[@]}" "$module" >/dev/null
    done

    stow --dir="$DOTFILES_DIR" --target="$tmp_home" --no-folding --restow --simulate thunar >/dev/null
    stow --dir="$DOTFILES_DIR" --target="$tmp_home" --no-folding --restow --simulate thunar >/dev/null

    ok "Stow simulation succeeds against a temporary HOME"
else
    ok "Stow simulation skipped because stow is not installed"
fi

HOME="$tmp_home" \
    XDG_STATE_HOME="$tmp_home/.local/state" \
    DRY_RUN=1 \
    bash "$DOTFILES_DIR/hypr/.config/hypr/scripts/set-wallpaper.sh" "$tmp_home/Pictures/Wallpapers/mocked wallpaper (test).png" >/dev/null 2>&1 ||
    fail "set-wallpaper dry run failed"
[[ ! -e "$tmp_home/.local/state/hypr/current-wallpaper" ]] ||
    fail "dry run changed wallpaper state"
[[ ! -e "$tmp_home/.config/hypr/current-wallpaper" ]] ||
    fail "dry run changed wallpaper symlink"
ok "set-wallpaper dry run does not change user configuration"

mock_bin="$tmp_home/mock-bin"
mock_log="$tmp_home/mock.log"
mock_ready="$tmp_home/hyprpaper.ready"
mkdir -p -- "$mock_bin"
cat > "$mock_bin/hyprpaper" <<'MOCK_HYPRPAPER'
#!/usr/bin/env sh
printf 'hyprpaper %s\n' "$*" >> "$MOCK_LOG"
touch "$MOCK_READY"
MOCK_HYPRPAPER
cat > "$mock_bin/hyprctl" <<'MOCK_HYPRCTL'
#!/usr/bin/env sh
printf 'hyprctl %s\n' "$*" >> "$MOCK_LOG"
if [ "$1" = "hyprpaper" ] && [ "$2" = "listactive" ]; then
    [ -e "$MOCK_READY" ]
    exit $?
fi
exit 0
MOCK_HYPRCTL
chmod +x "$mock_bin/hyprpaper" "$mock_bin/hyprctl"

HOME="$tmp_home" \
    XDG_STATE_HOME="$tmp_home/.local/state" \
    PATH="$mock_bin:$PATH" \
    MOCK_LOG="$mock_log" \
    MOCK_READY="$mock_ready" \
    bash "$DOTFILES_DIR/hypr/.config/hypr/scripts/set-wallpaper.sh" "$tmp_home/Pictures/Wallpapers/mocked wallpaper (test).png" >/dev/null ||
    fail "set-wallpaper mocked run failed"

grep -Fq 'hyprpaper -c' "$mock_log" || fail "set-wallpaper did not start Hyprpaper when IPC was unavailable"
grep -Fq 'hyprctl hyprpaper wallpaper' "$mock_log" || fail "set-wallpaper did not call Hyprpaper IPC"
[[ "$(cat "$tmp_home/.local/state/hypr/current-wallpaper")" == "$tmp_home/Pictures/Wallpapers/mocked wallpaper (test).png" ]] ||
    fail "set-wallpaper did not persist the selected wallpaper"
[[ -L "$tmp_home/.config/hypr/current-wallpaper" ]] ||
    fail "set-wallpaper did not create the current wallpaper symlink"
[[ "$(readlink -- "$tmp_home/.config/hypr/current-wallpaper")" == "$tmp_home/Pictures/Wallpapers/mocked wallpaper (test).png" ]] ||
    fail "current wallpaper symlink points to the wrong image"
ok "set-wallpaper works with mocked Hyprpaper IPC"

ok "safe structure test completed"
