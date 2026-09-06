import QtQuick

Rectangle {
    id: root
    required property int index
    required property var entry
    property bool selected: false
    property color accentColor: "#e69a5b"
    property Item coordinateRoot
    signal clicked(var entry, int modifiers)
    signal doubleClicked(var entry)
    signal contextRequested(var entry, real globalX, real globalY)

    // Hypr-Files in-window folder drag.
    // We keep the MouseArea grab for the whole gesture (preventStealing) and
    // report pointer movement to shell.qml, which owns the floating drag ghost
    // and Favorites hit-testing.  This avoids the platform/native DnD path
    // interfering with the surrounding GridView/ListView Flickable.
    property bool folderDragging: false
    property bool suppressNextClick: false
    property real dragPressX: 0
    property real dragPressY: 0
    signal folderDragStarted(var entry, real globalX, real globalY)
    signal folderDragMoved(var entry, real globalX, real globalY)
    signal folderDragFinished(var entry, real globalX, real globalY)

    height: 38
    width: ListView.view ? ListView.view.width : 700
    color: selected ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12)
         : (mouse.containsMouse ? Qt.rgba(1,1,1,0.03) : "transparent")
    border.width: selected ? 1 : 0
    border.color: selected ? accentColor : "transparent"
    radius: 0

    Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 10
        Text {
            width: 24
            anchors.verticalCenter: parent.verticalCenter
            text: entry.isDir ? "󰉋" : "󰈔"
            color: entry.isDir ? root.accentColor : "#cfd5da"
            font.pixelSize: 18
        }
        Text {
            width: Math.max(200, root.width * 0.42)
            anchors.verticalCenter: parent.verticalCenter
            text: entry.name
            color: "#eef1f3"
            font.pixelSize: 12
            elide: Text.ElideMiddle
        }
        Text {
            width: 105
            anchors.verticalCenter: parent.verticalCenter
            text: entry.isDir ? "Folder" : entry.sizeHuman
            color: "#9aa4ad"
            font.pixelSize: 11
        }
        Text {
            width: 155
            anchors.verticalCenter: parent.verticalCenter
            text: entry.mtimeText
            color: "#9aa4ad"
            font.pixelSize: 11
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(100, root.width - 540)
            text: entry.isDir ? "inode/directory" : entry.mime
            color: "#76818a"
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        preventStealing: true
        cursorShape: root.folderDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onPressed: function(ev) {
            root.dragPressX = ev.x
            root.dragPressY = ev.y
            root.folderDragging = false
            root.suppressNextClick = false
        }
        onPositionChanged: function(ev) {
            if (!pressed || !root.entry || ev.buttons === Qt.NoButton)
                return
            const dx = ev.x - root.dragPressX
            const dy = ev.y - root.dragPressY
            if (!root.folderDragging && Math.sqrt(dx * dx + dy * dy) >= 8) {
                root.folderDragging = true
                const p0 = root.coordinateRoot ? root.mapToItem(root.coordinateRoot, ev.x, ev.y) : Qt.point(ev.x, ev.y)
                root.folderDragStarted(root.entry, p0.x, p0.y)
            }
            if (root.folderDragging) {
                const p = root.coordinateRoot ? root.mapToItem(root.coordinateRoot, ev.x, ev.y) : Qt.point(ev.x, ev.y)
                root.folderDragMoved(root.entry, p.x, p.y)
            }
        }
        onReleased: function(ev) {
            if (root.folderDragging) {
                const p = root.coordinateRoot ? root.mapToItem(root.coordinateRoot, ev.x, ev.y) : Qt.point(ev.x, ev.y)
                root.folderDragFinished(root.entry, p.x, p.y)
                root.folderDragging = false
                root.suppressNextClick = true
            }
        }
        onCanceled: {
            root.folderDragging = false
            root.suppressNextClick = true
        }
        onClicked: function(ev) {
            if (root.suppressNextClick) { root.suppressNextClick = false; return }
            if (ev.button === Qt.RightButton) {
                const p = root.coordinateRoot ? root.mapToItem(root.coordinateRoot, ev.x, ev.y) : Qt.point(ev.x, ev.y)
                root.contextRequested(root.entry, p.x, p.y)
            } else {
                root.clicked(root.entry, ev.modifiers)
            }
        }
        onDoubleClicked: function(ev) {
            if (ev.button === Qt.LeftButton) root.doubleClicked(root.entry)
        }
    }
}
