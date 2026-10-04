pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// Session lock state for the lock screen (modules/lock/LockScreen.qml), replacing hyprlock: locked
// from the session menu, `loginctl lock-session` and before the system sleeps (services/Idle.qml),
// or over IPC. Unlocking only goes through PAM, with the shell's own config (assets/pam.d/lock).
Singleton {
    id: root

    property alias locked: props.locked
    // Every output is covered (WlSessionLock.secure); set by the lock screen.
    property bool secure
    readonly property bool checking: pam.active
    property int failures
    property string message
    // Held only until PAM asks for it.
    property string pending

    function lock(): void {
        if (!locked) {
            failures = 0;
            message = "";
        }
        locked = true;
    }

    function unlock(password: string): void {
        if (pam.active || password === "")
            return;
        message = "";
        pending = password;
        pam.start();
    }

    PersistentProperties {
        id: props

        property bool locked

        reloadableId: "lock"
    }

    PamContext {
        id: pam

        configDirectory: Quickshell.shellDir + "/assets/pam.d"
        config: "lock"

        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(root.pending);
                root.pending = "";
            }
        }
        onCompleted: result => {
            root.pending = "";
            if (result === PamResult.Success) {
                root.locked = false;
                root.failures = 0;
            } else {
                root.failures++;
                root.message = "Wrong password";
            }
        }
        onError: error => {
            root.pending = "";
            root.message = `PAM error: ${PamError.toString(error)}`;
        }
    }

    IpcHandler {
        target: "lock"

        // There is deliberately no unlock here.
        function lock(): void {
            root.lock();
        }

        function isLocked(): bool {
            return root.locked;
        }
    }
}
