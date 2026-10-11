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
 * An expandable quick-setting tile. The stock applet owns network scanning,
 * passwords, pairing and connection actions, so the expanded action opens its
 * own selector. The model roles are read through a plain root object: the
 * delegate model only initializes required properties declared there.
 */
Item {
    id: tile

    required property var model
    required property int index

    signal activated()

    property bool expanded: false

    readonly property Item applet: model.hasApplet ? model.applet : null
    readonly property string itemId: model.itemId ?? ""
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
                             content.implicitHeight + Kirigami.Units.smallSpacing * 4)

    HoverHandler {
        id: tileHover
        cursorShape: Qt.PointingHandCursor
    }

    QuickSettingCard {
        id: card

        anchors.fill: parent
        color: Qt.alpha(Kirigami.Theme.textColor, tileHover.hovered ? 0.12 : 0.06)
    }

    ColumnLayout {
        id: content

        anchors.fill: card
        anchors.margins: Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            id: rowContent

            Layout.fillWidth: true

            TapHandler {
                onTapped: tile.expanded = !tile.expanded
            }

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

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Layout.preferredWidth
                source: tile.expanded ? "go-up" : "go-down"
                opacity: 0.65
            }
        }

        PlasmaComponents3.Button {
            Layout.fillWidth: true
            visible: tile.expanded
            text: tile.itemId === "org.kde.plasma.networkmanagement"
                ? i18n("Choose a network…")
                : i18n("Choose a device…")
            icon.name: "go-next"
            onClicked: {
                if (tile.applet?.Plasmoid) {
                    tile.applet.Plasmoid.activated();
                    tile.activated();
                }
            }
        }
    }
}
