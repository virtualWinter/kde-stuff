/*
    SPDX-FileCopyrightText: 2026 vwinter

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.components as PlasmaComponents3

/*
 * The Do Not Disturb module. It reads and writes the same settings the stock
 * notifications applet uses, so the daemon and that applet stay in sync.
 */
GridModule {
    id: dnd

    property int sizeCode: 2

    readonly property bool iconOnly: sizeCode === 1
    readonly property bool inhibited: NotificationManager.Server.inhibited
    readonly property int iconSize: iconOnly
        ? Kirigami.Units.iconSizes.medium
        : Kirigami.Units.iconSizes.large

    active: dnd.inhibited

    onActivated: dnd.toggle()

    NotificationManager.Settings {
        id: notificationSettings
    }

    function toggle() {
        const next = !dnd.inhibited;

        // Tell the daemon first so a notification arriving right now is
        // already covered, then persist the choice like the stock applet.
        NotificationManager.Server.inhibited = next;

        if (next) {
            const until = new Date();
            until.setFullYear(until.getFullYear() + 1);
            notificationSettings.notificationsInhibitedUntil = until;
        } else {
            notificationSettings.notificationsInhibitedUntil = undefined;
        }
        notificationSettings.save();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: dnd.iconOnly
        }

        Kirigami.Icon {
            Layout.alignment: dnd.iconOnly ? Qt.AlignHCenter : Qt.AlignVCenter
            Layout.preferredWidth: dnd.iconSize
            Layout.preferredHeight: dnd.iconSize
            source: dnd.inhibited ? "notifications-disabled" : "notifications"
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: !dnd.iconOnly
            text: i18n("Do Not Disturb")
            elide: Text.ElideRight
            maximumLineCount: 1
            font.weight: Font.DemiBold
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: !dnd.iconOnly
            text: dnd.inhibited ? i18n("On") : i18n("Off")
            elide: Text.ElideRight
            maximumLineCount: 1
            opacity: 0.65
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: dnd.iconOnly
        }
    }
}
