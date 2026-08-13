import QtQuick
import Quickshell
import Quickshell.Wayland

PopupWindow {
    id: menuRoot

    // ============================================================
    // PUBLIC API
    // ============================================================

    property var menu: null
    property var anchorItem: null

    // ============================================================
    // WINDOW
    // ============================================================

    implicitWidth: 250
    implicitHeight: menuColumn.implicitHeight + 20

    color: "transparent"

    visible: false

    grabFocus: true

    // ============================================================
    // POSITION
    // ============================================================

    anchor.item: menuRoot.anchorItem

    // A tray ikon alsó jobb sarkát használjuk anchorpontnak.
    anchor.edges: Edges.Bottom | Edges.Right

    // A popup LEFELÉ terjeszkedik.
    anchor.gravity: Edges.Bottom | Edges.Right

    // Kis távolság a RightBar és a menü között.
    anchor.margins.bottom: -8

    // Ha a képernyő széléhez ér, igazodjon.
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide

    // ============================================================
    // OPEN ANIMATION
    // ============================================================

    onVisibleChanged: {
        if (visible) {
            menuBackground.opacity = 0
            menuBackground.scale = 0.94

            openAnimation.restart()
        }
    }

    ParallelAnimation {
        id: openAnimation

        NumberAnimation {
            target: menuBackground
            property: "opacity"

            from: 0
            to: 1

            duration: 180

            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: menuBackground
            property: "scale"

            from: 0.94
            to: 1.0

            duration: 220

            easing.type: Easing.OutBack
        }
    }

    // ============================================================
    // GLASS BACKGROUND BLUR
    // ============================================================

    BackgroundEffect.blurRegion: Region {
        item: menuBackground
    }

    // ============================================================
    // MENU DATA
    // ============================================================

    QsMenuOpener {
        id: menuOpener

        menu: menuRoot.menu
    }

    // ============================================================
    // SHADOW
    // ============================================================

    Shadow {
        id: menuShadow

        sourceItem: menuBackground

        z: -2
    }

    // ============================================================
    // CYAN GLOW
    // ============================================================

    Glow {
        id: menuGlow

        sourceItem: menuBackground

        z: -1
    }

    // ============================================================
    // GLASS BACKGROUND
    // ============================================================

    Rectangle {
        id: menuBackground

        anchors.fill: parent

        radius: 16

        opacity: 1
        scale: 1

        transformOrigin: Item.TopRight

        color: Qt.rgba(
            10 / 255,
            12 / 255,
            18 / 255,
            0.72
        )

        border.width: 2

        border.color: Qt.rgba(
            55 / 255,
            245 / 255,
            235 / 255,
            0.55
        )

        // ========================================================
        // CONTENT
        // ========================================================

        Column {
            id: menuColumn

            anchors.fill: parent
            anchors.margins: 10

            spacing: 3

            Repeater {
                model: menuOpener.children

                delegate: Item {

                    required property var modelData

                    width: menuColumn.width

                    height: modelData.isSeparator
                            ? 9
                            : 34

                    // =================================================
                    // SEPARATOR
                    // =================================================

                    Rectangle {
                        visible: modelData.isSeparator

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        height: 1

                        color: Qt.rgba(
                            1,
                            1,
                            1,
                            0.10
                        )
                    }

                    // =================================================
                    // MENU ITEM
                    // =================================================

                    Rectangle {
                        id: itemBackground

                        visible: !modelData.isSeparator

                        anchors.fill: parent

                        radius: 9

                        color: mouseArea.containsMouse
                               ? Qt.rgba(
                                     55 / 255,
                                     245 / 255,
                                     235 / 255,
                                     0.16
                                 )
                               : Qt.rgba(
                                     1,
                                     1,
                                     1,
                                     0.015
                                 )

                        border.width:
                            mouseArea.containsMouse ? 1 : 0

                        border.color: Qt.rgba(
                            55 / 255,
                            245 / 255,
                            235 / 255,
                            0.20
                        )

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        // =================================================
                        // ICON
                        // =================================================

                        Image {
                            id: menuIcon

                            anchors.left: parent.left
                            anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter

                            width: 17
                            height: 17

                            source: modelData.icon

                            sourceSize.width: 17
                            sourceSize.height: 17

                            visible: source !== ""
                        }

                        // =================================================
                        // TEXT
                        // =================================================

                        Text {
                            id: menuText

                            anchors.left: menuIcon.visible
                                         ? menuIcon.right
                                         : parent.left

                            anchors.leftMargin: menuIcon.visible
                                               ? 10
                                               : 12

                            anchors.right: menuArrow.visible
                                            ? menuArrow.left
                                            : parent.right

                            anchors.rightMargin: menuArrow.visible
                                                 ? 8
                                                 : 12

                            anchors.verticalCenter:
                                parent.verticalCenter

                            text: modelData.text

                            color: modelData.enabled
                                   ? "white"
                                   : Qt.rgba(
                                         1,
                                         1,
                                         1,
                                         0.35
                                     )

                            font.family: "Inter"
                            font.pixelSize: 12

                            elide: Text.ElideRight
                        }

                        // =================================================
                        // SUBMENU ARROW
                        // =================================================

                        Text {
                            id: menuArrow

                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter

                            text: "›"

                            visible: modelData.hasChildren

                            color: Qt.rgba(
                                55 / 255,
                                245 / 255,
                                235 / 255,
                                0.75
                            )

                            font.family: "Inter"
                            font.pixelSize: 18
                        }

                        // =================================================
                        // MOUSE
                        // =================================================

                        MouseArea {
                            id: mouseArea

                            anchors.fill: parent

                            enabled: modelData.enabled

                            hoverEnabled: true

                            cursorShape:
                                Qt.PointingHandCursor

                            onClicked: {
                                modelData.triggered()
                                menuRoot.visible = false
                            }
                        }
                    }
                }
            }
        }
    }

    // ============================================================
    // API
    // ============================================================

    function showMenu() {
        menuRoot.visible = true
    }
}