// Upstream plasma-workspace generates this via CMake (config-X11.h.cmake).
// The applet only uses it to guard a KWindowSystem::isPlatformX11() branch,
// which is a runtime check and pulls in no X11 headers or libraries, so it is
// safe to enable unconditionally.
#pragma once

#define HAVE_X11 1
#define HAVE_XCURSOR 1
#define HAVE_XFIXES 1
