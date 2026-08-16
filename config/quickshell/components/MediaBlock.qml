import QtQuick
import Quickshell.Services.Mpris

Item {
    id: root

    property bool active: false
    property var player: null

    signal interaction()

    implicitWidth: contentRow.implicitWidth
    implicitHeight: 30

    width: implicitWidth
    height: implicitHeight

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

        spacing: 14

        Column {
            anchors.verticalCenter: parent.verticalCenter

            spacing: 1

            Text {
                width: 180

                text:
                    root.player
                    ? (
                        root.player.trackTitle
                        || "Ismeretlen szám"
                    )
                    : ""

                color: "white"

                font.family: "Inter"
                font.pixelSize: 12
                font.bold: true

                elide: Text.ElideRight
            }

            Text {
                width: 180

                text:
                    root.player
                    ? (
                        root.player.trackArtist
                        || "Ismeretlen előadó"
                    )
                    : ""

                color: Qt.rgba(
                    1,
                    1,
                    1,
                    0.55
                )

                font.family: "Inter"
                font.pixelSize: 10

                elide: Text.ElideRight
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter

            text: "󰒮"

            color:
                root.player
                && root.player.canGoPrevious
                ? "white"
                : Qt.rgba(1, 1, 1, 0.25)

            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16

            MouseArea {
                anchors.fill: parent

                enabled:
                    root.player
                    && root.player.canGoPrevious

                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    root.player.previous()
                    root.interaction()
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter

            text:
                root.player
                && root.player.isPlaying
                ? "󰏤"
                : "󰐊"

            color:
                root.player
                && root.player.canTogglePlaying
                ? "white"
                : Qt.rgba(1, 1, 1, 0.25)

            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18

            MouseArea {
                anchors.fill: parent

                enabled:
                    root.player
                    && root.player.canTogglePlaying

                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    root.player.togglePlaying()
                    root.interaction()
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter

            text: "󰒭"

            color:
                root.player
                && root.player.canGoNext
                ? "white"
                : Qt.rgba(1, 1, 1, 0.25)

            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16

            MouseArea {
                anchors.fill: parent

                enabled:
                    root.player
                    && root.player.canGoNext

                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    root.player.next()
                    root.interaction()
                }
            }
        }
    }
}
