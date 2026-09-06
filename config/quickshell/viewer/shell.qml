//@ pragma AppId hypr-lab-viewer

import QtQuick
import Quickshell
import Quickshell.Io
import "components"

FloatingWindow {
    id: viewerWindow

    title: "Hypr-Viewer"
    visible: true
    color: "transparent"

    implicitWidth: 1180
    implicitHeight: 760

    minimumSize: Qt.size(720, 480)

    property var imagePaths: []
    property int currentIndex: -1

    property bool galleryOpen: false
    property int galleryWidth: 260

    property bool infoOpen: false
    property int infoWidth: 280

    property var rotations: ({})
    property string imageFileSize: "—"

    readonly property string stateHome: {
        const xdgState = Quickshell.env("XDG_STATE_HOME") || "";
        const home = Quickshell.env("HOME") || "";

        return xdgState.length > 0
            ? xdgState
            : home + "/.local/state";
    }

    readonly property string rotationStatePath:
        stateHome + "/hypr-lab/hypr-viewer-rotations.json"

    readonly property int currentRotation:
        currentIndex >= 0 && currentIndex < imagePaths.length
            ? rotationFor(imagePaths[currentIndex])
            : 0

    readonly property color surfaceColor: Qt.rgba(7 / 255, 11 / 255, 16 / 255, 0.96)
    readonly property color cardColor: Qt.rgba(1, 1, 1, 0.028)
    readonly property color buttonColor: Qt.rgba(8 / 255, 12 / 255, 17 / 255, 0.72)
    readonly property color cardBorderColor: Qt.rgba(1, 1, 1, 0.065)

    readonly property url currentSource: currentIndex >= 0 && currentIndex < imagePaths.length ? rootPathToUrl(imagePaths[currentIndex]) : ""

    function accent(alpha) {
        return Qt.rgba(accentReader.accentColor.r, accentReader.accentColor.g, accentReader.accentColor.b, alpha);
    }

    function urlToPath(url) {
        let value = String(url);

        if (value.startsWith("file://"))
            value = value.substring(7);

        return decodeURIComponent(value);
    }

    function rootPathToUrl(path) {
        if (!path || path.length === 0)
            return "";

        return "file://" + encodeURI(path);
    }

    function fileName(path) {
        if (!path)
            return "";

        const clean = String(path);
        const pos = clean.lastIndexOf("/");

        return pos >= 0 ? clean.substring(pos + 1) : clean;
    }

    function fileExtension(path) {
        const name = fileName(path);
        const pos = name.lastIndexOf(".");

        return pos >= 0
            ? name.substring(pos + 1).toUpperCase()
            : "—";
    }

    function normalizeRotation(value) {
        let result = value % 360;

        if (result < 0)
            result += 360;

        return result;
    }

    function rotationFor(path) {
        if (!path)
            return 0;

        const value = rotations[path];

        return value === undefined
            ? 0
            : normalizeRotation(Number(value));
    }

    function rotateCurrent(delta) {
        if (currentIndex < 0 || currentIndex >= imagePaths.length)
            return;

        const path = imagePaths[currentIndex];
        const nextRotation =
            normalizeRotation(rotationFor(path) + delta);

        const updated = Object.assign({}, rotations);
        updated[path] = nextRotation;
        rotations = updated;

        imageViewport.resetView(false);
        rotationSaveTimer.restart();
    }

    function toggleInfo() {
        infoOpen = !infoOpen;
    }

    function refreshImageInfo() {
        if (currentIndex < 0 || currentIndex >= imagePaths.length) {
            imageFileSize = "—";
            return;
        }

        imageInfoReader.command = [
            "python3",
            "-c",
            "import os,sys; "
                + "size=os.path.getsize(sys.argv[1]); "
                + "units=['B','KiB','MiB','GiB']; "
                + "i=0; value=float(size); "
                + "exec(\"while value >= 1024 and i < len(units)-1:\\n"
                + " value /= 1024\\n"
                + " i += 1\"); "
                + "print(f'{value:.1f} {units[i]}' if i else f'{int(value)} {units[i]}')",
            imagePaths[currentIndex]
        ];

        imageInfoReader.running = true;
    }

    function persistRotations() {
        rotationWriter.command = [
            "python3",
            "-c",
            "import json,os,sys; "
                + "path=sys.argv[1]; "
                + "os.makedirs(os.path.dirname(path), exist_ok=True); "
                + "tmp=path+'.tmp'; "
                + "open(tmp,'w',encoding='utf-8').write(sys.argv[2]); "
                + "os.replace(tmp,path)",
            rotationStatePath,
            JSON.stringify(rotations)
        ];

        rotationWriter.running = true;
    }

    function openFiles(urls) {
        let paths = [];

        for (let url of urls) {
            const path = urlToPath(url);

            if (path.length > 0)
                paths.push(path);
        }

        if (paths.length === 0)
            return;
        imagePaths = paths;
        imageViewport.resetView(false);
        currentIndex = 0;
        imageViewport.playImageTransition(0);
        refreshImageInfo();
    }

    function openFolder(url) {
        const path = urlToPath(url);

        if (path.length === 0)
            return;
        folderReader.command = ["find", path, "-maxdepth", "1", "-type", "f", "(", "-iname", "*.png", "-o", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.webp", "-o", "-iname", "*.bmp", "-o", "-iname", "*.gif", ")", "-print"];

        folderReader.running = true;
    }

    function changeImage(index, direction) {
        if (index < 0 || index >= imagePaths.length)
            return;

        if (index === currentIndex)
            return;

        imageViewport.resetView(false);
        currentIndex = index;
        imageViewport.playImageTransition(direction);
        refreshImageInfo();
    }

    function previousImage() {
        if (imagePaths.length <= 1)
            return;

        const index =
            (currentIndex - 1 + imagePaths.length)
            % imagePaths.length;

        changeImage(index, -1);
    }

    function nextImage() {
        if (imagePaths.length <= 1)
            return;

        const index =
            (currentIndex + 1)
            % imagePaths.length;

        changeImage(index, 1);
    }

    function openStartupInput() {
        const raw = Quickshell.env("HYPR_VIEWER_INPUT");

        if (raw === null || raw === undefined || String(raw).trim().length === 0)
            return;

        try {
            const items = JSON.parse(String(raw));

            if (!Array.isArray(items) || items.length === 0)
                return;

            if (items.length === 1 && items[0].kind === "directory") {
                openFolder(rootPathToUrl(items[0].path));
                return;
            }

            let urls = [];

            for (let item of items) {
                if (item.kind === "file")
                    urls.push(rootPathToUrl(item.path));
            }

            if (urls.length > 0)
                openFiles(urls);
        } catch (error) {
            console.warn("Hypr-Viewer: invalid startup input:", error);
        }
    }

    function toggleGallery() {
        galleryOpen = !galleryOpen;
    }

    AdaptiveAccent {
        id: accentReader
    }

    Component.onCompleted: {
        rotationReader.running = true;
        Qt.callLater(viewerWindow.openStartupInput);
    }

    Process {
        id: rotationReader

        command: [
            "python3",
            "-c",
            "import json,os,sys; "
                + "path=sys.argv[1]; "
                + "print(json.dumps(json.load(open(path,encoding='utf-8'))) "
                + "if os.path.exists(path) else '{}')",
            viewerWindow.rotationStatePath
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(String(text).trim() || "{}");

                    viewerWindow.rotations = parsed;
                } catch (error) {
                    viewerWindow.rotations = {};
                }
            }
        }
    }

    Process {
        id: rotationWriter
    }

    Timer {
        id: rotationSaveTimer

        interval: 250
        repeat: false

        onTriggered: {
            if (!rotationWriter.running)
                viewerWindow.persistRotations();
        }
    }

    Process {
        id: imageInfoReader

        stdout: StdioCollector {
            onStreamFinished: {
                viewerWindow.imageFileSize =
                    String(text).trim() || "—";
            }
        }
    }

    Process {
        id: folderReader

        stdout: StdioCollector {
            onStreamFinished: {
                const raw = String(text).trim();

                if (raw.length === 0) {
                    viewerWindow.imagePaths = [];
                    viewerWindow.currentIndex = -1;
                    return;
                }

                let paths = raw.split("\n").filter(function (path) {
                    return path.length > 0;
                });

                paths.sort(function (a, b) {
                    return viewerWindow.fileName(a).localeCompare(viewerWindow.fileName(b));
                });

                viewerWindow.imagePaths = paths;
                imageViewport.resetView(false);
                viewerWindow.currentIndex = paths.length > 0 ? 0 : -1;

                if (paths.length > 0) {
                    imageViewport.playImageTransition(0);
                    viewerWindow.refreshImageInfo();
                }
            }
        }
    }

    Shortcut {
        sequence: "Left"
        onActivated: viewerWindow.previousImage()
    }

    Shortcut {
        sequence: "Right"
        onActivated: viewerWindow.nextImage()
    }

    Shortcut {
        sequence: "L"
        enabled: viewerWindow.currentIndex >= 0 && !viewerFileDialog.opened
        onActivated: viewerWindow.rotateCurrent(-90)
    }

    Shortcut {
        sequence: "R"
        enabled: viewerWindow.currentIndex >= 0 && !viewerFileDialog.opened
        onActivated: viewerWindow.rotateCurrent(90)
    }

    Shortcut {
        sequence: "I"
        enabled: !viewerFileDialog.opened
        onActivated: viewerWindow.toggleInfo()
    }

    Shortcut {
        sequence: "Tab"
        onActivated: viewerWindow.toggleGallery()
    }

    Shortcut {
        sequence: "Ctrl+O"
        onActivated: viewerFileDialog.openFileMode()
    }

    Shortcut {
        sequence: "Ctrl+Shift+O"
        onActivated: viewerFileDialog.openFolderMode()
    }

    Rectangle {
        anchors.fill: parent

        color: viewerWindow.surfaceColor

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            border.width: 1
            border.color: viewerWindow.accent(0.28)
        }

        //
        // Thumbnail drawer
        //
        Item {
            id: galleryDrawer

            width: viewerWindow.galleryWidth
            height: parent.height

            x: viewerWindow.galleryOpen ? 0 : -width

            z: 20

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent

                color: Qt.rgba(8 / 255, 12 / 255, 17 / 255, 0.97)

                border.width: 1
                border.color: viewerWindow.accent(0.24)
            }

            Column {
                anchors.fill: parent
                anchors.margins: 12

                spacing: 10

                Text {
                    text: "IMAGES"

                    color: accentReader.accentColor

                    font.family: "Inter"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.0
                }

                Text {
                    text: viewerWindow.imagePaths.length + " image" + (viewerWindow.imagePaths.length === 1 ? "" : "s")

                    color: Qt.rgba(1, 1, 1, 0.38)

                    font.family: "Inter"
                    font.pixelSize: 10
                }

                Item {
                    width: 1
                    height: 2
                }

                GridView {
                    id: thumbnailGrid

                    width: parent.width
                    height: parent.height - 60

                    clip: true

                    cellWidth: (width - 8) / 2
                    cellHeight: 118

                    model: viewerWindow.imagePaths.length

                    delegate: Item {
                        required property int index

                        width: thumbnailGrid.cellWidth
                        height: thumbnailGrid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4

                            radius: 1

                            color: index === viewerWindow.currentIndex ? viewerWindow.accent(0.09) : viewerWindow.cardColor

                            border.width: 1

                            border.color: index === viewerWindow.currentIndex ? viewerWindow.accent(0.6) : thumbMouse.containsMouse ? viewerWindow.accent(0.32) : viewerWindow.cardBorderColor

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 110
                                }
                            }

                            Image {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right

                                anchors.margins: 6

                                height: 76

                                source: viewerWindow.rootPathToUrl(viewerWindow.imagePaths[index])

                                fillMode: Image.PreserveAspectCrop

                                asynchronous: true
                                cache: true

                                smooth: true
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom

                                anchors.leftMargin: 7
                                anchors.rightMargin: 7
                                anchors.bottomMargin: 7

                                text: viewerWindow.fileName(viewerWindow.imagePaths[index])

                                color: index === viewerWindow.currentIndex ? accentReader.accentColor : Qt.rgba(1, 1, 1, 0.58)

                                font.family: "Inter"
                                font.pixelSize: 9

                                elide: Text.ElideMiddle

                                horizontalAlignment: Text.AlignHCenter
                            }

                            MouseArea {
                                id: thumbMouse

                                anchors.fill: parent

                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    const direction =
                                        index > viewerWindow.currentIndex
                                            ? 1
                                            : -1;

                                    viewerWindow.changeImage(
                                        index,
                                        direction
                                    );
                                }
                            }
                        }
                    }
                }
            }
        }

        //
        // Main image area
        //
        Item {
            id: imageArea

            x: viewerWindow.galleryOpen ? viewerWindow.galleryWidth : 0

            width:
                parent.width
                - x
                - (viewerWindow.infoOpen ? viewerWindow.infoWidth : 0)

            height: parent.height

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on width {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            //
            // Top-left controls
            //
            Row {
                z: 100

                anchors.left: parent.left
                anchors.top: parent.top

                anchors.leftMargin: 16
                anchors.topMargin: 16

                spacing: 8

                Rectangle {
                    width: 36
                    height: 36

                    radius: 1

                    color: galleryButtonMouse.containsMouse ? viewerWindow.accent(0.11) : viewerWindow.buttonColor

                    border.width: 1
                    border.color: viewerWindow.galleryOpen ? viewerWindow.accent(0.62) : viewerWindow.cardBorderColor

                    Text {
                        anchors.centerIn: parent

                        text: "󰕰"

                        color: accentReader.accentColor

                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 17
                    }

                    MouseArea {
                        id: galleryButtonMouse

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: viewerWindow.toggleGallery()
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: 7

                        width: galleryTooltipText.implicitWidth + 16
                        height: 24

                        z: 200
                        radius: 1

                        opacity: galleryButtonMouse.containsMouse ? 1 : 0
                        visible: opacity > 0

                        color: Qt.rgba(8 / 255, 12 / 255, 17 / 255, 0.96)

                        border.width: 1
                        border.color: viewerWindow.accent(0.34)

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            id: galleryTooltipText

                            anchors.centerIn: parent

                            text: viewerWindow.galleryOpen ? "Hide Gallery" : "Show Gallery"

                            color: Qt.rgba(1, 1, 1, 0.72)

                            font.family: "Inter"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    width: 36
                    height: 36

                    radius: 1

                    color: fileButtonMouse.containsMouse ? viewerWindow.accent(0.11) : viewerWindow.buttonColor

                    border.width: 1
                    border.color: viewerWindow.cardBorderColor

                    Text {
                        anchors.centerIn: parent

                        text: "󰈔"

                        color: accentReader.accentColor

                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 17
                    }

                    MouseArea {
                        id: fileButtonMouse

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: viewerFileDialog.openFileMode()
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: 7

                        width: openImageTooltipText.implicitWidth + 16
                        height: 24

                        z: 200
                        radius: 1

                        opacity: fileButtonMouse.containsMouse ? 1 : 0
                        visible: opacity > 0

                        color: Qt.rgba(8 / 255, 12 / 255, 17 / 255, 0.96)

                        border.width: 1
                        border.color: viewerWindow.accent(0.34)

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            id: openImageTooltipText

                            anchors.centerIn: parent

                            text: "Open Image"

                            color: Qt.rgba(1, 1, 1, 0.72)

                            font.family: "Inter"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    width: 36
                    height: 36

                    radius: 1

                    color: folderButtonMouse.containsMouse ? viewerWindow.accent(0.11) : viewerWindow.buttonColor

                    border.width: 1
                    border.color: viewerWindow.cardBorderColor

                    Text {
                        anchors.centerIn: parent

                        text: "󰉋"

                        color: accentReader.accentColor

                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 17
                    }

                    MouseArea {
                        id: folderButtonMouse

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: viewerFileDialog.openFolderMode()
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: 7

                        width: openFolderTooltipText.implicitWidth + 16
                        height: 24

                        z: 200
                        radius: 1

                        opacity: folderButtonMouse.containsMouse ? 1 : 0
                        visible: opacity > 0

                        color: Qt.rgba(8 / 255, 12 / 255, 17 / 255, 0.96)

                        border.width: 1
                        border.color: viewerWindow.accent(0.34)

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            id: openFolderTooltipText

                            anchors.centerIn: parent

                            text: "Open Folder"

                            color: Qt.rgba(1, 1, 1, 0.72)

                            font.family: "Inter"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    width: 36
                    height: 36

                    radius: 1

                    color:
                        rotateLeftMouse.containsMouse
                            ? viewerWindow.accent(0.11)
                            : viewerWindow.buttonColor

                    border.width: 1
                    border.color: viewerWindow.cardBorderColor

                    opacity: viewerWindow.currentIndex >= 0 ? 1 : 0.32

                    Text {
                        anchors.centerIn: parent

                        text: "↶"

                        color: accentReader.accentColor

                        font.family: "Inter"
                        font.pixelSize: 19
                        font.bold: true
                    }

                    MouseArea {
                        id: rotateLeftMouse

                        anchors.fill: parent

                        enabled: viewerWindow.currentIndex >= 0
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: viewerWindow.rotateCurrent(-90)
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: 7

                        width: rotateLeftTooltipText.implicitWidth + 16
                        height: 24

                        z: 200
                        radius: 1

                        opacity: rotateLeftMouse.containsMouse ? 1 : 0
                        visible: opacity > 0

                        color: Qt.rgba(8 / 255, 12 / 255, 17 / 255, 0.96)

                        border.width: 1
                        border.color: viewerWindow.accent(0.34)

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            id: rotateLeftTooltipText

                            anchors.centerIn: parent

                            text: "Rotate Left"

                            color: Qt.rgba(1, 1, 1, 0.72)

                            font.family: "Inter"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    width: 36
                    height: 36

                    radius: 1

                    color:
                        rotateRightMouse.containsMouse
                            ? viewerWindow.accent(0.11)
                            : viewerWindow.buttonColor

                    border.width: 1
                    border.color: viewerWindow.cardBorderColor

                    opacity: viewerWindow.currentIndex >= 0 ? 1 : 0.32

                    Text {
                        anchors.centerIn: parent

                        text: "↷"

                        color: accentReader.accentColor

                        font.family: "Inter"
                        font.pixelSize: 19
                        font.bold: true
                    }

                    MouseArea {
                        id: rotateRightMouse

                        anchors.fill: parent

                        enabled: viewerWindow.currentIndex >= 0
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: viewerWindow.rotateCurrent(90)
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: 7

                        width: rotateRightTooltipText.implicitWidth + 16
                        height: 24

                        z: 200
                        radius: 1

                        opacity: rotateRightMouse.containsMouse ? 1 : 0
                        visible: opacity > 0

                        color: Qt.rgba(8 / 255, 12 / 255, 17 / 255, 0.96)

                        border.width: 1
                        border.color: viewerWindow.accent(0.34)

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            id: rotateRightTooltipText

                            anchors.centerIn: parent

                            text: "Rotate Right"

                            color: Qt.rgba(1, 1, 1, 0.72)

                            font.family: "Inter"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }
            }

            //
            // Empty state
            //
            Column {
                anchors.centerIn: parent

                visible: viewerWindow.currentIndex < 0

                spacing: 12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "󰋩"

                    color: accentReader.accentColor

                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 44
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "HYPR-VIEWER"

                    color: "white"

                    font.family: "Inter"
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "Open an image or folder"

                    color: Qt.rgba(1, 1, 1, 0.4)

                    font.family: "Inter"
                    font.pixelSize: 11
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "Ctrl+O · file     Ctrl+Shift+O · folder"

                    color: Qt.rgba(1, 1, 1, 0.25)

                    font.family: "Inter"
                    font.pixelSize: 9
                }
            }

            //
            // Current image
            //
            Item {
                id: imageViewport

                anchors.fill: parent

                readonly property int contentMargin:
                    viewerWindow.galleryOpen || viewerWindow.infoOpen
                        ? 12
                        : 0

                anchors.leftMargin: contentMargin
                anchors.rightMargin: contentMargin
                anchors.topMargin: contentMargin
                anchors.bottomMargin: contentMargin

                visible: viewerWindow.currentIndex >= 0

                clip: true

                property real zoom: 1.0
                property real minZoom: 0.1
                property real maxZoom: 8.0

                property real panX: 0
                property real panY: 0

                property bool viewAnimationEnabled: true

                property real transitionOffset: 0
                property real transitionOpacity: 1
                property real transitionScale: 1.0

                function resetView(animated) {
                    const shouldAnimate =
                        animated === undefined
                            ? true
                            : animated;

                    if (!shouldAnimate)
                        viewAnimationEnabled = false;

                    zoom = 1.0;
                    panX = 0;
                    panY = 0;

                    if (!shouldAnimate) {
                        Qt.callLater(function() {
                            imageViewport.viewAnimationEnabled = true;
                        });
                    }
                }

                function setZoom(newZoom, centerX, centerY) {
                    const oldZoom = zoom;
                    const clampedZoom = Math.max(
                        minZoom,
                        Math.min(maxZoom, newZoom)
                    );

                    if (Math.abs(clampedZoom - oldZoom) < 0.0001)
                        return;

                    const imageX =
                        (centerX - panX) / oldZoom;

                    const imageY =
                        (centerY - panY) / oldZoom;

                    zoom = clampedZoom;

                    panX =
                        centerX
                        - imageX * clampedZoom;

                    panY =
                        centerY
                        - imageY * clampedZoom;
                }

                function playImageTransition(direction) {
                    imageTransition.stop();

                    transitionOffset =
                        direction === 0
                            ? 0
                            : direction * 18;

                    transitionOpacity = 0;
                    transitionScale = 0.985;

                    imageTransition.restart();
                }

                Behavior on zoom {
                    enabled:
                        imageViewport.viewAnimationEnabled
                        && !imageMouse.pressed

                    NumberAnimation {
                        duration: 145
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on panX {
                    enabled:
                        imageViewport.viewAnimationEnabled
                        && !imageMouse.pressed

                    NumberAnimation {
                        duration: 145
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on panY {
                    enabled:
                        imageViewport.viewAnimationEnabled
                        && !imageMouse.pressed

                    NumberAnimation {
                        duration: 145
                        easing.type: Easing.OutCubic
                    }
                }

                ParallelAnimation {
                    id: imageTransition

                    NumberAnimation {
                        target: imageViewport
                        property: "transitionOpacity"
                        from: 0
                        to: 1
                        duration: 170
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: imageViewport
                        property: "transitionOffset"
                        to: 0
                        duration: 210
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: imageViewport
                        property: "transitionScale"
                        from: 0.985
                        to: 1.0
                        duration: 210
                        easing.type: Easing.OutCubic
                    }
                }

                Item {
                    id: imageTransform

                    width: imageViewport.width
                    height: imageViewport.height

                    opacity: imageViewport.transitionOpacity

                    scale:
                        imageViewport.zoom
                        * imageViewport.transitionScale

                    x:
                        imageViewport.panX
                        + imageViewport.transitionOffset

                    y: imageViewport.panY

                    transformOrigin: Item.TopLeft

                    Image {
                        id: mainImage

                        anchors.centerIn: parent

                        readonly property bool quarterTurn:
                            viewerWindow.currentRotation === 90
                            || viewerWindow.currentRotation === 270

                        width:
                            quarterTurn
                                ? imageViewport.height
                                : imageViewport.width

                        height:
                            quarterTurn
                                ? imageViewport.width
                                : imageViewport.height

                        source: viewerWindow.currentSource

                        asynchronous: true
                        cache: true
                        smooth: true
                        mipmap: true

                        fillMode: Image.PreserveAspectFit

                        rotation: viewerWindow.currentRotation
                        transformOrigin: Item.Center

                        Behavior on rotation {
                            NumberAnimation {
                                duration: 190
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                MouseArea {
                    id: imageMouse

                    anchors.fill: parent

                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton

                    property real lastX: 0
                    property real lastY: 0

                    cursorShape:
                        pressed
                            ? Qt.ClosedHandCursor
                            : imageViewport.zoom > 1.0
                                ? Qt.OpenHandCursor
                                : Qt.ArrowCursor

                    onPressed: function(mouse) {
                        lastX = mouse.x;
                        lastY = mouse.y;
                    }

                    onPositionChanged: function(mouse) {
                        if (!pressed)
                            return;

                        if (imageViewport.zoom <= 1.0)
                            return;

                        const dx = mouse.x - lastX;
                        const dy = mouse.y - lastY;

                        imageViewport.panX += dx;
                        imageViewport.panY += dy;

                        lastX = mouse.x;
                        lastY = mouse.y;
                    }

                    onWheel: function(wheel) {
                        const factor =
                            wheel.angleDelta.y > 0
                                ? 1.12
                                : 1 / 1.12;

                        imageViewport.setZoom(
                            imageViewport.zoom * factor,
                            wheel.x,
                            wheel.y
                        );

                        wheel.accepted = true;
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    // Keep the zoom readout clear of the i / previous / next buttons.
                    anchors.rightMargin: 158
                    anchors.bottomMargin: 21

                    width: zoomText.implicitWidth + 16
                    height: 24

                    radius: 1

                    color: viewerWindow.cardColor

                    border.width: 1
                    border.color: viewerWindow.cardBorderColor

                    Text {
                        id: zoomText

                        anchors.centerIn: parent

                        text: Math.round(imageViewport.zoom * 100) + "%"

                        color: Qt.rgba(1, 1, 1, 0.56)

                        font.family: "Inter"
                        font.pixelSize: 9
                    }
                }
            }

            //
            // Filename bottom-left
            //
            Text {
                z: 90

                anchors.left: parent.left
                anchors.bottom: parent.bottom

                anchors.leftMargin: 18
                anchors.bottomMargin: 18

                visible: viewerWindow.currentIndex >= 0

                text: viewerWindow.currentIndex >= 0 ? viewerWindow.fileName(viewerWindow.imagePaths[viewerWindow.currentIndex]) : ""

                color: Qt.rgba(1, 1, 1, 0.48)

                font.family: "Inter"
                font.pixelSize: 10
            }

            //
            // Navigation bottom-right
            //
            Row {
                z: 100

                anchors.right: parent.right
                anchors.bottom: parent.bottom

                anchors.rightMargin: 18
                anchors.bottomMargin: 16

                spacing: 8

                Rectangle {
                    width: 38
                    height: 34

                    radius: 1

                    color:
                        infoMouse.containsMouse
                            ? viewerWindow.accent(0.12)
                            : viewerWindow.buttonColor

                    border.width: 1

                    border.color:
                        viewerWindow.infoOpen
                            ? viewerWindow.accent(0.58)
                            : viewerWindow.cardBorderColor

                    Text {
                        anchors.centerIn: parent

                        text: "i"

                        color: accentReader.accentColor

                        font.family: "Inter"
                        font.pixelSize: 15
                        font.bold: true
                        font.italic: true
                    }

                    MouseArea {
                        id: infoMouse

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: viewerWindow.toggleInfo()
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 7

                        width: infoTooltipText.implicitWidth + 16
                        height: 24

                        z: 200
                        radius: 1

                        opacity: infoMouse.containsMouse ? 1 : 0
                        visible: opacity > 0

                        color: Qt.rgba(8 / 255, 12 / 255, 17 / 255, 0.96)

                        border.width: 1
                        border.color: viewerWindow.accent(0.34)

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            id: infoTooltipText

                            anchors.centerIn: parent

                            text: viewerWindow.infoOpen ? "Hide Info" : "Image Info"

                            color: Qt.rgba(1, 1, 1, 0.72)

                            font.family: "Inter"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    width: 38
                    height: 34

                    radius: 1

                    color: prevMouse.containsMouse ? viewerWindow.accent(0.12) : viewerWindow.buttonColor

                    border.width: 1
                    border.color: viewerWindow.cardBorderColor

                    opacity: viewerWindow.imagePaths.length > 1 ? 1.0 : 0.32

                    Text {
                        anchors.centerIn: parent

                        text: "←"

                        color: accentReader.accentColor

                        font.family: "Inter"
                        font.pixelSize: 17
                        font.bold: true
                    }

                    MouseArea {
                        id: prevMouse

                        anchors.fill: parent

                        enabled: viewerWindow.imagePaths.length > 1

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: viewerWindow.previousImage()
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 7

                        width: prevTooltipText.implicitWidth + 16
                        height: 24

                        z: 200
                        radius: 1

                        opacity: prevMouse.containsMouse && viewerWindow.imagePaths.length > 1 ? 1 : 0
                        visible: opacity > 0

                        color: Qt.rgba(8 / 255, 12 / 255, 17 / 255, 0.96)

                        border.width: 1
                        border.color: viewerWindow.accent(0.34)

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            id: prevTooltipText

                            anchors.centerIn: parent

                            text: "Previous Image"

                            color: Qt.rgba(1, 1, 1, 0.72)

                            font.family: "Inter"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    width: 38
                    height: 34

                    radius: 1

                    color: nextMouse.containsMouse ? viewerWindow.accent(0.12) : viewerWindow.buttonColor

                    border.width: 1
                    border.color: viewerWindow.cardBorderColor

                    opacity: viewerWindow.imagePaths.length > 1 ? 1.0 : 0.32

                    Text {
                        anchors.centerIn: parent

                        text: "→"

                        color: accentReader.accentColor

                        font.family: "Inter"
                        font.pixelSize: 17
                        font.bold: true
                    }

                    MouseArea {
                        id: nextMouse

                        anchors.fill: parent

                        enabled: viewerWindow.imagePaths.length > 1

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: viewerWindow.nextImage()
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 7

                        width: nextTooltipText.implicitWidth + 16
                        height: 24

                        z: 200
                        radius: 1

                        opacity: nextMouse.containsMouse && viewerWindow.imagePaths.length > 1 ? 1 : 0
                        visible: opacity > 0

                        color: Qt.rgba(8 / 255, 12 / 255, 17 / 255, 0.96)

                        border.width: 1
                        border.color: viewerWindow.accent(0.34)

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            id: nextTooltipText

                            anchors.centerIn: parent

                            text: "Next Image"

                            color: Qt.rgba(1, 1, 1, 0.72)

                            font.family: "Inter"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }
            }
        }
        Item {
            id: infoDrawer

            width: viewerWindow.infoWidth
            height: parent.height

            x:
                viewerWindow.infoOpen
                    ? parent.width - width
                    : parent.width

            z: 20

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent

                color: Qt.rgba(8 / 255, 12 / 255, 17 / 255, 0.97)

                border.width: 1
                border.color: viewerWindow.accent(0.24)
            }

            Column {
                anchors.fill: parent
                anchors.margins: 16

                spacing: 12

                Text {
                    text: "IMAGE INFO"

                    color: accentReader.accentColor

                    font.family: "Inter"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.0
                }

                Rectangle {
                    width: parent.width
                    height: 1

                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            position: 0
                            color: viewerWindow.accent(0)
                        }

                        GradientStop {
                            position: 0.5
                            color: viewerWindow.accent(0.5)
                        }

                        GradientStop {
                            position: 1
                            color: viewerWindow.accent(0)
                        }
                    }
                }

                Text {
                    width: parent.width

                    text:
                        viewerWindow.currentIndex >= 0
                            ? viewerWindow.fileName(
                                viewerWindow.imagePaths[
                                    viewerWindow.currentIndex
                                ]
                            )
                            : "No image"

                    color: "white"

                    font.family: "Inter"
                    font.pixelSize: 12
                    font.bold: true

                    wrapMode: Text.WrapAnywhere
                }

                Item {
                    width: 1
                    height: 4
                }

                Text {
                    text: "FORMAT"

                    color: Qt.rgba(1, 1, 1, 0.34)

                    font.family: "Inter"
                    font.pixelSize: 9
                    font.bold: true
                }

                Text {
                    text:
                        viewerWindow.currentIndex >= 0
                            ? viewerWindow.fileExtension(
                                viewerWindow.imagePaths[
                                    viewerWindow.currentIndex
                                ]
                            )
                            : "—"

                    color: Qt.rgba(1, 1, 1, 0.72)

                    font.family: "Inter"
                    font.pixelSize: 11
                }

                Text {
                    text: "RESOLUTION"

                    color: Qt.rgba(1, 1, 1, 0.34)

                    font.family: "Inter"
                    font.pixelSize: 9
                    font.bold: true
                }

                Text {
                    text:
                        mainImage.status === Image.Ready
                            ? Math.round(mainImage.sourceSize.width)
                                + " × "
                                + Math.round(mainImage.sourceSize.height)
                            : "—"

                    color: Qt.rgba(1, 1, 1, 0.72)

                    font.family: "Inter"
                    font.pixelSize: 11
                }

                Text {
                    text: "FILE SIZE"

                    color: Qt.rgba(1, 1, 1, 0.34)

                    font.family: "Inter"
                    font.pixelSize: 9
                    font.bold: true
                }

                Text {
                    text: viewerWindow.imageFileSize

                    color: Qt.rgba(1, 1, 1, 0.72)

                    font.family: "Inter"
                    font.pixelSize: 11
                }

                Text {
                    text: "ROTATION"

                    color: Qt.rgba(1, 1, 1, 0.34)

                    font.family: "Inter"
                    font.pixelSize: 9
                    font.bold: true
                }

                Text {
                    text: viewerWindow.currentRotation + "°"

                    color: Qt.rgba(1, 1, 1, 0.72)

                    font.family: "Inter"
                    font.pixelSize: 11
                }

                Text {
                    text: "ZOOM"

                    color: Qt.rgba(1, 1, 1, 0.34)

                    font.family: "Inter"
                    font.pixelSize: 9
                    font.bold: true
                }

                Text {
                    text: Math.round(imageViewport.zoom * 100) + "%"

                    color: Qt.rgba(1, 1, 1, 0.72)

                    font.family: "Inter"
                    font.pixelSize: 11
                }

                Text {
                    text: "PATH"

                    color: Qt.rgba(1, 1, 1, 0.34)

                    font.family: "Inter"
                    font.pixelSize: 9
                    font.bold: true
                }

                Text {
                    width: parent.width

                    text:
                        viewerWindow.currentIndex >= 0
                            ? viewerWindow.imagePaths[
                                viewerWindow.currentIndex
                            ]
                            : "—"

                    color: Qt.rgba(1, 1, 1, 0.54)

                    font.family: "Inter"
                    font.pixelSize: 9

                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        ViewerFileDialog {
            id: viewerFileDialog

            accentColor: accentReader.accentColor

            onFilesAccepted: function(files) {
                let urls = [];

                for (let file of files)
                    urls.push("file://" + encodeURI(file));

                viewerWindow.openFiles(urls);
            }

            onFolderAccepted: function(folder) {
                viewerWindow.openFolder(
                    "file://" + encodeURI(folder)
                );
            }
        }

    }
}
