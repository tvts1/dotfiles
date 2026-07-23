# Default applications
set -gx SHELL /usr/bin/fish
set -gx TERMINAL kitty
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BROWSER firefox

# Better pager
set -gx PAGER bat

# Locale
if type -q locale
    if locale -a | string match -q -- en_US.utf8 en_US.UTF-8
        set -gx LANG en_US.UTF-8
    end
end

# Volta - Node.js toolchain manager
set -gx VOLTA_HOME "$HOME/.volta"
if test -d "$VOLTA_HOME/bin"
    fish_add_path "$VOLTA_HOME/bin"
end
