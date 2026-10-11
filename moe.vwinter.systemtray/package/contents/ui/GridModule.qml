/*
    SPDX-FileCopyrightText: 2026 vwinter

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

/*
 * Shared container for the module grid. Its position and size are decided by
 * GridCenter, so this only owns the look: rounded background, hover feedback
 * and the tap signal.
 */
Rectangle {
    id: module

    default property alias contents: contentItem.data

    /*
     * Highlighted state, used by toggles such as Do Not Disturb. Active
     * modules keep the accent colour even when they are not hovered.
     */
    property bool active: false

    /* Modules that own their own controls (a slider, a mute button) leave the
     * surface itself inert. */
    property bool canActivate: true

    signal activated()

    color: active
        ? Qt.alpha(Kirigami.Theme.highlightColor, 0.35)
        : Qt.alpha(Kirigami.Theme.textColor, moduleHover.hovered ? 0.12 : 0.06)
    radius: Kirigami.Units.gridUnit * 0.9

    HoverHandler {
        id: moduleHover
        cursorShape: module.canActivate ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        enabled: module.canActivate
        onTapped: module.activated()
    }

    Item {
        id: contentItem

        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing * 2
    }
}
