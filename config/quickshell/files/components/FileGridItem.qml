import QtQuick

Item {
    id: root
    required property int index
    required property var entry
    property bool selected: false
    property color accentColor: "#e69a5b"
    property Item coordinateRoot
    property int tileWidth: 160
    property int tileHeight: 142
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

    width: tileWidth
    height: tileHeight

    readonly property bool isImage: !entry.isDir && ["png","jpg","jpeg","webp","bmp","gif"].indexOf(String(entry.ext).toLowerCase()) >= 0

    Rectangle {
        anchors.fill: parent
        color: root.selected ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12)
             : (mouse.containsMouse ? Qt.rgba(1,1,1,0.035) : "transparent")
        border.width: root.selected ? 1 : 0
        border.color: root.selected ? root.accentColor : "transparent"
        radius: 0
    }

    Item {
        id: preview
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.tileWidth - 24
        height: 82

        Image {
            anchors.fill: parent
            visible: root.isImage
            source: root.isImage ? entry.url : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize.width: 240
            sourceSize.height: 160
        }

        Text {
            anchors.centerIn: parent
            visible: !root.isImage
            text: entry.isDir ? "󰉋" : fileGlyph(entry)
            color: entry.isDir ? root.accentColor : "#d8dde2"
            font.pixelSize: entry.isDir ? 54 : 43
        }
    }

    Text {
        anchors.top: preview.bottom
        anchors.topMargin: 7
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 7
        anchors.rightMargin: 7
        text: entry.name
        color: "#eef1f3"
        font.pixelSize: 12
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideMiddle
        maximumLineCount: 1
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 7
        anchors.left: parent.left
        anchors.right: parent.right
        text: entry.isDir ? "Folder" : entry.sizeHuman
        color: "#7f8a94"
        font.pixelSize: 10
        horizontalAlignment: Text.AlignHCenter
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
                return
            }
            root.clicked(root.entry, ev.modifiers)
        }
        onDoubleClicked: function(ev) {
            if (ev.button === Qt.LeftButton)
                root.doubleClicked(root.entry)
        }
    }

    function fileGlyph(e) {
        const ext = String(e.ext).toLowerCase()
        if (["zip","7z","rar","tar","gz","bz2","xz"].indexOf(ext) >= 0) return "󰀼"
        if (["txt","md","log","conf","ini","json","yaml","yml"].indexOf(ext) >= 0) return "󰈙"
        if (["mp3","ogg","flac","wav","m4a"].indexOf(ext) >= 0) return "󰎄"
        if (["mp4","mkv","webm","avi","mov"].indexOf(ext) >= 0) return "󰕧"
        if (ext === "pdf") return "󰈦"
        return "󰈔"
    }
}
