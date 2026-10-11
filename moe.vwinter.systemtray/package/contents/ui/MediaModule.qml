/*
    SPDX-FileCopyrightText: 2026 vwinter

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.private.mpris as Mpris

/*
 * The media module. It talks to whatever MPRIS player is currently active
 * through the same plugin the stock media applet uses. The content follows the
 * module size: transport only when small, art and track info when there is
 * room for them.
 */
GridModule {
    id: media

    property int sizeCode: 2

    readonly property bool iconOnly: sizeCode === 1
    readonly property bool stacked: sizeCode === 3

    readonly property var player: mpris.currentPlayer
    readonly property bool hasPlayer: player !== null
    readonly property int playbackStatus: hasPlayer ? player.playbackStatus : Mpris.PlaybackStatus.Stopped
    readonly property bool playing: playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property bool hasTrack: playbackStatus > Mpris.PlaybackStatus.Stopped
    readonly property string trackTitle: hasTrack ? (player.track ?? "") : ""
    readonly property string trackArtist: hasTrack ? (player.artist ?? "") : ""
    readonly property string artUrl: hasTrack ? (player.artUrl ?? "") : ""
    readonly property bool canGoNext: hasPlayer && player.canGoNext
    readonly property bool canGoPrevious: hasPlayer && player.canGoPrevious

    canActivate: false

    Mpris.Mpris2Model {
        id: mpris
    }

    component AlbumArt: Rectangle {
        id: artRoot

        color: Qt.alpha(Kirigami.Theme.textColor, 0.08)
        radius: Kirigami.Units.smallSpacing * 1.5
        clip: true

        Image {
            id: artImage

            anchors.fill: parent
            source: media.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
        }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.medium
            height: Kirigami.Units.iconSizes.medium
            source: "media-playback-start"
            visible: !artImage.visible
        }
    }

    component Transport: Row {
        id: transport

        /* A narrow module has room for play and next only. */
        property bool showPrevious: true

        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.ToolButton {
            visible: transport.showPrevious
            enabled: media.canGoPrevious
            icon.name: "media-skip-backward"
            display: PlasmaComponents3.AbstractButton.IconOnly
            text: i18n("Previous")
            onClicked: media.player.Previous()

            PlasmaComponents3.ToolTip {
                text: parent.text
            }
        }

        PlasmaComponents3.ToolButton {
            enabled: media.hasPlayer
            icon.name: media.playing ? "media-playback-pause" : "media-playback-start"
            display: PlasmaComponents3.AbstractButton.IconOnly
            text: media.playing ? i18n("Pause") : i18n("Play")
            onClicked: media.playing ? media.player.Pause() : media.player.Play()

            PlasmaComponents3.ToolTip {
                text: parent.text
            }
        }

        PlasmaComponents3.ToolButton {
            enabled: media.canGoNext
            icon.name: "media-skip-forward"
            display: PlasmaComponents3.AbstractButton.IconOnly
            text: i18n("Next")
            onClicked: media.player.Next()

            PlasmaComponents3.ToolTip {
                text: parent.text
            }
        }
    }

    component TrackInfo: ColumnLayout {
        spacing: 0

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: media.hasTrack ? media.trackTitle : i18n("No media playing")
            elide: Text.ElideRight
            maximumLineCount: 1
            font.weight: Font.DemiBold
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: text !== ""
            text: media.trackArtist
            elide: Text.ElideRight
            maximumLineCount: 1
            opacity: 0.65
        }
    }

    // Icon sized module: transport only.
    ColumnLayout {
        visible: media.iconOnly

        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Transport {
            Layout.alignment: Qt.AlignHCenter
            showPrevious: false
        }

        PlasmaComponents3.Label {
            Layout.alignment: Qt.AlignHCenter
            visible: media.hasTrack && media.trackTitle !== ""
            text: media.trackTitle
            elide: Text.ElideRight
            maximumLineCount: 1
            opacity: 0.8
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    // Wide module: track info above the transport row.
    ColumnLayout {
        visible: !media.iconOnly && !media.stacked

        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            AlbumArt {
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Layout.preferredWidth
            }

            TrackInfo {
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: media.trackArtist
                elide: Text.ElideRight
                maximumLineCount: 1
                opacity: 0.65
            }

            Transport {
                Layout.alignment: Qt.AlignVCenter
                showPrevious: false
            }
        }
    }

    // Large module: art above the track info and a full transport row.
    ColumnLayout {
        visible: media.stacked

        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        AlbumArt {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        TrackInfo {
            Layout.fillWidth: true
        }

        Transport {
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
