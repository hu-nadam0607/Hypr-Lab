import QtQuick
import Quickshell.Io

Item {
    id: root

    property string iconText: "?"
    property string labelText: "Option"
    property var actionCommand: []
    property color accentColor: "#d9903d"
    property bool shown: false
    property int revealDelay: 0
    property int closeDelay: 0
    property real travelDistance: 1180

    signal triggered()

    width: 244
    height: 320
    opacity: 0
    scale: mouse.pressed ? 0.955 : (mouse.containsMouse ? 0.978 : 1.0)

    // Keep the Row's layout position untouched. The entrance/exit motion is
    // visual-only via a Translate transform, otherwise Row and animated x
    // fight each other and the four cards collapse on top of one another.
    transform: Translate {
        id: slideTranslate
        x: -root.travelDistance
    }

    Process { id: execProc; command: root.actionCommand }

    function execute(): void {
        // Launch first, then start the menu-close animation. This prevents the
        // action process from being torn down before it has actually started.
        execProc.running = false
        execProc.running = true
        root.triggered()
    }

    states: [
        State {
            name: "shown"
            when: root.shown
            PropertyChanges { target: slideTranslate; x: 0 }
            PropertyChanges { target: root; opacity: 1 }
        },
        State {
            name: "hidden"
            when: !root.shown
            PropertyChanges { target: slideTranslate; x: root.travelDistance }
            PropertyChanges { target: root; opacity: 0 }
        }
    ]

    transitions: [
        Transition {
            from: ""; to: "shown"
            SequentialAnimation {
                PauseAnimation { duration: root.revealDelay }
                ParallelAnimation {
                    NumberAnimation { target: slideTranslate; property: "x"; duration: 235; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; duration: 145; easing.type: Easing.OutCubic }
                }
            }
        },
        Transition {
            from: "hidden"; to: "shown"
            SequentialAnimation {
                PauseAnimation { duration: root.revealDelay }
                ParallelAnimation {
                    NumberAnimation { target: slideTranslate; property: "x"; duration: 235; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; duration: 145; easing.type: Easing.OutCubic }
                }
            }
        },
        Transition {
            from: "shown"; to: "hidden"
            SequentialAnimation {
                PauseAnimation { duration: root.closeDelay }
                ParallelAnimation {
                    NumberAnimation { target: slideTranslate; property: "x"; duration: 205; easing.type: Easing.InCubic }
                    NumberAnimation { property: "opacity"; duration: 155; easing.type: Easing.InCubic }
                }
            }
        }
    ]

    Behavior on scale {
        NumberAnimation { duration: 95; easing.type: Easing.OutCubic }
    }

    Canvas {
        id: card
        anchors.fill: parent
        antialiasing: true

        function path(ctx, inset) {
            const s = 34
            ctx.beginPath()
            ctx.moveTo(s + inset, inset)
            ctx.lineTo(width - inset, inset)
            ctx.lineTo(width - s - inset, height - inset)
            ctx.lineTo(inset, height - inset)
            ctx.closePath()
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            path(ctx, 2)
            ctx.fillStyle = mouse.containsMouse
                ? Qt.rgba(10/255, 14/255, 18/255, 0.72)
                : Qt.rgba(7/255, 11/255, 15/255, 0.62)
            ctx.fill()

            const glass = ctx.createLinearGradient(0, 0, width, height)
            glass.addColorStop(0.00, Qt.rgba(1,1,1, mouse.containsMouse ? 0.105 : 0.075))
            glass.addColorStop(0.42, Qt.rgba(1,1,1,0.018))
            glass.addColorStop(1.00, Qt.rgba(0,0,0,0.18))
            path(ctx, 2)
            ctx.fillStyle = glass
            ctx.fill()

            path(ctx, 2)
            ctx.lineWidth = 2
            ctx.strokeStyle = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b,
                                      mouse.containsMouse ? 1.0 : 0.78)
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(38, 3)
            ctx.lineTo(width - 5, 3)
            ctx.lineWidth = 0.7
            ctx.strokeStyle = Qt.rgba(1,1,1,0.18)
            ctx.stroke()
        }

        Connections {
            target: mouse
            function onContainsMouseChanged() { card.requestPaint() }
        }
        Connections {
            target: root
            function onAccentColorChanged() { card.requestPaint() }
        }
    }

    // One centered content group for all three visual elements. Keeping the
    // icon, label and underline in the same coordinate space prevents the
    // previous independent offsets from making the contents look shifted
    // inside the angled card.
    Item {
        id: contentGroup
        anchors.centerIn: parent
        width: parent.width
        height: 178

        Text {
            id: optionIcon
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: parent.width
            height: 72
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.iconText
            color: root.accentColor
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 58
            font.weight: Font.Light
            scale: mouse.containsMouse ? 1.035 : 1.0
            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
        }

        Text {
            id: optionLabel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: optionIcon.bottom
            anchors.topMargin: 18
            width: parent.width
            height: 30
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.labelText
            color: Qt.rgba(1,1,1,0.94)
            font.family: "Inter"
            font.pixelSize: 21
            font.weight: Font.DemiBold
            font.italic: true
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: mouse.containsMouse ? 96 : 72
            height: 2
            color: root.accentColor
            opacity: mouse.containsMouse ? 0.95 : 0.70
            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: root.execute()
    }
}
