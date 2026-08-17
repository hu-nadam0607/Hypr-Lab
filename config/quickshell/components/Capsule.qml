import QtQuick

Rectangle {
    id: capsule

    property int capsuleWidth: 240
    property int capsuleHeight: 40

    property int capsuleRadius: capsuleHeight / 2

    property color capsuleColor: Qt.rgba(7 / 255, 12 / 255, 18 / 255, 0.20)

    property color borderColor: Qt.rgba(1, 1, 1, 0.12)
    property int borderWidth: 1

    width: capsuleWidth
    height: capsuleHeight

    radius: capsuleRadius
    color: capsuleColor

    border.width: borderWidth
    border.color: borderColor

    Rectangle {
        anchors.fill: parent
        radius: capsule.radius
        color: "transparent"

        gradient: Gradient {
            GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.20) }
            GradientStop { position: 0.12; color: Qt.rgba(1, 1, 1, 0.070) }
            GradientStop { position: 0.42; color: "transparent" }
            GradientStop { position: 0.78; color: "transparent" }
            GradientStop { position: 1.00; color: Qt.rgba(0, 0, 0, 0.20) }
        }
    }

    Behavior on radius {
        SpringAnimation {
            spring: 3.5
            damping: 0.25
        }
    }
}
