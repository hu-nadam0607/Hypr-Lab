import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property bool isOpen: false
    property bool windowVisible: false
    property bool contentVisible: false
    property bool english: false
    property bool autoShowDisabled: false
    property real borderProgress: 0.0
    property bool showAllBinds: false

    function tr(hu, en) {
        return english ? en : hu
    }

    function open() {
        closeTimer.stop()
        windowVisible = true
        isOpen = true
        contentVisible = true
        borderProgress = 1.0
        showAllBinds = false
    }

    function close() {
        if (!windowVisible)
            return
        isOpen = false
        contentVisible = false
        borderProgress = 0.0
        closeTimer.restart()
    }

    function toggle() {
        if (isOpen)
            close()
        else
            open()
    }

    function setAutoShowDisabled(disabled) {
        autoShowDisabled = disabled
        if (disabled) {
            Quickshell.execDetached([
                "sh", "-c",
                "mkdir -p \"$HOME/.config/quickshell\" && touch \"$HOME/.config/quickshell/.welcome-disabled\""
            ])
        } else {
            Quickshell.execDetached([
                "sh", "-c",
                "rm -f \"$HOME/.config/quickshell/.welcome-disabled\""
            ])
        }
    }

    IpcHandler {
        target: "welcome"

        function open() { root.open() }
        function close() { root.close() }
        function toggle() { root.toggle() }
    }

    Process {
        id: startupProbe
        command: [
            "sh", "-c",
            "test -f \"$HOME/.config/quickshell/.welcome-disabled\""
        ]
        running: true

        onExited: (exitCode, exitStatus) => {
            root.autoShowDisabled = (exitCode === 0)
            if (!root.autoShowDisabled)
                root.open()
        }
    }

    Timer {
        id: closeTimer
        interval: 230
        repeat: false
        onTriggered: {
            if (!root.isOpen)
                root.windowVisible = false
        }
    }

    Behavior on borderProgress {
        NumberAnimation {
            duration: root.isOpen ? 420 : 190
            easing.type: root.isOpen ? Easing.OutCubic : Easing.InCubic
        }
    }

    PanelWindow {
        id: welcomeWindow

        visible: root.windowVisible
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        aboveWindows: true

        WlrLayershell.namespace: "hypr-lab-welcome"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        FocusScope {
            anchors.fill: parent
            focus: welcomeWindow.visible

            Keys.onEscapePressed: root.close()

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(4/255, 8/255, 12/255, 0.24)
                opacity: root.contentVisible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            Item {
                id: cardWrap
                anchors.centerIn: parent
                width: Math.min(820, parent.width - 80)
                height: Math.min(650, parent.height - 70)

                opacity: root.contentVisible ? 1 : 0
                scale: root.contentVisible ? 1 : 0.965

                Behavior on opacity {
                    NumberAnimation { duration: root.isOpen ? 220 : 150; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: root.isOpen ? 260 : 170; easing.type: Easing.OutCubic }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => mouse.accepted = true
                }

                Rectangle {
                    id: card
                    anchors.fill: parent
                    radius: 24
                    color: Qt.rgba(8/255, 14/255, 19/255, 0.82)
                    // Egységes, 2 px-es Hypr-Lab cyan keret.
                    // Nincs külön felső highlight vagy belső második border,
                    // így minden oldalon azonos vastagságú marad.
                    border.width: 2
                    border.color: Qt.rgba(55/255, 245/255, 235/255, 0.34)
                }

                Item {
                    id: welcomeMainPage
                    anchors.fill: parent
                    visible: !root.showAllBinds
                    opacity: root.showAllBinds ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 38
                        spacing: 0

                    Item {
                        width: parent.width
                        height: 72

                        Column {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                text: "HYPR-LAB"
                                color: "#37f5eb"
                                font.family: "Inter"
                                font.pixelSize: 14
                                font.bold: true
                                font.letterSpacing: 3.1
                            }

                            Text {
                                text: root.tr("Üdvözlünk a laborban.", "Welcome to the lab.")
                                color: "#edf7f8"
                                font.family: "Inter"
                                font.pixelSize: 27
                                font.bold: true
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 122
                            height: 34
                            radius: 17
                            color: Qt.rgba(1, 1, 1, 0.045)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.07)

                            Rectangle {
                                x: root.english ? parent.width / 2 + 2 : 2
                                y: 2
                                width: parent.width / 2 - 4
                                height: parent.height - 4
                                radius: 15
                                color: Qt.rgba(55/255, 245/255, 235/255, 0.14)
                                border.width: 1
                                border.color: Qt.rgba(55/255, 245/255, 235/255, 0.30)

                                Behavior on x {
                                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                }
                            }

                            Row {
                                anchors.fill: parent

                                Repeater {
                                    model: ["HU", "EN"]
                                    Item {
                                        width: 61
                                        height: 34
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: ((index === 1) === root.english) ? "#37f5eb" : Qt.rgba(1,1,1,0.48)
                                            font.family: "Inter"
                                            font.pixelSize: 10
                                            font.bold: true
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.english = (index === 1)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: root.tr(
                            "A Hypr-Lab egy gyors, letisztult és személyre szabható Hyprland környezet. Az alapok már készen állnak — az alábbi gyorsbillentyűkkel azonnal elindulhatsz.",
                            "Hypr-Lab is a fast, clean and customizable Hyprland environment. The essentials are already in place — use these shortcuts to get moving immediately."
                        )
                        color: Qt.rgba(226/255, 238/255, 240/255, 0.64)
                        font.family: "Inter"
                        font.pixelSize: 13
                        lineHeight: 1.35
                        wrapMode: Text.WordWrap
                    }

                    Item { width: 1; height: 25 }

                    Row {
                        width: parent.width
                        height: 155
                        spacing: 12

                        Repeater {
                            model: [
                                { icon: "󰀻", key: "SUPER + SPACE", hu: "Alkalmazások", en: "Applications", hud: "Nyisd meg a Hypr-Lab launchert.", end: "Open the Hypr-Lab launcher." },
                                { icon: "󰏘", key: "SUPER + SHIFT + W", hu: "Háttérképek", en: "Wallpapers", hud: "Válassz hátteret és animációt.", end: "Choose a wallpaper and transition." },
                                { icon: "󰒓", key: "SUPER + SHIFT + C", hu: "Vezérlőközpont", en: "Control Center", hud: "Hang, média és gyorsbeállítások.", end: "Audio, media and quick controls." }
                            ]

                            Rectangle {
                                width: (parent.width - 24) / 3
                                height: 155
                                radius: 17
                                color: tileMouse.containsMouse ? Qt.rgba(55/255,245/255,235/255,0.075) : Qt.rgba(1,1,1,0.027)
                                border.width: 1
                                border.color: tileMouse.containsMouse ? Qt.rgba(55/255,245/255,235/255,0.22) : Qt.rgba(1,1,1,0.055)

                                Behavior on color { ColorAnimation { duration: 130 } }
                                Behavior on border.color { ColorAnimation { duration: 130 } }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 7

                                    Text {
                                        text: modelData.icon
                                        color: "#37f5eb"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 22
                                    }
                                    Text {
                                        text: root.english ? modelData.en : modelData.hu
                                        color: "#e6f2f3"
                                        font.family: "Inter"
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                    Text {
                                        width: parent.width
                                        text: root.english ? modelData.end : modelData.hud
                                        color: Qt.rgba(1,1,1,0.45)
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        wrapMode: Text.WordWrap
                                    }
                                    Item { width: 1; height: 1 }
                                    Rectangle {
                                        width: keyText.implicitWidth + 16
                                        height: 24
                                        radius: 8
                                        color: Qt.rgba(0,0,0,0.20)
                                        border.width: 1
                                        border.color: Qt.rgba(55/255,245/255,235/255,0.14)
                                        Text {
                                            id: keyText
                                            anchors.centerIn: parent
                                            text: modelData.key
                                            color: Qt.rgba(55/255,245/255,235/255,0.76)
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }
                                }

                                MouseArea {
                                    id: tileMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 12 }

                    Row {
                        width: parent.width
                        height: 125
                        spacing: 12

                        Repeater {
                            model: [
                                { icon: "󰆍", key: "SUPER + C", hu: "Terminál", en: "Terminal", hud: "Nyisd meg a Ghostty terminált.", end: "Open the Ghostty terminal." },
                                { icon: "󰖲", key: "SUPER + 1–9", hu: "Munkaterületek", en: "Workspaces", hud: "Válts gyorsan a munkaterületek között.", end: "Quickly switch between workspaces." },
                                { icon: "󰗼", key: "SUPER + M", hu: "Kilépés a sessionből", en: "Exit session", hud: "Bármikor kiléphetsz a Hyprland sessionből.", end: "Exit the Hyprland session at any time." }
                            ]

                            Rectangle {
                                width: (parent.width - 24) / 3
                                height: 125
                                radius: 17
                                color: extraTileMouse.containsMouse ? Qt.rgba(55/255,245/255,235/255,0.075) : Qt.rgba(1,1,1,0.027)
                                border.width: 1
                                border.color: extraTileMouse.containsMouse ? Qt.rgba(55/255,245/255,235/255,0.22) : Qt.rgba(1,1,1,0.055)

                                Behavior on color { ColorAnimation { duration: 130 } }
                                Behavior on border.color { ColorAnimation { duration: 130 } }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 5

                                    Row {
                                        width: parent.width
                                        spacing: 8
                                        Text {
                                            text: modelData.icon
                                            color: "#37f5eb"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 19
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: root.english ? modelData.en : modelData.hu
                                            color: "#e6f2f3"
                                            font.family: "Inter"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }
                                    Text {
                                        width: parent.width
                                        text: root.english ? modelData.end : modelData.hud
                                        color: Qt.rgba(1,1,1,0.45)
                                        font.family: "Inter"
                                        font.pixelSize: 9
                                        wrapMode: Text.WordWrap
                                    }
                                    Rectangle {
                                        width: extraKeyText.implicitWidth + 16
                                        height: 22
                                        radius: 8
                                        color: Qt.rgba(0,0,0,0.20)
                                        border.width: 1
                                        border.color: Qt.rgba(55/255,245/255,235/255,0.14)
                                        Text {
                                            id: extraKeyText
                                            anchors.centerIn: parent
                                            text: modelData.key
                                            color: Qt.rgba(55/255,245/255,235/255,0.76)
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }
                                }

                                MouseArea {
                                    id: extraTileMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 16 }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Qt.rgba(1,1,1,0.055)
                    }

                    Item { width: 1; height: 18 }

                    Item {
                        width: parent.width
                        height: 48

                        Rectangle {
                            id: beginButton
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 160
                            height: 40
                            radius: 13
                            color: beginMouse.containsMouse ? Qt.rgba(55/255,245/255,235/255,0.17) : Qt.rgba(55/255,245/255,235/255,0.10)
                            border.width: 1
                            border.color: Qt.rgba(55/255,245/255,235/255, beginMouse.containsMouse ? 0.52 : 0.30)

                            Text {
                                anchors.centerIn: parent
                                text: root.tr("Kezdjük  ❯", "Let's begin  ❯")
                                color: "#37f5eb"
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                id: beginMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.close()
                            }
                        }

                        Rectangle {
                            id: allBindsButton
                            anchors.left: beginButton.right
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 150
                            height: 40
                            radius: 13
                            color: allBindsMouse.containsMouse ? Qt.rgba(1,1,1,0.075) : Qt.rgba(1,1,1,0.035)
                            border.width: 1
                            border.color: allBindsMouse.containsMouse ? Qt.rgba(55/255,245/255,235/255,0.30) : Qt.rgba(1,1,1,0.08)

                            Row {
                                anchors.centerIn: parent
                                spacing: 7

                                Text {
                                    text: "󰌌"
                                    color: "#37f5eb"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                }

                                Text {
                                    text: root.tr("Összes bind", "All shortcuts")
                                    color: "#dfeaec"
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: allBindsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.showAllBinds = true
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 11

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    anchors.right: parent.right
                                    text: root.tr("Megjelenítés induláskor", "Show on startup")
                                    color: "#dfeaec"
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                                Text {
                                    anchors.right: parent.right
                                    text: root.tr("SUPER + ALT + W-vel bármikor visszahívható", "Always available with SUPER + ALT + W")
                                    color: Qt.rgba(1,1,1,0.34)
                                    font.family: "Inter"
                                    font.pixelSize: 9
                                }
                            }

                            Rectangle {
                                id: startupSwitch
                                width: 52
                                height: 28
                                radius: 14
                                color: root.autoShowDisabled ? Qt.rgba(1,1,1,0.075) : Qt.rgba(55/255,245/255,235/255,0.16)
                                border.width: 1
                                border.color: root.autoShowDisabled ? Qt.rgba(1,1,1,0.11) : Qt.rgba(55/255,245/255,235/255,0.42)

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    y: 4
                                    x: root.autoShowDisabled ? 4 : 28
                                    color: root.autoShowDisabled ? Qt.rgba(1,1,1,0.46) : "#37f5eb"

                                    Behavior on x {
                                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setAutoShowDisabled(!root.autoShowDisabled)
                                }
                            }
                        }
                    }
                }
                }

                Item {
                    id: bindsPage
                    anchors.fill: parent
                    visible: root.showAllBinds
                    opacity: root.showAllBinds ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 30
                        spacing: 14

                        Item {
                            width: parent.width
                            height: 50

                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 36
                                height: 36
                                radius: 18
                                color: backMouse.containsMouse ? Qt.rgba(55/255,245/255,235/255,0.13) : Qt.rgba(1,1,1,0.045)
                                border.width: 1
                                border.color: backMouse.containsMouse ? Qt.rgba(55/255,245/255,235/255,0.34) : Qt.rgba(1,1,1,0.08)

                                Text {
                                    anchors.centerIn: parent
                                    text: "←"
                                    color: "#37f5eb"
                                    font.family: "Inter"
                                    font.pixelSize: 20
                                    font.bold: true
                                }

                                MouseArea {
                                    id: backMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.showAllBinds = false
                                }
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: root.tr("Összes gyorsbillentyű", "All shortcuts")
                                    color: "#edf7f8"
                                    font.family: "Inter"
                                    font.pixelSize: 19
                                    font.bold: true
                                }

                                Text {
                                    text: root.tr("A Hypr-Lab v1.0 aktuális bindlistája", "Current Hypr-Lab v1.0 shortcut reference")
                                    color: Qt.rgba(1,1,1,0.40)
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 88
                                height: 28
                                radius: 14
                                color: Qt.rgba(1,1,1,0.045)
                                border.width: 1
                                border.color: Qt.rgba(1,1,1,0.07)

                                Row {
                                    anchors.fill: parent
                                    Repeater {
                                        model: ["HU", "EN"]
                                        Item {
                                            width: 44
                                            height: 28
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: ((index === 1) === root.english) ? "#37f5eb" : Qt.rgba(1,1,1,0.42)
                                                font.family: "Inter"
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.english = (index === 1)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Qt.rgba(1,1,1,0.055)
                        }

                        ListView {
                            id: bindsList
                            width: parent.width
                            height: parent.height - 66
                            clip: true
                            spacing: 7

                            model: [
                                { groupHu:"HYPR-LAB", groupEn:"HYPR-LAB", key:"SUPER + SPACE", hu:"Alkalmazásindító megnyitása / bezárása", en:"Open / close the App Launcher" },
                                { groupHu:"HYPR-LAB", groupEn:"HYPR-LAB", key:"SUPER + SHIFT + C", hu:"Control Center megnyitása; Audio oldalról vissza a főoldalra", en:"Open Control Center; return to the main page from Audio" },
                                { groupHu:"HYPR-LAB", groupEn:"HYPR-LAB", key:"SUPER + SHIFT + V", hu:"Control Center megnyitása közvetlenül az Audio panelen", en:"Open Control Center directly on the Audio page" },
                                { groupHu:"HYPR-LAB", groupEn:"HYPR-LAB", key:"SUPER + SHIFT + N", hu:"Értesítési központ megnyitása / bezárása", en:"Open / close the Notification Center" },
                                { groupHu:"HYPR-LAB", groupEn:"HYPR-LAB", key:"SUPER + SHIFT + D", hu:"Ne zavarjanak mód be- / kikapcsolása", en:"Toggle Do Not Disturb" },
                                { groupHu:"HYPR-LAB", groupEn:"HYPR-LAB", key:"SUPER + W", hu:"Véletlen háttérkép véletlen átmenettel", en:"Random wallpaper with a random transition" },
                                { groupHu:"HYPR-LAB", groupEn:"HYPR-LAB", key:"SUPER + SHIFT + W", hu:"Háttérképválasztó megnyitása / bezárása", en:"Open / close the Wallpaper Picker" },
                                { groupHu:"HYPR-LAB", groupEn:"HYPR-LAB", key:"SUPER + ALT + W", hu:"Üdvözlőképernyő megnyitása / bezárása", en:"Open / close this Welcome Screen" },
                                { groupHu:"HYPR-LAB", groupEn:"HYPR-LAB", key:"SUPER + SHIFT + P", hu:"Power menü megnyitása / bezárása", en:"Open / close the Power Menu" },
                                { groupHu:"HYPR-LAB", groupEn:"HYPR-LAB", key:"SUPER + L", hu:"Session lezárása a Hypr-Lab Lockkal", en:"Lock the session with Hypr-Lab Lock" },
                                { groupHu:"HYPR-LAB", groupEn:"HYPR-LAB", key:"SUPER + ALT + A", hu:"Ablakkeret glow animáció be- / kikapcsolása", en:"Toggle the window-border glow animation" },

                                { groupHu:"ALKALMAZÁSOK", groupEn:"APPLICATIONS", key:"SUPER + C", hu:"Ghostty terminál megnyitása", en:"Open the Ghostty terminal" },
                                { groupHu:"ALKALMAZÁSOK", groupEn:"APPLICATIONS", key:"SUPER + B", hu:"Beállított alapértelmezett böngésző megnyitása", en:"Open the configured default browser" },
                                { groupHu:"ALKALMAZÁSOK", groupEn:"APPLICATIONS", key:"SUPER + E", hu:"Beállított fájlkezelő megnyitása", en:"Open the configured file manager" },
                                { groupHu:"ALKALMAZÁSOK", groupEn:"APPLICATIONS", key:"SUPER + SHIFT + B", hu:"Blender megnyitása", en:"Open Blender" },

                                { groupHu:"ABLAKOK", groupEn:"WINDOWS", key:"SUPER + Q", hu:"Aktív ablak bezárása", en:"Close the active window" },
                                { groupHu:"ABLAKOK", groupEn:"WINDOWS", key:"SUPER + T", hu:"Aktív ablak lebegő / csempézett módjának váltása", en:"Toggle floating / tiled mode for the active window" },
                                { groupHu:"ABLAKOK", groupEn:"WINDOWS", key:"SUPER + F", hu:"Aktív ablak teljes képernyős módja", en:"Toggle fullscreen for the active window" },
                                { groupHu:"ABLAKOK", groupEn:"WINDOWS", key:"SUPER + ← / → / ↑ / ↓", hu:"Fókusz mozgatása a szomszédos ablakokra", en:"Move focus between neighboring windows" },
                                { groupHu:"ABLAKOK", groupEn:"WINDOWS", key:"SUPER + CTRL + ← / → / ↑ / ↓", hu:"Aktív ablak átméretezése 100 pixeles lépésekben", en:"Resize the active window in 100-pixel steps" },
                                { groupHu:"ABLAKOK", groupEn:"WINDOWS", key:"SUPER + BAL EGÉR", hu:"Lebegő ablak mozgatása húzással", en:"Drag a floating window" },
                                { groupHu:"ABLAKOK", groupEn:"WINDOWS", key:"SUPER + JOBB EGÉR", hu:"Lebegő ablak átméretezése húzással", en:"Resize a floating window by dragging" },
                                { groupHu:"ABLAKOK", groupEn:"WINDOWS", key:"SUPER + J", hu:"Split irányának váltása", en:"Toggle the split direction" },
                                { groupHu:"ABLAKOK", groupEn:"WINDOWS", key:"SUPER + K", hu:"A split két oldalának felcserélése", en:"Swap the two sides of the split" },

                                { groupHu:"MUNKATERÜLETEK", groupEn:"WORKSPACES", key:"SUPER + 1–0", hu:"Váltás az 1–10. munkaterületre", en:"Switch to workspace 1–10" },
                                { groupHu:"MUNKATERÜLETEK", groupEn:"WORKSPACES", key:"SUPER + SHIFT + 1–0", hu:"Aktív ablak áthelyezése az 1–10. munkaterületre", en:"Move the active window to workspace 1–10" },

                                { groupHu:"KÉPERNYŐKÉP", groupEn:"SCREENSHOTS", key:"SUPER + SHIFT + S", hu:"Kijelölt terület képernyőmentése", en:"Capture a selected area" },
                                { groupHu:"KÉPERNYŐKÉP", groupEn:"SCREENSHOTS", key:"SUPER + SHIFT + A", hu:"Teljes képernyő mentése", en:"Capture the full screen" },

                                { groupHu:"MÉDIA", groupEn:"MEDIA", key:"HANGERŐ + / −", hu:"Rendszerhangerő növelése / csökkentése", en:"Raise / lower system volume" },
                                { groupHu:"MÉDIA", groupEn:"MEDIA", key:"NÉMÍTÁS", hu:"Rendszerhang némítása / visszakapcsolása", en:"Mute / unmute system audio" },
                                { groupHu:"MÉDIA", groupEn:"MEDIA", key:"PLAY / PAUSE", hu:"Médialejátszás indítása / szüneteltetése", en:"Play / pause media" },
                                { groupHu:"MÉDIA", groupEn:"MEDIA", key:"ELŐZŐ / KÖVETKEZŐ", hu:"Előző / következő médiaszám", en:"Previous / next media track" },

                                { groupHu:"SESSION", groupEn:"SESSION", key:"SUPER + M", hu:"Kilépés a Hyprland sessionből", en:"Exit the Hyprland session" }
                            ]

                            delegate: Column {
                                required property var modelData
                                required property int index
                                width: bindsList.width
                                spacing: 5

                                Text {
                                    visible: index === 0
                                        || bindsList.model[index - 1].groupHu !== modelData.groupHu
                                    height: visible ? 20 : 0
                                    text: root.english ? modelData.groupEn : modelData.groupHu
                                    color: Qt.rgba(55/255,245/255,235/255,0.66)
                                    font.family: "Inter"
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 1.5
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 48
                                    radius: 13
                                    color: bindMouse.containsMouse ? Qt.rgba(55/255,245/255,235/255,0.055) : Qt.rgba(1,1,1,0.025)
                                    border.width: 1
                                    border.color: bindMouse.containsMouse ? Qt.rgba(55/255,245/255,235/255,0.18) : Qt.rgba(1,1,1,0.05)

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.min(220, bindKey.implicitWidth + 20)
                                        height: 27
                                        radius: 9
                                        color: Qt.rgba(0,0,0,0.20)
                                        border.width: 1
                                        border.color: Qt.rgba(55/255,245/255,235/255,0.14)

                                        Text {
                                            id: bindKey
                                            anchors.centerIn: parent
                                            text: modelData.key
                                            color: "#37f5eb"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 240
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.english ? modelData.en : modelData.hu
                                        color: "#dfeaec"
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        id: bindMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.NoButton
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
