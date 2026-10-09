import QtQuick

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

KCM.SimpleKCM {
    id: page

    property alias cfg_iconSize: iconSizeSpin.value
    property alias cfg_spacing: spacingSpin.value
    property alias cfg_dotSize: dotSizeSpin.value
    property alias cfg_focusedIndicatorWidth: focusedWidthSpin.value
    property alias cfg_useAccentDot: useAccentDotBox.checked
    property alias cfg_showAttentionDot: showAttentionDotBox.checked
    property alias cfg_minimizeActiveTaskOnClick: minimizeActiveBox.checked
    property alias cfg_showOnlyCurrentDesktop: showDesktopBox.checked
    property alias cfg_showOnlyCurrentScreen: showScreenBox.checked
    property alias cfg_showOnlyCurrentActivity: showActivityBox.checked
    property alias cfg_showLauncherSeparator: showSeparatorBox.checked

    Kirigami.FormLayout {
        PlasmaComponents3.SpinBox {
            id: iconSizeSpin
            Kirigami.FormData.label: i18n("Icon size (pixels, 0 = fit panel):")
            from: 0
            to: 128
        }

        PlasmaComponents3.SpinBox {
            id: spacingSpin
            Kirigami.FormData.label: i18n("Spacing between icons (pixels):")
            from: 0
            to: 32
        }

        PlasmaComponents3.SpinBox {
            id: dotSizeSpin
            Kirigami.FormData.label: i18n("Indicator size (pixels):")
            from: 2
            to: 16
        }

        PlasmaComponents3.SpinBox {
            id: focusedWidthSpin
            Kirigami.FormData.label: i18n("Focused task line width (pixels):")
            from: 5
            to: 64
        }

        PlasmaComponents3.CheckBox {
            id: useAccentDotBox
            text: i18n("Use accent color for the indicators (otherwise white)")
        }

        PlasmaComponents3.CheckBox {
            id: showAttentionDotBox
            text: i18n("Also show a dot when a task demands attention")
        }

        PlasmaComponents3.CheckBox {
            id: minimizeActiveBox
            text: i18n("Minimize the active task when its icon is clicked")
        }

        PlasmaComponents3.CheckBox {
            id: showDesktopBox
            text: i18n("Show only tasks from the current desktop")
        }

        PlasmaComponents3.CheckBox {
            id: showScreenBox
            text: i18n("Show only tasks from the current screen")
        }

        PlasmaComponents3.CheckBox {
            id: showActivityBox
            text: i18n("Show only tasks from the current activity")
        }

        PlasmaComponents3.CheckBox {
            id: showSeparatorBox
            text: i18n("Show a separator between pinned launchers and running apps")
        }
    }
}
