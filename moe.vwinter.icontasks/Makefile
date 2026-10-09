PLASMOID_ID := moe.vwinter.icontasks
PACKAGE_DIR := package

.PHONY: all install upgrade uninstall restart

all: install

install:
	@if kpackagetool6 --type Plasma/Applet --upgrade $(PACKAGE_DIR) >/dev/null 2>&1; then \
		echo "Upgraded $(PLASMOID_ID)"; \
	else \
		kpackagetool6 --type Plasma/Applet --install $(PACKAGE_DIR); \
	fi

upgrade:
	kpackagetool6 --type Plasma/Applet --upgrade $(PACKAGE_DIR)

uninstall:
	kpackagetool6 --type Plasma/Applet --remove $(PLASMOID_ID)

restart:
	QT_PLUGIN_PATH=$(HOME)/.local/lib/qt6/plugins setsid -f plasmashell --replace >/dev/null 2>&1
