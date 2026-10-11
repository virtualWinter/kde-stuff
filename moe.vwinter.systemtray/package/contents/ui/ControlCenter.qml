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

/*
 * A purposefully small quick-settings layout:
 *   Wi-Fi | Bluetooth
 *   Volume and output devices
 *   Brightness
 *   Notifications
 */
Item {
    id: controlCenter

    readonly property string notificationsAppletId: "org.kde.plasma.notifications"
    readonly property int tileCount: wifiTiles.count + bluetoothTiles.count
        + volumeTiles.count

    implicitWidth: Kirigami.Units.gridUnit * 22
    implicitHeight: Math.max(Kirigami.Units.gridUnit * 12,
                             heading.height + headerRow.implicitHeight
                             + connectivityRow.implicitHeight
                             + volumeTilesBox.implicitHeight
                             + brightnessControl.implicitHeight
                             + notifications.implicitHeight)
    Layout.minimumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight

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

    KItemModels.KSortFilterProxyModel {
        id: bluetoothModel
        filterRoleName: "itemId"
        filterRowCallback: (sourceRow, sourceParent) => controlCenter.isVisibleSystemApplet(
            sourceModel, sourceRow, sourceParent, "org.kde.plasma.bluetooth")
        Component.onCompleted: sourceModel = Plasmoid.systemTrayModel
    }

    KItemModels.KSortFilterProxyModel {
        id: volumeModel
        filterRoleName: "itemId"
        filterRowCallback: (sourceRow, sourceParent) => controlCenter.isVisibleSystemApplet(
            sourceModel, sourceRow, sourceParent, "org.kde.plasma.volume")
        Component.onCompleted: sourceModel = Plasmoid.systemTrayModel
    }


    PlasmaExtras.PlasmoidHeading {
        id: heading

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: headerRow.height + bottomPadding
    }

    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            topMargin: heading.height
        }
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            id: headerRow

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
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

                PlasmaComponents3.ToolTip { text: configureButton.text }
            }

            PlasmaComponents3.ToolButton {
                id: pinButton
                icon.name: "window-pin"
                checkable: true
                checked: Plasmoid.configuration.pin
                display: PlasmaComponents3.AbstractButton.IconOnly
                text: i18n("Keep Open")
                onToggled: Plasmoid.configuration.pin = checked

                PlasmaComponents3.ToolTip { text: pinButton.text }
            }
        }

        RowLayout {
            id: connectivityRow

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                id: wifiTiles
                model: wifiModel
                delegate: ControlTile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    onActivated: systemTrayState.expanded = false
                }
            }

            Repeater {
                id: bluetoothTiles
                model: bluetoothModel
                delegate: ControlTile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    onActivated: systemTrayState.expanded = false
                }
            }
        }

        Item {
            id: volumeTilesBox
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            implicitHeight: volumeTiles.count > 0 && volumeTiles.itemAt(0)
                ? volumeTiles.itemAt(0).implicitHeight
                : 0

            Repeater {
                id: volumeTiles
                model: volumeModel
                delegate: InlineAppletCard {
                    anchors.left: parent ? parent.left : undefined
                    anchors.right: parent ? parent.right : undefined
                    titleOverride: i18n("Volume & Output")
                    controlHeight: Kirigami.Units.gridUnit * 13
                }
            }
        }

        BrightnessQuickControl {
            id: brightnessControl
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        NotificationsSection {
            id: notifications
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
        }
    }

    Keys.onEscapePressed: event => {
        systemTrayState.expanded = false;
        event.accepted = true;
    }
}
