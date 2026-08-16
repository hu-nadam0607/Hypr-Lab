import QtQuick
import Qt.labs.folderlistmodel

import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string wallpaperDirectory:
        Quickshell.env("HOME") + "/.config/hypr/hyprlab-wpp"

    property url currentWallpaper: ""
    property int transitionEffect: 0

    readonly property string wallpaperStateDirectory:
        Quickshell.env("HOME") + "/.cache/hypr-lab"

    readonly property string wallpaperStateFile:
        wallpaperStateDirectory
        + "/current-wallpaper"

    property bool stateReadFinished: false

    readonly property int effectCount:
        10

    FolderListModel {
        id: wallpaperModel

        folder:
            "file://" + root.wallpaperDirectory

        nameFilters: [
            "*.jpg", "*.JPG",
            "*.jpeg", "*.JPEG",
            "*.png", "*.PNG",
            "*.webp", "*.WEBP"
        ]

        showDirs:
            false

        showDotAndDotDot:
            false

        showHidden:
            false

        showOnlyReadable:
            true

        sortField:
            FolderListModel.Name
    }

    function wallpaperCount(): int {
        return wallpaperModel.count
    }

    function wallpaperAt(index: int): url {
        if (
            index < 0
            || index >= wallpaperModel.count
        ) {
            return ""
        }

        return wallpaperModel.get(
            index,
            "fileUrl"
        )
    }

    function localPath(source: url): string {
        if (!source)
            return ""

        const value =
            source.toString()

        if (value.length === 0)
            return ""

        if (value.startsWith("file://")) {
            return decodeURIComponent(
                value.substring(7)
            )
        }

        return decodeURIComponent(
            value
        )
    }

    function fileUrlFromPath(path: string): url {
        if (!path || path.length === 0)
            return ""

        if (path.startsWith("file://"))
            return path

        return "file://" + path
    }

    function currentWallpaperIndex(): int {
        if (
            !currentWallpaper
            || currentWallpaper.toString() === ""
        ) {
            return -1
        }

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

    function chooseEffect(): int {
        return Math.floor(
            Math.random()
            * effectCount
        )
    }

    function randomIndexExcludingCurrent(): int {
        const count =
            wallpaperModel.count

        if (count <= 0)
            return -1

        if (count === 1)
            return 0

        const currentIndex =
            currentWallpaperIndex()

        let index =
            Math.floor(
                Math.random()
                * count
            )

        if (index === currentIndex) {
            index =
                (
                    index
                    + 1
                    + Math.floor(
                        Math.random()
                        * (count - 1)
                    )
                )
                % count
        }

        return index
    }

    function persistCurrentWallpaper(): void {
        const path =
            localPath(currentWallpaper)

        if (path.length === 0)
            return

        wallpaperStateWriter.running =
            false

        wallpaperStateWriter.command = [
            "sh",
            "-c",
            "mkdir -p \"$1\" && printf '%s\\n' \"$2\" > \"$3\"",
            "hypr-lab-wallpaper",
            wallpaperStateDirectory,
            path,
            wallpaperStateFile
        ]

        wallpaperStateWriter.running =
            true
    }

    function setWallpaper(
        source: url,
        randomEffect: bool
    ): void {
        if (
            !source
            || source.toString() === ""
        ) {
            return
        }

        if (
            source.toString()
            === currentWallpaper.toString()
        ) {
            return
        }

        if (randomEffect) {
            transitionEffect =
                chooseEffect()
        }

        currentWallpaper =
            source
    }

    function randomWallpaper(): void {
        const index =
            randomIndexExcludingCurrent()

        if (index < 0) {
            console.warn(
                "[Hypr-Lab Wallpaper] "
                + "Nincs használható kép:",
                wallpaperDirectory
            )

            return
        }

        setWallpaper(
            wallpaperAt(index),
            true
        )
    }

    function ensureInitialWallpaper(): void {
        if (!stateReadFinished)
            return

        if (
            currentWallpaper
            && currentWallpaper.toString() !== ""
        ) {
            return
        }

        if (
            wallpaperModel.status
            !== FolderListModel.Ready
        ) {
            return
        }

        if (wallpaperModel.count <= 0) {
            console.warn(
                "[Hypr-Lab Wallpaper] "
                + "A wallpaper könyvtár üres:",
                wallpaperDirectory
            )

            return
        }

        transitionEffect = 0

        currentWallpaper =
            wallpaperAt(0)
    }

    Process {
        id: wallpaperStateWriter
    }

    Process {
        id: wallpaperStateReader

        command: [
            "sh",
            "-c",
            "if [ -s \"$1\" ]; then cat \"$1\"; fi",
            "hypr-lab-wallpaper",
            root.wallpaperStateFile
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const path =
                    text.trim()

                if (path.length > 0) {
                    root.transitionEffect = 0

                    root.currentWallpaper =
                        root.fileUrlFromPath(
                            path
                        )
                }

                root.stateReadFinished =
                    true

                root.ensureInitialWallpaper()
            }
        }
    }

    onCurrentWallpaperChanged: {
        if (
            currentWallpaper
            && currentWallpaper.toString() !== ""
        ) {
            persistCurrentWallpaper()
        }
    }

    function togglePicker(): void {
        picker.toggle()
    }

    IpcHandler {
        target:
            "wallpaper"

        function random(): void {
            root.randomWallpaper()
        }

        function togglePicker(): void {
            picker.toggle()
        }

        function openPicker(): void {
            picker.open()
        }

        function closePicker(): void {
            picker.close()
        }
    }

    Connections {
        target:
            wallpaperModel

        function onStatusChanged(): void {
            if (
                wallpaperModel.status
                === FolderListModel.Ready
            ) {
                root.ensureInitialWallpaper()
            }
        }
    }

    Component.onCompleted: {
        wallpaperStateReader.running =
            true
    }

    Variants {
        model:
            Quickshell.screens

        WallpaperSurface {
            required property var modelData

            screen:
                modelData

            requestedSource:
                root.currentWallpaper

            requestedEffect:
                root.transitionEffect
        }
    }

    WallpaperPicker {
        id: picker

        wallpaperModel:
            wallpaperModel

        currentWallpaper:
            root.currentWallpaper

        onWallpaperChosen:
            function(source) {
                root.setWallpaper(
                    source,
                    true
                )

                picker.close()
            }
    }
}
