#pragma once

#include <QChar>

class QString;

/**
 * Swap mnemonic char: Qt uses '&', while dbusmenu uses '_'
 */
QString swapMnemonicChar(const QString &in, QChar src, QChar dst);
