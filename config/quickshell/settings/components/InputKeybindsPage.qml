import QtQuick

Item {
    id:root
    property var backend
    property color accentColor:"#68787D"
    readonly property var binds:[
        ["SUPER + SPACE","App Launcher"],["SUPER + I","Hypr-Lab Settings"],["SUPER + SHIFT + C","Control Center"],
        ["SUPER + SHIFT + V","Audio Control"],["SUPER + SHIFT + N","Notification Center"],["SUPER + SHIFT + W","Wallpaper Picker"],
        ["SUPER + W","Random wallpaper"],["SUPER + L","Lock Screen"],["SUPER + SHIFT + P","Power Menu"],
        ["SUPER + ALT + W","Welcome Screen"],["SUPER + C","Ghostty"],["SUPER + E","File Manager"],["SUPER + B","Browser"],["SUPER + M","Exit session"]
    ]
    Flickable {
        anchors.fill:parent; contentWidth:width; contentHeight:col.implicitHeight+16; clip:true; boundsBehavior:Flickable.StopAtBounds
        Column {
            id:col; width:parent.width; spacing:0
            SectionLabel { width:parent.width; text:"SHORTCUTS"; accentColor:root.accentColor }
            Repeater {
                model:root.binds
                delegate:Item {
                    required property var modelData
                    width:col.width; height:42
                    Text { anchors.left:parent.left; anchors.verticalCenter:parent.verticalCenter; text:modelData[0]; color:root.accentColor; font.family:"JetBrains Mono"; font.pixelSize:9; font.bold:true }
                    Text { anchors.right:parent.right; anchors.verticalCenter:parent.verticalCenter; text:modelData[1]; color:Qt.rgba(1,1,1,0.68); font.family:"Inter"; font.pixelSize:9; font.italic:true }
                    Rectangle { anchors.left:parent.left; anchors.right:parent.right; anchors.bottom:parent.bottom; height:1; color:Qt.rgba(1,1,1,0.045) }
                }
            }
            SectionLabel { width:parent.width; text:"TOOLS"; accentColor:root.accentColor }
            SettingAction { width:parent.width; accentColor:root.accentColor; title:"Open keybind guide"; subtitle:"Open the Hypr-Lab Welcome screen with the full shortcut reference"; icon:"󰌌"; buttonText:"OPEN"; onTriggered:backend.openWelcome() }
            SettingAction { width:parent.width; accentColor:root.accentColor; title:"Reload Hyprland"; subtitle:"Reload the current Lua configuration"; icon:"󰑐"; buttonText:"RELOAD"; onTriggered:backend.reloadHyprland() }
        }
    }
}
