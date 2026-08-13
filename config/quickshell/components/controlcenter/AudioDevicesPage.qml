import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: root

    signal backRequested()
    signal closeRequested()

    readonly property var outputNodes: Pipewire.nodes.values.filter(node =>
        node && node.audio !== null && !node.isStream && node.isSink)
    readonly property var inputNodes: Pipewire.nodes.values.filter(node =>
        node && node.audio !== null && !node.isStream && !node.isSink)

    function selectOutput(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node
    }

    function selectInput(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node
    }

    Row {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 36
        spacing: 8

        Rectangle {
            width: 96
            height: 32
            radius: 12
            color: backMouse.containsMouse
                ? Qt.rgba(55/255,245/255,235/255,0.16)
                : Qt.rgba(55/255,245/255,235/255,0.075)
            border.width: 1
            border.color: backMouse.containsMouse
                ? Qt.rgba(55/255,245/255,235/255,0.42)
                : Qt.rgba(55/255,245/255,235/255,0.20)

            Row {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: "󰁍"
                    color: backMouse.containsMouse ? "#7ffcf5" : "#37f5eb"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                }
                Text {
                    text: "VISSZA"
                    color: backMouse.containsMouse ? "#ffffff" : Qt.rgba(232/255,248/255,248/255,0.88)
                    font.family: "Inter"
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 0.8
                }
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.backRequested()
            }
        }

        Column {
            width: parent.width - 142
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                text: "AUDIO"
                color: "#e8f4f5"
                font.family: "Inter"
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 1.2
            }
            Text {
                text: "PipeWire · output and input devices"
                color: Qt.rgba(1,1,1,0.38)
                font.family: "Inter"
                font.pixelSize: 8
            }
        }

        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: closeMouse.containsMouse
                ? Qt.rgba(55/255,245/255,235/255,0.10)
                : "transparent"

            Text {
                anchors.centerIn: parent
                text: "󰅖"
                color: closeMouse.containsMouse ? "#37f5eb" : Qt.rgba(1,1,1,0.56)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }
        }
    }

    Flickable {
        id: scroller
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        contentWidth: width
        contentHeight: deviceColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: deviceColumn
            width: scroller.width
            spacing: 8

            // A Flickable clip-je ne érjen bele a felső cím betűibe.
            Item { width: 1; height: 4 }

            Text {
                text: "OUTPUT DEVICES"
                color: Qt.rgba(190/255,205/255,210/255,0.52)
                font.family: "Inter"
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.6
            }

            Text {
                visible: root.outputNodes.length === 0
                text: Pipewire.ready ? "No output devices found" : "Loading PipeWire…"
                color: Qt.rgba(1,1,1,0.40)
                font.family: "Inter"
                font.pixelSize: 10
                height: visible ? 28 : 0
            }

            Repeater {
                model: ScriptModel { values: root.outputNodes }
                AudioDeviceCard {
                    required property var modelData
                    width: deviceColumn.width
                    node: modelData
                    outputDevice: true
                    active: modelData === Pipewire.defaultAudioSink
                    onSelectRequested: root.selectOutput(modelData)
                }
            }

            Item { width: 1; height: 4 }

            Text {
                text: "INPUT DEVICES"
                color: Qt.rgba(190/255,205/255,210/255,0.52)
                font.family: "Inter"
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.6
            }

            Text {
                visible: root.inputNodes.length === 0
                text: Pipewire.ready ? "No input devices found" : "Loading PipeWire…"
                color: Qt.rgba(1,1,1,0.40)
                font.family: "Inter"
                font.pixelSize: 10
                height: visible ? 28 : 0
            }

            Repeater {
                model: ScriptModel { values: root.inputNodes }
                AudioDeviceCard {
                    required property var modelData
                    width: deviceColumn.width
                    node: modelData
                    outputDevice: false
                    active: modelData === Pipewire.defaultAudioSource
                    onSelectRequested: root.selectInput(modelData)
                }
            }

            Item { width: 1; height: 2 }
        }
    }
}
