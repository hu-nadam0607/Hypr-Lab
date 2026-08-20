import QtQuick
import QtQuick.Controls
import QtQuick.Effects

import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    property var wallpaperModel: null
    property url currentWallpaper: ""
    property color accentColor: "#37f5eb"

    property bool isOpen: false
    property bool windowVisible: false
    property real openProgress: 0.0
    property real exitProgress: 0.0
    property url pendingWallpaper: ""
    property string hoveredFileName: ""
    property int edgeScrollDirection: 0

    signal wallpaperChosen(url source)

    Timer {
        id: edgeScrollTimer
        interval: 16
        repeat: true

        onTriggered: {
            if (root.edgeScrollDirection === 0)
                return

            const maxX =
                Math.max(
                    0,
                    ribbonView.contentWidth
                    - ribbonView.width
                )

            const nextX =
                Math.max(
                    0,
                    Math.min(
                        maxX,
                        ribbonView.contentX
                        + root.edgeScrollDirection * 4.4
                    )
                )

            ribbonView.contentX = nextX

            if (
                nextX <= 0
                || nextX >= maxX
            ) {
                stop()
                root.edgeScrollDirection = 0
            }
        }
    }

    readonly property real topBarHeight: 36
    readonly property int cardWidth: 230
    readonly property int cardHeight: 142
    readonly property int cardSpacing: 12

    readonly property string selectedFileName: {
        if (
            !wallpaperModel
            || ribbonView.currentIndex < 0
            || ribbonView.currentIndex >= wallpaperModel.count
        ) {
            return ""
        }

        return wallpaperModel.get(
            ribbonView.currentIndex,
            "fileName"
        )
    }

    function open(): void {
        if (isOpen)
            return

        pendingWallpaper = ""
        hoveredFileName = ""
        exitProgress = 0.0
        openProgress = 0.0
        windowVisible = true
        isOpen = true

        openDelay.restart()
        focusDelay.restart()
    }

    function close(): void {
        if (!windowVisible)
            return

        isOpen = false
        hoveredFileName = ""
        edgeScrollDirection = 0
        edgeScrollTimer.stop()
        openDelay.stop()
        applyDelay.stop()
        applyFadeDelay.stop()

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
                === currentWallpaper.toString()
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
            ribbonView.currentIndex = -1
            return
        }

        const index = currentWallpaperIndex()

        ribbonView.currentIndex =
            index >= 0 ? index : 0

        Qt.callLater(
            function() {
                ribbonView.positionViewAtIndex(
                    ribbonView.currentIndex,
                    ListView.Center
                )
            }
        )
    }

    function moveSelection(delta: int): void {
        if (ribbonView.count <= 0)
            return

        ribbonView.currentIndex =
            Math.max(
                0,
                Math.min(
                    ribbonView.currentIndex + delta,
                    ribbonView.count - 1
                )
            )

        ribbonView.positionViewAtIndex(
            ribbonView.currentIndex,
            ListView.Center
        )
    }

    function startEdgeScroll(direction: int): void {
        if (ribbonView.count <= 0)
            return

        edgeScrollDirection = direction
        edgeScrollTimer.start()
    }

    function stopEdgeScroll(direction: int): void {
        if (edgeScrollDirection === direction) {
            edgeScrollDirection = 0
            edgeScrollTimer.stop()
        }
    }

    function beginApply(source: url): void {
        if (
            !source
            || source.toString() === ""
            || pendingWallpaper.toString() !== ""
        ) {
            return
        }

        pendingWallpaper = source
        isOpen = false

        // The cards first fall out of the ribbon.
        exitProgress = 1.0

        // Then the remaining title/footer material fades away.
        applyFadeDelay.restart()

        // Only after the picker is visually gone does WallpaperManager receive
        // the selected source, so its existing random transition stays clean.
        applyDelay.restart()
    }

    function chooseSelected(): void {
        if (
            !wallpaperModel
            || ribbonView.currentIndex < 0
        ) {
            return
        }

        beginApply(
            wallpaperModel.get(
                ribbonView.currentIndex,
                "fileUrl"
            )
        )
    }

    Timer {
        id: openDelay
        interval: 18
        repeat: false

        onTriggered:
            root.openProgress = 1.0
    }

    Timer {
        id: focusDelay
        interval: 75
        repeat: false

        onTriggered: {
            root.restoreSelection()
            keyboardCatcher.forceActiveFocus()
        }
    }

    Timer {
        id: applyFadeDelay
        interval: 170
        repeat: false

        onTriggered:
            root.openProgress = 0.0
    }

    Timer {
        id: applyDelay
        interval: 360
        repeat: false

        onTriggered: {
            const source = root.pendingWallpaper

            if (
                source
                && source.toString() !== ""
            ) {
                root.wallpaperChosen(source)
            }
        }
    }

    Timer {
        id: hideDelay
        interval: 300
        repeat: false

        onTriggered: {
            root.windowVisible = false
            root.exitProgress = 0.0
            root.pendingWallpaper = ""
        }
    }

    Behavior on openProgress {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Behavior on exitProgress {
        NumberAnimation {
            duration: 260
            easing.type: Easing.InCubic
        }
    }

    PanelWindow {
        id: pickerWindow

        visible: root.windowVisible

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        aboveWindows: true

        WlrLayershell.namespace:
            "hypr-lab-wallpaper-picker"

        WlrLayershell.layer:
            WlrLayer.Overlay

        WlrLayershell.keyboardFocus:
            WlrKeyboardFocus.Exclusive

        // Keep the unified TopBar visually untouched. Everything under it gets
        // only a restrained dim layer; compositor blur is still provided by the
        // existing Hyprland layer rule for this namespace.
        Rectangle {
            anchors {
                top: parent.top
                topMargin: root.topBarHeight
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }

            color:
                Qt.rgba(
                    2 / 255,
                    5 / 255,
                    8 / 255,
                    0.24 * root.openProgress
                )

            MouseArea {
                anchors.fill: parent

                onClicked:
                    root.close()
            }
        }

        Item {
            id: titleBlock

            anchors.horizontalCenter: parent.horizontalCenter

            y: Math.max(
                root.topBarHeight + 78,
                parent.height * 0.25
            )

            width: 620
            height: 58
            opacity: root.openProgress

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top

                text: "VÁLASSZ EGY KÉPERNYŐHÁTTERET"

                color: Qt.rgba(1, 1, 1, 0.94)
                font.family: "Inter"
                font.pixelSize: 19
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 29

                text:
                    root.wallpaperModel
                    ?
                    root.wallpaperModel.count
                    + " háttérkép  •  ← → navigáció  •  Enter alkalmazás  •  Esc bezárás"
                    :
                    ""

                color: Qt.rgba(1, 1, 1, 0.46)
                font.family: "Inter"
                font.pixelSize: 11
            }
        }

        Item {
            id: ribbonHost

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            anchors.leftMargin: 110
            anchors.rightMargin: 110

            height: 205

            opacity:
                root.openProgress > 0
                || root.exitProgress > 0
                ? 1
                : 0

            Canvas {
                id: ribbonSurface

                anchors.fill: parent
                antialiasing: true
                opacity: 0.94 * root.openProgress

                onPaint: {
                    const ctx = getContext("2d")
                    const w = width
                    const h = height
                    const sl = 32

                    ctx.clearRect(0, 0, w, h)

                    ctx.beginPath()
                    ctx.moveTo(sl, 12)
                    ctx.lineTo(w - 8, 12)
                    ctx.lineTo(w - sl, h - 12)
                    ctx.lineTo(8, h - 12)
                    ctx.closePath()

                    ctx.fillStyle =
                        Qt.rgba(
                            6 / 255,
                            10 / 255,
                            14 / 255,
                            0.34
                        )
                    ctx.fill()

                    // Wallpaper-adaptive 2px bottom border only.
                    ctx.beginPath()
                    ctx.moveTo(8, h - 12.5)
                    ctx.lineTo(w - sl, h - 12.5)
                    ctx.lineWidth = 2
                    ctx.strokeStyle =
                        Qt.rgba(
                            root.accentColor.r,
                            root.accentColor.g,
                            root.accentColor.b,
                            0.88
                        )
                    ctx.stroke()
                }

                Connections {
                    target: root

                    function onAccentColorChanged(): void {
                        ribbonSurface.requestPaint()
                    }

                    function onOpenProgressChanged(): void {
                        ribbonSurface.requestPaint()
                    }
                }
            }

            ListView {
                id: ribbonView

                anchors.fill: parent
                anchors.leftMargin: 34
                anchors.rightMargin: 34
                anchors.topMargin: 22
                anchors.bottomMargin: 22

                orientation: ListView.Horizontal
                spacing: root.cardSpacing
                clip: true

                model:
                    root.windowVisible
                    ? root.wallpaperModel
                    : null

                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 2700
                maximumFlickVelocity: 2200

                currentIndex: -1
                highlightFollowsCurrentItem: false

                delegate: Item {
                    id: delegateRoot

                    required property int index
                    required property url fileUrl
                    required property string fileName

                    width: root.cardWidth
                    height: ribbonView.height

                    readonly property bool selected:
                        ribbonView.currentIndex === index

                    readonly property bool activeWallpaper:
                        root.currentWallpaper.toString()
                        === fileUrl.toString()

                    property bool entered: false

                    Timer {
                        id: entryTimer

                        interval:
                            35
                            + Math.min(
                                delegateRoot.index,
                                16
                            ) * 26

                        repeat: false

                        onTriggered:
                            delegateRoot.entered = true
                    }

                    Component.onCompleted:
                        entryTimer.start()

                    Item {
                        id: cardVisual

                        anchors.horizontalCenter: parent.horizontalCenter

                        width: root.cardWidth
                        height: root.cardHeight

                        y:
                            delegateRoot.entered
                            ?
                            (
                                8
                                + root.exitProgress * 205
                            )
                            :
                            -190

                        opacity:
                            delegateRoot.entered
                            ?
                            (
                                (1.0 - root.exitProgress)
                                * Math.max(
                                    root.openProgress,
                                    0.001
                                )
                            )
                            :
                            0

                        scale:
                            cardMouse.containsMouse
                            ? 1.055
                            : 1.0

                        z:
                            cardMouse.containsMouse
                            || delegateRoot.selected
                            ? 10
                            : 1

                        Behavior on y {
                            NumberAnimation {
                                duration: 330
                                easing.type: Easing.OutBack
                                easing.overshoot: 0.85
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 115
                                easing.type: Easing.OutCubic
                            }
                        }

                        Image {
                            id: wallpaperImage

                            anchors.fill: parent

                            source:
                                root.windowVisible
                                ? delegateRoot.fileUrl
                                : ""

                            sourceSize.width:
                                Math.ceil(width * 1.5)

                            sourceSize.height:
                                Math.ceil(height * 1.5)

                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            smooth: true
                            visible: false
                        }

                        Item {
                            id: angledMask

                            anchors.fill: parent
                            visible: false
                            layer.enabled: true

                            Canvas {
                                anchors.fill: parent
                                antialiasing: true

                                onPaint: {
                                    const ctx = getContext("2d")
                                    const w = width
                                    const h = height
                                    const sl = 18

                                    ctx.clearRect(0, 0, w, h)
                                    ctx.beginPath()
                                    ctx.moveTo(sl, 0)
                                    ctx.lineTo(w, 0)
                                    ctx.lineTo(w - sl, h)
                                    ctx.lineTo(0, h)
                                    ctx.closePath()
                                    ctx.fillStyle = "white"
                                    ctx.fill()
                                }
                            }
                        }

                        MultiEffect {
                            anchors.fill: parent

                            source: wallpaperImage
                            maskEnabled: true
                            maskSource: angledMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                        }

                        Item {
                            anchors.fill: parent

                            Canvas {
                                anchors.fill: parent
                                antialiasing: true
                                opacity: 0.52

                                onPaint: {
                                    const ctx = getContext("2d")
                                    const w = width
                                    const h = height
                                    const sl = 18

                                    ctx.clearRect(0, 0, w, h)

                                    ctx.beginPath()
                                    ctx.moveTo(sl, h * 0.58)
                                    ctx.lineTo(w - sl * 0.42, h * 0.58)
                                    ctx.lineTo(w - sl, h)
                                    ctx.lineTo(0, h)
                                    ctx.closePath()

                                    const g =
                                        ctx.createLinearGradient(
                                            0,
                                            h * 0.55,
                                            0,
                                            h
                                        )

                                    g.addColorStop(
                                        0,
                                        Qt.rgba(0, 0, 0, 0)
                                    )

                                    g.addColorStop(
                                        1,
                                        Qt.rgba(0, 0, 0, 0.78)
                                    )

                                    ctx.fillStyle = g
                                    ctx.fill()
                                }
                            }
                        }

                        Canvas {
                            id: cardBorder

                            anchors.fill: parent
                            antialiasing: true

                            function redraw(): void {
                                requestPaint()
                            }

                            onPaint: {
                                const ctx = getContext("2d")
                                const w = width
                                const h = height
                                const sl = 18

                                ctx.clearRect(0, 0, w, h)

                                ctx.beginPath()
                                ctx.moveTo(sl, 1)
                                ctx.lineTo(w - 1, 1)
                                ctx.lineTo(w - sl - 1, h - 1)
                                ctx.lineTo(1, h - 1)
                                ctx.closePath()

                                const emphasized =
                                    delegateRoot.selected
                                    || cardMouse.containsMouse
                                    || delegateRoot.activeWallpaper

                                ctx.lineWidth =
                                    delegateRoot.selected
                                    ? 2
                                    : 1

                                ctx.strokeStyle =
                                    emphasized
                                    ?
                                    Qt.rgba(
                                        root.accentColor.r,
                                        root.accentColor.g,
                                        root.accentColor.b,
                                        delegateRoot.selected
                                        ? 0.98
                                        : 0.66
                                    )
                                    :
                                    Qt.rgba(1, 1, 1, 0.13)

                                ctx.stroke()
                            }

                            Connections {
                                target: root

                                function onAccentColorChanged(): void {
                                    cardBorder.redraw()
                                }
                            }

                            Connections {
                                target: delegateRoot

                                function onSelectedChanged(): void {
                                    cardBorder.redraw()
                                }

                                function onActiveWallpaperChanged(): void {
                                    cardBorder.redraw()
                                }
                            }

                            Connections {
                                target: cardMouse

                                function onContainsMouseChanged(): void {
                                    cardBorder.redraw()
                                }
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 15
                            anchors.top: parent.top
                            anchors.topMargin: 11

                            width: 8
                            height: 8
                            radius: 4

                            visible:
                                delegateRoot.activeWallpaper

                            color: root.accentColor
                        }

                        MouseArea {
                            id: cardMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onContainsMouseChanged: {
                                if (containsMouse) {
                                    root.hoveredFileName =
                                        delegateRoot.fileName
                                } else if (
                                    root.hoveredFileName
                                    === delegateRoot.fileName
                                ) {
                                    root.hoveredFileName = ""
                                }
                            }

                            onClicked: {
                                ribbonView.currentIndex =
                                    delegateRoot.index

                                root.beginApply(
                                    delegateRoot.fileUrl
                                )
                            }
                        }
                    }
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse
                    orientation: Qt.Vertical

                    onWheel: function(event) {
                        if (event.angleDelta.y < 0)
                            root.moveSelection(1)
                        else if (event.angleDelta.y > 0)
                            root.moveSelection(-1)

                        event.accepted = true
                    }
                }
            }

            // Edge hover controls. No click is required:
            // entering the left/right zone jumps the ribbon to the first/last
            // wallpaper while keeping keyboard and wheel navigation unchanged.
            Item {
                id: leftEdgeControl

                anchors.right: parent.left
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                width: 72
                height: 118
                z: 30
                opacity: root.openProgress

                Text {
                    anchors.centerIn: parent

                    text: "<"

                    color:
                        leftEdgeMouse.containsMouse
                        ? root.accentColor
                        : Qt.rgba(1, 1, 1, 0.72)

                    font.family: "Inter"
                    font.pixelSize: 42
                    font.weight: Font.Light
                    font.italic: true

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }

                    scale:
                        leftEdgeMouse.containsMouse
                        ? 1.12
                        : 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 110
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: leftEdgeMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.NoButton

                    onEntered:
                        root.startEdgeScroll(-1)

                    onExited:
                        root.stopEdgeScroll(-1)
                }
            }

            Item {
                id: rightEdgeControl

                anchors.left: parent.right
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                width: 72
                height: 118
                z: 30
                opacity: root.openProgress

                Text {
                    anchors.centerIn: parent

                    text: ">"

                    color:
                        rightEdgeMouse.containsMouse
                        ? root.accentColor
                        : Qt.rgba(1, 1, 1, 0.72)

                    font.family: "Inter"
                    font.pixelSize: 42
                    font.weight: Font.Light
                    font.italic: true

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }

                    scale:
                        rightEdgeMouse.containsMouse
                        ? 1.12
                        : 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 110
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: rightEdgeMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.NoButton

                    onEntered:
                        root.startEdgeScroll(1)

                    onExited:
                        root.stopEdgeScroll(1)
                }
            }
        }

        Item {
            id: selectionFooter

            anchors.horizontalCenter: parent.horizontalCenter

            y:
                ribbonHost.y
                + ribbonHost.height
                + 20

            width: 700
            height: 52
            opacity: root.openProgress

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top

                text:
                    root.hoveredFileName !== ""
                    ? root.hoveredFileName
                    : root.selectedFileName

                color: Qt.rgba(1, 1, 1, 0.92)
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.italic: true
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 28

                width: 74
                height: 2

                color: root.accentColor
                opacity: 0.82
            }
        }

        Item {
            id: keyboardCatcher

            anchors.fill: parent
            focus: true

            Keys.onPressed:
                function(event) {
                    if (
                        event.key === Qt.Key_Escape
                    ) {
                        root.close()
                        event.accepted = true
                        return
                    }

                    if (
                        event.key === Qt.Key_Left
                        || event.key === Qt.Key_Up
                    ) {
                        root.moveSelection(-1)
                        event.accepted = true
                        return
                    }

                    if (
                        event.key === Qt.Key_Right
                        || event.key === Qt.Key_Down
                    ) {
                        root.moveSelection(1)
                        event.accepted = true
                        return
                    }

                    if (
                        event.key === Qt.Key_Return
                        || event.key === Qt.Key_Enter
                    ) {
                        root.chooseSelected()
                        event.accepted = true
                    }
                }
        }
    }
}
