cmake_minimum_required(VERSION 3.16)
project(v-launchpad VERSION 0.1.0)

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

# KDECMakeSettings only sets these when it knows the ECM version, so make sure
# the plugin ends up in <build>/bin/plasma/applets.
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

find_package(Qt6 REQUIRED COMPONENTS Core Quick)
find_package(KF6 REQUIRED COMPONENTS Config CoreAddons I18n)
find_package(Plasma REQUIRED)

add_definitions(-DTRANSLATION_DOMAIN=\"plasma_applet_moe.vwinter.launchpad\")

plasma_add_applet(moe.vwinter.launchpad
    QML_SOURCES
        package/contents/ui/main.qml
        package/contents/ui/TileMenu.qml
    CPP_SOURCES
        src/launchpadapplet.cpp
    RESOURCES
        package/contents/config/main.xml
    QML_ARGS DEPENDENCIES QtCore org.kde.plasma.core
)

target_include_directories(moe.vwinter.launchpad PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(moe.vwinter.launchpad PRIVATE
    Qt::Core
    Qt::Quick
    Plasma::Plasma
    KF6::ConfigGui
    KF6::CoreAddons
    KF6::I18n
)
