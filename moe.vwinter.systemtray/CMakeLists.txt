cmake_minimum_required(VERSION 3.16)
project(v-systemtray VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_MODULE_PATH})
set(QT_MAJOR_VERSION 6)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMQtDeclareLoggingCategory)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Quick DBus)
find_package(Qt6GuiPrivate REQUIRED)
find_package(KF6 REQUIRED COMPONENTS Config CoreAddons IconThemes I18n KIO JobWidgets Service ItemModels WindowSystem XmlGui)
find_package(KF6StatusNotifierItem REQUIRED)
find_package(Plasma REQUIRED)
find_package(PlasmaQuick REQUIRED)

# ---------------------------------------------------------------------------
# Bundled libdbusmenuqt, vendored from plasma-workspace (GPL-2.0-or-later).
# Built in its own subdirectory so its generated debug.h does not collide with
# the applet's own logging category header.
# ---------------------------------------------------------------------------
add_subdirectory(vendor/libdbusmenuqt)

# ---------------------------------------------------------------------------
# System tray backend (status notifier host/model, plasmoid registry).
# ---------------------------------------------------------------------------
add_definitions(-DTRANSLATION_DOMAIN=\"plasma_applet_moe.vwinter.systemtray\")

set(systemtray_SRCS
    src/dbusserviceobserver.cpp src/dbusserviceobserver.h
    src/plasmoidregistry.cpp src/plasmoidregistry.h
    src/statusnotifieritemhost.cpp src/statusnotifieritemhost.h
    src/statusnotifieritemsource.cpp src/statusnotifieritemsource.h
    src/systemtraysettings.cpp src/systemtraysettings.h
    src/systemtraytypes.cpp
    src/systemtraymodel.cpp
    src/sortedsystemtraymodel.cpp src/sortedsystemtraymodel.h
)

qt_add_dbus_interface(systemtray_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/vendor/dbus/kf6_org.kde.StatusNotifierWatcher.xml statusnotifierwatcher_interface)
qt_add_dbus_interface(systemtray_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/vendor/dbus/org.freedesktop.DBus.Properties.xml dbusproperties)

set(statusnotifieritem_xml ${CMAKE_CURRENT_SOURCE_DIR}/vendor/dbus/kf6_org.kde.StatusNotifierItem.xml)
set_source_files_properties(${statusnotifieritem_xml} PROPERTIES
    NO_NAMESPACE false
    INCLUDE "systemtraytypes.h"
    CLASSNAME OrgKdeStatusNotifierItem
)
qt_add_dbus_interface(systemtray_SRCS ${statusnotifieritem_xml} statusnotifieritem_interface)

ecm_qt_declare_logging_category(systemtray_SRCS HEADER debug.h
    IDENTIFIER SYSTEM_TRAY
    CATEGORY_NAME kde.systemtray
    DEFAULT_SEVERITY Info
    DESCRIPTION "plasma applet systemtray"
)

add_library(systemtray_static STATIC ${systemtray_SRCS})
target_include_directories(systemtray_static PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src ${CMAKE_CURRENT_BINARY_DIR})
target_link_libraries(systemtray_static
    PUBLIC
        Qt::DBus
        Qt::Gui
        Qt::GuiPrivate
        Qt::Quick
        KF6::ConfigCore
        KF6::IconThemes
        KF6::I18n
        KF6::KIOGui
        KF6::JobWidgets
        KF6::Service
        KF6::ItemModels
        KF6::WindowSystem
        KF6::XmlGui
        Plasma::Plasma
        Plasma::PlasmaQuick
        dbusmenuqt
)
set_property(TARGET systemtray_static PROPERTY POSITION_INDEPENDENT_CODE ON)

# ---------------------------------------------------------------------------
# The applet
# ---------------------------------------------------------------------------
plasma_add_applet(moe.vwinter.systemtray
    CPP_SOURCES
        src/systemtray.cpp
    QML_SOURCES
        package/contents/ui/AbstractItem.qml
        package/contents/ui/BackgroundAppItem.qml
        package/contents/ui/ConfigGeneral.qml
        package/contents/ui/CurrentItemHighLight.qml
        package/contents/ui/ExpanderArrow.qml
        package/contents/ui/ItemLoader.qml
        package/contents/ui/PlasmoidItem.qml
        package/contents/ui/PulseAnimation.qml
        package/contents/ui/SystemTrayState.qml
        package/contents/ui/CompactApplet.qml
        package/contents/ui/config.qml
        package/contents/ui/ExpandedRepresentation.qml
        package/contents/ui/HiddenItemsView.qml
        package/contents/ui/main.qml
        package/contents/ui/PlasmoidPopupsContainer.qml
        package/contents/ui/StatusNotifierItem.qml
    RESOURCES
        package/contents/config/main.xml
    QML_ARGS DEPENDENCIES QtCore org.kde.plasma.core
)

target_include_directories(moe.vwinter.systemtray PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_libraries(moe.vwinter.systemtray PRIVATE systemtray_static)
