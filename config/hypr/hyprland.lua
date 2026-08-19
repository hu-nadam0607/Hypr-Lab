hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/hyprlab-scripts/hyprlab-xdg.sh")

    hl.exec_cmd("quickshell")

    hl.exec_cmd("bash ~/.config/hypr/hyprlab-scripts/hyprlab-settings.sh apply")

    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpolkitagent")
end)

hl.config({
    input = {
        kb_layout = "hu",
    },
})

local terminal = "ghostty"
local mainMod = "SUPER"

hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(terminal), {
        description = "open_terminal"
    }
)

hl.bind(mainMod .. " + M", hl.dsp.exit(), {
        description = "quit_hyprland"
    }
)

hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("~/.config/hypr/settings/browser.sh"), {
        description = "Open the browser declared in the sh file."
    }
)

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("~/.config/hypr/settings/filemanager.sh"), {
        description = "Open the file manager declared in the sh file."
    }
)

hl.bind(mainMod .. " + Q", hl.dsp.window.close(), {
        description = "Kill active window"
    }
)

hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("qs ipc call notifications toggle"), {
        description = "Open/Close Hypr-Lab notification center"
    }
)

hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("qs ipc call notifications dnd"), {
        description = "Toggle Hypr-Lab Do Not Disturb"
    }
)

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), {
        repeating = true,
        description = "Volume up with keyboard"
    }
)

hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), {
        repeating = true,
        description = "Volume down with keyboard"
    }
)

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), {
        locked = true,
        description = "Mute volume with keyboard"
    }
)

hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("qs ipc call topbarAudio toggle"), {
        description = "Toggle Hypr-Lab angled Audio Control panel"
    }
)

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), {
        locked = true,
        description = "Music play with keyboard"
    }
)

hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), {
        locked = true,
        description = "Music pause with keyboard"
    }
)

hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), {
        locked = true,
        description = "Play previous music"
    }
)

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), {
        locked = true,
        description = "Play next music"
    }
)

hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call wallpaper random"), {
        description = "Random Hypr-Lab wallpaper + random transition"
    }
)

hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("qs ipc call wallpaper togglePicker"), {
        description = "Open/Close Hypr-Lab wallpaper picker"
    }
)

hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs ipc call launcher toggle"), {
        description = "Open/Close Hypr-Lab App Launcher"
    }
)

hl.bind("SUPER + ALT + W", hl.dsp.exec_cmd("qs ipc call welcome toggle"), {
        description = "Open/Close Hypr-Lab welcome screen"
    }
)

hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("blender"), {
        description = "open blender"
    }
)

hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("qs ipc call powermenu toggle"), {
        description = "Open/Close Hypr-Lab power menu"
    }
)

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("quickshell -p ~/.config/quickshell/lock/shell.qml"), {
        description = "Lock session with Hypr-Lab Lock"
    }
)

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/hyprlab-scripts/screenshot-area.sh"), {
        description = "Selected area"
    }
)

hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("~/.config/hypr/hyprlab-scripts/screenshot-full.sh"), {
        description = "Fullscreen"
    }
)

for i = 1, 10 do
    local key = i % 10

    hl.bind(
        mainMod .. " + " .. key,
        hl.dsp.focus({
            workspace = i
        })
    )
end

for i = 1, 10 do
    local key = i % 10

    hl.bind(
        mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({
            workspace = i
        })
    )
end

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

hl.bind(
    mainMod .. " + T",
    hl.dsp.window.float({ action = "toggle" })
)

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), {
        mouse = true,
        description = "Move left mouse button"
    }
)

hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), {
        mouse = true,
        description = "Resize hold SUPER + Right mouse button"
    }
)

hl.bind(
    mainMod .. " + left",
    hl.dsp.focus({ direction = "left" }),
    {
        description = "Window focus left"
    }
)

hl.bind(
    mainMod .. " + right",
    hl.dsp.focus({ direction = "right" }),
    {
        description = "Window focus right"
    }
)

hl.bind(
    mainMod .. " + up",
    hl.dsp.focus({ direction = "up" }),
    {
        description = "Window focus up"
    }
)

hl.bind(
    mainMod .. " + down",
    hl.dsp.focus({ direction = "down" }),
    {
        description = "Window focus down"
    }
)

hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), {
        description = "Split window horizontal and vertical."
    }
)

hl.bind(mainMod .. " + K", hl.dsp.layout("swapsplit"), {
        description = "Change window split"
    }
)

hl.layer_rule({
    name = "hypr-lab-topbar-blur",

    match = {
        namespace = "hypr-lab-shell"
    },

    blur = true,
    ignore_alpha = 0.055,
    xray = false,
})


hl.layer_rule({
    name = "hypr-lab-control-center-blur",

    match = {
        namespace = "hypr-lab-control-center-v4"
    },

    blur = true,
    ignore_alpha = 0.055,
    xray = false,
})

hl.layer_rule({
    name = "hypr-lab-wallpaper-picker-blur",

    match = {
        namespace = "hypr-lab-wallpaper-picker"
    },

    blur = true,

    ignore_alpha = 0.001,

    xray = true,
})

-- Hyprland 0.56.x: the launcher is a layer-shell surface. Layer rules expose
-- blur/animation/order effects, but no per-layer shadow effect. Keep the
-- compositor-side frosted blur here; the broken QML shadow was removed.
hl.layer_rule({
    name = "hypr-lab-launcher-blur",

    match = {
        namespace = "hypr-lab-launcher"
    },

    blur = true,

    ignore_alpha = 0.001,

    xray = false,
})

hl.layer_rule({
    name = "hypr-lab-welcome-blur",

    match = {
        namespace = "hypr-lab-welcome"
    },

    blur = true,
    ignore_alpha = 0.001,
    xray = true,
})

hl.layer_rule({
    name = "hypr-lab-power-menu-blur",

    match = {
        namespace = "hypr-lab-power-menu"
    },

    blur = true,

    ignore_alpha = 0.001,

    xray = true,
})

hl.window_rule({
    match = {
        class = "blender"
    },

    opaque = true,
})

hl.window_rule({
    match = {
        class = "gimp"
    },

    opaque = true,
})

hl.config({
    dwindle = {
        force_split = 2,
        preserve_split = true,
    },
})

hl.config({
    general = {
        gaps_in = 10,
        gaps_out = 10,

        border_size = 2,

        col = {
            active_border = "rgba(68787Ddd)",
            inactive_border = "rgba(68787D44)",
        },
    },

    decoration = {
        rounding = 2,

        active_opacity = 0.80,
        inactive_opacity = 0.70,
        fullscreen_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 18,
            render_power = 2,

            color = "rgba(000000ee)",
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

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 7,
    bezier = "myBezier"
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 10,
    bezier = "default",
    style = "slide"
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 10,
    bezier = "default",
    style = "slide"
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

hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("qs ipc call controlcenter main"), {
        description = "Open Hypr-Lab Control Center main page / return from Audio"
    }
)
