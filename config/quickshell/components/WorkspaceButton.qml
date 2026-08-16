import QtQuick

import Quickshell.Hyprland
import Quickshell.Io

Rectangle {
    id: wsBtn

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

    width:
        isActive
        ? 28
        : 18

    height: 18

    radius:
        height / 2

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

    Process {
        id: workspaceSwitchProcess
    }

    function switchWorkspace() {
        workspaceSwitchProcess.command = [
            "hyprctl",
            "dispatch",
            'hl.dsp.focus({ workspace = "' +
                wsBtn.workspaceId +
                '" })'
        ]

        workspaceSwitchProcess.running = true
    }

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
