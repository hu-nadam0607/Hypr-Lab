import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: root
    implicitHeight: 134

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinkAudio: root.sink ? root.sink.audio : null
    readonly property var sourceAudio: root.source ? root.source.audio : null

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Column {
        anchors.fill: parent
        spacing: 6

        Text {
            text: "AUDIO"
            color: Qt.rgba(190/255, 205/255, 210/255, 0.52)
            font.family: "Inter"
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 1.6
        }

        AudioSlider {
            width: parent.width
            icon: root.sinkAudio && root.sinkAudio.muted ? "󰖁" : "󰕾"
            label: root.sink ? (root.sink.description || "Speakers") : "No output device"
            value: root.sinkAudio ? root.sinkAudio.volume : 0.0
            muted: root.sinkAudio ? root.sinkAudio.muted : true
            available: root.sinkAudio !== null

            onValueRequested: value => {
                if (!root.sinkAudio) return
                root.sinkAudio.volume = value
                if (root.sinkAudio.muted)
                    root.sinkAudio.muted = false
            }

            onMuteRequested: {
                if (root.sinkAudio)
                    root.sinkAudio.muted = !root.sinkAudio.muted
            }
        }

        AudioSlider {
            width: parent.width
            icon: root.sourceAudio && root.sourceAudio.muted ? "󰍭" : "󰍬"
            label: root.source ? (root.source.description || "Microphone") : "No input device"
            value: root.sourceAudio ? root.sourceAudio.volume : 0.0
            muted: root.sourceAudio ? root.sourceAudio.muted : true
            available: root.sourceAudio !== null

            onValueRequested: value => {
                if (!root.sourceAudio) return
                root.sourceAudio.volume = value
                if (root.sourceAudio.muted)
                    root.sourceAudio.muted = false
            }

            onMuteRequested: {
                if (root.sourceAudio)
                    root.sourceAudio.muted = !root.sourceAudio.muted
            }
        }
    }
}
