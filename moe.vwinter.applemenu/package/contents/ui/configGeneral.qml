import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts

import org.kde.iconthemes as KIconThemes
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

KCM.SimpleKCM {
    id: page

    property alias cfg_iconName: iconNameField.text
    property alias cfg_menuWidth: menuWidthSpin.value
    property string cfg_menuBackgroundColor

    property alias cfg_showAbout: showAboutBox.checked
    property alias cfg_showSystemSettings: showSystemSettingsBox.checked
    property alias cfg_showSoftwareCenter: showSoftwareCenterBox.checked
    property alias cfg_showForceQuit: showForceQuitBox.checked
    property alias cfg_showScreenshot: showScreenshotBox.checked
    property alias cfg_showSleep: showSleepBox.checked
    property alias cfg_showRestart: showRestartBox.checked
    property alias cfg_showShutdown: showShutdownBox.checked
    property alias cfg_showLock: showLockBox.checked
    property alias cfg_showLogout: showLogoutBox.checked
    property alias cfg_keepGlobalMenu: keepGlobalMenuBox.checked

    KIconThemes.IconDialog {
        id: iconDialog
        onIconNameChanged: iconName => iconNameField.text = iconName
    }

    ColorDialog {
        id: colorDialog
        title: i18n("Menu Background Color")
        selectedColor: page.cfg_menuBackgroundColor.length > 0 ? page.cfg_menuBackgroundColor : Kirigami.Theme.backgroundColor
        onAccepted: page.cfg_menuBackgroundColor = selectedColor.toString()
    }

    Kirigami.FormLayout {
        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Kirigami.FormData.label: i18n("Menu button icon:")

            PlasmaComponents3.TextField {
                id: iconNameField
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                placeholderText: i18n("Automatic")
            }

            PlasmaComponents3.Button {
                text: i18n("Choose…")
                onClicked: iconDialog.open()
            }
        }

        PlasmaComponents3.SpinBox {
            id: menuWidthSpin
            Kirigami.FormData.label: i18n("Menu width (grid units):")
            from: 8
            to: 24
        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Kirigami.FormData.label: i18n("Menu background:")

            Rectangle {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                radius: height / 2
                color: page.cfg_menuBackgroundColor.length > 0 ? page.cfg_menuBackgroundColor : Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                      Kirigami.Theme.textColor.g,
                                      Kirigami.Theme.textColor.b,
                                      0.3)
            }

            PlasmaComponents3.Button {
                text: i18n("Choose…")
                onClicked: colorDialog.open()
            }

            PlasmaComponents3.Button {
                text: i18n("Default")
                enabled: page.cfg_menuBackgroundColor.length > 0
                onClicked: page.cfg_menuBackgroundColor = ""
            }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Menu entries")
        }

        PlasmaComponents3.CheckBox {
            id: showAboutBox
            text: i18n("About This System")
        }

        PlasmaComponents3.CheckBox {
            id: showSystemSettingsBox
            text: i18n("System Settings")
        }

        PlasmaComponents3.CheckBox {
            id: showSoftwareCenterBox
            text: i18n("Software Center")
        }

        PlasmaComponents3.CheckBox {
            id: showForceQuitBox
            text: i18n("Force Quit")
        }

        PlasmaComponents3.CheckBox {
            id: showScreenshotBox
            text: i18n("Take a Screenshot")
        }

        PlasmaComponents3.CheckBox {
            id: showSleepBox
            text: i18n("Sleep")
        }

        PlasmaComponents3.CheckBox {
            id: showRestartBox
            text: i18n("Restart")
        }

        PlasmaComponents3.CheckBox {
            id: showShutdownBox
            text: i18n("Shut Down")
        }

        PlasmaComponents3.CheckBox {
            id: showLockBox
            text: i18n("Lock Screen")
        }

        PlasmaComponents3.CheckBox {
            id: showLogoutBox
            text: i18n("Log Out")
        }

        PlasmaComponents3.CheckBox {
            id: keepGlobalMenuBox
            text: i18n("Keep the global menu visible while this menu is open")
        }
    }
}
