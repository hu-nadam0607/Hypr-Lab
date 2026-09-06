import QtQuick

Rectangle {
    id: root
    required property int index
    required property string labelText
    required property string iconText
    required property string path
    property string secondaryText: ""
    property bool active: false
    property color accentColor: "#e69a5b"
    signal activated(string path)
    signal contextRequested(real x, real y)

    height: secondaryText.length > 0 ? 46 : 38
    width: ListView.view ? ListView.view.width : 180
    color: active ? Qt.rgba(1,1,1,0.065) : (mouse.containsMouse ? Qt.rgba(1,1,1,0.04) : "transparent")
    radius: 0

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        spacing: 11

        Text {
            width: 20
            anchors.verticalCenter: parent.verticalCenter
            text: root.iconText
            color: root.active ? root.accentColor : "#d8dde2"
            font.pixelSize: 17
            horizontalAlignment: Text.AlignHCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 31
            spacing: 1

            Text {
                width: parent.width
                text: root.labelText
                color: root.active ? "#f2f4f5" : "#d0d5da"
                font.pixelSize: 13
                font.weight: root.active ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: root.secondaryText.length > 0
                text: root.secondaryText
                color: "#74808a"
                font.pixelSize: 9
                elide: Text.ElideMiddle
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton)
                root.contextRequested(mouse.x, mouse.y)
            else
                root.activated(root.path)
        }
    }
}
