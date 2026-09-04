import QtQuick

Item {
    id: root

    property var backend
    property color accentColor: "#68787D"

    property int draftFromMinutes: backend ? backend.nightLightFromMinutes : 1200
    property int draftUntilMinutes: backend ? backend.nightLightUntilMinutes : 420

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

        function onNightLightFromMinutesChanged() {
            root.draftFromMinutes = backend.nightLightFromMinutes;
        }

        function onNightLightUntilMinutesChanged() {
            root.draftUntilMinutes = backend.nightLightUntilMinutes;
        }
    }

    Flickable {
        anchors.fill: parent

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
                text: "NIGHT LIGHT"
                accentColor: root.accentColor
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor

                title: "Turn on now"
                subtitle: "Enable the warmer display tone manually"

                checked: backend.nightLightManual

                onToggled: function (v) {
                    backend.setNightLightManual(v);
                }
            }

            SectionLabel {
                width: parent.width
                text: "COLOR TEMPERATURE"
                accentColor: root.accentColor
            }

            SettingStepper {
                width: parent.width
                accentColor: root.accentColor

                title: "Temperature"
                subtitle: "Lower values produce a warmer display tone"

                valueText: backend.nightLightTemperature + " K"

                onDecrease: {
                    backend.setNightLightTemperature(Math.max(1000, backend.nightLightTemperature - 100));
                }

                onIncrease: {
                    backend.setNightLightTemperature(Math.min(6500, backend.nightLightTemperature + 100));
                }
            }

            SectionLabel {
                width: parent.width
                text: "AUTOMATIC SCHEDULE"
                accentColor: root.accentColor
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor

                title: "Automatic activation"
                subtitle: "Enable Night Light automatically during the configured time range"

                checked: backend.nightLightAuto

                onToggled: function (v) {
                    backend.setNightLightAuto(v);
                }
            }

            SettingTimeRow {
                width: parent.width
                accentColor: root.accentColor

                title: "From"
                subtitle: "Automatic Night Light start time · type HH:MM or use the buttons"

                timeText: root.timeText(root.draftFromMinutes)
                enabled: backend.nightLightAuto

                onDecrease: {
                    root.draftFromMinutes = root.stepTime(root.draftFromMinutes, -5);
                }

                onIncrease: {
                    root.draftFromMinutes = root.stepTime(root.draftFromMinutes, 5);
                }

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
                subtitle: "Automatic Night Light end time · type HH:MM or use the buttons"

                timeText: root.timeText(root.draftUntilMinutes)
                enabled: backend.nightLightAuto

                onDecrease: {
                    root.draftUntilMinutes = root.stepTime(root.draftUntilMinutes, -5);
                }

                onIncrease: {
                    root.draftUntilMinutes = root.stepTime(root.draftUntilMinutes, 5);
                }

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

                subtitle: backend.nightLightAuto ? "Save " + root.timeText(root.draftFromMinutes) + " – " + root.timeText(root.draftUntilMinutes) : "Enable Automatic activation to configure a schedule"

                icon: "󰃰"
                buttonText: "APPLY"

                enabled: backend.nightLightAuto

                onTriggered: {
                    backend.applyNightLightSchedule(root.draftFromMinutes, root.draftUntilMinutes);
                }
            }
        }
    }
}
