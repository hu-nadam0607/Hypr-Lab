import QtQuick

Item {
    id: leftBarRoot

    property int barWidth: 1080
    property int barHeight: 40

    signal openAppLauncher()

    implicitWidth: barWidth
    implicitHeight: barHeight

    Capsule {
        id: capsule
        anchors.fill: parent
        capsuleWidth: leftBarRoot.barWidth
        capsuleHeight: leftBarRoot.barHeight
    }

    Shadow {
        sourceItem: capsule
        z: -2
    }

    Glow {
        sourceItem: capsule
        z: -1
    }

    Row {
        id: contentRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        spacing: 7
        z: 1

        // Hypr-Lab / Arch launcher button.
        BarActionButton {
            id: launcherButton
            icon: "󰣇"
            iconSize: 18
            onClicked: leftBarRoot.openAppLauncher()
        }

        // Visszafogott elválasztás a launcher és a workspace-ek között.
        Rectangle {
            width: 1
            height: 18
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        Row {
            id: workspaceRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Repeater {
                model: 10

                WorkspaceButton {
                    workspaceId: index + 1
                }
            }
        }
    }
}
