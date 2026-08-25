import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland

Item {
    id: root

    property var toplevel
    property real monitorScaleX: 1.0
    property real monitorScaleY: 1.0
    property real monitorOriginX: 0
    property real monitorOriginY: 0
    property bool livePreview: false
    property bool allowWindowDrag: true
    property color accentColor: "#68787D"

    signal dropRequested(string address, real sceneX, real sceneY)

    readonly property var ipc:
        root.toplevel && root.toplevel.lastIpcObject
            ? root.toplevel.lastIpcObject
            : ({})

    readonly property var windowAt:
        root.ipc.at ? root.ipc.at : [0, 0]

    readonly property var windowSize:
        root.ipc.size ? root.ipc.size : [640, 360]

    readonly property string appId:
        root.toplevel && root.toplevel.wayland && root.toplevel.wayland.appId
            ? root.toplevel.wayland.appId
            : (root.ipc.class ? String(root.ipc.class) : "app")

    readonly property string windowAddress:
        root.toplevel && root.toplevel.address
            ? root.toplevel.address
            : ""

    readonly property bool hovered: dragArea.containsMouse
    readonly property bool highlighted:
        root.hovered
        || dragArea.drag.active
        || (root.toplevel && root.toplevel.activated)

    property string scopeDragType: "window"

    x: Math.max(
        0,
        (Number(root.windowAt[0]) - root.monitorOriginX) * root.monitorScaleX
    )

    y: Math.max(
        0,
        (Number(root.windowAt[1]) - root.monitorOriginY) * root.monitorScaleY
    )

    width: Math.max(
        28,
        Number(root.windowSize[0]) * root.monitorScaleX
    )

    height: Math.max(
        22,
        Number(root.windowSize[1]) * root.monitorScaleY
    )

    z: root.highlighted ? 24 : 10
    scale: dragArea.drag.active ? 0.965 : (root.hovered ? 1.012 : 1.0)
    opacity: dragArea.drag.active ? 0.72 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 110
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 100
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#111A22"
        border.width: root.highlighted ? 2 : 1
        border.color: root.highlighted
            ? root.accentColor
            : Qt.rgba(1, 1, 1, 0.20)
        radius: 1
        clip: true

        Behavior on border.color {
            ColorAnimation { duration: 100 }
        }

        ScreencopyView {
            id: capture
            anchors.fill: parent
            captureSource:
                root.toplevel && root.toplevel.wayland
                    ? root.toplevel.wayland
                    : null
            live: root.livePreview
            paintCursor: false
            visible: hasContent

            Component.onCompleted: {
                if (!live && captureSource)
                    captureFrame()
            }

            onCaptureSourceChanged: {
                if (!live && captureSource)
                    captureFrame()
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: !capture.hasContent
            color: Qt.rgba(0.04, 0.07, 0.09, 0.96)

            Text {
                anchors.centerIn: parent
                width: parent.width - 10
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.appId
                color: Qt.rgba(1, 1, 1, 0.62)
                font.family: "Inter"
                font.pixelSize: Math.max(7, Math.min(12, parent.height / 4))
                font.bold: true
                font.italic: true
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.min(18, Math.max(10, parent.height * 0.14))
            color: Qt.rgba(0.02, 0.03, 0.04, 0.72)
            visible: parent.height > 32

            Text {
                anchors.fill: parent
                anchors.leftMargin: 5
                anchors.rightMargin: 5
                verticalAlignment: Text.AlignVCenter
                text: root.appId
                color: Qt.rgba(1, 1, 1, 0.68)
                elide: Text.ElideRight
                font.family: "Inter"
                font.pixelSize: 7
                font.italic: true
            }
        }
    }

    Item {
        id: dragProxy
        x: 0
        y: 0
        width: root.width
        height: root.height
        z: 1000
        visible: dragArea.drag.active

        Drag.active: dragArea.drag.active
        Drag.source: root
        Drag.keys: ["hypr-scope-window"]
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.02, 0.04, 0.055, 0.72)
            border.width: 2
            border.color: root.accentColor
            radius: 1

            Text {
                anchors.centerIn: parent
                width: parent.width - 12
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.appId
                color: root.accentColor
                font.family: "Inter"
                font.pixelSize: Math.max(7, Math.min(12, parent.height / 4))
                font.bold: true
                font.italic: true
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: root.allowWindowDrag && root.windowAddress.length > 0
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: drag.active
            ? Qt.ClosedHandCursor
            : Qt.OpenHandCursor

        drag.target: dragProxy
        drag.threshold: 7
        drag.smoothed: false

        onReleased: function(mouse) {
            if (drag.active) {
                // Use the actual pointer position in scene coordinates.
                // The previous Drag.target approach used the proxy/hotspot,
                // which introduced a visible offset from the cursor.
                const scenePoint = dragArea.mapToItem(
                    null,
                    mouse.x,
                    mouse.y
                )

                root.dropRequested(
                    root.windowAddress,
                    scenePoint.x,
                    scenePoint.y
                )

                dragProxy.Drag.cancel()
            }

            dragProxy.x = 0
            dragProxy.y = 0
        }

        onCanceled: {
            if (drag.active)
                dragProxy.Drag.cancel()

            dragProxy.x = 0
            dragProxy.y = 0
        }
    }
}
