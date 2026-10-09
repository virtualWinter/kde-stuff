import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    Plasmoid.title: i18n("v-launchpad")
    toolTipMainText: i18n("v-launchpad")
    toolTipSubText: i18n("Show all applications")

    // ------------------------------------------------------------------
    // Configuration
    // ------------------------------------------------------------------
    readonly property string iconNameOverride: Plasmoid.configuration.iconName || ""
    readonly property string iconSource: iconNameOverride.length > 0 ? iconNameOverride : "applications-other"
    readonly property int columns: Plasmoid.configuration.columns
    readonly property int rows: Plasmoid.configuration.rows
    readonly property int cellSize: Plasmoid.configuration.cellSize
    readonly property var hiddenApplicationIds: Plasmoid.configuration.hiddenApplications || []
    readonly property int contentPadding: Plasmoid.configuration.contentPadding
    readonly property real applicationIconScale: Plasmoid.configuration.applicationIconScale / 100
    readonly property real panelIconScale: Plasmoid.configuration.panelIconScale / 100
    readonly property int pageTransitionDuration: Plasmoid.configuration.pageTransitionDuration
    readonly property int touchpadSwipeThreshold: Plasmoid.configuration.touchpadSwipeThreshold
    readonly property bool showLabels: Plasmoid.configuration.showLabels
    readonly property bool showSearch: Plasmoid.configuration.showSearch
    readonly property bool showPageIndicators: Plasmoid.configuration.showPageIndicators
    readonly property bool closeOnLaunch: Plasmoid.configuration.closeOnLaunch
    readonly property bool closeOnBackgroundClick: Plasmoid.configuration.closeOnBackgroundClick

    // ------------------------------------------------------------------
    // Application model
    // ------------------------------------------------------------------
    Kicker.RootModel {
        id: rootModel

        appletInterface: root
        flat: true
        sorted: true
        showAllApps: true
        showAllAppsCategorized: false
        autoPopulate: true

        onCountChanged: root.findAllAppsModel()
    }

    property var allAppsModel: null

    ListModel {
        id: gridModel
    }

    property int gridRevision: 0

    Timer {
        id: gridModelUpdateTimer

        interval: 1
        repeat: false
        onTriggered: root.rebuildGridModel()
    }

    function scheduleGridModelRebuild() {
        gridModelUpdateTimer.restart();
    }

    function rebuildGridModel() {
        gridModel.clear();

        const pageSize = Math.max(1, root.columns * root.rows);
        const pageCount = Math.ceil(searchProxy.count / pageSize);

        for (let page = 0; page < pageCount; ++page) {
            const pageEntries = [];

            for (let visualIndex = 0; visualIndex < pageSize; ++visualIndex) {
                const sourceIndex = page * pageSize + visualIndex;
                if (sourceIndex < searchProxy.count) {
                    const app = searchProxy.get(sourceIndex);
                    pageEntries.push({
                        "applicationId": String(app.favoriteId ?? ""),
                        "appUrl": String(app.url ?? ""),
                        "decoration": app.decoration,
                        "display": app.display ?? "",
                        "placeholder": false,
                        "sourceIndex": sourceIndex
                    });
                } else {
                    pageEntries.push({
                        "applicationId": "",
                        "appUrl": "",
                        "decoration": "",
                        "display": "",
                        "placeholder": true,
                        "sourceIndex": -1
                    });
                }
            }

            // GridView flows down columns to make pages horizontal. Store a
            // row-major page in its column-major source order instead.
            for (let column = 0; column < root.columns; ++column) {
                for (let row = 0; row < root.rows; ++row) {
                    gridModel.append(pageEntries[row * root.columns + column]);
                }
            }
        }
        ++root.gridRevision;
    }

    function isApplicationHidden(applicationId) {
        return hiddenApplicationIds.indexOf(String(applicationId)) !== -1;
    }

    function refreshHiddenApplicationsFilter() {
        hiddenAppsProxy.filterCallback = function(sourceRow, applicationId) {
            return !root.isApplicationHidden(applicationId);
        };
        root.scheduleGridModelRebuild();
    }

    function findAllAppsModel() {
        for (let i = 0; i < rootModel.count; ++i) {
            const model = rootModel.modelForRow(i);
            if (model && model.description === "KICKER_ALL_MODEL") {
                root.allAppsModel = model;
                root.scheduleGridModelRebuild();
                return;
            }
        }
        root.allAppsModel = null;
        root.scheduleGridModelRebuild();
    }

    P5Support.SortFilterModel {
        id: hiddenAppsProxy

        sourceModel: root.allAppsModel
        filterRole: "favoriteId"
    }

    P5Support.SortFilterModel {
        id: searchProxy

        sourceModel: hiddenAppsProxy
        filterRole: "display"

        onCountChanged: root.scheduleGridModelRebuild()
    }

    Connections {
        target: searchProxy

        function onDataChanged() { root.scheduleGridModelRebuild(); }
        function onModelReset() { root.scheduleGridModelRebuild(); }
        function onLayoutChanged() { root.scheduleGridModelRebuild(); }
        function onRowsMoved() { root.scheduleGridModelRebuild(); }
    }

    property string searchText: ""

    onColumnsChanged: root.scheduleGridModelRebuild()
    onRowsChanged: root.scheduleGridModelRebuild()
    onHiddenApplicationIdsChanged: root.refreshHiddenApplicationsFilter()

    Component.onCompleted: {
        root.findAllAppsModel();
        root.refreshHiddenApplicationsFilter();
    }

    // Helper item carrying the automatic drag started from a tile; see
    // performDrag() in the delegate.
    Item {
        id: dragSource

        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction | Qt.LinkAction | Qt.MoveAction
    }

    // ------------------------------------------------------------------
    // Launcher popup
    // ------------------------------------------------------------------
    function toggleLauncher() {
        root.expanded = !root.expanded;
    }

    function launch(modelIndex) {
        if (!root.allAppsModel || gridModelUpdateTimer.running
                || modelIndex < 0 || modelIndex >= searchProxy.count) {
            return;
        }

        const visibleIndex = searchProxy.mapToSource(searchProxy.index(modelIndex, 0));
        const sourceIndex = hiddenAppsProxy.mapToSource(visibleIndex);
        if (!sourceIndex || !sourceIndex.valid) {
            return;
        }
        root.allAppsModel.trigger(sourceIndex.row, "", null);

        if (root.closeOnLaunch) {
            root.expanded = false;
        }
    }

    function launchGridIndex(gridIndex) {
        if (gridIndex < 0 || gridIndex >= gridModel.count) {
            return;
        }
        const entry = gridModel.get(gridIndex);
        if (!entry.placeholder) {
            root.launch(entry.sourceIndex);
        }
    }

    // ------------------------------------------------------------------
    // Pin to Task Manager
    // ------------------------------------------------------------------
    readonly property Component tileMenuComponent: Qt.createComponent("TileMenu.qml")

    function createTileMenu(visualParentItem, appId, appName) {
        if (tileMenuComponent.status !== Component.Ready) {
            return null;
        }
        return tileMenuComponent.createObject(visualParentItem, {
            "visualParent": visualParentItem,
            "appId": appId,
            "appName": appName,
        });
    }

    // The C++ backend edits the launchers of every v-taskmanager widget of the
    // session directly, so no plasmashell scripting round-trip is involved.
    function pinToTaskManager(applicationId) {
        const id = String(applicationId ?? "");
        if (id.length > 0) {
            Plasmoid.pinToTaskManager(id);
        }
    }

    function unpinFromTaskManager(applicationId) {
        const id = String(applicationId ?? "");
        if (id.length > 0) {
            Plasmoid.unpinFromTaskManager(id);
        }
    }

    function isPinnedToTaskManager(applicationId) {
        const id = String(applicationId ?? "");
        return id.length > 0 && Plasmoid.isPinnedToTaskManager(id);
    }

    // ------------------------------------------------------------------
    // Launcher content
    // ------------------------------------------------------------------
    fullRepresentation: Item {
        id: launcherContent

        // The popup hugs its content: both the minimum and maximum are pinned
        // to the computed size, which also overrides any size the shell
        // persisted for the popup from an earlier session.
        readonly property int computedWidth: Math.round(contentColumn.implicitWidth + root.contentPadding * 2)
        readonly property int computedHeight: Math.round(contentColumn.implicitHeight + root.contentPadding * 2)

        Layout.preferredWidth: computedWidth
        Layout.minimumWidth: computedWidth
        Layout.maximumWidth: computedWidth
        Layout.preferredHeight: computedHeight
        Layout.minimumHeight: computedHeight
        Layout.maximumHeight: computedHeight

        implicitWidth: computedWidth
        implicitHeight: computedHeight

        Connections {
            target: root

            function onGridRevisionChanged() {
                appGrid.resetToFirstPage();
                appGrid.currentIndex = appGrid.count > 0 ? 0 : -1;
            }
        }

        Keys.onEscapePressed: {
            if (searchField.text.length > 0) {
                searchField.text = "";
            } else {
                root.expanded = false;
            }
        }

        onVisibleChanged: {
            if (visible) {
                searchField.text = "";
                appGrid.resetToFirstPage();
                searchField.forceActiveFocus(Qt.OtherFocusReason);
            } else {
                appGrid.resetToFirstPage();
            }
        }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        if (root.closeOnBackgroundClick) {
                            root.expanded = false;
                        }
                    }
                }

                ColumnLayout {
                    id: contentColumn

                    anchors.fill: parent
                    anchors.margins: root.contentPadding
                    spacing: 0

                    PlasmaExtras.SearchField {
                        id: searchField

                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Math.min(Kirigami.Units.gridUnit * 16, root.columns * root.cellSize * 0.7)
                        Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.8)
                        visible: root.showSearch
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize
                        placeholderText: i18n("Search…")

                        onTextChanged: {
                            root.searchText = text;
                            searchProxy.filterString = text;
                            appGrid.positionViewAtBeginning();
                        }

                        Keys.onReturnPressed: {
                            if (appGrid.count > 0) {
                                root.launchGridIndex(appGrid.currentIndex >= 0 ? appGrid.currentIndex : 0);
                            }
                        }
                    }

                    Item {
                        id: gridArea

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        implicitWidth: root.columns * root.cellSize
                        implicitHeight: root.rows * root.cellSize

                        readonly property int cellWidth: Math.floor(width / root.columns)
                        readonly property int cellHeight: Math.floor(height / root.rows)

                        GridView {
                            id: appGrid

                            anchors.centerIn: parent
                            width: root.columns * gridArea.cellWidth
                            height: root.rows * gridArea.cellHeight

                            cellWidth: gridArea.cellWidth
                            cellHeight: gridArea.cellHeight

                            flow: GridView.FlowTopToBottom
                            flickableDirection: Flickable.HorizontalFlick
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true
                            cacheBuffer: width * 2
                            reuseItems: false

                            model: gridModel

                            readonly property int pageCount: Math.max(1, Math.ceil(searchProxy.count / Math.max(1, root.columns * root.rows)))
                            readonly property int currentPage: Math.round(contentX / Math.max(1, width))
                            property int wheelStartPage: 0
                            property real wheelDelta: 0
                            property bool wheelPageCommitted: false

                            onMovementStarted: snapAnimation.stop()
                            onMovementEnded: snapToPage(Math.round(contentX / Math.max(1, width)))

                            function snapToPage(page) {
                                const pageTarget = Math.max(0, Math.min(pageCount - 1, page)) * width;
                                const maximumContentX = Math.max(0, contentWidth - width);
                                snapAnimation.to = Math.min(pageTarget, maximumContentX);
                                snapAnimation.restart();
                            }

                            function resetToFirstPage() {
                                snapAnimation.stop();
                                wheelGestureTimer.stop();
                                contentX = 0;
                                wheelDelta = 0;
                                wheelPageCommitted = false;
                            }

                            Timer {
                                id: wheelGestureTimer

                                interval: 300
                                repeat: false
                                onTriggered: {
                                    if (!appGrid.wheelPageCommitted) {
                                        appGrid.snapToPage(appGrid.currentPage);
                                    }
                                    appGrid.wheelDelta = 0;
                                    appGrid.wheelPageCommitted = false;
                                }
                            }

                            WheelHandler {
                                target: null

                                onWheel: event => {
                                    const pixelDelta = Math.abs(event.pixelDelta.x) > Math.abs(event.pixelDelta.y)
                                        ? event.pixelDelta.x : event.pixelDelta.y;
                                    const delta = pixelDelta !== 0
                                        ? pixelDelta
                                        : (Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y)
                                            ? event.angleDelta.x : event.angleDelta.y);

                                    if (delta === 0) {
                                        return;
                                    }

                                    if (!wheelGestureTimer.running) {
                                        appGrid.wheelStartPage = appGrid.currentPage;
                                        appGrid.wheelDelta = 0;
                                        appGrid.wheelPageCommitted = false;
                                    }

                                    appGrid.wheelDelta += delta;
                                    if (!appGrid.wheelPageCommitted
                                            && Math.abs(appGrid.wheelDelta) >= root.touchpadSwipeThreshold) {
                                        appGrid.snapToPage(appGrid.wheelStartPage + (appGrid.wheelDelta < 0 ? 1 : -1));
                                        appGrid.wheelPageCommitted = true;
                                    }

                                    wheelGestureTimer.restart();
                                    event.accepted = true;
                                }
                            }

                            NumberAnimation {
                                id: snapAnimation

                                target: appGrid
                                property: "contentX"
                                duration: root.pageTransitionDuration
                                easing.type: Easing.OutCubic
                            }

                            delegate: PlasmaComponents3.ItemDelegate {
                                id: tile

                                width: appGrid.cellWidth
                                height: appGrid.cellHeight

                                leftPadding: 0
                                rightPadding: 0
                                topPadding: 0
                                bottomPadding: 0

                                readonly property int iconSize: Math.max(
                                    Kirigami.Units.iconSizes.smallMedium,
                                    Math.min(appGrid.cellWidth, appGrid.cellHeight) * root.applicationIconScale)

                                visible: !model.placeholder
                                enabled: !model.placeholder

                                // Dragging an icon out carries the application
                                // .desktop file, e.g. to drop it onto the task
                                // manager to pin it.
                                function performDrag(handler) {
                                    if (!handler.active) {
                                        dragSource.Drag.active = false;
                                        dragSource.Drag.imageSource = "";
                                        return;
                                    }
                                    tile.grabToImage(function(result) {
                                        if (!handler.active) {
                                            return;
                                        }
                                        dragSource.Drag.imageSource = result.url;
                                        dragSource.Drag.mimeData = { "text/uri-list": [model.appUrl] };
                                        dragSource.Drag.active = true;
                                    });
                                }

                                DragHandler {
                                    id: dragHandler
                                    acceptedButtons: Qt.LeftButton
                                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
                                    enabled: !model.placeholder && (model.appUrl ?? "") !== ""
                                    target: null
                                    onActiveChanged: tile.performDrag(this)
                                }

                                background: Rectangle {
                                    radius: Kirigami.Units.smallSpacing
                                    color: tile.pressed || tile.hovered
                                        ? Qt.rgba(1, 1, 1, tile.pressed ? 0.2 : 0.12)
                                        : "transparent"
                                }

                                contentItem: Item {
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        width: parent.width
                                        spacing: Kirigami.Units.smallSpacing

                                        Kirigami.Icon {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.preferredWidth: tile.iconSize
                                            Layout.preferredHeight: tile.iconSize
                                            source: model.decoration
                                            animated: false
                                        }

                                        PlasmaComponents3.Label {
                                            Layout.fillWidth: true
                                            visible: root.showLabels
                                            horizontalAlignment: Text.AlignHCenter
                                            maximumLineCount: 2
                                            wrapMode: Text.Wrap
                                            elide: Text.ElideRight
                                            color: "white"
                                            text: model.display ?? ""
                                        }
                                    }
                                }

                                onClicked: {
                                    if (!dragHandler.active) {
                                        root.launch(model.sourceIndex);
                                    }
                                }

                                // Right-click opens a small menu, e.g. to pin
                                // the application to the task manager.
                                TapHandler {
                                    id: tileMenuClickHandler
                                    acceptedButtons: Qt.RightButton
                                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
                                    gesturePolicy: TapHandler.WithinBounds
                                    enabled: !model.placeholder && (model.appUrl ?? "") !== ""
                                    onPressedChanged: {
                                        if (pressed) {
                                            tileMenuTimer.start();
                                        }
                                    }
                                }

                                Timer {
                                    id: tileMenuTimer
                                    interval: 0
                                    onTriggered: {
                                        const menu = root.createTileMenu(tile, model.applicationId ?? "", model.display ?? "");
                                        if (menu) {
                                            menu.show();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Kirigami.Units.smallSpacing
                        visible: root.showPageIndicators && appGrid.pageCount > 1

                        Repeater {
                            model: appGrid.pageCount

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: Qt.rgba(1, 1, 1, index === appGrid.currentPage ? 0.9 : 0.3)

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: appGrid.snapToPage(index)
                                }
                            }
                        }
                    }
                }
    }

    // ------------------------------------------------------------------
    // Panel button
    // ------------------------------------------------------------------
    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: Kirigami.Units.iconSizes.smallMedium

        Layout.minimumWidth: height
        Layout.preferredWidth: height
        Layout.minimumHeight: implicitHeight

        Rectangle {
            anchors.fill: parent
            radius: 2
            color: mouseArea.containsMouse
                ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                : "transparent"
        }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * root.panelIconScale
            height: width
            source: root.iconSource
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.toggleLauncher()
        }
    }
}
