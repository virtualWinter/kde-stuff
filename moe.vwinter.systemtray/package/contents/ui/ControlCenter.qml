/*
    SPDX-FileCopyrightText: 2026 vwinter

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.bluezqt as BluezQt

/*
 * The Control Center popup. It offers two layouts, selected in the applet
 * configuration:
 *   Compact - Wi-Fi and Bluetooth tiles, the Sound and Brightness quick
 *             controls and the docked notification list
 *   Grid    - a module grid with per-module sizes
 */
Item {
    id: controlCenter

    readonly property bool gridMode: Plasmoid.configuration.layoutStyle === 1
    property string activeSection: ""

    implicitWidth: Kirigami.Units.gridUnit * 22
    implicitHeight: content.implicitHeight + Kirigami.Units.smallSpacing * 2
    Layout.minimumWidth: implicitWidth
    Layout.minimumHeight: 0
    Layout.preferredHeight: implicitHeight

    focus: true


    // Role numbers from BaseModel::BaseRole in src/systemtraymodel.h:
    // ItemType = Qt::UserRole + 1, ItemId = +2, EffectiveStatus = +6.
    function isVisibleSystemApplet(sourceModel, sourceRow, sourceParent, itemId) {
        const row = sourceModel.index(sourceRow, 0, sourceParent);
        const itemType = sourceModel.data(row, Qt.UserRole + 1);
        const id = sourceModel.data(row, Qt.UserRole + 2);
        const status = sourceModel.data(row, Qt.UserRole + 6);

        return itemType === "Plasmoid" && id === itemId
            && (status === PlasmaCore.Types.ActiveStatus || status === PlasmaCore.Types.PassiveStatus);
    }

    KItemModels.KSortFilterProxyModel {
        id: wifiModel
        filterRoleName: "itemId"
        filterRowCallback: (sourceRow, sourceParent) => controlCenter.isVisibleSystemApplet(
            sourceModel, sourceRow, sourceParent, "org.kde.plasma.networkmanagement")
        Component.onCompleted: sourceModel = Plasmoid.systemTrayModel
    }

    PlasmaNM.NetworkModel {
        id: networkModel
    }

    Connections {
        target: controlCenter
        function onActiveSectionChanged() {
            if (controlCenter.activeSection === "org.kde.plasma.networkmanagement") {
                networkActivationHandler.requestScan();
            }
        }
    }

    PlasmaNM.Handler {
        id: networkActivationHandler
        onConnectionActivationFailed: (connectionPath, message) => {
            const networkApplet = wifiModel.get(0)?.applet;
            if (networkApplet?.Plasmoid) {
                networkApplet.Plasmoid.activated();
                systemTrayState.expanded = false;
            }
        }
    }

    PlasmaNM.AppletProxyModel {
        id: networkListModel
        sourceModel: networkModel
    }

    BluezQt.DevicesModel {
        id: bluetoothDevices
    }

    KItemModels.KSortFilterProxyModel {
        id: bluetoothDeviceList
        sourceModel: bluetoothDevices
        filterRoleName: "blocked"
        filterRowCallback: (sourceRow, sourceParent) => {
            const row = sourceModel.index(sourceRow, 0, sourceParent);
            return !sourceModel.data(row, Qt.UserRole + 11);
        }
    }

    KItemModels.KSortFilterProxyModel {
        id: bluetoothModel
        filterRoleName: "itemId"
        filterRowCallback: (sourceRow, sourceParent) => controlCenter.isVisibleSystemApplet(
            sourceModel, sourceRow, sourceParent, "org.kde.plasma.bluetooth")
        Component.onCompleted: sourceModel = Plasmoid.systemTrayModel
    }

    KItemModels.KSortFilterProxyModel {
        id: batteryModel
        filterRoleName: "itemId"
        filterRowCallback: (sourceRow, sourceParent) => controlCenter.isVisibleSystemApplet(
            sourceModel, sourceRow, sourceParent, "org.kde.plasma.battery")
        Component.onCompleted: sourceModel = Plasmoid.systemTrayModel
    }

    ColumnLayout {
        id: content

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            leftMargin: Kirigami.Units.smallSpacing
            rightMargin: Kirigami.Units.smallSpacing
            bottomMargin: Kirigami.Units.smallSpacing
        }
        spacing: Kirigami.Units.smallSpacing
        RowLayout {
            id: headerRow

            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.leftMargin: Kirigami.Units.smallSpacing / 2
            Layout.rightMargin: Kirigami.Units.smallSpacing / 2
            Layout.topMargin: Kirigami.Units.smallSpacing / 2
            spacing: Kirigami.Units.smallSpacing

            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: 3
                text: i18n("Control Center")
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            PlasmaComponents3.ToolButton {
                id: configureButton

                readonly property var configureAction: Plasmoid.internalAction("configure")

                icon.name: "configure"
                visible: !!configureAction
                enabled: !!configureAction && configureAction.enabled
                display: PlasmaComponents3.AbstractButton.IconOnly
                text: configureAction ? configureAction.text : i18n("Configure System Tray")
                onClicked: configureButton.configureAction?.trigger()

                PlasmaComponents3.ToolTip {
                    text: configureButton.text
                }
            }

            PlasmaComponents3.ToolButton {
                id: pinButton

                icon.name: "window-pin"
                checkable: true
                checked: Plasmoid.configuration.pin
                display: PlasmaComponents3.AbstractButton.IconOnly
                text: i18n("Keep Open")
                onToggled: Plasmoid.configuration.pin = checked

                PlasmaComponents3.ToolTip {
                    text: pinButton.text
                }
            }
        }

        RowLayout {
            id: connectivityRow

            Layout.fillWidth: true
            Layout.fillHeight: false
            visible: !controlCenter.gridMode
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                id: wifiTiles

                model: controlCenter.activeSection === "" ? wifiModel : null

                delegate: Item {
                    required property string itemId
                    required property string displayText
                    required property bool hasApplet
                    required property var applet
                    required property string iconName
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    implicitHeight: tile.implicitHeight

                    ControlTile {
                        id: tile
                        anchors.fill: parent
                        itemId: parent.itemId
                        displayText: parent.displayText
                        hasApplet: parent.hasApplet
                        applet: parent.applet
                        iconName: parent.iconName
                        onRequested: itemId => controlCenter.activeSection = itemId
                    }
                }
            }

            Repeater {
                id: bluetoothTiles

                model: controlCenter.activeSection === "" ? bluetoothModel : null

                delegate: Item {
                    required property string itemId
                    required property string displayText
                    required property bool hasApplet
                    required property var applet
                    required property string iconName
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    implicitHeight: tile.implicitHeight

                    ControlTile {
                        id: tile
                        anchors.fill: parent
                        itemId: parent.itemId
                        displayText: parent.displayText
                        hasApplet: parent.hasApplet
                        applet: parent.applet
                        iconName: parent.iconName
                        onRequested: itemId => controlCenter.activeSection = itemId
                    }
                }
            }
        }

        Repeater {
            model: controlCenter.activeSection === "org.kde.plasma.networkmanagement"
                ? wifiModel
                : (controlCenter.activeSection === "org.kde.plasma.bluetooth" ? bluetoothModel : null)

            delegate: Item {
                required property string itemId
                required property string displayText
                required property bool hasApplet
                required property var applet
                required property string iconName
                Layout.fillWidth: true
                implicitHeight: tile.implicitHeight

                ControlTile {
                    id: tile
                    anchors.fill: parent
                    itemId: parent.itemId
                    displayText: parent.displayText
                    hasApplet: parent.hasApplet
                    applet: parent.applet
                    iconName: parent.iconName
                    expanded: true
                    expandedContent: connectivityChooser
                    onRefreshRequested: networkActivationHandler.requestScan()
                    onRequested: controlCenter.activeSection = controlCenter.activeSection === itemId ? "" : itemId
                }
            }
        }

        AudioQuickControl {
            visible: !controlCenter.gridMode
        }

        BrightnessQuickControl {
            visible: !controlCenter.gridMode
        }

        Repeater {
            model: controlCenter.gridMode ? 0 : batteryModel

            delegate: BatteryStatusCard {}
        }

        NotificationsSection {
            id: notifications

            Layout.fillWidth: true
            visible: !controlCenter.gridMode && notifications.hasNotificationContent
        }

        GridCenter {
            id: grid

            Layout.fillWidth: true
            Layout.fillHeight: false
            implicitHeight: controlCenter.gridMode ? grid.implicitHeight : 0
            visible: controlCenter.gridMode

            onAppletPopupLaunched: systemTrayState.expanded = false
        }
    }

    Component {
        id: connectivityChooser

        ColumnLayout {
            width: parent ? parent.width : 0
            height: parent ? parent.height : implicitHeight
            spacing: Kirigami.Units.smallSpacing / 2

            Kirigami.Separator {
                Layout.fillWidth: true
                opacity: 0.45
            }

            ListView {
                id: networkList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 0
                readonly property bool sectionActive: controlCenter.activeSection === "org.kde.plasma.networkmanagement"
                visible: sectionActive
                model: sectionActive ? networkListModel : null
                clip: true
                enabled: sectionActive
                spacing: Kirigami.Units.smallSpacing / 2
                section.property: "Section"
                section.delegate: PlasmaExtras.ListSectionHeader {
                    required property string section
                    width: networkList.width - Kirigami.Units.smallSpacing * 2
                    text: section
                }

                delegate: Item {
                    id: networkDelegate
                    required property int index
                    required property var model
                    property string connectionName: model.ItemUniqueName ?? ""
                    property string connectionIcon: model.ConnectionIcon ?? "network-wireless"
                    property int connectionState: model.ConnectionState
                    property string connectionPath: model.ConnectionPath ?? ""
                    property string devicePath: model.DevicePath ?? ""
                    property string specificPath: model.SpecificPath ?? ""
                    property string uuid: model.Uuid ?? ""
                    property int connectionType: model.Type
                    property int securityType: model.SecurityType
                    property bool predictableWirelessPassword: !uuid
                        && connectionType === PlasmaNM.Enums.Wireless
                        && (securityType === PlasmaNM.Enums.StaticWep
                            || securityType === PlasmaNM.Enums.WpaPsk
                            || securityType === PlasmaNM.Enums.Wpa2Psk
                            || securityType === PlasmaNM.Enums.SAE)
                    width: networkList.width - Kirigami.Units.smallSpacing * 2
                    implicitHeight: networkRow.implicitHeight + Kirigami.Units.smallSpacing

                    RowLayout {
                        id: networkRow
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: Layout.preferredWidth
                            source: networkDelegate.connectionIcon
                        }

                        PlasmaComponents3.BusyIndicator {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Layout.preferredWidth
                            running: networkDelegate.connectionState === PlasmaNM.Enums.Activating
                                || networkDelegate.connectionState === PlasmaNM.Enums.Deactivating
                            visible: running
                        }

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: networkDelegate.connectionName
                            elide: Text.ElideRight
                        }

                        PlasmaComponents3.ToolButton {
                            icon.name: networkDelegate.connectionState === PlasmaNM.Enums.Activated
                                ? "network-disconnect" : "network-connect"
                            text: networkDelegate.connectionState === PlasmaNM.Enums.Activated
                                ? i18n("Disconnect") : i18n("Connect")
                            onClicked: {
                                if (!networkDelegate.predictableWirelessPassword) {
                                    if (networkDelegate.connectionState === PlasmaNM.Enums.Deactivated) {
                                        if (!networkDelegate.uuid) {
                                            networkActivationHandler.addAndActivateConnection(networkDelegate.devicePath, networkDelegate.specificPath);
                                        } else {
                                            networkActivationHandler.activateConnection(networkDelegate.connectionPath, networkDelegate.devicePath, networkDelegate.specificPath);
                                        }
                                    } else {
                                        networkActivationHandler.deactivateConnection(networkDelegate.connectionPath, networkDelegate.devicePath);
                                    }
                                } else {
                                    const networkApplet = wifiModel.get(0)?.applet;
                                    if (networkApplet?.Plasmoid) {
                                        networkApplet.Plasmoid.activated();
                                        systemTrayState.expanded = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ListView {
                id: bluetoothList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 0
                readonly property bool sectionActive: controlCenter.activeSection === "org.kde.plasma.bluetooth"
                visible: sectionActive
                model: sectionActive ? bluetoothDeviceList : null
                clip: true
                enabled: sectionActive
                spacing: Kirigami.Units.smallSpacing / 2

                delegate: Item {
                    id: bluetoothDelegate
                    required property int index
                    required property var model
                    property string deviceName: model.name ?? ""
                    property string deviceIcon: model.icon ?? "preferences-system-bluetooth"
                    property bool isConnected: model.connected ?? false
                    property bool isPaired: model.paired ?? false
                    property bool isBlocked: model.blocked ?? false
                    property var device: BluezQt.Manager.deviceForUbi(model.ubi ?? "")
                    width: bluetoothList.width - Kirigami.Units.smallSpacing * 2
                    implicitHeight: bluetoothRow.implicitHeight + Kirigami.Units.smallSpacing

                    RowLayout {
                        id: bluetoothRow
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: Layout.preferredWidth
                            source: bluetoothDelegate.deviceIcon
                        }

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: bluetoothDelegate.deviceName
                            elide: Text.ElideRight
                        }

                        PlasmaComponents3.ToolButton {
                            icon.name: bluetoothDelegate.isConnected ? "network-disconnect"
                                : (bluetoothDelegate.isPaired ? "network-connect" : "list-add")
                            text: bluetoothDelegate.isConnected ? i18n("Disconnect")
                                : (bluetoothDelegate.isPaired ? i18n("Connect") : i18n("Pair"))
                            enabled: !bluetoothDelegate.isBlocked
                            onClicked: {
                                const device = bluetoothDelegate.device;
                                if (!device) {
                                    return;
                                }
                                if (bluetoothDelegate.isConnected) {
                                    device.disconnectFromDevice();
                                } else if (bluetoothDelegate.isPaired) {
                                    device.connectToDevice();
                                } else {
                                    device.pair();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: event => {
        if (controlCenter.activeSection !== "") {
            controlCenter.activeSection = "";
        } else {
            systemTrayState.expanded = false;
        }
        event.accepted = true;
    }
}
