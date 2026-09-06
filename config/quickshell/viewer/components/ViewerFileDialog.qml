import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property color accentColor: "#68787D"
    property bool opened: false
    property bool folderMode: false

    property string currentPath: Quickshell.env("HOME")
    property var entries: []
    property string selectedPath: ""

    signal filesAccepted(var files)
    signal folderAccepted(string folder)
    signal cancelled

    anchors.fill: parent

    visible: opacity > 0

    opacity: opened ? 1 : 0
    z: 100

    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    function accent(alpha) {
        return Qt.rgba(accentColor.r, accentColor.g, accentColor.b, alpha);
    }

    function fileName(path) {
        if (!path)
            return "";

        const pos = path.lastIndexOf("/");

        return pos >= 0 ? path.substring(pos + 1) : path;
    }

    function parentPath(path) {
        if (!path || path === "/")
            return "/";

        let clean = path;

        while (clean.length > 1 && clean.endsWith("/"))
            clean = clean.slice(0, -1);

        const pos = clean.lastIndexOf("/");

        if (pos <= 0)
            return "/";

        return clean.substring(0, pos);
    }

    function refresh() {
        directoryReader.command = [
            "bash",
            "-lc",
            "python3 - <<'PY'\n"
            + "import os\n"
            + "p = " + JSON.stringify(currentPath) + "\n"
            + "\n"
            + "try:\n"
            + "    names = sorted(\n"
            + "        [name for name in os.listdir(p) if not name.startswith('.')],\n"
            + "        key=str.lower\n"
            + "    )\n"
            + "except Exception:\n"
            + "    names = []\n"
            + "\n"
            + "for name in names:\n"
            + "    full = os.path.join(p, name)\n"
            + "\n"
            + "    if os.path.isdir(full):\n"
            + "        print('D\\t' + full)\n"
            + "    else:\n"
            + "        low = name.lower()\n"
            + "\n"
            + "        if low.endswith((\n"
            + "            '.png',\n"
            + "            '.jpg',\n"
            + "            '.jpeg',\n"
            + "            '.webp',\n"
            + "            '.bmp',\n"
            + "            '.gif'\n"
            + "        )):\n"
            + "            print('F\\t' + full)\n"
            + "PY"
        ];

        directoryReader.running = true;
    }

    function openFileMode() {
        folderMode = false;
        selectedPath = "";
        opened = true;
        refresh();
    }

    function openFolderMode() {
        folderMode = true;
        selectedPath = "";
        opened = true;
        refresh();
    }

    function closeDialog() {
        opened = false;
        selectedPath = "";
        cancelled();
    }

    function enterDirectory(path) {
        currentPath = path;
        selectedPath = "";
        refresh();
    }

    Process {
        id: directoryReader

        stdout: StdioCollector {
            onStreamFinished: {
                const raw = String(text).trim();

                if (raw.length === 0) {
                    root.entries = [];
                    return;
                }

                let result = [];

                const lines = raw.split("\n");

                for (let line of lines) {
                    const tab = line.indexOf("\t");

                    if (tab < 1)
                        continue;
                    const kind = line.substring(0, tab);
                    const path = line.substring(tab + 1);

                    result.push({
                        directory: kind === "D",
                        path: path
                    });
                }

                root.entries = result;
            }
        }
    }

    Shortcut {
        enabled: root.opened
        sequence: "Escape"

        onActivated: root.closeDialog()
    }

    Rectangle {
        anchors.fill: parent

        color: Qt.rgba(0, 0, 0, 0.58)

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeDialog()
        }
    }

    Rectangle {
        id: panel

        width: Math.min(parent.width - 120, 880)
        height: Math.min(parent.height - 100, 600)

        anchors.centerIn: parent

        radius: 1

        color: Qt.rgba(8 / 255, 12 / 255, 17 / 255, 0.98)

        border.width: 2
        border.color: root.accent(0.48)

        scale: root.opened ? 1 : 0.97

        Behavior on scale {
            NumberAnimation {
                duration: 170
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16

            spacing: 12

            Row {
                width: parent.width
                height: 36

                spacing: 8

                Rectangle {
                    width: 36
                    height: 36

                    radius: 1

                    color: backMouse.containsMouse ? root.accent(0.12) : Qt.rgba(1, 1, 1, 0.025)

                    border.width: 1
                    border.color: root.accent(0.18)

                    Text {
                        anchors.centerIn: parent

                        text: "←"

                        color: root.accentColor

                        font.family: "Inter"
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        id: backMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            root.enterDirectory(root.parentPath(root.currentPath));
                        }
                    }
                }

                Rectangle {
                    width: 36
                    height: 36

                    radius: 1

                    color: homeMouse.containsMouse ? root.accent(0.12) : Qt.rgba(1, 1, 1, 0.025)

                    border.width: 1
                    border.color: root.accent(0.18)

                    Text {
                        anchors.centerIn: parent

                        text: "󰋜"

                        color: root.accentColor

                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: homeMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            root.enterDirectory(Quickshell.env("HOME"));
                        }
                    }
                }

                Rectangle {
                    height: 36
                    width: parent.width - 88

                    radius: 1

                    color: Qt.rgba(1, 1, 1, 0.025)

                    border.width: 1
                    border.color: root.accent(0.18)

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        anchors.leftMargin: 12
                        anchors.rightMargin: 12

                        text: root.currentPath

                        color: Qt.rgba(1, 1, 1, 0.62)

                        font.family: "Inter"
                        font.pixelSize: 10

                        elide: Text.ElideMiddle
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1

                gradient: Gradient {
                    orientation: Gradient.Horizontal

                    GradientStop {
                        position: 0
                        color: root.accent(0)
                    }

                    GradientStop {
                        position: 0.5
                        color: root.accent(0.5)
                    }

                    GradientStop {
                        position: 1
                        color: root.accent(0)
                    }
                }
            }

            Text {
                text: root.folderMode ? "SELECT FOLDER" : "SELECT IMAGE"

                color: root.accentColor

                font.family: "Inter"
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1.0
            }

            GridView {
                id: fileGrid

                width: parent.width
                height: parent.height - 140

                clip: true

                cellWidth: 150
                cellHeight: 128

                model: root.entries.length

                delegate: Item {
                    required property int index

                    readonly property var entry: root.entries[index]

                    width: fileGrid.cellWidth
                    height: fileGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 5

                        radius: 1

                        color: root.selectedPath === entry.path ? root.accent(0.10) : itemMouse.containsMouse ? root.accent(0.055) : Qt.rgba(1, 1, 1, 0.025)

                        border.width: 1

                        border.color: root.selectedPath === entry.path ? root.accent(0.58) : itemMouse.containsMouse ? root.accent(0.30) : root.accent(0.10)

                        Image {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right

                            anchors.margins: 8

                            height: 78

                            visible: !entry.directory

                            source: entry.directory ? "" : "file://" + encodeURI(entry.path)

                            fillMode: Image.PreserveAspectCrop

                            asynchronous: true
                            cache: true
                            smooth: true
                        }

                        Text {
                            anchors.centerIn: parent

                            visible: entry.directory

                            text: "󰉋"

                            color: root.accentColor

                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 32
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom

                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.bottomMargin: 8

                            text: root.fileName(entry.path)

                            color: root.selectedPath === entry.path ? root.accentColor : Qt.rgba(1, 1, 1, 0.58)

                            font.family: "Inter"
                            font.pixelSize: 9

                            elide: Text.ElideMiddle

                            horizontalAlignment: Text.AlignHCenter
                        }

                        MouseArea {
                            id: itemMouse

                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (entry.directory) {
                                    root.selectedPath = entry.path;
                                } else if (!root.folderMode) {
                                    root.selectedPath = entry.path;
                                }
                            }

                            onDoubleClicked: {
                                if (entry.directory) {
                                    root.enterDirectory(entry.path);
                                } else if (!root.folderMode) {
                                    root.filesAccepted([entry.path]);
                                    root.opened = false;
                                }
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 36

                layoutDirection: Qt.RightToLeft
                spacing: 8

                Rectangle {
                    width: 96
                    height: 34

                    radius: 1

                    opacity: root.folderMode || root.selectedPath.length > 0 ? 1 : 0.32

                    color: openMouse.containsMouse ? root.accent(0.16) : root.accent(0.08)

                    border.width: 1
                    border.color: root.accent(0.46)

                    Text {
                        anchors.centerIn: parent

                        text: root.folderMode ? "OPEN FOLDER" : "OPEN"

                        color: root.accentColor

                        font.family: "Inter"
                        font.pixelSize: 10
                        font.bold: true
                    }

                    MouseArea {
                        id: openMouse

                        anchors.fill: parent

                        enabled: root.folderMode || root.selectedPath.length > 0

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (root.folderMode) {
                                root.folderAccepted(root.selectedPath.length > 0 ? root.selectedPath : root.currentPath);

                                root.opened = false;
                            } else {
                                root.filesAccepted([root.selectedPath]);

                                root.opened = false;
                            }
                        }
                    }
                }

                Rectangle {
                    width: 82
                    height: 34

                    radius: 1

                    color: cancelMouse.containsMouse ? root.accent(0.09) : Qt.rgba(1, 1, 1, 0.025)

                    border.width: 1
                    border.color: root.accent(0.14)

                    Text {
                        anchors.centerIn: parent

                        text: "CANCEL"

                        color: Qt.rgba(1, 1, 1, 0.55)

                        font.family: "Inter"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: cancelMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        cursorShape: Qt.PointingHandCursor

                        onClicked: root.closeDialog()
                    }
                }
            }
        }
    }
}
