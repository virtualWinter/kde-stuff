pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
// Deliberately imported after QtQuick to avoid missing restoreMode property in Binding. Fix in Qt 6.
import QtQml

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import plasma.applet.moe.vwinter.appmenu

PlasmoidItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool view: Plasmoid.configuration.compactView

    // ------------------------------------------------------------------
    // Application name (macOS-style menu title)
    // ------------------------------------------------------------------
    property string activeAppName: ""

    TaskManager.TasksModel {
        id: activeWindowModel

        filterByScreen: !Plasmoid.configuration.allScreens
        screenGeometry: root.screenGeometry
        // The title is shown for any focused window, so do not exclude
        // windows because of their desktop, activity or taskbar flags.
        filterByVirtualDesktop: false
        filterByActivity: false
        filterHidden: false
        filterNotMinimized: false
    }

    // The tasks model briefly reports no active task while the focus is
    // switching windows, so the name is only cleared once that state
    // persists for a moment.
    Timer {
        id: clearAppNameTimer

        interval: 250
        onTriggered: {
            if (!root.activeTaskIndex()) {
                root.activeAppName = "";
            }
        }
    }

    // Safety net: the model does not emit a signal for every change of the
    // active task (e.g. when a window enters or leaves its filters), so
    // re-check periodically as well.
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateActiveAppName()
    }

    function activeTaskIndex() {
        const index = activeWindowModel.activeTask;
        if (index && index.valid) {
            return index;
        }
        // Fall back to scanning the rows if the convenience accessor did not
        // find the active task.
        for (let i = 0; i < activeWindowModel.rowCount(); ++i) {
            const idx = activeWindowModel.index(i, 0);
            if (activeWindowModel.data(idx, TaskManager.AbstractTasksModel.IsActive)) {
                return idx;
            }
        }
        return null;
    }

    function updateActiveAppName() {
        const index = root.activeTaskIndex();
        if (index) {
            const name = String(activeWindowModel.data(index, TaskManager.AbstractTasksModel.AppName) ?? "");
            root.activeAppName = name;
            clearAppNameTimer.stop();
            return;
        }
        // No application task is active: keep the last name while the panel
        // has focus (a panel popup is open), otherwise clear it shortly after.
        if (Plasmoid.containment.status === PlasmaCore.Types.AcceptingInputStatus) {
            clearAppNameTimer.stop();
            return;
        }
        clearAppNameTimer.restart();
    }

    Connections {
        target: activeWindowModel

        function onActiveTaskChanged() {
            root.updateActiveAppName();
        }

        function onCountChanged() {
            root.updateActiveAppName();
        }

        function onRowsInserted() {
            root.updateActiveAppName();
        }

        function onRowsRemoved() {
            root.updateActiveAppName();
        }

        function onModelReset() {
            root.updateActiveAppName();
        }

        function onLayoutChanged() {
            root.updateActiveAppName();
        }

        function onDataChanged(topLeft, bottomRight, roles) {
            if (roles.length === 0
                    || roles.includes(TaskManager.AbstractTasksModel.IsActive)
                    || roles.includes(TaskManager.AbstractTasksModel.AppName)) {
                root.updateActiveAppName();
            }
        }
    }

    Connections {
        target: Plasmoid.containment

        function onStatusChanged() {
            root.updateActiveAppName();
        }
    }

    // The applet must not rely on its representation to change its status:
    // the representation is not instantiated while the applet is hidden, so
    // the status is computed here, in the always-alive root item.
    property int menuCount: 0

    Plasmoid.status: {
        if (appMenuModel.menuAvailable && Plasmoid.currentIndex > -1 && root.menuCount > 0) {
            return PlasmaCore.Types.NeedsAttentionStatus;
        }
        return (root.menuCount > 0 || root.activeAppName.length > 0 || Plasmoid.configuration.compactView)
            ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus;
    }

    Connections {
        target: appMenuModel

        function onVisibleChanged() {
            root.updateMenuCount();
        }

        function onRowsInserted() {
            root.updateMenuCount();
        }

        function onRowsRemoved() {
            root.updateMenuCount();
        }

        function onModelReset() {
            root.updateMenuCount();
        }
    }

    function updateMenuCount() {
        root.menuCount = appMenuModel.visible ? appMenuModel.rowCount() : 0;
    }

    Component.onCompleted: {
        updateActiveAppName();
        updateMenuCount();
    }

    onViewChanged: {
        Plasmoid.view = view;
    }

    Plasmoid.constraintHints: Plasmoid.CanFillArea
    preferredRepresentation: Plasmoid.configuration.compactView ? compactRepresentation : fullRepresentation

    // Only exists because the default CompactRepresentation doesn't expose a
    // way to mark its icon as disabled.
    // TODO remove once it gains that feature.
    compactRepresentation: PlasmaComponents3.ToolButton {
        readonly property int fakeIndex: 0
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.minimumWidth: implicitWidth
        Layout.maximumWidth: implicitWidth
        enabled: appMenuModel.menuAvailable
        checkable: appMenuModel.menuAvailable && Plasmoid.currentIndex === fakeIndex
        checked: checkable
        icon.name: "application-menu"

        display: PlasmaComponents3.AbstractButton.IconOnly
        text: Plasmoid.title
        Accessible.description: root.toolTipSubText

        onClicked: Plasmoid.trigger(this, 0);
    }

    fullRepresentation: GridLayout {
        id: buttonGrid

        LayoutMirroring.enabled: Application.layoutDirection === Qt.RightToLeft
        Layout.minimumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight

        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rowSpacing: 0
        columnSpacing: 0

        Binding {
            target: Plasmoid
            property: "buttonGrid"
            value: buttonGrid
            restoreMode: Binding.RestoreNone
        }

        Connections {
            target: Plasmoid
            function onRequestActivateIndex(index: int) {
                const button = buttonRepeater.itemAt(index) as MenuDelegate;
                if (button) {
                    button.activated();
                }
            }
        }

        Connections {
            target: Plasmoid
            function onActivated() {
                const button = buttonRepeater.itemAt(0) as MenuDelegate;
                if (button) {
                    button.activated();
                }
            }
        }

        // Whether the application already has a menu with the given name, so
        // the application title is not repeated.
        function hasMenuNamed(name) {
            for (let i = 0; i < buttonRepeater.count; ++i) {
                const button = buttonRepeater.itemAt(i);
                if (button && button.visible && button.text === name) {
                    return true;
                }
            }
            return false;
        }

        // macOS-style application title.
        PlasmaComponents3.Label {
            id: appNameLabel

            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing

            text: root.activeAppName
            font.bold: true
            elide: Text.ElideRight
            visible: text.length > 0 && !buttonGrid.hasMenuNamed(text)
        }

        PlasmaComponents3.ToolButton {
            id: noMenuPlaceholder
            visible: buttonRepeater.count === 0 && !appNameLabel.visible
            text: Plasmoid.title
            Layout.fillWidth: root.vertical
            Layout.fillHeight: !root.vertical
        }

        Repeater {
            id: buttonRepeater
            model: appMenuModel.visible ? appMenuModel : null

            MenuDelegate {
                required property int index
                required property string activeMenu
                required property PlasmaCore.Action activeActions
                readonly property int buttonIndex: index

                Layout.fillWidth: root.vertical
                Layout.fillHeight: !root.vertical
                text: activeMenu
                Kirigami.MnemonicData.active: altState.pressed

                down: Plasmoid.currentIndex === index
                visible: text !== "" && (activeActions?.visible ?? false)

                menuIsOpen: Plasmoid.currentIndex !== -1
                onActivated: Plasmoid.trigger(this, index)

                // So we can show mnemonic underlines only while Alt is pressed
                KeyboardIndicator.KeyState {
                    id: altState
                    key: Qt.Key_Alt
                }
            }
        }
        Item {
            Layout.preferredWidth: 0
            Layout.preferredHeight: 0
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    AppMenuModel {
        id: appMenuModel
        containmentStatus: Plasmoid.containment.status
        screenGeometry: root.screenGeometry
        allScreens: Plasmoid.configuration.allScreens
        onRequestActivateIndex: Plasmoid.requestActivateIndex(index)
        Component.onCompleted: {
            Plasmoid.model = appMenuModel;
        }
    }
}
