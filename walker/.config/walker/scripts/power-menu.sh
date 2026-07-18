#!/usr/bin/env bash

set -u

LOCK="󰌾  Lock"
SUSPEND="󰒲  Suspend"
HIBERNATE="󰤄  Hibernate"
LOGOUT="󰍃  Log out"
REBOOT="󰜉  Reboot"
SHUTDOWN="󰐥  Shut down"

selected="$(
    printf '%s\n' \
        "$LOCK" \
        "$SUSPEND" \
        "$HIBERNATE" \
        "$LOGOUT" \
        "$REBOOT" \
        "$SHUTDOWN" |
        walker --dmenu --exit
)"

case "$selected" in
    "$LOCK")
        exec hyprlock
        ;;

    "$SUSPEND")
        hyprlock &
        sleep 1
        exec systemctl suspend
        ;;

    "$HIBERNATE")
        hyprlock &
        sleep 1
        exec systemctl hibernate
        ;;

    "$LOGOUT")
        exec hyprctl dispatch exit
        ;;

    "$REBOOT")
        exec systemctl reboot
        ;;

    "$SHUTDOWN")
        exec systemctl poweroff
        ;;

    *)
        exit 0
        ;;
esac
