import QtQuick
import Quickshell.Services.Pipewire

Rectangle {
    id: root

    property var node: null
    property bool active: false
    property bool outputDevice: true

    signal selectRequested()

    readonly property var nodeAudio: root.node ? root.node.audio : null
    readonly property string deviceName: {
        if (!root.node) return "Unknown device"
        if (root.node.description && root.node.description.length > 0) return root.node.description
        if (root.node.nickname && root.node.nickname.length > 0) return root.node.nickname
        return root.node.name || "Audio device"
    }

    implicitHeight: 94
    radius: 16
    color: root.active
        ? Qt.rgba(55/255, 245/255, 235/255, 0.075)
        : (deviceMouse.containsMouse
            ? Qt.rgba(255/255,255/255,255/255,0.050)
            : Qt.rgba(255/255,255/255,255/255,0.028))
    border.width: 1
    border.color: root.active
        ? Qt.rgba(55/255,245/255,235/255,0.34)
        : Qt.rgba(255/255,255/255,255/255,0.055)

    Behavior on color { ColorAnimation { duration: 110 } }
    Behavior on border.color { ColorAnimation { duration: 110 } }

    PwObjectTracker {
        objects: root.node ? [root.node] : []
    }

    MouseArea {
        id: deviceMouse
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 38
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selectRequested()
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 13
        anchors.rightMargin: 13
        height: 38
        spacing: 10

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22
            radius: 11
            color: root.active
                ? Qt.rgba(55/255,245/255,235/255,0.13)
                : Qt.rgba(255/255,255/255,255/255,0.035)
            border.width: 1
            border.color: root.active
                ? Qt.rgba(55/255,245/255,235/255,0.42)
                : Qt.rgba(255/255,255/255,255/255,0.06)

            Text {
                anchors.centerIn: parent
                text: root.outputDevice ? "󰕾" : "󰍬"
                color: root.active ? "#37f5eb" : Qt.rgba(1,1,1,0.62)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 84
            spacing: 1

            Text {
                width: parent.width
                text: root.deviceName
                color: root.active ? "#eaffff" : "#dce8e9"
                font.family: "Inter"
                font.pixelSize: 10
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.active ? "ACTIVE" : "Click to activate"
                color: root.active
                    ? Qt.rgba(55/255,245/255,235/255,0.72)
                    : Qt.rgba(1,1,1,0.34)
                font.family: "Inter"
                font.pixelSize: 8
                font.bold: true
                font.letterSpacing: 0.8
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.active ? "󰄬" : ""
            color: "#37f5eb"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
        }
    }

    AudioSlider {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8
        anchors.rightMargin: 12
        height: 54
        icon: root.nodeAudio && root.nodeAudio.muted
            ? (root.outputDevice ? "󰖁" : "󰍭")
            : (root.outputDevice ? "󰕾" : "󰍬")
        label: ""
        value: root.nodeAudio ? root.nodeAudio.volume : 0.0
        muted: root.nodeAudio ? root.nodeAudio.muted : true
        available: root.nodeAudio !== null

        onValueRequested: value => {
            if (!root.nodeAudio) return
            root.nodeAudio.volume = value
            if (root.nodeAudio.muted) root.nodeAudio.muted = false
        }

        onMuteRequested: {
            if (root.nodeAudio) root.nodeAudio.muted = !root.nodeAudio.muted
        }
    }
}
