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
 * Hosts a stock tray applet's full representation as an inline control. This
 * is used only for volume and brightness, whose controls work without opening
 * an independent popup. More complex applets remain action tiles instead.
 */
Rectangle {
    id: card

    required property var model
    required property int index

    property int controlHeight: Kirigami.Units.gridUnit * 6
    property string titleOverride: ""
    property Item control: null
    property Item originalParent: null

    readonly property Item applet: model.hasApplet ? model.applet : null
    readonly property string title: titleOverride !== "" ? titleOverride
        : (applet && applet.Plasmoid && applet.Plasmoid.title
            ? applet.Plasmoid.title
            : (model.displayText ?? ""))

    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight
    implicitHeight: content.implicitHeight + Kirigami.Units.smallSpacing * 2

    color: Qt.alpha(Kirigami.Theme.textColor, 0.06)
    radius: Kirigami.Units.gridUnit * 0.6
    clip: true

    function adopt(item) {
        if (!item || control === item) {
            return;
        }

        release();
        originalParent = item.parent;

        item.anchors.left = undefined;
        item.anchors.top = undefined;
        item.anchors.right = undefined;
        item.anchors.bottom = undefined;
        item.anchors.centerIn = undefined;
        item.anchors.fill = undefined;

        item.parent = controlHost;
        item.width = Qt.binding(() => controlHost.width);
        item.height = Qt.binding(() => controlHost.height);
        item.visible = true;
        control = item;
    }

    function preloadAndAdopt() {
        if (!applet) {
            return;
        }

        const item = applet.fullRepresentationItem;
        if (item) {
            adopt(item);
        }
    }

    function release() {
        if (!control) {
            return;
        }
        control.parent = originalParent;
        control = null;
        originalParent = null;
    }

    Component.onCompleted: {
        preloadAndAdopt();
    }

    Component.onDestruction: release()

    Connections {
        target: card.applet
        function onFullRepresentationItemChanged(item) {
            card.adopt(item);
        }
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: card.title
            elide: Text.ElideRight
            maximumLineCount: 1
            font.weight: Font.DemiBold
        }

        Item {
            id: controlHost

            Layout.fillWidth: true
            Layout.preferredHeight: card.controlHeight
        }
    }
}
