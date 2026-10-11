/*
    SPDX-FileCopyrightText: 2026 vwinter

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.plasmoid

/*
 * The notification list, docked below the quick settings. It renders the
 * org.kde.plasma.notifications applet's own full representation, so Do Not
 * Disturb and Clear All keep working. The section is hidden when its model is empty.
 */
Item {
    id: section

    readonly property string notificationsAppletId: "org.kde.plasma.notifications"
    property Item applet: null
    property Item notificationList: null

    readonly property bool hasNotificationContent: !!notificationList?.historyModel
        && notificationList.historyModel.count > 0
    implicitHeight: hasNotificationContent
        ? Math.min(notificationList.implicitHeight, Kirigami.Units.gridUnit * 12)
        : 0

    KItemModels.KSortFilterProxyModel {
        id: notificationsModel

        filterRoleName: "itemId"
        filterRowCallback: (sourceRow, sourceParent) => {
            return sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), filterRole)
                === section.notificationsAppletId;
        }
        // avoid unnecessary binding, it causes loops
        Component.onCompleted: sourceModel = Plasmoid.systemTrayModel
    }

    Instantiator {
        model: notificationsModel

        delegate: QtObject {
            required property QtObject applet
            required property bool hasApplet

            function sync() {
                section.applet = hasApplet && applet ? applet : null;
            }

            Component.onCompleted: sync();
            onAppletChanged: sync();
            onHasAppletChanged: sync();
        }
    }

    Item {
        id: host
        visible: section.hasNotificationContent
        anchors.fill: parent
    }

    function syncNotificationList() {
        const next = applet ? applet.fullRepresentationItem : null;

        if (notificationList && notificationList !== next) {
            notificationList.parent = null;
        }

        notificationList = next;

        if (notificationList) {
            notificationList.anchors.left = undefined;
            notificationList.anchors.top = undefined;
            notificationList.anchors.right = undefined;
            notificationList.anchors.bottom = undefined;
            notificationList.anchors.centerIn = undefined;
            notificationList.anchors.fill = undefined;
            notificationList.parent = host;
            notificationList.anchors.fill = host;
            notificationList.visible = true;
        }
    }

    onAppletChanged: syncNotificationList()

    Connections {
        target: section.applet

        // The notification applet creates its list asynchronously at startup.
        function onFullRepresentationItemChanged() {
            section.syncNotificationList();
        }
    }

    Component.onCompleted: {
        if (applet) {
            syncNotificationList();
        }
    }
}
