import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    Plasmoid.title: i18n("v-taskmanager")
    Plasmoid.constraintHints: Plasmoid.CanFillArea

    // ------------------------------------------------------------------
    // Configuration
    // ------------------------------------------------------------------
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int configuredIconSize: Plasmoid.configuration.iconSize
    readonly property int iconSpacing: Plasmoid.configuration.spacing
    readonly property int dotSize: Math.max(2, Plasmoid.configuration.dotSize)
    readonly property int focusedIndicatorWidth: Math.max(2, Plasmoid.configuration.focusedIndicatorWidth)
    readonly property bool useAccentDot: Plasmoid.configuration.useAccentDot
    readonly property bool showAttentionDot: Plasmoid.configuration.showAttentionDot
    readonly property bool minimizeActiveTaskOnClick: Plasmoid.configuration.minimizeActiveTaskOnClick
    readonly property bool showOnlyCurrentDesktop: Plasmoid.configuration.showOnlyCurrentDesktop
    readonly property bool showOnlyCurrentScreen: Plasmoid.configuration.showOnlyCurrentScreen
    readonly property bool showOnlyCurrentActivity: Plasmoid.configuration.showOnlyCurrentActivity
    readonly property bool showLauncherSeparator: Plasmoid.configuration.showLauncherSeparator
    readonly property var pinnedLauncherUrls: Plasmoid.configuration.launchers || []

    readonly property int dotGap: 2
    readonly property int dotSpace: dotSize + dotGap
    // Show one dot per window, capped at this many.
    readonly property int maxIndicatorDots: 3
    readonly property int autoIconSize: Math.max(16, Math.floor(
        (vertical ? root.width : root.height) - root.dotSpace - 4))
    readonly property int effectiveIconSize: configuredIconSize > 0 ? configuredIconSize : autoIconSize
    readonly property color indicatorColor: useAccentDot ? Kirigami.Theme.highlightColor : "white"

    // Rows involved in a drag-to-reorder (-1 when idle).
    property int reorderSourceRow: -1
    property int reorderTargetRow: -1

    // True while the launcher model is being updated to match the config, so
    // the resulting model changes are not written back to the config.
    property bool syncingLaunchersFromConfig: false

    // Number of leading rows that are pinned: launchers plus the running
    // windows that occupy their launcher's slot (launch-in-place). The
    // separator between pinned and unpinned apps goes after these.
    readonly property int pinnedRowCount: {
        const count = tasksModel.count;
        const pins = root.pinnedLauncherUrls;
        let pinned = 0;
        for (let i = 0; i < count; ++i) {
            const idx = tasksModel.makeModelIndex(i);
            const isLauncher = tasksModel.data(idx, TaskManager.AbstractTasksModel.IsLauncher);
            const isWindow = tasksModel.data(idx, TaskManager.AbstractTasksModel.IsWindow);
            let rowIsPinned = !!isLauncher;
            if (!rowIsPinned && isWindow) {
                const url = tasksModel.data(idx, TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon);
                rowIsPinned = tasksModel.launcherPosition(url) !== -1;
            }
            if (!rowIsPinned) {
                break;
            }
            ++pinned;
        }
        return pinned;
    }

    // ------------------------------------------------------------------
    // Task model: one row per application, no launchers
    // ------------------------------------------------------------------
    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    TaskManager.TasksModel {
        id: tasksModel

        screenGeometry: root.Plasmoid.containment ? root.Plasmoid.containment.screenGeometry : Qt.rect(0, 0, 0, 0)
        activity: activityInfo.currentActivity

        filterByCurrentVirtualDesktop: root.showOnlyCurrentDesktop
        filterByScreen: root.showOnlyCurrentScreen
        filterByActivity: root.showOnlyCurrentActivity

        groupMode: TaskManager.TasksModel.GroupApplications
        groupInline: false

        // Manual sorting is required for drag-to-reorder (and is also the
        // stock task manager's default). launchInPlace keeps a running app in
        // its launcher's slot and makes those tasks reorderable.
        sortMode: TaskManager.TasksModel.SortManual
        launchInPlace: true

        separateLaunchers: true
        hideActivatedLaunchers: true

        onLauncherListChanged: {
            // Ignore changes we just applied while syncing from the config.
            if (root.syncingLaunchersFromConfig) {
                return;
            }
            // Do not write back an equivalent list (the model re-sorts
            // launchers): that would ping-pong between config and model.
            if (root.sameLaunchers(Plasmoid.configuration.launchers, launcherList)) {
                return;
            }
            Plasmoid.configuration.launchers = launcherList;
        }
    }

    Component.onCompleted: {
        root.findAppsModel();
        tasksModel.launcherList = root.pinnedLauncherUrls || [];
    }

    // ------------------------------------------------------------------
    // Application actions for the context menu (jump list actions and
    // recent documents), looked up through Kicker.
    // ------------------------------------------------------------------
    Kicker.RootModel {
        id: appModel

        // The Kicker model needs the applet interface to build each entry's
        // action list (jump-list actions and recent documents). Without it the
        // context menu's app-specific sections come out empty.
        appletInterface: root

        flat: true
        sorted: true
        showAllApps: true
        showAllAppsCategorized: false
        autoPopulate: true

        onCountChanged: root.findAppsModel()
    }

    property var appsModel: null

    function findAppsModel() {
        for (let i = 0; i < appModel.count; ++i) {
            const model = appModel.modelForRow(i);
            if (model && model.description === "KICKER_ALL_MODEL") {
                root.appsModel = model;
                return;
            }
        }
    }

    P5Support.SortFilterModel {
        id: appEntryProxy

        sourceModel: root.appsModel
        filterRole: "favoriteId"
    }

    function appActionSections(appId) {
        if (!root.appsModel || appEntryProxy.count === 0) {
            return null;
        }

        let wanted = String(appId ?? "");
        if (wanted.endsWith(".desktop")) {
            wanted = wanted.slice(0, wanted.length - 8);
        }
        if (wanted.length === 0) {
            return null;
        }

        for (let row = 0; row < appEntryProxy.count; ++row) {
            const entry = appEntryProxy.get(row);
            if (!entry) {
                continue;
            }
            if (String(entry.favoriteId ?? "") !== wanted + ".desktop") {
                continue;
            }
            const recents = [];
            const actions = [];
            const list = entry.actionList ?? [];
            for (let i = 0; i < list.length; ++i) {
                const action = list[i];
                if (!action) {
                    continue;
                }
                if (action.actionId === "_kicker_recentDocument") {
                    recents.push(action);
                } else if (action.actionId === "_kicker_jumpListAction") {
                    actions.push(action);
                }
            }
            return { "row": row, "recents": recents, "actions": actions };
        }

        return null;
    }

    function triggerAppAction(proxyRow, actionId, argument) {
        if (!root.appsModel) {
            return;
        }
        const sourceIndex = appEntryProxy.mapToSource(appEntryProxy.index(proxyRow, 0));
        if (sourceIndex && sourceIndex.valid) {
            root.appsModel.trigger(sourceIndex.row, actionId, argument);
        }
    }

    // Keep the model in sync when the launcher list is changed from outside,
    // e.g. by the Launchpad's "Pin to Task Manager" action writing our config.
    onPinnedLauncherUrlsChanged: {
        const wanted = root.pinnedLauncherUrls || [];
        const current = tasksModel.launcherList || [];
        if (root.sameLaunchers(wanted, current)) {
            return;
        }
        // requestAddLauncher/requestRemoveLauncher apply synchronously and
        // emit launcherListChanged; guard so those intermediate states are
        // not written back into the config.
        root.syncingLaunchersFromConfig = true;
        for (let i = 0; i < wanted.length; ++i) {
            if (tasksModel.launcherPosition(wanted[i]) === -1) {
                tasksModel.requestAddLauncher(wanted[i]);
            }
        }
        for (let i = 0; i < current.length; ++i) {
            let keep = false;
            for (let j = 0; j < wanted.length; ++j) {
                if (String(wanted[j]) === String(current[i])) {
                    keep = true;
                    break;
                }
            }
            if (!keep) {
                tasksModel.requestRemoveLauncher(current[i]);
            }
        }
        root.syncingLaunchersFromConfig = false;
    }

    // Whether two launcher lists contain the same entries (order-insensitive:
    // the model re-sorts launchers on its own, which must not ping-pong back
    // into the config).
    function sameLaunchers(a, b) {
        const left = a || [];
        const right = b || [];
        if (left.length !== right.length) {
            return false;
        }
        const wanted = new Set(Array.from(left, String));
        return Array.from(right, String).every(url => wanted.has(url));
    }

    function taskRole(row, role) {
        return tasksModel.data(tasksModel.makeModelIndex(row), role);
    }

    function activateTaskRow(row) {
        if (taskRole(row, TaskManager.AbstractTasksModel.IsGroupParent)) {
            const parentIndex = tasksModel.makeModelIndex(row);
            const childCount = tasksModel.rowCount(parentIndex);
            if (childCount === 0) {
                return;
            }
            let activeChild = -1;
            for (let j = 0; j < childCount; ++j) {
                const child = tasksModel.makeModelIndex(row, j);
                if (tasksModel.data(child, TaskManager.AbstractTasksModel.IsActive)) {
                    activeChild = j;
                    break;
                }
            }
            // Cycle through the group's windows, starting with the first one.
            const next = activeChild < 0 ? 0 : (activeChild + 1) % childCount;
            tasksModel.requestActivate(tasksModel.makeModelIndex(row, next));
            return;
        }

        const taskIndex = tasksModel.makeModelIndex(row);
        if (taskRole(row, TaskManager.AbstractTasksModel.IsMinimized)) {
            tasksModel.requestToggleMinimized(taskIndex);
            tasksModel.requestActivate(taskIndex);
        } else if (taskRole(row, TaskManager.AbstractTasksModel.IsActive) && root.minimizeActiveTaskOnClick) {
            tasksModel.requestToggleMinimized(taskIndex);
        } else {
            tasksModel.requestActivate(taskIndex);
        }
    }

    function closeTaskRow(row) {
        if (taskRole(row, TaskManager.AbstractTasksModel.IsGroupParent)) {
            const childCount = tasksModel.rowCount(tasksModel.makeModelIndex(row));
            for (let j = 0; j < childCount; ++j) {
                tasksModel.requestClose(tasksModel.makeModelIndex(row, j));
            }
            return;
        }
        if (taskRole(row, TaskManager.AbstractTasksModel.IsWindow)) {
            tasksModel.requestClose(tasksModel.makeModelIndex(row));
        }
    }

    // ------------------------------------------------------------------
    // Panel representation: icons in a row, dot below the active task
    // ------------------------------------------------------------------
    // Context menu, created fresh for every right-click like the stock
    // task manager does (see TaskMenu.qml).
    readonly property Component taskMenuComponent: Qt.createComponent("TaskMenu.qml")

    function createTaskMenu(visualParentItem, modelIndex) {
        if (taskMenuComponent.status !== Component.Ready) {
            return null;
        }
        return taskMenuComponent.createObject(visualParentItem, {
            "visualParent": visualParentItem,
            "modelIndex": modelIndex,
        });
    }

    fullRepresentation: Item {
        id: taskRow

        Layout.fillWidth: !root.vertical
        Layout.fillHeight: root.vertical
        Layout.minimumWidth: root.vertical ? root.effectiveIconSize : taskLayout.implicitWidth
        Layout.minimumHeight: root.vertical ? taskLayout.implicitHeight : root.effectiveIconSize + root.dotSpace

        implicitWidth: Layout.minimumWidth
        implicitHeight: Layout.minimumHeight

        // ------------------------------------------------------------------
        // Drag to reorder
        // ------------------------------------------------------------------
        function reorderIndexAt(sceneX, sceneY) {
            const count = taskRepeater.count;
            if (count === 0) {
                return -1;
            }
            const local = taskLayout.mapFromItem(null, sceneX, sceneY);
            const step = root.effectiveIconSize + root.iconSpacing + (root.vertical ? root.dotSpace : 0);
            const pos = root.vertical ? local.y : local.x;
            return Math.max(0, Math.min(count - 1, Math.floor(pos / step)));
        }

        function finishReorder(sceneX, sceneY) {
            const from = root.reorderSourceRow;
            let target = root.reorderTargetRow;
            root.reorderSourceRow = -1;
            root.reorderTargetRow = -1;
            if (from < 0 || from >= taskRepeater.count) {
                return;
            }
            if (target < 0) {
                target = reorderIndexAt(sceneX, sceneY);
            }
            if (target < 0 || target === from) {
                return;
            }
            tasksModel.move(from, target);
            tasksModel.syncLaunchers();
        }

        DropArea {
            anchors.fill: parent

            onEntered: drag => {
                // Reject internal plasmoid and task-manager drags, accept files.
                if (drag.formats.indexOf("text/x-plasmoidservicename") >= 0
                        || drag.formats.indexOf("application/x-orgkdeplasmataskmanager_taskbuttonitem") >= 0) {
                    drag.accepted = false;
                } else if (drag.hasUrls) {
                    drag.accepted = true;
                }
            }

            onDropped: drop => {
                if (!drop.hasUrls) {
                    return;
                }
                for (let i = 0; i < drop.urls.length; ++i) {
                    tasksModel.requestAddLauncher(drop.urls[i]);
                }
                drop.accepted = true;
            }
        }

        Grid {
            id: taskLayout

            anchors.centerIn: parent
            columns: root.vertical ? 1 : Math.max(1, taskRepeater.count)
            rows: root.vertical ? Math.max(1, taskRepeater.count) : 1
            flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
            spacing: root.iconSpacing

            Repeater {
                id: taskRepeater

                model: tasksModel

                delegate: PlasmaCore.ToolTipArea {
                    id: taskDelegate

                    width: root.effectiveIconSize
                    height: root.effectiveIconSize + root.dotSpace

                    readonly property bool runningTask: !model.IsLauncher && !model.IsStartup
                        && (model.IsWindow || model.IsGroupParent)
                    readonly property bool focusedTask: !!model.IsActive
                    readonly property bool attentionTask: root.showAttentionDot && !!model.IsDemandingAttention

                    // Number of windows behind this icon: one for a plain
                    // window, the child count for a grouped application.
                    readonly property int windowCount: {
                        if (model.IsGroupParent) {
                            return Math.max(1, model.ChildCount);
                        }
                        if (model.IsWindow) {
                            return 1;
                        }
                        return 0;
                    }

                    // One indicator dot per window, capped at maxIndicatorDots.
                    readonly property int indicatorDotCount: Math.min(windowCount, root.maxIndicatorDots)

                    // Which visible dot represents the active window, so its
                    // dot can stretch into the focused line.
                    readonly property int focusedDotIndex: {
                        if (!focusedTask || indicatorDotCount === 0) {
                            return -1;
                        }
                        if (!model.IsGroupParent) {
                            return 0;
                        }
                        const childCount = tasksModel.rowCount(tasksModel.makeModelIndex(index));
                        for (let j = 0; j < childCount; ++j) {
                            if (tasksModel.data(tasksModel.makeModelIndex(index, j),
                                    TaskManager.AbstractTasksModel.IsActive)) {
                                return Math.min(j, indicatorDotCount - 1);
                            }
                        }
                        return 0;
                    }

                    // Lift the icon while it is being dragged for reordering.
                    z: reorderHandler.active ? 10 : 0
                    scale: reorderHandler.active ? 1.1 : 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }

                    // Icons slide aside to open a gap at the drop position
                    // while another icon is being dragged.
                    readonly property int slotStep: root.effectiveIconSize + root.iconSpacing + (root.vertical ? root.dotSpace : 0)
                    readonly property int shiftSteps: {
                        const src = root.reorderSourceRow;
                        const dst = root.reorderTargetRow;
                        if (src < 0 || dst < 0 || index === src) {
                            return 0;
                        }
                        if (src < dst && index > src && index <= dst) {
                            return -1;
                        }
                        if (src > dst && index >= dst && index < src) {
                            return 1;
                        }
                        return 0;
                    }

                    transform: [
                        Translate {
                            x: root.vertical ? 0 : taskDelegate.shiftSteps * taskDelegate.slotStep
                            y: root.vertical ? taskDelegate.shiftSteps * taskDelegate.slotStep : 0

                            Behavior on x {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on y {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }
                        },
                        Translate {
                            x: reorderHandler.active ? reorderHandler.activeTranslation.x : 0
                            y: reorderHandler.active ? reorderHandler.activeTranslation.y : 0
                        }
                    ]

                    mainText: model.display ?? ""

                    Kirigami.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.effectiveIconSize
                        height: root.effectiveIconSize
                        source: model.decoration
                        active: hoverHandler.hovered
                        scale: hoverHandler.hovered ? 1.06 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    // Indicator: one dot per window (up to maxIndicatorDots);
                    // the active window's dot stretches into a short line. The
                    // transitions between the states are animated.
                    Row {
                        id: indicator

                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: root.dotSize
                        spacing: root.dotGap
                        opacity: taskDelegate.runningTask ? 1 : 0
                        visible: opacity > 0

                        Repeater {
                            model: taskDelegate.indicatorDotCount

                            delegate: Rectangle {
                                readonly property bool focusedDot: taskDelegate.focusedTask
                                    && index === taskDelegate.focusedDotIndex

                                y: Math.round((indicator.height - height) / 2)
                                height: root.dotSize
                                radius: height / 2
                                width: focusedDot ? root.focusedIndicatorWidth : root.dotSize
                                color: (taskDelegate.attentionTask && !taskDelegate.focusedTask)
                                    ? "#f47629" : root.indicatorColor

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 160
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    // Subtle separator between the pinned launchers and the
                    // unpinned running applications.
                    Rectangle {
                        readonly property bool shown: root.showLauncherSeparator
                            && root.pinnedRowCount > 0
                            && root.pinnedRowCount < taskRepeater.count
                            && index === root.pinnedRowCount - 1

                        width: root.vertical ? Math.round(root.effectiveIconSize / 2) : 1
                        height: root.vertical ? 1 : Math.round(root.effectiveIconSize / 2)
                        radius: Math.max(width, height) / 2
                        color: Kirigami.Theme.textColor
                        opacity: shown ? 0.3 : 0
                        visible: opacity > 0

                        x: root.vertical
                            ? Math.round((parent.width - width) / 2)
                            : Math.round(parent.width + root.iconSpacing / 2 - width / 2)
                        y: root.vertical
                            ? Math.round(parent.height + root.iconSpacing / 2 - height / 2)
                            : Math.round((parent.height - height) / 2)

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Kirigami.Units.smallSpacing
                        color: hoverHandler.hovered
                            ? Qt.rgba(1, 1, 1, 0.12)
                            : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    HoverHandler {
                        id: hoverHandler
                    }

                    // Drag to reorder: the icon follows the pointer and the
                    // task moves when it is dropped over another icon.
                    DragHandler {
                        id: reorderHandler
                        acceptedButtons: Qt.LeftButton
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
                        target: null
                        grabPermissions: PointerHandler.CanTakeOverFromAnything

                        onTranslationChanged: {
                            if (active) {
                                const pos = reorderHandler.centroid.scenePosition;
                                root.reorderTargetRow = taskRow.reorderIndexAt(pos.x, pos.y);
                            }
                        }

                        onActiveChanged: {
                            if (active) {
                                root.reorderSourceRow = index;
                                root.reorderTargetRow = index;
                            } else {
                                taskRow.finishReorder(reorderHandler.centroid.scenePosition.x,
                                                      reorderHandler.centroid.scenePosition.y);
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton) {
                                root.closeTaskRow(index);
                            } else {
                                root.activateTaskRow(index);
                            }
                        }
                    }

                    // Open the menu on right-button press, like the stock task
                    // manager, so the panel does not eat the event.
                    TapHandler {
                        id: rightClickHandler
                        acceptedButtons: Qt.RightButton
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
                        gesturePolicy: TapHandler.WithinBounds
                        onPressedChanged: {
                            if (pressed) {
                                taskMenuTimer.start();
                            }
                        }
                    }

                    Timer {
                        id: taskMenuTimer
                        interval: 0
                        onTriggered: {
                            const menu = root.createTaskMenu(taskDelegate, tasksModel.makeModelIndex(index));
                            if (menu) {
                                menu.show();
                            }
                        }
                    }
                }
            }
        }
    }
}
