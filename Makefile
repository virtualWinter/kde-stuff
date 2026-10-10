# Monorepo root: build/install every add-on.
#
#   make build      compile the compiled plugins without installing
#   make install    install all add-ons (builds the compiled plugins)
#   make plugin     build and install the compiled plugins
#   make restart    restart plasmashell
#   make uninstall  remove all add-ons
#   make clean      remove build outputs

ADDONS := moe.vwinter.applemenu moe.vwinter.launchpad moe.vwinter.icontasks moe.vwinter.appmenu moe.vwinter.systemtray
COMPILED := moe.vwinter.appmenu moe.vwinter.launchpad moe.vwinter.systemtray
PLUGIN_DIR := $(HOME)/.local/lib/qt6/plugins

.PHONY: all build install plugin uninstall restart clean

all: build

build:
	@for d in $(COMPILED); do \
		$(MAKE) --no-print-directory -C $$d build || exit 1; \
	done

install:
	@for d in $(ADDONS); do \
		echo "== $$d"; \
		$(MAKE) --no-print-directory -C $$d install || exit 1; \
	done

plugin:
	@for d in $(COMPILED); do \
		$(MAKE) --no-print-directory -C $$d plugin || exit 1; \
	done

uninstall:
	@for d in $(ADDONS); do \
		echo "== $$d"; \
		$(MAKE) --no-print-directory -C $$d uninstall || true; \
	done

restart:
	QT_PLUGIN_PATH="$(PLUGIN_DIR)$${QT_PLUGIN_PATH:+:$$QT_PLUGIN_PATH}" setsid -f plasmashell --replace >/dev/null 2>&1

clean:
	@for d in $(COMPILED); do \
		$(MAKE) --no-print-directory -C $$d clean || true; \
	done
