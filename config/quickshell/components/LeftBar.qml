import QtQuick
import Quickshell.Hyprland

Item {
    id: leftBarRoot

    property int barWidth: 1080
    property int barHeight: 36
    property color accentColor: "#68787D"

    readonly property int activeWorkspaceId:
        Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    property real indicatorLeft: 0
    property real indicatorRight: 28
    property real targetIndicatorLeft: 0
    property real targetIndicatorRight: 28
    property bool indicatorInitialized: false

    signal openAppLauncher()

    implicitWidth: barWidth
    implicitHeight: barHeight

    Capsule {
        id: capsule
        anchors.fill: parent
        capsuleWidth: leftBarRoot.barWidth
        capsuleHeight: leftBarRoot.barHeight
        borderColor: Qt.rgba(leftBarRoot.accentColor.r, leftBarRoot.accentColor.g, leftBarRoot.accentColor.b, 0.82)
    }

    function updateIndicator(animate) {
        const index = Math.max(0, Math.min(9, leftBarRoot.activeWorkspaceId - 1))
        const item = workspaceRepeater.itemAt(index)

        if (!item)
            return

        const left = item.x - 2
        const right = item.x + item.width + 2

        leftBarRoot.targetIndicatorLeft = left
        leftBarRoot.targetIndicatorRight = right

        if (!leftBarRoot.indicatorInitialized || !animate) {
            moveRightAnimation.stop()
            moveLeftAnimation.stop()
            leftBarRoot.indicatorLeft = left
            leftBarRoot.indicatorRight = right
            leftBarRoot.indicatorInitialized = true
            activeIndicator.requestPaint()
            return
        }

        if (left > leftBarRoot.indicatorLeft) {
            moveLeftAnimation.stop()
            moveRightAnimation.restart()
        } else if (left < leftBarRoot.indicatorLeft) {
            moveRightAnimation.stop()
            moveLeftAnimation.restart()
        } else {
            leftBarRoot.indicatorLeft = left
            leftBarRoot.indicatorRight = right
        }
    }

    // Moving right: the leading edge reaches the new workspace first,
    // then the old left edge snaps after it with a springy catch-up.
    SequentialAnimation {
        id: moveRightAnimation

        NumberAnimation {
            target: leftBarRoot
            property: "indicatorRight"
            to: leftBarRoot.targetIndicatorRight
            duration: 105
            easing.type: Easing.OutCubic
        }

        SpringAnimation {
            target: leftBarRoot
            property: "indicatorLeft"
            to: leftBarRoot.targetIndicatorLeft
            spring: 6.4
            damping: 0.24
            epsilon: 0.08
        }
    }

    // Moving left is the same gesture mirrored: left edge stretches first,
    // then the trailing right edge catches up.
    SequentialAnimation {
        id: moveLeftAnimation

        NumberAnimation {
            target: leftBarRoot
            property: "indicatorLeft"
            to: leftBarRoot.targetIndicatorLeft
            duration: 105
            easing.type: Easing.OutCubic
        }

        SpringAnimation {
            target: leftBarRoot
            property: "indicatorRight"
            to: leftBarRoot.targetIndicatorRight
            spring: 6.4
            damping: 0.24
            epsilon: 0.08
        }
    }

    onIndicatorLeftChanged: activeIndicator.requestPaint()
    onIndicatorRightChanged: activeIndicator.requestPaint()
    onAccentColorChanged: activeIndicator.requestPaint()

    onActiveWorkspaceIdChanged: {
        Qt.callLater(function() {
            leftBarRoot.updateIndicator(true)
        })
    }

    Row {
        id: contentRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 24
        spacing: 7
        z: 1

        BarActionButton {
            id: launcherButton
            icon: "󰣇"
            iconSize: 15
            accentColor: leftBarRoot.accentColor
            onClicked: leftBarRoot.openAppLauncher()
        }

        Text {
            text: "/"
            color: Qt.rgba(1, 1, 1, 0.48)
            font.family: "Inter"
            font.pixelSize: 14
            font.italic: true
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            id: workspaceContainer
            width: workspaceRow.implicitWidth
            height: 26
            anchors.verticalCenter: parent.verticalCenter

            Canvas {
                id: activeIndicator
                x: leftBarRoot.indicatorLeft
                y: 1
                width: Math.max(4, leftBarRoot.indicatorRight - leftBarRoot.indicatorLeft)
                height: 24
                antialiasing: true
                z: 0

                onWidthChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d")
                    const s = Math.min(7, Math.max(3, width / 4))
                    ctx.clearRect(0, 0, width, height)
                    ctx.beginPath()
                    ctx.moveTo(s, 0)
                    ctx.lineTo(width, 0)
                    ctx.lineTo(width - s, height)
                    ctx.lineTo(0, height)
                    ctx.closePath()
                    ctx.fillStyle = leftBarRoot.accentColor
                    ctx.globalAlpha = 0.92
                    ctx.fill()
                    ctx.globalAlpha = 1.0
                }
            }

            Row {
                id: workspaceRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                z: 1

                Repeater {
                    id: workspaceRepeater
                    model: 10

                    WorkspaceButton {
                        workspaceId: index + 1
                        accentColor: leftBarRoot.accentColor
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            leftBarRoot.updateIndicator(false)
        })
    }
}
