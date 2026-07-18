local mainMod = "SUPER"
local screenshots = os.getenv("HOME") .. "/Pictures/Screenshots"

-- Aplicativos
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(launcher))

-- Menu de energia com Walker
hl.bind(
    mainMod .. " + X",
    hl.dsp.exec_cmd(
        os.getenv("HOME") ..
        "/.config/walker/scripts/power-menu.sh"
    )
)

-- Janelas e sessão
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(
    mainMod .. " + F",
    hl.dsp.window.fullscreen({ mode = 1 })
)
hl.bind(mainMod .. "+ SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(
    mainMod .. " + SHIFT + E",
    hl.dsp.exec_cmd("hyprctl dispatch 'hl.dsp.exit()'")
)

-- Foco no estilo Vim
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

-- Workspaces
for workspace = 1, 10 do
    local key = workspace % 10

    hl.bind(
        mainMod .. " + " .. key,
        hl.dsp.focus({ workspace = workspace })
    )

    hl.bind(
        mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({ workspace = workspace })
    )
end

-- Mouse<D-Space>
hl.bind(
    mainMod .. " + mouse:272",
    hl.dsp.window.drag(),
    { mouse = true }
)

hl.bind(
    mainMod .. " + mouse:273",
    hl.dsp.window.resize(),
    { mouse = true }
)

-- Áudio
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true }
)

-- Brilho
hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd("brightnessctl set 5%+"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd("brightnessctl set 5%-"),
    { locked = true, repeating = true }
)

hl.bind(
    mainMod .. " + C",
    hl.dsp.exec_cmd(
        "cliphist list | walker --dmenu | cliphist decode | wl-copy"
    )
)

-- Tela inteira → Clipboard
hl.bind(
    "PRINT",
    hl.dsp.exec_cmd("hyprshot -m output --clipboard-only")
)

-- Região → Clipboard
hl.bind(
    "SHIFT + PRINT",
    hl.dsp.exec_cmd("hyprshot -m region --clipboard-only")
)

-- Tela inteira → Salva
hl.bind(
    mainMod .. " + PRINT",
    hl.dsp.exec_cmd("hyprshot -m output -o " .. screenshots)
)

-- Região → Salva
hl.bind(
    mainMod .. " + SHIFT + PRINT",
    hl.dsp.exec_cmd("hyprshot -m region -o " .. screenshots)
)
