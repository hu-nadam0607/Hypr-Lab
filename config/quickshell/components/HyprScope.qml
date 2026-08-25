import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Scope {
    id: root

    property int workspaceCount: 10
    property color accentColor: "#68787D"
    property url wallpaperSource: ""

    property int selectedWorkspace: 1
    property int stageWorkspace: 1
    property int transitionWorkspace: 1
    property int stageDirection: 1
    property bool stageSliding: false
    property real reveal: 0.0
    property bool scopeVisible: false
    property int pendingActivation: 0
    property bool busy: false

    readonly property string helper:
        Quickshell.env("HOME")
        + "/.config/hypr/hyprlab-scripts/hyprlab-scope.sh"

    readonly property real deckHeight:
        Math.max(190, Math.min(245, scopeWindow.height * 0.225))

    readonly property real stageWidth:
        scopeWindow.width
        * (1.0 - 0.12 * root.reveal)

    readonly property real stageHeight:
        scopeWindow.height
        - root.reveal * (root.deckHeight + 105)

    readonly property real stageX:
        (scopeWindow.width - root.stageWidth) / 2

    readonly property real stageY:
        root.reveal * 54

    function focusedWorkspaceId() {
        return Hyprland.focusedWorkspace
            ? Hyprland.focusedWorkspace.id
            : 1
    }

    function clampWorkspace(value) {
        return Math.max(
            1,
            Math.min(root.workspaceCount, value)
        )
    }

    function refreshHyprland() {
        Hyprland.refreshMonitors()
        Hyprland.refreshWorkspaces()
        Hyprland.refreshToplevels()
    }

    function open() {
        if (root.scopeVisible)
            return

        root.refreshHyprland()
        root.pendingActivation = 0
        root.selectedWorkspace =
            root.clampWorkspace(root.focusedWorkspaceId())
        root.stageWorkspace = root.selectedWorkspace
        root.transitionWorkspace = root.selectedWorkspace

        root.scopeVisible = true
        root.reveal = 0.0

        Qt.callLater(function() {
            keyCatcher.forceActiveFocus()
            root.reveal = 1.0
        })
    }

    function close() {
        if (!root.scopeVisible)
            return

        root.pendingActivation = 0
        root.reveal = 0.0
    }

    function toggle() {
        if (root.scopeVisible)
            root.close()
        else
            root.open()
    }

    function selectWorkspace(id) {
        const next = root.clampWorkspace(id)

        root.selectedWorkspace = next

        if (next === root.stageWorkspace && !root.stageSliding)
            return

        root.startStageSlide(next)
    }

    function startStageSlide(nextWorkspace) {
        if (root.stageSliding) {
            stageSlide.stop()
            root.stageWorkspace = root.transitionWorkspace
            stageCurrent.workspaceId = root.stageWorkspace
            stageCurrent.x = 0
            stageNext.x = stageViewport.width
            root.stageSliding = false
        }

        if (nextWorkspace === root.stageWorkspace)
            return

        root.stageDirection =
            nextWorkspace > root.stageWorkspace ? 1 : -1

        root.transitionWorkspace = nextWorkspace
        root.stageSliding = true

        stageNext.workspaceId = nextWorkspace
        stageCurrent.x = 0
        stageNext.x =
            root.stageDirection * stageViewport.width

        stageSlide.restart()
    }

    function activateSelected() {
        if (!root.scopeVisible)
            return

        root.pendingActivation = root.selectedWorkspace
        root.reveal = 0.0
    }

    function moveSelection(delta) {
        let next = root.selectedWorkspace + delta

        if (next < 1)
            next = root.workspaceCount
        else if (next > root.workspaceCount)
            next = 1

        root.selectWorkspace(next)
    }

    function runHelper(args) {
        const command = ["bash", root.helper]

        for (let i = 0; i < args.length; ++i)
            command.push(String(args[i]))

        Quickshell.execDetached(command)
        root.busy = true
        operationRefresh.restart()
    }

    function moveWindow(address, targetWorkspace) {
        if (!address || address.length === 0)
            return

        root.runHelper([
            "move-window",
            address,
            targetWorkspace
        ])
    }

    function dropWindowAt(address, sceneX, sceneY) {
        if (!address || address.length === 0)
            return

        for (let i = 0; i < workspaceRepeater.count; ++i) {
            const card = workspaceRepeater.itemAt(i)

            if (!card)
                continue

            const local = card.mapFromItem(
                null,
                sceneX,
                sceneY
            )

            if (
                local.x >= 0
                && local.y >= 0
                && local.x <= card.width
                && local.y <= card.height
            ) {
                // Dropping on the currently displayed workspace is a no-op.
                if (card.workspaceId !== root.stageWorkspace)
                    root.moveWindow(address, card.workspaceId)

                return
            }
        }
    }

    function closeWorkspace(id) {
        if (root.workspaceCount <= 1)
            return

        if (root.selectedWorkspace === id) {
            root.selectedWorkspace =
                id > 1 ? id - 1 : 1
        } else if (root.selectedWorkspace > id) {
            root.selectedWorkspace -= 1
        }

        root.runHelper([
            "close",
            id
        ])
    }

    function addWorkspace() {
        if (root.workspaceCount >= 10)
            return

        root.runHelper(["add"])
        root.selectedWorkspace =
            Math.min(10, root.workspaceCount + 1)
    }

    IpcHandler {
        target: "hyprscope"

        function open(): void {
            root.open()
        }

        function close(): void {
            root.close()
        }

        function toggle(): void {
            root.toggle()
        }
    }

    Timer {
        id: operationRefresh
        interval: 520
        repeat: false

        onTriggered: {
            root.busy = false
            root.refreshHyprland()
            root.selectedWorkspace =
                root.clampWorkspace(root.selectedWorkspace)
        }
    }

    Behavior on reveal {
        NumberAnimation {
            id: revealAnimation
            duration: 270
            easing.type: Easing.InOutCubic

            onRunningChanged: {
                if (!running && root.reveal <= 0.001) {
                    const target = root.pendingActivation

                    root.scopeVisible = false
                    root.pendingActivation = 0

                    if (target > 0) {
                        Hyprland.dispatch(
                            'hl.dsp.focus({ workspace = "'
                            + target
                            + '" })'
                        )
                    }
                }
            }
        }
    }

    onWorkspaceCountChanged: {
        root.selectedWorkspace =
            root.clampWorkspace(root.selectedWorkspace)
    }

    PanelWindow {
        id: scopeWindow
        visible: root.scopeVisible

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"
        aboveWindows: true
        focusable: true
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "hypr-lab-scope"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        // Hypr-Scope owns the complete visual background while open.
        // At reveal == 0 the live workspace stage still covers the screen.
        // While the stage shrinks, this wallpaper surface is revealed behind it
        // instead of exposing the real (possibly occlusion-throttled) desktop.
        Rectangle {
            anchors.fill: parent
            color: "#050A0F"
        }

        Image {
            id: scopeWallpaper
            anchors.fill: parent
            source: root.wallpaperSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            opacity: root.reveal
            scale: 1.0 + (0.018 * root.reveal)

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.InOutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 270
                    easing.type: Easing.InOutCubic
                }
            }
        }

        // Strong enough to make the Scope read as its own surface, but still
        // leaves the current wallpaper visible around the live stage.
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(
                0.012,
                0.023,
                0.032,
                0.62 * root.reveal
            )
        }

        // Subtle stage halo. It replaces the visual dependency on the actual
        // windows behind the overlay and helps the live stage detach cleanly.
        Rectangle {
            x: Math.max(0, root.stageX - 18)
            y: Math.max(0, root.stageY - 14)
            width: Math.min(
                scopeWindow.width,
                root.stageWidth + 36
            )
            height: Math.min(
                scopeWindow.height,
                root.stageHeight + 28
            )
            color: Qt.rgba(
                root.accentColor.r,
                root.accentColor.g,
                root.accentColor.b,
                0.025 * root.reveal
            )
            border.width: root.reveal > 0.05 ? 1 : 0
            border.color: Qt.rgba(
                root.accentColor.r,
                root.accentColor.g,
                root.accentColor.b,
                0.11 * root.reveal
            )
            opacity: root.reveal
        }

        Item {
            id: stage
            x: root.stageX
            y: root.stageY
            width: root.stageWidth
            height: root.stageHeight
            opacity: 0.86 + 0.14 * root.reveal

            Rectangle {
                anchors.fill: parent
                color: "#08121A"
                border.width: root.reveal > 0.02 ? 1 : 0
                border.color: Qt.rgba(
                    root.accentColor.r,
                    root.accentColor.g,
                    root.accentColor.b,
                    0.72 * root.reveal
                )
                radius: 1
                clip: true

                Item {
                    id: stageViewport
                    anchors.fill: parent
                    anchors.margins: root.reveal > 0.03 ? 5 : 0
                    clip: true

                    HyprScopeWorkspacePreview {
                        id: stageCurrent
                        x: 0
                        y: 0
                        width: stageViewport.width
                        height: stageViewport.height

                        workspaceId: root.stageWorkspace
                        wallpaperSource: root.wallpaperSource
                        accentColor: root.accentColor
                        liveWindows: true
                        allowWindowDrag: true

                        onWindowDropRequested: function(address, sceneX, sceneY) {
                            root.dropWindowAt(address, sceneX, sceneY)
                        }
                    }

                    HyprScopeWorkspacePreview {
                        id: stageNext
                        x: stageViewport.width
                        y: 0
                        width: stageViewport.width
                        height: stageViewport.height

                        workspaceId: root.transitionWorkspace
                        wallpaperSource: root.wallpaperSource
                        accentColor: root.accentColor
                        liveWindows: true
                        allowWindowDrag: true

                        onWindowDropRequested: function(address, sceneX, sceneY) {
                            root.dropWindowAt(address, sceneX, sceneY)
                        }
                    }

                    ParallelAnimation {
                        id: stageSlide

                        NumberAnimation {
                            target: stageCurrent
                            property: "x"
                            to: -root.stageDirection * stageViewport.width
                            duration: 285
                            easing.type: Easing.InOutCubic
                        }

                        NumberAnimation {
                            target: stageNext
                            property: "x"
                            to: 0
                            duration: 285
                            easing.type: Easing.InOutCubic
                        }

                        onFinished: {
                            root.stageWorkspace =
                                root.transitionWorkspace
                            stageCurrent.workspaceId =
                                root.stageWorkspace
                            stageCurrent.x = 0
                            stageNext.x =
                                root.stageDirection
                                * stageViewport.width
                            root.stageSliding = false
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 14
                    width: selectedLabel.implicitWidth + 24
                    height: 28
                    visible: root.reveal > 0.15
                    color: Qt.rgba(0.02, 0.03, 0.04, 0.74)
                    border.width: 1
                    border.color: Qt.rgba(
                        root.accentColor.r,
                        root.accentColor.g,
                        root.accentColor.b,
                        0.48
                    )

                    Text {
                        id: selectedLabel
                        anchors.centerIn: parent
                        text: "WORKSPACE " + root.selectedWorkspace
                        color: root.accentColor
                        font.family: "Inter"
                        font.pixelSize: 9
                        font.bold: true
                        font.italic: true
                    }
                }
            }
        }

        Item {
            id: deck
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.deckHeight
            opacity: root.reveal
            y: (1.0 - root.reveal) * 58

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.018, 0.032, 0.043, 0.94)
                border.width: 1
                border.color: Qt.rgba(
                    root.accentColor.r,
                    root.accentColor.g,
                    root.accentColor.b,
                    0.30
                )
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.top: parent.top
                anchors.topMargin: 16
                text: "HYPR-SCOPE"
                color: root.accentColor
                font.family: "Inter"
                font.pixelSize: 11
                font.bold: true
                font.italic: true
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 32
                anchors.top: parent.top
                anchors.topMargin: 17
                text: "Click: preview  ·  Enter: open  ·  Drag app to workspace: move  ·  Esc: close"
                color: Qt.rgba(1, 1, 1, 0.34)
                font.family: "Inter"
                font.pixelSize: 8
                font.italic: true
            }

            Row {
                id: workspaceRow
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                spacing: 10

                property real availableWidth:
                    deck.width - 86 - 66

                property real computedCardWidth:
                    Math.max(
                        122,
                        Math.min(
                            186,
                            (
                                availableWidth
                                - (root.workspaceCount - 1) * spacing
                            )
                            / Math.max(1, root.workspaceCount)
                        )
                    )

                Repeater {
                    id: workspaceRepeater

                    model: Math.max(
                        1,
                        Math.min(10, root.workspaceCount)
                    )

                    delegate: HyprScopeWorkspaceCard {
                        required property int index

                        width: workspaceRow.computedCardWidth
                        height: Math.min(
                            142,
                            Math.max(
                                104,
                                width * 0.61
                            )
                        )

                        workspaceId: index + 1
                        workspaceCount: root.workspaceCount
                        selected:
                            root.selectedWorkspace === workspaceId
                        wallpaperSource: root.wallpaperSource
                        accentColor: root.accentColor

                        onSelectedRequested: function(id) {
                            root.selectWorkspace(id)
                        }

                        onCloseRequested: function(id) {
                            root.closeWorkspace(id)
                        }
                    }
                }

                Item {
                    width: 52
                    height: Math.min(
                        142,
                        Math.max(
                            104,
                            workspaceRow.computedCardWidth * 0.61
                        )
                    )

                    Rectangle {
                        anchors.centerIn: parent
                        width: 44
                        height: 44
                        color: addMouse.containsMouse
                            ? Qt.rgba(
                                root.accentColor.r,
                                root.accentColor.g,
                                root.accentColor.b,
                                0.16
                            )
                            : Qt.rgba(1, 1, 1, 0.035)
                        border.width: 1
                        border.color:
                            root.workspaceCount < 10
                                ? (
                                    addMouse.containsMouse
                                        ? root.accentColor
                                        : Qt.rgba(
                                            root.accentColor.r,
                                            root.accentColor.g,
                                            root.accentColor.b,
                                            0.45
                                        )
                                )
                                : Qt.rgba(1, 1, 1, 0.10)
                        opacity:
                            root.workspaceCount < 10
                                ? 1.0
                                : 0.34

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color:
                                root.workspaceCount < 10
                                    ? root.accentColor
                                    : Qt.rgba(1, 1, 1, 0.24)
                            font.family: "Inter"
                            font.pixelSize: 22
                            font.bold: false
                        }

                        MouseArea {
                            id: addMouse
                            anchors.fill: parent
                            enabled: root.workspaceCount < 10
                            hoverEnabled: true
                            cursorShape:
                                enabled
                                    ? Qt.PointingHandCursor
                                    : Qt.ArrowCursor

                            onClicked: root.addWorkspace()
                        }
                    }
                }
            }
        }

        Item {
            id: keyCatcher
            anchors.fill: parent
            focus: root.scopeVisible
            z: -100

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                } else if (
                    event.key === Qt.Key_Return
                    || event.key === Qt.Key_Enter
                ) {
                    root.activateSelected()
                    event.accepted = true
                } else if (event.key === Qt.Key_Left) {
                    root.moveSelection(-1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    root.moveSelection(1)
                    event.accepted = true
                }
            }
        }
    }
}
