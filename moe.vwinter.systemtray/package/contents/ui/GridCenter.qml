/*
    SPDX-FileCopyrightText: 2026 vwinter

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

/*
 * The module grid: a four column layout of rounded modules whose sizes come
 * from the applet configuration. Modules are placed by a small packer that
 * wraps rows the way a flow would, so mixed sizes interlock instead of being
 * forced onto a rigid row grid.
 */
Item {
    id: grid

    signal appletPopupLaunched()

    readonly property int columns: 4
    readonly property real gap: Kirigami.Units.smallSpacing * 2

    // Placement order, top to bottom.
    readonly property var moduleOrder: [
        "wifi", "bluetooth", "media", "dnd", "sound", "brightness", "notifications"
    ]

    // Size used when the module has no explicit size configured.
    readonly property var automaticSizes: ({
        "wifi": 2,
        "bluetooth": 2,
        "media": 3,
        "dnd": 2,
        "sound": 4,
        "brightness": 4,
        "notifications": 2
    })

    readonly property var configuredSizes: ({
        "wifi": Plasmoid.configuration.wifiModuleSize,
        "bluetooth": Plasmoid.configuration.bluetoothModuleSize,
        "media": Plasmoid.configuration.mediaModuleSize,
        "dnd": Plasmoid.configuration.dndModuleSize,
        "sound": Plasmoid.configuration.soundModuleSize,
        "brightness": Plasmoid.configuration.brightnessModuleSize,
        "notifications": Plasmoid.configuration.notificationsModuleSize
    })

    // The launcher modules resolve their applet from the tray model.
    property Item wifiApplet: null
    property string wifiIcon: ""
    property string wifiTitle: ""
    property string wifiSubtitle: ""

    property Item bluetoothApplet: null
    property string bluetoothIcon: ""
    property string bluetoothTitle: ""
    property string bluetoothSubtitle: ""

    property Item notificationsApplet: null
    property string notificationsIcon: ""
    property string notificationsTitle: ""
    property string notificationsSubtitle: ""

    readonly property real cellSize: Math.max(Kirigami.Units.gridUnit * 3,
                                              (width - (columns - 1) * gap) / columns)
    readonly property real gridWidth: columns * cellSize + (columns - 1) * gap

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

    function firstLine(text) {
        const first = String(text).split("\n")[0].trim();
        return first;
    }

    /* The applet tray items can be hidden, so the modules that launch them
     * disappear with them and leave no gap behind. */
    function moduleAvailable(key) {
        if (key === "wifi") {
            return wifiApplet !== null;
        }
        if (key === "bluetooth") {
            return bluetoothApplet !== null;
        }
        if (key === "notifications") {
            return notificationsApplet !== null;
        }
        return true;
    }

    function sizeOf(key) {
        const configured = configuredSizes[key] ?? 0;
        return configured > 0 ? configured : (automaticSizes[key] ?? 2);
    }

    // Size code to grid cells: 1 small (1x1), 2 wide (2x1), 3 large (2x2), 4 full.
    function cellsOf(sizeCode) {
        switch (sizeCode) {
        case 1:
            return [1, 1];
        case 3:
            return [2, 2];
        case 4:
            return [columns, 1];
        default:
            return [2, 1];
        }
    }

    function computeBoxes() {
        const boxes = {};
        let x = 0;
        let y = 0;
        let rowHeight = 0;

        for (const key of moduleOrder) {
            if (!moduleAvailable(key)) {
                continue;
            }

            const cells = cellsOf(sizeOf(key));
            const moduleWidth = cells[0] * cellSize + (cells[0] - 1) * gap;
            const moduleHeight = cells[1] * cellSize + (cells[1] - 1) * gap;

            // Wrap when the module does not fit on the current row.
            if (x > 0 && x + moduleWidth > gridWidth + 0.5) {
                x = 0;
                y += rowHeight + gap;
                rowHeight = 0;
            }

            boxes[key] = {
                "x": x,
                "y": y,
                "width": moduleWidth,
                "height": moduleHeight
            };

            x += moduleWidth + gap;
            rowHeight = Math.max(rowHeight, moduleHeight);

            if (x >= gridWidth - 0.5) {
                x = 0;
                y += rowHeight + gap;
                rowHeight = 0;
            }
        }

        return {
            "boxes": boxes,
            "height": y + rowHeight
        };
    }

    readonly property var layoutResult: computeBoxes()
    readonly property var boxes: layoutResult.boxes

    function boxFor(key) {
        return boxes[key] ?? ({ "x": 0, "y": 0, "width": 0, "height": 0 });
    }

    implicitWidth: gridWidth
    implicitHeight: layoutResult.height

    KItemModels.KSortFilterProxyModel {
        id: wifiModel

        filterRoleName: "itemId"
        filterRowCallback: (sourceRow, sourceParent) => grid.isVisibleSystemApplet(
            sourceModel, sourceRow, sourceParent, "org.kde.plasma.networkmanagement")
        Component.onCompleted: sourceModel = Plasmoid.systemTrayModel
    }

    KItemModels.KSortFilterProxyModel {
        id: bluetoothModel

        filterRoleName: "itemId"
        filterRowCallback: (sourceRow, sourceParent) => grid.isVisibleSystemApplet(
            sourceModel, sourceRow, sourceParent, "org.kde.plasma.bluetooth")
        Component.onCompleted: sourceModel = Plasmoid.systemTrayModel
    }

    KItemModels.KSortFilterProxyModel {
        id: notificationsModel

        filterRoleName: "itemId"
        filterRowCallback: (sourceRow, sourceParent) => grid.isVisibleSystemApplet(
            sourceModel, sourceRow, sourceParent, "org.kde.plasma.notifications")
        Component.onCompleted: sourceModel = Plasmoid.systemTrayModel
    }

    Instantiator {
        model: wifiModel

        delegate: QtObject {
            required property QtObject applet
            required property bool hasApplet
            required property string iconName
            required property string displayText

            function sync() {
                grid.wifiApplet = hasApplet && applet ? applet : null;
                grid.wifiIcon = iconName;
                grid.wifiTitle = applet && applet.Plasmoid && applet.Plasmoid.title
                    ? applet.Plasmoid.title
                    : displayText;
                grid.wifiSubtitle = grid.firstLine(applet?.toolTipSubText ?? "");
            }

            Component.onCompleted: sync()
            onAppletChanged: sync()
            onHasAppletChanged: sync()
        }
    }

    Instantiator {
        model: bluetoothModel

        delegate: QtObject {
            required property QtObject applet
            required property bool hasApplet
            required property string iconName
            required property string displayText

            function sync() {
                grid.bluetoothApplet = hasApplet && applet ? applet : null;
                grid.bluetoothIcon = iconName;
                grid.bluetoothTitle = applet && applet.Plasmoid && applet.Plasmoid.title
                    ? applet.Plasmoid.title
                    : displayText;
                grid.bluetoothSubtitle = grid.firstLine(applet?.toolTipSubText ?? "");
            }

            Component.onCompleted: sync()
            onAppletChanged: sync()
            onHasAppletChanged: sync()
        }
    }

    Instantiator {
        model: notificationsModel

        delegate: QtObject {
            required property QtObject applet
            required property bool hasApplet
            required property string iconName
            required property string displayText

            function sync() {
                grid.notificationsApplet = hasApplet && applet ? applet : null;
                grid.notificationsIcon = iconName;
                grid.notificationsTitle = applet && applet.Plasmoid && applet.Plasmoid.title
                    ? applet.Plasmoid.title
                    : displayText;
                grid.notificationsSubtitle = grid.firstLine(applet?.toolTipSubText ?? "");
            }

            Component.onCompleted: sync()
            onAppletChanged: sync()
            onHasAppletChanged: sync()
        }
    }

    AppletModule {
        applet: grid.wifiApplet
        iconName: grid.wifiIcon
        title: grid.wifiTitle
        subtitle: grid.wifiSubtitle
        sizeCode: grid.sizeOf("wifi")
        visible: grid.wifiApplet !== null

        x: grid.boxFor("wifi").x
        y: grid.boxFor("wifi").y
        width: grid.boxFor("wifi").width
        height: grid.boxFor("wifi").height

        onPopupLaunched: grid.appletPopupLaunched()
    }

    AppletModule {
        applet: grid.bluetoothApplet
        iconName: grid.bluetoothIcon
        title: grid.bluetoothTitle
        subtitle: grid.bluetoothSubtitle
        sizeCode: grid.sizeOf("bluetooth")
        visible: grid.bluetoothApplet !== null

        x: grid.boxFor("bluetooth").x
        y: grid.boxFor("bluetooth").y
        width: grid.boxFor("bluetooth").width
        height: grid.boxFor("bluetooth").height

        onPopupLaunched: grid.appletPopupLaunched()
    }

    MediaModule {
        sizeCode: grid.sizeOf("media")

        x: grid.boxFor("media").x
        y: grid.boxFor("media").y
        width: grid.boxFor("media").width
        height: grid.boxFor("media").height
    }

    DndModule {
        sizeCode: grid.sizeOf("dnd")

        x: grid.boxFor("dnd").x
        y: grid.boxFor("dnd").y
        width: grid.boxFor("dnd").width
        height: grid.boxFor("dnd").height
    }

    SoundModule {
        sizeCode: grid.sizeOf("sound")

        x: grid.boxFor("sound").x
        y: grid.boxFor("sound").y
        width: grid.boxFor("sound").width
        height: grid.boxFor("sound").height
    }

    BrightnessModule {
        sizeCode: grid.sizeOf("brightness")

        x: grid.boxFor("brightness").x
        y: grid.boxFor("brightness").y
        width: grid.boxFor("brightness").width
        height: grid.boxFor("brightness").height
    }

    AppletModule {
        applet: grid.notificationsApplet
        iconName: grid.notificationsIcon
        title: grid.notificationsTitle
        subtitle: grid.notificationsSubtitle
        sizeCode: grid.sizeOf("notifications")
        visible: grid.notificationsApplet !== null

        x: grid.boxFor("notifications").x
        y: grid.boxFor("notifications").y
        width: grid.boxFor("notifications").width
        height: grid.boxFor("notifications").height

        onPopupLaunched: grid.appletPopupLaunched()
    }
}
