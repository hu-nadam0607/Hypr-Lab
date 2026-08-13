-- ============================================================
-- Hypr-Lab config -- migrated from hyprland.conf (hyprlang)
-- to hyprland.lua for Hyprland >= 0.55 (tested against 0.56.1)
-- Since Hyprland 0.55, hyprlang (.conf) is deprecated in favor
-- of Lua.
-- ============================================================

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

--==================================
--HYPR-LAB BORDER GLOW (Lua-native)
--==================================

local borderGlowOn = false

local function set_border_glow(enabled)
    if enabled then
        hl.config({
            general = {
                col = {
                    active_border = {
                        colors = {
                            "rgba(00ffffff)",
                            "rgba(044440ff)"
                        },
                        angle = 45,
                    },
                },
            },
        })
    else
        hl.config({
            general = {
                col = {
                    active_border =
                        "rgba(0ee3d8ff)",
                },
            },
        })
    end
end

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()

    hl.exec_cmd(
        "~/.config/hypr/hyprlab-scripts/hyprlab-xdg.sh"
    )

    -- Re-apply persistent values changed from Hypr-Lab Settings.
    hl.exec_cmd("~/.config/hypr/hyprlab-scripts/hyprlab-settings.sh apply")

    -- Hypr-Lab cursor theme (installed by installer when themes are enabled).
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Hypr-Lab 24")

    borderGlowOn = true
    set_border_glow(borderGlowOn)

    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpolkitagent")

    -- SwayNC eltávolítva.
    -- Az értesítéseket a Quickshell kezeli.
end)

--========================
--HYPR-LAB KEYBOARD LAYOUT
--========================

hl.config({
    input = {
        kb_layout = "__HYPRLAB_KB_LAYOUT__",
    },
})

--======================
--KEYBINDS IN Hypr-Lab
--======================

local terminal = "ghostty"
local mainMod   = "SUPER"

-- ============================================================
-- MAIN KEYBINDS
-- ============================================================

hl.bind(
    mainMod .. " + C",
    hl.dsp.exec_cmd(terminal),
    {
        description = "open_terminal"
    }
)

hl.bind(
    mainMod .. " + M",
    hl.dsp.exit(),
    {
        description = "quit_hyprland"
    }
)

hl.bind(
    mainMod .. " + B",
    hl.dsp.exec_cmd(
        "~/.config/hypr/settings/browser.sh"
    ),
    {
        description =
            "Open the browser declared in the sh file."
    }
)

hl.bind(
    mainMod .. " + E",
    hl.dsp.exec_cmd(
        "~/.config/hypr/settings/filemanager.sh"
    ),
    {
        description =
            "Open the file manager declared in the sh file."
    }
)

hl.bind(
    mainMod .. " + Q",
    hl.dsp.window.close(),
    {
        description = "Kill active window"
    }
)

-- ============================================================
-- HYPR-LAB NOTIFICATION CENTER
-- ============================================================

hl.bind(
    mainMod .. " + SHIFT + N",
    hl.dsp.exec_cmd(
        "qs ipc call notifications toggle"
    ),
    {
        description =
            "Open/Close Hypr-Lab notification center"
    }
)

-- ============================================================
-- HYPR-LAB DO NOT DISTURB
-- ============================================================

hl.bind(
    mainMod .. " + SHIFT + D",
    hl.dsp.exec_cmd(
        "qs ipc call notifications dnd"
    ),
    {
        description =
            "Toggle Hypr-Lab Do Not Disturb"
    }
)

-- ============================================================
-- VOLUME CONTROL
-- ============================================================

hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd(
        "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
    ),
    {
        repeating = true,
        description =
            "Volume up with keyboard"
    }
)

hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd(
        "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    ),
    {
        repeating = true,
        description =
            "Volume down with keyboard"
    }
)

hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ),
    {
        locked = true,
        description =
            "Mute volume with keyboard"
    }
)

-- ============================================================
-- HYPR-LAB VOLUME PANEL
-- ============================================================

hl.bind(
    mainMod .. " + SHIFT + V",
    hl.dsp.exec_cmd(
        "qs ipc call controlcenter audio"
    ),
    {
        description =
            "Open Hypr-Lab Control Center directly on the Audio page"
    }
)

-- ============================================================
-- MUSIC CONTROL
-- ============================================================

hl.bind(
    "XF86AudioPlay",
    hl.dsp.exec_cmd(
        "playerctl play-pause"
    ),
    {
        locked = true,
        description =
            "Music play with keyboard"
    }
)

hl.bind(
    "XF86AudioPause",
    hl.dsp.exec_cmd(
        "playerctl play-pause"
    ),
    {
        locked = true,
        description =
            "Music pause with keyboard"
    }
)

hl.bind(
    "XF86AudioPrev",
    hl.dsp.exec_cmd(
        "playerctl previous"
    ),
    {
        locked = true,
        description =
            "Play previous music"
    }
)

hl.bind(
    "XF86AudioNext",
    hl.dsp.exec_cmd(
        "playerctl next"
    ),
    {
        locked = true,
        description =
            "Play next music"
    }
)

-- ============================================================
-- HYPR-LAB WALLPAPER
-- ============================================================

hl.bind(
    mainMod .. " + W",
    hl.dsp.exec_cmd(
        "qs ipc call wallpaper random"
    ),
    {
        description =
            "Random Hypr-Lab wallpaper + random transition"
    }
)

hl.bind(
    mainMod .. " + SHIFT + W",
    hl.dsp.exec_cmd(
        "qs ipc call wallpaper togglePicker"
    ),
    {
        description =
            "Open/Close Hypr-Lab wallpaper picker"
    }
)

-- ============================================================
-- HYPR-LAB APP LAUNCHER
-- ============================================================

hl.bind(
    mainMod .. " + SPACE",
    hl.dsp.exec_cmd(
        "qs ipc call launcher toggle"
    ),
    {
        description =
            "Open/Close Hypr-Lab App Launcher"
    }
)

-- ============================================================
-- HYPR-LAB WELCOME
-- ============================================================

hl.bind(
    "SUPER + ALT + W",
    hl.dsp.exec_cmd(
        "qs ipc call welcome toggle"
    ),
    {
        description =
            "Open/Close Hypr-Lab welcome screen"
    }
)

-- ============================================================
-- BLENDER
-- ============================================================

hl.bind(
    mainMod .. " + SHIFT + B",
    hl.dsp.exec_cmd("blender"),
    {
        description =
            "open blender"
    }
)

-- ============================================================
-- POWER MANAGEMENT
-- ============================================================

hl.bind(
    mainMod .. " + SHIFT + P",
    hl.dsp.exec_cmd(
        "qs ipc call powermenu toggle"
    ),
    {
        description =
            "Open/Close Hypr-Lab power menu"
    }
)

-- ============================================================
-- HYPR-LAB LOCK
-- ============================================================

hl.bind(
    mainMod .. " + L",
    hl.dsp.exec_cmd(
        "quickshell -p ~/.config/quickshell/lock/shell.qml"
    ),
    {
        description =
            "Lock session with Hypr-Lab Lock"
    }
)

-- ============================================================
-- SCREENSHOTS
-- ============================================================

hl.bind(
    mainMod .. " + SHIFT + S",
    hl.dsp.exec_cmd(
        "~/.config/hypr/hyprlab-scripts/screenshot-area.sh"
    ),
    {
        description =
            "Selected area"
    }
)

hl.bind(
    mainMod .. " + SHIFT + A",
    hl.dsp.exec_cmd(
        "~/.config/hypr/hyprlab-scripts/screenshot-full.sh"
    ),
    {
        description =
            "Fullscreen"
    }
)

-- ============================================================
-- WORKSPACE SWITCH
-- ============================================================

for i = 1, 10 do
    local key = i % 10

    hl.bind(
        mainMod .. " + " .. key,
        hl.dsp.focus({
            workspace = i
        })
    )
end

-- ============================================================
-- MOVE ACTIVE WINDOW OTHER WORKSPACE
-- ============================================================

for i = 1, 10 do
    local key = i % 10

    hl.bind(
        mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({
            workspace = i
        })
    )
end

-- ============================================================
-- RESIZE ACTIVE WINDOW
-- ============================================================

hl.bind(
    mainMod .. " + CTRL + right",
    hl.dsp.window.resize({
        x = 100,
        y = 0,
        relative = true
    })
)

hl.bind(
    mainMod .. " + CTRL + left",
    hl.dsp.window.resize({
        x = -100,
        y = 0,
        relative = true
    })
)

hl.bind(
    mainMod .. " + CTRL + down",
    hl.dsp.window.resize({
        x = 0,
        y = 100,
        relative = true
    })
)

hl.bind(
    mainMod .. " + CTRL + up",
    hl.dsp.window.resize({
        x = 0,
        y = -100,
        relative = true
    })
)

-- ============================================================
-- WINDOW FLOATING MODE
-- ============================================================

hl.bind(
    mainMod .. " + T",
    hl.dsp.window.float({
        action = "toggle"
    })
)

hl.bind(
    mainMod .. " + F",
    hl.dsp.window.fullscreen()
)

-- ============================================================
-- FLOATING WINDOW MOVE / RESIZE
-- ============================================================

hl.bind(
    mainMod .. " + mouse:272",
    hl.dsp.window.drag(),
    {
        mouse = true,
        description =
            "Move left mouse button"
    }
)

hl.bind(
    mainMod .. " + mouse:273",
    hl.dsp.window.resize(),
    {
        mouse = true,
        description =
            "Resize hold SUPER + Right mouse button"
    }
)

-- ============================================================
-- WINDOW FOCUS WITH ARROWS
-- ============================================================

hl.bind(
    mainMod .. " + left",
    hl.dsp.focus({
        direction = "left"
    }),
    {
        description =
            "Window focus left"
    }
)

hl.bind(
    mainMod .. " + right",
    hl.dsp.focus({
        direction = "right"
    }),
    {
        description =
            "Window focus right"
    }
)

hl.bind(
    mainMod .. " + up",
    hl.dsp.focus({
        direction = "up"
    }),
    {
        description =
            "Window focus up"
    }
)

hl.bind(
    mainMod .. " + down",
    hl.dsp.focus({
        direction = "down"
    }),
    {
        description =
            "Window focus down"
    }
)

-- ============================================================
-- WINDOW SPLITS
-- ============================================================

hl.bind(
    mainMod .. " + J",
    hl.dsp.layout("togglesplit"),
    {
        description =
            "Split window horizontal and vertical."
    }
)

hl.bind(
    mainMod .. " + K",
    hl.dsp.layout("swapsplit"),
    {
        description =
            "Change window split"
    }
)

-- ============================================================
-- WINDOW BORDER ANIMATION
-- ============================================================

hl.bind(
    "SUPER + ALT + A",
    function()

        borderGlowOn =
            not borderGlowOn

        set_border_glow(
            borderGlowOn
        )

    end,
    {
        description =
            "Turn on/off the border glow animation."
    }
)

--==========================
--HYPR-LAB LAYER RULES
--==========================

-- ============================================================
-- HYPR-LAB WALLPAPER PICKER BLUR
-- ============================================================

hl.layer_rule({
    name =
        "hypr-lab-wallpaper-picker-blur",

    match = {
        namespace =
            "hypr-lab-wallpaper-picker"
    },

    blur = true,

    -- Gyakorlatilag az animáció teljes
    -- időtartama alatt aktív marad.
    ignore_alpha = 0.001,

    xray = true,
})

-- ============================================================
-- HYPR-LAB APP LAUNCHER CARD BLUR
-- ============================================================

hl.layer_rule({
    name =
        "hypr-lab-launcher-blur",

    match = {
        namespace =
            "hypr-lab-launcher"
    },

    blur = true,

    -- A fullscreen launcher surface mindenhol
    -- teljesen transzparens, kivéve a kártyát.
    --
    -- Ezért a blur csak a kártya pixelei alatt
    -- jelenik meg, nem az egész kijelzőn.
    ignore_alpha = 0.001,

    -- Nem kell átnézni más shell layereken.
    -- A launcher saját glass-card blurként működik.
    xray = false,
})

-- ============================================================
-- HYPR-LAB WELCOME BLUR
-- ============================================================

hl.layer_rule({
    name =
        "hypr-lab-welcome-blur",

    match = {
        namespace =
            "hypr-lab-welcome"
    },

    blur = true,
    ignore_alpha = 0.001,
    xray = true,
})

-- ============================================================
-- HYPR-LAB POWER MENU BLUR
-- ============================================================

hl.layer_rule({
    name =
        "hypr-lab-power-menu-blur",

    match = {
        namespace =
            "hypr-lab-power-menu"
    },

    blur = true,

    -- A zárási fade legvégéig
    -- megmaradjon a compositor blur.
    ignore_alpha = 0.001,

    xray = true,
})

--======================
--HYPR-LAB WINDOW RULES
--======================

-- ============================================================
-- BLENDER BLUR OFF
-- ============================================================

hl.window_rule({
    match = {
        class = "blender"
    },

    opaque = true,
})

-- ============================================================
-- GIMP BLUR OFF
-- ============================================================

hl.window_rule({
    match = {
        class = "gimp"
    },

    opaque = true,
})

--==============================
--HYPR-LAB FORCE TOGGLE FUNCTION
--==============================

hl.config({
    dwindle = {
        force_split = 2,
        preserve_split = true,
    },
})

--==============================================
--Hypr-Lab window decorations, animations & gaps
--==============================================

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,

        border_size = 2,

        col = {
            active_border =
                "rgba(0ee3d8ff)",

            inactive_border =
                "rgba(044440ff)",
        },
    },

    decoration = {
        rounding = 17,

        active_opacity = 0.80,
        inactive_opacity = 0.70,
        fullscreen_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 20,
            render_power = 10,

            color =
                "rgba(044440ff)",
        },

        blur = {
            enabled = true,
            size = 4,
            passes = 3,

            new_optimizations = true,

            xray = false,

            ignore_opacity = true,
        },
    },

    animations = {
        enabled = true,
    },
})

-- ============================================================
-- BEZIER CURVES
-- ============================================================

hl.curve(
    "myBezier",
    {
        type = "bezier",

        points = {
            { 0.05, 0.9 },
            { 0.1, 1.05 }
        }
    }
)

hl.curve(
    "linear",
    {
        type = "bezier",

        points = {
            { 0.0, 0.0 },
            { 1.0, 1.0 }
        }
    }
)

hl.curve(
    "extremeOvershoot",
    {
        type = "bezier",

        points = {
            { 0.18, 1.1 },
            { 0.1, 1.3 }
        }
    }
)

hl.curve(
    "glowSpring",
    {
        type = "spring",

        mass = 5,
        stiffness = 100,
        dampening = 100
    }
)

-- ============================================================
-- ANIMATIONS
-- ============================================================

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 7,
    bezier = "myBezier"
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 7,
    bezier = "default"
})

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 7,
    bezier = "default"
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 5,
    bezier = "extremeOvershoot",
    style = "slidefade 20%"
})

hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 8,
    spring = "glowSpring",
    style = "loop"
})
-- ============================================================
-- HYPR-LAB CONTROL CENTER
-- ============================================================

hl.bind(
    mainMod .. " + SHIFT + C",
    hl.dsp.exec_cmd(
        "qs ipc call controlcenter main"
    ),
    {
        description =
            "Open Hypr-Lab Control Center main page / return from Audio"
    }
)

