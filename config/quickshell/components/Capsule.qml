import QtQuick

Rectangle {
    id: capsule

    property int capsuleWidth: 240
    property int capsuleHeight: 40

    property int capsuleRadius: capsuleHeight / 2

    property color capsuleColor: Qt.rgba(15 / 255, 20 / 255, 28 / 255, 0.45)

    property color borderColor: Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.50)
    property int borderWidth: 2

    width: capsuleWidth
    height: capsuleHeight

    radius: capsuleRadius
    color: capsuleColor

    border.width: borderWidth
    border.color: borderColor

    Behavior on radius {
        SpringAnimation {
            spring: 3.5
            damping: 0.25
        }
    }
}
