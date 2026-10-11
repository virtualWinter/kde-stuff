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
 * Control Center: the tray's quick settings as a grid of cards, with the
 * notification list docked underneath.
 */
Item {
    id: controlCenter

    readonly property string notificationsAppletId: "org.kde.plasma.notifications"
    readonly property int tileCount: tiles.count

    implicitWidth: Kirigami.Units.gridUnit * 22
    // Keep the popup only as tall as its header, full settings grid, and
    // notification section. The settings themselves never need a scrollbar.
    implicitHeight: Math.max(Kirigami.Units.gridUnit * 12,
                             heading.height + headerRow.implicitHeight
                             + quickSettingsGrid.implicitHeight
                             + notifications.implicitHeight)
    Layout.minimumWidth: implicitWidth
    // AppletPopup remembers its previous size. Keep that saved size from
    // clipping the complete no-scroll grid or its notification footer.
    Layout.minimumHeight: implicitHeight

    focus: true

    // Role numbers from BaseModel::BaseRole in src/systemtraymodel.h:
    // ItemType = Qt::UserRole + 1, ItemId = +2, EffectiveStatus = +6.
    // Only applets that are part of this tray (not unloaded plugins, not
    // status-notifier apps) and that are shown in the panel or popup count.
    KItemModels.KSortFilterProxyModel {
        id: quickSettingsModel

        filterRoleName: "effectiveStatus"
        filterRowCallback: (sourceRow, sourceParent) => {
            const row = sourceModel.index(sourceRow, 0, sourceParent);
            const itemType = sourceModel.data(row, Qt.UserRole + 1);
            const itemId = sourceModel.data(row, Qt.UserRole + 2);
            const status = sourceModel.data(row, Qt.UserRole + 6);

            return itemType === "Plasmoid"
                && itemId !== controlCenter.notificationsAppletId
                && (status === PlasmaCore.Types.ActiveStatus || status === PlasmaCore.Types.PassiveStatus);
        }
        // avoid unnecessary binding, it causes loops
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
        spacing: 0

        RowLayout {
            id: headerRow

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.topMargin: 0
            Layout.bottomMargin: 0
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

        Flow {
            id: quickSettingsGrid

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                id: tiles

                model: quickSettingsModel

                delegate: ControlTile {
                    // Finish an odd row cleanly instead of leaving a spare
                    // card-sized hole beside the last setting.
                    spanFullRow: tiles.count % 2 === 1 && index === tiles.count - 1
                    onActivated: systemTrayState.expanded = false
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            visible: notifications.visible
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
