import QtQuick
import Quickshell.Services.Pipewire 0.1

Item {
    id: root

    // CenterIsland ezt állítja true-ra,
    // amikor a hangerő kijelzést meg akarja jeleníteni.
    property bool active: false

    // 1. Alapértelmezett kimeneti eszköz és Tracker
    property var sink: Pipewire.defaultAudioSink
    property var audio: sink ? sink.audio : null

    // Quickshell 0.3.0 kötelező eleme az élő követéshez
    PwObjectTracker {
        objects: [root.sink]
    }

    // 2. ÉLŐ KÖTÉSEK
    property real volumeLevel: audio ? audio.volume : 0.0
    property bool isMuted: audio ? audio.muted : false

    // Némított állapotban 0.0 hangerőt jelenítünk meg, egyébként a valós szintet
    property real displayVolume: isMuted ? 0.0 : volumeLevel

    // Méret
    width: contentRow.implicitWidth
    height: contentRow.implicitHeight

    // Megjelenés és áttűnés
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

        // ==========================================
        // HANGERŐ / NÉMA IKON
        // ==========================================

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

        // ==========================================
        // HANGERŐ SLIDER
        // ==========================================

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

                // Élő szélesség kalkuláció (némítva 0px)
                width: Math.max(
                    0,
                    Math.min(
                        root.displayVolume * parent.width,
                        parent.width
                    )
                )

                // A folyamatos kúszó animáció fix időtartammal és OutCubic lágyítással
                Behavior on width {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        // ==========================================
        // SZÁZALÉK
        // ==========================================

        Text {
            anchors.verticalCenter: parent.verticalCenter

            // Némítás esetén 0%-ot jelenít meg
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