import QtQuick
import Qt.labs.folderlistmodel

import Quickshell
import Quickshell.Io

Scope {
    id: root

    // ============================================================
    // HYPR-LAB WALLPAPER SETTINGS
    // ============================================================

    property string wallpaperDirectory:
        Quickshell.env("HOME") + "/.config/hypr/hyprlab-wpp"

    property url currentWallpaper: ""
    property int transitionEffect: 0

    // ============================================================
    // PERSISTENT WALLPAPER STATE
    // ============================================================

    readonly property string wallpaperStateDirectory:
        Quickshell.env("HOME") + "/.cache/hypr-lab"

    readonly property string wallpaperStateFile:
        wallpaperStateDirectory
        + "/current-wallpaper"

    // Addig nem választunk fallback képet,
    // amíg meg nem próbáltuk visszaolvasni
    // az előző session háttérképét.
    property bool stateReadFinished: false

    // ============================================================
    // TRANSITION EFFECTS
    // ============================================================

    // 0 = fade
    // 1 = zoom
    // 2 = slide right
    // 3 = slide left
    // 4 = slide bottom
    // 5 = slide top
    // 6 = brush wipe
    // 7 = falling tiles
    // 8 = soft spiral
    // 9 = silk wave

    readonly property int effectCount:
        10

    // ============================================================
    // WALLPAPER DIRECTORY
    // ============================================================

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

    // ============================================================
    // HELPERS
    // ============================================================

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

    // ============================================================
    // PERSIST CURRENT WALLPAPER
    // ============================================================

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

    // ============================================================
    // SET WALLPAPER
    // ============================================================

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

    // ============================================================
    // RANDOM WALLPAPER
    // ============================================================

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

    // ============================================================
    // INITIAL WALLPAPER FALLBACK
    // ============================================================

    function ensureInitialWallpaper(): void {
        // Előbb várjuk meg az előző session
        // háttérképének visszaolvasását.
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

        // Ha nincs előző háttérkép,
        // az első fájllal indulunk.
        transitionEffect = 0

        currentWallpaper =
            wallpaperAt(0)
    }

    // ============================================================
    // STATE WRITER
    // ============================================================

    Process {
        id: wallpaperStateWriter
    }

    // ============================================================
    // STATE READER
    // ============================================================

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
                    // Startupnál nincs animáció.
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

    // ============================================================
    // KEEP STATE FILE UPDATED
    // ============================================================

    onCurrentWallpaperChanged: {
        if (
            currentWallpaper
            && currentWallpaper.toString() !== ""
        ) {
            persistCurrentWallpaper()
        }
    }

    // Public helper a Control Centernek.
    function togglePicker(): void {
        picker.toggle()
    }

    // ============================================================
    // IPC
    // ============================================================

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

    // ============================================================
    // WALLPAPER MODEL READY
    // ============================================================

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

    // ============================================================
    // INITIAL LOAD
    // ============================================================

    Component.onCompleted: {
        // Először az előző session
        // háttérképét próbáljuk visszaállítani.
        wallpaperStateReader.running =
            true
    }

    // ============================================================
    // ONE WALLPAPER SURFACE PER MONITOR
    // ============================================================

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

    // ============================================================
    // HYPR-LAB WALLPAPER PICKER
    // ============================================================

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