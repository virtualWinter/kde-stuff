PLASMOID_ID := moe.vwinter.launchpad
PACKAGE_DIR := package
BUILD_DIR := build
PLUGIN_DIR ?= $(HOME)/.local/lib/qt6/plugins/plasma/applets
CMAKE ?= cmake
JOBS ?= $(shell nproc)
ECM_PREFIX ?= $(patsubst %/share/ECM/cmake/ECMConfig.cmake,%,$(firstword $(wildcard /usr/share/ECM/cmake/ECMConfig.cmake /usr/local/share/ECM/cmake/ECMConfig.cmake)))
PLUGIN_SO := $(BUILD_DIR)/bin/plasma/applets/$(PLASMOID_ID).so

.PHONY: all build compile install kpackage plugin upgrade uninstall restart clean

all: install

# Full install: the KPackage (metadata/config) and the compiled plugin.
install: plugin
	@$(MAKE) --no-print-directory kpackage

# Compile the plugin without installing it.
build: compile
	@echo "Built $(PLUGIN_SO) (not installed)"

# Build and install the plugin (this is what makes the widget appear).
plugin: compile
	@mkdir -p "$(PLUGIN_DIR)"
	install -m755 "$(PLUGIN_SO)" "$(PLUGIN_DIR)/$(PLASMOID_ID).so"
	@echo "Installed $(PLUGIN_DIR)/$(PLASMOID_ID).so"
	@if ! grep -rqs "QT_PLUGIN_PATH=.*$(patsubst %/plasma/applets,%,$(PLUGIN_DIR))" "$(HOME)/.config/environment.d/" 2>/dev/null; then \
		echo ""; \
		echo "note: plasmashell must search user plugins. Add to ~/.config/environment.d/vwinter.conf:"; \
		echo "      QT_PLUGIN_PATH=$(patsubst %/plasma/applets,%,$(PLUGIN_DIR))"; \
	fi

# Configure and compile with cmake. Needs cmake and extra-cmake-modules.
compile:
	@command -v "$(CMAKE)" >/dev/null 2>&1 || { echo "error: cmake not found — install cmake (see README)" >&2; exit 1; }
	@test -n "$(ECM_PREFIX)" || { echo "error: extra-cmake-modules not found — install it (see README)" >&2; exit 1; }
	@mkdir -p "$(BUILD_DIR)"
	@$(CMAKE) -S . -B "$(BUILD_DIR)" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(ECM_PREFIX)" >"$(BUILD_DIR)/configure.log" 2>&1 || { tail -n 20 "$(BUILD_DIR)/configure.log" >&2; exit 1; }
	@$(CMAKE) --build "$(BUILD_DIR)" --parallel "$(JOBS)" >"$(BUILD_DIR)/build.log" 2>&1 || { tail -n 30 "$(BUILD_DIR)/build.log" >&2; exit 1; }

# Install or upgrade the KPackage (metadata and config pages).
kpackage:
	@if kpackagetool6 --type Plasma/Applet --upgrade $(PACKAGE_DIR) >/dev/null 2>&1; then \
		echo "Upgraded $(PLASMOID_ID)"; \
	else \
		kpackagetool6 --type Plasma/Applet --install $(PACKAGE_DIR); \
	fi

upgrade: install

uninstall:
	kpackagetool6 --type Plasma/Applet --remove $(PLASMOID_ID)
	rm -f "$(PLUGIN_DIR)/$(PLASMOID_ID).so"

restart:
	QT_PLUGIN_PATH="$(patsubst %/plasma/applets,%,$(PLUGIN_DIR))$${QT_PLUGIN_PATH:+:$$QT_PLUGIN_PATH}" setsid -f plasmashell --replace >/dev/null 2>&1

clean:
	rm -rf "$(BUILD_DIR)"
