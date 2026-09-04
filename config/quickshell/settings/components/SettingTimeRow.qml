import QtQuick

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string timeText: "00:00"
    property bool enabled: true
    property color accentColor: "#68787D"

    signal decrease()
    signal increase()
    signal timeAccepted(string value)

    height: 66
    opacity: enabled ? 1.0 : 0.42

    function normalizeTime(value) {
        const raw = String(value).trim()
        const match = raw.match(/^([0-9]{1,2}):([0-9]{1,2})$/)
        if (!match) return ""

        const h = parseInt(match[1])
        const m = parseInt(match[2])
        if (isNaN(h) || isNaN(m) || h < 0 || h > 23 || m < 0 || m > 59)
            return ""

        const hh = h < 10 ? "0" + h : String(h)
        const mm = m < 10 ? "0" + m : String(m)
        return hh + ":" + mm
    }

    function commitInput() {
        const normalized = normalizeTime(timeInput.text)
        if (normalized.length === 0) {
            timeInput.text = root.timeText
            return
        }
        timeInput.text = normalized
        root.timeAccepted(normalized)
    }

    onTimeTextChanged: {
        if (!timeInput.activeFocus)
            timeInput.text = root.timeText
    }

    Column {
        anchors.left: parent.left
        anchors.right: controls.left
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Text {
            width: parent.width
            text: root.title
            color: Qt.rgba(1,1,1,0.88)
            font.family: "Inter"
            font.pixelSize: 11
            font.bold: true
            font.italic: true
        }

        Text {
            width: parent.width
            text: root.subtitle
            color: Qt.rgba(1,1,1,0.38)
            font.family: "Inter"
            font.pixelSize: 8
            font.italic: true
        }
    }

    Row {
        id: controls
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Item {
            width: 30
            height: 28

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: minusMouse.containsMouse ? Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.12) : Qt.rgba(1,1,1,0.035)
                border.width: 1
                border.color: minusMouse.containsMouse ? root.accentColor : Qt.rgba(1,1,1,0.12)
            }

            Text {
                anchors.centerIn: parent
                text: "−"
                color: Qt.rgba(1,1,1,0.72)
                font.family: "Inter"
                font.pixelSize: 14
            }

            MouseArea {
                id: minusMouse
                anchors.fill: parent
                enabled: root.enabled
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.decrease()
            }
        }

        Rectangle {
            width: 78
            height: 28
            radius: 2
            color: timeInput.activeFocus ? Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.10) : Qt.rgba(1,1,1,0.028)
            border.width: 1
            border.color: timeInput.activeFocus ? root.accentColor : Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.25)

            TextInput {
                id: timeInput
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                text: root.timeText
                color: root.enabled ? root.accentColor : Qt.rgba(1,1,1,0.36)
                selectionColor: root.accentColor
                selectedTextColor: "#0B1116"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                font.bold: true
                enabled: root.enabled
                validator: RegularExpressionValidator { regularExpression: /^([0-9]{0,2})(:([0-9]{0,2})?)?$/ }

                Keys.onReturnPressed: {
                    root.commitInput()
                    focus = false
                }

                Keys.onEnterPressed: {
                    root.commitInput()
                    focus = false
                }

                onEditingFinished: root.commitInput()
            }
        }

        Item {
            width: 30
            height: 28

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: plusMouse.containsMouse ? Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.12) : Qt.rgba(1,1,1,0.035)
                border.width: 1
                border.color: plusMouse.containsMouse ? root.accentColor : Qt.rgba(1,1,1,0.12)
            }

            Text {
                anchors.centerIn: parent
                text: "+"
                color: Qt.rgba(1,1,1,0.72)
                font.family: "Inter"
                font.pixelSize: 14
            }

            MouseArea {
                id: plusMouse
                anchors.fill: parent
                enabled: root.enabled
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.increase()
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Qt.rgba(1,1,1,0.055)
    }
}
