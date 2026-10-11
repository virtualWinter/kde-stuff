/*
    SPDX-FileCopyrightText: 2026 vwinter

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

/*
 * One quick setting in the Control Center. Tapping it activates the applet,
 * which opens that applet's own popup, exactly like clicking it in the panel.
 */
Rectangle {
    id: tile

    required property var model
    required property int index

    signal activated()
    property bool spanFullRow: false

    readonly property Item applet: model.hasApplet ? model.applet : null
    // Printers is the only trailing item in the default tray order. Give it a
    // full final row rather than leaving an empty second column beside it.
    readonly property bool fullRow: spanFullRow || model.itemId === "org.kde.plasma.printmanager"
    readonly property string title: applet && applet.Plasmoid && applet.Plasmoid.title
        ? applet.Plasmoid.title
        : (model.displayText ?? "")
    readonly property string subtitle: applet ? (applet.toolTipMainText ?? "") : ""

    implicitHeight: Kirigami.Units.gridUnit * 4
    width: parent
        ? (fullRow ? parent.width : (parent.width - parent.spacing) / 2)
        : 0

    color: Qt.alpha(Kirigami.Theme.textColor, hoverHandler.hovered ? 0.12 : 0.06)
    radius: Kirigami.Units.gridUnit * 0.6

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: {
            if (tile.applet && tile.applet.Plasmoid) {
                tile.applet.Plasmoid.activated();
                tile.activated();
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Layout.preferredWidth
            source: model.iconName ?? ""
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: tile.title
                elide: Text.ElideRight
                maximumLineCount: 1
                font.weight: Font.DemiBold
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: tile.subtitle
                elide: Text.ElideRight
                maximumLineCount: 1
                opacity: 0.7
            }
        }
    }
}
