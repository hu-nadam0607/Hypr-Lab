import QtQuick

Item {
    id: root
    property var backend
    property color accentColor: "#68787D"

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 16
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 0

            SectionLabel {
                width: parent.width
                text: "WORKSPACES"
                accentColor: root.accentColor
            }

            SettingStepper {
                width: parent.width
                accentColor: root.accentColor
                title: "Workspace count"
                subtitle: "Number of workspace buttons shown in the Top Bar"
                valueText: String(backend.workspaceCount)

                onDecrease: {
                    if (backend.workspaceCount > 1)
                        backend.setWorkspaceCount(backend.workspaceCount - 1)
                }
                onIncrease: {
                    if (backend.workspaceCount < 10)
                        backend.setWorkspaceCount(backend.workspaceCount + 1)
                }
            }

            Item {
                width: parent.width
                height: workspaceFlow.implicitHeight + 58

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        text: "Switch workspace"
                        color: Qt.rgba(1, 1, 1, 0.88)
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.bold: true
                        font.italic: true
                    }

                    Flow {
                        id: workspaceFlow
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: Math.max(1, Math.min(10, backend.workspaceCount))

                            delegate: Item {
                                width: 42
                                height: 28

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 2
                                    color: wsMouse.containsMouse
                                        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.13)
                                        : Qt.rgba(1, 1, 1, 0.035)
                                    border.width: 1
                                    border.color: wsMouse.containsMouse
                                        ? root.accentColor
                                        : Qt.rgba(1, 1, 1, 0.12)
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: String(index + 1)
                                    color: root.accentColor
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                MouseArea {
                                    id: wsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.switchWorkspace(index + 1)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.055)
                }
            }

            SectionLabel {
                width: parent.width
                text: "OVERVIEW"
                accentColor: root.accentColor
            }

            Text {
                width: parent.width
                height: 64
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                text: "Workspace count is applied immediately to the Top Bar. Hyprland workspaces remain dynamic and are created when they are used."
                color: Qt.rgba(1, 1, 1, 0.42)
                font.family: "Inter"
                font.pixelSize: 9
                font.italic: true
            }
        }
    }
}
