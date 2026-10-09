import QtQuick

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid

import org.kde.private.desktopcontainment.folder as Folder

import org.kde.taskmanager as TaskManager

PlasmaExtras.Menu {
    id: menu

    required property /*QModelIndex*/var modelIndex

    readonly property var atm: TaskManager.AbstractTasksModel

    // The user's Places (Home, Documents, Trash, drives, ...). Declared as a
    // property rather than a child: a Menu's default property only accepts
    // QMenuItem, so a bare child object would fail to load. This is the only
    // places model exposed to QML.
    readonly property Folder.PlacesModel placesModel: Folder.PlacesModel {
        showDesktopEntry: false
    }

    placement: {
        switch (Plasmoid.location) {
        case PlasmaCore.Types.LeftEdge:
            return PlasmaExtras.Menu.RightPosedTopAlignedPopup;
        case PlasmaCore.Types.TopEdge:
            return PlasmaExtras.Menu.BottomPosedLeftAlignedPopup;
        case PlasmaCore.Types.RightEdge:
            return PlasmaExtras.Menu.LeftPosedTopAlignedPopup;
        default:
            return PlasmaExtras.Menu.TopPosedLeftAlignedPopup;
        }
    }

    minimumWidth: visualParent ? (visualParent as Item).width : 0

    onStatusChanged: {
        if (status === PlasmaExtras.Menu.Closed) {
            menu.destroy();
        }
    }

    function get(modelProp) {
        return tasksModel.data(modelIndex, modelProp);
    }

    function show() {
        openRelative();
    }

    // Menu rows are compiled once instead of being built from QML strings at
    // runtime. The submenus below are populated from models, so they still
    // create their items on demand.
    //
    // These are declared as properties rather than plain children: a Menu's
    // default property is its list of QMenuItem, so a bare `Component { }`
    // child is a type error that makes the whole menu fail to load.
    property Component menuItemComponent: Component {
        PlasmaExtras.MenuItem {}
    }

    property Component separatorComponent: Component {
        PlasmaExtras.MenuItem {
            separator: true
        }
    }

    function newMenuItem(parent) {
        return menuItemComponent.createObject(parent);
    }

    function newSeparator(parent) {
        return separatorComponent.createObject(parent);
    }

    function foreachChildTask(callback, index) {
        const childCount = tasksModel.rowCount(index);
        if (childCount > 0) {
            for (let i = 0; i < childCount; ++i) {
                callback(tasksModel.index(i, 0, index));
            }
        } else {
            callback(index);
        }
    }

    // Builds the per-application sections (Recent Files and the app's own
    // jump list actions) that the stock task manager menu shows.
    function buildAppSections() {
        const info = root.appActionSections(menu.get(menu.atm.AppId));
        if (!info) {
            return;
        }

        const sections = [];
        if (info.recents.length > 0) {
            sections.push({ "title": i18n("Recent Files"), "group": "recents", "actions": info.recents });
        }
        if (info.actions.length > 0) {
            sections.push({ "title": i18n("Actions"), "group": "actions", "actions": info.actions });
        }

        sections.forEach(section => {
            // Like the stock menu: no "Actions" header when it is the only
            // section.
            if (section.group !== "actions" || sections.length > 1) {
                const header = menu.newMenuItem(menu);
                header.text = section.title;
                header.section = true;
                menu.addMenuItem(header, startNewInstanceItem);
            }

            for (let i = 0; i < section.actions.length; ++i) {
                const action = section.actions[i];
                const item = menu.newMenuItem(menu);
                item.text = String(action.text ?? "");
                item.icon = String(action.icon ?? "");
                item.clicked.connect(() => {
                    root.triggerAppAction(info.row, String(action.actionId ?? ""), action.actionArgument);
                });
                menu.addMenuItem(item, startNewInstanceItem);
            }
        });
    }

    // The stock task manager adds the user's Places for file managers (its
    // C++ backend checks the .desktop "FileManager" category). QML cannot
    // read an app's categories, so this is limited to Dolphin.
    function isDolphin() {
        let appId = String(menu.get(menu.atm.AppId) ?? "");
        if (appId.endsWith(".desktop")) {
            appId = appId.slice(0, appId.length - 8);
        }
        return appId === "org.kde.dolphin" || appId === "dolphin";
    }

    function placeIcon(url) {
        const s = String(url);
        if (s.startsWith("trash:")) {
            return "user-trash";
        }
        if (s.startsWith("remote:")) {
            return "network-workgroup";
        }
        if (s.startsWith("recentlyused:")) {
            return s.indexOf("/locations") >= 0 ? "folder-open-recent" : "document-open-recent";
        }
        if (s === "file:///") {
            return "drive-harddisk";
        }
        if (s.startsWith("file:")) {
            return "folder";
        }
        return "network-workgroup";
    }

    function buildPlaces() {
        if (!isDolphin()) {
            return;
        }

        const count = placesModel.rowCount();
        if (count <= 0) {
            return;
        }

        for (let i = 0; i < count; ++i) {
            const idx = placesModel.index(i, 0);
            const url = placesModel.urlForIndex(i);
            const item = menu.newMenuItem(menu);
            item.text = String(placesModel.data(idx, Qt.DisplayRole) ?? "");
            item.icon = placeIcon(url);
            item.clicked.connect((u => () => tasksModel.requestOpenUrls(menu.modelIndex, [u]))(url));
            menu.addMenuItem(item, startNewInstanceItem);
        }

        menu.addMenuItem(menu.newSeparator(menu), startNewInstanceItem);
    }

    Component.onCompleted: {
        buildPlaces();
        buildAppSections();
    }

    PlasmaExtras.MenuItem {
        id: startNewInstanceItem

        visible: menu.get(menu.atm.CanLaunchNewInstance)
        text: i18nc("action:inmenu", "Open New Window")
        icon: "window-new"

        onClicked: tasksModel.requestNewInstance(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        id: virtualDesktopsMenuItem

        visible: virtualDesktopInfo.numberOfDesktops > 1
            && !menu.get(menu.atm.IsLauncher)
            && !menu.get(menu.atm.IsStartup)
            && menu.get(menu.atm.IsVirtualDesktopsChangeable)

        enabled: visible
        text: i18nc("action:inmenu", "Move to &Desktop")
        icon: "virtual-desktops"

        readonly property Connections virtualDesktopsMenuConnections: Connections {
            target: virtualDesktopInfo

            function onNumberOfDesktopsChanged() {
                Qt.callLater(virtualDesktopsMenu.refresh);
            }
            function onDesktopIdsChanged() {
                Qt.callLater(virtualDesktopsMenu.refresh);
            }
            function onDesktopNamesChanged() {
                Qt.callLater(virtualDesktopsMenu.refresh);
            }
        }

        readonly property PlasmaExtras.Menu subMenu: PlasmaExtras.Menu {
            id: virtualDesktopsMenu

            visualParent: virtualDesktopsMenuItem.action

            function refresh() {
                clearMenuItems();

                if (virtualDesktopInfo.numberOfDesktops <= 1 || !virtualDesktopsMenuItem.enabled) {
                    return;
                }

                let menuItem = menu.newMenuItem(virtualDesktopsMenu);
                menuItem.text = i18nc("action:inmenu", "Move &To Current Desktop");
                menuItem.enabled = Qt.binding(() => {
                    if (!menu.visualParent) {
                        return false;
                    }

                    let isAnyTaskNotOnCurrentDesktop = false;
                    menu.foreachChildTask((childIndex) => {
                        const screenGeometry = tasksModel.data(childIndex, menu.atm.ScreenGeometry);
                        const currentDesktop = virtualDesktopInfo.currentDesktopByScreenGeometry(screenGeometry);
                        isAnyTaskNotOnCurrentDesktop = isAnyTaskNotOnCurrentDesktop
                            || tasksModel.data(childIndex, menu.atm.VirtualDesktops).indexOf(currentDesktop) === -1;
                    }, menu.modelIndex);

                    return isAnyTaskNotOnCurrentDesktop;
                });
                menuItem.clicked.connect(() => {
                    menu.foreachChildTask((childIndex) => {
                        tasksModel.requestVirtualDesktops(childIndex, [virtualDesktopInfo.currentDesktopByScreenGeometry(tasksModel.data(childIndex, menu.atm.ScreenGeometry))]);
                    }, menu.modelIndex);
                });

                menuItem = menu.newMenuItem(virtualDesktopsMenu);
                menuItem.text = i18nc("action:inmenu", "&All Desktops");
                menuItem.checkable = true;
                menuItem.checked = Qt.binding(() => {
                    return menu.visualParent && menu.get(menu.atm.IsOnAllVirtualDesktops);
                });
                menuItem.clicked.connect(() => {
                    tasksModel.requestVirtualDesktops(menu.modelIndex, []);
                });

                menu.newSeparator(virtualDesktopsMenu);

                for (let i = 0; i < virtualDesktopInfo.desktopNames.length; ++i) {
                    menuItem = menu.newMenuItem(virtualDesktopsMenu);
                    menuItem.text = virtualDesktopInfo.desktopNames[i];
                    menuItem.checkable = true;
                    menuItem.checked = Qt.binding((i => {
                        return () => menu.visualParent && menu.get(menu.atm.VirtualDesktops).indexOf(virtualDesktopInfo.desktopIds[i]) > -1;
                    })(i));
                    menuItem.clicked.connect((i => {
                        return () => tasksModel.requestVirtualDesktops(menu.modelIndex, [virtualDesktopInfo.desktopIds[i]]);
                    })(i));
                }

                menu.newSeparator(virtualDesktopsMenu);

                menuItem = menu.newMenuItem(virtualDesktopsMenu);
                menuItem.text = i18nc("action:inmenu", "&New Desktop");
                menuItem.icon = "list-add";
                menuItem.clicked.connect(() => {
                    tasksModel.requestNewVirtualDesktop(menu.modelIndex);
                });
            }

            Component.onCompleted: refresh()
        }
    }

    PlasmaExtras.MenuItem {
        id: activitiesMenuItem

        visible: activityInfo.numberOfRunningActivities > 1
            && !menu.get(menu.atm.IsLauncher)
            && !menu.get(menu.atm.IsStartup)

        enabled: visible
        text: i18nc("action:inmenu", "Show in &Activities")
        icon: "activities"

        readonly property Connections activitiesConnections: Connections {
            target: activityInfo

            function onNumberOfRunningActivitiesChanged() {
                Qt.callLater(activitiesMenu.refresh);
            }
        }

        readonly property PlasmaExtras.Menu subMenu: PlasmaExtras.Menu {
            id: activitiesMenu

            visualParent: activitiesMenuItem.action

            function refresh() {
                clearMenuItems();

                if (activityInfo.numberOfRunningActivities <= 1) {
                    return;
                }

                let menuItem = menu.newMenuItem(activitiesMenu);
                menuItem.text = i18nc("action:inmenu", "Add To Current Activity");
                menuItem.enabled = Qt.binding(() => {
                    return menu.visualParent && menu.get(menu.atm.Activities).length > 0
                        && menu.get(menu.atm.Activities).indexOf(activityInfo.currentActivity) < 0;
                });
                menuItem.clicked.connect(() => {
                    tasksModel.requestActivities(menu.modelIndex, menu.get(menu.atm.Activities).concat(activityInfo.currentActivity));
                });

                menuItem = menu.newMenuItem(activitiesMenu);
                menuItem.text = i18nc("action:inmenu", "All Activities");
                menuItem.checkable = true;
                menuItem.checked = Qt.binding(() => {
                    return menu.visualParent && menu.get(menu.atm.Activities).length === 0;
                });
                menuItem.toggled.connect(checked => {
                    let newActivities = [];
                    if (!checked) {
                        newActivities = [activityInfo.currentActivity];
                    }
                    tasksModel.requestActivities(menu.modelIndex, newActivities);
                });

                menu.newSeparator(activitiesMenu);

                const runningActivities = activityInfo.runningActivities();
                for (let i = 0; i < runningActivities.length; ++i) {
                    const activityId = runningActivities[i];

                    menuItem = menu.newMenuItem(activitiesMenu);
                    menuItem.text = activityInfo.activityName(runningActivities[i]);
                    menuItem.icon = activityInfo.activityIcon(runningActivities[i]);
                    menuItem.checkable = true;
                    menuItem.checked = Qt.binding((activityId => {
                        return () => menu.visualParent && menu.get(menu.atm.Activities).indexOf(activityId) >= 0;
                    })(activityId));
                    menuItem.toggled.connect((activityId => {
                        return checked => {
                            let newActivities = menu.get(menu.atm.Activities);
                            if (checked) {
                                newActivities = newActivities.concat(activityId);
                            } else {
                                const index = newActivities.indexOf(activityId);
                                if (index < 0) {
                                    return;
                                }
                                newActivities.splice(index, 1);
                            }
                            return tasksModel.requestActivities(menu.modelIndex, newActivities);
                        };
                    })(activityId));
                }

                menu.newSeparator(activitiesMenu);

                for (let i = 0; i < runningActivities.length; ++i) {
                    const activityId = runningActivities[i];
                    const onActivities = menu.get(menu.atm.Activities);

                    if (onActivities.length === 1 && onActivities[0] === activityId) {
                        continue;
                    }

                    menuItem = menu.newMenuItem(activitiesMenu);
                    menuItem.text = i18nc("action:inmenu", "Move to %1", activityInfo.activityName(activityId));
                    menuItem.icon = activityInfo.activityIcon(activityId);
                    menuItem.clicked.connect((activityId => {
                        return () => tasksModel.requestActivities(menu.modelIndex, [activityId]);
                    })(activityId));
                }

                menu.newSeparator(activitiesMenu);
            }

            Component.onCompleted: refresh()
        }
    }

    PlasmaExtras.MenuItem {
        id: launcherToggleAction

        visible: menu.visualParent
            && !menu.get(menu.atm.IsLauncher)
            && !menu.get(menu.atm.IsStartup)
            && Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
            && (activityInfo.numberOfRunningActivities < 2)
            && !doesBelongToCurrentActivity()

        enabled: menu.visualParent && menu.get(menu.atm.LauncherUrlWithoutIcon).toString() !== ""
        text: i18nc("action:inmenu", "&Pin to Task Manager")
        icon: "window-pin"

        function doesBelongToCurrentActivity() {
            return tasksModel.launcherActivities(menu.get(menu.atm.LauncherUrlWithoutIcon))
                .some(activity => activity === activityInfo.currentActivity || activity === activityInfo.nullUuid);
        }

        onClicked: {
            tasksModel.requestAddLauncher(menu.get(menu.atm.LauncherUrl));
        }
    }

    PlasmaExtras.MenuItem {
        id: showLauncherInActivitiesItem

        text: i18nc("action:inmenu", "&Pin to Task Manager")
        icon: "window-pin"

        visible: menu.visualParent
            && !menu.get(menu.atm.IsStartup)
            && Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
            && (activityInfo.numberOfRunningActivities >= 2)

        readonly property PlasmaExtras.Menu subMenu: PlasmaExtras.Menu {
            id: activitiesLaunchersMenu

            visualParent: showLauncherInActivitiesItem.action

            function refresh() {
                clearMenuItems();

                if (menu.visualParent === null) {
                    return;
                }

                const createNewItem = (id, title, iconName, url, activities) => {
                    const result = menu.newMenuItem(activitiesLaunchersMenu);
                    result.text = title;
                    result.icon = iconName;
                    result.visible = true;
                    result.checkable = true;
                    result.checked = activities.some(activity => activity === id);
                    result.clicked.connect(() => {
                        if (result.checked) {
                            tasksModel.requestAddLauncherToActivity(url, id);
                        } else {
                            tasksModel.requestRemoveLauncherFromActivity(url, id);
                        }
                    });
                    return result;
                };

                const url = menu.get(menu.atm.LauncherUrlWithoutIcon);
                const activities = tasksModel.launcherActivities(url);

                createNewItem(activityInfo.nullUuid, i18nc("action:inmenu", "On All Activities"), "", url, activities);

                if (activityInfo.numberOfRunningActivities <= 1) {
                    return;
                }

                createNewItem(activityInfo.currentActivity, i18nc("action:inmenu", "On The Current Activity"), activityInfo.activityIcon(activityInfo.currentActivity), url, activities);

                menu.newSeparator(activitiesLaunchersMenu);

                activityInfo.runningActivities().forEach(id => {
                    createNewItem(id, activityInfo.activityName(id), activityInfo.activityIcon(id), url, activities);
                });
            }

            Component.onCompleted: {
                menu.visualParentChanged.connect(refresh);
                refresh();
            }
        }
    }

    PlasmaExtras.MenuItem {
        visible: menu.visualParent
            && menu.get(menu.atm.IsStartup) !== true
            && Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
            && !launcherToggleAction.visible
            && !showLauncherInActivitiesItem.visible
            && (activityInfo.numberOfRunningActivities < 2)

        text: i18nc("action:inmenu", "Unpin from Task Manager")
        icon: "window-unpin"

        onClicked: {
            tasksModel.requestRemoveLauncher(menu.get(menu.atm.LauncherUrlWithoutIcon));
        }
    }

    PlasmaExtras.MenuItem {
        id: moreActionsMenuItem

        visible: menu.visualParent
            && !menu.get(menu.atm.IsLauncher)
            && !menu.get(menu.atm.IsStartup)

        enabled: visible
        text: i18nc("item:inmenu opens submenu", "More")
        icon: "view-more-symbolic"

        readonly property PlasmaExtras.Menu subMenu: PlasmaExtras.Menu {
            visualParent: moreActionsMenuItem.action

            PlasmaExtras.MenuItem {
                enabled: menu.visualParent && menu.get(menu.atm.IsMovable)
                text: i18nc("action:inmenu", "&Move")
                icon: "transform-move"
                onClicked: tasksModel.requestMove(menu.modelIndex)
            }

            PlasmaExtras.MenuItem {
                enabled: menu.visualParent && menu.get(menu.atm.IsResizable)
                text: i18nc("action:inmenu", "Re&size")
                icon: "transform-scale"
                onClicked: tasksModel.requestResize(menu.modelIndex)
            }

            PlasmaExtras.MenuItem {
                enabled: menu.visualParent && menu.get(menu.atm.IsMaximizable)
                checkable: true
                checked: menu.visualParent && menu.get(menu.atm.IsMaximized)
                text: i18nc("action:inmenu", "Ma&ximize")
                icon: "window-maximize"
                onClicked: tasksModel.requestToggleMaximized(menu.modelIndex)
            }

            PlasmaExtras.MenuItem {
                enabled: menu.visualParent && menu.get(menu.atm.IsMinimizable)
                checkable: true
                checked: menu.visualParent && menu.get(menu.atm.IsMinimized)
                text: i18nc("action:inmenu", "Mi&nimize")
                icon: "window-minimize"
                onClicked: tasksModel.requestToggleMinimized(menu.modelIndex)
            }

            PlasmaExtras.MenuItem {
                checkable: true
                checked: menu.visualParent && menu.get(menu.atm.IsKeepAbove)
                text: i18nc("action:inmenu", "Keep &Above Others")
                icon: "window-keep-above"
                onClicked: tasksModel.requestToggleKeepAbove(menu.modelIndex)
            }

            PlasmaExtras.MenuItem {
                checkable: true
                checked: menu.visualParent && menu.get(menu.atm.IsKeepBelow)
                text: i18nc("action:inmenu", "Keep &Below Others")
                icon: "window-keep-below"
                onClicked: tasksModel.requestToggleKeepBelow(menu.modelIndex)
            }

            PlasmaExtras.MenuItem {
                enabled: menu.visualParent && menu.get(menu.atm.IsFullScreenable)
                checkable: true
                checked: menu.visualParent && menu.get(menu.atm.IsFullScreen)
                text: i18nc("action:inmenu", "&Fullscreen")
                icon: "view-fullscreen"
                onClicked: tasksModel.requestToggleFullScreen(menu.modelIndex)
            }

            PlasmaExtras.MenuItem {
                enabled: menu.visualParent && menu.get(menu.atm.CanSetNoBorder)
                checkable: true
                checked: menu.visualParent && menu.get(menu.atm.HasNoBorder)
                text: i18nc("@action:inmenu", "&No Titlebar and Frame")
                icon: "edit-none-border"
                onClicked: tasksModel.requestToggleNoBorder(menu.modelIndex)
            }

            PlasmaExtras.MenuItem {
                enabled: menu.visualParent
                checkable: true
                checked: menu.visualParent && menu.get(menu.atm.IsExcludedFromCapture)
                visible: Qt.platform.pluginName === "wayland"
                text: i18nc("@action:inmenu", "&Hide from Screencast")
                icon: "view-private"
                onClicked: tasksModel.requestToggleExcludeFromCapture(menu.modelIndex)
            }

            PlasmaExtras.MenuItem { separator: true }

            PlasmaExtras.MenuItem {
                visible: (Plasmoid.configuration.groupingStrategy !== 0) && menu.get(menu.atm.IsWindow)
                checkable: true
                checked: menu.visualParent && menu.get(menu.atm.IsGroupable)
                text: i18nc("@option:check inmenu", "Allow this program to be grouped")
                icon: "view-group"
                onClicked: tasksModel.requestToggleGrouping(menu.modelIndex)
            }
        }
    }

    PlasmaExtras.MenuItem { separator: true }

    PlasmaExtras.MenuItem {
        property PlasmaCore.Action configureAction: null

        enabled: configureAction && configureAction.enabled
        visible: configureAction && configureAction.visible
        text: configureAction ? configureAction.text : ""
        icon: configureAction ? configureAction.icon : ""

        onClicked: configureAction.trigger()

        Component.onCompleted: configureAction = Plasmoid.internalAction("configure")
    }

    PlasmaExtras.MenuItem {
        property PlasmaCore.Action editModeAction: null

        enabled: editModeAction && editModeAction.enabled
        visible: editModeAction && editModeAction.visible
        text: editModeAction ? editModeAction.text : ""
        icon: editModeAction ? editModeAction.icon : ""

        onClicked: editModeAction.trigger()

        Component.onCompleted: editModeAction = Plasmoid.containment.internalAction("configure")
    }

    PlasmaExtras.MenuItem { separator: true }

    PlasmaExtras.MenuItem {
        id: closeWindowItem

        visible: menu.visualParent
            && !menu.get(menu.atm.IsLauncher)
            && !menu.get(menu.atm.IsStartup)

        enabled: menu.visualParent && menu.get(menu.atm.IsClosable)
        text: menu.get(menu.atm.IsGroupParent) ? i18nc("@action:inmenu", "&Close All") : i18nc("@action:inmenu", "&Close")
        icon: "window-close"

        onClicked: tasksModel.requestClose(menu.modelIndex)
    }
}
