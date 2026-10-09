# v-launchpad (`moe.vwinter.launchpad`)

A KDE Plasma 6 panel applet that opens a macOS Launchpad-style application
grid above its panel button: paged app icons, page dots and a search field.

The applet is compiled: a small C++ backend handles "Pin to Task Manager",
which edits the `launchers` of every v-taskmanager widget in the session. All
of the user interface is QML.

## Features

- Compact panel popup opened above its panel button, with the desktop still
  visible around it
- All applications in a paged grid; drag horizontally or use a two-finger
  touchpad scroll to move one page at a time, or click the page dots
- Search field at the top filters applications as you type; Enter launches the
  selected match
- Click an application to launch it; the launcher closes afterwards by default
- Hide applications from the settings page (checkbox list, no accidental hiding)
- Right-click a tile to pin or unpin the application in the v-taskmanager
  (uses the C++ backend, no plasmashell scripting)
- Drag an icon out of the launcher: it carries the application .desktop file,
  e.g. drop it onto a task manager to pin it (drag empty space to page)
- Escape clears the search, then closes the launcher; clicking an empty area
  within it also closes it
- Configurable: panel icon, icons per row, rows per page, application labels,
  close-on-launch

## Requirements

- Plasma 6.0 or newer
- The private QML modules `org.kde.plasma.private.kicker` and
  `org.kde.plasma.plasma5support`, which are shipped with plasma-workspace
- A compiler toolchain installed system-wide: cmake ≥ 3.16,
  extra-cmake-modules, Qt 6, KF6 and libplasma (on Arch Linux:
  `sudo pacman -S cmake extra-cmake-modules`).

## Installation

```sh
make install
```

This installs the KPackage and builds/installs the plugin to
`~/.local/lib/qt6/plugins/plasma/applets/`. plasmashell must search that
directory, e.g. in `~/.config/environment.d/vwinter.conf`:

```
QT_PLUGIN_PATH=/home/<user>/.local/lib/qt6/plugins
```

Then add the widget to a panel: right-click the panel, *Enter Edit Mode*,
*Add Widgets…*, search for "v-launchpad". If it does not appear in the list,
restart plasmashell with `make restart`.

The UI runs from the QML compiled into the plugin, so re-run `make install`
after changing any QML. `make uninstall` removes the widget and the plugin.
`make build` compiles without installing.

## Configuration

Right-click the widget and choose *Configure v-launchpad…*:

- *Panel button icon* - an icon name from the active icon theme, or use
  *Choose…* to pick one; defaults to `applications-other`
- *Icons per row* / *Rows per page* - the page grid size (default 7 × 5)
- *Hidden applications* - checkbox list; uncheck to hide, re-check to restore
- *Show application names* - toggles the labels under the icons
- *Close after launching an application*

## How it works

- The application list comes from `Kicker.RootModel` with `showAllApps: true`;
  the "All Applications" submodel (`KICKER_ALL_MODEL`) is used directly.
- Search filters that model with `Plasma5Support.SortFilterModel`; launching
  maps the filtered row back to the source model with `mapToSource()`. A
  preceding proxy filters app IDs the user has hidden.
- The launcher is a Plasma shell-managed `fullRepresentation` popup, so it is
  positioned reliably above the panel on Wayland. The applet draws its own
  dark application grid inside that popup.
- The applet advertises `org.kde.plasma.launchermenu` in its metadata, so the
  shell's "activate launcher menu" action also toggles it.
- The C++ backend (`src/launchpadapplet.cpp`, a `Plasma::Applet`) is exposed to
  QML as `Plasmoid.pinToTaskManager()` / `unpinFromTaskManager()` /
  `isPinnedToTaskManager()`. It walks the corona's containments, finds every
  applet whose plugin id is `moe.vwinter.icontasks` and updates its
  `launchers` entry through its `KConfigLoader`, so the running widget refreshes
  immediately.
