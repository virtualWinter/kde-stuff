/*
    SPDX-FileCopyrightText: 2026 vwinter

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.private.volume

/*
 * The Sound quick control: master volume, mute and an output picker listing
 * every sink and its ports. It talks to the audio daemon through the plasma-pa
 * QML plugin directly, so it stays a real control instead of the stock popup
 * embedded in a card.
 */
QuickSettingCard {
    id: audio

    property bool outputExpanded: false

    /* The stock volume applet, for the parts this card does not show, such as
     * the per-application streams. Tapping the header opens it. */
    property Item applet: null

    signal popupLaunched()

    function openApplet() {
        if (audio.applet && audio.applet.Plasmoid) {
            audio.applet.Plasmoid.activated();
            audio.popupLaunched();
        }
    }

    readonly property var sink: Server.defaultSink
    readonly property bool muted: sink ? sink.muted : false
    readonly property int percent: sink
        ? Math.round(sink.volume / PulseAudio.NormalVolume * 100)
        : 0
    readonly property var currentPort: {
        const s = sink;
        if (!s || !s.ports || s.ports.length < 2) {
            return null;
        }
        return s.ports[s.activePortIndex] ?? null;
    }
    readonly property string currentOutputName: sink
        ? (currentPort ? currentPort.description : sink.description)
        : ""
    readonly property var outputPorts: {
        const s = sink;
        if (!s || !s.ports || s.ports.length < 2) {
            return [];
        }
        return s.ports.map((port, i) => ({
            "portIndex": i,
            "portDescription": port.description ?? port.name ?? ""
        }));
    }

    SinkModel {
        id: sinkModel
    }

    RowLayout {
        id: headerRow

        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        TapHandler {
            enabled: audio.applet !== null
            onTapped: audio.openApplet()
        }

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Layout.preferredWidth
            source: AudioIcon.forVolume(audio.percent, audio.muted, "audio-volume")
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: i18n("Sound")
            elide: Text.ElideRight
            maximumLineCount: 1
            font.weight: Font.DemiBold
        }

        PlasmaComponents3.ToolButton {
            id: muteButton

            enabled: !!audio.sink
            icon.name: audio.muted ? "audio-volume-muted" : "audio-volume-high"
            display: PlasmaComponents3.AbstractButton.IconOnly
            text: audio.muted ? i18n("Unmute") : i18n("Mute")
            onClicked: audio.sink.muted = !audio.muted

            PlasmaComponents3.ToolTip {
                text: muteButton.text
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: !!audio.sink
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Slider {
            id: volumeSlider

            Layout.fillWidth: true
            enabled: audio.sink && audio.sink.volumeWritable !== false
            from: PulseAudio.MinimalVolume
            to: audio.sink && audio.sink.volume >= PulseAudio.NormalVolume * 1.01
                ? PulseAudio.MaximalVolume
                : PulseAudio.NormalVolume
            stepSize: PulseAudio.NormalVolume / 100
            value: audio.sink ? audio.sink.volume : 0
            onMoved: audio.sink.volume = value
        }

        PlasmaComponents3.Label {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
            horizontalAlignment: Text.AlignRight
            text: audio.percent + "%"
        }
    }

    PlasmaComponents3.Label {
        Layout.fillWidth: true
        visible: !audio.sink
        text: i18n("No audio output available")
        opacity: 0.65
    }

    /*
     * Output picker. The row always shows the active sink (and its active port
     * when there is more than one); tapping it expands the device list.
     */
    Rectangle {
        id: outputRow

        Layout.fillWidth: true
        implicitHeight: outputRowContent.implicitHeight + Kirigami.Units.smallSpacing * 2
        radius: Kirigami.Units.smallSpacing
        visible: !!audio.sink
        color: Qt.alpha(Kirigami.Theme.textColor, outputHover.hovered ? 0.10 : 0.05)

        Behavior on color {
            ColorAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            id: outputHover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: audio.outputExpanded = !audio.outputExpanded
        }

        RowLayout {
            id: outputRowContent

            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Layout.preferredWidth
                source: "audio-speakers"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: i18n("Output")
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    opacity: 0.65
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: audio.currentOutputName
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Layout.preferredWidth
                source: "arrow-down"
                opacity: 0.6
                rotation: audio.outputExpanded ? 180 : 0

                Behavior on rotation {
                    NumberAnimation {
                        duration: Kirigami.Units.longDuration
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.gridUnit
        // rowCount() has no notify signal, so it cannot guard this binding.
        visible: audio.outputExpanded
        spacing: 0

        Repeater {
            model: sinkModel

            delegate: Rectangle {
                id: sinkRow

                required property var model
                required property int index

                readonly property bool selected: !!audio.sink && model.Name === audio.sink.name

                Layout.fillWidth: true
                implicitHeight: sinkRowContent.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.alpha(Kirigami.Theme.textColor, sinkRowHover.hovered ? 0.10 : 0)

                HoverHandler {
                    id: sinkRowHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: sinkRow.model.PulseObject.default = true
                }

                RowLayout {
                    id: sinkRowContent

                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Layout.preferredWidth
                        source: sinkRow.model.PulseObject?.iconName || "audio-speakers"
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: sinkRow.model.Description
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        font.weight: sinkRow.selected ? Font.DemiBold : Font.Normal
                    }

                    Kirigami.Icon {
                        visible: sinkRow.selected
                        source: "checkmark"
                    }
                }
            }
        }

        /*
         * Ports of the active sink. They are flattened into plain rows: a Port
         * list cannot inject required properties into a delegate.
         */
        Repeater {
            model: audio.outputPorts

            delegate: Rectangle {
                id: portRow

                required property int portIndex
                required property string portDescription

                readonly property bool selected: !!audio.sink
                    && audio.sink.activePortIndex === portIndex

                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit
                implicitHeight: portRowContent.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.alpha(Kirigami.Theme.textColor, portRowHover.hovered ? 0.10 : 0)

                HoverHandler {
                    id: portRowHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: audio.sink.activePortIndex = portRow.portIndex
                }

                RowLayout {
                    id: portRowContent

                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Layout.preferredWidth
                        source: portRow.portDescription.toLowerCase().indexOf("headphone") >= 0
                            ? "audio-headphones"
                            : "audio-speakers"
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: portRow.portDescription
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        opacity: 0.8
                        font.weight: portRow.selected ? Font.DemiBold : Font.Normal
                    }

                    Kirigami.Icon {
                        visible: portRow.selected
                        source: "checkmark"
                    }
                }
            }
        }
    }
}
