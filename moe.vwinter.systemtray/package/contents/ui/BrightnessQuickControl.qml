/*
    SPDX-FileCopyrightText: 2026 vwinter

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.private.brightnesscontrolplugin

/*
 * A direct screen-brightness slider. It uses the same ScreenBrightnessControl
 * backend as org.kde.plasma.brightness but avoids its separate popup lifecycle.
 */
Rectangle {
    id: card

    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight
    implicitHeight: content.implicitHeight + Kirigami.Units.smallSpacing * 2

    color: Qt.alpha(Kirigami.Theme.textColor, 0.06)
    radius: Kirigami.Units.gridUnit * 0.6

    ScreenBrightnessControl {
        id: screenBrightnessControl
        isSilent: true
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: i18n("Brightness")
            font.weight: Font.DemiBold
        }

        Repeater {
            model: screenBrightnessControl.displays

            delegate: RowLayout {
                required property string displayName
                required property string label
                required property int brightness
                required property int maxBrightness

                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Layout.preferredWidth
                    source: "video-display-brightness"
                }

                PlasmaComponents3.Slider {
                    id: slider

                    Layout.fillWidth: true
                    from: 0
                    to: maxBrightness
                    value: brightness
                    stepSize: Math.max(1, maxBrightness / 100)
                    enabled: maxBrightness > 0
                    onMoved: screenBrightnessControl.setBrightness(displayName, value)
                }

                PlasmaComponents3.Label {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    horizontalAlignment: Text.AlignRight
                    text: maxBrightness ? Math.round(100 * brightness / maxBrightness) + "%" : ""
                }
            }
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: !screenBrightnessControl.isBrightnessAvailable
            text: i18n("No brightness control available")
            opacity: 0.65
        }
    }
}
