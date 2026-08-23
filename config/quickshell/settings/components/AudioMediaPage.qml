import QtQuick

Item {
    id: root

    property var backend
    property color accentColor: "#68787D"

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 16
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 0

            SectionLabel {
                width: parent.width
                text: "MASTER AUDIO"
                accentColor: root.accentColor
            }

            SettingStepper {
                width: parent.width
                accentColor: root.accentColor
                title: "Output volume"
                subtitle: "Default PipeWire output"
                valueText: Math.round(backend.audioVolume * 100) + "%"
                onDecrease: backend.changeAudioVolume(-5)
                onIncrease: backend.changeAudioVolume(5)
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Mute output"
                subtitle: "Mute or unmute the default output"
                checked: backend.audioMuted
                onToggled: function(value) {
                    backend.setAudioMuted(value)
                }
            }

            SettingAction {
                width: parent.width
                accentColor: root.accentColor
                title: "Advanced audio settings"
                subtitle: "Open pavucontrol"
                icon: "󰓃"
                buttonText: "OPEN"
                onTriggered: backend.openAudioSettings()
            }

            SectionLabel {
                width: parent.width
                text: "CENTER ISLAND"
                accentColor: root.accentColor
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Volume feedback"
                subtitle: "Show the temporary volume indicator in Center Island"
                checked: backend.centerVolumeFeedback
                onToggled: function(value) {
                    backend.centerVolumeFeedback = value
                    backend.setBool("CENTER_VOLUME_FEEDBACK", value)
                }
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Compact CAVA"
                subtitle: "Show the five-bar visualizer while music is playing"
                checked: backend.centerCava
                onToggled: function(value) {
                    backend.centerCava = value
                    backend.setBool("CENTER_CAVA", value)
                }
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Media feedback"
                subtitle: "Allow scroll-up media information in Center Island"
                checked: backend.centerMediaFeedback
                onToggled: function(value) {
                    backend.centerMediaFeedback = value
                    backend.setBool("CENTER_MEDIA_FEEDBACK", value)
                }
            }
        }
    }

    Component.onCompleted: {
        if (backend)
            backend.refreshAudio()
    }
}
