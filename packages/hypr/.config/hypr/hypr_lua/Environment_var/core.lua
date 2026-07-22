-- Toolkit Backend Variables
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- XDG Specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_MENU_PREFIX", "arch-")

-- Qt Variables
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
--env = QT_STYLE_OVERRIDE,kvantum

-- env = XDG_DATA_DIRS=$XDG_DATA_DIRS:/usr/share:/usr/local/share:~/.local/share

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("__NV_DISABLE_EXPLICIT_SYNC", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("__GL_GSYNC_ALLOWED", "1")

-- Linux Variables
hl.env("EDITOR", " nvim")

hl.env("AQ_NO_ATOMIC", "1")
