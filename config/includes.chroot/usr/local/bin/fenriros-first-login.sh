
#!/bin/sh
set -eu

WALLPAPER="/usr/share/backgrounds/fenriros/default.png"
MENU_ICON="/usr/share/pixmaps/fenriros/app-icon.png"
MARKER="${XDG_CONFIG_HOME:-$HOME/.config}/fenriros/branding-v3"

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


# Configure wallpaper on all connected displays.
MONITORS=$(xrandr --query |
    awk '$2 == "connected" {print $1}')

[ -n "$MONITORS" ] || exit 1

WORKSPACES=$(xfconf-query -c xfwm4 \
    -p /general/workspace_count 2>/dev/null || echo 1)

case "$WORKSPACES" in
    ''|*[!0-9]*|0) WORKSPACES=1 ;;
esac

for monitor in $MONITORS; do
    i=0
    while [ "$i" -lt "$WORKSPACES" ]; do
        base="/backdrop/screen0/monitor${monitor}/workspace${i}"

        set_property xfce4-desktop \
            "$base/last-image" string "$WALLPAPER"

        set_property xfce4-desktop \
            "$base/image-style" int 5

        i=$((i + 1))
    done
done

xfdesktop --reload

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

# Reload the Xfce panel to display the branded icon.
xfce4-panel -r

mkdir -p "$(dirname "$MARKER")"
touch "$MARKER"