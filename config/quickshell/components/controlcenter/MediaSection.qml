import QtQuick
import Quickshell.Services.Mpris

Rectangle {
    id: root

    property var player: null
    property var players: Mpris.players.values

    implicitHeight: player ? 118 : 0
    visible: implicitHeight > 0
    radius: 14
    color: Qt.rgba(10/255, 14/255, 21/255, 0.56)
    border.width: 1
    border.color: Qt.rgba(1,1,1,0.07)

    function selectPlayer() {
        const list = Mpris.players.values
        let selected = null
        for (let i = 0; i < list.length; ++i) {
            if (list[i].isPlaying) {
                selected = list[i]
                break
            }
        }
        if (!selected && list.length > 0)
            selected = list[0]
        root.player = selected
    }

    onPlayersChanged: selectPlayer()
    Component.onCompleted: selectPlayer()

    Timer {
        interval: 800
        repeat: true
        running: root.visible
        onTriggered: root.selectPlayer()
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 5

        Text {
            text: "NOW PLAYING"
            color: Qt.rgba(190/255, 205/255, 210/255, 0.50)
            font.family: "Inter"
            font.pixelSize: 8
            font.bold: true
            font.letterSpacing: 1.4
        }

        Row {
            id: infoRow
            width: parent.width
            spacing: 12

            Column {
                width: parent.width - controls.width - 12
                spacing: 1

                Text {
                    width: parent.width
                    text: root.player ? (root.player.trackTitle || "Ismeretlen szám") : ""
                    color: "#e8f2f3"
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.player ? (root.player.trackArtist || "Ismeretlen előadó") : ""
                    color: Qt.rgba(1,1,1,0.52)
                    font.family: "Inter"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            Row {
                id: controls
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Repeater {
                    model: [
                        { icon: "󰒮", action: "prev" },
                        { icon: root.player && root.player.isPlaying ? "󰏤" : "󰐊", action: "toggle" },
                        { icon: "󰒭", action: "next" }
                    ]

                    Text {
                        required property var modelData
                        text: modelData.icon
                        color: controlMouse.containsMouse ? "#37f5eb" : "#dce8e9"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: modelData.action === "toggle" ? 18 : 16

                        MouseArea {
                            id: controlMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.player) return
                                if (modelData.action === "prev" && root.player.canGoPrevious) root.player.previous()
                                else if (modelData.action === "next" && root.player.canGoNext) root.player.next()
                                else if (modelData.action === "toggle" && root.player.canTogglePlaying) root.player.togglePlaying()
                            }
                        }
                    }
                }
            }
        }

        CavaVisualizer {
            width: parent.width
            height: 25
            active: root.player !== null && root.player.isPlaying
        }
    }
}
