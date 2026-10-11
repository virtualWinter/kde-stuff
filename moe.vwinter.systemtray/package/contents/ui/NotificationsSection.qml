/*
    SPDX-FileCopyrightText: 2026 vwinter

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.plasmoid

/*
 * The notification list, docked below the quick settings. It renders the
 * org.kde.plasma.notifications applet's own full representation, so Do Not
 * Disturb and Clear All keep working. When there is nothing to show, a compact
 * empty state keeps the footer present instead of leaving a visual gap.
 */
Item {
    id: section

    readonly property string notificationsAppletId: "org.kde.plasma.notifications"
    readonly property int maximumHeight: Kirigami.Units.gridUnit * 12
    readonly property int emptyHeight: Kirigami.Units.gridUnit * 3

    property Item applet: null
    property Item notificationList: null

    readonly property bool hasNotificationContent: notificationList
        && notificationList.implicitHeight > 0
    implicitHeight: (hasNotificationContent
        ? heading.height
        : emptyHeight) + (hasNotificationContent
        ? Math.min(notificationList.implicitHeight, maximumHeight)
        : 0)

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
        height: Kirigami.Units.gridUnit * 2
        text: i18n("Notifications")
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    Item {
        id: host
        visible: section.hasNotificationContent
        anchors {
            top: heading.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
    }

    PlasmaComponents3.Label {
        id: emptyState

        anchors {
            top: heading.bottom
            left: parent.left
            right: parent.right
            topMargin: Kirigami.Units.smallSpacing
            leftMargin: Kirigami.Units.smallSpacing
            rightMargin: Kirigami.Units.smallSpacing
        }
        visible: !section.hasNotificationContent
        text: i18n("No new notifications")
        height: Kirigami.Units.gridUnit
        horizontalAlignment: Text.AlignHCenter
        opacity: 0.65
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
