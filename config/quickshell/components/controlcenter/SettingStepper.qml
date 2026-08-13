import QtQuick
Rectangle {
    id: root
    property string title: ""
    property string subtitle: ""
    property string valueText: ""
    signal decrease()
    signal increase()
    width: parent ? parent.width : 380
    height: 62; radius: 17
    color: Qt.rgba(1,1,1,0.035)
    border.width: 1; border.color: Qt.rgba(1,1,1,0.055)
    Column {
        anchors.left: parent.left; anchors.leftMargin:14; anchors.verticalCenter:parent.verticalCenter
        width: parent.width - 145; spacing:2
        Text { width:parent.width; text:root.title; color:"#e7f1f2"; font.family:"Inter"; font.pixelSize:11; font.bold:true; elide:Text.ElideRight }
        Text { width:parent.width; text:root.subtitle; color:Qt.rgba(1,1,1,0.40); font.family:"Inter"; font.pixelSize:9; elide:Text.ElideRight }
    }
    Row {
        anchors.right:parent.right; anchors.rightMargin:10; anchors.verticalCenter:parent.verticalCenter; spacing:6
        Repeater {
            model: [{t:"−",a:"dec"},{t:root.valueText,a:"val"},{t:"+",a:"inc"}]
            Rectangle {
                required property var modelData
                width: modelData.a === "val" ? 54 : 30; height:30; radius:15
                color: modelData.a === "val" ? Qt.rgba(55/255,245/255,235/255,0.10) : Qt.rgba(1,1,1,0.06)
                border.width:1; border.color: modelData.a === "val" ? Qt.rgba(55/255,245/255,235/255,0.28) : Qt.rgba(1,1,1,0.08)
                Text { anchors.centerIn:parent; text:modelData.t; color:modelData.a==="val" ? "#37f5eb" : "#dbe7e8"; font.family:"Inter"; font.pixelSize:10; font.bold:true }
                MouseArea {
                    anchors.fill:parent; enabled:modelData.a!=="val"; hoverEnabled:true; cursorShape:enabled?Qt.PointingHandCursor:Qt.ArrowCursor
                    onClicked: { if(modelData.a==="dec") root.decrease(); else if(modelData.a==="inc") root.increase() }
                }
            }
        }
    }
}
