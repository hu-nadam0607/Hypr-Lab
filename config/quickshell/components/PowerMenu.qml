import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property bool isOpen: false
    property bool windowVisible: false
    property bool cardsShown: false

    AdaptiveAccent {
        id: adaptiveAccent
    }
    readonly property color accent: adaptiveAccent.accentColor

    function open(): void {
        closeTimer.stop();
        if (windowVisible && isOpen)
            return;
        windowVisible = true;
        isOpen = true;
        cardsShown = false;
        revealTimer.restart();
    }

    function close(): void {
        if (!windowVisible || !isOpen)
            return;
        revealTimer.stop();
        isOpen = false;
        cardsShown = false;
        closeTimer.restart();
    }

    function toggle(): void {
        isOpen ? close() : open();
    }

    IpcHandler {
        target: "powermenu"
        function toggle() {
            root.toggle();
        }
        function open() {
            root.open();
        }
        function close() {
            root.close();
        }
    }

    Timer {
        id: revealTimer
        interval: 12
        repeat: false
        onTriggered: if (root.isOpen)
            root.cardsShown = true
    }

    Timer {
        id: closeTimer
        // Last card starts after 105 ms and needs 205 ms to leave.
        interval: 330
        repeat: false
        onTriggered: if (!root.isOpen)
            root.windowVisible = false
    }

    PanelWindow {
        id: window
        visible: root.windowVisible
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        aboveWindows: true

        WlrLayershell.namespace: "hypr-lab-power-menu"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        FocusScope {
            anchors.fill: parent
            focus: window.visible
            Keys.onEscapePressed: root.close()

            // Intentionally transparent: no fullscreen dimming and no fullscreen blur.
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            Item {
                id: stage
                anchors.centerIn: parent
                width: Math.min(window.width - 160, 1060)
                height: 340

                Row {
                    id: cards
                    anchors.centerIn: parent
                    spacing: 28

                    // Clicking a card is accepted by its own MouseArea, so the
                    // fullscreen close area underneath only handles empty space.
                    PowerMenuOption {
                        iconText: "󰌾"
                        labelText: "Lock"
                        accentColor: root.accent
                        shown: root.cardsShown
                        revealDelay: 0
                        closeDelay: 105
                        actionCommand: ["quickshell", "-p", Quickshell.env("HOME") + "/.config/quickshell/lock/shell.qml"]
                        onTriggered: root.close()
                    }

                    PowerMenuOption {
                        iconText: "󰍃"
                        labelText: "Logout"
                        accentColor: Qt.lighter(root.accent, 1.18)
                        shown: root.cardsShown
                        revealDelay: 42
                        closeDelay: 70
                        actionCommand: [Quickshell.env("HOME") + "/.config/hypr/hyprlab-scripts/hyprlab-exit.sh"]
                        onTriggered: root.close()
                    }

                    PowerMenuOption {
                        iconText: "󰑓"
                        labelText: "Reboot"
                        accentColor: Qt.tint(root.accent, Qt.rgba(0.38, 0.18, 0.90, 0.42))
                        shown: root.cardsShown
                        revealDelay: 84
                        closeDelay: 35
                        actionCommand: ["systemctl", "reboot"]
                        onTriggered: root.close()
                    }

                    PowerMenuOption {
                        iconText: "󰐥"
                        labelText: "Shutdown"
                        accentColor: "#ef6657"
                        shown: root.cardsShown
                        revealDelay: 126
                        closeDelay: 0
                        actionCommand: ["systemctl", "poweroff"]
                        onTriggered: root.close()
                    }
                }
            }
        }
    }
}
