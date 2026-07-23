hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 15,
        border_size = 2,
        resize_on_border = true,
        layout = "dwindle",

        col = {
            active_border = "rgba(8aadf4ee)",
            inactive_border = "rgba(494d64aa)",
        },
    },

    decoration = {
        rounding = 12,
        active_opacity = 1.0,
        inactive_opacity = 0.95,

        blur = {
            enabled = true,
            size = 6,
            passes = 2,
        },

        shadow = {
            enabled = true,
            range = 8,
            render_power = 3,
            color = 0x99181726,
        },
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
    },
})

-- Cursor theme
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
