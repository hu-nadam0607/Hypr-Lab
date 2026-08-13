import QtQuick

Item {
    id: root

    property string icon: "󰕾"
    property string label: "Audio"
    property real value: 0.0
    property bool muted: false
    property bool available: true

    signal valueRequested(real value)
    signal muteRequested()

    implicitHeight: 54

    Rectangle {
        id: muteButton
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        height: 34
        radius: 17
        color: muteMouse.containsMouse ? Qt.rgba(55/255,245/255,235/255,0.08) : "transparent"

        Text {
            anchors.centerIn: parent
            text: root.icon
            color: root.muted
                ? Qt.rgba(1,1,1,0.32)
                : (muteMouse.containsMouse ? "#37f5eb" : "#dfeaec")
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
        }

        MouseArea {
            id: muteMouse
            anchors.fill: parent
            enabled: root.available
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.muteRequested()
        }
    }

    Item {
        anchors.left: muteButton.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 46

        Text {
            id: labelText
            anchors.left: parent.left
            anchors.top: parent.top
            text: root.label
            color: root.available ? "#dfeaec" : Qt.rgba(1,1,1,0.32)
            font.family: "Inter"
            font.pixelSize: 11
            font.bold: true
            elide: Text.ElideRight
            width: parent.width - 52
        }

        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            text: Math.round(Math.max(0, root.value) * 100) + "%"
            color: root.muted
                ? Qt.rgba(1,1,1,0.34)
                : Qt.rgba(55/255,245/255,235/255,0.82)
            font.family: "Inter"
            font.pixelSize: 10
            font.bold: true
        }

        Item {
            id: hitTrack
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 20

            Rectangle {
                id: track
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 5
                radius: 3
                color: Qt.rgba(1,1,1,0.09)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.value))
                    height: parent.height
                    radius: parent.radius
                    color: root.muted
                        ? Qt.rgba(1,1,1,0.20)
                        : Qt.rgba(55/255,245/255,235/255,0.82)
                }

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    x: Math.max(0, Math.min(track.width - width, track.width * Math.max(0, Math.min(1, root.value)) - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.muted ? "#718084" : "#bffefa"
                    scale: trackMouse.containsMouse || trackMouse.pressed ? 1.12 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
            }

            function sendAt(xPos) {
                root.valueRequested(Math.max(0, Math.min(1, xPos / width)))
            }

            MouseArea {
                id: trackMouse
                anchors.fill: parent
                enabled: root.available
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                onPressed: mouse => hitTrack.sendAt(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed)
                        hitTrack.sendAt(mouse.x)
                }
            }
        }
    }
}
