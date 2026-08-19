import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: root
    property var node: null
    property bool active: false
    property bool outputDevice: true
    property color accentColor: "#68787D"
    signal selectRequested()

    readonly property var nodeAudio: root.node ? root.node.audio : null
    readonly property string deviceName: {
        if (!root.node) return "Unknown device"
        if (root.node.description && root.node.description.length > 0) return root.node.description
        if (root.node.nickname && root.node.nickname.length > 0) return root.node.nickname
        return root.node.name || "Audio device"
    }

    implicitHeight: 72

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: deviceMouse.containsMouse
            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.08)
            : Qt.rgba(1,1,1,0.025)
        border.width: 1
        border.color: root.active
            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.52)
            : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
    }

    PwObjectTracker { objects: root.node ? [root.node] : [] }

    MouseArea {
        id: deviceMouse
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 30
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selectRequested()
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.top: parent.top
        anchors.topMargin: 8
        text: root.outputDevice ? "󰕾" : "󰍬"
        color: root.active ? root.accentColor : Qt.rgba(1,1,1,0.56)
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 34
        anchors.right: activeMark.left
        anchors.rightMargin: 8
        anchors.top: parent.top
        anchors.topMargin: 7
        text: root.deviceName
        color: root.active ? "white" : Qt.rgba(1,1,1,0.72)
        font.family: "Inter"
        font.italic: true
        font.pixelSize: 9
        font.bold: true
        elide: Text.ElideRight
    }

    Text {
        id: activeMark
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.top: parent.top
        anchors.topMargin: 7
        text: root.active ? "󰄬" : ""
        color: root.accentColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
    }

    Item {
        id: slider
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        height: 24

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 4
            radius: 2
            color: Qt.rgba(1,1,1,0.09)
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.nodeAudio ? root.nodeAudio.volume : 0))
                height: parent.height
                radius: 2
                color: root.nodeAudio && root.nodeAudio.muted ? Qt.rgba(1,1,1,0.18) : root.accentColor
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function setAt(xPos) {
                if (!root.nodeAudio) return
                root.nodeAudio.volume = Math.max(0, Math.min(1, xPos / width))
                if (root.nodeAudio.muted) root.nodeAudio.muted = false
            }
            onPressed: function(mouse) { setAt(mouse.x) }
            onPositionChanged: function(mouse) { if (pressed) setAt(mouse.x) }
        }
    }
}
