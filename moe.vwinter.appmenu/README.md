# v-appmenu (`moe.vwinter.appmenu`)

A fork of Plasma's Global Menu applet (`org.kde.plasma.appmenu`) that adds a
macOS-style application name at the start of the menu bar. Everything else is
the stock 6.7 implementation.

- The name of the focused window's application is shown in bold, like macOS.
- If the application already has a menu entry with the same name, the title is
  not repeated.
- Works for any focused window, even ones that do not export a menu
  (Electron apps, games, …).
- The name is kept while a panel popup is open, and cleared when no window is
  focused.
- The applet hides itself when there is nothing to show and comes back as soon
  as there is something.

## Install

```sh
make install    # install the KPackage and build/install the plugin
make restart
```

From the monorepo root, `make install` installs every add-on.

## Build requirements

The plugin is compiled, so it needs these packages installed system-wide
(on Arch Linux: `sudo pacman -S cmake extra-cmake-modules`):

- cmake >= 3.16 and extra-cmake-modules
- Qt 6 (Core, Widgets, Quick, DBus)
- KF6 (Config, CoreAddons, WindowSystem, I18n), libplasma, LibTaskManager

`make build` compiles without installing or restarting Plasma. Override
`BUILD_DIR` for a separate build directory or `JOBS` for the number of
parallel compilation jobs.

The plugin is installed to
`~/.local/lib/qt6/plugins/plasma/applets/moe.vwinter.appmenu.so`, and
plasmashell must be told to look there, e.g. in
`~/.config/environment.d/v-appmenu.conf`:

```
QT_PLUGIN_PATH=/home/<user>/.local/lib/qt6/plugins
```

`make plugin` prints a reminder if that is missing. `make uninstall` removes
both the KPackage and the plugin.

## Layout

- `package/` — the KPackage (metadata, config, QML sources)
- `src/` — the C++ applet class and menu model (forked from plasma-workspace)
- `vendor/libdbusmenuqt/` — the DBusMenu importer, vendored from
  plasma-workspace
- `CMakeLists.txt` — the plugin build (driven by the Makefile)

## Development note

The running applet uses the QML compiled into the plugin, not the copy on disk
in the KPackage. After changing any QML, rebuild the plugin (`make plugin`)
and restart plasmashell.
