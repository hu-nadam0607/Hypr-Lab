import QtQuick
Rectangle {
    id: root
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    signal toggled(bool value)
    width: parent ? parent.width : 380
    height: 58; radius: 17
    color: Qt.rgba(1,1,1,0.035)
    border.width: 1; border.color: Qt.rgba(1,1,1,0.055)
    Column {
        anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 86; spacing: 2
        Text { width: parent.width; text: root.title; color: "#e7f1f2"; font.family:"Inter"; font.pixelSize:11; font.bold:true; elide: Text.ElideRight }
        Text { width: parent.width; text: root.subtitle; color: Qt.rgba(1,1,1,0.40); font.family:"Inter"; font.pixelSize:9; elide: Text.ElideRight }
    }
    Rectangle {
        width: 48; height: 24; radius: 12
        anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? Qt.rgba(55/255,245/255,235/255,0.22) : Qt.rgba(1,1,1,0.08)
        border.width: 1; border.color: root.checked ? Qt.rgba(55/255,245/255,235/255,0.62) : Qt.rgba(1,1,1,0.10)
        Rectangle {
            width: 18; height: 18; radius: 9; anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width-width-3 : 3
            color: root.checked ? "#37f5eb" : Qt.rgba(1,1,1,0.48)
            Behavior on x { NumberAnimation { duration: 130; easing.type:Easing.OutCubic } }
        }
    }
    MouseArea { anchors.fill: parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked: root.toggled(!root.checked) }
}
