
#!/bin/sh
set -eu

WALLPAPER="/usr/share/backgrounds/fenriros/default.png"
MENU_ICON="/usr/share/pixmaps/fenriros/menu-icon.png"
MARKER="${XDG_CONFIG_HOME:-$HOME/.config}/fenriros/branding-v1"

# Apply defaults once, without overwriting user changes.
[ -e "$MARKER" ] && exit 0
[ -r "$WALLPAPER" ] || exit 1

# Allow Xfce to initialize its desktop and panel.
sleep 5

# Create or update an Xfconf property.
set_property() {
    if xfconf-query -c "$1" -p "$2" >/dev/null 2>&1; then
        xfconf-query -c "$1" -p "$2" -s "$4"
    else
        xfconf-query -c "$1" -p "$2" -n -t "$3" -s "$4"
    fi
}

# Use the wallpaper properties Xfce already detected.
PROPS=$(xfconf-query -c xfce4-desktop -p /backdrop -l 2>/dev/null |
    grep '/last-image$' || true)

if [ -n "$PROPS" ]; then
    printf '%s\n' "$PROPS" | while IFS= read -r prop; do
        set_property xfce4-desktop "$prop" string "$WALLPAPER"
        set_property xfce4-desktop \
            "${prop%/last-image}/image-style" int 5
    done
else
    # Fallback for a new Xfce configuration.
    MONITORS=$(xrandr --query 2>/dev/null |
        awk '$2 == "connected" {print $1}' || true)

    for monitor in $MONITORS 0; do
        base="/backdrop/screen0/monitor${monitor}/workspace0"
        set_property xfce4-desktop \
            "$base/last-image" string "$WALLPAPER"
        set_property xfce4-desktop \
            "$base/image-style" int 5
    done
fi

# Brand the standard Xfce Applications Menu.
if [ -r "$MENU_ICON" ]; then
    MENUS=$(xfconf-query -c xfce4-panel -lv 2>/dev/null |
        awk '$2 == "applicationsmenu" {print $1}' || true)

    printf '%s\n' "$MENUS" | while IFS= read -r menu; do
        [ -n "$menu" ] || continue
        set_property xfce4-panel \
            "$menu/button-icon" string "$MENU_ICON"
    done
fi

mkdir -p "$(dirname "$MARKER")"
touch "$MARKER"
