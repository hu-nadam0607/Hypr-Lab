import QtQuick

Item {
    id:root
    property var backend
    property color accentColor:"#68787D"
    Flickable {
        anchors.fill:parent; contentWidth:width; contentHeight:col.implicitHeight+16; clip:true; boundsBehavior:Flickable.StopAtBounds
        Column {
            id:col; width:parent.width; spacing:0
            SectionLabel { width:parent.width; text:"DISPLAY"; accentColor:root.accentColor }
            SettingAction { width:parent.width; accentColor:root.accentColor; title:"Monitor & Display"; subtitle:"Resolution, refresh rate and scale using the existing Hypr-Lab monitor controls"; icon:"󰍹"; buttonText:"OPEN"; onTriggered:backend.openMonitorSettings() }
            SectionLabel { width:parent.width; text:"DEFAULT APPLICATIONS"; accentColor:root.accentColor }
            SettingAction { width:parent.width; accentColor:root.accentColor; title:"Browser"; subtitle:"Launch the current XDG default browser"; icon:"󰖟"; buttonText:"TEST"; onTriggered:backend.openBrowser() }
            SettingAction { width:parent.width; accentColor:root.accentColor; title:"File manager"; subtitle:"Launch the configured or detected file manager"; icon:"󰉋"; buttonText:"TEST"; onTriggered:backend.openFileManager() }
            SettingAction { width:parent.width; accentColor:root.accentColor; title:"Calculator"; subtitle:"Launch the configured or detected calculator"; icon:"󰪚"; buttonText:"TEST"; onTriggered:backend.openCalculator() }
            SectionLabel { width:parent.width; text:"HYPRLAND"; accentColor:root.accentColor }
            SettingAction { width:parent.width; accentColor:root.accentColor; title:"Reload configuration"; subtitle:"Reload Hyprland without ending the session"; icon:"󰑐"; buttonText:"RELOAD"; onTriggered:backend.reloadHyprland() }
        }
    }
}
