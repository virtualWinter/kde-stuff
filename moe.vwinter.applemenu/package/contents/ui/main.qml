import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import org.kde.plasma.private.sessions 2.0

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    Plasmoid.title: i18n("v-menu")
    toolTipMainText: i18n("v-menu")
    toolTipSubText: i18n("System and session actions")

    // ------------------------------------------------------------------
    // Configuration
    // ------------------------------------------------------------------
    readonly property int menuWidth: Plasmoid.configuration.menuWidth
    readonly property string menuBackgroundColorName: Plasmoid.configuration.menuBackgroundColor || ""
    readonly property color menuBackgroundColor: menuBackgroundColorName.length > 0 ? menuBackgroundColorName : Kirigami.Theme.backgroundColor
    readonly property bool showAbout: Plasmoid.configuration.showAbout
    readonly property bool showSystemSettings: Plasmoid.configuration.showSystemSettings
    readonly property bool showSoftwareCenter: Plasmoid.configuration.showSoftwareCenter
    readonly property bool showForceQuit: Plasmoid.configuration.showForceQuit
    readonly property bool showScreenshot: Plasmoid.configuration.showScreenshot
    readonly property bool showSleep: Plasmoid.configuration.showSleep
    readonly property bool showRestart: Plasmoid.configuration.showRestart
    readonly property bool showShutdown: Plasmoid.configuration.showShutdown
    readonly property bool showLock: Plasmoid.configuration.showLock
    readonly property bool showLogout: Plasmoid.configuration.showLogout
    readonly property string iconNameOverride: Plasmoid.configuration.iconName || ""
    readonly property string iconSource: iconNameOverride.length > 0 ? iconNameOverride : detectedIconName
    readonly property bool keepGlobalMenu: Plasmoid.configuration.keepGlobalMenu

    // ------------------------------------------------------------------
    // Global menu
    // ------------------------------------------------------------------
    // The application menu applet clears its menus whenever the active window
    // changes, and opening a panel popup makes plasmashell the active window.
    // Marking the containment as "accepting input" makes the applet keep the
    // last menu instead, so the global menu stays visible while this popup is
    // open. The shell recomputes the containment status from its applets, so
    // it is re-asserted until the popup closes.
    property int savedContainmentStatus: -1

    function keepContainmentAcceptingInput() {
        const containment = Plasmoid.containment;
        if (containment && root.expanded && root.keepGlobalMenu
                && containment.status !== PlasmaCore.Types.AcceptingInputStatus) {
            containment.status = PlasmaCore.Types.AcceptingInputStatus;
        }
    }

    onExpandedChanged: {
        const containment = Plasmoid.containment;
        if (!containment) {
            return;
        }
        if (root.expanded) {
            if (root.keepGlobalMenu) {
                savedContainmentStatus = containment.status;
                keepContainmentAcceptingInput();
            }
        } else if (savedContainmentStatus >= 0) {
            containment.status = savedContainmentStatus;
            savedContainmentStatus = -1;
        }
    }

    Connections {
        target: Plasmoid.containment

        function onStatusChanged() {
            root.keepContainmentAcceptingInput();
        }
    }

    // ------------------------------------------------------------------
    // Environment, resolved once by contents/code/env.sh
    // ------------------------------------------------------------------
    property bool environmentLoaded: false
    property string detectedIconName: "start-here-kde"
    property string systemSettingsCommand: ""
    property string softwareCenterCommand: ""
    property string infoCenterCommand: ""
    property string forceQuitCommand: ""
    property string screenshotCommand: ""

    readonly property string environmentScriptPath: decodeURIComponent(Qt.resolvedUrl("../code/env.sh").toString().replace(/^file:\/\//, ""))
    readonly property string environmentCommand: "sh " + root.shellQuote(environmentScriptPath)

    // ------------------------------------------------------------------
    // Session management
    // ------------------------------------------------------------------
    SessionManagement {
        id: sessionManagement
    }
    readonly property bool sessionsReady: sessionManagement.state === SessionManagement.Ready

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------
    component MenuEntry: PlasmaComponents3.ItemDelegate {
        id: entry

        Layout.fillWidth: true

        // Some Plasma themes ship an effectively invisible listitem "hover"
        // element (Materia uses opacity 0.001), so the highlight is drawn
        // here instead of relying on the theme background.
        leftPadding: Kirigami.Units.largeSpacing
        rightPadding: Kirigami.Units.largeSpacing
        topPadding: Kirigami.Units.smallSpacing
        bottomPadding: Kirigami.Units.smallSpacing

        background: Rectangle {
            radius: Kirigami.Units.smallSpacing / 2
            color: {
                const textColor = Kirigami.Theme.textColor;
                if (entry.pressed) {
                    return Qt.rgba(textColor.r, textColor.g, textColor.b, 0.20);
                }
                if (entry.hovered) {
                    return Qt.rgba(textColor.r, textColor.g, textColor.b, 0.12);
                }
                return "transparent";
            }

            Behavior on color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    P5Support.DataSource {
        id: commandRunner

        engine: "executable"
        connectedSources: []

        onNewData: function(source, data) {
            if (source === root.environmentCommand) {
                root.handleEnvironmentReport(data.stdout || "");
            }
            commandRunner.disconnectSource(source);
        }
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function runCommand(command) {
        if (command.length === 0) {
            return;
        }
        commandRunner.connectSource(command);
        root.expanded = false;
    }

    function handleEnvironmentReport(output) {
        const lines = output.split("\n");
        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i];
            if (line.indexOf("ICON:") === 0) {
                const iconName = line.substring(5).trim();
                if (iconName.length > 0) {
                    root.detectedIconName = iconName;
                }
            } else if (line.indexOf("CMD:") === 0) {
                const parts = line.substring(4).split("=");
                const commandName = parts[0];
                const rawPath = parts.slice(1).join("=");
                if (rawPath.length === 0) {
                    continue;
                }
                const path = root.shellQuote(rawPath);
                if (commandName === "systemsettings") {
                    root.systemSettingsCommand = path;
                } else if (commandName === "plasma-discover" || commandName === "discover") {
                    if (root.softwareCenterCommand.length === 0) {
                        root.softwareCenterCommand = path;
                    }
                } else if (commandName === "kinfocenter") {
                    root.infoCenterCommand = path;
                } else if (commandName === "plasma-systemmonitor") {
                    root.forceQuitCommand = path;
                } else if (commandName === "spectacle") {
                    root.screenshotCommand = path;
                }
            }
        }
        root.environmentLoaded = true;
    }

    Component.onCompleted: commandRunner.connectSource(environmentCommand)

    // ------------------------------------------------------------------
    // Panel button
    // ------------------------------------------------------------------
    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: Kirigami.Units.iconSizes.smallMedium

        Layout.minimumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight

        Rectangle {
            anchors.fill: parent
            radius: 2
            color: mouseArea.containsMouse
                ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }
        }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height)
            height: width
            source: root.iconSource
            scale: mouseArea.containsMouse ? 1.06 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
        }
    }

    // ------------------------------------------------------------------
    // Menu
    // ------------------------------------------------------------------
    fullRepresentation: Item {
        id: menuRoot

        // Layouts recompute their own implicit size, so the popup size has
        // to be driven through the attached Layout properties.
        Layout.preferredWidth: Kirigami.Units.gridUnit * root.menuWidth
        Layout.minimumWidth: Kirigami.Units.gridUnit * root.menuWidth
        implicitHeight: menuColumn.implicitHeight

        // Painted over the popup frame provided by plasmashell: the frame is
        // drawn behind the content, so extending past the content area covers
        // it while the window's rounded shape clips the corners.
        Rectangle {
            anchors.fill: parent
            anchors.margins: -Kirigami.Units.gridUnit * 2
            color: root.menuBackgroundColor
        }

        // Subtle open animation: the content fades in and settles a few pixels
        // downward, while the background appears together with the popup.
        onVisibleChanged: {
            if (visible) {
                openAnimation.restart();
            }
        }

        Component.onCompleted: {
            if (visible) {
                openAnimation.restart();
            }
        }

        ParallelAnimation {
            id: openAnimation

            NumberAnimation {
                target: menuColumn
                property: "opacity"
                from: 0
                to: 1
                duration: 160
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: contentSlide
                property: "y"
                from: -Kirigami.Units.smallSpacing
                to: 0
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: menuColumn

            anchors.fill: parent
            spacing: 0
            opacity: 0

            transform: Translate {
                id: contentSlide

                y: -Kirigami.Units.smallSpacing
            }

            MenuEntry {
                text: i18n("About This System")
                visible: root.showAbout && root.infoCenterCommand.length > 0
                onClicked: root.runCommand(root.infoCenterCommand + " kcm_about-distro")
            }

            MenuEntry {
                text: i18n("System Settings")
                visible: root.showSystemSettings && root.systemSettingsCommand.length > 0
                onClicked: root.runCommand(root.systemSettingsCommand)
            }

            MenuEntry {
                text: i18n("Software Center")
                visible: root.showSoftwareCenter && root.softwareCenterCommand.length > 0
                onClicked: root.runCommand(root.softwareCenterCommand)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                visible: (root.showForceQuit && root.forceQuitCommand.length > 0)
                    || (root.showScreenshot && root.screenshotCommand.length > 0)

                Kirigami.Separator {
                    Layout.fillWidth: true
                }

                MenuEntry {
                    text: i18n("Force Quit…")
                    visible: root.showForceQuit && root.forceQuitCommand.length > 0
                    onClicked: root.runCommand(root.forceQuitCommand + " --page-id processes")
                }

                MenuEntry {
                    text: i18n("Take a Screenshot…")
                    visible: root.showScreenshot && root.screenshotCommand.length > 0
                    onClicked: root.runCommand(root.screenshotCommand)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                visible: root.sessionsReady
                    && ((root.showSleep && sessionManagement.canSuspend)
                        || (root.showRestart && sessionManagement.canReboot)
                        || (root.showShutdown && sessionManagement.canShutdown))

                Kirigami.Separator {
                    Layout.fillWidth: true
                }

                MenuEntry {
                    text: i18n("Sleep")
                    visible: root.showSleep && sessionManagement.canSuspend
                    onClicked: {
                        sessionManagement.suspend();
                        root.expanded = false;
                    }
                }

                MenuEntry {
                    text: i18n("Restart…")
                    visible: root.showRestart && sessionManagement.canReboot
                    onClicked: {
                        sessionManagement.requestReboot(SessionManagement.Default);
                        root.expanded = false;
                    }
                }

                MenuEntry {
                    text: i18n("Shut Down…")
                    visible: root.showShutdown && sessionManagement.canShutdown
                    onClicked: {
                        sessionManagement.requestShutdown(SessionManagement.Default);
                        root.expanded = false;
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                visible: root.sessionsReady
                    && ((root.showLock && sessionManagement.canLock)
                        || (root.showLogout && sessionManagement.canLogout))

                Kirigami.Separator {
                    Layout.fillWidth: true
                }

                MenuEntry {
                    text: i18n("Lock Screen")
                    visible: root.showLock && sessionManagement.canLock
                    onClicked: {
                        sessionManagement.lock();
                        root.expanded = false;
                    }
                }

                MenuEntry {
                    text: i18n("Log Out…")
                    visible: root.showLogout && sessionManagement.canLogout
                    onClicked: {
                        sessionManagement.requestLogout(SessionManagement.Default);
                        root.expanded = false;
                    }
                }
            }
        }
    }
}
