#!/bin/sh
# Environment detection for the Apple Menu plasmoid.
#
# Prints one record per line:
#   ICON:<icon-theme-name>          best available themed icon for the menu button
#   CMD:<command>=<absolute-path>   available commands the menu can launch
#
# Exact matches only for icons: kiconfinder6 silently falls back to a
# different icon when the exact name does not exist (for example
# distributor-logo-apple resolves to distributor-logo, which in some themes
# is a different vendor's logo), so the resolved file name is compared with
# the requested one.
#
# The Arch Linux logo is preferred so that the button matches the rest of the
# desktop; the Apple-style names are still tried afterwards for users who
# have them in their icon theme.

icon=""
for name in distributor-logo-archlinux archlinux-logo start-here-archlinux distributor-logo-apple apple start-here-kde start-here; do
    path=$(kiconfinder6 "$name" 2>/dev/null)
    base=${path##*/}
    base=${base%.*}
    if [ -n "$path" ] && [ "$base" = "$name" ]; then
        icon="$name"
        break
    fi
done
if [ -z "$icon" ]; then
    icon="start-here-kde"
fi
printf 'ICON:%s\n' "$icon"

for command in systemsettings plasma-discover discover kinfocenter plasma-systemmonitor spectacle; do
    path=$(command -v "$command" 2>/dev/null)
    if [ -n "$path" ]; then
        printf 'CMD:%s=%s\n' "$command" "$path"
    fi
done
