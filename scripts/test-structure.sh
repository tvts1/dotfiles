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

cd "$DOTFILES_DIR"

hardcoded_home='/home/''tassio'

if rg -n --hidden -S "$hardcoded_home" --glob '!.git/**' .; then
  fail "hard-coded user home remains"
fi
ok "no hard-coded user home paths"

if rg -n --hidden -S 'pacman\s+-Sy(\s|$)' --glob '!.git/**' .; then
  fail "unsafe pacman sync-only command remains"
fi
ok "no unsafe pacman sync-only usage"

if find . -xtype l -not -path './.git/*' -print | grep -q .; then
  find . -xtype l -not -path './.git/*' -print >&2
  fail "broken symlinks found in repository"
fi
ok "no broken symlinks in repository"

[[ -f hypr/.config/hypr/hyprpaper.conf.tmpl ]] || fail "missing Hyprpaper template"
[[ -f hypr/.config/hypr/hyprlock.conf.tmpl ]] || fail "missing Hyprlock template"
[[ ! -e hypr/.config/hypr/hyprpaper.conf ]] || fail "Hyprpaper generated config should not be stowed"
[[ ! -e hypr/.config/hypr/hyprlock.conf ]] || fail "Hyprlock generated config should not be stowed"
ok "generated Hypr configs are templates only"

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
[[ -f "$tmp_home/.config/hypr/hyprpaper.conf" ]] || fail "missing generated Hyprpaper config"
[[ -f "$tmp_home/.config/hypr/hyprlock.conf" ]] || fail "missing generated Hyprlock config"

if rg -n --hidden -S "$hardcoded_home|eDP-1" "$tmp_home/.config/hypr"; then
  fail "generated Hypr config is not portable"
fi
ok "prepare-user-files works against a temporary HOME"

if command -v stow >/dev/null 2>&1; then
  for module in desktop fish gtk hypr kitty nvim starship thunar walker waybar; do
    stow --dir="$DOTFILES_DIR" --target="$tmp_home" --no-folding --simulate "$module" >/dev/null
  done

  ok "Stow simulation succeeds against a temporary HOME"
else
  ok "Stow simulation skipped because stow is not installed"
fi

ok "safe structure test completed"
