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
 * A compact action tile. Tapping it opens the stock applet's own popup, which
 * is the only reliable way to drive complex applets such as the network and
 * bluetooth ones. The model roles are read through a plain root object: the
 * delegate model only initializes required properties declared there.
 */
Item {
    id: tile

    required property var model
    required property int index

    signal activated()

    readonly property Item applet: model.hasApplet ? model.applet : null
    readonly property string title: applet && applet.Plasmoid && applet.Plasmoid.title
        ? applet.Plasmoid.title
        : (model.displayText ?? "")
    readonly property string subtitle: {
        // The applet tooltip repeats the title when it has nothing to add.
        const lines = (applet?.toolTipSubText ?? "").split("\n");
        const first = lines[0].trim();
        return first === "" || first === title ? "" : first;
    }

    Layout.fillWidth: true
    implicitHeight: Math.max(Kirigami.Units.gridUnit * 4,
                             rowContent.implicitHeight + Kirigami.Units.smallSpacing * 4)

    HoverHandler {
        id: tileHover
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

    QuickSettingCard {
        id: card

        anchors.fill: parent
        color: Qt.alpha(Kirigami.Theme.textColor, tileHover.hovered ? 0.12 : 0.06)
    }

    RowLayout {
        id: rowContent

        anchors.fill: card
        anchors.margins: Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Layout.preferredWidth
            source: tile.model.iconName ?? ""
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
                opacity: 0.65
            }
        }
    }
}
