/*
    SPDX-FileCopyrightText: 2026 vwinter

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

/*
 * Shared container for every quick setting in the Control Center. It owns the
 * background, corner radius and padding so all cards use identical spacing.
 */
Rectangle {
    id: card

    default property alias contents: content.data

    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight

    implicitHeight: content.implicitHeight
        + content.anchors.topMargin + content.anchors.bottomMargin

    color: Qt.alpha(Kirigami.Theme.textColor, 0.055)
    radius: Kirigami.Units.gridUnit * 0.65
    Behavior on color {
        ColorAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        id: content

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Kirigami.Units.smallSpacing * 2
        }
        spacing: Kirigami.Units.smallSpacing
    }
}
