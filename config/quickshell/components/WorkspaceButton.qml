import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: wsBtn

    property int workspaceId: 1
    property color accentColor: "#68787D"

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

    width: 22
    height: 24

    Process { id: workspaceSwitchProcess }

    function switchWorkspace() {
        workspaceSwitchProcess.command = [
            "hyprctl", "dispatch",
            'hl.dsp.focus({ workspace = "' + wsBtn.workspaceId + '" })'
        ]
        workspaceSwitchProcess.running = true
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 1
        color: Qt.rgba(1, 1, 1, 0.06)
        opacity: mouseArea.containsMouse && !wsBtn.isActive ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 100 }
        }
    }

    Text {
        anchors.centerIn: parent
        text: wsBtn.workspaceId.toString()
        color: wsBtn.isActive ? Qt.rgba(0.02, 0.03, 0.04, 0.96) : "white"
        font.family: "Inter"
        font.pixelSize: 10
        font.bold: wsBtn.isActive
        font.italic: true
        opacity: wsBtn.isActive || wsBtn.isOccupied ? 0.95 : 0.42
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: wsBtn.switchWorkspace()
    }
}
