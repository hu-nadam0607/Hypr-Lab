import QtQuick
import Quickshell.Widgets

Item {
    id: root

    property var notification: null

    signal dismissRequested()

    implicitWidth: 320
    implicitHeight: 62

    width: implicitWidth
    height: implicitHeight

    Rectangle {
        id: card

        anchors.fill: parent

        radius: height / 2

        color: Qt.rgba(
            1,
            1,
            1,
            0.045
        )

        border.width: 1

        border.color: Qt.rgba(
            55 / 255,
            245 / 255,
            235 / 255,
            0.08
        )

        Row {
            anchors.fill: parent

            anchors.leftMargin: 10
            anchors.rightMargin: 8
            anchors.topMargin: 7
            anchors.bottomMargin: 7

            spacing: 10

            Rectangle {
                width: 34
                height: 34

                radius: width / 2

                anchors.verticalCenter:
                    parent.verticalCenter

                color: Qt.rgba(
                    1,
                    1,
                    1,
                    0.07
                )

                IconImage {
                    anchors.centerIn: parent

                    width: 19
                    height: 19

                    source:
                        root.notification
                        ? root.notification.appIcon
                        : ""
                }
            }

            Column {
                width:
                    parent.width
                    - 34
                    - closeButton.width
                    - 30

                anchors.verticalCenter:
                    parent.verticalCenter

                spacing: 1

                Text {
                    width: parent.width

                    text:
                        root.notification
                        ? (
                            root.notification.appName
                            || "Értesítés"
                        )
                        : ""

                    color: Qt.rgba(
                        1,
                        1,
                        1,
                        0.45
                    )

                    font.family: "Inter"
                    font.pixelSize: 8

                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width

                    text:
                        root.notification
                        ? root.notification.summary
                        : ""

                    color: "white"

                    font.family: "Inter"
                    font.pixelSize: 11
                    font.bold: true

                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width

                    visible:
                        root.notification
                        && root.notification.body !== ""

                    text:
                        root.notification
                        ? root.notification.body
                        : ""

                    textFormat: Text.PlainText

                    color: Qt.rgba(
                        1,
                        1,
                        1,
                        0.60
                    )

                    font.family: "Inter"
                    font.pixelSize: 8

                    maximumLineCount: 1
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                id: closeButton

                width: 26
                height: 26

                radius: width / 2

                anchors.verticalCenter:
                    parent.verticalCenter

                color:
                    closeMouse.containsMouse
                    ? Qt.rgba(
                        55 / 255,
                        245 / 255,
                        235 / 255,
                        0.18
                    )
                    : Qt.rgba(
                        1,
                        1,
                        1,
                        0.05
                    )

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                Text {
                    anchors.centerIn: parent

                    text: "×"

                    color: "white"

                    font.family: "Inter"
                    font.pixelSize: 15
                }

                MouseArea {
                    id: closeMouse

                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.dismissRequested()
                    }
                }
            }
        }
    }
}
