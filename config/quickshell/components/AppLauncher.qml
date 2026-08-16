import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: launcherRoot

    property bool isOpen: false
    property bool windowVisible: false

    property real shellProgress: 0.0
    property real bodyProgress: 0.0

    property real borderProgress: 0.0

    readonly property int borderAnimationDuration: 520

    property var pendingLaunchApp: null

    onBorderProgressChanged: {
        if (borderCanvas)
            borderCanvas.requestPaint()
    }

    function normalize(value) {
        return (value || "")
            .toString()
            .toLowerCase()
    }

    function scoreApp(app, query) {
        if (query === "")
            return 1

        const name =
            normalize(app.name)

        const genericName =
            normalize(app.genericName)

        const comment =
            normalize(app.comment)

        const id =
            normalize(app.id)

        const keywords =
            app.keywords
            ? app.keywords.join(" ").toLowerCase()
            : ""

        let score = 0

        if (name === query)
            score += 1000

        else if (name.startsWith(query))
            score += 700

        else if (name.includes(query))
            score += 500

        if (genericName.startsWith(query))
            score += 220

        else if (genericName.includes(query))
            score += 150

        if (keywords.includes(query))
            score += 120

        if (comment.includes(query))
            score += 70

        if (id.includes(query))
            score += 40

        return score
    }

    function isLauncherNoise(app) {
        const name =
            normalize(app.name)

        const id =
            normalize(app.id)

        const genericName =
            normalize(app.genericName)

        const noise = [
            "avahi",
            "zeroconf",
            "vnc-kiszolgáló",
            "ssh-kiszolgáló",
            "xfce névjegye",
            "xfce about",
            "thunar beállítás",
            "thunar settings",
            "csoportos átnevezés",
            "bulk rename",
            "thunar-bulk-rename",
            "thunar-volman",
            "mime type editor",
            "mimetype editor",
            "preferred applications",
            "session and startup"
        ]

        for (const token of noise) {
            if (
                name.includes(token)
                || id.includes(token)
                || genericName.includes(token)
            ) {
                return true
            }
        }

        return (
            app.noDisplay === true
            || app.hidden === true
        )
    }

    function preferredRank(app) {
        const haystack =
            normalize(
                app.id
                + " "
                + app.name
            )

        const preferred = [
            "firefox",
            "chromium",
            "brave",
            "ghostty",
            "thunar",
            "blender",
            "steam",
            "discord",
            "transmission",
            "pavucontrol"
        ]

        for (
            let i = 0;
            i < preferred.length;
            ++i
        ) {
            if (
                haystack.includes(
                    preferred[i]
                )
            ) {
                return i
            }
        }

        return 1000
    }

    function filteredApplications(queryText) {
        const query =
            normalize(queryText).trim()

        const apps =
            [
                ...DesktopEntries
                    .applications
                    .values
            ]
            .filter(
                app =>
                    !isLauncherNoise(app)
            )

        if (query === "") {
            return apps.sort(
                (a, b) => {
                    const rankA =
                        preferredRank(a)

                    const rankB =
                        preferredRank(b)

                    if (rankA !== rankB)
                        return rankA - rankB

                    return a.name.localeCompare(
                        b.name
                    )
                }
            )
        }

        return apps
            .map(
                app => ({
                    app: app,
                    score:
                        scoreApp(
                            app,
                            query
                        )
                })
            )
            .filter(
                result =>
                    result.score > 0
            )
            .sort(
                (a, b) => {
                    if (
                        b.score
                        !== a.score
                    ) {
                        return (
                            b.score
                            - a.score
                        )
                    }

                    return (
                        a.app.name
                            .localeCompare(
                                b.app.name
                            )
                    )
                }
            )
            .map(
                result =>
                    result.app
            )
    }

    function open() {
        if (isOpen)
            return

        borderCloseDelay.stop()
        shellCloseDelay.stop()
        windowHideDelay.stop()

        pendingLaunchApp = null

        windowVisible = true
        isOpen = true

        borderProgress = 0.0

        shellProgress = 1.0

        bodyOpenDelay.restart()

        borderOpenDelay.restart()

        focusDelay.restart()
    }

    function close() {
        if (!windowVisible)
            return

        isOpen = false

        bodyOpenDelay.stop()
        borderOpenDelay.stop()
        focusDelay.stop()

        borderProgress = 0.0

        borderCloseDelay.restart()
    }

    function toggle() {
        if (isOpen)
            close()
        else
            open()
    }

    function moveSelection(delta) {
        if (resultList.count <= 0)
            return

        resultList.currentIndex =
            Math.max(
                0,
                Math.min(
                    resultList.currentIndex
                    + delta,

                    resultList.count - 1
                )
            )

        resultList.positionViewAtIndex(
            resultList.currentIndex,
            ListView.Contain
        )
    }

    function launchSelected() {
        if (
            resultList.count <= 0
            || resultList.currentIndex < 0
        ) {
            return
        }

        const app =
            resultModel.values[
                resultList.currentIndex
            ]

        if (!app)
            return

        pendingLaunchApp = app

        close()
    }

    IpcHandler {
        target:
            "launcher"

        function toggle(): void {
            launcherRoot.toggle()
        }

        function open(): void {
            launcherRoot.open()
        }

        function close(): void {
            launcherRoot.close()
        }
    }

    Timer {
        id: bodyOpenDelay

        interval: 235
        repeat: false

        onTriggered:
            launcherRoot.bodyProgress =
                1.0
    }

    Timer {
        id: borderOpenDelay

        interval: 510
        repeat: false

        onTriggered:
            launcherRoot.borderProgress =
                1.0
    }

    Timer {
        id: focusDelay

        interval: 260
        repeat: false

        onTriggered: {
            searchInput.forceActiveFocus()
            searchInput.selectAll()
        }
    }

    Timer {
        id: borderCloseDelay

        interval:
            launcherRoot.borderAnimationDuration

        repeat: false

        onTriggered: {
            launcherRoot.bodyProgress =
                0.0

            shellCloseDelay.restart()
        }
    }

    Timer {
        id: shellCloseDelay

        interval: 250
        repeat: false

        onTriggered: {
            launcherRoot.shellProgress =
                0.0

            windowHideDelay.restart()
        }
    }

    Timer {
        id: windowHideDelay

        interval: 310
        repeat: false

        onTriggered: {
            launcherRoot.windowVisible =
                false

            searchInput.text =
                ""

            resultList.currentIndex =
                0

            launcherRoot.shellProgress =
                0.0

            launcherRoot.bodyProgress =
                0.0

            launcherRoot.borderProgress =
                0.0

            if (launcherRoot.pendingLaunchApp) {
                const app =
                    launcherRoot.pendingLaunchApp

                launcherRoot.pendingLaunchApp =
                    null

                app.execute()
            }
        }
    }

    Behavior on shellProgress {
        NumberAnimation {
            duration: 290

            easing.type:
                Easing.InOutCubic
        }
    }

    Behavior on bodyProgress {
        NumberAnimation {
            duration: 250

            easing.type:
                Easing.InOutCubic
        }
    }

    Behavior on borderProgress {
        NumberAnimation {
            duration:
                launcherRoot.borderAnimationDuration

            easing.type:
                Easing.InOutCubic
        }
    }

    PanelWindow {
        id: launcherWindow

        visible:
            launcherRoot.windowVisible

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color:
            "transparent"

        exclusionMode:
            ExclusionMode.Ignore

        focusable:
            true

        aboveWindows:
            true

        WlrLayershell.namespace:
            "hypr-lab-launcher"

        WlrLayershell.layer:
            WlrLayer.Overlay

        WlrLayershell.keyboardFocus:
            WlrKeyboardFocus.Exclusive

        Item {
            anchors.fill:
                parent

            MouseArea {
                anchors.fill:
                    parent

                onClicked:
                    launcherRoot.close()
            }
        }

        Item {
            id: launcherContainer

            anchors.horizontalCenter:
                parent.horizontalCenter

            anchors.bottom:
                parent.bottom

            anchors.bottomMargin:
                54

            width:
                700

            height:
                68
                +
                (
                    548
                    * launcherRoot.bodyProgress
                )

            opacity:
                launcherRoot.shellProgress

            scale:
                0.965
                +
                (
                    0.035
                    * launcherRoot.shellProgress
                )

            transformOrigin:
                Item.Bottom

            Behavior on height {
                NumberAnimation {
                    duration: 250

                    easing.type:
                        Easing.InOutCubic
                }
            }

            Rectangle {
                id: launcherCard

                anchors.fill:
                    parent

                radius:
                    34
                    -
                    (
                        10
                        * launcherRoot.bodyProgress
                    )

                color:
                    Qt.rgba(
                        10 / 255,
                        14 / 255,
                        20 / 255,
                        0.80
                    )

                border.width:
                    0

                antialiasing:
                    true

                clip:
                    true

                Behavior on radius {
                    NumberAnimation {
                        duration: 250

                        easing.type:
                            Easing.InOutCubic
                    }
                }

                MouseArea {
                    anchors.fill:
                        parent

                    onClicked:
                        function(mouse) {
                            mouse.accepted =
                                true
                        }
                }

                Rectangle {
                    id: searchArea

                    anchors.top:
                        parent.top

                    anchors.topMargin:
                        2

                    anchors.left:
                        parent.left

                    anchors.leftMargin:
                        2

                    anchors.right:
                        parent.right

                    anchors.rightMargin:
                        2

                    height:
                        66

                    radius:
                        Math.max(
                            0,
                            launcherCard.radius
                            - 2
                        )

                    color:
                        Qt.rgba(
                            13 / 255,
                            19 / 255,
                            27 / 255,
                            0.76
                        )

                    antialiasing:
                        true

                    Rectangle {
                        anchors.left:
                            parent.left

                        anchors.right:
                            parent.right

                        anchors.bottom:
                            parent.bottom

                        height:
                            Math.min(
                                launcherCard.radius,
                                parent.height / 2
                            )

                        color:
                            parent.color
                    }

                    Rectangle {
                        anchors.left:
                            parent.left

                        anchors.leftMargin:
                            20

                        anchors.verticalCenter:
                            parent.verticalCenter

                        width:
                            36

                        height:
                            36

                        radius:
                            18

                        color:
                            Qt.rgba(
                                55 / 255,
                                245 / 255,
                                235 / 255,
                                0.08
                            )

                        Text {
                            anchors.centerIn:
                                parent

                            text:
                                "⌕"

                            color:
                                Qt.rgba(
                                    55 / 255,
                                    245 / 255,
                                    235 / 255,
                                    0.95
                                )

                            font.family:
                                "Inter"

                            font.pixelSize:
                                22
                        }
                    }

                    TextInput {
                        id: searchInput

                        anchors.left:
                            parent.left

                        anchors.leftMargin:
                            70

                        anchors.right:
                            parent.right

                        anchors.rightMargin:
                            24

                        anchors.verticalCenter:
                            parent.verticalCenter

                        color:
                            "#efffff"

                        selectionColor:
                            Qt.rgba(
                                55 / 255,
                                245 / 255,
                                235 / 255,
                                0.30
                            )

                        selectedTextColor:
                            "#ffffff"

                        font.family:
                            "Inter"

                        font.pixelSize:
                            16

                        font.weight:
                            Font.Medium

                        clip:
                            true

                        onTextChanged: {
                            resultList.currentIndex =
                                0

                            resultList
                                .positionViewAtBeginning()
                        }

                        Keys.onPressed:
                            event => {
                                if (
                                    event.key
                                    === Qt.Key_Down
                                ) {
                                    launcherRoot
                                        .moveSelection(1)

                                    event.accepted =
                                        true
                                } else if (
                                    event.key
                                    === Qt.Key_Up
                                ) {
                                    launcherRoot
                                        .moveSelection(-1)

                                    event.accepted =
                                        true
                                } else if (
                                    event.key
                                    === Qt.Key_Return
                                    ||
                                    event.key
                                    === Qt.Key_Enter
                                ) {
                                    launcherRoot
                                        .launchSelected()

                                    event.accepted =
                                        true
                                } else if (
                                    event.key
                                    === Qt.Key_Escape
                                ) {
                                    launcherRoot
                                        .close()

                                    event.accepted =
                                        true
                                }
                            }
                    }

                    Text {
                        anchors.left:
                            searchInput.left

                        anchors.verticalCenter:
                            searchInput.verticalCenter

                        visible:
                            searchInput.text.length
                            === 0

                        text:
                            "Search applications..."

                        color:
                            Qt.rgba(
                                200 / 255,
                                220 / 255,
                                225 / 255,
                                0.38
                            )

                        font.family:
                            "Inter"

                        font.pixelSize:
                            16
                    }

                    Rectangle {
                        anchors.left:
                            parent.left

                        anchors.right:
                            parent.right

                        anchors.bottom:
                            parent.bottom

                        height:
                            1

                        color:
                            Qt.rgba(
                                55 / 255,
                                245 / 255,
                                235 / 255,

                                0.22
                                * launcherRoot.bodyProgress
                            )
                    }
                }

                Item {
                    id: resultsArea

                    anchors.top:
                        searchArea.bottom

                    anchors.left:
                        parent.left

                    anchors.right:
                        parent.right

                    anchors.bottom:
                        parent.bottom

                    opacity:
                        launcherRoot.bodyProgress

                    y:
                        12
                        *
                        (
                            1.0
                            - launcherRoot.bodyProgress
                        )

                    ScriptModel {
                        id: resultModel

                        values:
                            launcherRoot
                                .filteredApplications(
                                    searchInput.text
                                )
                    }

                    ListView {
                        id: resultList

                        anchors.fill:
                            parent

                        anchors.margins:
                            14

                        spacing:
                            7

                        clip:
                            true

                        model:
                            resultModel

                        currentIndex:
                            0

                        boundsBehavior:
                            Flickable.StopAtBounds

                        interactive:
                            contentHeight > height

                        delegate:
                            AppLauncherItem {
                                required property var modelData

                                required property int index

                                app:
                                    modelData

                                itemIndex:
                                    index

                                selected:
                                    ListView.isCurrentItem

                                onActivated: {
                                    resultList.currentIndex =
                                        index

                                    launcherRoot
                                        .launchSelected()
                                }
                            }
                    }

                    Column {
                        anchors.centerIn:
                            parent

                        spacing:
                            6

                        visible:
                            resultList.count === 0

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text:
                                "No applications found"

                            color:
                                Qt.rgba(
                                    225 / 255,
                                    235 / 255,
                                    238 / 255,
                                    0.64
                                )

                            font.family:
                                "Inter"

                            font.pixelSize:
                                14

                            font.bold:
                                true
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text:
                                "Try a different search"

                            color:
                                Qt.rgba(
                                    190 / 255,
                                    205 / 255,
                                    210 / 255,
                                    0.38
                                )

                            font.family:
                                "Inter"

                            font.pixelSize:
                                11
                        }
                    }
                }
            }

            Canvas {
                id: borderCanvas

                anchors.fill:
                    launcherCard

                z:
                    100

                antialiasing:
                    true

                enabled:
                    false

                onWidthChanged:
                    requestPaint()

                onHeightChanged:
                    requestPaint()

                function drawRoundedProgress(
                    ctx,
                    x,
                    y,
                    w,
                    h,
                    radius,
                    progress
                ) {
                    if (progress <= 0)
                        return

                    const r =
                        Math.min(
                            radius,
                            w / 2,
                            h / 2
                        )

                    const topLength =
                        w - 2 * r

                    const sideLength =
                        h - 2 * r

                    const arcLength =
                        Math.PI * r / 2

                    const perimeter =
                        2 * topLength
                        + 2 * sideLength
                        + 4 * arcLength

                    let remaining =
                        perimeter
                        * Math.min(
                            1,
                            progress
                        )

                    ctx.beginPath()

                    ctx.moveTo(
                        x + r,
                        y
                    )

                    if (remaining <= topLength) {
                        ctx.lineTo(
                            x + r + remaining,
                            y
                        )

                        ctx.stroke()
                        return
                    }

                    ctx.lineTo(
                        x + w - r,
                        y
                    )

                    remaining -=
                        topLength

                    if (remaining <= arcLength) {
                        const angle =
                            -Math.PI / 2
                            +
                            (
                                remaining
                                / arcLength
                            )
                            * Math.PI / 2

                        ctx.arc(
                            x + w - r,
                            y + r,
                            r,
                            -Math.PI / 2,
                            angle,
                            false
                        )

                        ctx.stroke()
                        return
                    }

                    ctx.arc(
                        x + w - r,
                        y + r,
                        r,
                        -Math.PI / 2,
                        0,
                        false
                    )

                    remaining -=
                        arcLength

                    if (remaining <= sideLength) {
                        ctx.lineTo(
                            x + w,
                            y + r + remaining
                        )

                        ctx.stroke()
                        return
                    }

                    ctx.lineTo(
                        x + w,
                        y + h - r
                    )

                    remaining -=
                        sideLength

                    if (remaining <= arcLength) {
                        const angle =
                            (
                                remaining
                                / arcLength
                            )
                            * Math.PI / 2

                        ctx.arc(
                            x + w - r,
                            y + h - r,
                            r,
                            0,
                            angle,
                            false
                        )

                        ctx.stroke()
                        return
                    }

                    ctx.arc(
                        x + w - r,
                        y + h - r,
                        r,
                        0,
                        Math.PI / 2,
                        false
                    )

                    remaining -=
                        arcLength

                    if (remaining <= topLength) {
                        ctx.lineTo(
                            x + w - r - remaining,
                            y + h
                        )

                        ctx.stroke()
                        return
                    }

                    ctx.lineTo(
                        x + r,
                        y + h
                    )

                    remaining -=
                        topLength

                    if (remaining <= arcLength) {
                        const angle =
                            Math.PI / 2
                            +
                            (
                                remaining
                                / arcLength
                            )
                            * Math.PI / 2

                        ctx.arc(
                            x + r,
                            y + h - r,
                            r,
                            Math.PI / 2,
                            angle,
                            false
                        )

                        ctx.stroke()
                        return
                    }

                    ctx.arc(
                        x + r,
                        y + h - r,
                        r,
                        Math.PI / 2,
                        Math.PI,
                        false
                    )

                    remaining -=
                        arcLength

                    if (remaining <= sideLength) {
                        ctx.lineTo(
                            x,
                            y + h - r - remaining
                        )

                        ctx.stroke()
                        return
                    }

                    ctx.lineTo(
                        x,
                        y + r
                    )

                    remaining -=
                        sideLength

                    if (remaining <= arcLength) {
                        const angle =
                            Math.PI
                            +
                            (
                                remaining
                                / arcLength
                            )
                            * Math.PI / 2

                        ctx.arc(
                            x + r,
                            y + r,
                            r,
                            Math.PI,
                            angle,
                            false
                        )

                        ctx.stroke()
                        return
                    }

                    ctx.arc(
                        x + r,
                        y + r,
                        r,
                        Math.PI,
                        Math.PI * 1.5,
                        false
                    )

                    ctx.stroke()
                }

                onPaint: {
                    const ctx =
                        getContext("2d")

                    ctx.reset()

                    if (
                        launcherRoot.borderProgress
                        <= 0
                    ) {
                        return
                    }

                    const inset =
                        2

                    const radius =
                        Math.max(
                            0,
                            launcherCard.radius
                            - inset
                        )

                    ctx.lineWidth =
                        5

                    ctx.strokeStyle =
                        "rgba(55, 245, 235, 0.16)"

                    drawRoundedProgress(
                        ctx,
                        inset,
                        inset,
                        width - inset * 2,
                        height - inset * 2,
                        radius,
                        launcherRoot.borderProgress
                    )

                    ctx.lineWidth =
                        2

                    ctx.strokeStyle =
                        "rgba(55, 245, 235, 0.88)"

                    drawRoundedProgress(
                        ctx,
                        inset,
                        inset,
                        width - inset * 2,
                        height - inset * 2,
                        radius,
                        launcherRoot.borderProgress
                    )
                }
            }
        }
    }
}
