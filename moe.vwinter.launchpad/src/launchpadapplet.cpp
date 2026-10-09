#include "launchpadapplet.h"

#include <KConfigLoader>
#include <KConfigSkeleton>
#include <KPluginFactory>
#include <Plasma/Containment>
#include <Plasma/Corona>

namespace
{
constexpr auto s_taskManagerId = "moe.vwinter.icontasks";

QString launcherUrl(const QString &desktopUrl)
{
    QString url = desktopUrl;
    if (!url.startsWith(QLatin1String("applications:"))) {
        url.prepend(QLatin1String("applications:"));
    }
    return url;
}

// Every v-taskmanager applet in the session, across panels and screens.
QList<Plasma::Applet *> taskManagerApplets(const Plasma::Applet *self)
{
    QList<Plasma::Applet *> result;
    const Plasma::Containment *containment = self ? self->containment() : nullptr;
    Plasma::Corona *corona = containment ? containment->corona() : nullptr;
    if (!corona) {
        return result;
    }
    const auto containments = corona->containments();
    for (Plasma::Containment *c : containments) {
        const auto applets = c->applets();
        for (Plasma::Applet *applet : applets) {
            if (applet->pluginMetaData().pluginId() == QLatin1String(s_taskManagerId)) {
                result << applet;
            }
        }
    }
    return result;
}

QStringList readLaunchers(Plasma::Applet *taskManager)
{
    KConfigLoader *scheme = taskManager->configScheme();
    if (!scheme) {
        return {};
    }
    KConfigSkeletonItem *item = scheme->findItemByName(QStringLiteral("launchers"));
    return item ? item->property().toStringList() : QStringList();
}
}

LaunchpadApplet::LaunchpadApplet(QObject *parent, const KPluginMetaData &data, const QVariantList &args)
    : Plasma::Applet(parent, data, args)
{
}

LaunchpadApplet::~LaunchpadApplet() = default;

void LaunchpadApplet::pinToTaskManager(const QString &desktopUrl)
{
    const QString url = launcherUrl(desktopUrl);
    if (url == QLatin1String("applications:")) {
        return;
    }

    const auto applets = taskManagerApplets(this);
    for (Plasma::Applet *applet : applets) {
        KConfigLoader *scheme = applet->configScheme();
        if (!scheme) {
            continue;
        }
        KConfigSkeletonItem *item = scheme->findItemByName(QStringLiteral("launchers"));
        if (!item) {
            continue;
        }
        QStringList launchers = item->property().toStringList();
        if (launchers.contains(url)) {
            continue;
        }
        launchers << url;
        item->setProperty(launchers);
        scheme->save();
        scheme->read();
        Q_EMIT scheme->configChanged();
    }
}

void LaunchpadApplet::unpinFromTaskManager(const QString &desktopUrl)
{
    const QString url = launcherUrl(desktopUrl);
    if (url == QLatin1String("applications:")) {
        return;
    }

    const auto applets = taskManagerApplets(this);
    for (Plasma::Applet *applet : applets) {
        KConfigLoader *scheme = applet->configScheme();
        if (!scheme) {
            continue;
        }
        KConfigSkeletonItem *item = scheme->findItemByName(QStringLiteral("launchers"));
        if (!item) {
            continue;
        }
        QStringList launchers = item->property().toStringList();
        if (!launchers.removeAll(url)) {
            continue;
        }
        item->setProperty(launchers);
        scheme->save();
        scheme->read();
        Q_EMIT scheme->configChanged();
    }
}

bool LaunchpadApplet::isPinnedToTaskManager(const QString &desktopUrl) const
{
    const QString url = launcherUrl(desktopUrl);
    const auto applets = taskManagerApplets(this);
    for (Plasma::Applet *applet : applets) {
        if (readLaunchers(applet).contains(url)) {
            return true;
        }
    }
    return false;
}

K_PLUGIN_CLASS_WITH_JSON(LaunchpadApplet, "metadata.json")

#include "launchpadapplet.moc"
