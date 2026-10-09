# vwinter's Plasma add-ons

A monorepo with custom KDE Plasma 6 add-ons: two QML-only widgets and two
compiled widgets (a Global Menu fork with a macOS-style application name, and a
Launchpad whose pinning uses a C++ backend).

| Add-on | Widget name | Package id | Description |
| --- | --- | --- | --- |
| [`moe.vwinter.applemenu`](moe.vwinter.applemenu/) | v-menu | `moe.vwinter.applemenu` | macOS-style Apple menu (system info, settings, screenshots, session actions) |
| [`moe.vwinter.launchpad`](moe.vwinter.launchpad/) | v-launchpad | `moe.vwinter.launchpad` | Fullscreen Launchpad-style app grid with paging and search (QML + C++ plugin) |
| [`moe.vwinter.icontasks`](moe.vwinter.icontasks/) | v-taskmanager | `moe.vwinter.icontasks` | Icons-only task manager: a dot under every running app, a short line under the focused one |
| [`moe.vwinter.appmenu`](moe.vwinter.appmenu/) | v-appmenu | `moe.vwinter.appmenu` | Global Menu fork showing the focused application's name in bold (QML + C++ plugin) |

## Install

```sh
make install    # installs all four add-ons (builds the compiled plugins)
make restart    # restart plasmashell
```

Useful targets:

| Command | What it does |
| --- | --- |
| `make build` | compile the plugins without installing or restarting Plasma |
| `make install` | all add-ons: KPackages plus the compiled plugins |
| `make plugin` | just build/install the compiled plugins |
| `make restart` | restart plasmashell (`setsid -f plasmashell --replace`) |
| `make uninstall` | remove all add-ons |
| `make clean` | remove build outputs |

Each add-on can also be installed on its own:

```sh
make -C moe.vwinter.launchpad install
```

## Requirements

- Plasma 6.0 or newer.
- The QML-only widgets (`v-menu`, `v-taskmanager`) need nothing else; they use
  private QML modules that ship with plasma-workspace.
- `v-appmenu` and `v-launchpad` are compiled: cmake ≥ 3.16,
  extra-cmake-modules, Qt 6, KF6 and libplasma (v-appmenu also needs
  LibTaskManager). On Arch Linux: `sudo pacman -S cmake extra-cmake-modules`
  (the rest are pulled in by the Plasma/Qt packages). The plugins install to
  `~/.local/lib/qt6/plugins/plasma/applets/`, and plasmashell needs
  `QT_PLUGIN_PATH=~/.local/lib/qt6/plugins` (e.g. in
  `~/.config/environment.d/vwinter.conf`).

## Restarting plasmashell

`systemctl --user restart plasma-plasmashell` does not work in this setup.
Use:

```sh
setsid -f plasmashell --replace
```

or `make restart`.

## Repository layout

```
.
├── Makefile                  # monorepo orchestration
├── moe.vwinter.applemenu/    # v-menu
├── moe.vwinter.launchpad/    # v-launchpad (C++ plugin + KPackage)
├── moe.vwinter.icontasks/    # v-taskmanager
└── moe.vwinter.appmenu/      # v-appmenu (C++ plugin + KPackage)
```
