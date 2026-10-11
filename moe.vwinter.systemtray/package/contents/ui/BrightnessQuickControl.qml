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
 * The Brightness quick control. It drives the same ScreenBrightnessControl
 * backend as org.kde.plasma.brightness, without that applet's popup.
 */
QuickSettingCard {
    id: brightness

    ScreenBrightnessControl {
        id: screenBrightnessControl
        isSilent: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Layout.preferredWidth
            source: "video-display-brightness"
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: i18n("Brightness")
            elide: Text.ElideRight
            maximumLineCount: 1
            font.weight: Font.DemiBold
        }
    }

    Repeater {
        model: screenBrightnessControl.displays

        delegate: RowLayout {
            id: displayRow

            required property var model
            required property int index

            readonly property int percent: model.maxBrightness
                ? Math.round(100 * model.brightness / model.maxBrightness)
                : 0

            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Layout.preferredWidth
                source: "video-display-brightness"
                opacity: 0.8
            }

            PlasmaComponents3.Slider {
                Layout.fillWidth: true
                from: 0
                to: model.maxBrightness
                value: model.brightness
                stepSize: Math.max(1, model.maxBrightness / 100)
                enabled: model.maxBrightness > 0
                onMoved: screenBrightnessControl.setBrightness(model.displayName, value)
            }

            PlasmaComponents3.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                horizontalAlignment: Text.AlignRight
                text: model.maxBrightness ? displayRow.percent + "%" : ""
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
