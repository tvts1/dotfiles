# Thunar Wallpaper Plugin

Arch's `thunar` package includes:

```bash
/usr/lib/thunarx-3/thunar-wallpaper-plugin.so
```

That plugin adds Thunar's native `Set as wallpaper` menu item. These dotfiles
keep the custom Hyprpaper action and disable the native plugin.

Disable:

```bash
bash scripts/disable-thunar-wallpaper-plugin.sh
```

Check:

```bash
bash scripts/disable-thunar-wallpaper-plugin.sh --check
```

Restore:

```bash
bash scripts/restore-thunar-wallpaper-plugin.sh
```

The disable script adds this pacman option:

```bash
NoExtract = usr/lib/thunarx-3/thunar-wallpaper-plugin.so
```

It also moves any existing plugin file into:

```bash
/var/lib/dotfiles/thunar-wallpaper-plugin/
```

Because pacman owns `NoExtract`, package upgrades do not re-create the disabled
plugin file. The restore script removes the managed `NoExtract` entry and copies
the saved plugin back, or reinstalls `thunar` when no backup is available.
