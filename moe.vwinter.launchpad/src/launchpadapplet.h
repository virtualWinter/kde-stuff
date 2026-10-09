#pragma once

#include <Plasma/Applet>

#include <QVariantList>

class LaunchpadApplet : public Plasma::Applet
{
    Q_OBJECT

public:
    LaunchpadApplet(QObject *parent, const KPluginMetaData &data, const QVariantList &args);
    ~LaunchpadApplet() override;

    // Pins/unpins a .desktop file in every v-taskmanager widget of the session,
    // replacing the previous plasmashell scripting round-trip.
    Q_INVOKABLE void pinToTaskManager(const QString &desktopUrl);
    Q_INVOKABLE void unpinFromTaskManager(const QString &desktopUrl);
    Q_INVOKABLE bool isPinnedToTaskManager(const QString &desktopUrl) const;
};
