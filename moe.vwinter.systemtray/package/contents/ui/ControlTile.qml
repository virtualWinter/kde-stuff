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
 * A connectivity quick-setting tile. The model roles are read through a plain
 * root object: the delegate model only initializes required properties there.
 */
Item {
    id: tile

    required property string itemId
    required property string displayText
    required property bool hasApplet
    required property var applet
    required property string iconName

    signal requested(string itemId)
    signal refreshRequested()

    property bool expanded: false
    property Component expandedContent: null

    readonly property string title: applet && applet.Plasmoid && applet.Plasmoid.title
        ? applet.Plasmoid.title
        : displayText
    readonly property string subtitle: {
        // The applet tooltip repeats the title when it has nothing to add.
        const lines = (applet?.toolTipSubText ?? "").split("\n");
        const first = lines[0].trim();
        return first === "" || first === title ? "" : first;
    }

    readonly property real compactHeight: Kirigami.Units.gridUnit * 4.5
    readonly property real expandedHeight: Kirigami.Units.gridUnit * 15

    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight
    implicitHeight: compactHeight + (expanded ? expandedHeight : 0)

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutCubic
        }
    }

    TapHandler {
        enabled: !tile.expanded
        onTapped: tile.requested(tile.itemId)
    }

    HoverHandler {
        id: tileHover
        cursorShape: Qt.PointingHandCursor
    }

    QuickSettingCard {
        id: card

        anchors.fill: parent
        color: Qt.alpha(Kirigami.Theme.textColor, tileHover.hovered ? 0.12 : 0.06)
        radius: Kirigami.Units.gridUnit * 0.65

        Behavior on color {
            ColorAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.OutCubic
            }
        }
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
                enabled: tile.expanded
                onTapped: tile.requested(tile.itemId)
            }

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Layout.preferredWidth
                source: tile.iconName
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

            PlasmaComponents3.ToolButton {
                visible: tile.itemId === "org.kde.plasma.networkmanagement" && tile.expanded
                icon.name: "view-refresh"
                text: i18n("Refresh networks")
                display: PlasmaComponents3.AbstractButton.IconOnly
                onClicked: tile.refreshRequested()

                PlasmaComponents3.ToolTip {
                    text: parent.text
                }
            }

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Layout.preferredWidth
                source: tile.expanded ? "go-down" : "go-next"
                opacity: 0.65
                x: tileHover.hovered ? Kirigami.Units.smallSpacing / 3 : 0

                Behavior on x {
                    NumberAnimation {
                        duration: Kirigami.Units.shortDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.preferredHeight: tile.expanded ? tile.expandedHeight : 0
            visible: tile.expanded
            active: tile.expanded
            sourceComponent: tile.expandedContent
            clip: true
            asynchronous: false
            opacity: visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Kirigami.Units.shortDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
