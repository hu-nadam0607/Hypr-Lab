import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: launcherRoot

    property bool isOpen: false
    property bool windowVisible: false
    property real reveal: 0.0
    property var pendingLaunchApp: null

    readonly property int launcherWidth: 800
    readonly property int launcherHeight: 585
    readonly property int slant: 36
    readonly property int gridColumns: 4
    readonly property int innerWidth: 672

    // Horizontal center of the slanted parent at a given panel-local Y.
    // The top edge starts `slant` px to the right; the bottom edge ends
    // `slant` px to the left, so the visual center travels left with Y.
    function panelCenterAt(yPos) {
        const t = Math.max(0, Math.min(1, yPos / Math.max(1, launcherHeight)))
        return launcherWidth / 2 + slant / 2 - slant * t
    }

    AdaptiveAccent { id: adaptiveAccent }
    readonly property color accentColor: adaptiveAccent.accentColor

    function normalize(value) {
        return (value || "").toString().toLowerCase()
    }

    function scoreApp(app, query) {
        if (query === "") return 1

        const name = normalize(app.name)
        const genericName = normalize(app.genericName)
        const comment = normalize(app.comment)
        const id = normalize(app.id)
        const keywords = app.keywords ? app.keywords.join(" ").toLowerCase() : ""

        let score = 0
        if (name === query) score += 1000
        else if (name.startsWith(query)) score += 700
        else if (name.includes(query)) score += 500

        if (genericName.startsWith(query)) score += 220
        else if (genericName.includes(query)) score += 150

        if (keywords.includes(query)) score += 120
        if (comment.includes(query)) score += 70
        if (id.includes(query)) score += 40
        return score
    }

    function isLauncherNoise(app) {
        const name = normalize(app.name)
        const id = normalize(app.id)
        const genericName = normalize(app.genericName)
        const noise = [
            "avahi", "zeroconf", "vnc-kiszolgáló", "ssh-kiszolgáló",
            "xfce névjegye", "xfce about", "thunar beállítás", "thunar settings",
            "csoportos átnevezés", "bulk rename", "thunar-bulk-rename",
            "thunar-volman", "mime type editor", "mimetype editor",
            "preferred applications", "session and startup"
        ]

        for (const token of noise) {
            if (name.includes(token) || id.includes(token) || genericName.includes(token))
                return true
        }

        return app.noDisplay === true || app.hidden === true
    }

    function preferredRank(app) {
        const haystack = normalize(app.id + " " + app.name)
        const preferred = [
            "firefox", "chromium", "brave", "ghostty", "thunar",
            "blender", "steam", "discord", "transmission", "pavucontrol"
        ]

        for (let i = 0; i < preferred.length; ++i) {
            if (haystack.includes(preferred[i])) return i
        }
        return 1000
    }

    function filteredApplications(queryText) {
        const query = normalize(queryText).trim()
        const apps = [...DesktopEntries.applications.values].filter(app => !isLauncherNoise(app))

        if (query === "") {
            return apps.sort((a, b) => {
                const rankA = preferredRank(a)
                const rankB = preferredRank(b)
                if (rankA !== rankB) return rankA - rankB
                return a.name.localeCompare(b.name)
            })
        }

        return apps
            .map(app => ({ app: app, score: scoreApp(app, query) }))
            .filter(result => result.score > 0)
            .sort((a, b) => b.score !== a.score ? b.score - a.score : a.app.name.localeCompare(b.app.name))
            .map(result => result.app)
    }

    function open() {
        if (isOpen) return
        hideTimer.stop()
        pendingLaunchApp = null
        windowVisible = true
        isOpen = true
        reveal = 1.0
        focusTimer.restart()
    }

    function close() {
        if (!windowVisible) return
        isOpen = false
        focusTimer.stop()
        reveal = 0.0
        hideTimer.restart()
    }

    function toggle() {
        if (isOpen) close()
        else open()
    }

    function moveSelection(delta) {
        if (resultGrid.count <= 0) return
        resultGrid.currentIndex = Math.max(0, Math.min(resultGrid.currentIndex + delta, resultGrid.count - 1))
        resultGrid.positionViewAtIndex(resultGrid.currentIndex, GridView.Contain)
    }

    function launchSelected() {
        if (resultGrid.count <= 0 || resultGrid.currentIndex < 0) return
        const app = resultModel.values[resultGrid.currentIndex]
        if (!app) return

        // Launch immediately. The close animation runs in parallel and never delays app startup.
        app.execute()
        close()
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcherRoot.toggle() }
        function open(): void { launcherRoot.open() }
        function close(): void { launcherRoot.close() }
    }

    Timer {
        id: focusTimer
        interval: 95
        repeat: false
        onTriggered: {
            searchInput.forceActiveFocus()
            searchInput.selectAll()
        }
    }

    Timer {
        id: hideTimer
        interval: 145
        repeat: false
        onTriggered: {
            launcherRoot.windowVisible = false
            searchInput.text = ""
            resultGrid.currentIndex = 0
        }
    }

    Behavior on reveal {
        NumberAnimation {
            duration: launcherRoot.isOpen ? 165 : 120
            easing.type: launcherRoot.isOpen ? Easing.OutCubic : Easing.InCubic
        }
    }

    PanelWindow {
        id: launcherWindow
        visible: launcherRoot.windowVisible

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        aboveWindows: true

        WlrLayershell.namespace: "hypr-lab-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        MouseArea {
            anchors.fill: parent
            onClicked: launcherRoot.close()
        }

        Item {
            id: launcherContainer

            width: launcherRoot.launcherWidth
            height: launcherRoot.launcherHeight
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 68

            opacity: launcherRoot.reveal
            y: (1.0 - launcherRoot.reveal) * 26
            scale: 0.985 + launcherRoot.reveal * 0.015
            transformOrigin: Item.Bottom

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => mouse.accepted = true
            }

            Canvas {
                id: surfaceCanvas
                anchors.fill: parent
                antialiasing: true

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Connections {
                    target: adaptiveAccent
                    function onAccentColorChanged() { surfaceCanvas.requestPaint() }
                }

                function panelPath(ctx, inset) {
                    const w = width
                    const h = height
                    const s = launcherRoot.slant

                    // Asymmetric, sharp Hypr-Lab geometry. No rounded corners.
                    ctx.beginPath()
                    ctx.moveTo(s + inset, inset)
                    ctx.lineTo(w - inset, inset)
                    ctx.lineTo(w - s - inset, h - inset)
                    ctx.lineTo(inset, h - inset)
                    ctx.closePath()
                }

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    panelPath(ctx, 1)
                    ctx.fillStyle = Qt.rgba(5 / 255, 9 / 255, 14 / 255, 0.56)
                    ctx.fill()

                    const material = ctx.createLinearGradient(0, 0, 0, height)
                    material.addColorStop(0.00, Qt.rgba(1, 1, 1, 0.13))
                    material.addColorStop(0.18, Qt.rgba(1, 1, 1, 0.040))
                    material.addColorStop(0.68, Qt.rgba(0, 0, 0, 0.030))
                    material.addColorStop(1.00, Qt.rgba(0, 0, 0, 0.22))
                    panelPath(ctx, 1)
                    ctx.fillStyle = material
                    ctx.fill()

                    panelPath(ctx, 1)
                    ctx.lineWidth = 2
                    ctx.strokeStyle = Qt.rgba(
                        launcherRoot.accentColor.r,
                        launcherRoot.accentColor.g,
                        launcherRoot.accentColor.b,
                        0.90
                    )
                    ctx.stroke()

                    // Fixed top glass highlight.
                    ctx.beginPath()
                    ctx.moveTo(launcherRoot.slant + 4, 3)
                    ctx.lineTo(width - 7, 3)
                    ctx.lineWidth = 0.7
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.20)
                    ctx.stroke()
                }
            }

            Item {
                id: content
                anchors.fill: parent

                opacity: Math.max(0, Math.min(1, (launcherRoot.reveal - 0.10) / 0.90))
                y: (1.0 - launcherRoot.reveal) * 9

                Item {
                    id: searchBar
                    readonly property real panelY: 28
                    readonly property real centerYInPanel: panelY + height / 2
                    x: launcherRoot.panelCenterAt(centerYInPanel) - width / 2
                    y: panelY
                    width: launcherRoot.innerWidth
                    height: 52

                    // The search field uses the same sharp slant as the parent panel.
                    Canvas {
                        id: searchCanvas
                        anchors.fill: parent
                        antialiasing: true

                        function fieldPath(ctx) {
                            const localSlant = launcherRoot.slant * height / launcherRoot.launcherHeight
                            ctx.beginPath()
                            ctx.moveTo(localSlant, 0)
                            ctx.lineTo(width, 0)
                            ctx.lineTo(width - localSlant, height)
                            ctx.lineTo(0, height)
                            ctx.closePath()
                        }

                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            fieldPath(ctx)
                            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.025)
                            ctx.fill()
                            fieldPath(ctx)
                            ctx.lineWidth = 1
                            ctx.strokeStyle = Qt.rgba(launcherRoot.accentColor.r, launcherRoot.accentColor.g, launcherRoot.accentColor.b, 0.28)
                            ctx.stroke()
                        }

                        Connections {
                            target: adaptiveAccent
                            function onAccentColorChanged() { searchCanvas.requestPaint() }
                        }
                    }

                    Text {
                        id: searchIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 17
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⌕"
                        color: launcherRoot.accentColor
                        font.family: "Inter"
                        font.pixelSize: 21
                    }

                    TextInput {
                        id: searchInput
                        anchors.left: searchIcon.right
                        anchors.leftMargin: 13
                        anchors.right: parent.right
                        anchors.rightMargin: 18
                        anchors.verticalCenter: parent.verticalCenter

                        color: "#f4f6f7"
                        selectionColor: Qt.rgba(launcherRoot.accentColor.r, launcherRoot.accentColor.g, launcherRoot.accentColor.b, 0.30)
                        selectedTextColor: "#ffffff"
                        font.family: "Inter"
                        font.pixelSize: 15
                        font.italic: true
                        clip: true

                        onTextChanged: {
                            resultGrid.currentIndex = 0
                            resultGrid.positionViewAtBeginning()
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Right) {
                                launcherRoot.moveSelection(1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Left) {
                                launcherRoot.moveSelection(-1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down) {
                                launcherRoot.moveSelection(launcherRoot.gridColumns)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                launcherRoot.moveSelection(-launcherRoot.gridColumns)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                launcherRoot.launchSelected()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                launcherRoot.close()
                                event.accepted = true
                            }
                        }
                    }

                    Text {
                        anchors.left: searchInput.left
                        anchors.verticalCenter: searchInput.verticalCenter
                        visible: searchInput.text.length === 0
                        text: "Keresés alkalmazások között..."
                        color: Qt.rgba(0.86, 0.90, 0.92, 0.38)
                        font.family: "Inter"
                        font.pixelSize: 15
                        font.italic: true
                    }
                }

                ScriptModel {
                    id: resultModel
                    values: launcherRoot.filteredApplications(searchInput.text)
                }

                GridView {
                    id: resultGrid
                    readonly property real panelY: searchBar.y + searchBar.height + 17
                    readonly property real panelBottom: footer.y - 12
                    readonly property real centerYInPanel: (panelY + panelBottom) / 2
                    x: launcherRoot.panelCenterAt(centerYInPanel) - width / 2
                    y: panelY
                    width: launcherRoot.innerWidth
                    height: Math.max(1, panelBottom - panelY)

                    // Four columns and four visible rows. Keep the viewport clipped so
                    // scrolling content can never paint over the search field or footer.
                    // Delegate X translation is based on its *visible* Y position, so the
                    // grid keeps tracking the slanted launcher geometry while scrolling.
                    clip: true
                    model: resultModel
                    currentIndex: 0
                    cellWidth: width / launcherRoot.gridColumns
                    cellHeight: 98
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height

                    delegate: AppLauncherItem {
                        required property var modelData
                        required property int index
                        app: modelData
                        itemIndex: index
                        selected: GridView.isCurrentItem
                        accentColor: launcherRoot.accentColor
                        gridCellWidth: resultGrid.cellWidth
                        gridCellHeight: resultGrid.cellHeight
                        gridColumns: launcherRoot.gridColumns
                        panelHeight: launcherRoot.launcherHeight
                        panelSlant: launcherRoot.slant
                        gridTopInPanel: resultGrid.y
                        gridCenterInPanel: resultGrid.centerYInPanel

                        onActivated: {
                            resultGrid.currentIndex = index
                            launcherRoot.launchSelected()
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: resultGrid.count === 0
                        text: "Nincs találat"
                        color: Qt.rgba(0.90, 0.93, 0.94, 0.62)
                        font.family: "Inter"
                        font.pixelSize: 14
                        font.italic: true
                    }
                }

                Item {
                    id: footer
                    readonly property real panelY: launcherRoot.launcherHeight - 26 - height
                    readonly property real centerYInPanel: panelY + height / 2
                    x: launcherRoot.panelCenterAt(centerYInPanel) - width / 2
                    y: panelY
                    width: launcherRoot.innerWidth
                    height: 28

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: 1
                        color: Qt.rgba(launcherRoot.accentColor.r, launcherRoot.accentColor.g, launcherRoot.accentColor.b, 0.20)
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: searchInput.text.length > 0 ? (resultGrid.count + " találat") : "MINDEN"
                        color: launcherRoot.accentColor
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.italic: true
                        font.bold: true
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "↑ ↓ ← →  navigáció    Enter  indítás    Esc  bezárás"
                        color: Qt.rgba(0.86, 0.90, 0.92, 0.38)
                        font.family: "Inter"
                        font.pixelSize: 9
                        font.italic: true
                    }
                }
            }
        }
    }
}
