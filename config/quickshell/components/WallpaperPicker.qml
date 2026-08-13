import QtQuick
import QtQuick.Controls
import QtQuick.Effects

import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    property var wallpaperModel: null

    property url currentWallpaper: ""

    property bool isOpen: false

    property bool windowVisible: false

    property real openProgress: 0.0

    signal wallpaperChosen(url source)

    readonly property int columns: 4

    readonly property int cellWidth: 230

    readonly property int cellHeight: 150

    // ============================================================
    // PUBLIC API
    // ============================================================

    function open(): void {
        if (isOpen)
            return

        windowVisible = true
        isOpen = true

        openDelay.restart()
        focusDelay.restart()
    }

    function close(): void {
        if (!windowVisible)
            return

        isOpen = false

        openDelay.stop()

        openProgress = 0.0

        hideDelay.restart()
    }

    function toggle(): void {
        if (isOpen)
            close()
        else
            open()
    }

    function currentWallpaperIndex(): int {
        if (!wallpaperModel)
            return -1

        for (
            let i = 0;
            i < wallpaperModel.count;
            ++i
        ) {
            const source =
                wallpaperModel.get(
                    i,
                    "fileUrl"
                )

            if (
                source.toString()
                ===
                currentWallpaper.toString()
            ) {
                return i
            }
        }

        return -1
    }

    function restoreSelection(): void {
        if (
            !wallpaperModel
            || wallpaperModel.count <= 0
        ) {
            wallpaperGrid.currentIndex =
                -1

            return
        }

        const index =
            currentWallpaperIndex()

        wallpaperGrid.currentIndex =
            index >= 0 ? index : 0

        wallpaperGrid.positionViewAtIndex(
            wallpaperGrid.currentIndex,
            GridView.Contain
        )
    }

    function moveHorizontal(
        delta: int
    ): void {
        if (wallpaperGrid.count <= 0)
            return

        wallpaperGrid.currentIndex =
            Math.max(
                0,
                Math.min(
                    wallpaperGrid.currentIndex
                    + delta,

                    wallpaperGrid.count - 1
                )
            )

        wallpaperGrid.positionViewAtIndex(
            wallpaperGrid.currentIndex,
            GridView.Contain
        )
    }

    function moveVertical(
        deltaRows: int
    ): void {
        moveHorizontal(
            deltaRows * columns
        )
    }

    function chooseSelected(): void {
        if (
            !wallpaperModel
            || wallpaperGrid.currentIndex < 0
        ) {
            return
        }

        const source =
            wallpaperModel.get(
                wallpaperGrid.currentIndex,
                "fileUrl"
            )

        if (source)
            wallpaperChosen(source)
    }

    // ============================================================
    // OPEN / CLOSE
    // ============================================================

    Timer {
        id: openDelay

        interval: 15

        repeat: false

        onTriggered:
            root.openProgress = 1.0
    }

    Timer {
        id: focusDelay

        interval: 70

        repeat: false

        onTriggered: {
            root.restoreSelection()

            keyboardCatcher
                .forceActiveFocus()
        }
    }

    Timer {
        id: hideDelay

        interval: 300

        repeat: false

        onTriggered:
            root.windowVisible = false
    }

    Behavior on openProgress {
        NumberAnimation {
            duration: 280

            easing.type:
                Easing.OutCubic
        }
    }

    // ============================================================
    // WINDOW
    // ============================================================

    PanelWindow {
        id: pickerWindow

        visible:
            root.windowVisible

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"

        // ========================================================
        // CRITICAL:
        //
        // A modal overlay NEM tiszteli a felső
        // Hypr-Lab panel exclusive zone-ját.
        //
        // Így ténylegesen 0,0-tól a monitor
        // legalsó pixeléig terjed.
        //
        // NE tegyünk mellé exclusiveZone: 0-t,
        // mert az visszavált Normal módba.
        // ========================================================

        exclusionMode:
            ExclusionMode.Ignore

        focusable: true
        aboveWindows: true

        WlrLayershell.namespace:
            "hypr-lab-wallpaper-picker"

        WlrLayershell.layer:
            WlrLayer.Overlay

        WlrLayershell.keyboardFocus:
            WlrKeyboardFocus.Exclusive

        // ========================================================
        // BACKDROP
        // ========================================================

        Rectangle {
            anchors.fill: parent

            color:
                Qt.rgba(
                    4 / 255,
                    7 / 255,
                    11 / 255,
                    0.28
                    * root.openProgress
                )

            MouseArea {
                anchors.fill: parent

                onClicked:
                    root.close()
            }
        }

        // ========================================================
        // PICKER CONTAINER
        // ========================================================

        Item {
            id: pickerContainer

            anchors.centerIn: parent

            width: 1000

            height:
                Math.min(
                    690,
                    Math.max(
                        390,

                        wallpaperGrid
                            .contentHeight
                        + 150
                    )
                )

            opacity:
                root.openProgress

            scale:
                0.94
                +
                (
                    0.06
                    * root.openProgress
                )

            transformOrigin:
                Item.Center

            // ====================================================
            // OUTER GLOW
            // ====================================================

            Rectangle {
                anchors.fill:
                    pickerCard

                anchors.margins: -7

                radius:
                    pickerCard.radius + 7

                color:
                    "transparent"

                border.width: 1

                border.color:
                    Qt.rgba(
                        55 / 255,
                        245 / 255,
                        235 / 255,

                        0.20
                        * root.openProgress
                    )

                opacity:
                    root.openProgress
            }

            // ====================================================
            // CARD
            // ====================================================

            Rectangle {
                id: pickerCard

                anchors.fill: parent

                radius: 28

                color:
                    Qt.rgba(
                        10 / 255,
                        14 / 255,
                        20 / 255,
                        0.94
                    )

                border.width: 2

                border.color:
                    Qt.rgba(
                        55 / 255,
                        245 / 255,
                        235 / 255,
                        0.78
                    )

                antialiasing: true

                MouseArea {
                    anchors.fill: parent

                    onClicked:
                        function(mouse) {
                            mouse.accepted = true
                        }
                }

                // ================================================
                // HEADER
                // ================================================

                Item {
                    id: header

                    anchors.top:
                        parent.top

                    anchors.left:
                        parent.left

                    anchors.right:
                        parent.right

                    height: 92

                    Text {
                        anchors.left:
                            parent.left

                        anchors.leftMargin:
                            28

                        anchors.top:
                            parent.top

                        anchors.topMargin:
                            20

                        text:
                            "HYPR-LAB WALLPAPERS"

                        color:
                            "#efffff"

                        font.family:
                            "Inter"

                        font.pixelSize:
                            18

                        font.weight:
                            Font.DemiBold

                        font.letterSpacing:
                            1.4
                    }

                    Text {
                        anchors.left:
                            parent.left

                        anchors.leftMargin:
                            28

                        anchors.top:
                            parent.top

                        anchors.topMargin:
                            52

                        text:
                            root.wallpaperModel
                            ?
                            root.wallpaperModel.count
                            +
                            " wallpaper  •  "
                            +
                            "← ↑ ↓ →  Enter  Esc"
                            :
                            "Nincs wallpaper model"

                        color:
                            Qt.rgba(
                                200 / 255,
                                220 / 255,
                                225 / 255,
                                0.55
                            )

                        font.family:
                            "Inter"

                        font.pixelSize:
                            13
                    }

                    Rectangle {
                        anchors.left:
                            parent.left

                        anchors.right:
                            parent.right

                        anchors.bottom:
                            parent.bottom

                        height: 1

                        color:
                            Qt.rgba(
                                55 / 255,
                                245 / 255,
                                235 / 255,
                                0.20
                            )
                    }
                }

                // ================================================
                // GRID
                // ================================================

                GridView {
                    id: wallpaperGrid

                    anchors.top:
                        header.bottom

                    anchors.left:
                        parent.left

                    anchors.right:
                        parent.right

                    anchors.bottom:
                        parent.bottom

                    anchors.margins: 20

                    clip: true

                    model:
                        root.wallpaperModel

                    cellWidth:
                        root.cellWidth

                    cellHeight:
                        root.cellHeight

                    boundsBehavior:
                        Flickable.StopAtBounds

                    highlightFollowsCurrentItem:
                        true

                    ScrollBar.vertical:
                        ScrollBar {}

                    delegate: Item {
                        id: delegateRoot

                        required property int index

                        required property url fileUrl

                        required property string fileName

                        width:
                            wallpaperGrid.cellWidth

                        height:
                            wallpaperGrid.cellHeight

                        readonly property bool selected:
                            wallpaperGrid.currentIndex
                            === index

                        readonly property bool activeWallpaper:
                            root.currentWallpaper
                                .toString()
                            ===
                            fileUrl.toString()

                        Item {
                            anchors.fill:
                                parent

                            anchors.margins:
                                7

                            // ====================================
                            // SELECTION BORDER
                            // ====================================

                            Rectangle {
                                anchors.fill:
                                    parent

                                anchors.margins:
                                    -4

                                radius: 18

                                color:
                                    "transparent"

                                antialiasing:
                                    true

                                border.width:
                                    delegateRoot.selected
                                    ? 2
                                    : 1

                                border.color:
                                    delegateRoot.selected
                                    ?
                                    Qt.rgba(
                                        55 / 255,
                                        245 / 255,
                                        235 / 255,
                                        0.95
                                    )
                                    :
                                    delegateRoot.activeWallpaper
                                    ?
                                    Qt.rgba(
                                        55 / 255,
                                        245 / 255,
                                        235 / 255,
                                        0.42
                                    )
                                    :
                                    Qt.rgba(
                                        1,
                                        1,
                                        1,
                                        0.08
                                    )

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 130
                                    }
                                }
                            }

                            // ====================================
                            // THUMBNAIL
                            // ====================================

                            Item {
                                id: thumbnailFrame

                                anchors.fill:
                                    parent

                                Image {
                                    id: thumbnailSource

                                    anchors.fill:
                                        parent

                                    source:
                                        delegateRoot.fileUrl

                                    fillMode:
                                        Image.PreserveAspectCrop

                                    asynchronous:
                                        true

                                    cache:
                                        true

                                    smooth:
                                        true

                                    mipmap:
                                        true

                                    visible:
                                        false
                                }

                                Item {
                                    id: thumbnailMask

                                    anchors.fill:
                                        parent

                                    visible:
                                        false

                                    layer.enabled:
                                        true

                                    Rectangle {
                                        anchors.fill:
                                            parent

                                        radius:
                                            14

                                        color:
                                            "white"

                                        antialiasing:
                                            true
                                    }
                                }

                                MultiEffect {
                                    anchors.fill:
                                        parent

                                    source:
                                        thumbnailSource

                                    maskEnabled:
                                        true

                                    maskSource:
                                        thumbnailMask

                                    maskThresholdMin:
                                        0.5

                                    maskSpreadAtMin:
                                        1.0
                                }

                                Rectangle {
                                    anchors.left:
                                        parent.left

                                    anchors.right:
                                        parent.right

                                    anchors.bottom:
                                        parent.bottom

                                    height: 43

                                    bottomLeftRadius:
                                        14

                                    bottomRightRadius:
                                        14

                                    gradient:
                                        Gradient {

                                            GradientStop {
                                                position:
                                                    0.0

                                                color:
                                                    "#00000000"
                                            }

                                            GradientStop {
                                                position:
                                                    1.0

                                                color:
                                                    "#df000000"
                                            }
                                        }
                                }

                                Text {
                                    anchors.left:
                                        parent.left

                                    anchors.leftMargin:
                                        11

                                    anchors.right:
                                        activeMark.left

                                    anchors.rightMargin:
                                        8

                                    anchors.bottom:
                                        parent.bottom

                                    anchors.bottomMargin:
                                        9

                                    text:
                                        delegateRoot.fileName

                                    elide:
                                        Text.ElideRight

                                    color:
                                        "#f2ffff"

                                    font.family:
                                        "Inter"

                                    font.pixelSize:
                                        12

                                    font.weight:
                                        Font.Medium
                                }

                                Rectangle {
                                    id: activeMark

                                    anchors.right:
                                        parent.right

                                    anchors.rightMargin:
                                        10

                                    anchors.bottom:
                                        parent.bottom

                                    anchors.bottomMargin:
                                        10

                                    width: 9
                                    height: 9

                                    radius: 5

                                    visible:
                                        delegateRoot
                                            .activeWallpaper

                                    color:
                                        "#37f5eb"
                                }

                                Rectangle {
                                    anchors.fill:
                                        parent

                                    radius:
                                        14

                                    color:
                                        mouseArea
                                            .containsMouse
                                        ?
                                        Qt.rgba(
                                            55 / 255,
                                            245 / 255,
                                            235 / 255,
                                            0.08
                                        )
                                        :
                                        "transparent"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration:
                                                120
                                        }
                                    }
                                }

                                MouseArea {
                                    id: mouseArea

                                    anchors.fill:
                                        parent

                                    hoverEnabled:
                                        true

                                    cursorShape:
                                        Qt.PointingHandCursor

                                    onEntered:
                                        wallpaperGrid
                                            .currentIndex
                                        =
                                        delegateRoot.index

                                    onClicked: {
                                        wallpaperGrid
                                            .currentIndex
                                        =
                                        delegateRoot.index

                                        root.wallpaperChosen(
                                            delegateRoot.fileUrl
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ========================================================
        // KEYBOARD
        // ========================================================

        Item {
            id: keyboardCatcher

            anchors.fill:
                parent

            focus: true

            Keys.onPressed:
                function(event) {

                    if (
                        event.key
                        === Qt.Key_Escape
                    ) {
                        root.close()

                        event.accepted =
                            true

                        return
                    }

                    if (
                        event.key
                        === Qt.Key_Left
                    ) {
                        root.moveHorizontal(-1)

                        event.accepted =
                            true

                        return
                    }

                    if (
                        event.key
                        === Qt.Key_Right
                    ) {
                        root.moveHorizontal(1)

                        event.accepted =
                            true

                        return
                    }

                    if (
                        event.key
                        === Qt.Key_Up
                    ) {
                        root.moveVertical(-1)

                        event.accepted =
                            true

                        return
                    }

                    if (
                        event.key
                        === Qt.Key_Down
                    ) {
                        root.moveVertical(1)

                        event.accepted =
                            true

                        return
                    }

                    if (
                        event.key
                        === Qt.Key_Return
                        ||
                        event.key
                        === Qt.Key_Enter
                    ) {
                        root.chooseSelected()

                        event.accepted =
                            true
                    }
                }
        }
    }
}