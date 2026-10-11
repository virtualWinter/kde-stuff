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
 * The Sound module of the grid, driven by the plasma-pa QML plugin directly.
 * A small module is a mute toggle, wider ones add the volume slider, and a
 * large one stacks the current output below it.
 */
GridModule {
    id: sound

    property int sizeCode: 2

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
    readonly property string outputName: sink
        ? (currentPort ? currentPort.description : sink.description)
        : ""

    readonly property bool iconOnly: sizeCode === 1
    readonly property bool stacked: sizeCode === 3

    // The icon-sized module has no room for a mute button, so its surface is one.
    canActivate: sound.iconOnly
    onActivated: sound.toggleMute()

    function toggleMute() {
        if (sound.sink) {
            sound.sink.muted = !sound.muted;
        }
    }

    ColumnLayout {
        visible: sound.iconOnly

        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Layout.preferredWidth
            source: AudioIcon.forVolume(sound.percent, sound.muted, "audio-volume")
        }

        PlasmaComponents3.Label {
            Layout.alignment: Qt.AlignHCenter
            text: sound.percent + "%"
            opacity: 0.8
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    RowLayout {
        visible: !sound.iconOnly && !sound.stacked

        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.ToolButton {
            Layout.alignment: Qt.AlignVCenter

            enabled: !!sound.sink
            icon.name: sound.muted ? "audio-volume-muted" : "audio-volume-high"
            display: PlasmaComponents3.AbstractButton.IconOnly
            text: sound.muted ? i18n("Unmute") : i18n("Mute")
            onClicked: sound.toggleMute()

            PlasmaComponents3.ToolTip {
                text: parent.text
            }
        }

        PlasmaComponents3.Slider {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            enabled: sound.sink && sound.sink.volumeWritable !== false
            from: PulseAudio.MinimalVolume
            to: sound.sink && sound.sink.volume >= PulseAudio.NormalVolume * 1.01
                ? PulseAudio.MaximalVolume
                : PulseAudio.NormalVolume
            stepSize: PulseAudio.NormalVolume / 100
            value: sound.sink ? sound.sink.volume : 0
            onMoved: sound.sink.volume = value
        }

        PlasmaComponents3.Label {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
            horizontalAlignment: Text.AlignRight
            text: sound.percent + "%"
        }
    }

    ColumnLayout {
        visible: sound.stacked

        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Layout.preferredWidth
                source: AudioIcon.forVolume(sound.percent, sound.muted, "audio-volume")
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: i18n("Sound")
                elide: Text.ElideRight
                maximumLineCount: 1
                font.weight: Font.DemiBold
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.ToolButton {
                enabled: !!sound.sink
                icon.name: sound.muted ? "audio-volume-muted" : "audio-volume-high"
                display: PlasmaComponents3.AbstractButton.IconOnly
                text: sound.muted ? i18n("Unmute") : i18n("Mute")
                onClicked: sound.toggleMute()

                PlasmaComponents3.ToolTip {
                    text: parent.text
                }
            }

            PlasmaComponents3.Slider {
                Layout.fillWidth: true

                enabled: sound.sink && sound.sink.volumeWritable !== false
                from: PulseAudio.MinimalVolume
                to: sound.sink && sound.sink.volume >= PulseAudio.NormalVolume * 1.01
                    ? PulseAudio.MaximalVolume
                    : PulseAudio.NormalVolume
                stepSize: PulseAudio.NormalVolume / 100
                value: sound.sink ? sound.sink.volume : 0
                onMoved: sound.sink.volume = value
            }

            PlasmaComponents3.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                horizontalAlignment: Text.AlignRight
                text: sound.percent + "%"
            }
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: sound.outputName !== ""
            text: sound.outputName
            elide: Text.ElideRight
            maximumLineCount: 1
            opacity: 0.65
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
