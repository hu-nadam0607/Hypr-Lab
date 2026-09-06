//@ pragma AppId hypr-lab-files

import QtQuick
import Quickshell
import Quickshell.Io
import "components"

FloatingWindow {
    id: filesWindow

    title: "Hypr-Files"
    visible: true
    color: "transparent"
    implicitWidth: 1320
    implicitHeight: 780
    minimumSize: Qt.size(900, 560)

    readonly property string filesDir: Quickshell.env("HYPR_FILES_DIR") || ""
    readonly property string backend: filesDir + "/scripts/hypr-files-backend.py"
    readonly property string homePath: Quickshell.env("HOME") || "/"

    property string currentPath: homePath
    property var entries: []
    property var filteredEntries: []
    property var placeItems: []
    property var favoriteItems: []

    // Tabs. Each tab owns its path and navigation history; the active tab is
    // projected into currentPath/history so the existing file-view logic stays
    // simple and reliable.
    property var tabs: []
    property int activeTabIndex: 0
    property int hoveredTabIndex: -1

    // In-window entry drag state.  The delegate owns the pointer grab; the
    // window owns hit-testing and the drag ghost so it can cross clipped views.
    property bool folderDragActive: false
    property bool folderDragOverFavorites: false
    property int folderDragOverTabIndex: -1
    property string folderDragPath: ""
    property string folderDragName: ""
    property bool folderDragIsDir: false
    property var folderDragPaths: []
    property real folderDragX: 0
    property real folderDragY: 0

    property var pendingTransferPaths: []
    property int pendingTransferTabIndex: -1
    property string pendingTransferTargetPath: ""
    property string conflictTransferMode: ""
    property var conflictTransferPaths: []
    property string conflictTransferTargetPath: ""
    property bool conflictTransferRefreshAfter: false
    property var conflictTransferItems: []
    property var deviceItems: []
    property var externalDeviceItems: []
    property int keyboardCursorIndex: -1
    property var history: []
    property int historyIndex: -1

    property bool showHidden: false
    property bool gridMode: true
    property string searchText: ""
    property string sortKey: "name"
    property bool sortDescending: false
    property bool foldersFirst: true
    property int gridCellWidth: 165
    property int gridCellHeight: 145

    property var selectedPaths: ({})
    property var selectedEntries: []
    property var clipboardPaths: []
    property string clipboardMode: "copy"

    property var contextEntry: null
    property bool contextIsTrash: false
    property var openWithApps: []
    property var infoEntry: null
    property string statusMessage: ""
    property bool busy: false
    property bool operationProgressVisible: false
    property int operationProgressPercent: 0
    property string operationProgressLabel: ""
    property string operationProgressDetail: ""
    property bool operationProgressCancelling: false
    property var favoriteContextEntry: null
    property real scrollIndicatorOpacity: 0.0
    property real sidebarScrollIndicatorOpacity: 0.0

    // Rubber-band selection in the main file view. Mouse dragging on empty
    // space selects intersecting visible entries; scrolling remains wheel-only.
    property bool lassoActive: false
    property real lassoStartX: 0
    property real lassoStartY: 0
    property real lassoCurrentX: 0
    property real lassoCurrentY: 0
    property var lassoBaseSelection: ({})

    readonly property color surfaceColor: Qt.rgba(7/255, 11/255, 16/255, 0.97)
    readonly property color panelColor: Qt.rgba(11/255, 16/255, 22/255, 0.96)
    readonly property color cardColor: Qt.rgba(1, 1, 1, 0.026)
    readonly property color lineColor: Qt.rgba(1, 1, 1, 0.09)
    readonly property color textColor: "#edf0f2"
    readonly property color mutedColor: "#89949e"
    readonly property color accentColor: accentReader.accentColor

    function accent(alpha) {
        return Qt.rgba(accentColor.r, accentColor.g, accentColor.b, alpha)
    }

    function pathToUrl(path) {
        return "file://" + encodeURI(path)
    }

    function basename(path) {
        if (!path || path === "/") return "/"
        const clean = String(path).replace(/\/$/, "")
        const pos = clean.lastIndexOf("/")
        return pos >= 0 ? clean.substring(pos + 1) : clean
    }

    function parentPath(path) {
        if (!path || path === "/") return "/"
        const clean = String(path).replace(/\/$/, "")
        const pos = clean.lastIndexOf("/")
        return pos <= 0 ? "/" : clean.substring(0, pos)
    }

    function isSelected(path) {
        return selectedPaths[path] === true
    }

    function clearSelection() {
        selectedPaths = ({})
        keyboardCursorIndex = -1
        selectedEntries = []
        infoEntry = null
    }

    function rebuildSelectedEntries() {
        const result = []
        for (let item of entries) {
            if (selectedPaths[item.path] === true)
                result.push(item)
        }
        selectedEntries = result
        infoEntry = result.length === 1 ? result[0] : null
    }

    function selectEntry(entry, modifiers) {
        const ctrl = (modifiers & Qt.ControlModifier) !== 0
        const shift = (modifiers & Qt.ShiftModifier) !== 0
        let next = Object.assign({}, selectedPaths)

        if (!ctrl && !shift)
            next = ({})

        if (ctrl && next[entry.path] === true)
            delete next[entry.path]
        else
            next[entry.path] = true

        selectedPaths = next
        rebuildSelectedEntries()
    }

    function selectAll() {
        const next = ({})
        for (let item of filteredEntries)
            next[item.path] = true
        selectedPaths = next
        rebuildSelectedEntries()
    }

    function lassoRect() {
        const x1 = Math.min(lassoStartX, lassoCurrentX)
        const y1 = Math.min(lassoStartY, lassoCurrentY)
        const x2 = Math.max(lassoStartX, lassoCurrentX)
        const y2 = Math.max(lassoStartY, lassoCurrentY)
        return Qt.rect(x1, y1, x2 - x1, y2 - y1)
    }

    function rectsIntersect(a, b) {
        return a.x < b.x + b.width && a.x + a.width > b.x
            && a.y < b.y + b.height && a.y + a.height > b.y
    }

    function updateLassoSelection() {
        if (!lassoActive) return
        const next = Object.assign({}, lassoBaseSelection)
        const r = lassoRect()
        const view = gridMode ? gridView : listView
        const kids = view.contentItem ? view.contentItem.children : []
        for (let i = 0; i < kids.length; ++i) {
            const item = kids[i]
            if (!item || !item.entry || !item.entry.path || !item.visible) continue
            const pt = item.mapToItem(contentArea, 0, 0)
            const ir = Qt.rect(pt.x, pt.y, item.width, item.height)
            if (rectsIntersect(r, ir)) next[item.entry.path] = true
        }
        selectedPaths = next
        rebuildSelectedEntries()
    }

    function applyFilter() {
        const needle = searchText.trim().toLowerCase()
        if (!needle) {
            filteredEntries = entries.slice()
            return
        }
        filteredEntries = entries.filter(e => String(e.name).toLowerCase().indexOf(needle) >= 0)
    }

    function tabTitle(path) {
        const name = basename(path)
        return name === "/" ? "/" : (name || path)
    }

    function syncActiveTab() {
        if (tabs.length === 0 || activeTabIndex < 0 || activeTabIndex >= tabs.length) return
        const next = tabs.slice()
        next[activeTabIndex] = {
            path: currentPath,
            history: history.slice(),
            historyIndex: historyIndex
        }
        tabs = next
    }

    function openNewTab() {
        syncActiveTab()
        const next = tabs.slice()
        next.push({ path: homePath, history: [homePath], historyIndex: 0 })
        tabs = next
        switchTab(next.length - 1)
    }

    function switchTab(index) {
        if (index < 0 || index >= tabs.length || index === activeTabIndex) return
        syncActiveTab()
        activeTabIndex = index
        const tab = tabs[index]
        currentPath = tab.path
        history = (tab.history || [tab.path]).slice()
        historyIndex = tab.historyIndex === undefined ? history.length - 1 : tab.historyIndex
        clearSelection()
        contextMenu.visible = false
        favoriteMenu.visible = false
        sortMenu.visible = false
        openWithMenu.visible = false
        searchText = ""
        searchInput.text = ""
        pathInput.text = currentPath
        refresh()
    }

    function closeTab(index) {
        if (tabs.length <= 1 || index < 0 || index >= tabs.length) return
        syncActiveTab()
        const wasActive = index === activeTabIndex
        const next = tabs.slice()
        next.splice(index, 1)
        tabs = next
        if (index < activeTabIndex) activeTabIndex--
        if (wasActive) {
            activeTabIndex = Math.min(index, next.length - 1)
            const tab = next[activeTabIndex]
            currentPath = tab.path
            history = (tab.history || [tab.path]).slice()
            historyIndex = tab.historyIndex === undefined ? history.length - 1 : tab.historyIndex
            clearSelection()
            searchText = ""
            searchInput.text = ""
            pathInput.text = currentPath
            refresh()
        }
        hoveredTabIndex = -1
    }

    function closeContextTab() {
        closeTab(hoveredTabIndex >= 0 ? hoveredTabIndex : activeTabIndex)
    }

    function navigate(path, pushHistory) {
        if (!path || String(path).length === 0) return
        let target = String(path)
        if (target.startsWith("~")) target = homePath + target.substring(1)
        currentPath = target
        clearSelection()
        contextMenu.visible = false
        sortMenu.visible = false
        openWithMenu.visible = false
        searchText = ""
        searchInput.text = ""
        pathInput.text = target

        if (pushHistory !== false) {
            if (historyIndex < history.length - 1)
                history = history.slice(0, historyIndex + 1)
            history.push(target)
            historyIndex = history.length - 1
        }
        syncActiveTab()
        refresh()
    }

    function goBack() {
        if (historyIndex <= 0) return
        historyIndex--
        navigate(history[historyIndex], false)
    }

    function goForward() {
        if (historyIndex < 0 || historyIndex >= history.length - 1) return
        historyIndex++
        navigate(history[historyIndex], false)
    }

    function goUp() { navigate(parentPath(currentPath), true) }

    function refresh() {
        if (!backend || listProcess.running) return
        busy = true
        listProcess.command = [backend, "list", currentPath, showHidden ? "1" : "0", sortKey, sortDescending ? "1" : "0", foldersFirst ? "1" : "0"]
        listProcess.running = true
    }

    function runAction(args, refreshAfter) {
        if (actionProcess.running) return
        actionProcess.refreshAfter = refreshAfter === true
        actionProcess.receivedFinal = false
        operationProgressCancelling = false
        actionProcess.command = [backend].concat(args)
        actionProcess.running = true
    }

    function handleActionOutput(line) {
        const raw = String(line).trim()
        if (!raw) return
        try {
            const data = JSON.parse(raw)
            if (data.event === "progress") {
                progressHideTimer.stop()
                operationProgressVisible = true
                operationProgressPercent = Math.max(0, Math.min(100, Number(data.percent) || 0))
                operationProgressLabel = String(data.operation || "Working")
                operationProgressDetail = String(data.detail || "")
                return
            }
            if (data.ok === false) {
                actionProcess.receivedFinal = true
                statusMessage = data.error || "Operation failed"
                operationProgressVisible = false
                operationProgressCancelling = false
            } else {
                actionProcess.receivedFinal = true
                if (operationProgressVisible) {
                    operationProgressPercent = 100
                    progressHideTimer.restart()
                }
                operationProgressCancelling = false
                if (actionProcess.refreshAfter) refresh()
            }
        } catch (e) {
            // Ignore non-JSON diagnostic output; action completion still refreshes on exit.
        }
    }

    function cancelCurrentOperation() {
        if (!actionProcess.running) return
        operationProgressCancelling = true
        operationProgressLabel = "Cancelling"
        operationProgressDetail = ""
        statusMessage = "Cancelling operation…"
        actionProcess.running = false
    }

    function openEntry(entry) {
        if (!entry) return
        if (entry.isDir) navigate(entry.path, true)
        else runAction(["open", entry.path], false)
    }

    function keyboardNavigationEnabled() {
        return !pathInput.activeFocus && !searchInput.activeFocus
            && !renameInput.activeFocus && !newFolderInput.activeFocus
    }

    function selectKeyboardIndex(index) {
        const count = filteredEntries.length
        if (count <= 0) {
            keyboardCursorIndex = -1
            return
        }
        const next = Math.max(0, Math.min(count - 1, index))
        keyboardCursorIndex = next
        const entry = filteredEntries[next]
        selectedPaths = ({})
        selectedPaths[entry.path] = true
        selectedPaths = Object.assign({}, selectedPaths)
        rebuildSelectedEntries()
        Qt.callLater(function() {
            if (gridMode) gridView.positionViewAtIndex(next, GridView.Contain)
            else listView.positionViewAtIndex(next, ListView.Contain)
        })
    }

    function moveKeyboardCursor(dx, dy) {
        if (!keyboardNavigationEnabled() || filteredEntries.length === 0) return
        let idx = keyboardCursorIndex
        if (idx < 0) {
            if (selectedEntries.length === 1) {
                const wanted = selectedEntries[0].path
                idx = filteredEntries.findIndex(e => e.path === wanted)
            }
            if (idx < 0) idx = 0
        }
        if (gridMode) {
            const cols = Math.max(1, Math.floor(gridView.width / gridView.cellWidth))
            idx += dx + dy * cols
        } else {
            // List view is vertical; Up/Down move rows. Left goes to parent,
            // Right opens the selected directory (or file) like Enter.
            if (dx < 0) { goUp(); return }
            if (dx > 0) {
                const e = filteredEntries[idx]
                if (e) openEntry(e)
                return
            }
            idx += dy
        }
        selectKeyboardIndex(idx)
    }

    function activateKeyboardSelection() {
        if (!keyboardNavigationEnabled()) return
        let idx = keyboardCursorIndex
        if (idx < 0 && selectedEntries.length === 1)
            idx = filteredEntries.findIndex(e => e.path === selectedEntries[0].path)
        if (idx >= 0 && idx < filteredEntries.length) openEntry(filteredEntries[idx])
    }

    function runDeviceAction(action, block) {
        if (!backend || deviceActionProcess.running) return
        statusMessage = ""
        deviceActionProcess.command = [backend, "device-action", action, block]
        deviceActionProcess.running = true
    }

    function selectedPathArray() {
        return selectedEntries.map(e => e.path)
    }

    function cutSelection() {
        clipboardPaths = selectedPathArray()
        clipboardMode = "move"
        statusMessage = clipboardPaths.length + " item(s) cut"
    }

    function copySelection() {
        clipboardPaths = selectedPathArray()
        clipboardMode = "copy"
        statusMessage = clipboardPaths.length + " item(s) copied"
    }

    function pasteClipboard() {
        if (clipboardPaths.length === 0) return
        requestTransfer(clipboardMode, clipboardPaths.slice(), currentPath, true)
    }

    function trashSelection() {
        if (selectedEntries.length === 0) return
        runAction(["trash", JSON.stringify(selectedPathArray())], true)
    }

    function permanentDeleteSelection() {
        if (selectedEntries.length === 0) return
        confirmDelete.visible = true
    }

    function showContext(entry, x, y) {
        if (!isSelected(entry.path)) {
            selectedPaths = ({})
            selectedPaths[entry.path] = true
            selectedPaths = Object.assign({}, selectedPaths)
            rebuildSelectedEntries()
        }
        contextEntry = entry
        contextIsTrash = false
        contextMenu.x = Math.max(220, Math.min(shellRoot.width - contextMenu.width - 12, x))
        contextMenu.y = Math.max(52, Math.min(shellRoot.height - contextMenu.height - 36, y))
        contextMenu.visible = true
        sortMenu.visible = false
        openWithMenu.visible = false
    }

    function showTrashContext(x, y) {
        contextEntry = null
        contextIsTrash = true
        contextMenu.x = Math.max(12, Math.min(shellRoot.width - contextMenu.width - 12, x))
        contextMenu.y = Math.max(52, Math.min(shellRoot.height - contextMenu.height - 36, y))
        contextMenu.visible = true
        sortMenu.visible = false
        openWithMenu.visible = false
    }

    function emptyTrash() {
        contextMenu.visible = false
        confirmEmptyTrash.visible = true
    }

    function reloadSidebar() {
        if (!placesProcess.running)
            placesProcess.running = true
    }

    function pointInsideFavorites(x, y) {
        const p = favoritesDropArea.mapFromItem(shellRoot, x, y)
        return p.x >= 0 && p.y >= 0 && p.x <= favoritesDropArea.width && p.y <= favoritesDropArea.height
    }

    function tabAtPoint(x, y) {
        for (let i = 0; i < tabRepeater.count; ++i) {
            const item = tabRepeater.itemAt(i)
            if (!item) continue
            const p = item.mapFromItem(shellRoot, x, y)
            if (p.x >= 0 && p.y >= 0 && p.x <= item.width && p.y <= item.height)
                return i
        }
        return -1
    }

    function beginFolderDrag(entry, x, y) {
        if (!entry) return
        folderDragActive = true
        folderDragPath = String(entry.path)
        folderDragName = String(entry.name)
        folderDragIsDir = entry.isDir === true
        folderDragPaths = isSelected(entry.path) ? selectedPathArray() : [String(entry.path)]
        updateFolderDrag(entry, x, y)
    }

    function updateFolderDrag(entry, x, y) {
        if (!folderDragActive || !entry) return
        folderDragX = x
        folderDragY = y
        folderDragOverFavorites = folderDragIsDir && pointInsideFavorites(x, y)
        const tabIndex = tabAtPoint(x, y)
        folderDragOverTabIndex = tabIndex >= 0 && tabIndex !== activeTabIndex ? tabIndex : -1
    }

    function finishFolderDrag(entry, x, y) {
        if (!folderDragActive) return
        folderDragX = x
        folderDragY = y
        const favoriteAccept = folderDragIsDir && pointInsideFavorites(x, y)
        const targetTab = tabAtPoint(x, y)
        const path = entry ? String(entry.path) : folderDragPath
        const paths = folderDragPaths.slice()
        const wasDir = folderDragIsDir
        folderDragActive = false
        folderDragOverFavorites = false
        folderDragOverTabIndex = -1
        folderDragPath = ""
        folderDragName = ""
        folderDragIsDir = false
        folderDragPaths = []

        if (favoriteAccept && wasDir && path) {
            addFavorite(path)
            return
        }
        if (targetTab >= 0 && targetTab !== activeTabIndex && paths.length > 0) {
            pendingTransferPaths = paths
            pendingTransferTabIndex = targetTab
            pendingTransferTargetPath = tabs[targetTab].path
            transferDialog.visible = true
        }
    }

    function performPendingTransfer(mode) {
        if (pendingTransferPaths.length === 0 || !pendingTransferTargetPath) {
            cancelPendingTransfer()
            return
        }
        const paths = pendingTransferPaths.slice()
        const target = pendingTransferTargetPath
        cancelPendingTransfer()
        requestTransfer(mode, paths, target, mode === "move")
        statusMessage = mode === "move" ? "Moving to tab…" : "Copying to tab…"
    }

    function requestTransfer(mode, paths, target, refreshAfter) {
        if (!backend || conflictCheckProcess.running || actionProcess.running || paths.length === 0 || !target) return
        conflictTransferMode = mode
        conflictTransferPaths = paths.slice()
        conflictTransferTargetPath = target
        conflictTransferRefreshAfter = refreshAfter === true
        conflictTransferItems = []
        conflictCheckProcess.command = [backend, "check-transfer", JSON.stringify(paths), target]
        conflictCheckProcess.running = true
    }

    function executeConflictTransfer(policy) {
        conflictDialog.visible = false
        const mode = conflictTransferMode
        const paths = conflictTransferPaths.slice()
        const target = conflictTransferTargetPath
        const refreshAfter = conflictTransferRefreshAfter
        conflictTransferItems = []
        conflictTransferMode = ""
        conflictTransferPaths = []
        conflictTransferTargetPath = ""
        conflictTransferRefreshAfter = false
        runAction(["transfer", mode, JSON.stringify(paths), target, policy], refreshAfter)
        if (mode === "move" && policy !== "skip") clipboardPaths = []
    }

    function cancelConflictTransfer() {
        conflictDialog.visible = false
        conflictTransferItems = []
        conflictTransferMode = ""
        conflictTransferPaths = []
        conflictTransferTargetPath = ""
        conflictTransferRefreshAfter = false
        statusMessage = "Transfer cancelled"
    }

    function cancelPendingTransfer() {
        transferDialog.visible = false
        pendingTransferPaths = []
        pendingTransferTabIndex = -1
        pendingTransferTargetPath = ""
    }

    function addFavorite(path) {
        if (!path || favoriteProcess.running) return
        favoriteProcess.command = [backend, "favorite-add", String(path)]
        favoriteProcess.running = true
    }

    function removeFavorite(path) {
        if (!path || favoriteProcess.running) return
        favoriteMenu.visible = false
        favoriteProcess.command = [backend, "favorite-remove", String(path)]
        favoriteProcess.running = true
    }

    function showFavoriteContext(entry, x, y) {
        favoriteContextEntry = entry
        favoriteMenu.x = Math.max(12, Math.min(shellRoot.width - favoriteMenu.width - 12, x))
        favoriteMenu.y = Math.max(52, Math.min(shellRoot.height - favoriteMenu.height - 36, y))
        favoriteMenu.visible = true
        contextMenu.visible = false
        sortMenu.visible = false
        openWithMenu.visible = false
    }

    function showScrollIndicator() {
        const view = gridMode ? gridView : listView
        if (!view || view.contentHeight <= view.height + 1) {
            scrollIndicatorOpacity = 0.0
            return
        }
        scrollIndicatorOpacity = 1.0
        scrollHideTimer.restart()
    }

    function scrollBy(amount) {
        const view = gridMode ? gridView : listView
        const maxY = Math.max(0, view.contentHeight - view.height)
        view.contentY = Math.max(0, Math.min(maxY, view.contentY + amount))
        showScrollIndicator()
    }

    function showSidebarScrollIndicator() {
        if (sidebarFlick.contentHeight <= sidebarFlick.height + 1) {
            sidebarScrollIndicatorOpacity = 0.0
            return
        }
        sidebarScrollIndicatorOpacity = 1.0
        sidebarScrollHideTimer.restart()
    }

    function scrollSidebarBy(amount) {
        const maxY = Math.max(0, sidebarFlick.contentHeight - sidebarFlick.height)
        sidebarFlick.contentY = Math.max(0, Math.min(maxY, sidebarFlick.contentY + amount))
        showSidebarScrollIndicator()
    }

    function archiveSelection(format) {
        if (selectedEntries.length === 0) return
        contextMenu.visible = false
        runAction(["archive", format, JSON.stringify(selectedPathArray()), currentPath], true)
    }

    function isArchive(entry) {
        if (!entry || entry.isDir) return false
        const n = String(entry.name).toLowerCase()
        return n.endsWith(".zip") || n.endsWith(".tar") || n.endsWith(".tar.gz") || n.endsWith(".tgz") || n.endsWith(".tar.xz") || n.endsWith(".txz") || n.endsWith(".tar.bz2") || n.endsWith(".tbz2")
    }

    function extractContextArchive() {
        if (!isArchive(contextEntry)) return
        const archivePath = contextEntry.path
        contextMenu.visible = false
        runAction(["extract", archivePath, currentPath], true)
    }

    function requestOpenWith() {
        if (!contextEntry || contextEntry.isDir || appsProcess.running) return
        openWithApps = []
        appsProcess.command = [backend, "apps", contextEntry.mime]
        appsProcess.running = true
    }

    function openTerminalHere(entry) {
        const target = entry ? entry.path : currentPath
        runAction(["terminal", target], false)
    }

    function beginRename() {
        if (selectedEntries.length !== 1) return
        renameInput.text = selectedEntries[0].name
        renameDialog.visible = true
        renameInput.forceActiveFocus()
        renameInput.selectAll()
    }

    function completeRename() {
        if (selectedEntries.length !== 1) return
        const name = renameInput.text.trim()
        if (!name) return
        renameDialog.visible = false
        runAction(["rename", selectedEntries[0].path, name], true)
    }

    function beginNewFolder() {
        newFolderInput.text = "New Folder"
        newFolderDialog.visible = true
        newFolderInput.forceActiveFocus()
        newFolderInput.selectAll()
    }

    function completeNewFolder() {
        const name = newFolderInput.text.trim()
        if (!name) return
        newFolderDialog.visible = false
        runAction(["new-folder", currentPath, name], true)
    }

    AdaptiveAccent { id: accentReader }

    Process {
        id: listProcess
        stdout: StdioCollector {
            onStreamFinished: {
                filesWindow.busy = false
                try {
                    const data = JSON.parse(text)
                    if (data.ok === false) {
                        filesWindow.statusMessage = data.error || "Unable to read folder"
                        filesWindow.entries = []
                    } else {
                        if (String(data.path) !== String(filesWindow.currentPath)) {
                            Qt.callLater(function() { filesWindow.refresh() })
                            return
                        }
                        filesWindow.currentPath = data.path
                        pathInput.text = data.path
                        filesWindow.entries = data.items || []
                        filesWindow.statusMessage = ""
                        filesWindow.syncActiveTab()
                    }
                } catch (e) {
                    filesWindow.entries = []
                    filesWindow.statusMessage = "Invalid folder response"
                }
                filesWindow.clearSelection()
                filesWindow.applyFilter()
            }
        }
    }

    Process {
        id: placesProcess
        command: [backend, "places"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    filesWindow.placeItems = data.places || []
                    filesWindow.favoriteItems = data.favorites || []
                    filesWindow.deviceItems = data.devices || []
                    filesWindow.externalDeviceItems = data.externalDevices || []
                } catch (e) {}
            }
        }
    }

    Process {
        id: favoriteProcess
        stdout: StdioCollector {
            onStreamFinished: filesWindow.reloadSidebar()
        }
    }

    Process {
        id: deviceActionProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    filesWindow.statusMessage = data.ok === false ? (data.error || "Device action failed") : (data.message || "")
                } catch (e) {}
                Qt.callLater(function() { filesWindow.reloadSidebar() })
            }
        }
    }

    Process {
        id: conflictCheckProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    if (data.ok === false) {
                        filesWindow.statusMessage = data.error || "Unable to check destination"
                        filesWindow.cancelConflictTransfer()
                        return
                    }
                    filesWindow.conflictTransferItems = data.conflicts || []
                    if (filesWindow.conflictTransferItems.length > 0)
                        conflictDialog.visible = true
                    else
                        filesWindow.executeConflictTransfer("rename")
                } catch (e) {
                    filesWindow.statusMessage = "Unable to check destination"
                    filesWindow.cancelConflictTransfer()
                }
            }
        }
    }

    Process {
        id: actionProcess
        property bool refreshAfter: false
        property bool receivedFinal: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => filesWindow.handleActionOutput(data)
        }
        onRunningChanged: {
            if (!running && filesWindow.operationProgressCancelling) {
                filesWindow.operationProgressVisible = false
                filesWindow.operationProgressPercent = 0
                filesWindow.operationProgressLabel = ""
                filesWindow.operationProgressDetail = ""
                filesWindow.operationProgressCancelling = false
                filesWindow.statusMessage = "Operation cancelled"
                if (actionProcess.refreshAfter) Qt.callLater(function() { filesWindow.refresh() })
                return
            }
            if (!running && actionProcess.refreshAfter && !actionProcess.receivedFinal)
                filesWindow.refresh()
        }
    }

    Timer {
        id: progressHideTimer
        interval: 900
        repeat: false
        onTriggered: {
            filesWindow.operationProgressVisible = false
            filesWindow.operationProgressPercent = 0
            filesWindow.operationProgressLabel = ""
            filesWindow.operationProgressDetail = ""
        }
    }

    Process {
        id: appsProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    filesWindow.openWithApps = data.apps || []
                    contextMenu.visible = false
                    openWithMenu.x = Math.min(shellRoot.width - openWithMenu.width - 12, contextMenu.x + 18)
                    openWithMenu.y = Math.min(shellRoot.height - openWithMenu.height - 36, contextMenu.y + 28)
                    openWithMenu.visible = true
                } catch (e) {}
            }
        }
    }

    Timer {
        id: scrollHideTimer
        interval: 1400
        repeat: false
        onTriggered: filesWindow.scrollIndicatorOpacity = 0.0
    }

    Timer {
        id: sidebarScrollHideTimer
        interval: 1400
        repeat: false
        onTriggered: filesWindow.sidebarScrollIndicatorOpacity = 0.0
    }

    Timer {
        id: externalDeviceRefreshTimer
        interval: 2000
        repeat: true
        running: true
        onTriggered: filesWindow.reloadSidebar()
    }

    Component.onCompleted: {
        placesProcess.running = true
        const start = Quickshell.env("HYPR_FILES_START_PATH") || homePath
        history = [start]
        historyIndex = 0
        currentPath = start
        tabs = [{ path: start, history: [start], historyIndex: 0 }]
        activeTabIndex = 0
        pathInput.text = start
        refresh()
    }

    Shortcut { sequence: "Ctrl+H"; onActivated: { showHidden = !showHidden; refresh() } }
    Shortcut { sequence: "Ctrl+R"; onActivated: refresh() }
    Shortcut { sequence: "Ctrl+F"; onActivated: searchInput.forceActiveFocus() }
    Shortcut { sequence: "Ctrl+L"; onActivated: { pathInput.forceActiveFocus(); pathInput.selectAll() } }
    Shortcut { sequence: "Ctrl+A"; onActivated: selectAll() }
    Shortcut { sequence: "Ctrl+C"; onActivated: copySelection() }
    Shortcut { sequence: "Ctrl+X"; onActivated: cutSelection() }
    Shortcut { sequence: "Ctrl+V"; onActivated: pasteClipboard() }
    Shortcut { sequence: "F2"; onActivated: beginRename() }
    Shortcut { sequence: "Delete"; onActivated: trashSelection() }
    Shortcut { sequence: "Shift+Delete"; onActivated: permanentDeleteSelection() }
    Shortcut { sequence: "Alt+Left"; onActivated: goBack() }
    Shortcut { sequence: "Alt+Right"; onActivated: goForward() }
    Shortcut { sequence: "Alt+Up"; onActivated: goUp() }
    Shortcut { sequence: "Backspace"; onActivated: goBack() }
    Shortcut { sequence: "Ctrl+Shift+N"; onActivated: beginNewFolder() }
    Shortcut { sequence: "Ctrl+T"; onActivated: openNewTab() }
    Shortcut { sequence: "Ctrl+W"; onActivated: closeContextTab() }
    Shortcut { sequence: "Left"; enabled: filesWindow.keyboardNavigationEnabled(); onActivated: filesWindow.moveKeyboardCursor(-1, 0) }
    Shortcut { sequence: "Right"; enabled: filesWindow.keyboardNavigationEnabled(); onActivated: filesWindow.moveKeyboardCursor(1, 0) }
    Shortcut { sequence: "Up"; enabled: filesWindow.keyboardNavigationEnabled(); onActivated: filesWindow.moveKeyboardCursor(0, -1) }
    Shortcut { sequence: "Down"; enabled: filesWindow.keyboardNavigationEnabled(); onActivated: filesWindow.moveKeyboardCursor(0, 1) }
    Shortcut { sequence: "Return"; enabled: filesWindow.keyboardNavigationEnabled(); onActivated: filesWindow.activateKeyboardSelection() }
    Shortcut { sequence: "Enter"; enabled: filesWindow.keyboardNavigationEnabled(); onActivated: filesWindow.activateKeyboardSelection() }

    Rectangle {
        id: shellRoot
        anchors.fill: parent
        color: filesWindow.surfaceColor
        border.width: 1
        border.color: filesWindow.accentColor
        radius: 0
        focus: true


        Rectangle {
            id: sidebar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: statusBar.top
            width: 210
            color: filesWindow.panelColor
            border.width: 0
            radius: 0

            Flickable {
                id: sidebarFlick
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.topMargin: 14
                anchors.bottomMargin: 14
                anchors.rightMargin: 28
                clip: true
                onMovementStarted: filesWindow.showSidebarScrollIndicator()
                onMovementEnded: filesWindow.showSidebarScrollIndicator()
                onContentYChanged: filesWindow.showSidebarScrollIndicator()
                contentWidth: width
                contentHeight: sidebarColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: sidebarColumn
                    width: sidebarFlick.width
                    spacing: 7

                    Row {
                        width: parent.width
                        height: 50
                        spacing: 10
                        Rectangle {
                            width: 34; height: 34
                            anchors.verticalCenter: parent.verticalCenter
                            color: filesWindow.accentColor
                            radius: 0
                            Text { anchors.centerIn: parent; text: "󰉋"; color: "#10161c"; font.pixelSize: 21 }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text { text: "Hypr-Files"; color: filesWindow.textColor; font.pixelSize: 15; font.weight: Font.DemiBold }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: filesWindow.lineColor }
                    Text { text: "PLACES"; color: filesWindow.mutedColor; font.pixelSize: 9; font.weight: Font.DemiBold }

                    ListView {
                        id: placesView
                        width: parent.width
                        height: contentHeight
                        model: filesWindow.placeItems.length
                        interactive: false
                        spacing: 1
                        delegate: SidebarItem {
                            width: placesView.width
                            labelText: filesWindow.placeItems[index].label
                            iconText: filesWindow.placeItems[index].icon
                            path: filesWindow.placeItems[index].path
                            accentColor: filesWindow.accentColor
                            active: filesWindow.currentPath === filesWindow.placeItems[index].path
                            onActivated: p => filesWindow.navigate(p, true)
                            onContextRequested: function(x, y) {
                                if (filesWindow.placeItems[index].label === "Trash") {
                                    const pt = mapToItem(shellRoot, x, y)
                                    filesWindow.showTrashContext(pt.x, pt.y)
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width; height: 9
                        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; height: 1; color: filesWindow.lineColor }
                    }

                    Row {
                        width: parent.width
                        height: 16
                        Text { text: "FAVORITES"; color: filesWindow.mutedColor; font.pixelSize: 9; font.weight: Font.DemiBold }
                        Item { width: 1; height: 1 }
                    }

                    DropArea {
                        id: favoritesDropArea
                        width: parent.width
                        height: Math.max(44, favoritesView.contentHeight)
                        keys: ["hypr-files-folder"]

                        Rectangle {
                            anchors.fill: parent
                            color: (favoritesDropArea.containsDrag || filesWindow.folderDragOverFavorites) ? filesWindow.accent(0.08) : "transparent"
                            border.width: (favoritesDropArea.containsDrag || filesWindow.folderDragOverFavorites) ? 1 : 0
                            border.color: filesWindow.accentColor
                            radius: 0

                            Text {
                                anchors.centerIn: parent
                                visible: filesWindow.favoriteItems.length === 0
                                text: (favoritesDropArea.containsDrag || filesWindow.folderDragOverFavorites) ? "Drop folder here" : "Drag folders here"
                                color: (favoritesDropArea.containsDrag || filesWindow.folderDragOverFavorites) ? filesWindow.accentColor : "#66717a"
                                font.pixelSize: 10
                                font.italic: true
                            }
                        }

                        ListView {
                            id: favoritesView
                            anchors.fill: parent
                            height: contentHeight
                            model: filesWindow.favoriteItems.length
                            interactive: false
                            spacing: 1
                            delegate: SidebarItem {
                                width: favoritesView.width
                                labelText: filesWindow.favoriteItems[index].label
                                iconText: "󰉋"
                                path: filesWindow.favoriteItems[index].path
                                accentColor: filesWindow.accentColor
                                active: filesWindow.currentPath === filesWindow.favoriteItems[index].path
                                onActivated: p => filesWindow.navigate(p, true)
                                onContextRequested: function(x, y) {
                                    const pt = mapToItem(shellRoot, x, y)
                                    filesWindow.showFavoriteContext(filesWindow.favoriteItems[index], pt.x, pt.y)
                                }
                            }
                        }

                        onDropped: function(drop) {
                            let path = ""

                            // For in-app Qt Quick drags, Drag.source is the
                            // most reliable source of the directory entry.
                            try {
                                if (drop.source && drop.source.entry && drop.source.entry.isDir)
                                    path = String(drop.source.entry.path)
                            } catch (e) {}

                            // MIME fallback also keeps this compatible with
                            // new-style/automatic drag events.
                            if (!path) {
                                try { path = drop.getDataAsString("text/plain") } catch (e) {}
                            }

                            if (path && path.length > 0) {
                                filesWindow.addFavorite(path)
                                drop.acceptProposedAction()
                            } else {
                                drop.accepted = false
                            }
                        }
                    }

                    Item {
                        width: parent.width; height: 9
                        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; height: 1; color: filesWindow.lineColor }
                    }
                    Text { text: "DEVICES"; color: filesWindow.mutedColor; font.pixelSize: 9; font.weight: Font.DemiBold }

                    ListView {
                        id: devicesView
                        width: parent.width
                        height: contentHeight
                        model: filesWindow.deviceItems.length
                        interactive: false
                        spacing: 1
                        delegate: SidebarItem {
                            width: devicesView.width
                            labelText: filesWindow.deviceItems[index].label
                            secondaryText: filesWindow.deviceItems[index].secondary || ""
                            iconText: filesWindow.deviceItems[index].icon
                            path: filesWindow.deviceItems[index].path
                            accentColor: filesWindow.accentColor
                            active: filesWindow.currentPath === filesWindow.deviceItems[index].path
                            onActivated: p => filesWindow.navigate(p, true)
                        }
                    }


                    Item {
                        visible: filesWindow.externalDeviceItems.length > 0
                        width: parent.width
                        height: visible ? 9 : 0
                        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; height: 1; color: filesWindow.lineColor }
                    }
                    Text {
                        visible: filesWindow.externalDeviceItems.length > 0
                        text: "EXTERNAL DEVICES"
                        color: filesWindow.mutedColor
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }

                    Column {
                        id: externalDevicesColumn
                        visible: filesWindow.externalDeviceItems.length > 0
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: filesWindow.externalDeviceItems.length
                            delegate: Column {
                                required property int index
                                width: externalDevicesColumn.width
                                spacing: 2
                                readonly property var dev: filesWindow.externalDeviceItems[index]

                                Rectangle {
                                    width: parent.width
                                    height: 42
                                    color: "transparent"
                                    Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: filesWindow.lineColor }
                                    Text {
                                        anchors.left: parent.left; anchors.right: ejectButton.left; anchors.rightMargin: 5; anchors.top: parent.top; anchors.topMargin: 6
                                        text: dev.label + (dev.secondary ? " · " + dev.secondary : "")
                                        color: filesWindow.textColor; font.pixelSize: 10; font.weight: Font.DemiBold; elide: Text.ElideRight
                                    }
                                    Text {
                                        anchors.left: parent.left; anchors.right: ejectButton.left; anchors.rightMargin: 5; anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                                        text: dev.block
                                        color: filesWindow.mutedColor; font.pixelSize: 8; elide: Text.ElideMiddle
                                    }
                                    Rectangle {
                                        id: ejectButton
                                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        width: 46; height: 24
                                        color: ejectMouse.containsMouse ? filesWindow.accent(0.11) : filesWindow.cardColor
                                        border.width: 1; border.color: filesWindow.lineColor
                                        Text { anchors.centerIn: parent; text: "EJECT"; color: filesWindow.accentColor; font.pixelSize: 8; font.weight: Font.DemiBold }
                                        MouseArea { id: ejectMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: filesWindow.runDeviceAction("eject", dev.block) }
                                    }
                                }

                                Repeater {
                                    model: dev.partitions ? dev.partitions.length : 0
                                    delegate: Rectangle {
                                        required property int index
                                        width: parent.width
                                        height: 47
                                        color: partMouse.containsMouse ? filesWindow.accent(0.06) : "transparent"
                                        readonly property var part: dev.partitions[index]

                                        Text { anchors.left: parent.left; anchors.leftMargin: 9; anchors.top: parent.top; anchors.topMargin: 6; text: "󰋊"; color: filesWindow.mutedColor; font.pixelSize: 13 }
                                        Text {
                                            anchors.left: parent.left; anchors.leftMargin: 30; anchors.right: partButton.left; anchors.rightMargin: 5; anchors.top: parent.top; anchors.topMargin: 5
                                            text: part.label
                                            color: filesWindow.textColor; font.pixelSize: 10; elide: Text.ElideRight
                                        }
                                        Text {
                                            anchors.left: parent.left; anchors.leftMargin: 30; anchors.right: partButton.left; anchors.rightMargin: 5; anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                                            text: part.secondary
                                            color: filesWindow.mutedColor; font.pixelSize: 8; elide: Text.ElideMiddle
                                        }
                                        Rectangle {
                                            id: partButton
                                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                            width: 58; height: 24
                                            color: partButtonMouse.containsMouse ? filesWindow.accent(0.11) : filesWindow.cardColor
                                            border.width: 1; border.color: filesWindow.lineColor
                                            Text { anchors.centerIn: parent; text: part.mounted ? "UNMOUNT" : "MOUNT"; color: filesWindow.accentColor; font.pixelSize: 8; font.weight: Font.DemiBold }
                                            MouseArea {
                                                id: partButtonMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: filesWindow.runDeviceAction(part.mounted ? "unmount" : "mount", part.block)
                                            }
                                        }
                                        MouseArea {
                                            id: partMouse
                                            anchors.left: parent.left; anchors.right: partButton.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                                            hoverEnabled: true; cursorShape: part.mounted ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onDoubleClicked: { if (part.mounted && part.path) filesWindow.navigate(part.path, true) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: sidebarScrollControl
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                width: 20
                z: 20

                readonly property real maxY: Math.max(0, sidebarFlick.contentHeight - sidebarFlick.height)
                readonly property bool canScroll: maxY > 1

                Rectangle {
                    id: sidebarUpButton
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 20; height: 22
                    color: sidebarUpMouse.containsMouse ? filesWindow.accent(0.10) : "transparent"
                    Text { anchors.centerIn: parent; text: "󰅃"; color: filesWindow.mutedColor; font.pixelSize: 13 }
                    MouseArea {
                        id: sidebarUpMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: filesWindow.scrollSidebarBy(-80)
                    }
                }

                Item {
                    id: sidebarScrollTrack
                    anchors.top: sidebarUpButton.bottom
                    anchors.topMargin: 5
                    anchors.bottom: sidebarDownButton.top
                    anchors.bottomMargin: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 8
                    opacity: sidebarScrollControl.canScroll ? filesWindow.sidebarScrollIndicatorOpacity : 0.0
                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 2; height: parent.height; color: filesWindow.accent(0.18) }
                    Rectangle {
                        id: sidebarScrollThumb
                        readonly property real h: Math.max(28, sidebarScrollTrack.height * Math.min(1, sidebarFlick.height / Math.max(sidebarFlick.contentHeight, 1)))
                        width: 6; height: h; x: 1
                        y: sidebarScrollControl.maxY <= 0 ? 0 : (sidebarFlick.contentY / sidebarScrollControl.maxY) * Math.max(0, sidebarScrollTrack.height - h)
                        color: filesWindow.accentColor
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: function(mouse) {
                            const usable = Math.max(1, sidebarScrollTrack.height - sidebarScrollThumb.height)
                            const y = Math.max(0, Math.min(usable, mouse.y - sidebarScrollThumb.height / 2))
                            sidebarFlick.contentY = (y / usable) * sidebarScrollControl.maxY
                            filesWindow.showSidebarScrollIndicator()
                        }
                        onPositionChanged: function(mouse) {
                            if (!pressed) return
                            const usable = Math.max(1, sidebarScrollTrack.height - sidebarScrollThumb.height)
                            const y = Math.max(0, Math.min(usable, mouse.y - sidebarScrollThumb.height / 2))
                            sidebarFlick.contentY = (y / usable) * sidebarScrollControl.maxY
                            filesWindow.showSidebarScrollIndicator()
                        }
                    }
                }

                Rectangle {
                    id: sidebarDownButton
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 20; height: 22
                    color: sidebarDownMouse.containsMouse ? filesWindow.accent(0.10) : "transparent"
                    Text { anchors.centerIn: parent; text: "󰅀"; color: filesWindow.mutedColor; font.pixelSize: 13 }
                    MouseArea {
                        id: sidebarDownMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: filesWindow.scrollSidebarBy(80)
                    }
                }
            }
        }

        Item {
            id: folderDragGhost
            visible: filesWindow.folderDragActive
            x: Math.max(8, Math.min(shellRoot.width - width - 8, filesWindow.folderDragX + 14))
            y: Math.max(8, Math.min(shellRoot.height - height - 8, filesWindow.folderDragY + 14))
            width: 126
            height: 70
            z: 1000
            opacity: (filesWindow.folderDragOverFavorites || filesWindow.folderDragOverTabIndex >= 0) ? 1.0 : 0.90

            Behavior on opacity { NumberAnimation { duration: 100 } }

            Rectangle {
                anchors.fill: parent
                color: (filesWindow.folderDragOverFavorites || filesWindow.folderDragOverTabIndex >= 0) ? filesWindow.accent(0.16) : Qt.rgba(0.035, 0.045, 0.055, 0.94)
                border.width: 1
                border.color: (filesWindow.folderDragOverFavorites || filesWindow.folderDragOverTabIndex >= 0) ? filesWindow.accentColor : filesWindow.lineColor
                radius: 0
            }
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: filesWindow.folderDragIsDir ? "󰉋" : "󰈔"
                color: filesWindow.folderDragIsDir ? filesWindow.accentColor : "#d8dde2"
                font.pixelSize: 32
            }
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 54
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: filesWindow.folderDragName
                color: filesWindow.textColor
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: toolbar
            anchors.left: sidebar.right
            anchors.right: infoPanel.left
            anchors.top: parent.top
            height: 62
            color: filesWindow.surfaceColor
            border.width: 0
            radius: 0

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 14
                spacing: 8

                component ToolButton: Rectangle {
                    property string glyph: ""
                    property string tip: ""
                    signal triggered()
                    width: 34; height: 34
                    anchors.verticalCenter: parent.verticalCenter
                    color: toolMouse.containsMouse ? filesWindow.accent(0.13) : filesWindow.cardColor
                    border.width: 1
                    border.color: toolMouse.containsMouse ? filesWindow.accentColor : filesWindow.lineColor
                    radius: 0
                    Text { anchors.centerIn: parent; text: parent.glyph; color: toolMouse.containsMouse ? filesWindow.accentColor : "#cad1d7"; font.pixelSize: 16 }
                    MouseArea { id: toolMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.triggered() }
                }

                ToolButton { glyph: "󰁍"; onTriggered: filesWindow.goBack() }
                ToolButton { glyph: "󰁔"; onTriggered: filesWindow.goForward() }
                ToolButton { glyph: "󰁞"; onTriggered: filesWindow.goUp() }
                ToolButton { glyph: "󰋜"; onTriggered: filesWindow.navigate(filesWindow.homePath, true) }

                Rectangle {
                    width: Math.max(240, toolbar.width - 570)
                    height: 34
                    anchors.verticalCenter: parent.verticalCenter
                    color: filesWindow.cardColor
                    border.width: 1
                    border.color: pathInput.activeFocus ? filesWindow.accentColor : filesWindow.lineColor
                    radius: 0
                    TextInput {
                        id: pathInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: filesWindow.textColor
                        selectionColor: filesWindow.accent(0.45)
                        selectedTextColor: filesWindow.textColor
                        font.pixelSize: 11
                        clip: true
                        onAccepted: filesWindow.navigate(text, true)
                    }
                }

                Rectangle {
                    width: 190; height: 34
                    anchors.verticalCenter: parent.verticalCenter
                    color: filesWindow.cardColor
                    border.width: 1
                    border.color: searchInput.activeFocus ? filesWindow.accentColor : filesWindow.lineColor
                    radius: 0
                    Text { anchors.left: parent.left; anchors.leftMargin: 9; anchors.verticalCenter: parent.verticalCenter; text: "󰍉"; color: filesWindow.mutedColor; font.pixelSize: 14 }
                    TextInput {
                        id: searchInput
                        anchors.left: parent.left; anchors.leftMargin: 30
                        anchors.right: parent.right; anchors.rightMargin: 8
                        anchors.top: parent.top; anchors.bottom: parent.bottom
                        verticalAlignment: TextInput.AlignVCenter
                        color: filesWindow.textColor
                        font.pixelSize: 10
                        clip: true
                        onTextChanged: { filesWindow.searchText = text; filesWindow.applyFilter() }
                    }
                    Text { anchors.left: parent.left; anchors.leftMargin: 31; anchors.verticalCenter: parent.verticalCenter; visible: searchInput.text.length === 0; text: "Search this folder..."; color: "#59636c"; font.pixelSize: 10 }
                }

                ToolButton { glyph: filesWindow.gridMode ? "󰕰" : "󰕵"; onTriggered: filesWindow.gridMode = !filesWindow.gridMode }
                ToolButton { glyph: "󰒺"; onTriggered: { sortMenu.x = toolbar.x + toolbar.width - 172; sortMenu.y = toolbar.height - 5; sortMenu.visible = !sortMenu.visible } }
                ToolButton { glyph: "󰐕"; onTriggered: filesWindow.beginNewFolder() }
            }

            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: filesWindow.lineColor }
        }

        Rectangle {
            id: tabBar
            anchors.left: sidebar.right
            anchors.right: infoPanel.left
            anchors.top: toolbar.bottom
            height: 36
            color: filesWindow.panelColor
            border.width: 0
            z: 15

            Flickable {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                contentWidth: tabRow.implicitWidth
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: tabRow
                    height: parent.height
                    spacing: 3

                    Repeater {
                        id: tabRepeater
                        model: filesWindow.tabs.length
                        delegate: Rectangle {
                            id: tabItem
                            required property int index
                            width: 150
                            height: 30
                            anchors.verticalCenter: parent.verticalCenter
                            color: filesWindow.folderDragOverTabIndex === index ? filesWindow.accent(0.18)
                                 : (index === filesWindow.activeTabIndex ? filesWindow.accent(0.10)
                                 : (tabMouse.containsMouse ? filesWindow.cardColor : "transparent"))
                            border.width: index === filesWindow.activeTabIndex || filesWindow.folderDragOverTabIndex === index ? 1 : 0
                            border.color: filesWindow.folderDragOverTabIndex === index ? filesWindow.accentColor : filesWindow.lineColor

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 6
                                spacing: 6
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "󰉋"; color: index === filesWindow.activeTabIndex ? filesWindow.accentColor : filesWindow.mutedColor; font.pixelSize: 13 }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 104
                                    text: filesWindow.tabTitle(filesWindow.tabs[index].path)
                                    color: index === filesWindow.activeTabIndex ? filesWindow.textColor : "#aab2b9"
                                    font.pixelSize: 10
                                    elide: Text.ElideMiddle
                                }
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "×"; color: closeMouse.containsMouse ? filesWindow.accentColor : filesWindow.mutedColor; font.pixelSize: 14
                                    MouseArea { id: closeMouse; anchors.fill: parent; anchors.margins: -5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: filesWindow.closeTab(index) }
                                }
                            }
                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                anchors.rightMargin: 20
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: filesWindow.hoveredTabIndex = index
                                onExited: if (filesWindow.hoveredTabIndex === index) filesWindow.hoveredTabIndex = -1
                                onClicked: filesWindow.switchTab(index)
                            }
                        }
                    }
                }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: filesWindow.lineColor }
        }

        Rectangle {
            id: contentArea
            anchors.left: sidebar.right
            anchors.right: infoPanel.left
            anchors.top: tabBar.bottom
            anchors.bottom: statusBar.top
            color: "transparent"
            radius: 0

            MouseArea {
                id: selectionMouse
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                preventStealing: true
                z: 0

                onPressed: function(mouse) {
                    filesWindow.lassoStartX = mouse.x
                    filesWindow.lassoStartY = mouse.y
                    filesWindow.lassoCurrentX = mouse.x
                    filesWindow.lassoCurrentY = mouse.y
                    filesWindow.lassoActive = false
                    filesWindow.lassoBaseSelection = (mouse.modifiers & Qt.ControlModifier)
                        ? Object.assign({}, filesWindow.selectedPaths) : ({})
                }
                onPositionChanged: function(mouse) {
                    if (!pressed) return
                    const dx = mouse.x - filesWindow.lassoStartX
                    const dy = mouse.y - filesWindow.lassoStartY
                    if (!filesWindow.lassoActive && Math.sqrt(dx * dx + dy * dy) >= 5)
                        filesWindow.lassoActive = true
                    filesWindow.lassoCurrentX = mouse.x
                    filesWindow.lassoCurrentY = mouse.y
                    if (filesWindow.lassoActive) filesWindow.updateLassoSelection()
                }
                onReleased: function(mouse) {
                    if (!filesWindow.lassoActive) {
                        if (!(mouse.modifiers & Qt.ControlModifier)) filesWindow.clearSelection()
                    } else {
                        filesWindow.lassoCurrentX = mouse.x
                        filesWindow.lassoCurrentY = mouse.y
                        filesWindow.updateLassoSelection()
                    }
                    filesWindow.lassoActive = false
                }
                onCanceled: filesWindow.lassoActive = false
                onWheel: function(wheel) {
                    const view = filesWindow.gridMode ? gridView : listView
                    const maxY = Math.max(0, view.contentHeight - view.height)
                    if (maxY <= 0) return
                    let delta = wheel.angleDelta.y
                    if (delta === 0) delta = wheel.pixelDelta.y
                    const step = delta === 0 ? 0 : -(delta / 120.0) * (filesWindow.gridMode ? filesWindow.gridCellHeight * 0.75 : 90)
                    view.contentY = Math.max(0, Math.min(maxY, view.contentY + step))
                    filesWindow.showScrollIndicator()
                    wheel.accepted = true
                }
            }

            Rectangle {
                id: selectionBand
                visible: filesWindow.lassoActive
                z: 30
                x: Math.min(filesWindow.lassoStartX, filesWindow.lassoCurrentX)
                y: Math.min(filesWindow.lassoStartY, filesWindow.lassoCurrentY)
                width: Math.abs(filesWindow.lassoCurrentX - filesWindow.lassoStartX)
                height: Math.abs(filesWindow.lassoCurrentY - filesWindow.lassoStartY)
                color: filesWindow.accent(0.10)
                border.width: 1
                border.color: filesWindow.accentColor
                radius: 0
            }

            GridView {
                id: gridView
                anchors.fill: parent
                anchors.margins: 14
                visible: filesWindow.gridMode
                clip: true
                cellWidth: filesWindow.gridCellWidth
                cellHeight: filesWindow.gridCellHeight
                model: filesWindow.filteredEntries.length
                interactive: false
                onMovementStarted: filesWindow.showScrollIndicator()
                onMovementEnded: filesWindow.showScrollIndicator()
                onContentYChanged: filesWindow.showScrollIndicator()
                delegate: FileGridItem {
                    entry: filesWindow.filteredEntries[index]
                    tileWidth: gridView.cellWidth - 7
                    tileHeight: gridView.cellHeight - 7
                    accentColor: filesWindow.accentColor
                    coordinateRoot: shellRoot
                    selected: filesWindow.isSelected(entry.path)
                    onClicked: (e, mods) => filesWindow.selectEntry(e, mods)
                    onDoubleClicked: e => filesWindow.openEntry(e)
                    onContextRequested: (e, x, y) => filesWindow.showContext(e, x, y)
                    onFolderDragStarted: (e, x, y) => filesWindow.beginFolderDrag(e, x, y)
                    onFolderDragMoved: (e, x, y) => filesWindow.updateFolderDrag(e, x, y)
                    onFolderDragFinished: (e, x, y) => filesWindow.finishFolderDrag(e, x, y)
                }
            }

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 14
                visible: !filesWindow.gridMode
                clip: true
                spacing: 1
                model: filesWindow.filteredEntries.length
                interactive: false
                onMovementStarted: filesWindow.showScrollIndicator()
                onMovementEnded: filesWindow.showScrollIndicator()
                onContentYChanged: filesWindow.showScrollIndicator()
                delegate: FileListRow {
                    width: listView.width
                    entry: filesWindow.filteredEntries[index]
                    accentColor: filesWindow.accentColor
                    coordinateRoot: shellRoot
                    selected: filesWindow.isSelected(entry.path)
                    onClicked: (e, mods) => filesWindow.selectEntry(e, mods)
                    onDoubleClicked: e => filesWindow.openEntry(e)
                    onContextRequested: (e, x, y) => filesWindow.showContext(e, x, y)
                    onFolderDragStarted: (e, x, y) => filesWindow.beginFolderDrag(e, x, y)
                    onFolderDragMoved: (e, x, y) => filesWindow.updateFolderDrag(e, x, y)
                    onFolderDragFinished: (e, x, y) => filesWindow.finishFolderDrag(e, x, y)
                }
            }

            Item {
                id: contentScrollControl
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                width: 22
                z: 12

                readonly property var view: filesWindow.gridMode ? gridView : listView
                readonly property real maxY: Math.max(0, view.contentHeight - view.height)
                readonly property bool canScroll: maxY > 1

                Rectangle {
                    id: scrollUpButton
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 22; height: 22
                    color: upMouse.containsMouse ? filesWindow.accent(0.10) : "transparent"
                    radius: 0
                    Text { anchors.centerIn: parent; text: "󰅃"; color: filesWindow.mutedColor; font.pixelSize: 14 }
                    MouseArea {
                        id: upMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: filesWindow.scrollBy(-(filesWindow.gridMode ? filesWindow.gridCellHeight : 38))
                    }
                }

                Item {
                    id: scrollTrack
                    anchors.top: scrollUpButton.bottom
                    anchors.topMargin: 5
                    anchors.bottom: scrollDownButton.top
                    anchors.bottomMargin: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 8
                    opacity: contentScrollControl.canScroll ? filesWindow.scrollIndicatorOpacity : 0.0

                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 2
                        height: parent.height
                        color: filesWindow.accent(0.18)
                        radius: 0
                    }

                    Rectangle {
                        id: scrollThumb
                        readonly property real h: Math.max(34, scrollTrack.height * Math.min(1, contentScrollControl.view.height / Math.max(contentScrollControl.view.contentHeight, 1)))
                        width: 6
                        height: h
                        x: 1
                        y: contentScrollControl.maxY <= 0 ? 0 : (contentScrollControl.view.contentY / contentScrollControl.maxY) * Math.max(0, scrollTrack.height - h)
                        color: filesWindow.accentColor
                        radius: 0
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: function(mouse) {
                            const usable = Math.max(1, scrollTrack.height - scrollThumb.height)
                            const y = Math.max(0, Math.min(usable, mouse.y - scrollThumb.height / 2))
                            contentScrollControl.view.contentY = (y / usable) * contentScrollControl.maxY
                            filesWindow.showScrollIndicator()
                        }
                        onPositionChanged: function(mouse) {
                            if (!pressed) return
                            const usable = Math.max(1, scrollTrack.height - scrollThumb.height)
                            const y = Math.max(0, Math.min(usable, mouse.y - scrollThumb.height / 2))
                            contentScrollControl.view.contentY = (y / usable) * contentScrollControl.maxY
                            filesWindow.showScrollIndicator()
                        }
                    }
                }

                Rectangle {
                    id: scrollDownButton
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 22; height: 22
                    color: downMouse.containsMouse ? filesWindow.accent(0.10) : "transparent"
                    radius: 0
                    Text { anchors.centerIn: parent; text: "󰅀"; color: filesWindow.mutedColor; font.pixelSize: 14 }
                    MouseArea {
                        id: downMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: filesWindow.scrollBy(filesWindow.gridMode ? filesWindow.gridCellHeight : 38)
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                visible: !filesWindow.busy && filesWindow.filteredEntries.length === 0
                spacing: 8
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: filesWindow.searchText ? "󰍉" : "󰉋"; color: filesWindow.accentColor; font.pixelSize: 36 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: filesWindow.searchText ? "No matches" : "This folder is empty"; color: filesWindow.textColor; font.pixelSize: 13; font.weight: Font.DemiBold }
            }

            Text {
                anchors.centerIn: parent
                visible: filesWindow.busy
                text: "Loading…"
                color: filesWindow.mutedColor
                font.pixelSize: 12
            }
        }

        Rectangle {
            id: infoPanel
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: statusBar.top
            width: 265
            color: filesWindow.panelColor
            border.width: 0
            radius: 0

            Rectangle { anchors.left: parent.left; width: 1; height: parent.height; color: filesWindow.lineColor }

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Text { text: "DETAILS"; color: filesWindow.mutedColor; font.pixelSize: 9; font.weight: Font.DemiBold }

                Rectangle {
                    width: parent.width; height: 146
                    color: filesWindow.cardColor
                    border.width: 1
                    border.color: filesWindow.infoEntry ? filesWindow.accent(0.48) : filesWindow.lineColor
                    radius: 0

                    Image {
                        id: previewImage
                        anchors.fill: parent
                        anchors.margins: 6
                        visible: filesWindow.infoEntry && !filesWindow.infoEntry.isDir && ["png","jpg","jpeg","webp","bmp","gif"].indexOf(String(filesWindow.infoEntry.ext).toLowerCase()) >= 0
                        source: visible ? filesWindow.infoEntry.url : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        sourceSize.width: 440
                        sourceSize.height: 250
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !previewImage.visible
                        text: filesWindow.infoEntry ? (filesWindow.infoEntry.isDir ? "󰉋" : "󰈔") : "󰋼"
                        color: filesWindow.infoEntry && filesWindow.infoEntry.isDir ? filesWindow.accentColor : "#69747d"
                        font.pixelSize: 56
                    }
                }

                Text {
                    width: parent.width
                    text: filesWindow.infoEntry ? filesWindow.infoEntry.name : "Nothing selected"
                    color: filesWindow.textColor
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideMiddle
                }

                Text { text: filesWindow.infoEntry ? (filesWindow.infoEntry.isDir ? "Folder" : filesWindow.infoEntry.mime) : "Select an item to inspect it"; color: filesWindow.mutedColor; font.pixelSize: 10 }
                Rectangle { width: parent.width; height: 1; color: filesWindow.lineColor }

                Grid {
                    width: parent.width
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 8
                    visible: filesWindow.infoEntry !== null
                    Text { text: "Size"; color: filesWindow.mutedColor; font.pixelSize: 10 }
                    Text { width: 130; text: filesWindow.infoEntry ? filesWindow.infoEntry.sizeHuman : "—"; color: filesWindow.textColor; font.pixelSize: 10; elide: Text.ElideRight }
                    Text { text: "Modified"; color: filesWindow.mutedColor; font.pixelSize: 10 }
                    Text { width: 130; text: filesWindow.infoEntry ? filesWindow.infoEntry.mtimeText : "—"; color: filesWindow.textColor; font.pixelSize: 10 }
                    Text { text: "Type"; color: filesWindow.mutedColor; font.pixelSize: 10 }
                    Text { width: 130; text: filesWindow.infoEntry ? (filesWindow.infoEntry.isDir ? "Directory" : String(filesWindow.infoEntry.ext).toUpperCase()) : "—"; color: filesWindow.textColor; font.pixelSize: 10 }
                    Text { text: "Dimensions"; visible: previewImage.visible; color: filesWindow.mutedColor; font.pixelSize: 10 }
                    Text { width: 130; visible: previewImage.visible; text: previewImage.status === Image.Ready ? previewImage.implicitWidth + " × " + previewImage.implicitHeight : "—"; color: filesWindow.textColor; font.pixelSize: 10 }
                }

                Text { text: "Path"; visible: filesWindow.infoEntry !== null; color: filesWindow.mutedColor; font.pixelSize: 10 }
                Text { width: parent.width; visible: filesWindow.infoEntry !== null; text: filesWindow.infoEntry ? filesWindow.infoEntry.path : ""; color: "#b8c0c7"; font.pixelSize: 9; wrapMode: Text.WrapAnywhere; maximumLineCount: 4; elide: Text.ElideMiddle }

                Item { width: 1; height: 3 }

                component SideAction: Rectangle {
                    property string glyph: ""
                    property string label: ""
                    property bool dangerous: false
                    signal triggered()
                    width: infoPanel.width - 32; height: 34
                    color: saMouse.containsMouse ? (dangerous ? Qt.rgba(0.75,0.17,0.17,0.13) : filesWindow.accent(0.10)) : filesWindow.cardColor
                    border.width: 1
                    border.color: saMouse.containsMouse ? (dangerous ? "#bb4545" : filesWindow.accentColor) : filesWindow.lineColor
                    radius: 0
                    Row { anchors.fill: parent; anchors.leftMargin: 10; spacing: 9; Text { anchors.verticalCenter: parent.verticalCenter; text: parent.parent.glyph; color: parent.parent.dangerous ? "#d76565" : filesWindow.accentColor; font.pixelSize: 14 } Text { anchors.verticalCenter: parent.verticalCenter; text: parent.parent.label; color: filesWindow.textColor; font.pixelSize: 10 } }
                    MouseArea { id: saMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.triggered() }
                }

                SideAction { visible: filesWindow.infoEntry !== null; glyph: "󰏌"; label: "Open"; onTriggered: filesWindow.openEntry(filesWindow.infoEntry) }
                SideAction { visible: filesWindow.infoEntry !== null; glyph: "󰆍"; label: "Open in Terminal"; onTriggered: filesWindow.openTerminalHere(filesWindow.infoEntry) }
                SideAction { visible: filesWindow.infoEntry !== null; glyph: "󰆴"; label: "Move to Trash"; dangerous: true; onTriggered: filesWindow.trashSelection() }
            }
        }

        Rectangle {
            id: statusBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 34
            color: filesWindow.panelColor
            border.width: 0
            radius: 0
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: filesWindow.lineColor }

            Text {
                anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                text: filesWindow.statusMessage.length > 0 ? filesWindow.statusMessage
                    : (filesWindow.selectedEntries.length > 0 ? filesWindow.selectedEntries.length + " item(s) selected" : filesWindow.filteredEntries.length + " item(s)")
                color: filesWindow.statusMessage.length > 0 ? filesWindow.accentColor : filesWindow.mutedColor
                font.pixelSize: 10
            }

            Rectangle {
                id: operationProgress
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(470, parent.width * 0.46)
                height: 26
                visible: filesWindow.operationProgressVisible
                opacity: visible ? 1.0 : 0.0
                color: Qt.rgba(0, 0, 0, 0.18)
                border.width: 1
                border.color: filesWindow.accent(0.42)
                radius: 0

                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: cancelOperationButton.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: filesWindow.operationProgressLabel + (filesWindow.operationProgressDetail ? " · " + filesWindow.operationProgressDetail : "")
                    color: filesWindow.textColor
                    font.pixelSize: 9
                    elide: Text.ElideMiddle
                }
                Rectangle {
                    id: cancelOperationButton
                    anchors.right: percentText.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 58
                    height: 18
                    color: cancelOperationMouse.containsMouse ? Qt.rgba(0.65,0.12,0.12,0.20) : Qt.rgba(1,1,1,0.035)
                    border.width: 1
                    border.color: cancelOperationMouse.containsMouse ? "#b74747" : filesWindow.lineColor
                    radius: 0
                    Text { anchors.centerIn: parent; text: filesWindow.operationProgressCancelling ? "Wait…" : "Cancel"; color: cancelOperationMouse.containsMouse ? "#e88989" : filesWindow.textColor; font.pixelSize: 8 }
                    MouseArea {
                        id: cancelOperationMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: actionProcess.running && !filesWindow.operationProgressCancelling
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: filesWindow.cancelCurrentOperation()
                    }
                }
                Text {
                    id: percentText
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: filesWindow.operationProgressPercent + "%"
                    color: filesWindow.accentColor
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 3
                    color: filesWindow.lineColor
                    Rectangle {
                        width: parent.width * filesWindow.operationProgressPercent / 100
                        height: parent.height
                        color: filesWindow.accentColor
                        Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                    }
                }
            }

            Row {
                anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Text { text: filesWindow.showHidden ? "󰈈 Hidden shown" : "󰈉 Hidden off"; color: filesWindow.mutedColor; font.pixelSize: 9 }
                Rectangle { width: 1; height: 16; color: filesWindow.lineColor }
                Text { text: filesWindow.gridMode ? "󰕰 Grid" : "󰕵 List"; color: filesWindow.mutedColor; font.pixelSize: 9 }
            }
        }

        Rectangle {
            id: transferDialog
            anchors.centerIn: parent
            width: 420
            height: 190
            visible: false
            z: 1300
            color: filesWindow.panelColor
            border.width: 1
            border.color: filesWindow.accentColor

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12
                Text { text: "Copy or move?"; color: filesWindow.textColor; font.pixelSize: 16; font.weight: Font.DemiBold }
                Text {
                    width: parent.width
                    text: filesWindow.pendingTransferPaths.length + " item(s) → " + filesWindow.pendingTransferTargetPath
                    color: filesWindow.mutedColor
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                }
                Text { width: parent.width; text: "Choose what should happen to the dragged item(s). Cancel leaves everything unchanged."; color: "#aab2b9"; font.pixelSize: 10; wrapMode: Text.WordWrap }
                Row {
                    spacing: 8
                    component DialogButton: Rectangle {
                        property string label: ""
                        property bool primary: false
                        signal triggered()
                        width: 112; height: 34
                        color: dbm.containsMouse ? filesWindow.accent(primary ? 0.20 : 0.10) : filesWindow.cardColor
                        border.width: 1
                        border.color: primary ? filesWindow.accentColor : filesWindow.lineColor
                        Text { anchors.centerIn: parent; text: parent.label; color: filesWindow.textColor; font.pixelSize: 10; font.weight: Font.DemiBold }
                        MouseArea { id: dbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.triggered() }
                    }
                    DialogButton { label: "Copy"; primary: true; onTriggered: filesWindow.performPendingTransfer("copy") }
                    DialogButton { label: "Move"; primary: true; onTriggered: filesWindow.performPendingTransfer("move") }
                    DialogButton { label: "Cancel"; onTriggered: filesWindow.cancelPendingTransfer() }
                }
            }
        }

        Rectangle {
            id: conflictDialog
            anchors.centerIn: parent
            width: 470
            height: 230
            visible: false
            z: 1310
            color: filesWindow.panelColor
            border.width: 1
            border.color: filesWindow.accentColor

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 11
                Text { text: "File already exists"; color: filesWindow.textColor; font.pixelSize: 16; font.weight: Font.DemiBold }
                Text {
                    width: parent.width
                    text: filesWindow.conflictTransferItems.length === 1
                          ? filesWindow.conflictTransferItems[0].name
                          : filesWindow.conflictTransferItems.length + " items already exist in the destination."
                    color: filesWindow.textColor
                    font.pixelSize: 11
                    elide: Text.ElideMiddle
                }
                Text {
                    width: parent.width
                    text: "Choose how Hypr-Files should handle the existing item(s)."
                    color: filesWindow.mutedColor
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
                Row {
                    spacing: 8
                    Rectangle {
                        width: 125; height: 34; color: ow.containsMouse ? filesWindow.accent(0.20) : filesWindow.cardColor; border.width: 1; border.color: filesWindow.accentColor
                        Text { anchors.centerIn: parent; text: "Overwrite"; color: filesWindow.textColor; font.pixelSize: 10; font.weight: Font.DemiBold }
                        MouseArea { id: ow; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: filesWindow.executeConflictTransfer("overwrite") }
                    }
                    Rectangle {
                        width: 145; height: 34; color: rn.containsMouse ? filesWindow.accent(0.14) : filesWindow.cardColor; border.width: 1; border.color: filesWindow.lineColor
                        Text { anchors.centerIn: parent; text: "Keep both"; color: filesWindow.textColor; font.pixelSize: 10; font.weight: Font.DemiBold }
                        MouseArea { id: rn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: filesWindow.executeConflictTransfer("rename") }
                    }
                    Rectangle {
                        width: 105; height: 34; color: cn.containsMouse ? Qt.rgba(1,1,1,0.06) : filesWindow.cardColor; border.width: 1; border.color: filesWindow.lineColor
                        Text { anchors.centerIn: parent; text: "Cancel"; color: filesWindow.textColor; font.pixelSize: 10; font.weight: Font.DemiBold }
                        MouseArea { id: cn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: filesWindow.cancelConflictTransfer() }
                    }
                }
                Text { text: "Keep both creates a new name automatically."; color: filesWindow.mutedColor; font.pixelSize: 9 }
            }
        }

        // Dismiss transient menus when clicking anywhere outside them.
        MouseArea {
            id: menuDismissLayer
            anchors.fill: parent
            z: 49
            visible: contextMenu.visible || favoriteMenu.visible || sortMenu.visible || openWithMenu.visible
            acceptedButtons: Qt.LeftButton
            onClicked: {
                contextMenu.visible = false
                favoriteMenu.visible = false
                sortMenu.visible = false
                openWithMenu.visible = false
            }
        }

        // Context menu
        Rectangle {
            id: contextMenu
            width: 205; height: contextColumn.height + 12
            visible: false
            z: 50
            color: "#0c1218"
            border.width: 1
            border.color: filesWindow.accent(0.72)
            radius: 0

            Column {
                id: contextColumn
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 6
                spacing: 1

                component MenuItem: Rectangle {
                    property string glyph: ""
                    property string label: ""
                    property string shortcut: ""
                    property bool dangerous: false
                    signal triggered()
                    width: contextMenu.width - 12; height: 31
                    color: miMouse.containsMouse ? (dangerous ? Qt.rgba(0.7,0.1,0.1,0.14) : filesWindow.accent(0.12)) : "transparent"
                    radius: 0
                    Row {
                        anchors.fill: parent; anchors.leftMargin: 9; anchors.rightMargin: 7; spacing: 8
                        Text { width: 18; anchors.verticalCenter: parent.verticalCenter; text: parent.parent.glyph; color: parent.parent.dangerous ? "#d55b5b" : filesWindow.accentColor; font.pixelSize: 13 }
                        Text { width: 110; anchors.verticalCenter: parent.verticalCenter; text: parent.parent.label; color: parent.parent.dangerous ? "#e27b7b" : filesWindow.textColor; font.pixelSize: 10 }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: parent.parent.shortcut; color: filesWindow.mutedColor; font.pixelSize: 9 }
                    }
                    MouseArea { id: miMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.triggered() }
                }

                MenuItem { glyph: "󰏌"; label: "Open"; shortcut: "Enter"; visible: !filesWindow.contextIsTrash; onTriggered: { contextMenu.visible=false; filesWindow.openEntry(filesWindow.contextEntry) } }
                MenuItem { glyph: "󰏋"; label: "Open With…"; visible: !filesWindow.contextIsTrash && filesWindow.contextEntry && !filesWindow.contextEntry.isDir; onTriggered: filesWindow.requestOpenWith() }
                MenuItem { glyph: "󰆍"; label: "Open in Terminal"; visible: !filesWindow.contextIsTrash; onTriggered: { contextMenu.visible=false; filesWindow.openTerminalHere(filesWindow.contextEntry) } }
                Rectangle { width: contextMenu.width - 12; height: 1; color: filesWindow.lineColor; visible: !filesWindow.contextIsTrash }
                MenuItem { glyph: "󰆏"; label: "Cut"; shortcut: "Ctrl+X"; visible: !filesWindow.contextIsTrash; onTriggered: { contextMenu.visible=false; filesWindow.cutSelection() } }
                MenuItem { glyph: "󰆏"; label: "Copy"; shortcut: "Ctrl+C"; visible: !filesWindow.contextIsTrash; onTriggered: { contextMenu.visible=false; filesWindow.copySelection() } }
                MenuItem { glyph: "󰑕"; label: "Rename"; shortcut: "F2"; visible: !filesWindow.contextIsTrash; onTriggered: { contextMenu.visible=false; filesWindow.beginRename() } }
                Rectangle { width: contextMenu.width - 12; height: 1; color: filesWindow.lineColor; visible: !filesWindow.contextIsTrash }
                MenuItem { glyph: "󰗇"; label: "Compress to ZIP"; visible: !filesWindow.contextIsTrash; onTriggered: filesWindow.archiveSelection("zip") }
                MenuItem { glyph: "󰗇"; label: "Compress to TAR.GZ"; visible: !filesWindow.contextIsTrash; onTriggered: filesWindow.archiveSelection("tar.gz") }
                MenuItem { glyph: "󰗇"; label: "Compress to TAR.XZ"; visible: !filesWindow.contextIsTrash; onTriggered: filesWindow.archiveSelection("tar.xz") }
                MenuItem { glyph: "󰁝"; label: "Extract Here"; visible: !filesWindow.contextIsTrash && filesWindow.isArchive(filesWindow.contextEntry); onTriggered: filesWindow.extractContextArchive() }
                Rectangle { width: contextMenu.width - 12; height: 1; color: filesWindow.lineColor; visible: !filesWindow.contextIsTrash }
                MenuItem { glyph: "󰆴"; label: "Move to Trash"; shortcut: "Delete"; visible: !filesWindow.contextIsTrash; dangerous: true; onTriggered: { contextMenu.visible=false; filesWindow.trashSelection() } }
                MenuItem { glyph: "󰩹"; label: "Empty Trash"; visible: filesWindow.contextIsTrash; dangerous: true; onTriggered: filesWindow.emptyTrash() }
            }
        }

        Rectangle {
            id: favoriteMenu
            width: 190; height: 43
            visible: false
            z: 50
            color: "#0c1218"
            border.width: 1
            border.color: filesWindow.accent(0.72)
            radius: 0

            Rectangle {
                anchors.fill: parent
                anchors.margins: 6
                color: favRemoveMouse.containsMouse ? filesWindow.accent(0.12) : "transparent"
                radius: 0
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    spacing: 8
                    Text { width: 18; anchors.verticalCenter: parent.verticalCenter; text: "󰆴"; color: filesWindow.accentColor; font.pixelSize: 13 }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Remove from Favorites"; color: filesWindow.textColor; font.pixelSize: 10 }
                }
                MouseArea {
                    id: favRemoveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (filesWindow.favoriteContextEntry) filesWindow.removeFavorite(filesWindow.favoriteContextEntry.path)
                }
            }
        }

        Rectangle {
            id: sortMenu
            width: 164; height: 190
            visible: false; z: 51
            color: "#0c1218"; border.width: 1; border.color: filesWindow.accent(0.72); radius: 0
            Column {
                anchors.fill: parent; anchors.margins: 6; spacing: 1
                Text { height: 24; text: "SORT BY"; color: filesWindow.mutedColor; font.pixelSize: 9; verticalAlignment: Text.AlignVCenter }
                Repeater {
                    model: 4
                    delegate: Rectangle {
                        width: 152; height: 29; color: sm.containsMouse ? filesWindow.accent(0.11) : "transparent"; radius: 0
                        Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: {
                                const items = [{k:"name",n:"Name"},{k:"mtime",n:"Modified"},{k:"size",n:"Size"},{k:"type",n:"Type"}]
                                const item = items[index]
                                return (filesWindow.sortKey === item.k ? "󰄬  " : "     ") + item.n
                            }
                            color: filesWindow.textColor
                            font.pixelSize: 10
                        }
                        MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; onClicked: {
                                const items = [{k:"name",n:"Name"},{k:"mtime",n:"Modified"},{k:"size",n:"Size"},{k:"type",n:"Type"}]
                                filesWindow.sortKey = items[index].k
                                sortMenu.visible = false
                                filesWindow.refresh()
                            } }
                    }
                }
                Rectangle { width: 152; height: 1; color: filesWindow.lineColor }
                Rectangle {
                    width: 152; height: 29; color: dm.containsMouse ? filesWindow.accent(0.11) : "transparent"
                    Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: filesWindow.sortDescending ? "󰄬  Descending" : "     Descending"; color: filesWindow.textColor; font.pixelSize: 10 }
                    MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; onClicked: { filesWindow.sortDescending=!filesWindow.sortDescending; sortMenu.visible=false; filesWindow.refresh() } }
                }
            }
        }

        Rectangle {
            id: openWithMenu
            width: 235
            height: Math.min(340, 52 + openWithApps.length * 34)
            visible: false; z: 52
            color: "#0c1218"; border.width: 1; border.color: filesWindow.accent(0.72); radius: 0
            Column {
                anchors.fill: parent; anchors.margins: 7; spacing: 3
                Text { height: 25; text: "OPEN WITH"; color: filesWindow.mutedColor; font.pixelSize: 9; verticalAlignment: Text.AlignVCenter }
                ListView {
                    width: parent.width; height: openWithMenu.height - 46
                    clip: true; model: filesWindow.openWithApps.length; spacing: 1
                    delegate: Rectangle {
                        width: ListView.view.width; height: 32; color: awm.containsMouse ? filesWindow.accent(0.11) : "transparent"; radius: 0
                        Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: filesWindow.openWithApps[index].name; color: filesWindow.textColor; font.pixelSize: 10; elide: Text.ElideRight }
                        MouseArea { id: awm; anchors.fill: parent; hoverEnabled: true; onClicked: { openWithMenu.visible=false; filesWindow.runAction(["launch-app", filesWindow.openWithApps[index].id, filesWindow.contextEntry.path], false) } }
                    }
                }
            }
        }

        // Reusable modal backdrop.
        Rectangle {
            id: modalShade
            anchors.fill: parent
            visible: newFolderDialog.visible || renameDialog.visible || confirmDelete.visible || confirmEmptyTrash.visible || conflictDialog.visible
            z: 80
            color: Qt.rgba(0,0,0,0.50)
            MouseArea { anchors.fill: parent }
        }

        Rectangle {
            id: newFolderDialog
            width: 360; height: 155
            anchors.centerIn: parent
            visible: false; z: 81
            color: "#0b1117"; border.width: 1; border.color: filesWindow.accentColor; radius: 0
            Column {
                anchors.fill: parent; anchors.margins: 16; spacing: 12
                Text { text: "New Folder"; color: filesWindow.textColor; font.pixelSize: 14; font.weight: Font.DemiBold }
                Rectangle { width: parent.width; height: 34; color: filesWindow.cardColor; border.width: 1; border.color: newFolderInput.activeFocus ? filesWindow.accentColor : filesWindow.lineColor; radius: 0
                    TextInput { id: newFolderInput; anchors.fill: parent; anchors.margins: 8; verticalAlignment: TextInput.AlignVCenter; color: filesWindow.textColor; selectionColor: filesWindow.accent(0.45); onAccepted: filesWindow.completeNewFolder() }
                }
                Row { anchors.right: parent.right; spacing: 7
                    Rectangle { width: 78; height: 30; color: cancelNF.containsMouse ? Qt.rgba(1,1,1,0.06) : filesWindow.cardColor; border.width:1; border.color:filesWindow.lineColor; Text { anchors.centerIn: parent; text:"Cancel"; color:filesWindow.textColor; font.pixelSize:10 } MouseArea{id:cancelNF;anchors.fill:parent;hoverEnabled:true;onClicked:newFolderDialog.visible=false} }
                    Rectangle { width: 78; height: 30; color: filesWindow.accent(0.16); border.width:1; border.color:filesWindow.accentColor; Text { anchors.centerIn: parent; text:"Create"; color:filesWindow.textColor; font.pixelSize:10 } MouseArea{anchors.fill:parent;onClicked:filesWindow.completeNewFolder()} }
                }
            }
        }

        Rectangle {
            id: renameDialog
            width: 360; height: 155
            anchors.centerIn: parent
            visible: false; z: 81
            color: "#0b1117"; border.width: 1; border.color: filesWindow.accentColor; radius: 0
            Column {
                anchors.fill: parent; anchors.margins: 16; spacing: 12
                Text { text: "Rename"; color: filesWindow.textColor; font.pixelSize: 14; font.weight: Font.DemiBold }
                Rectangle { width: parent.width; height: 34; color: filesWindow.cardColor; border.width: 1; border.color: renameInput.activeFocus ? filesWindow.accentColor : filesWindow.lineColor; radius: 0
                    TextInput { id: renameInput; anchors.fill: parent; anchors.margins: 8; verticalAlignment: TextInput.AlignVCenter; color: filesWindow.textColor; selectionColor: filesWindow.accent(0.45); onAccepted: filesWindow.completeRename() }
                }
                Row { anchors.right: parent.right; spacing: 7
                    Rectangle { width: 78; height: 30; color: cancelRN.containsMouse ? Qt.rgba(1,1,1,0.06) : filesWindow.cardColor; border.width:1; border.color:filesWindow.lineColor; Text { anchors.centerIn: parent; text:"Cancel"; color:filesWindow.textColor; font.pixelSize:10 } MouseArea{id:cancelRN;anchors.fill:parent;hoverEnabled:true;onClicked:renameDialog.visible=false} }
                    Rectangle { width: 78; height: 30; color: filesWindow.accent(0.16); border.width:1; border.color:filesWindow.accentColor; Text { anchors.centerIn: parent; text:"Rename"; color:filesWindow.textColor; font.pixelSize:10 } MouseArea{anchors.fill:parent;onClicked:filesWindow.completeRename()} }
                }
            }
        }

        Rectangle {
            id: confirmDelete
            width: 390; height: 170
            anchors.centerIn: parent
            visible: false; z: 81
            color: "#0b1117"; border.width: 1; border.color: "#b74747"; radius: 0
            Column {
                anchors.fill: parent; anchors.margins: 17; spacing: 12
                Text { text: "Delete permanently?"; color: "#f0dddd"; font.pixelSize: 14; font.weight: Font.DemiBold }
                Text { width: parent.width; text: "This permanently deletes " + filesWindow.selectedEntries.length + " selected item(s). This cannot be undone."; color: filesWindow.mutedColor; font.pixelSize: 10; wrapMode: Text.WordWrap }
                Row { anchors.right: parent.right; spacing: 7
                    Rectangle { width: 82; height: 30; color: cancelDel.containsMouse ? Qt.rgba(1,1,1,0.06) : filesWindow.cardColor; border.width:1; border.color:filesWindow.lineColor; Text { anchors.centerIn: parent; text:"Cancel"; color:filesWindow.textColor; font.pixelSize:10 } MouseArea{id:cancelDel;anchors.fill:parent;hoverEnabled:true;onClicked:confirmDelete.visible=false} }
                    Rectangle { width: 90; height: 30; color: Qt.rgba(0.65,0.12,0.12,0.2); border.width:1; border.color:"#b74747"; Text { anchors.centerIn: parent; text:"Delete"; color:"#e88989"; font.pixelSize:10 } MouseArea{anchors.fill:parent;onClicked:{confirmDelete.visible=false;filesWindow.runAction(["delete",JSON.stringify(filesWindow.selectedPathArray())],true)}} }
                }
            }
        }

        Rectangle {
            id: confirmEmptyTrash
            width: 390; height: 165
            anchors.centerIn: parent
            visible: false; z: 81
            color: "#0b1117"; border.width: 1; border.color: "#b74747"; radius: 0
            Column {
                anchors.fill: parent; anchors.margins: 17; spacing: 12
                Text { text: "Empty Trash?"; color: "#f0dddd"; font.pixelSize: 14; font.weight: Font.DemiBold }
                Text { width: parent.width; text: "All items in Trash will be permanently deleted. This cannot be undone."; color: filesWindow.mutedColor; font.pixelSize: 10; wrapMode: Text.WordWrap }
                Row { anchors.right: parent.right; spacing: 7
                    Rectangle { width: 82; height: 30; color: cancelEmpty.containsMouse ? Qt.rgba(1,1,1,0.06) : filesWindow.cardColor; border.width:1; border.color:filesWindow.lineColor; Text { anchors.centerIn: parent; text:"Cancel"; color:filesWindow.textColor; font.pixelSize:10 } MouseArea{id:cancelEmpty;anchors.fill:parent;hoverEnabled:true;onClicked:confirmEmptyTrash.visible=false} }
                    Rectangle { width: 100; height: 30; color: Qt.rgba(0.65,0.12,0.12,0.2); border.width:1; border.color:"#b74747"; Text { anchors.centerIn: parent; text:"Empty Trash"; color:"#e88989"; font.pixelSize:10 } MouseArea{anchors.fill:parent;onClicked:{confirmEmptyTrash.visible=false;filesWindow.runAction(["empty-trash"],true)}} }
                }
            }
        }

    }
}
