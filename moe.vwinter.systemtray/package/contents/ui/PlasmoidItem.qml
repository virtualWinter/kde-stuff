/*
    SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2022 ivan tkachenko <me@ratijas.tk>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami as Kirigami

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid

AbstractItem {
    id: plasmoidContainer

    property Item applet: model?.applet ?? null
    text: applet?.Plasmoid.title ?? ""

    itemId: applet?.Plasmoid.pluginName ?? ""
    mainText: applet && (inVisibleLayout || (applet.toolTipMainText && applet.toolTipMainText != text)) ? applet.toolTipMainText : ""
    subText: applet?.toolTipSubText ?? ""
    mainItem: applet?.toolTipItem ?? null
    textFormat: applet?.toolTipTextFormat ?? 0 /* Text.AutoText, the default value */
    active: inVisibleLayout || (systemTrayState.activeApplet !== applet && (text != mainText || subText.length > 0))

    /*
     * The tray applets the control center has a module for. They are sorted to
     * the front of the tray by the tray model, so that they form one group,
     * and each of them draws its piece of the underline of that group.
     */
    readonly property bool onControlCenterGroup: inVisibleLayout && [
        "org.kde.plasma.networkmanagement",
        "org.kde.plasma.bluetooth",
        "org.kde.plasma.volume",
        "org.kde.plasma.brightness",
        "org.kde.plasma.notifications"
    ].includes(itemId)

    /*
     * Those same icons open the control center instead of the applet's popup.
     * The applets it does not cover (clipboard, weather, battery and friends)
     * keep theirs, and items sitting in the hidden area keep theirs as well,
     * since the control center cannot replace an applet that is not
     * represented in it.
     */
    readonly property bool opensControlCenter: onControlCenterGroup
        && Plasmoid.configuration.trayClickOpensControlCenter

    // The tray, not the embedded applet, owns the clicks on those icons.
    interceptInput: opensControlCenter

    /*
     * One continuous bar under the whole group: every icon of the group spans
     * its entire cell with the bar, so neighbouring bars join. It is only drawn
     * while the control center is open, so the group is unmarked at rest.
     */
    Rectangle {
        id: controlCenterBar

        readonly property int thickness: Math.max(2, Math.round(Kirigami.Units.gridUnit / 6))

        visible: opacity > 0
        opacity: plasmoidContainer.onControlCenterGroup && systemTrayState.expanded ? 1 : 0

        color: systemTrayState.expanded
            ? Kirigami.Theme.highlightColor
            : Qt.alpha(Kirigami.Theme.highlightColor, 0.4)
        // Each delegate draws one segment; square ends make adjacent segments
        // meet without antialiased gaps.
        radius: 0

        // A vertical panel underlines on the side the icons emerge from.
        x: root.vertical ? parent.width - thickness : 0
        y: root.vertical ? 0 : parent.height - thickness
        width: root.vertical ? thickness : parent.width
        height: root.vertical ? parent.height : thickness

        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: Kirigami.Units.shortDuration
            }
        }
    }

    // FIXME: Use an input type agnostic way to activate whatever the primary
    // action of a plasmoid is supposed to be, even if it's just expanding the
    // Plasmoid. Not all plasmoids are supposed to expand and not all plasmoids
    // do anything with onActivated.
    onActivated: pos => {
        if (plasmoidContainer.opensControlCenter) {
            systemTrayState.expanded = !systemTrayState.expanded;
        } else if (applet) {
            applet.Plasmoid.activated()
        }
    }

    onClicked: mouse => {
        if (!applet) {
            return
        }
        if (mouse.button === Qt.LeftButton && plasmoidContainer.opensControlCenter) {
            systemTrayState.expanded = !systemTrayState.expanded;
            return
        }
        //forward click event to the applet
        const appletItem = applet.compactRepresentationItem ?? applet.fullRepresentationItem
        const mouseArea = findMouseArea(appletItem)

        if (mouseArea && mouse.button !== Qt.RightButton) {
            mouseArea.clicked(mouse)
        } else if (mouse.button === Qt.LeftButton) {//fallback
            activated(null)
        }
    }
    onPressed: mouse => {
        // Only Plasmoids can show context menu on the mouse pressed event.
        // SNI has few problems, for example legacy applications that still use XEmbed require mouse to be released.
        if (mouse.button === Qt.RightButton) {
            contextMenu(mouse);
        } else if (mouse.button === Qt.LeftButton && plasmoidContainer.opensControlCenter) {
            // The control center takes this click, so there is no applet
            // interaction to forward the press to.
        } else {
            const appletItem = applet.compactRepresentationItem ?? applet.fullRepresentationItem
            const mouseArea = findMouseArea(appletItem)
            if (mouseArea) {
                // The correct way here would be to invoke the "pressed"
                // signal; however, mouseArea.pressed signal is overridden
                // by its bool value, and our only option is to call the
                // handler directly.
                mouseArea.onPressed(mouse)
            }
        }
    }
    onContextMenu: mouse => {
        if (applet) {
            effectivePressed = false;
            Plasmoid.showPlasmoidMenu(applet, 0, inHiddenLayout ? applet.height : 0);
        }
    }
    onWheel: wheel => {
        if (!applet) {
            return
        }
        //forward wheel event to the applet
        const appletItem = applet.compactRepresentationItem ?? applet.fullRepresentationItem
        const mouseArea = findMouseArea(appletItem)
        if (mouseArea) {
            mouseArea.wheel(wheel)
        }
    }

    function __isSuitableMouseArea(child: Item): bool {
        const item = child.parent;
        return child instanceof MouseArea
            && child.enabled
            // check if MouseArea covers the entire item
            && (child.anchors.fill === item
                || (child.x === 0
                    && child.y === 0
                    && child.width === item.width
                    && child.height === item.height));
    }

    //some heuristics to find MouseArea
    function findMouseArea(item: Item): MouseArea {
        if (!item) {
            return null
        }

        if (item instanceof MouseArea) {
            return item as MouseArea
        }

        return item.children.find(__isSuitableMouseArea) ?? null;
    }

    onAppletChanged: {
        if (applet) {
            applet.parent = iconContainer
            applet.anchors.fill = applet.parent
            applet.visible = true
        }
    }

    Connections {
        enabled: plasmoidContainer.applet !== null
        target: plasmoidContainer.findMouseArea(
            plasmoidContainer.applet?.compactRepresentationItem ??
            plasmoidContainer.applet?.fullRepresentationItem ??
            plasmoidContainer.applet
        )

        function onContainsPressChanged() {
            plasmoidContainer.effectivePressed = (target as MouseArea).containsPress;
        }

        // TODO For touch/stylus only, since the feature is not desired for mouse users
        function onPressAndHold(mouse) {
            if (mouse.button === Qt.LeftButton) {
                plasmoidContainer.contextMenu(mouse)
            }
        }
    }

    Connections {
        target: plasmoidContainer.applet?.Plasmoid ?? null

        //activation using global keyboard shortcut
        function onActivated() {
            plasmoidContainer.effectivePressed = true;
            Qt.callLater(() => {
                plasmoidContainer.effectivePressed = false;
            });
        }
    }

    Connections {
        target: plasmoidContainer.applet

        function onExpandedChanged(expanded) {
            if (expanded) {
                plasmoidContainer.effectivePressed = false;
            }
        }
    }

    PlasmaComponents3.BusyIndicator {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            leftMargin: plasmoidContainer.inHiddenLayout ? Math.round(Kirigami.Units.smallSpacing / 2) : 0
            right: plasmoidContainer.inHiddenLayout ? undefined : parent.right
        }
        z: 999
        running: plasmoidContainer.applet?.Plasmoid.busy ?? false
    }

    Binding {
        property: "hideOnWindowDeactivate"
        // Upstream ties this to Plasmoid.configuration.pin, which makes every
        // tray item tear its own popup down as soon as the tray popup takes
        // window activation (main.qml's onVisibleChanged calls
        // dialog.requestActivate()). Collapsing the item's expanded state then
        // collapses the whole tray again, so the popup only flashes for a frame.
        // The tray popup owns that behaviour itself via its own
        // hideOnWindowDeactivate, so the items must not opt into it themselves.
        value: false
        target: plasmoidContainer.applet
        when: plasmoidContainer.applet !== null
        restoreMode: Binding.RestoreBinding
    }
    Binding {
        property: "activeFocusOnTab"
        value: false
        target: plasmoidContainer.applet?.compactRepresentationItem ?? null
        when: plasmoidContainer?.applet && plasmoidContainer.inHiddenLayout
        restoreMode: Binding.RestoreBinding
    }
    Binding {
        property: "activeFocusOnTab"
        value: false
        target: plasmoidContainer.applet?.fullRepresentationItem ?? null
        when: plasmoidContainer?.applet && plasmoidContainer.inHiddenLayout && !plasmoidContainer.applet.compactRepresentationItem
        restoreMode: Binding.RestoreBinding
    }
}
