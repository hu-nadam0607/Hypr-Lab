import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    signal backRequested()
    signal closeRequested()
    signal monitorRequested()

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
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/hyprlab-scripts/hyprlab-settings.sh", "set", key, String(value)])
    }
    function clamp(v,a,b){ return Math.max(a,Math.min(b,v)) }

    Process {
        id: loadProc
        command: [Quickshell.env("HOME") + "/.config/hypr/hyprlab-scripts/hyprlab-settings.sh", "dump"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                for (let line of lines) {
                    const p=line.split("="); if(p.length<2) continue
                    const k=p[0], v=p.slice(1).join("=")
                    if(k==="BORDER_SIZE") root.borderSize=parseInt(v)
                    else if(k==="ROUNDING") root.rounding=parseInt(v)
                    else if(k==="ACTIVE_OPACITY") root.activeOpacity=parseFloat(v)
                    else if(k==="INACTIVE_OPACITY") root.inactiveOpacity=parseFloat(v)
                    else if(k==="SHADOW") root.shadowEnabled=v==="1"
                    else if(k==="BLUR") root.blurEnabled=v==="1"
                    else if(k==="BLUR_SIZE") root.blurSize=parseInt(v)
                    else if(k==="BLUR_PASSES") root.blurPasses=parseInt(v)
                    else if(k==="XRAY") root.xrayEnabled=v==="1"
                    else if(k==="ANIMATIONS") root.animationsEnabled=v==="1"
                    else if(k==="GAPS_IN") root.gapsIn=parseInt(v)
                    else if(k==="GAPS_OUT") root.gapsOut=parseInt(v)
                }
            }
        }
    }
    Component.onCompleted: loadProc.running=true

    SettingsHeader {
        id: header; anchors.left:parent.left; anchors.right:parent.right; anchors.top:parent.top
        title:"SETTINGS"; subtitle:"Hyprland + Hypr-Lab"
        onBackRequested:root.backRequested(); onCloseRequested:root.closeRequested()
    }

    Flickable {
        anchors.left:parent.left; anchors.right:parent.right; anchors.top:header.bottom; anchors.bottom:parent.bottom
        anchors.topMargin:8; contentWidth:width; contentHeight:content.implicitHeight+12
        clip:true; boundsBehavior:Flickable.StopAtBounds

        Column {
            id:content; width:parent.width; spacing:8
            Text { text:"DISPLAY"; color:Qt.rgba(190/255,205/255,210/255,0.52); font.family:"Inter"; font.pixelSize:9; font.bold:true; font.letterSpacing:1.6 }
            Rectangle {
                width:parent.width; height:64; radius:18
                color:monitorMouse.containsMouse?Qt.rgba(55/255,245/255,235/255,0.10):Qt.rgba(1,1,1,0.035)
                border.width:1; border.color:monitorMouse.containsMouse?Qt.rgba(55/255,245/255,235/255,0.38):Qt.rgba(1,1,1,0.06)
                Row {
                    anchors.fill:parent; anchors.margins:13; spacing:11
                    Text { anchors.verticalCenter:parent.verticalCenter; text:"󰍹"; color:"#37f5eb"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:20 }
                    Column { anchors.verticalCenter:parent.verticalCenter; width:parent.width-70
                        Text{text:"Monitor & Display";color:"#e7f1f2";font.family:"Inter";font.pixelSize:11;font.bold:true}
                        Text{text:"Resolution · refresh rate · scale";color:Qt.rgba(1,1,1,0.42);font.family:"Inter";font.pixelSize:9}
                    }
                    Text { anchors.verticalCenter:parent.verticalCenter; text:"󰅂"; color:Qt.rgba(1,1,1,0.48); font.family:"JetBrainsMono Nerd Font"; font.pixelSize:16 }
                }
                MouseArea{id:monitorMouse;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:root.monitorRequested()}
            }

            Text {
                text: "APPEARANCE"
                topPadding: 6
                color: Qt.rgba(190/255,205/255,210/255,0.52)
                font.family: "Inter"
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.6
            }

            SettingStepper {
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
                title: "Active opacity"
                subtitle: "Focused windows"
                valueText: Math.round(root.activeOpacity * 100) + "%"

                onDecrease: {
                    root.activeOpacity = root.clamp(
                        Math.round((root.activeOpacity - 0.05) * 100) / 100,
                        0.25,
                        1.0
                    )
                    root.setValue("ACTIVE_OPACITY", root.activeOpacity.toFixed(2))
                }

                onIncrease: {
                    root.activeOpacity = root.clamp(
                        Math.round((root.activeOpacity + 0.05) * 100) / 100,
                        0.25,
                        1.0
                    )
                    root.setValue("ACTIVE_OPACITY", root.activeOpacity.toFixed(2))
                }
            }

            SettingStepper {
                title: "Inactive opacity"
                subtitle: "Background windows"
                valueText: Math.round(root.inactiveOpacity * 100) + "%"

                onDecrease: {
                    root.inactiveOpacity = root.clamp(
                        Math.round((root.inactiveOpacity - 0.05) * 100) / 100,
                        0.20,
                        1.0
                    )
                    root.setValue("INACTIVE_OPACITY", root.inactiveOpacity.toFixed(2))
                }

                onIncrease: {
                    root.inactiveOpacity = root.clamp(
                        Math.round((root.inactiveOpacity + 0.05) * 100) / 100,
                        0.20,
                        1.0
                    )
                    root.setValue("INACTIVE_OPACITY", root.inactiveOpacity.toFixed(2))
                }
            }

            SettingToggle {
                title: "Shadow"
                subtitle: "Hyprland window shadows"
                checked: root.shadowEnabled

                onToggled: function(value) {
                    root.shadowEnabled = value
                    root.setValue("SHADOW", value ? 1 : 0)
                }
            }

            SettingToggle {
                title: "Blur"
                subtitle: "Background blur"
                checked: root.blurEnabled

                onToggled: function(value) {
                    root.blurEnabled = value
                    root.setValue("BLUR", value ? 1 : 0)
                }
            }

            SettingStepper {
                title: "Blur size"
                subtitle: "Blur radius"
                valueText: String(root.blurSize)

                onDecrease: {
                    root.blurSize = root.clamp(root.blurSize - 1, 1, 12)
                    root.setValue("BLUR_SIZE", root.blurSize)
                }

                onIncrease: {
                    root.blurSize = root.clamp(root.blurSize + 1, 1, 12)
                    root.setValue("BLUR_SIZE", root.blurSize)
                }
            }

            SettingStepper {
                title: "Blur passes"
                subtitle: "Quality / GPU cost"
                valueText: String(root.blurPasses)

                onDecrease: {
                    root.blurPasses = root.clamp(root.blurPasses - 1, 1, 6)
                    root.setValue("BLUR_PASSES", root.blurPasses)
                }

                onIncrease: {
                    root.blurPasses = root.clamp(root.blurPasses + 1, 1, 6)
                    root.setValue("BLUR_PASSES", root.blurPasses)
                }
            }

            SettingToggle {
                subtitle: "Blur through opaque surfaces"
                checked: root.xrayEnabled

                onToggled: function(value) {
                    root.xrayEnabled = value
                    root.setValue("XRAY", value ? 1 : 0)
                }
            }

            Text {
                text: "LAYOUT & MOTION"
                topPadding: 6
                color: Qt.rgba(190/255,205/255,210/255,0.52)
                font.family: "Inter"
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.6
            }

            SettingToggle {
                title: "Animations"
                subtitle: "Hyprland animations"
                checked: root.animationsEnabled

                onToggled: function(value) {
                    root.animationsEnabled = value
                    root.setValue("ANIMATIONS", value ? 1 : 0)
                }
            }

            SettingStepper {
                title: "Inner gaps"
                subtitle: "Space between windows"
                valueText: root.gapsIn + " px"

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
                title: "Outer gaps"
                subtitle: "Space around workspace"
                valueText: root.gapsOut + " px"

                onDecrease: {
                    root.gapsOut = root.clamp(root.gapsOut - 1, 0, 40)
                    root.setValue("GAPS_OUT", root.gapsOut)
                }

                onIncrease: {
                    root.gapsOut = root.clamp(root.gapsOut + 1, 0, 40)
                    root.setValue("GAPS_OUT", root.gapsOut)
                }
            }

            Item { width:1; height:4 }
        }
    }
}
