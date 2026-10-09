cmake_minimum_required(VERSION 3.16)
project(v-appmenu VERSION 0.1.0)

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

# KDECMakeSettings only sets these when it knows the ECM version, so make sure
# the plugin ends up in <build>/bin/plasma/applets.
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

find_package(Qt6 REQUIRED COMPONENTS Core Widgets Quick DBus)
find_package(KF6 REQUIRED COMPONENTS Config CoreAddons WindowSystem I18n)
find_package(Plasma REQUIRED)
find_package(LibTaskManager REQUIRED)

# ---------------------------------------------------------------------------
# Bundled libdbusmenuqt, vendored from plasma-workspace (GPL-2.0-or-later).
# The DBus proxy (dbusmenu_interface.{h,cpp}) is generated at build time from
# the Canonical DBusMenu XML.
# ---------------------------------------------------------------------------
set(DBUSMENU_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor/libdbusmenuqt" CACHE PATH "libdbusmenuqt source directory")

set(libdbusmenu_SRCS
    ${DBUSMENU_SRC_DIR}/dbusmenuimporter.cpp
    ${DBUSMENU_SRC_DIR}/dbusmenushortcut_p.cpp
    ${DBUSMENU_SRC_DIR}/dbusmenutypes_p.cpp
    ${DBUSMENU_SRC_DIR}/utils.cpp
    ${DBUSMENU_SRC_DIR}/dbusmenuimporter.h
    ${DBUSMENU_SRC_DIR}/dbusmenushortcut_p.h
    ${DBUSMENU_SRC_DIR}/dbusmenutypes_p.h
    ${DBUSMENU_SRC_DIR}/utils_p.h
)

ecm_qt_declare_logging_category(libdbusmenu_SRCS HEADER debug.h
    IDENTIFIER DBUSMENUQT
    CATEGORY_NAME org.kde.libdbusmenuqt
    DEFAULT_SEVERITY Info
    DESCRIPTION "libdbusmenu debug"
)

set_source_files_properties(${DBUSMENU_SRC_DIR}/com.canonical.dbusmenu.xml PROPERTIES
    NO_NAMESPACE true
    INCLUDE "dbusmenutypes_p.h"
    CLASSNAME DBusMenuInterface
)
qt_add_dbus_interface(libdbusmenu_SRCS ${DBUSMENU_SRC_DIR}/com.canonical.dbusmenu.xml dbusmenu_interface)

add_library(dbusmenuqt STATIC ${libdbusmenu_SRCS})
target_include_directories(dbusmenuqt PUBLIC ${DBUSMENU_SRC_DIR} ${CMAKE_CURRENT_BINARY_DIR})
target_link_libraries(dbusmenuqt PUBLIC Qt::DBus Qt::Widgets)

# ---------------------------------------------------------------------------
# The applet
# ---------------------------------------------------------------------------
add_definitions(-DTRANSLATION_DOMAIN=\"plasma_applet_moe.vwinter.appmenu\")

plasma_add_applet(moe.vwinter.appmenu
    QML_SOURCES
        package/contents/ui/configGeneral.qml
        package/contents/ui/config.qml
        package/contents/ui/main.qml
        package/contents/ui/MenuDelegate.qml
    CPP_SOURCES
        src/appmenuapplet.cpp
        src/appmenumodel.cpp
    RESOURCES
        package/contents/config/main.xml
    QML_ARGS DEPENDENCIES QtCore org.kde.plasma.core
)

# The generated QML type registration includes <appmenumodel.h>.
target_include_directories(moe.vwinter.appmenu PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(moe.vwinter.appmenu PRIVATE
    Qt::Core
    Qt::Widgets
    Qt::Quick
    Qt::DBus
    Plasma::Plasma
    KF6::WindowSystem
    KF6::I18n
    PW::LibTaskManager
    dbusmenuqt
)
