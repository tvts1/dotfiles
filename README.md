# Dotfiles

Arch Linux dotfiles managed with GNU Stow.

## Install

Run the normal installer as a regular user:

```bash
./install.sh
```

The default install stays lightweight. It installs desktop packages, applies
Stow modules, enables required services, configures Elephant for Walker, and
disables Thunar's native wallpaper plugin so only the custom Hyprpaper action is
shown.

To also install the optional Java and Node development toolchain:

```bash
./install.sh --with-dev-tools
```

The optional toolchain can also be installed later:

```bash
bash scripts/install-dev-toolchain.sh
```

## Walker And Elephant

Walker is the frontend. Elephant is the backend service that provides searchable
data. Desktop application results require the `desktopapplications` Elephant
provider, installed by the AUR package `elephant-desktopapplications`.

This repository installs:

- `walker-bin`
- `elephant`
- `elephant-desktopapplications`
- `elephant-providerlist`
- `elephant-runner`

Elephant is managed as a systemd user service through:

```bash
bash scripts/configure-elephant.sh
```

Check the current state with:

```bash
bash scripts/configure-elephant.sh --check
elephant listproviders
systemctl --user status elephant.service --no-pager
```

Hyprland starts Walker once with `walker --gapplication-service`. It does not
start Elephant directly.

## Thunar Wallpaper Plugin

The custom Thunar action calls:

```bash
$HOME/.config/hypr/scripts/set-wallpaper.sh
```

The native Thunar plugin at
`/usr/lib/thunarx-3/thunar-wallpaper-plugin.so` is disabled by:

```bash
bash scripts/disable-thunar-wallpaper-plugin.sh
```

The script adds a managed pacman `NoExtract` entry for
`usr/lib/thunarx-3/thunar-wallpaper-plugin.so` and moves the existing plugin to:

```bash
/var/lib/dotfiles/thunar-wallpaper-plugin/thunar-wallpaper-plugin.so
```

That keeps the plugin disabled after Thunar package updates.

Restore it with:

```bash
bash scripts/restore-thunar-wallpaper-plugin.sh
```

## Development Toolchain

The optional toolchain script installs:

- SDKMAN in `$HOME/.sdkman`
- Java through SDKMAN
- Maven through SDKMAN
- Volta in `$HOME/.volta`
- Node through Volta
- npm bundled with Node
- pnpm through Volta native pnpm support

Defaults:

- `JAVA_VERSION` empty: `sdk install java`
- `MAVEN_VERSION` empty: `sdk install maven`
- `NODE_VERSION=lts`: `volta install node`

Examples:

```bash
bash scripts/install-dev-toolchain.sh --check
bash scripts/install-dev-toolchain.sh --dry-run
bash scripts/install-dev-toolchain.sh --java 21.0.4-tem --maven 3.9.9 --node 22
bash scripts/install-dev-toolchain.sh --skip-java
bash scripts/install-dev-toolchain.sh --skip-node
```

Fish integration is provided by the Stow-managed Fish config. A new Fish session
loads SDKMAN and Volta without relying on `.bashrc` or `.zshrc`.
