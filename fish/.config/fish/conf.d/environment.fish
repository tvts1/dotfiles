# Default applications
set -gx SHELL /usr/bin/fish
set -gx TERMINAL kitty
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BROWSER firefox

# Better pager
set -gx PAGER bat

# Locale
set -gx LANG en_US.UTF-8

# Volta - Node.js toolchain manager
set -gx VOLTA_HOME "$HOME/.volta"
fish_add_path "$VOLTA_HOME/bin"
