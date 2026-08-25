import QtQuick

Item {
    id: root

    property int workspaceId: 1
    property bool selected: false
    property int workspaceCount: 1
    property url wallpaperSource: ""
    property color accentColor: "#68787D"

    signal selectedRequested(int workspaceId)
    signal closeRequested(int workspaceId)
    signal windowMoveRequested(string address, int workspaceId)

    readonly property bool hovered:
        hoverSensor.containsMouse
        || closeMouse.containsMouse
        || dropArea.containsDrag

    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: root.selectedRequested(root.workspaceId)
    }

    Rectangle {
        id: cardSurface
        anchors.fill: parent
        color: root.selected
            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.10)
            : Qt.rgba(0.025, 0.045, 0.06, 0.90)
        border.width: root.selected || root.hovered ? 2 : 1
        border.color: root.selected || dropArea.containsDrag
            ? root.accentColor
            : (root.hovered
                ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.70)
                : Qt.rgba(1, 1, 1, 0.14))
        radius: 1

        Behavior on border.color {
            ColorAnimation { duration: 90 }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 90
                easing.type: Easing.OutCubic
            }
        }
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 28
        z: 40

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "WORKSPACE " + root.workspaceId
            color: root.selected
                ? root.accentColor
                : Qt.rgba(1, 1, 1, 0.72)
            font.family: "Inter"
            font.pixelSize: 8
            font.bold: true
            font.italic: true
        }
    }

    HyprScopeWorkspacePreview {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.margins: 5

        workspaceId: root.workspaceId
        wallpaperSource: root.wallpaperSource
        accentColor: root.accentColor
        liveWindows: false

        // Only the big center preview is allowed to start app drags.
        allowWindowDrag: false
    }

    // Reliable hover sensor over the complete card. It accepts no buttons,
    // so click selection and the X button remain functional.
    MouseArea {
        id: hoverSensor
        anchors.fill: parent
        z: 100
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    Rectangle {
        id: closeButton
        width: 24
        height: 24
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        z: 2000
        visible: root.workspaceCount > 1 && root.hovered

        color: closeMouse.containsMouse
            ? Qt.rgba(0.95, 0.24, 0.20, 0.18)
            : Qt.rgba(0.02, 0.03, 0.04, 0.82)
        border.width: 1
        border.color: closeMouse.containsMouse
            ? "#ff6258"
            : Qt.rgba(1, 1, 1, 0.18)
        radius: 1

        Text {
            anchors.centerIn: parent
            text: "×"
            color: closeMouse.containsMouse
                ? "#ff6b63"
                : Qt.rgba(1, 1, 1, 0.70)
            font.family: "Inter"
            font.pixelSize: 14
            font.bold: true
        }

        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: function(mouse) {
                mouse.accepted = true
                root.closeRequested(root.workspaceId)
            }
        }
    }

    Rectangle {
        id: dropFlash
        anchors.fill: parent
        z: 900
        color: "transparent"
        border.width: 3
        border.color: root.accentColor
        opacity: 0.0
        visible: opacity > 0.001
    }

    SequentialAnimation {
        id: acceptedPulse

        NumberAnimation {
            target: dropFlash
            property: "opacity"
            from: 0.0
            to: 0.95
            duration: 70
        }

        NumberAnimation {
            target: dropFlash
            property: "opacity"
            from: 0.95
            to: 0.0
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        z: 500

        property int targetWorkspace: root.workspaceId
        keys: ["hypr-scope-window"]

        onEntered: {
            cardSurface.scale = 1.025
        }

        onExited: {
            cardSurface.scale = 1.0
        }
    }

}
