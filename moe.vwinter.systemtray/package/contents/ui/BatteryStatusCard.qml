/*
    SPDX-FileCopyrightText: 2026 vwinter

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Item {
    id: card

    required property var model
    required property int index

    readonly property Item applet: model.hasApplet ? model.applet : null
    readonly property string statusText: applet?.toolTipMainText ?? model.displayText ?? i18n("Battery")
    readonly property string detailText: {
        const lines = (applet?.toolTipSubText ?? "").split("\n");
        return lines.length > 0 ? lines[0].trim() : "";
    }

    Layout.fillWidth: true
    implicitHeight: Math.max(Kirigami.Units.gridUnit * 3,
                             row.implicitHeight + Kirigami.Units.smallSpacing * 2)

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: {
            if (card.applet?.Plasmoid) {
                card.applet.Plasmoid.activated();
                systemTrayState.expanded = false;
            }
        }
    }

    QuickSettingCard {
        anchors.fill: parent
        color: Qt.alpha(Kirigami.Theme.textColor, hover.hovered ? 0.12 : 0.06)
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing * 2
        anchors.rightMargin: Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Layout.preferredWidth
            source: card.model.iconName ?? "battery"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: card.statusText
                elide: Text.ElideRight
                maximumLineCount: 1
                font.weight: Font.DemiBold
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.detailText
                elide: Text.ElideRight
                maximumLineCount: 1
                opacity: 0.65
            }
        }
    }
}
