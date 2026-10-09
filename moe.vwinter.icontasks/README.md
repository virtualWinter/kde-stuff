# v-taskmanager (`moe.vwinter.icontasks`)

A lightweight QML-only icons-only task manager for KDE Plasma 6.

Every running task is marked with a small dot centered below its icon; the
focused task's dot becomes a short line. Tasks that demand attention get an
orange dot. Clicking a grouped icon cycles through its windows.

## Behavior

- One icon per running application (windows grouped by application).
- Left-click activates; clicking the active task minimizes it (configurable).
- Middle-click closes the task (all windows for grouped icons).
- Drag an icon to reorder the tasks; the order of pinned apps is remembered.
- Right-click for the task manager menu (pin/unpin, move to desktop,
  activities, window actions, the application's own actions and recent files).
- Drag application .desktop files (e.g. from the Launchpad) onto the widget to
  pin them.
- Pinned launchers stay visible when the app is not running; a running app
  takes its launcher's place in the row.
- A subtle separator divides the pinned apps from the unpinned running ones
  (can be turned off in the settings).
- Indicators animate: dots fade/scale in for running tasks and the focused
  task's dot stretches into a line; icons and hover highlights fade smoothly.

## Options

- Icon size (0 fits the panel height automatically), icon spacing.
- Indicator size and focused line width, accent or white color.
- Attention dot on/off, minimize-on-click on/off.
- Filter tasks by current desktop, screen, activity.

## Install

```sh
make install
systemctl --user restart plasma-plasmashell.service
```

Then add "v-taskmanager" via Add Widgets, replacing the
stock Icons-Only Task Manager.
