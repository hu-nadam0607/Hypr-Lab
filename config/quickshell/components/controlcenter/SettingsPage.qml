import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    signal backRequested()
    signal closeRequested()
    signal monitorRequested()

    property color accentColor: "#68787D"
    property real slope: 14 / 36
    property real corridorWidth: 360
    property real corridorTopLeft: 0
    property bool showHeader: true

    property int borderSize: 2
    property int rounding: 17
    property real activeOpacity: 0.80
    property real inactiveOpacity: 0.70
    property bool shadowEnabled: true
    property bool blurEnabled: true
    property int blurSize: 4
    property int blurPasses: 3
    property bool xrayEnabled: false
    property bool animationsEnabled: true
    property int gapsIn: 5
    property int gapsOut: 10

    function setValue(key, value) {
        Quickshell.execDetached([
            "bash",
            Quickshell.env("HOME") + "/.config/hypr/hyprlab-scripts/hyprlab-settings.sh",
            "set",
            key,
            String(value)
        ])
    }

    function clamp(v, a, b) {
        return Math.max(a, Math.min(b, v))
    }

    function rowX(viewY) {
        return corridorTopLeft - slope * Math.max(0, viewY)
    }

    Process {
        id: loadProc

        command: [
            "bash",
            Quickshell.env("HOME") + "/.config/hypr/hyprlab-scripts/hyprlab-settings.sh",
            "dump"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")

                for (let line of lines) {
                    const p = line.split("=")
                    if (p.length < 2)
                        continue

                    const k = p[0]
                    const v = p.slice(1).join("=")

                    if (k === "BORDER_SIZE")
                        root.borderSize = parseInt(v)
                    else if (k === "ROUNDING")
                        root.rounding = parseInt(v)
                    else if (k === "ACTIVE_OPACITY")
                        root.activeOpacity = parseFloat(v)
                    else if (k === "INACTIVE_OPACITY")
                        root.inactiveOpacity = parseFloat(v)
                    else if (k === "SHADOW")
                        root.shadowEnabled = v === "1"
                    else if (k === "BLUR")
                        root.blurEnabled = v === "1"
                    else if (k === "BLUR_SIZE")
                        root.blurSize = parseInt(v)
                    else if (k === "BLUR_PASSES")
                        root.blurPasses = parseInt(v)
                    else if (k === "XRAY")
                        root.xrayEnabled = v === "1"
                    else if (k === "ANIMATIONS")
                        root.animationsEnabled = v === "1"
                    else if (k === "GAPS_IN")
                        root.gapsIn = parseInt(v)
                    else if (k === "GAPS_OUT")
                        root.gapsOut = parseInt(v)
                }
            }
        }
    }

    Component.onCompleted: loadProc.running = true

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight + 16
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 1900

        Column {
            id: content
            width: flick.width
            spacing: 0

            Text {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                height: 26
                text: "DISPLAY"
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.78)
                font.family: "Inter"
                font.pixelSize: 8
                font.bold: true
                font.italic: true
                font.letterSpacing: 1.3
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                height: 52

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 9

                    Text {
                        text: "󰍹"
                        color: root.accentColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                    }

                    Column {
                        spacing: 1

                        Text {
                            text: "Monitor & Display"
                            color: Qt.rgba(1, 1, 1, 0.82)
                            font.family: "Inter"
                            font.pixelSize: 10
                            font.bold: true
                            font.italic: true
                        }

                        Text {
                            text: "Resolution · refresh rate · scale"
                            color: Qt.rgba(1, 1, 1, 0.38)
                            font.family: "Inter"
                            font.pixelSize: 8
                            font.italic: true
                        }
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "›"
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.family: "Inter"
                    font.pixelSize: 15
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16)
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.monitorRequested()
                }
            }

            Text {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                height: 32
                text: "APPEARANCE"
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.78)
                font.family: "Inter"
                font.pixelSize: 8
                font.bold: true
                font.italic: true
                font.letterSpacing: 1.3
                verticalAlignment: Text.AlignVCenter
            }

            SettingStepper {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                accentColor: root.accentColor
                title: "Border size"
                subtitle: "Active window border"
                valueText: root.borderSize + " px"
                onDecrease: {
                    root.borderSize = root.clamp(root.borderSize - 1, 0, 8)
                    root.setValue("BORDER_SIZE", root.borderSize)
                }
                onIncrease: {
                    root.borderSize = root.clamp(root.borderSize + 1, 0, 8)
                    root.setValue("BORDER_SIZE", root.borderSize)
                }
            }

            SettingStepper {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                accentColor: root.accentColor
                title: "Corner radius"
                subtitle: "Window rounding"
                valueText: String(root.rounding)
                onDecrease: {
                    root.rounding = root.clamp(root.rounding - 1, 0, 40)
                    root.setValue("ROUNDING", root.rounding)
                }
                onIncrease: {
                    root.rounding = root.clamp(root.rounding + 1, 0, 40)
                    root.setValue("ROUNDING", root.rounding)
                }
            }

            SettingStepper {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                accentColor: root.accentColor
                title: "Active opacity"
                subtitle: "Focused windows"
                valueText: Math.round(root.activeOpacity * 100) + "%"
                onDecrease: {
                    root.activeOpacity = root.clamp(Math.round((root.activeOpacity - 0.05) * 100) / 100, 0.25, 1)
                    root.setValue("ACTIVE_OPACITY", root.activeOpacity.toFixed(2))
                }
                onIncrease: {
                    root.activeOpacity = root.clamp(Math.round((root.activeOpacity + 0.05) * 100) / 100, 0.25, 1)
                    root.setValue("ACTIVE_OPACITY", root.activeOpacity.toFixed(2))
                }
            }

            SettingStepper {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                accentColor: root.accentColor
                title: "Inactive opacity"
                subtitle: "Background windows"
                valueText: Math.round(root.inactiveOpacity * 100) + "%"
                onDecrease: {
                    root.inactiveOpacity = root.clamp(Math.round((root.inactiveOpacity - 0.05) * 100) / 100, 0.20, 1)
                    root.setValue("INACTIVE_OPACITY", root.inactiveOpacity.toFixed(2))
                }
                onIncrease: {
                    root.inactiveOpacity = root.clamp(Math.round((root.inactiveOpacity + 0.05) * 100) / 100, 0.20, 1)
                    root.setValue("INACTIVE_OPACITY", root.inactiveOpacity.toFixed(2))
                }
            }

            SettingToggle {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                accentColor: root.accentColor
                title: "Shadow"
                subtitle: "Hyprland window shadows"
                checked: root.shadowEnabled
                onToggled: function(v) {
                    root.shadowEnabled = v
                    root.setValue("SHADOW", v ? 1 : 0)
                }
            }

            SettingToggle {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                accentColor: root.accentColor
                title: "Blur"
                subtitle: "Background blur"
                checked: root.blurEnabled
                onToggled: function(v) {
                    root.blurEnabled = v
                    root.setValue("BLUR", v ? 1 : 0)
                }
            }

            SettingStepper {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                accentColor: root.accentColor
                title: "Blur size"
                subtitle: "Blur radius"
                valueText: String(root.blurSize)
                onDecrease: {
                    root.blurSize = root.clamp(root.blurSize - 1, 1, 20)
                    root.setValue("BLUR_SIZE", root.blurSize)
                }
                onIncrease: {
                    root.blurSize = root.clamp(root.blurSize + 1, 1, 20)
                    root.setValue("BLUR_SIZE", root.blurSize)
                }
            }

            SettingStepper {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                accentColor: root.accentColor
                title: "Blur passes"
                subtitle: "Quality / GPU cost"
                valueText: String(root.blurPasses)
                onDecrease: {
                    root.blurPasses = root.clamp(root.blurPasses - 1, 1, 8)
                    root.setValue("BLUR_PASSES", root.blurPasses)
                }
                onIncrease: {
                    root.blurPasses = root.clamp(root.blurPasses + 1, 1, 8)
                    root.setValue("BLUR_PASSES", root.blurPasses)
                }
            }

            SettingToggle {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                accentColor: root.accentColor
                title: "XRAY"
                subtitle: "Blur through opaque layers"
                checked: root.xrayEnabled
                onToggled: function(v) {
                    root.xrayEnabled = v
                    root.setValue("XRAY", v ? 1 : 0)
                }
            }

            SettingToggle {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                accentColor: root.accentColor
                title: "Animations"
                subtitle: "Hyprland animations"
                checked: root.animationsEnabled
                onToggled: function(v) {
                    root.animationsEnabled = v
                    root.setValue("ANIMATIONS", v ? 1 : 0)
                }
            }

            SettingStepper {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                accentColor: root.accentColor
                title: "Inner gaps"
                subtitle: "Space between windows"
                valueText: String(root.gapsIn)
                onDecrease: {
                    root.gapsIn = root.clamp(root.gapsIn - 1, 0, 30)
                    root.setValue("GAPS_IN", root.gapsIn)
                }
                onIncrease: {
                    root.gapsIn = root.clamp(root.gapsIn + 1, 0, 30)
                    root.setValue("GAPS_IN", root.gapsIn)
                }
            }

            SettingStepper {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                accentColor: root.accentColor
                title: "Outer gaps"
                subtitle: "Space around workspace"
                valueText: String(root.gapsOut)
                onDecrease: {
                    root.gapsOut = root.clamp(root.gapsOut - 1, 0, 50)
                    root.setValue("GAPS_OUT", root.gapsOut)
                }
                onIncrease: {
                    root.gapsOut = root.clamp(root.gapsOut + 1, 0, 50)
                    root.setValue("GAPS_OUT", root.gapsOut)
                }
            }

            Item {
                width: 1
                height: 18
            }
        }
    }
}
