import QtQuick

import Quickshell.Hyprland
import Quickshell.Io

Rectangle {
    id: wsBtn

    // ============================================================
    // PUBLIC API
    // ============================================================

    property int workspaceId: 1

    property bool isActive:
        Hyprland.focusedWorkspace
        ? Hyprland.focusedWorkspace.id === workspaceId
        : false

    property bool isOccupied: {
        if (!Hyprland.workspaces)
            return false

        for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
            if (Hyprland.workspaces.values[i].id === workspaceId)
                return true
        }

        return false
    }

    // ============================================================
    // SIZE
    // ============================================================

    width:
        isActive
        ? 28
        : 18

    height: 18

    radius:
        height / 2

    // ============================================================
    // BACKGROUND
    // ============================================================

    color:
        isActive
        ? Qt.rgba(
              55 / 255,
              245 / 255,
              235 / 255,
              0.9
          )
        : (
              mouseArea.containsMouse
              ? Qt.rgba(
                    55 / 255,
                    245 / 255,
                    235 / 255,
                    0.18
                )
              : (
                    isOccupied
                    ? Qt.rgba(
                          1,
                          1,
                          1,
                          0.35
                      )
                    : Qt.rgba(
                          1,
                          1,
                          1,
                          0.12
                      )
                )
          )

    // ============================================================
    // ANIMATIONS
    // ============================================================

    Behavior on width {
        SpringAnimation {
            spring: 4
            damping: 0.3
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    // ============================================================
    // WORKSPACE SWITCH PROCESS
    // ============================================================

    Process {
        id: workspaceSwitchProcess
    }

    // ============================================================
    // SWITCH FUNCTION
    // ============================================================

    function switchWorkspace() {

        // Hyprland 0.55+ Lua dispatcher syntax.
        //
        // Példa:
        //
        // hyprctl dispatch
        // 'hl.dsp.focus({ workspace = "3" })'

        workspaceSwitchProcess.command = [
            "hyprctl",
            "dispatch",
            'hl.dsp.focus({ workspace = "' +
                wsBtn.workspaceId +
                '" })'
        ]

        workspaceSwitchProcess.running = true
    }

    // ============================================================
    // WORKSPACE NUMBER
    // ============================================================

    Text {
        anchors.centerIn:
            parent

        text:
            wsBtn.workspaceId.toString()

        color:
            wsBtn.isActive
            ? "black"
            : "white"

        font.family:
            "Inter"

        font.pixelSize:
            10

        font.bold:
            wsBtn.isActive

        opacity:
            wsBtn.isActive || wsBtn.isOccupied
            ? 1.0
            : 0.5
    }

    // ============================================================
    // MOUSE
    // ============================================================

    MouseArea {
        id: mouseArea

        anchors.fill:
            parent

        hoverEnabled:
            true

        cursorShape:
            Qt.PointingHandCursor

        acceptedButtons:
            Qt.LeftButton

        onClicked: {
            wsBtn.switchWorkspace()
        }
    }
}