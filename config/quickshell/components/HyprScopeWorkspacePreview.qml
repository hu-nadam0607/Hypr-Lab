import QtQuick
import Quickshell.Hyprland

Item {
    id: root

    property int workspaceId: 1
    property url wallpaperSource: ""
    property color accentColor: "#68787D"
    property bool liveWindows: false
    property bool allowWindowDrag: true
    property bool showWindowLabels: true

    signal windowDropRequested(string address, real sceneX, real sceneY)

    readonly property var workspaceObject: {
        if (!Hyprland.workspaces)
            return null

        const values = Hyprland.workspaces.values

        for (let i = 0; i < values.length; ++i) {
            if (values[i].id === root.workspaceId)
                return values[i]
        }

        return null
    }

    readonly property var toplevelModel:
        root.workspaceObject
            ? root.workspaceObject.toplevels.values
            : []

    clip: true

    Rectangle {
        anchors.fill: parent
        color: "#071019"
    }

    Image {
        anchors.fill: parent
        source: root.wallpaperSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        opacity: 0.92
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.01, 0.02, 0.025, 0.22)
    }

    Repeater {
        model: root.toplevelModel

        delegate: HyprScopeWindowPreview {
            required property var modelData

            toplevel: modelData
            accentColor: root.accentColor
            livePreview: root.liveWindows
            allowWindowDrag: root.allowWindowDrag

            onDropRequested: function(address, sceneX, sceneY) {
                root.windowDropRequested(address, sceneX, sceneY)
            }

            monitorOriginX:
                modelData && modelData.monitor
                    ? modelData.monitor.x
                    : 0

            monitorOriginY:
                modelData && modelData.monitor
                    ? modelData.monitor.y
                    : 0

            monitorScaleX:
                modelData && modelData.monitor && modelData.monitor.width > 0
                    ? root.width / modelData.monitor.width
                    : 1.0

            monitorScaleY:
                modelData && modelData.monitor && modelData.monitor.height > 0
                    ? root.height / modelData.monitor.height
                    : 1.0
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.toplevelModel.length === 0
        text: "EMPTY WORKSPACE"
        color: Qt.rgba(1, 1, 1, 0.20)
        font.family: "Inter"
        font.pixelSize: Math.max(8, Math.min(13, root.height / 12))
        font.bold: true
        font.italic: true
    }
}
