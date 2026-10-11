/*
    SPDX-FileCopyrightText: 2026 vwinter

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.plasmoid

/*
 * The notification list, docked below the quick settings. It renders the
 * org.kde.plasma.notifications applet's own full representation, so Do Not
 * Disturb and Clear All keep working. Hidden when that applet is not in the tray.
 */
Item {
    id: section

    readonly property string notificationsAppletId: "org.kde.plasma.notifications"
    readonly property int maximumHeight: Kirigami.Units.gridUnit * 12

    property Item applet: null
    property Item notificationList: null

    visible: notificationList !== null
    // With no notifications, the applet's list has an implicit height of
    // zero. Keep only the section heading instead of reserving an empty card.
    implicitHeight: visible
        ? heading.height + Math.min(notificationList.implicitHeight, maximumHeight)
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

    PlasmaExtras.Heading {
        id: heading

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            leftMargin: Kirigami.Units.smallSpacing
            rightMargin: Kirigami.Units.smallSpacing
        }
        level: 4
        text: i18n("Notifications")
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    Item {
        id: host
        anchors {
            top: heading.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
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
