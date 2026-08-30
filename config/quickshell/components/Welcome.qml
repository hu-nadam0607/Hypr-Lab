import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property color accentColor: "#68787D"

    readonly property color surfaceColor: Qt.rgba(12 / 255, 15 / 255, 18 / 255, 0.88)
    readonly property color cardColor: Qt.rgba(1, 1, 1, 0.027)
    readonly property color dividerColor: Qt.rgba(1, 1, 1, 0.055)
    readonly property color cardBorderColor: Qt.rgba(1, 1, 1, 0.055)

    property bool isOpen: false
    property bool windowVisible: false
    property bool contentVisible: false
    property bool english: false
    property bool autoShowDisabled: false
    property bool showAllBinds: false

    function tr(hu, en) {
        return english ? en : hu;
    }

    function accent(alpha) {
        return Qt.rgba(accentColor.r, accentColor.g, accentColor.b, alpha);
    }

    function open() {
        closeTimer.stop();
        windowVisible = true;
        isOpen = true;
        contentVisible = true;
        showAllBinds = false;
    }

    function close() {
        if (!windowVisible)
            return;
        isOpen = false;
        contentVisible = false;
        closeTimer.restart();
    }

    function toggle() {
        if (isOpen)
            close();
        else
            open();
    }

    function setAutoShowDisabled(disabled) {
        autoShowDisabled = disabled;
        if (disabled) {
            Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/.config/quickshell\" && touch \"$HOME/.config/quickshell/.welcome-disabled\""]);
        } else {
            Quickshell.execDetached(["sh", "-c", "rm -f \"$HOME/.config/quickshell/.welcome-disabled\""]);
        }
    }

    IpcHandler {
        target: "welcome"

        function open() {
            root.open();
        }
        function close() {
            root.close();
        }
        function toggle() {
            root.toggle();
        }
    }

    Process {
        id: startupProbe
        command: ["sh", "-c", "test -f \"$HOME/.config/quickshell/.welcome-disabled\""]
        running: true

        onExited: (exitCode, exitStatus) => {
            root.autoShowDisabled = (exitCode === 0);
            if (!root.autoShowDisabled)
                root.open();
        }
    }

    Timer {
        id: closeTimer
        interval: 230
        repeat: false
        onTriggered: {
            if (!root.isOpen)
                root.windowVisible = false;
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
                color: Qt.rgba(4 / 255, 8 / 255, 12 / 255, 0.24)
                opacity: root.contentVisible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
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
                    NumberAnimation {
                        duration: root.isOpen ? 220 : 150
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: root.isOpen ? 260 : 170
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => mouse.accepted = true
                }

                Rectangle {
                    id: card
                    anchors.fill: parent
                    radius: 1
                    color: root.surfaceColor

                    border.width: 2
                    border.color: root.accent(0.42)
                }

                Item {
                    id: welcomeMainPage
                    anchors.fill: parent
                    visible: !root.showAllBinds
                    opacity: root.showAllBinds ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
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
                                    color: root.accentColor
                                    font.family: "Inter"
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.letterSpacing: 3.1
                                }

                                Text {
                                    text: root.tr("Üdvözlünk a laborban.", "Welcome to the lab.")
                                    color: root.accentColor
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
                                radius: 1
                                color: root.cardColor
                                border.width: 1
                                border.color: root.cardBorderColor

                                Rectangle {
                                    x: root.english ? parent.width / 2 + 2 : 2
                                    y: 2
                                    width: parent.width / 2 - 4
                                    height: parent.height - 4
                                    radius: 1
                                    color: root.accent(0.10)

                                    border.width: 1
                                    border.color: root.accent(0.42)

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutCubic
                                        }
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
                                                color: ((index === 1) === root.english) ? root.accentColor : Qt.rgba(1, 1, 1, 0.48)

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }
                                                }

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
                            text: root.tr("A Hypr-Lab egy gyors, letisztult és személyre szabható Hyprland környezet. Az alapok már készen állnak — az alábbi gyorsbillentyűkkel azonnal elindulhatsz.", "Hypr-Lab is a fast, clean and customizable Hyprland environment. The essentials are already in place — use these shortcuts to get moving immediately.")
                            color: Qt.rgba(226 / 255, 238 / 255, 240 / 255, 0.64)
                            font.family: "Inter"
                            font.pixelSize: 13
                            lineHeight: 1.35
                            wrapMode: Text.WordWrap
                        }

                        Item {
                            width: 1
                            height: 25
                        }

                        Row {
                            width: parent.width
                            height: 155
                            spacing: 12

                            Repeater {
                                model: [
                                    {
                                        icon: "󰀻",
                                        key: "SUPER + SPACE",
                                        hu: "Alkalmazások",
                                        en: "Applications",
                                        hud: "Nyisd meg a Hypr-Lab launchert.",
                                        end: "Open the Hypr-Lab launcher."
                                    },
                                    {
                                        icon: "󰏘",
                                        key: "SUPER + SHIFT + W",
                                        hu: "Háttérképek",
                                        en: "Wallpapers",
                                        hud: "Válassz hátteret és animációt.",
                                        end: "Choose a wallpaper and transition."
                                    },
                                    {
                                        icon: "󰒓",
                                        key: "SUPER + SHIFT + C",
                                        hu: "Vezérlőközpont",
                                        en: "Control Center",
                                        hud: "Hang, média és gyorsbeállítások.",
                                        end: "Audio, media and quick controls."
                                    }
                                ]

                                Rectangle {
                                    width: (parent.width - 24) / 3
                                    height: 155
                                    radius: 1
                                    color: tileMouse.containsMouse ? root.accent(0.055) : root.cardColor

                                    border.width: 1
                                    border.color: tileMouse.containsMouse ? root.accent(0.34) : root.cardBorderColor

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 130
                                        }
                                    }
                                    Behavior on border.color {
                                        ColorAnimation {
                                            duration: 130
                                        }
                                    }

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 16
                                        spacing: 7

                                        Text {
                                            text: modelData.icon
                                            color: root.accentColor
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 22
                                        }
                                        Text {
                                            text: root.english ? modelData.en : modelData.hu
                                            color: root.accentColor
                                            font.family: "Inter"
                                            font.pixelSize: 12
                                            font.bold: true
                                        }
                                        Text {
                                            width: parent.width
                                            text: root.english ? modelData.end : modelData.hud
                                            color: Qt.rgba(1, 1, 1, 0.45)
                                            font.family: "Inter"
                                            font.pixelSize: 10
                                            wrapMode: Text.WordWrap
                                        }
                                        Item {
                                            width: 1
                                            height: 1
                                        }
                                        Rectangle {
                                            width: keyText.implicitWidth + 16
                                            height: 24
                                            radius: 1
                                            color: Qt.rgba(0, 0, 0, 0.20)
                                            border.width: 1
                                            border.color: root.accent(0.28)
                                            Text {
                                                id: keyText
                                                anchors.centerIn: parent
                                                text: modelData.key
                                                color: root.accent(0.76)
                                                font.family: "Inter"
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

                        Item {
                            width: 1
                            height: 12
                        }

                        Row {
                            width: parent.width
                            height: 125
                            spacing: 12

                            Repeater {
                                model: [
                                    {
                                        icon: "󰆍",
                                        key: "SUPER + C",
                                        hu: "Terminál",
                                        en: "Terminal",
                                        hud: "Nyisd meg a Ghostty terminált.",
                                        end: "Open the Ghostty terminal."
                                    },
                                    {
                                        icon: "󰖲",
                                        key: "SUPER + 1...0",
                                        hu: "Munkaterületek",
                                        en: "Workspaces",
                                        hud: "Válts gyorsan a munkaterületek között.",
                                        end: "Quickly switch between workspaces."
                                    },
                                    {
                                        icon: "󰗼",
                                        key: "SUPER + M",
                                        hu: "Kilépés a munkamenetből",
                                        en: "Exit session",
                                        hud: "Bármikor kiléphetsz a Hyprland munkamenetből.",
                                        end: "Exit the Hyprland session at any time."
                                    }
                                ]

                                Rectangle {
                                    width: (parent.width - 24) / 3
                                    height: 125
                                    radius: 1
                                    color: extraTileMouse.containsMouse ? root.accent(0.055) : root.cardColor
                                    border.width: 1
                                    border.color: extraTileMouse.containsMouse ? root.accent(0.34) : root.cardBorderColor

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 130
                                        }
                                    }
                                    Behavior on border.color {
                                        ColorAnimation {
                                            duration: 130
                                        }
                                    }

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 5

                                        Row {
                                            width: parent.width
                                            spacing: 8
                                            Text {
                                                text: modelData.icon
                                                color: root.accentColor
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 19
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: root.english ? modelData.en : modelData.hu
                                                color: root.accentColor
                                                font.family: "Inter"
                                                font.pixelSize: 11
                                                font.bold: true
                                            }
                                        }
                                        Text {
                                            width: parent.width
                                            text: root.english ? modelData.end : modelData.hud
                                            color: Qt.rgba(1, 1, 1, 0.45)
                                            font.family: "Inter"
                                            font.pixelSize: 9
                                            wrapMode: Text.WordWrap
                                        }
                                        Rectangle {
                                            width: extraKeyText.implicitWidth + 16
                                            height: 22
                                            radius: 1
                                            color: Qt.rgba(0, 0, 0, 0.20)
                                            border.width: 1
                                            border.color: root.accent(0.28)
                                            Text {
                                                id: extraKeyText
                                                anchors.centerIn: parent
                                                text: modelData.key
                                                color: root.accent(0.76)
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

                        Item {
                            width: 1
                            height: 16
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: root.dividerColor
                        }

                        Item {
                            width: 1
                            height: 18
                        }

                        Item {
                            width: parent.width
                            height: 48

                            Rectangle {
                                id: beginButton
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 160
                                height: 40
                                radius: 1
                                color: root.accent(beginMouse.containsMouse ? 0.14 : 0.10)
                                border.width: 1
                                border.color: root.accent(beginMouse.containsMouse ? 0.34 : 0.30)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 130
                                    }
                                }

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 130
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.tr("Kezdjük  ❯", "Let's begin  ❯")
                                    color: root.accentColor
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
                                radius: 1
                                color: allBindsMouse.containsMouse ? root.accent(0.055) : root.cardColor
                                border.width: 1
                                border.color: allBindsMouse.containsMouse ? root.accent(0.34) : root.cardBorderColor

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 130
                                    }
                                }

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 130
                                    }
                                }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 7

                                    Text {
                                        text: "󰌌"
                                        color: root.accentColor
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                    }

                                    Text {
                                        text: root.tr("Összes bind", "All shortcuts")
                                        color: root.accentColor
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
                                        color: root.accentColor
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        text: root.tr("SUPER + ALT + W-vel bármikor visszahívható", "Always available with SUPER + ALT + W")
                                        color: Qt.rgba(1, 1, 1, 0.34)
                                        font.family: "Inter"
                                        font.pixelSize: 9
                                    }
                                }

                                Rectangle {
                                    id: startupSwitch
                                    width: 52
                                    height: 28
                                    radius: 1
                                    color: root.autoShowDisabled ? root.cardColor : root.accent(0.16)
                                    border.width: 1
                                    border.color: root.autoShowDisabled ? root.cardBorderColor : root.accent(0.42)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }

                                    Behavior on border.color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 1
                                        y: 4
                                        x: root.autoShowDisabled ? 4 : 28
                                        color: root.autoShowDisabled ? Qt.rgba(1, 1, 1, 0.46) : root.accentColor

                                        Behavior on x {
                                            NumberAnimation {
                                                duration: 150
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }
                                        }
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
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
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
                                radius: 1
                                color: backMouse.containsMouse ? root.accent(0.08) : root.cardColor
                                border.width: 1
                                border.color: backMouse.containsMouse ? root.accent(0.34) : root.cardBorderColor

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 130
                                    }
                                }

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 130
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "←"
                                    color: root.accentColor
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
                                    color: root.accentColor
                                    font.family: "Inter"
                                    font.pixelSize: 19
                                    font.bold: true
                                }

                                Text {
                                    text: root.tr("A Hypr-Lab v1.5 aktuális bindlistája", "Current Hypr-Lab v1.5 shortcut reference")
                                    color: Qt.rgba(1, 1, 1, 0.40)
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 88
                                height: 28
                                radius: 1
                                color: root.cardColor
                                border.width: 1
                                border.color: root.cardBorderColor

                                Rectangle {
                                    x: root.english ? parent.width / 2 + 2 : 2
                                    y: 2
                                    width: parent.width / 2 - 4
                                    height: parent.height - 4
                                    radius: 1

                                    color: root.accent(0.10)
                                    border.width: 1
                                    border.color: root.accent(0.42)

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

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
                                                color: ((index === 1) === root.english) ? root.accentColor : Qt.rgba(1, 1, 1, 0.48)

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }
                                                }

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
                            color: root.dividerColor
                        }

                        ListView {
                            id: bindsList
                            width: parent.width
                            height: parent.height - 66
                            clip: true
                            spacing: 7

                            model: [
                                {
                                    groupHu: "HYPR-LAB",
                                    groupEn: "HYPR-LAB",
                                    key: "SUPER + SPACE",
                                    hu: "Alkalmazásindító megnyitása / bezárása",
                                    en: "Open / close the App Launcher"
                                },
                                {
                                    groupHu: "HYPR-LAB",
                                    groupEn: "HYPR-LAB",
                                    key: "SUPER + SHIFT + C",
                                    hu: "Control Center megnyitása / bezárása",
                                    en: "Open / close the Control Center"
                                },
                                {
                                    groupHu: "HYPR-LAB",
                                    groupEn: "HYPR-LAB",
                                    key: "SUPER + SHIFT + V",
                                    hu: "Audio Control panel megnyitása / bezárása",
                                    en: "Open / close the Audio Control panel"
                                },
                                {
                                    groupHu: "HYPR-LAB",
                                    groupEn: "HYPR-LAB",
                                    key: "SUPER + SHIFT + N",
                                    hu: "Értesítési központ megnyitása / bezárása",
                                    en: "Open / close the Notification Center"
                                },
                                {
                                    groupHu: "HYPR-LAB",
                                    groupEn: "HYPR-LAB",
                                    key: "SUPER + SHIFT + D",
                                    hu: "Hypr-Scope megnyitása / bezárása",
                                    en: "Open / close Hypr-Scope"
                                },
                                {
                                    groupHu: "HYPR-LAB",
                                    groupEn: "HYPR-LAB",
                                    key: "SUPER + W",
                                    hu: "Véletlen háttérkép véletlen átmenettel",
                                    en: "Random wallpaper with a random transition"
                                },
                                {
                                    groupHu: "HYPR-LAB",
                                    groupEn: "HYPR-LAB",
                                    key: "SUPER + SHIFT + W",
                                    hu: "Háttérképválasztó megnyitása / bezárása",
                                    en: "Open / close the Wallpaper Picker"
                                },
                                {
                                    groupHu: "HYPR-LAB",
                                    groupEn: "HYPR-LAB",
                                    key: "SUPER + ALT + W",
                                    hu: "Üdvözlőképernyő megnyitása / bezárása",
                                    en: "Open / close this Welcome Screen"
                                },
                                {
                                    groupHu: "HYPR-LAB",
                                    groupEn: "HYPR-LAB",
                                    key: "SUPER + SHIFT + P",
                                    hu: "Power menü megnyitása / bezárása",
                                    en: "Open / close the Power Menu"
                                },
                                {
                                    groupHu: "HYPR-LAB",
                                    groupEn: "HYPR-LAB",
                                    key: "SUPER + L",
                                    hu: "Képernyőzár aktiválása",
                                    en: "Activate the lock screen"
                                },
                                {
                                    groupHu: "HYPR-LAB",
                                    groupEn: "HYPR-LAB",
                                    key: "SUPER + I",
                                    hu: "Hypr-Lab beállítások megnyitása",
                                    en: "Open Hypr-Lab Settings"
                                },
                                {
                                    groupHu: "ALKALMAZÁSOK",
                                    groupEn: "APPLICATIONS",
                                    key: "SUPER + C",
                                    hu: "Ghostty terminál megnyitása",
                                    en: "Open the Ghostty terminal"
                                },
                                {
                                    groupHu: "ALKALMAZÁSOK",
                                    groupEn: "APPLICATIONS",
                                    key: "SUPER + B",
                                    hu: "Beállított alapértelmezett böngésző megnyitása",
                                    en: "Open the configured default browser"
                                },
                                {
                                    groupHu: "ALKALMAZÁSOK",
                                    groupEn: "APPLICATIONS",
                                    key: "SUPER + E",
                                    hu: "Beállított fájlkezelő megnyitása",
                                    en: "Open the configured file manager"
                                },
                                {
                                    groupHu: "ALKALMAZÁSOK",
                                    groupEn: "APPLICATIONS",
                                    key: "SUPER + SHIFT + B",
                                    hu: "Blender megnyitása",
                                    en: "Open Blender"
                                },
                                {
                                    groupHu: "ABLAKOK",
                                    groupEn: "WINDOWS",
                                    key: "SUPER + Q",
                                    hu: "Aktív ablak bezárása",
                                    en: "Close the active window"
                                },
                                {
                                    groupHu: "ABLAKOK",
                                    groupEn: "WINDOWS",
                                    key: "SUPER + T",
                                    hu: "Aktív ablak lebegő / csempézett módjának váltása",
                                    en: "Toggle floating / tiled mode for the active window"
                                },
                                {
                                    groupHu: "ABLAKOK",
                                    groupEn: "WINDOWS",
                                    key: "SUPER + F",
                                    hu: "Aktív ablak teljes képernyős módja",
                                    en: "Toggle fullscreen for the active window"
                                },
                                {
                                    groupHu: "ABLAKOK",
                                    groupEn: "WINDOWS",
                                    key: "SUPER + ← / → / ↑ / ↓",
                                    hu: "Fókusz mozgatása a szomszédos ablakokra",
                                    en: "Move focus between neighboring windows"
                                },
                                {
                                    groupHu: "ABLAKOK",
                                    groupEn: "WINDOWS",
                                    key: "SUPER + CTRL + ← / → / ↑ / ↓",
                                    hu: "Aktív ablak átméretezése 100 pixeles lépésekben",
                                    en: "Resize the active window in 100-pixel steps"
                                },
                                {
                                    groupHu: "ABLAKOK",
                                    groupEn: "WINDOWS",
                                    key: "SUPER + BAL EGÉR",
                                    hu: "Lebegő ablak mozgatása húzással",
                                    en: "Drag a floating window"
                                },
                                {
                                    groupHu: "ABLAKOK",
                                    groupEn: "WINDOWS",
                                    key: "SUPER + JOBB EGÉR",
                                    hu: "Lebegő ablak átméretezése húzással",
                                    en: "Resize a floating window by dragging"
                                },
                                {
                                    groupHu: "ABLAKOK",
                                    groupEn: "WINDOWS",
                                    key: "SUPER + J",
                                    hu: "Split irányának váltása",
                                    en: "Toggle the split direction"
                                },
                                {
                                    groupHu: "ABLAKOK",
                                    groupEn: "WINDOWS",
                                    key: "SUPER + K",
                                    hu: "A split két oldalának felcserélése",
                                    en: "Swap the two sides of the split"
                                },
                                {
                                    groupHu: "MUNKATERÜLETEK",
                                    groupEn: "WORKSPACES",
                                    key: "SUPER + 1...0",
                                    hu: "Váltás a kiválasztott munkaterületre",
                                    en: "Switch to the selected workspace"
                                },
                                {
                                    groupHu: "MUNKATERÜLETEK",
                                    groupEn: "WORKSPACES",
                                    key: "SUPER + SHIFT + 1...0",
                                    hu: "Aktív ablak áthelyezése a kiválasztott munkaterületre",
                                    en: "Move the active window to the selected workspace"
                                },
                                {
                                    groupHu: "KÉPERNYŐKÉP",
                                    groupEn: "SCREENSHOTS",
                                    key: "SUPER + SHIFT + S",
                                    hu: "Kijelölt terület képernyőmentése",
                                    en: "Capture a selected area"
                                },
                                {
                                    groupHu: "KÉPERNYŐKÉP",
                                    groupEn: "SCREENSHOTS",
                                    key: "SUPER + SHIFT + A",
                                    hu: "Teljes képernyő mentése",
                                    en: "Capture the full screen"
                                },
                                {
                                    groupHu: "MÉDIA",
                                    groupEn: "MEDIA",
                                    key: "HANGERŐ + / −",
                                    hu: "Rendszerhangerő növelése / csökkentése",
                                    en: "Raise / lower system volume"
                                },
                                {
                                    groupHu: "MÉDIA",
                                    groupEn: "MEDIA",
                                    key: "NÉMÍTÁS",
                                    hu: "Rendszerhang némítása / visszakapcsolása",
                                    en: "Mute / unmute system audio"
                                },
                                {
                                    groupHu: "MÉDIA",
                                    groupEn: "MEDIA",
                                    key: "PLAY / PAUSE",
                                    hu: "Médialejátszás indítása / szüneteltetése",
                                    en: "Play / pause media"
                                },
                                {
                                    groupHu: "MÉDIA",
                                    groupEn: "MEDIA",
                                    key: "ELŐZŐ / KÖVETKEZŐ",
                                    hu: "Előző / következő médiaszám",
                                    en: "Previous / next media track"
                                },
                                {
                                    groupHu: "MUNKAMENET",
                                    groupEn: "SESSION",
                                    key: "SUPER + M",
                                    hu: "Kilépés a Hyprland munkamenetből",
                                    en: "Exit the Hyprland session"
                                }
                            ]

                            delegate: Column {
                                required property var modelData
                                required property int index
                                width: bindsList.width
                                spacing: 5

                                Text {
                                    visible: index === 0 || bindsList.model[index - 1].groupHu !== modelData.groupHu
                                    height: visible ? 20 : 0
                                    text: root.english ? modelData.groupEn : modelData.groupHu
                                    color: root.accent(0.52)
                                    font.family: "Inter"
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 1.5
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 48
                                    radius: 1
                                    color: bindMouse.containsMouse ? root.accent(0.055) : root.cardColor
                                    border.width: 1
                                    border.color: bindMouse.containsMouse ? root.accent(0.34) : root.cardBorderColor

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 130
                                        }
                                    }

                                    Behavior on border.color {
                                        ColorAnimation {
                                            duration: 130
                                        }
                                    }

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.min(220, bindKey.implicitWidth + 20)
                                        height: 27
                                        radius: 1
                                        color: root.accent(0.14)
                                        border.width: 1
                                        border.color: root.accent(0.28)

                                        Text {
                                            id: bindKey
                                            anchors.centerIn: parent
                                            text: modelData.key
                                            color: root.accentColor
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
                                        color: root.accentColor
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
