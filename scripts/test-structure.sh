#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_DIR

PACMAN_FILE="$DOTFILES_DIR/packages/pacman.txt"

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

require_package() {
    local file="$1"
    local package="$2"

    package_list_contains "$file" "$package" ||
        fail "missing package in $(basename "$file"): $package"
}

reject_package() {
    local file="$1"
    local package="$2"

    if package_list_contains "$file" "$package"; then
        fail "retired or redundant package remains in $(basename "$file"): $package"
    fi
}

assert_file_executable() {
    local path="$1"

    [[ -f "$path" ]] || fail "missing file: $path"
    [[ -x "$path" ]] || fail "file is not executable: $path"
}

configured_stow_modules() {
    awk '
        /^modules=\($/ { in_modules = 1; next }
        in_modules && /^\)$/ { exit }
        in_modules {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "")
            if ($0 != "") print
        }
    ' scripts/apply-stow.sh
}

cd "$DOTFILES_DIR"

old_stack=(
    'hypr''land'
    'hypr''paper'
    'hypr''lock'
    'hypr''idle'
    'hypr''shot'
    'way''bar'
    'walk''er'
    'ele''phant'
    'sway''nc'
    'xdg-desktop-portal-''hypr''land'
    'quick''shell'
    'noctalia-''q''s'
)

old_pattern="$(IFS='|'; printf '%s' "${old_stack[*]}")"
if rg -n -i --hidden --glob '!.git/**' "$old_pattern" .; then
    fail "retired desktop references remain"
fi
ok "retired desktop references are absent"

retired_visual=('col''loid' 'bi''bata')
retired_visual_pattern="$(IFS='|'; printf '%s' "${retired_visual[*]}")"
if rg -n -i --hidden --glob '!.git/**' "$retired_visual_pattern" .; then
    fail "retired visual theme references remain"
fi

aur_helpers=('pa''ru' 'y''ay')
aur_helper_pattern="$(IFS='|'; printf '%s' "${aur_helpers[*]}")"
if rg -n -i --hidden --glob '!.git/**' --glob '!scripts/test-structure.sh' \
    "$aur_helper_pattern" .; then
    fail "an AUR helper is still required"
fi
[[ ! -e packages/aur.txt ]] || fail "AUR package list should not exist"
aur_install_script="scripts/install-${aur_helpers[0]}.sh"
[[ ! -e "$aur_install_script" ]] || fail "AUR helper installer remains"
ok "retired themes and AUR helper dependencies are absent"

if rg -n --hidden --glob '!.git/**' '/home/[[:alnum:]_-]+' .; then
    fail "hard-coded user home path remains"
fi
if rg -n 'pacman[[:space:]]+-Sy([[:space:]]|$)' install.sh scripts; then
    fail "unsafe pacman sync-only command remains"
fi
if find . -xtype l -not -path './.git/*' -print | grep -q .; then
    find . -xtype l -not -path './.git/*' -print >&2
    fail "broken symlink found in repository"
fi
ok "portable paths, safe Pacman usage and repository symlinks are clean"

for old_dir in "${old_stack[0]%%land}" "${old_stack[5]}" "${old_stack[6]}"; do
    [[ ! -e "$old_dir" ]] || fail "retired module remains: $old_dir"
done
ok "retired desktop modules are absent"

for script in install.sh scripts/*.sh; do
    assert_file_executable "$script"
    bash -n "$script"
done
ok "all shell scripts are executable and parse successfully"

for package in \
    stow niri noctalia xwayland-satellite \
    xdg-desktop-portal-gnome xdg-desktop-portal-gtk \
    greetd greetd-tuigreet \
    kitty zsh zsh-autosuggestions zsh-syntax-highlighting starship zoxide \
    eza bat fzf fd ripgrep fastfetch btop jq less git curl \
    neovim lazygit tree-sitter-cli firefox thunar thunar-archive-plugin \
    thunar-volman tumbler ffmpegthumbnailer poppler-glib file-roller gvfs gvfs-mtp \
    wl-clipboard pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol \
    networkmanager bluez bluez-utils brightnessctl playerctl upower \
    xdg-user-dirs xdg-utils libnotify imv zathura zathura-pdf-mupdf \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji papirus-icon-theme \
    polkit-gnome gnome-keyring adw-gtk-theme docker docker-compose; do
    require_package "$PACMAN_FILE" "$package"
done

for package in "${old_stack[@]}" xorg-xwayland cliphist network-manager-applet blueman \
    gsimplecal nwg-look "${retired_visual[@]}"; do
    reject_package "$PACMAN_FILE" "$package"
done

for display_manager in gdm sddm lightdm ly; do
    reject_package "$PACMAN_FILE" "$display_manager"
done

ok "official package list matches the Niri and Noctalia desktop"

mapfile -t stow_modules < <(configured_stow_modules)
expected_modules=(desktop gtk kitty niri noctalia nvim starship thunar zsh)
[[ "${stow_modules[*]}" == "${expected_modules[*]}" ]] ||
    fail "unexpected Stow modules: ${stow_modules[*]}"

for module in "${stow_modules[@]}"; do
    [[ -d "$module" ]] || fail "configured Stow module does not exist: $module"
done
ok "Stow modules match the repository"

essential_files=(
    niri/.config/niri/config.kdl
    niri/.config/niri/input.kdl
    niri/.config/niri/layout.kdl
    niri/.config/niri/rules.kdl
    niri/.config/niri/binds.kdl
    noctalia/.config/noctalia/config.toml
    system/greetd/config.toml
    scripts/configure-greetd.sh
)
for file in "${essential_files[@]}"; do
    [[ -f "$file" ]] || fail "missing desktop configuration: $file"
done
ok "essential Niri and Noctalia files are present"

grep -Fq '[terminal]' system/greetd/config.toml ||
    fail "greetd template is missing [terminal]"
grep -Fq '[default_session]' system/greetd/config.toml ||
    fail "greetd template is missing [default_session]"
grep -Fq 'user = "greeter"' system/greetd/config.toml ||
    fail "greetd template does not use the package service user"
for greetd_argument in \
    '{{TUIGREET_PATH}}' '--time' '--remember' '--remember-session' \
    '--user-menu' '--cmd' '{{NIRI_SESSION_PATH}}'; do
    grep -Fq -- "$greetd_argument" system/greetd/config.toml ||
        fail "greetd template is missing: $greetd_argument"
done
if rg -n -i 'initial_session|autologin|pass(word|wd)[[:space:]]*=' system/greetd/config.toml; then
    fail "greetd template contains autologin or a stored password"
fi

python3 - <<'PY'
import pathlib
import tomllib

template = pathlib.Path("system/greetd/config.toml").read_text()
rendered = template.replace("{{TUIGREET_PATH}}", "/usr/bin/tuigreet")
rendered = rendered.replace("{{NIRI_SESSION_PATH}}", "/usr/bin/niri-session")
config = tomllib.loads(rendered)

assert config["terminal"]["vt"] == 1
assert config["default_session"]["user"] == "greeter"
assert config["default_session"]["command"].endswith("--cmd /usr/bin/niri-session")
PY
ok "greetd template is valid TOML without autologin"

for competing_service in gdm.service sddm.service lightdm.service ly.service; do
    grep -Fq "$competing_service" scripts/configure-greetd.sh ||
        fail "greetd setup does not detect $competing_service"
done
grep -Fq 'BACKUP="$TARGET.dotfiles-backup"' scripts/configure-greetd.sh ||
    fail "greetd setup lacks a stable backup path"
grep -Fq 'cmp -s -- "$rendered_config" "$TARGET"' scripts/configure-greetd.sh ||
    fail "greetd setup is not idempotent"
if rg -n 'rm[[:space:]]+-rf' scripts/configure-greetd.sh; then
    fail "greetd setup must not use rm -rf"
fi
ok "greetd setup detects conflicts and preserves external configuration"

grep -Fq 'spawn-at-startup "noctalia"' niri/.config/niri/config.kdl ||
    fail "Niri does not start Noctalia"
grep -Fq 'spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"' \
    niri/.config/niri/config.kdl || fail "Polkit fallback is not started by Niri"
grep -Fq 'polkit_agent = false' noctalia/.config/noctalia/config.toml ||
    fail "Noctalia native Polkit agent must stay disabled while the fallback is active"
for template in gtk3 gtk4 kitty; do
    grep -Fq "\"$template\"" noctalia/.config/noctalia/config.toml ||
        fail "Noctalia built-in template is not enabled: $template"
done
grep -Fq 'enable_community_templates = false' noctalia/.config/noctalia/config.toml ||
    fail "Noctalia community templates must remain disabled"

for settings_file in gtk/.config/gtk-3.0/settings.ini gtk/.config/gtk-4.0/settings.ini; do
    grep -Fq 'gtk-icon-theme-name=Papirus-Dark' "$settings_file" ||
        fail "Papirus icon theme is missing from $settings_file"
    if rg -n -i 'gtk-theme-name|gtk-cursor-theme|prefer-dark-theme' "$settings_file"; then
        fail "Noctalia-managed GTK appearance is hard-coded in $settings_file"
    fi
done
grep -Fq 'include themes/noctalia.conf' kitty/.config/kitty/kitty.conf ||
    fail "Kitty does not include Noctalia-generated colors"
[[ ! -e kitty/.config/kitty/no-preference-theme.auto.conf ]] ||
    fail "a competing static Kitty color theme remains"
ok "Noctalia owns GTK and Kitty colors while Papirus remains configured"

required_binds=(
    'Mod+T hotkey-overlay-title="Open Kitty" { spawn "kitty"; }'
    'Mod+Space hotkey-overlay-title="Noctalia Launcher" { spawn "noctalia" "msg" "panel-toggle" "launcher"; }'
    'Mod+S hotkey-overlay-title="Noctalia Control Center" { spawn "noctalia" "msg" "panel-toggle" "control-center"; }'
    'Mod+Comma hotkey-overlay-title="Noctalia Settings" { spawn "noctalia" "msg" "settings-toggle"; }'
    'Alt+Tab hotkey-overlay-title="Noctalia Window Switcher" { spawn "noctalia" "msg" "window-switcher"; }'
    'Mod+Shift+L hotkey-overlay-title="Lock Session" { spawn "noctalia" "msg" "session" "lock"; }'
    'Mod+Q repeat=false { close-window; }'
    'Print { spawn "noctalia" "msg" "screenshot-region"; }'
    'Ctrl+Print { spawn "noctalia" "msg" "screenshot-fullscreen"; }'
    'XF86AudioRaiseVolume allow-when-locked=true { spawn "noctalia" "msg" "volume-up"; }'
    'XF86AudioLowerVolume allow-when-locked=true { spawn "noctalia" "msg" "volume-down"; }'
    'XF86AudioMute allow-when-locked=true { spawn "noctalia" "msg" "volume-mute"; }'
    'XF86MonBrightnessUp allow-when-locked=true { spawn "noctalia" "msg" "brightness-up"; }'
    'XF86MonBrightnessDown allow-when-locked=true { spawn "noctalia" "msg" "brightness-down"; }'
)
for bind in "${required_binds[@]}"; do
    grep -Fqx -- "    $bind" niri/.config/niri/binds.kdl ||
        fail "missing Niri binding: $bind"
done
ok "Niri startup, Polkit and Noctalia IPC bindings are configured"

for service in NetworkManager.service bluetooth.service docker.service; do
    grep -Fq "enable_system_service \"$service\"" scripts/enable-services.sh ||
        fail "required system service is not configured: $service"
done
grep -Fq 'enable_system_service_on_boot "greetd.service"' scripts/enable-services.sh ||
    fail "greetd is not enabled for the next boot"
if rg -n 'enable[[:space:]]+--now[[:space:]]+.*greetd|enable_system_service "greetd.service"' \
    scripts/enable-services.sh; then
    fail "greetd would be started immediately"
fi
if rg -n 'enable_system_service "(pipewire|wireplumber|niri|noctalia)' \
    scripts/enable-services.sh; then
    fail "a session component is configured as a system service"
fi
ok "only appropriate desktop services are enabled system-wide"

configure_line="$(grep -nF 'scripts/configure-greetd.sh' install.sh | cut -d: -f1)"
services_line="$(grep -nF 'scripts/enable-services.sh' install.sh | cut -d: -f1)"
[[ -n "$configure_line" && -n "$services_line" && "$configure_line" -lt "$services_line" ]] ||
    fail "install.sh must configure greetd before enabling services"
ok "installer configures greetd before enabling it"

if command -v niri >/dev/null 2>&1; then
    niri validate -c "$DOTFILES_DIR/niri/.config/niri/config.kdl"
    ok "Niri configuration is valid"
fi

if command -v noctalia >/dev/null 2>&1; then
    noctalia config validate "$DOTFILES_DIR/noctalia/.config/noctalia/config.toml"
    ok "Noctalia configuration is valid"
fi

python - thunar/.config/Thunar/uca.xml <<'PY'
import sys
import xml.etree.ElementTree as ET

actions = ET.parse(sys.argv[1]).getroot().findall("action")
by_name = {action.findtext("name", ""): action for action in actions}

wallpaper = by_name.get("Set as wallpaper")
if wallpaper is None:
    raise SystemExit("missing Thunar wallpaper action")
if "noctalia msg wallpaper-set" not in wallpaper.findtext("command", ""):
    raise SystemExit("Thunar wallpaper action does not use Noctalia v5 IPC")

expected = {
    "Open Terminal Here": "kitty --directory %f",
    "Open in Neovim": "kitty --directory %f nvim .",
}
for name, command in expected.items():
    action = by_name.get(name)
    if action is None or action.findtext("command", "") != command:
        raise SystemExit(f"changed or missing preserved Thunar action: {name}")
PY
ok "Thunar actions use Noctalia and preserve development shortcuts"

for zsh_file in zsh/.zshrc zsh/.zprofile zsh/.config/zsh/*.zsh; do
    [[ -f "$zsh_file" ]] || fail "missing Zsh configuration: $zsh_file"
    if command -v zsh >/dev/null 2>&1; then
        zsh -n "$zsh_file"
    fi
done

if rg -n 'niri-session' zsh; then
    fail "Niri session startup must not be configured in Zsh"
fi

grep -Fq 'export VOLTA_HOME="$HOME/.volta"' zsh/.config/zsh/environment.zsh ||
    fail "Volta environment is missing from Zsh"
grep -Fq 'export SDKMAN_DIR="$HOME/.sdkman"' zsh/.config/zsh/environment.zsh ||
    fail "SDKMAN environment is missing from Zsh"
grep -Fq 'run_cmd volta install pnpm' scripts/install-dev-toolchain.sh ||
    fail "pnpm is not managed by Volta"
ok "Zsh, SDKMAN and Volta integration is preserved"

tmp_home="$(mktemp -d)"
trap 'rm -rf -- "$tmp_home"' EXIT

if command -v zsh >/dev/null 2>&1; then
    zsh_output="$(
        HOME="$tmp_home" XDG_CONFIG_HOME="$tmp_home/.config" \
            zsh -f -c "source '$DOTFILES_DIR/zsh/.config/zsh/environment.zsh'; source '$DOTFILES_DIR/zsh/.config/zsh/environment.zsh'"
    )"
    [[ -z "$zsh_output" ]] || fail "Zsh environment printed output while loading"
    ok "Zsh environment loads quietly and idempotently"
fi

HOME="$tmp_home" DOTFILES_DIR="$DOTFILES_DIR" \
    bash scripts/prepare-user-files.sh >/dev/null
[[ -d "$tmp_home/Pictures/Screenshots" ]] || fail "missing screenshots directory"
[[ -d "$tmp_home/Pictures/Wallpapers" ]] || fail "missing wallpapers directory"
[[ ! -e "$tmp_home/.config/gtk-4.0" ]] || fail "user preparation created GTK theme files"
[[ ! -e "$tmp_home/.config/${old_stack[0]%%land}" ]] || fail "old config was generated"
ok "user preparation creates only shared desktop directories"

mock_bin="$tmp_home/mock-bin"
link_test_dir="$tmp_home/.config/link-safety"
owned_broken_absolute="$link_test_dir/owned-broken-absolute"
owned_broken_relative="$link_test_dir/owned-broken-relative"
owned_valid="$link_test_dir/owned-valid"
external_broken="$link_test_dir/external-broken"
regular_file="$link_test_dir/regular-file"
mkdir -p -- "$mock_bin" "$link_test_dir"
printf '#!/usr/bin/env sh\nexit 0\n' > "$mock_bin/stow"
chmod +x "$mock_bin/stow"
ln -s -- "$DOTFILES_DIR/retired-dotfiles/missing" "$owned_broken_absolute"
relative_target="$(realpath -m --relative-to="$link_test_dir" \
    "$DOTFILES_DIR/retired-dotfiles/missing-relative")"
ln -s -- "$relative_target" "$owned_broken_relative"
ln -s -- "$DOTFILES_DIR/README.md" "$owned_valid"
ln -s -- "$tmp_home/external-project/missing" "$external_broken"
printf 'keep me\n' > "$regular_file"

HOME="$tmp_home" XDG_CONFIG_HOME="$tmp_home/.config" \
    DOTFILES_DIR="$DOTFILES_DIR" PATH="$mock_bin:$PATH" \
    bash scripts/apply-stow.sh >/dev/null
[[ ! -L "$owned_broken_absolute" ]] || fail "absolute retired dotfiles link was not removed"
[[ ! -L "$owned_broken_relative" ]] || fail "relative retired dotfiles link was not removed"
[[ -L "$owned_valid" ]] || fail "valid dotfiles link was removed"
[[ -L "$external_broken" ]] || fail "external broken link was removed"
[[ -f "$regular_file" ]] || fail "regular config file was removed"
ok "Stow cleanup only removes broken links owned by this repository"

if command -v stow >/dev/null 2>&1; then
    stow_home="$tmp_home/stow-home"
    stow_backup="$tmp_home/stow-backup"
    mkdir -p -- "$stow_home/.config/kitty"
    printf 'local zsh configuration\n' > "$stow_home/.zshrc"
    printf 'local kitty configuration\n' > "$stow_home/.config/kitty/kitty.conf"

    for stow_run in 1 2; do
        HOME="$stow_home" DOTFILES_DIR="$DOTFILES_DIR" BACKUP_ROOT="$stow_backup" \
            bash scripts/apply-stow.sh >/dev/null ||
            fail "Stow application run $stow_run failed"
    done

    [[ "$(readlink -f -- "$stow_home/.config/niri/config.kdl")" == \
        "$(readlink -f -- "$DOTFILES_DIR/niri/.config/niri/config.kdl")" ]] ||
        fail "Stow did not link Niri"
    [[ "$(readlink -f -- "$stow_home/.config/noctalia/config.toml")" == \
        "$(readlink -f -- "$DOTFILES_DIR/noctalia/.config/noctalia/config.toml")" ]] ||
        fail "Stow did not link Noctalia"
    [[ "$(cat "$stow_backup/.zshrc")" == "local zsh configuration" ]] ||
        fail "Stow did not preserve the existing Zsh configuration"
    [[ "$(cat "$stow_backup/.config/kitty/kitty.conf")" == "local kitty configuration" ]] ||
        fail "Stow did not preserve the existing Kitty configuration"
    [[ "$(find "$stow_backup" -type f | wc -l)" == "2" ]] ||
        fail "Stow backups were duplicated"
    ok "Stow links the new modules idempotently and preserves conflicts"
else
    ok "Stow application test skipped because GNU Stow is not installed"
fi

ok "safe structure test completed"
