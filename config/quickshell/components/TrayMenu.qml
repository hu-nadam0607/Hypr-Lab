pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "."

PopupWindow {
    id: menuRoot

    property color accentColor: "#68787D"

    readonly property color surfaceColor: Qt.rgba(12 / 255, 15 / 255, 18 / 255, 0.88)
    readonly property color cardColor: Qt.rgba(1, 1, 1, 0.027)
    readonly property color cardBorderColor: Qt.rgba(1, 1, 1, 0.055)

    function accent(alpha) {
        return Qt.rgba(accentColor.r, accentColor.g, accentColor.b, alpha);
    }

    property var menu: null
    property var anchorItem: null

    implicitWidth: 250
    implicitHeight: menuColumn.implicitHeight + 20

    color: "transparent"

    visible: false

    grabFocus: true

    anchor.item: menuRoot.anchorItem

    anchor.edges: Edges.Bottom | Edges.Right

    anchor.gravity: Edges.Bottom | Edges.Right

    anchor.margins.bottom: -8

    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide

    onVisibleChanged: {
        if (visible) {
            menuBackground.opacity = 0;
            openAnimation.restart();
        }
    }

    NumberAnimation {
        id: openAnimation

        target: menuBackground
        property: "opacity"

        from: 0
        to: 1

        duration: 180

        easing.type: Easing.OutCubic
    }

    BackgroundEffect.blurRegion: Region {
        item: menuBackground
    }

    QsMenuOpener {
        id: menuOpener

        menu: menuRoot.menu
    }

    Shadow {
        id: menuShadow

        sourceItem: menuBackground

        z: -2
    }

    Glow {
        id: menuGlow

        sourceItem: menuBackground

        z: -1
    }

    Rectangle {
        id: menuBackground

        anchors.fill: parent

        radius: 1

        opacity: 1

        color: menuRoot.surfaceColor

        border.width: 2

        border.color: menuRoot.accent(0.42)

        Column {
            id: menuColumn

            anchors.fill: parent
            anchors.margins: 10

            spacing: 3

            Repeater {
                model: menuOpener.children

                delegate: Item {
                    id: menuItem

                    required property var modelData

                    width: menuColumn.width

                    height: menuItem.modelData.isSeparator ? 9 : 34

                    Rectangle {
                        visible: menuItem.modelData.isSeparator

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        height: 1

                        gradient: Gradient {
                            orientation: Gradient.Horizontal

                            GradientStop {
                                position: 0.0
                                color: menuRoot.accent(0.0)
                            }

                            GradientStop {
                                position: 0.5
                                color: menuRoot.accent(0.65)
                            }

                            GradientStop {
                                position: 1.0
                                color: menuRoot.accent(0.0)
                            }
                        }
                    }

                    Rectangle {
                        id: itemBackground

                        visible: !menuItem.modelData.isSeparator

                        anchors.fill: parent

                        radius: 1

                        color: mouseArea.containsMouse ? menuRoot.accent(0.055) : menuRoot.cardColor

                        border.width: 1

                        border.color: mouseArea.containsMouse ? menuRoot.accent(0.34) : menuRoot.cardBorderColor

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Image {
                            id: menuIcon

                            anchors.left: parent.left
                            anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter

                            width: 17
                            height: 17

                            source: menuItem.modelData.icon

                            sourceSize.width: 17
                            sourceSize.height: 17

                            visible: menuItem.modelData.icon !== ""
                        }

                        Text {
                            id: menuText

                            anchors.left: menuIcon.visible ? menuIcon.right : parent.left

                            anchors.leftMargin: menuIcon.visible ? 10 : 12

                            anchors.right: menuArrow.visible ? menuArrow.left : parent.right

                            anchors.rightMargin: 8

                            anchors.verticalCenter: parent.verticalCenter

                            text: menuItem.modelData.text

                            color: menuItem.modelData.enabled ? "white" : Qt.rgba(1, 1, 1, 0.35)

                            font.family: "Inter"
                            font.pixelSize: 12

                            elide: Text.ElideRight
                        }

                        Text {
                            id: menuArrow

                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter

                            text: ">"

                            visible: menuItem.modelData.hasChildren

                            color: menuRoot.accentColor

                            font.family: "Inter"
                            font.pixelSize: 18
                        }

                        MouseArea {
                            id: mouseArea

                            anchors.fill: parent

                            enabled: menuItem.modelData.enabled

                            hoverEnabled: true

                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                menuItem.modelData.triggered();
                                menuRoot.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }

    function showMenu() {
        menuRoot.visible = true;
    }
}
