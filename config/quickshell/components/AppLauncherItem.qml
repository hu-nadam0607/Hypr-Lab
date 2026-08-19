import QtQuick
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root

    required property var app
    required property int itemIndex
    property bool selected: false
    property color accentColor: "#68787D"

    // Grid geometry supplied by AppLauncher.qml. The visual translation does not
    // interfere with GridView's own layout, but makes every row track the panel slant.
    property real gridCellWidth: 160
    property real gridCellHeight: 98
    property int gridColumns: 4
    property real panelHeight: 585
    property real panelSlant: 36
    property real gridTopInPanel: 97
    property real gridCenterInPanel: 292

    // GridView delegates live in content coordinates. During scrolling, using the
    // model row would leave the old X offset behind and the item could cross the
    // slanted panel edge. Convert the delegate center to the *visible viewport Y*
    // and derive the slant from that live position instead.
    readonly property real viewportContentY: GridView.view ? GridView.view.contentY : 0
    readonly property real visibleCenterY: root.gridTopInPanel + root.y - root.viewportContentY + root.height / 2
    // The GridView itself is centered on the parent panel at its own vertical
    // midpoint. Each visible row only needs the *difference* from that center.
    // This prevents the whole grid from drifting left while still following
    // the exact parent slant during scrolling.
    readonly property real rowSlantShift: -root.panelSlant * (root.visibleCenterY - root.gridCenterInPanel) / Math.max(1, root.panelHeight)

    signal activated()

    width: Math.max(120, root.gridCellWidth - 12)
    height: 92

    transform: Translate {
        x: root.rowSlantShift
    }
    radius: 0

    color: root.selected
        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.115)
        : mouseArea.containsMouse
            ? Qt.rgba(1, 1, 1, 0.050)
            : Qt.rgba(1, 1, 1, 0.018)

    border.width: root.selected ? 1 : 0
    border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.55)

    Behavior on color { ColorAnimation { duration: 85 } }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.selected ? 2 : 0
        color: root.accentColor
        opacity: root.selected ? 0.95 : 0

        Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 80 } }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 18
        spacing: 7

        IconImage {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitSize: 35
            source: Quickshell.iconPath(root.app.icon, "application-x-executable")
            asynchronous: true
        }

        Text {
            width: parent.width
            text: root.app.name
            color: root.selected ? "#ffffff" : Qt.rgba(0.94, 0.96, 0.97, 0.86)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: "Inter"
            font.pixelSize: 12
            font.italic: true
            font.weight: root.selected ? Font.DemiBold : Font.Medium
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            if (GridView.view)
                GridView.view.currentIndex = root.itemIndex
        }

        onClicked: root.activated()
    }
}
