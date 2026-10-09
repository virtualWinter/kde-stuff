import QtQuick

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid

PlasmaExtras.Menu {
    id: menu

    required property string appId
    required property string appName

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

    onStatusChanged: {
        if (status === PlasmaExtras.Menu.Closed) {
            menu.destroy();
        }
    }

    function show() {
        openRelative();
    }

    PlasmaExtras.MenuItem {
        text: i18n("Pin to Task Manager")
        icon: "window-pin"
        enabled: menu.appId !== ""
        visible: !root.isPinnedToTaskManager(menu.appId)
        onClicked: root.pinToTaskManager(menu.appId)
    }

    PlasmaExtras.MenuItem {
        text: i18n("Remove from Task Manager")
        icon: "window-unpin"
        enabled: menu.appId !== ""
        visible: root.isPinnedToTaskManager(menu.appId)
        onClicked: root.unpinFromTaskManager(menu.appId)
    }
}
