import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: rightBarRoot

    property int barWidth: 1080
    property int barHeight: 40

    property bool capsLockActive: false
    property bool numLockActive: false
    property bool usbAvailable: false

    signal openControlCenter()
    signal openPowerMenu()
    signal toggleUsbManager(var anchorItem)

    implicitWidth: barWidth
    implicitHeight: barHeight

    function refreshLockStates() {
        if (!lockStateProcess.running)
            lockStateProcess.running = true
    }

    Capsule {
        id: capsule
        anchors.fill: parent
        capsuleWidth: rightBarRoot.barWidth
        capsuleHeight: rightBarRoot.barHeight
    }

    Shadow {
        sourceItem: capsule
        z: -2
    }

    Glow {
        sourceItem: capsule
        z: -1
    }

    // A kernel LED állapotait olvassuk. Ez nem függ külön X11-es segédprogramtól,
    // és Waylanden is a tényleges billentyűzetállapotot követi.
    Process {
        id: lockStateProcess
        command: [
            "sh", "-c",
            "for k in capslock numlock; do " +
            "v=0; " +
            "for f in /sys/class/leds/input*::$k/brightness; do " +
            "if [ -r \"$f\" ]; then read x < \"$f\"; " +
            "if [ \"${x:-0}\" -gt 0 ] 2>/dev/null; then v=1; break; fi; fi; " +
            "done; printf '%s' \"$v\"; " +
            "[ \"$k\" != numlock ] && printf '|'; done; printf '\\n'"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|")
                if (parts.length !== 2)
                    return

                rightBarRoot.capsLockActive = parts[0] === "1"
                rightBarRoot.numLockActive = parts[1] === "1"
            }
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: rightBarRoot.refreshLockStates()
    }

    Row {
        id: contentRow

        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        spacing: 7
        z: 1

        // USB manager – csak akkor látható, ha USB háttértár van csatlakoztatva.
        BarActionButton {
            id: usbButton
            visible: rightBarRoot.usbAvailable
            icon: "󰕓"
            iconSize: 17
            anchors.verticalCenter: parent.verticalCenter
            onClicked: rightBarRoot.toggleUsbManager(usbButton)
        }

        // Audio – közvetlen belépés a Control Center Audio oldalára.
        BarActionButton {
            id: audioButton
            icon: "󰕾"
            iconSize: 17
            anchors.verticalCenter: parent.verticalCenter
            onClicked: Quickshell.execDetached(["qs", "ipc", "call", "controlcenter", "audio"])
        }

        // Control Center – állandó, közvetlen belépési pont.
        BarActionButton {
            id: controlCenterButton
            icon: "󰒓"
            iconSize: 17
            anchors.verticalCenter: parent.verticalCenter
            onClicked: Quickshell.execDetached(["qs", "ipc", "call", "controlcenter", "toggle"])
        }

        Rectangle {
            width: 1
            height: 18
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        // Caps Lock és Num Lock mindig látható: cyan = aktív, tompa = kikapcsolt.
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            LockIndicator {
                symbol: "A"
                active: rightBarRoot.capsLockActive
            }

            LockIndicator {
                symbol: "1"
                active: rightBarRoot.numLockActive
            }
        }

        Rectangle {
            width: 1
            height: 18
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        SysTray {
            id: sysTray
        }

        PowerButton {
            id: powerButton

            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter

            onClicked: rightBarRoot.openPowerMenu()
        }
    }
}
