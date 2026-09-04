import QtQuick

Item {
    id: root

    property var backend
    property color accentColor: "#68787D"
    property bool dndConfigOpen: false

    property int draftFromMinutes: backend ? backend.dndFromMinutes : 1320
    property int draftUntilMinutes: backend ? backend.dndUntilMinutes : 360

    function pad2(v) {
        return v < 10 ? "0" + v : String(v);
    }
    function timeText(minutes) {
        let m = ((minutes % 1440) + 1440) % 1440;
        return pad2(Math.floor(m / 60)) + ":" + pad2(m % 60);
    }
    function stepTime(value, delta) {
        return (value + delta + 1440) % 1440;
    }
    function parseTime(value) {
        const raw = String(value).trim();
        const match = raw.match(/^([0-9]{1,2}):([0-9]{1,2})$/);
        if (!match)
            return -1;

        const h = parseInt(match[1]);
        const m = parseInt(match[2]);
        if (isNaN(h) || isNaN(m) || h < 0 || h > 23 || m < 0 || m > 59)
            return -1;

        return h * 60 + m;
    }

    Connections {
        target: backend
        function onDndFromMinutesChanged() {
            root.draftFromMinutes = backend.dndFromMinutes;
        }
        function onDndUntilMinutesChanged() {
            root.draftUntilMinutes = backend.dndUntilMinutes;
        }
    }

    Flickable {
        anchors.fill: parent
        visible: !root.dndConfigOpen
        clip: true
        contentWidth: width
        contentHeight: mainContent.implicitHeight + 24
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: mainContent
            width: parent.width
            spacing: 0

            SectionLabel {
                width: parent.width
                text: "DO NOT DISTURB"
                accentColor: root.accentColor
            }

            SettingAction {
                width: parent.width
                accentColor: root.accentColor
                title: "Configure Do Not Disturb"
                subtitle: backend && backend.dndAuto ? "Automatic schedule: " + root.timeText(backend.dndFromMinutes) + " – " + root.timeText(backend.dndUntilMinutes) : "Automatic scheduling, time range and manual activation"
                icon: "󰂛"
                buttonText: "CONFIGURE"
                onTriggered: root.dndConfigOpen = true
            }

            SectionLabel {
                width: parent.width
                text: "BEHAVIOR"
                accentColor: root.accentColor
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Notification sound"
                subtitle: "Play the Hypr-Lab notification sound when DND is inactive"
                checked: backend.notificationSound
                onToggled: function (v) {
                    backend.notificationSound = v;
                    backend.setBool("NOTIFICATION_SOUND", v);
                }
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Center Island summary"
                subtitle: "Show notification count feedback in Center Island"
                checked: backend.notificationSummary
                onToggled: function (v) {
                    backend.notificationSummary = v;
                    backend.setBool("NOTIFICATION_SUMMARY", v);
                }
            }

            SectionLabel {
                width: parent.width
                text: "HISTORY"
                accentColor: root.accentColor
            }

            SettingAction {
                width: parent.width
                accentColor: root.accentColor
                title: "Clear notifications"
                subtitle: "Dismiss all notifications currently tracked by Hypr-Lab"
                icon: "󰆴"
                buttonText: "CLEAR"
                onTriggered: backend.clearNotifications()
            }
        }
    }

    Flickable {
        anchors.fill: parent
        visible: root.dndConfigOpen
        clip: true
        contentWidth: width
        contentHeight: dndContent.implicitHeight + 24
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: dndContent
            width: parent.width
            spacing: 0

            Item {
                width: parent.width
                height: 48

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: "‹"
                        color: root.accentColor
                        font.family: "Inter"
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Text {
                        text: "Back"
                        color: Qt.rgba(1, 1, 1, 0.82)
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.bold: true
                        font.italic: true
                    }
                }

                MouseArea {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 92
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dndConfigOpen = false
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
                text: "DO NOT DISTURB CONFIGURATION"
                accentColor: root.accentColor
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Automatic activation"
                subtitle: "Enable Do Not Disturb automatically during the configured time range"
                checked: backend.dndAuto
                onToggled: function (v) {
                    backend.setDndAuto(v);
                }
            }

            SettingTimeRow {
                width: parent.width
                accentColor: root.accentColor
                title: "From"
                subtitle: "Automatic DND start time · type HH:MM or use the buttons"
                timeText: root.timeText(root.draftFromMinutes)
                enabled: backend.dndAuto
                onDecrease: root.draftFromMinutes = root.stepTime(root.draftFromMinutes, -5)
                onIncrease: root.draftFromMinutes = root.stepTime(root.draftFromMinutes, 5)
                onTimeAccepted: function (value) {
                    const parsed = root.parseTime(value);
                    if (parsed >= 0)
                        root.draftFromMinutes = parsed;
                }
            }

            SettingTimeRow {
                width: parent.width
                accentColor: root.accentColor
                title: "Until"
                subtitle: "Automatic DND end time · type HH:MM or use the buttons"
                timeText: root.timeText(root.draftUntilMinutes)
                enabled: backend.dndAuto
                onDecrease: root.draftUntilMinutes = root.stepTime(root.draftUntilMinutes, -5)
                onIncrease: root.draftUntilMinutes = root.stepTime(root.draftUntilMinutes, 5)
                onTimeAccepted: function (value) {
                    const parsed = root.parseTime(value);
                    if (parsed >= 0)
                        root.draftUntilMinutes = parsed;
                }
            }

            SettingAction {
                width: parent.width
                accentColor: root.accentColor
                title: "Apply automatic schedule"
                subtitle: backend.dndAuto ? "Save " + root.timeText(root.draftFromMinutes) + " – " + root.timeText(root.draftUntilMinutes) : "Enable Automatic activation to configure a schedule"
                icon: "󰃰"
                buttonText: "APPLY"
                enabled: backend.dndAuto
                onTriggered: backend.applyDndSchedule(root.draftFromMinutes, root.draftUntilMinutes)
            }

            SectionLabel {
                width: parent.width
                text: "MANUAL"
                accentColor: root.accentColor
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Turn on now"
                subtitle: "Manual DND. While enabled it takes priority over the automatic schedule"
                checked: backend.dndManual
                onToggled: function (v) {
                    backend.setDndManual(v);
                }
            }
        }
    }
}
