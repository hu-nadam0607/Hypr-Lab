//@ pragma AppId hypr-lab-settings
import QtQuick
import Quickshell
import "components"

FloatingWindow {
    id: settingsWindow

    title: "Hypr-Lab Settings"
    visible: true
    color: "transparent"

    implicitWidth: 1120
    implicitHeight: 720
    minimumSize: Qt.size(960, 620)

    property string currentPage: "lockpower"
    property bool entered: false

    readonly property var pages: [
        { id: "appearance", icon: "󰏘", title: "Appearance", available: false, description: "Wallpaper, shell appearance and adaptive visual options will live here." },
        { id: "desktop", icon: "󰍹", title: "Desktop", available: false, description: "Workspace names, Desktop Overview and workspace behavior will be added here." },
        { id: "topbar", icon: "󰕮", title: "Top Bar", available: false, description: "TopBar modules, tray and shell module visibility will be configurable here." },
        { id: "lockpower", icon: "󰌾", title: "Lock & Power", available: true, description: "Lock, display standby and suspend behavior." },
        { id: "audio", icon: "󰕾", title: "Audio & Media", available: false, description: "Audio, CAVA and MPRIS behavior will be added here." },
        { id: "notifications", icon: "󰂚", title: "Notifications", available: false, description: "DND and notification behavior will be added here." },
        { id: "input", icon: "󰌌", title: "Input & Keybinds", available: false, description: "Hypr-Lab keybind discovery and editing will be added here." },
        { id: "system", icon: "󰒋", title: "System", available: false, description: "Display, application defaults and system integration will be migrated here." },
        { id: "about", icon: "󰋼", title: "About", available: false, description: "Version, branch, update and project information will be added here." }
    ]

    function pageData(id) {
        for (let p of pages)
            if (p.id === id)
                return p
        return pages[3]
    }

    function selectPage(id) {
        currentPage = id
        pageBody.opacity = 0
        pageReset.restart()
    }

    function closeSettings() {
        rootSurface.opacity = 0
        rootSurface.scale = 0.985
        closeTimer.restart()
    }

    AccentReader { id: accentReader }
    PowerBackend { id: powerBackend }

    Item {
        id: rootSurface
        anchors.fill: parent
        anchors.margins: 12
        opacity: settingsWindow.entered ? 1 : 0
        scale: settingsWindow.entered ? 1 : 0.975

        Behavior on opacity { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        // Plain application surface. Hyprland owns the outer window border.
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(7 / 255, 11 / 255, 16 / 255, 0.95)
        }

        Rectangle {
            x: 0
            y: 1
            width: parent.width
            height: 1
            color: Qt.rgba(1, 1, 1, 0.055)
        }

        Item {
            id: titleBar
            x: 28
            y: 14
            width: parent.width - 56
            height: 52

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Text {
                    text: "󰣇"
                    color: accentReader.accentColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 20
                }

                Column {
                    spacing: 1
                    Text { text: "HYPR-LAB SETTINGS"; color:"white"; font.family:"Inter"; font.pixelSize:13; font.bold:true; font.italic:true; font.letterSpacing:1.1 }
                    Text { text: "v1.5 · system configuration"; color:Qt.rgba(1,1,1,0.35); font.family:"Inter"; font.pixelSize:8; font.italic:true }
                }
            }

            Text {
                anchors.right: closeButton.left
                anchors.rightMargin: 22
                anchors.verticalCenter: parent.verticalCenter
                text: powerBackend.statusText
                color: powerBackend.statusText === "Applied" ? accentReader.accentColor : Qt.rgba(1,1,1,0.30)
                font.family: "Inter"
                font.pixelSize: 8
                font.bold: true
                font.italic: true
            }

            Item {
                id: closeButton
                width: 32
                height: 32
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: closeMouse.containsMouse ? accentReader.accentColor : Qt.rgba(1,1,1,0.62)
                    font.family: "Inter"
                    font.pixelSize: 20
                    font.bold: true
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsWindow.closeSettings()
                }
            }

            MouseArea {
                anchors.left: parent.left
                anchors.right: closeButton.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                acceptedButtons: Qt.LeftButton
                onPressed: settingsWindow.startSystemMove()
            }
        }

        Rectangle {
            x: 28
            y: 74
            width: parent.width - 56
            height: 1
            color: Qt.rgba(accentReader.accentColor.r, accentReader.accentColor.g, accentReader.accentColor.b, 0.16)
        }

        Item {
            id: navigation
            x: 28
            y: 92
            width: 230
            height: parent.height - 120

            Column {
                anchors.fill: parent
                spacing: 2

                Repeater {
                    model: settingsWindow.pages

                    NavItem {
                        required property var modelData
                        width: navigation.width
                        icon: modelData.icon
                        title: modelData.title
                        pageId: modelData.id
                        selected: settingsWindow.currentPage === modelData.id
                        available: modelData.available
                        accentColor: accentReader.accentColor
                        onTriggered: pageId => settingsWindow.selectPage(pageId)
                    }
                }
            }
        }

        Rectangle {
            x: 274
            y: 92
            width: 1
            height: parent.height - 120
            color: Qt.rgba(1, 1, 1, 0.065)
        }

        Item {
            id: pageContainer
            x: 302
            y: 94
            width: parent.width - 338
            height: parent.height - 128

            Column {
                id: pageHeader
                width: parent.width
                spacing: 4

                Text {
                    text: settingsWindow.pageData(settingsWindow.currentPage).title.toUpperCase()
                    color: "white"
                    font.family: "Inter"
                    font.pixelSize: 17
                    font.bold: true
                    font.italic: true
                    font.letterSpacing: 0.9
                }

                Text {
                    width: parent.width
                    text: settingsWindow.pageData(settingsWindow.currentPage).description
                    color: Qt.rgba(1,1,1,0.38)
                    font.family: "Inter"
                    font.pixelSize: 9
                    font.italic: true
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                y: 58
                height: 1
                color: Qt.rgba(accentReader.accentColor.r, accentReader.accentColor.g, accentReader.accentColor.b, 0.15)
            }

            Item {
                id: pageBody
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 78
                anchors.bottom: parent.bottom
                opacity: 1

                Behavior on opacity { NumberAnimation { duration: 120 } }

                LockPowerPage {
                    anchors.fill: parent
                    visible: settingsWindow.currentPage === "lockpower"
                    backend: powerBackend
                    accentColor: accentReader.accentColor
                }

                PlaceholderPage {
                    anchors.fill: parent
                    visible: settingsWindow.currentPage !== "lockpower"
                    title: settingsWindow.pageData(settingsWindow.currentPage).title
                    description: settingsWindow.pageData(settingsWindow.currentPage).description
                    accentColor: accentReader.accentColor
                }
            }
        }
    }

    Timer {
        id: pageReset
        interval: 80
        repeat: false
        onTriggered: pageBody.opacity = 1
    }

    Timer {
        id: closeTimer
        interval: 180
        repeat: false
        onTriggered: Qt.quit()
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: settingsWindow.closeSettings()
        z: -1
    }

    Component.onCompleted: entered = true
    onClosed: Qt.quit()
}
