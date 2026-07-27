hl.on("hyprland.start", function()
    hl.exec_cmd(
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    )

    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd(
        "sh -c 'hyprpaper -c \"$HOME/.config/hypr/hyprpaper.conf\" >/dev/null 2>&1 & attempts=50; while [ \"$attempts\" -gt 0 ]; do hyprctl hyprpaper listactive >/dev/null 2>&1 && break; attempts=$((attempts - 1)); sleep 0.1; done; \"$HOME/.config/hypr/scripts/restore-wallpaper.sh\"'"
    )
    hl.exec_cmd("hypridle")

    hl.exec_cmd("walker --gapplication-service")

    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
end)
