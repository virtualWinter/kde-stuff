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
 * A grid module that opens a stock tray applet's popup. Only applets whose
 * real controls cannot be embedded use it (Wi-Fi, Bluetooth, Notifications):
 * the module is a launcher carrying the applet's own status text.
 */
GridModule {
    id: module

    property Item applet: null
    property string iconName: ""
    property string title: ""
    property string subtitle: ""

    /* Mirrors the size code GridCenter uses for placement. */
    property int sizeCode: 2

    readonly property bool iconOnly: sizeCode === 1

    signal popupLaunched()

    onActivated: {
        if (module.applet && module.applet.Plasmoid) {
            module.applet.Plasmoid.activated();
            module.popupLaunched();
        }
    }

    ColumnLayout {
        visible: module.iconOnly

        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.large
            Layout.preferredHeight: Layout.preferredWidth
            source: module.iconName
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: text !== ""
            text: module.title
            font: Kirigami.Theme.smallFont
            elide: Text.ElideRight
            maximumLineCount: 1
            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    RowLayout {
        visible: !module.iconOnly

        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            source: module.iconName
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: module.title
                elide: Text.ElideRight
                maximumLineCount: 1
                font.weight: Font.DemiBold
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: module.subtitle
                elide: Text.ElideRight
                maximumLineCount: 1
                opacity: 0.65
            }
        }
    }
}
