#!/usr/bin/env bash

set -u

LOCK="󰌾  Lock"
SUSPEND="󰒲  Suspend"
HIBERNATE="󰤄  Hibernate"
LOGOUT="󰍃  Log out"
REBOOT="󰜉  Reboot"
SHUTDOWN="󰐥  Shut down"

can_hibernate() {
    local value

    if command -v busctl >/dev/null 2>&1; then
        value="$(
            busctl get-property \
                org.freedesktop.login1 \
                /org/freedesktop/login1 \
                org.freedesktop.login1.Manager \
                CanHibernate 2>/dev/null |
                awk '{print $2}' |
                tr -d '"'
        )"

        [[ "$value" == "yes" || "$value" == "challenge" ]] && return 0
    fi

    [[ -r /sys/power/state ]] && grep -qw disk /sys/power/state
}

options=(
    "$LOCK"
    "$SUSPEND"
)

if can_hibernate; then
    options+=("$HIBERNATE")
fi

options+=(
    "$LOGOUT"
    "$REBOOT"
    "$SHUTDOWN"
)

selected="$(
    printf '%s\n' "${options[@]}" |
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
