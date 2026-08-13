import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var screen

    property url requestedSource: ""
    property int requestedEffect: 0

    property bool transitionPending: false
    property bool initialWallpaperPending: false

    property int brushMode: 0

    readonly property int brushStripCount: 24

    readonly property int tileColumns: 8
    readonly property int tileRows: 5
    readonly property int tileCount:
        tileColumns * tileRows

    readonly property int waveStripCount: 28

    property real slideDirectionX: 0
    property real slideDirectionY: 0

    screen: root.screen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "#000000"

    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace:
        "hypr-lab-wallpaper"

    WlrLayershell.layer:
        WlrLayer.Background

    WlrLayershell.keyboardFocus:
        WlrKeyboardFocus.None

    mask: Region {}

    updatesEnabled: true

    // ============================================================
    // CURRENT WALLPAPER
    // ============================================================

    Image {
    id: backImage

        anchors.fill: parent

        fillMode:
            Image.PreserveAspectCrop

        asynchronous: true
        cache: true
        smooth: true
        mipmap: true

        source: ""

        onStatusChanged: {
            if (
                status === Image.Ready
                && root.initialWallpaperPending
            ) {
                root.initialWallpaperPending = false
                initialFreezeTimer.restart()
            }
        }
    }

    // ============================================================
    // NEXT WALLPAPER
    // ============================================================

    Image {
        id: frontImage

        width: parent.width
        height: parent.height

        fillMode:
            Image.PreserveAspectCrop

        asynchronous: true
        cache: true
        smooth: true
        mipmap: true

        source: ""

        opacity: 0
        scale: 1

        x: 0
        y: 0

        visible:
            requestedEffect < 6

        onStatusChanged: {
            if (
                status === Image.Ready
                && root.transitionPending
            ) {
                root.startTransition()
            }
        }
    }

    // ============================================================
    // PREPARE NORMAL EFFECT
    // ============================================================

    function prepareNormalTransition(): void {
        normalTransition.stop()
        horizontalSlideTransition.stop()
        verticalSlideTransition.stop()

        frontImage.opacity = 0
        frontImage.scale = 1

        frontImage.x = 0
        frontImage.y = 0

        slideDirectionX = 0
        slideDirectionY = 0

        switch (requestedEffect) {

        case 0:
            // FADE

            frontImage.opacity = 0
            break

        case 1:
            // ZOOM

            frontImage.opacity = 0
            frontImage.scale = 1.14
            break

        case 2:
            // FROM RIGHT

            frontImage.opacity = 1
            frontImage.x = root.width

            slideDirectionX = -1
            break

        case 3:
            // FROM LEFT

            frontImage.opacity = 1
            frontImage.x = -root.width

            slideDirectionX = 1
            break

        case 4:
            // FROM BOTTOM

            frontImage.opacity = 1
            frontImage.y = root.height

            slideDirectionY = -1
            break

        case 5:
            // FROM TOP

            frontImage.opacity = 1
            frontImage.y = -root.height

            slideDirectionY = 1
            break
        }
    }

    // ============================================================
    // START TRANSITION
    // ============================================================

    function startTransition(): void {
        transitionPending = false
        updatesEnabled = true

        stopAllEffects()

        if (requestedEffect === 6) {
            startBrushTransition()
            return
        }

        if (requestedEffect === 7) {
            startFallingTiles()
            return
        }

        if (requestedEffect === 8) {
            startSpiralTransition()
            return
        }

        if (requestedEffect === 9) {
            startWaveTransition()
            return
        }

        prepareNormalTransition()

        if (
            requestedEffect === 2
            || requestedEffect === 3
        ) {
            horizontalSlideTransition.restart()
            return
        }

        if (
            requestedEffect === 4
            || requestedEffect === 5
        ) {
            verticalSlideTransition.restart()
            return
        }

        normalTransition.restart()
    }

    // ============================================================
    // STOP EFFECTS
    // ============================================================

    function stopAllEffects(): void {
        normalTransition.stop()
        horizontalSlideTransition.stop()
        verticalSlideTransition.stop()

        brushFinishTimer.stop()
        tileFinishTimer.stop()
        spiralFinishTimer.stop()
        waveFinishTimer.stop()

        brushLayer.visible = false
        fallingTileLayer.visible = false
        spiralLayer.visible = false
        waveLayer.visible = false
    }

    // ============================================================
    // FINISH TRANSITION
    // ============================================================

    function finishTransition(): void {
        backImage.source =
            requestedSource

        frontImage.opacity = 0
        frontImage.scale = 1

        frontImage.x = 0
        frontImage.y = 0

        frontImage.source = ""

        brushLayer.visible = false
        fallingTileLayer.visible = false
        spiralLayer.visible = false
        waveLayer.visible = false

        updatesEnabled = false
    }

    // ============================================================
    // APPLY WALLPAPER
    // ============================================================

    function applyRequestedWallpaper(): void {
        if (
            !requestedSource
            || requestedSource.toString() === ""
        ) {
            return
        }

        // --------------------------------------------------------
        // FIRST LOAD
        // --------------------------------------------------------
        //
        // Friss Quickshell/session induláskor nincs szükség
        // transitionre.
        //
        // Azonnal a backImage-re tesszük a képet.
        // --------------------------------------------------------

        if (
            !backImage.source
            || backImage.source.toString() === ""
        ) {
            stopAllEffects()

            transitionPending = false
            initialWallpaperPending = true

            // FONTOS:
            // az ablaknak frissítenie kell addig,
            // amíg az aszinkron Image ténylegesen betölt.
            updatesEnabled = true

            backImage.source =
                requestedSource

            frontImage.source =
                ""

            frontImage.opacity =
                0

            frontImage.scale =
                1

            frontImage.x =
                0

            frontImage.y =
                0

            return
        }

        // --------------------------------------------------------
        // SAME WALLPAPER
        // --------------------------------------------------------

        if (
            backImage.source.toString()
            === requestedSource.toString()
        ) {
            return
        }

        // --------------------------------------------------------
        // NORMAL WALLPAPER CHANGE
        // --------------------------------------------------------

        stopAllEffects()

        transitionPending =
            true

        updatesEnabled =
            true

        frontImage.source =
            requestedSource

        if (
            frontImage.status
            === Image.Ready
        ) {
            startTransition()
        }
    }

    // ============================================================
    // WALLPAPER CHANGE
    // ============================================================

    onRequestedSourceChanged: {
        applyRequestedWallpaper()
    }

    // ============================================================
    // INITIAL SURFACE LOAD
    // ============================================================
    //
    // Ez hiányzott eddig.
    //
    // Ha a WallpaperManager már azelőtt megadta
    // a requestedSource értékét, hogy ez a surface
    // teljesen elkészült volna, nem várunk egy újabb
    // sourceChanged eseményre.
    //
    // A surface létrejöttekor explicit alkalmazzuk
    // a már meglévő requestedSource-ot.
    // ============================================================

    Component.onCompleted: {
        applyRequestedWallpaper()
    }

    Timer {
        id: initialFreezeTimer

        interval: 80
        repeat: false

        onTriggered: {
            if (
                !root.transitionPending
                && backImage.status === Image.Ready
            ) {
                root.updatesEnabled = false
            }
        }
    }

    // ============================================================
    // FADE / ZOOM
    // ============================================================

    ParallelAnimation {
        id: normalTransition

        NumberAnimation {
            target: frontImage
            property: "opacity"

            to: 1

            duration: 1750

            easing.type:
                Easing.InOutCubic
        }

        NumberAnimation {
            target: frontImage
            property: "scale"

            to: 1

            duration: 1900

            easing.type:
                Easing.OutCubic
        }

        onFinished:
            root.finishTransition()
    }

    // ============================================================
    // HORIZONTAL SLIDE
    // DECAYING PING-PONG BOUNCE
    // ============================================================

    SequentialAnimation {
        id: horizontalSlideTransition

        // Nagy becsúszás majdnem a véghelyzetig.
        NumberAnimation {
            target: frontImage

            property: "x"

            to:
                root.slideDirectionX * 34

            duration: 1850

            easing.type:
                Easing.OutCubic
        }

        // pam
        NumberAnimation {
            target: frontImage

            property: "x"

            to:
                root.slideDirectionX * -20

            duration: 150

            easing.type:
                Easing.InOutQuad
        }

        // pam
        NumberAnimation {
            target: frontImage

            property: "x"

            to:
                root.slideDirectionX * 13

            duration: 125

            easing.type:
                Easing.InOutQuad
        }

        // pam
        NumberAnimation {
            target: frontImage

            property: "x"

            to:
                root.slideDirectionX * -8

            duration: 105

            easing.type:
                Easing.InOutQuad
        }

        // pam
        NumberAnimation {
            target: frontImage

            property: "x"

            to:
                root.slideDirectionX * 5

            duration: 90

            easing.type:
                Easing.InOutQuad
        }

        // pam
        NumberAnimation {
            target: frontImage

            property: "x"

            to:
                root.slideDirectionX * -3

            duration: 75

            easing.type:
                Easing.InOutQuad
        }

        // pam
        NumberAnimation {
            target: frontImage

            property: "x"

            to:
                root.slideDirectionX * 1.5

            duration: 62

            easing.type:
                Easing.InOutQuad
        }

        // p
        NumberAnimation {
            target: frontImage

            property: "x"

            to: 0

            duration: 55

            easing.type:
                Easing.OutQuad
        }

        onFinished:
            root.finishTransition()
    }

    // ============================================================
    // VERTICAL SLIDE
    // DECAYING PING-PONG BOUNCE
    // ============================================================

    SequentialAnimation {
        id: verticalSlideTransition

        // Nagy becsúszás majdnem a véghelyzetig.
        NumberAnimation {
            target: frontImage

            property: "y"

            to:
                root.slideDirectionY * 30

            duration: 1850

            easing.type:
                Easing.OutCubic
        }

        // pam
        NumberAnimation {
            target: frontImage

            property: "y"

            to:
                root.slideDirectionY * -18

            duration: 150

            easing.type:
                Easing.InOutQuad
        }

        // pam
        NumberAnimation {
            target: frontImage

            property: "y"

            to:
                root.slideDirectionY * 11

            duration: 125

            easing.type:
                Easing.InOutQuad
        }

        // pam
        NumberAnimation {
            target: frontImage

            property: "y"

            to:
                root.slideDirectionY * -7

            duration: 105

            easing.type:
                Easing.InOutQuad
        }

        // pam
        NumberAnimation {
            target: frontImage

            property: "y"

            to:
                root.slideDirectionY * 4

            duration: 90

            easing.type:
                Easing.InOutQuad
        }

        // pam
        NumberAnimation {
            target: frontImage

            property: "y"

            to:
                root.slideDirectionY * -2.5

            duration: 75

            easing.type:
                Easing.InOutQuad
        }

        // pam
        NumberAnimation {
            target: frontImage

            property: "y"

            to:
                root.slideDirectionY * 1.2

            duration: 62

            easing.type:
                Easing.InOutQuad
        }

        NumberAnimation {
            target: frontImage

            property: "y"

            to: 0

            duration: 55

            easing.type:
                Easing.OutQuad
        }

        onFinished:
            root.finishTransition()
    }

    // ============================================================
    // BRUSH EFFECT
    // ============================================================

    function startBrushTransition(): void {
        brushMode =
            Math.floor(
                Math.random() * 4
            )

        brushLayer.visible = true

        for (
            let i = 0;
            i < brushRepeater.count;
            ++i
        ) {
            const strip =
                brushRepeater.itemAt(i)

            if (strip)
                strip.startBrush()
        }

        brushFinishTimer.restart()
    }

    Item {
        id: brushLayer

        anchors.fill: parent

        visible: false
        clip: true

        Repeater {
            id: brushRepeater

            model:
                root.brushStripCount

            delegate: Item {
                id: stripRoot

                required property int index

                readonly property real stripHeight:
                    brushLayer.height
                    / root.brushStripCount

                readonly property bool fromRight:
                    root.brushMode === 1
                    || root.brushMode === 3

                readonly property bool bottomUp:
                    root.brushMode === 2
                    || root.brushMode === 3

                readonly property int orderedIndex:
                    bottomUp
                    ? root.brushStripCount
                      - 1
                      - index
                    : index

                property real reveal: 0

                x: 0

                y:
                    index
                    * stripHeight

                width:
                    brushLayer.width

                height:
                    stripHeight + 2

                clip: true

                function startBrush(): void {
                    brushAnimation.stop()

                    reveal = 0

                    brushAnimation.restart()
                }

                Item {
                    id: revealClip

                    height:
                        parent.height

                    width:
                        parent.width
                        * stripRoot.reveal

                    x:
                        stripRoot.fromRight
                        ? parent.width - width
                        : 0

                    clip: true

                    Image {
                        width:
                            brushLayer.width

                        height:
                            brushLayer.height

                        x:
                            -revealClip.x

                        y:
                            -stripRoot.y

                        source:
                            root.requestedSource

                        fillMode:
                            Image.PreserveAspectCrop

                        asynchronous: false
                        cache: true
                        smooth: true
                        mipmap: true
                    }
                }

                SequentialAnimation {
                    id: brushAnimation

                    PauseAnimation {
                        duration:
                            stripRoot.orderedIndex
                            * 52
                            +
                            (stripRoot.index % 4)
                            * 28
                    }

                    NumberAnimation {
                        target:
                            stripRoot

                        property:
                            "reveal"

                        from: 0
                        to: 1

                        duration: 1450

                        easing.type:
                            Easing.InOutCubic
                    }
                }
            }
        }
    }

    Timer {
        id: brushFinishTimer

        interval: 3000

        repeat: false

        onTriggered:
            root.finishTransition()
    }

    // ============================================================
    // FALLING TILES
    // ============================================================

    function startFallingTiles(): void {
        fallingTileLayer.visible = true

        for (
            let i = 0;
            i < fallingTileRepeater.count;
            ++i
        ) {
            const tile =
                fallingTileRepeater.itemAt(i)

            if (tile)
                tile.startTile()
        }

        tileFinishTimer.restart()
    }

    Item {
        id: fallingTileLayer

        anchors.fill: parent

        visible: false
        clip: true

        Repeater {
            id: fallingTileRepeater

            model:
                root.tileCount

            delegate: Item {
                id: fallingTile

                required property int index

                readonly property int column:
                    index % root.tileColumns

                readonly property int row:
                    Math.floor(
                        index / root.tileColumns
                    )

                readonly property real tileWidth:
                    fallingTileLayer.width
                    / root.tileColumns

                readonly property real tileHeight:
                    fallingTileLayer.height
                    / root.tileRows

                property real dropOffset: 0
                property real tileOpacity: 0
                property real tileRotation: 0

                x:
                    column * tileWidth

                y:
                    row * tileHeight
                    + dropOffset

                width:
                    tileWidth + 1

                height:
                    tileHeight + 1

                opacity:
                    tileOpacity

                rotation:
                    tileRotation

                clip: true

                transformOrigin:
                    Item.Center

                function startTile(): void {
                    tileAnimation.stop()

                    dropOffset =
                        -fallingTileLayer.height
                        - row * 55
                        - (column % 3) * 40

                    tileOpacity = 0

                    tileRotation =
                        column % 2 === 0
                        ? -3.5
                        : 3.5

                    tileAnimation.restart()
                }

                Image {
                    width:
                        fallingTileLayer.width

                    height:
                        fallingTileLayer.height

                    x:
                        -fallingTile.column
                        * fallingTile.tileWidth

                    y:
                        -fallingTile.row
                        * fallingTile.tileHeight

                    source:
                        root.requestedSource

                    fillMode:
                        Image.PreserveAspectCrop

                    asynchronous: false
                    cache: true
                    smooth: true
                    mipmap: true
                }

                SequentialAnimation {
                    id: tileAnimation

                    PauseAnimation {
                        duration:
                            fallingTile.column * 60
                            +
                            fallingTile.row * 85
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target:
                                fallingTile

                            property:
                                "dropOffset"

                            to: 0

                            duration: 1550

                            easing.type:
                                Easing.OutCubic
                        }

                        NumberAnimation {
                            target:
                                fallingTile

                            property:
                                "tileOpacity"

                            to: 1

                            duration: 700

                            easing.type:
                                Easing.OutCubic
                        }

                        NumberAnimation {
                            target:
                                fallingTile

                            property:
                                "tileRotation"

                            to: 0

                            duration: 1500

                            easing.type:
                                Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: tileFinishTimer

        interval: 2850

        repeat: false

        onTriggered:
            root.finishTransition()
    }

    // ============================================================
    // SOFT SPIRAL
    // ============================================================

    function startSpiralTransition(): void {
        spiralLayer.visible = true

        for (
            let i = 0;
            i < spiralRepeater.count;
            ++i
        ) {
            const tile =
                spiralRepeater.itemAt(i)

            if (tile)
                tile.startSpiral()
        }

        spiralFinishTimer.restart()
    }

    Item {
        id: spiralLayer

        anchors.fill: parent

        visible: false
        clip: true

        Repeater {
            id: spiralRepeater

            model:
                root.tileCount

            delegate: Item {
                id: spiralTile

                required property int index

                readonly property int column:
                    index % root.tileColumns

                readonly property int row:
                    Math.floor(
                        index / root.tileColumns
                    )

                readonly property real tileWidth:
                    spiralLayer.width
                    / root.tileColumns

                readonly property real tileHeight:
                    spiralLayer.height
                    / root.tileRows

                readonly property real centerColumn:
                    (root.tileColumns - 1) / 2

                readonly property real centerRow:
                    (root.tileRows - 1) / 2

                readonly property real dx:
                    column - centerColumn

                readonly property real dy:
                    row - centerRow

                readonly property real radiusDistance:
                    Math.sqrt(
                        dx * dx
                        + dy * dy
                    )

                readonly property real angle:
                    Math.atan2(
                        dy,
                        dx
                    )

                readonly property real normalizedAngle:
                    angle < 0
                    ? angle + Math.PI * 2
                    : angle

                property real tileOpacity: 0
                property real tileScale: 0.88
                property real tileRotation: 0

                x:
                    column * tileWidth

                y:
                    row * tileHeight

                width:
                    tileWidth + 1

                height:
                    tileHeight + 1

                opacity:
                    tileOpacity

                scale:
                    tileScale

                rotation:
                    tileRotation

                clip: true

                transformOrigin:
                    Item.Center

                function startSpiral(): void {
                    spiralAnimation.stop()

                    tileOpacity = 0
                    tileScale = 0.88

                    tileRotation =
                        normalizedAngle
                        * 180
                        / Math.PI
                        * 0.035

                    spiralAnimation.restart()
                }

                Image {
                    width:
                        spiralLayer.width

                    height:
                        spiralLayer.height

                    x:
                        -spiralTile.column
                        * spiralTile.tileWidth

                    y:
                        -spiralTile.row
                        * spiralTile.tileHeight

                    source:
                        root.requestedSource

                    fillMode:
                        Image.PreserveAspectCrop

                    asynchronous: false
                    cache: true
                    smooth: true
                    mipmap: true
                }

                SequentialAnimation {
                    id: spiralAnimation

                    PauseAnimation {
                        duration:
                            spiralTile
                                .normalizedAngle
                            * 130
                            +
                            spiralTile
                                .radiusDistance
                            * 75
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target:
                                spiralTile

                            property:
                                "tileOpacity"

                            to: 1

                            duration: 950

                            easing.type:
                                Easing.InOutCubic
                        }

                        NumberAnimation {
                            target:
                                spiralTile

                            property:
                                "tileScale"

                            to: 1

                            duration: 1250

                            easing.type:
                                Easing.OutCubic
                        }

                        NumberAnimation {
                            target:
                                spiralTile

                            property:
                                "tileRotation"

                            to: 0

                            duration: 1250

                            easing.type:
                                Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: spiralFinishTimer

        interval: 3000

        repeat: false

        onTriggered:
            root.finishTransition()
    }

    // ============================================================
    // SILK WAVE
    // ============================================================

    function startWaveTransition(): void {
        waveLayer.visible = true

        for (
            let i = 0;
            i < waveRepeater.count;
            ++i
        ) {
            const strip =
                waveRepeater.itemAt(i)

            if (strip)
                strip.startWave()
        }

        waveFinishTimer.restart()
    }

    Item {
        id: waveLayer

        anchors.fill: parent

        visible: false
        clip: true

        Repeater {
            id: waveRepeater

            model:
                root.waveStripCount

            delegate: Item {
                id: waveStrip

                required property int index

                readonly property real stripWidth:
                    waveLayer.width
                    / root.waveStripCount

                property real waveOffset: 0
                property real waveOpacity: 0

                x:
                    index * stripWidth

                y:
                    waveOffset

                width:
                    stripWidth + 2

                height:
                    waveLayer.height

                opacity:
                    waveOpacity

                clip: true

                function startWave(): void {
                    waveAnimation.stop()

                    waveOpacity = 0

                    waveOffset =
                        Math.sin(
                            index * 0.72
                        )
                        * waveLayer.height
                        * 0.16

                    waveAnimation.restart()
                }

                Image {
                    width:
                        waveLayer.width

                    height:
                        waveLayer.height

                    x:
                        -waveStrip.index
                        * waveStrip.stripWidth

                    y:
                        -waveStrip.waveOffset

                    source:
                        root.requestedSource

                    fillMode:
                        Image.PreserveAspectCrop

                    asynchronous: false
                    cache: true
                    smooth: true
                    mipmap: true
                }

                SequentialAnimation {
                    id: waveAnimation

                    PauseAnimation {
                        duration:
                            waveStrip.index
                            * 32
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target:
                                waveStrip

                            property:
                                "waveOffset"

                            to: 0

                            duration: 1550

                            easing.type:
                                Easing.InOutCubic
                        }

                        NumberAnimation {
                            target:
                                waveStrip

                            property:
                                "waveOpacity"

                            to: 1

                            duration: 1050

                            easing.type:
                                Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: waveFinishTimer

        interval: 2700

        repeat: false

        onTriggered:
            root.finishTransition()
    }
}