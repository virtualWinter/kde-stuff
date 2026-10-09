# v-menu (`moe.vwinter.applemenu`)

A KDE Plasma 6 panel applet that mimics the macOS Apple menu: click the
apple-style icon on the panel to open a drop-down menu with system
information, settings, screenshots and session actions.

## Features

- **About This System** - opens KInfoCenter on the "Information About This
  System" page
- **System Settings**
- **Software Center** - shown when Discover (`plasma-discover` or `discover`)
  is installed
- **Force Quit…** - opens System Monitor on its process list
- **Take a Screenshot…** - opens Spectacle
- **Sleep / Restart… / Shut Down… / Lock Screen / Log Out…** - uses Plasma's
  session management, so the usual confirmation dialogs appear
- Menu entries whose program is not installed are hidden automatically
- Every menu entry can be shown or hidden in the settings
- The menu width and background color are configurable; the background
  defaults to the theme's dark background color
- The button icon is resolved from the active icon theme (the Arch Linux
  logo is preferred) and can be changed with a built-in icon picker

## Requirements

- Plasma 6.0 or newer
- The private QML modules `org.kde.plasma.private.sessions` and
  `org.kde.plasma.plasma5support`, which are shipped with plasma-workspace
- Optional: `kiconfinder6` (kiconthemes) for icon theme detection; without it
  the fallback icon `start-here-kde` is used

## Installation

```sh
make install
```

Then add the widget to a panel: right-click the panel, *Enter Edit Mode*,
*Add Widgets…*, search for "v-menu". If it does not appear in the list,
restart plasmashell with `make restart`.

Re-run `make install` after changing the source; it upgrades the installed
copy in place. `make uninstall` removes the widget.

## Configuration

Right-click the widget and choose *Configure v-menu…*:

- *Menu button icon* - an icon name from the active icon theme, or use
  *Choose…* to pick one from the theme; leave empty for automatic detection
- *Menu width (grid units)* - how wide the drop-down is; the default is 12
- *Menu background* - a color picker for the drop-down background; *Default*
  uses the theme's background color
- *Menu entries* - a checkbox for every entry: About This System, System
  Settings, Software Center, Force Quit, Take a Screenshot, Sleep, Restart,
  Shut Down, Lock Screen and Log Out
- *Keep the global menu visible while this menu is open* - opening a panel
  popup normally makes plasmashell the active window, which makes the
  Application Menu applet clear itself; this option keeps the application's
  menus visible while the v-menu is open (on by default)

## How the icon is chosen

`contents/code/env.sh` probes `kiconfinder6` for these names, in order, and
stops at the first exact match:

1. `distributor-logo-archlinux`
2. `archlinux-logo`
3. `start-here-archlinux`
4. `distributor-logo-apple`
5. `apple`
6. `start-here-kde`
7. `start-here`

Exact matching is important because `kiconfinder6` silently falls back to a
different icon when a name does not exist (`distributor-logo-apple` resolves
to `distributor-logo`, which in some themes is the logo of a Linux
distribution). If no candidate matches exactly, `start-here-kde` is used.

The Arch Linux logo comes first so the button matches the rest of the
desktop; the Apple-style names are still tried afterwards for users who have
them in their icon theme. Use *Choose…* in the settings to pick another
icon, or place a custom icon named `distributor-logo-apple.svg` in
`~/.local/share/icons/hicolor/scalable/apps/`.

## Development

- The environment detection script is runnable standalone:
  `sh package/contents/code/env.sh`.
- The QML uses only public and Plasma-internal APIs that are present in a
  standard Plasma 6 installation:
  - `org.kde.plasma.private.sessions` for session actions
  - `org.kde.plasma.plasma5support` (`DataSource` with the `executable`
    engine) for launching programs
  - `PlasmaComponents3.ItemDelegate` for the menu rows
