#pragma once

// Qt
#include <QMetaType>
#include <QStringList>

class QKeySequence;

class DBusMenuShortcut : public QList<QStringList>
{
public:
    QKeySequence toKeySequence() const;
    static DBusMenuShortcut fromKeySequence(const QKeySequence &);
};
