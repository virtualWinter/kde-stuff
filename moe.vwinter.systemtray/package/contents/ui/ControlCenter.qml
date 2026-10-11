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
 * The Control Center popup. It offers two layouts, selected in the applet
 * configuration:
 *   Compact - Wi-Fi and Bluetooth tiles, the Sound and Brightness quick
 *             controls and the docked notification list
 *   Grid    - a module grid with per-module sizes
 */
Item {
    id: controlCenter

    readonly property string notificationsAppletId: "org.kde.plasma.notifications"
    readonly property bool gridMode: Plasmoid.configuration.layoutStyle === 1

    implicitWidth: Kirigami.Units.gridUnit * 22
    implicitHeight: Math.max(Kirigami.Units.gridUnit * 12,
                             content.implicitHeight + heading.height)
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
        id: content

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
            Layout.fillHeight: false
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing
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
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            visible: !controlCenter.gridMode
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

        AudioQuickControl {
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            visible: !controlCenter.gridMode
        }

        BrightnessQuickControl {
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            visible: !controlCenter.gridMode
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            visible: !controlCenter.gridMode
        }

        NotificationsSection {
            id: notifications

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: implicitHeight
            visible: !controlCenter.gridMode
        }

        GridCenter {
            id: grid

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing
            visible: controlCenter.gridMode

            onAppletPopupLaunched: systemTrayState.expanded = false
        }
    }

    Keys.onEscapePressed: event => {
        systemTrayState.expanded = false;
        event.accepted = true;
    }
}
