//@ pragma ShellId hypr-lab-lock
//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import "components"

ShellRoot {
    id: root

    property string username: Quickshell.env("USER") || "user"
    property string pendingPassword: ""
    property string authMessage: ""
    property bool authBusy: false
    property bool authSucceeded: false
    property bool unlockStarted: false
    property int authFailureSerial: 0

    function authenticate(password) {
        if (authBusy || authSucceeded || password.length === 0)
            return

        pendingPassword = password
        authMessage = ""
        authBusy = true

        if (!pam.active) {
            if (!pam.start()) {
                authBusy = false
                authMessage = "A hitelesítés nem indítható."
                authFailureSerial++
            }
        } else if (pam.responseRequired) {
            pam.respond(pendingPassword)
            pendingPassword = ""
        }
    }

    function completeUnlock() {
        if (unlockStarted)
            return

        unlockStarted = true
        sessionLock.locked = false
        Qt.quit()
    }

    Timer {
        id: unlockTimer
        interval: 520
        repeat: false
        onTriggered: root.completeUnlock()
    }

    PamContext {
        id: pam
        config: "login"

        onPamMessage: {
            if (responseRequired && root.pendingPassword.length > 0) {
                const response = root.pendingPassword
                root.pendingPassword = ""
                respond(response)
            } else if (messageIsError && message.length > 0) {
                root.authMessage = message
            }
        }

        onCompleted: result => {
            root.authBusy = false
            root.pendingPassword = ""

            if (result === PamResult.Success) {
                // A vizuális exit animáció minden lock surface-en elindul,
                // a tényleges unlockot viszont a root Timer végzi megbízhatóan.
                root.authSucceeded = true
                unlockTimer.restart()
            } else {
                root.authMessage = "Hibás jelszó"
                root.authFailureSerial++
            }
        }

        onError: error => {
            root.authBusy = false
            root.pendingPassword = ""
            root.authMessage = "Hitelesítési hiba"
            root.authFailureSerial++
            console.warn("Hypr-Lab Lock PAM error:", error)
        }
    }

    WlSessionLock {
        id: sessionLock

        surface: Component {
            LockSurface {
                controller: root
            }
        }
    }

    Component.onCompleted: sessionLock.locked = true
}
