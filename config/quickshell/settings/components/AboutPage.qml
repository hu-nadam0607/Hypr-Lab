import QtQuick

Item {
    id: root
    property var backend
    property color accentColor: "#68787D"

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 0

            Item {
                width: parent.width
                height: 118

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 18

                    Text {
                        text: "󰣇"
                        color: root.accentColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 48
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: "Hypr-Lab 1.5"
                            color: "white"
                            font.family: "Inter"
                            font.pixelSize: 20
                            font.bold: true
                            font.italic: true
                        }

                        Text {
                            text: "Arch · Hyprland · Quickshell"
                            color: Qt.rgba(1, 1, 1, 0.48)
                            font.family: "Inter"
                            font.pixelSize: 10
                            font.italic: true
                        }

                        Text {
                            text: "Development branch: develop-v1.5"
                            color: root.accentColor
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                        }
                    }
                }
            }

            SectionLabel {
                width: parent.width
                text: "SYSTEM"
                accentColor: root.accentColor
            }

            Repeater {
                model: [
                    ["System", backend ? backend.osName : "—"],
                    ["Uptime", backend ? backend.uptime : "—"],
                    ["Kernel", backend ? backend.kernel : "—"],
                    ["Memory", backend ? backend.memory : "—"],
                    ["CPU", backend ? backend.cpu : "—"],
                    ["VGA / GPU", backend ? backend.gpu : "—"],
                    ["HDD", backend ? backend.hdd : "—"],
                    ["SSD", backend ? backend.ssd : "—"],
                    ["NVMe", backend ? backend.nvme : "—"],
                    ["Monitor", backend ? backend.monitors : "—"]
                ]

                delegate: Item {
                    required property var modelData
                    width: col.width
                    height: Math.max(44, valueText.implicitHeight + 18)

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 120
                        text: modelData[0]
                        color: root.accentColor
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                        font.bold: true
                    }

                    Text {
                        id: valueText
                        anchors.left: parent.left
                        anchors.leftMargin: 138
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData[1]
                        color: Qt.rgba(1, 1, 1, 0.70)
                        font.family: "Inter"
                        font.pixelSize: 9
                        font.italic: true
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.045)
                    }
                }
            }

            SettingAction {
                width: parent.width
                accentColor: root.accentColor
                title: "Refresh system information"
                subtitle: "Refresh hardware, monitor and runtime information"
                icon: "󰑐"
                buttonText: "REFRESH"
                onTriggered: backend.refresh()
            }

            SectionLabel {
                width: parent.width
                text: "PROJECT"
                accentColor: root.accentColor
            }

            SettingAction {
                width: parent.width
                accentColor: root.accentColor
                title: "Hypr-Lab on GitHub"
                subtitle: "Open the project repository in your browser"
                icon: "󰊤"
                buttonText: "OPEN"
                onTriggered: Qt.openUrlExternally("https://github.com/hu-nadam0607/Hypr-Lab")
            }

            SettingAction {
                width: parent.width
                accentColor: root.accentColor
                title: "develop-v1.5 branch"
                subtitle: "Open the current development branch"
                icon: "󰘬"
                buttonText: "OPEN"
                onTriggered: Qt.openUrlExternally("https://github.com/hu-nadam0607/Hypr-Lab/tree/develop-v1.5")
            }
        }
    }

    Component.onCompleted: {
        if (backend)
            backend.refresh()
    }
}
