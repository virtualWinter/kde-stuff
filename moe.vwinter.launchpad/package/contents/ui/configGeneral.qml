import QtQuick
import QtQuick.Layouts

import org.kde.iconthemes as KIconThemes
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.private.kicker as Kicker

KCM.SimpleKCM {
    id: page

    property alias cfg_iconName: iconNameField.text
    property alias cfg_panelIconScale: panelIconScaleSpin.value
    property alias cfg_columns: columnsSpin.value
    property alias cfg_rows: rowsSpin.value
    property alias cfg_cellSize: cellSizeSpin.value
    property alias cfg_applicationIconScale: applicationIconScaleSpin.value
    property alias cfg_contentPadding: contentPaddingSpin.value
    property alias cfg_pageTransitionDuration: transitionDurationSpin.value
    property alias cfg_touchpadSwipeThreshold: swipeThresholdSpin.value
    property alias cfg_showLabels: showLabelsBox.checked
    property alias cfg_showSearch: showSearchBox.checked
    property alias cfg_showPageIndicators: showPageIndicatorsBox.checked
    property alias cfg_closeOnLaunch: closeOnLaunchBox.checked
    property alias cfg_closeOnBackgroundClick: closeOnBackgroundClickBox.checked
    property var cfg_hiddenApplications: []

    KIconThemes.IconDialog {
        id: iconDialog
        onIconNameChanged: iconName => iconNameField.text = iconName
    }

    // Application list for hiding entries from the launcher grid.
    Kicker.RootModel {
        id: configAppsModel

        flat: true
        sorted: true
        showAllApps: true
        showAllAppsCategorized: false
        autoPopulate: true
        onCountChanged: page.findAllApplications()
    }

    property var allApplications: null

    function findAllApplications() {
        for (let i = 0; i < configAppsModel.count; ++i) {
            const candidate = configAppsModel.modelForRow(i);
            if (candidate && candidate.description === "KICKER_ALL_MODEL") {
                page.allApplications = candidate;
                return;
            }
        }
        page.allApplications = null;
    }

    function isApplicationHidden(applicationId) {
        const id = String(applicationId);
        for (let i = 0; i < cfg_hiddenApplications.length; ++i) {
            if (String(cfg_hiddenApplications[i]) === id) {
                return true;
            }
        }
        return false;
    }

    function setApplicationHidden(applicationId, hidden) {
        const id = String(applicationId);
        const updated = [];
        for (let i = 0; i < cfg_hiddenApplications.length; ++i) {
            if (String(cfg_hiddenApplications[i]) !== id) {
                updated.push(String(cfg_hiddenApplications[i]));
            }
        }
        if (hidden) {
            updated.push(id);
        }
        cfg_hiddenApplications = updated;
    }

    Component.onCompleted: findAllApplications()

    Kirigami.FormLayout {
        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Kirigami.FormData.label: i18n("Panel button icon:")

            PlasmaComponents3.TextField {
                id: iconNameField
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                placeholderText: i18n("Automatic (applications-other)")
            }

            PlasmaComponents3.Button {
                text: i18n("Choose…")
                onClicked: iconDialog.open()
            }
        }

        PlasmaComponents3.SpinBox {
            id: panelIconScaleSpin
            Kirigami.FormData.label: i18n("Panel icon size (%):")
            from: 50
            to: 100
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Grid")
        }

        PlasmaComponents3.SpinBox {
            id: columnsSpin
            Kirigami.FormData.label: i18n("Icons per row:")
            from: 3
            to: 12
        }

        PlasmaComponents3.SpinBox {
            id: rowsSpin
            Kirigami.FormData.label: i18n("Rows per page:")
            from: 3
            to: 8
        }

        PlasmaComponents3.SpinBox {
            id: cellSizeSpin
            Kirigami.FormData.label: i18n("Cell size (pixels):")
            from: 48
            to: 200
            stepSize: 4
        }

        PlasmaComponents3.SpinBox {
            id: applicationIconScaleSpin
            Kirigami.FormData.label: i18n("Icon size (% of cell):")
            from: 20
            to: 80
        }

        PlasmaComponents3.SpinBox {
            id: contentPaddingSpin
            Kirigami.FormData.label: i18n("Content padding (pixels):")
            from: 0
            to: 48
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Behavior")
        }

        PlasmaComponents3.CheckBox {
            id: showLabelsBox
            text: i18n("Show application names")
        }

        PlasmaComponents3.CheckBox {
            id: showSearchBox
            text: i18n("Show the search field")
        }

        PlasmaComponents3.CheckBox {
            id: showPageIndicatorsBox
            text: i18n("Show page indicators")
        }

        PlasmaComponents3.CheckBox {
            id: closeOnLaunchBox
            text: i18n("Close after launching an application")
        }

        PlasmaComponents3.CheckBox {
            id: closeOnBackgroundClickBox
            text: i18n("Close when an empty area is clicked")
        }

        PlasmaComponents3.SpinBox {
            id: transitionDurationSpin
            Kirigami.FormData.label: i18n("Page transition (ms):")
            from: 0
            to: 1000
            stepSize: 50
        }

        PlasmaComponents3.SpinBox {
            id: swipeThresholdSpin
            Kirigami.FormData.label: i18n("Touchpad swipe distance:")
            from: 1
            to: 120
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Applications")
        }

        PlasmaComponents3.Label {
            Kirigami.FormData.label: i18n("Hidden:")
            text: i18n("Uncheck an application to hide it from Launchpad.")
        }

        Repeater {
            model: page.allApplications

            PlasmaComponents3.CheckBox {
                text: model.display
                checked: !page.isApplicationHidden(model.favoriteId)
                onToggled: page.setApplicationHidden(model.favoriteId, !checked)
            }
        }
    }
}
