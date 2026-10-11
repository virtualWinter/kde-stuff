/*
    SPDX-FileCopyrightText: 2026 vwinter

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

/* A compact action tile for a stock tray applet popup. */
Rectangle {
    id: tile

    required property var model
    required property int index

    signal activated()

    readonly property Item applet: model.hasApplet ? model.applet : null
    readonly property string title: applet && applet.Plasmoid && applet.Plasmoid.title
        ? applet.Plasmoid.title
        : (model.displayText ?? "")
    readonly property string subtitle: applet ? (applet.toolTipMainText ?? "") : ""

    implicitHeight: Kirigami.Units.gridUnit * 4

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
