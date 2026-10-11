/*
    SPDX-FileCopyrightText: 2020 Konrad Materka <materka@gmail.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

// Holds the open/closed state of the Control Center.
QtObject {
    id: systemTrayState

    property bool expanded: false

    // Allow expanded changes only once the tray was activated at least once,
    // so Plasma startup does not open the popup.
    property bool acceptExpandedChange: false

    onExpandedChanged: {
        if (expanded) {
            Plasmoid.status = PlasmaCore.Types.RequiresAttentionStatus
        } else {
            Plasmoid.status = PlasmaCore.Types.PassiveStatus
        }
        acceptExpandedChange = false
        root.expanded = expanded
    }

    readonly property Connections plasmoidConnections: Connections {
        target: Plasmoid
        function onActivated() {
            systemTrayState.acceptExpandedChange = true
        }
    }

    readonly property Connections rootConnections: Connections {
        function onExpandedChanged() {
            if (systemTrayState.acceptExpandedChange) {
                systemTrayState.expanded = root.expanded
            } else {
                root.expanded = systemTrayState.expanded
            }
        }
    }
}
