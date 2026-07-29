-- Environment variables
-- see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
-- (rewritten from env_var.conf + the two env = lines in hyprland.conf)

-- Toolkit backend variables
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Theming related variables
-- Set cursor size. See FAQ below for why you might want this variable set.
-- https://wiki.hypr.land/FAQ/
hl.env("XCURSOR_SIZE", "24")

-- Set a GTK theme manually, for those who want to avoid appearance tools such as lxappearance or nwg-look
-- hl.env("GTK_THEME", "")

-- Set your cursor theme. The theme needs to be installed and readable by your user.
-- hl.env("XCURSOR_THEME", "")

-- the line below may help with multiple monitors
-- hl.env("WLR_EGL_NO_MODIFIERS", "1")

-- XDG Specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- GTK: Use wayland if available, fall back to x11 if not.
-- hl.env("GDK_BACKEND", "wayland,x11")

-- QT: Use wayland if available, fall back to x11 if not.
-- hl.env("QT_QPA_PLATFORM", "wayland,xcb")

-- Run SDL2 applications on Wayland. Remove or set to x11 if games that
-- provide older versions of SDL cause compatibility issues
-- hl.env("SDL_VIDEODRIVER", "wayland")

-- Clutter package already has wayland enabled, this variable
-- will force Clutter applications to try and use the Wayland backend
-- hl.env("CLUTTER_BACKEND", "wayland")

-- QT Variables

-- (From the QT documentation) enables automatic scaling, based on the monitor's pixel density
-- https://doc.qt.io/qt-5/highdpi.html
-- hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

-- Disables window decorations on QT applications
-- hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- Tells QT based applications to pick your theme from qt5ct, use with Kvantum.
-- hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
