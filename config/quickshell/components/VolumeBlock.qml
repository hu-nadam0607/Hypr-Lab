import QtQuick
import Quickshell.Services.Pipewire 0.1

Item {
    id: root

    property bool active: false

    property var sink: Pipewire.defaultAudioSink
    property var audio: sink ? sink.audio : null

    PwObjectTracker {
        objects: [root.sink]
    }

    property real volumeLevel: audio ? audio.volume : 0.0
    property bool isMuted: audio ? audio.muted : false

    property real displayVolume: isMuted ? 0.0 : volumeLevel

    width: contentRow.implicitWidth
    height: contentRow.implicitHeight

    opacity: active ? 1.0 : 0.0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: 180
            easing.type: Easing.InOutQuad
        }
    }

    Row {
        id: contentRow

        anchors.centerIn: parent
        spacing: 12

        Text {
            anchors.verticalCenter: parent.verticalCenter

            text: root.isMuted
                  ? "🔇"
                  : root.volumeLevel > 0.5
                    ? "🔊"
                    : root.volumeLevel > 0
                      ? "🔉"
                      : "🔈"

            font.pixelSize: 14
        }

        Rectangle {
            id: sliderBackground

            anchors.verticalCenter: parent.verticalCenter

            width: 140
            height: 6
            radius: 3

            color: Qt.rgba(1, 1, 1, 0.15)

            Rectangle {
                id: sliderFill

                height: parent.height
                radius: parent.radius

                color: Qt.rgba(
                    55 / 255,
                    245 / 255,
                    235 / 255,
                    0.9
                )

                width: Math.max(
                    0,
                    Math.min(
                        root.displayVolume * parent.width,
                        parent.width
                    )
                )

                Behavior on width {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter

            text: Math.round(root.displayVolume * 100) + "%"

            color: "white"

            font.family: "Inter"
            font.pixelSize: 11
            font.bold: true

            width: 32
            horizontalAlignment: Text.AlignRight
        }
    }
}
