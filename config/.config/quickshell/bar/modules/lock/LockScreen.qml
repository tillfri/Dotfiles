pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// The lock screen, replacing hyprlock (laid out like ~/.config/hypr/hyprlock.conf): on every screen
// the blurred desktop, the time and date, and a password field. Enter unlocks, Esc clears the field.
// Locking and the PAM check are in services/Lock.qml.
WlSessionLock {
    id: root

    locked: Lock.locked
    onSecureChanged: Lock.secure = secure
    // The lock can also end without an unlock (the compositor finishing it); the service would then
    // still count as locked, and every later lock() would do nothing.
    onLockedChanged: {
        if (!locked && Lock.locked) {
            console.warn("Session lock ended without an unlock");
            Lock.locked = false;
        }
    }

    WlSessionLockSurface {
        id: surface

        color: Theme.lockTint

        // Whatever was on this screen when it locked, blurred and darkened.
        ScreencopyView {
            anchors.fill: parent
            captureSource: surface.screen
            layer.enabled: true
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1
                blurMax: 64
                brightness: -0.2
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.lockTint
            opacity: 0.4
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 45

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.lockFg
                font.pixelSize: 120
                text: Time.format("hh:mm")
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.lockFg
                font.pixelSize: 32
                font.bold: false
                text: Time.format("dddd, d MMMM yyyy")
            }
        }

        Rectangle {
            id: field

            anchors.centerIn: parent
            width: 450
            height: 90
            radius: height / 2
            color: Qt.rgba(10 / 255, 10 / 255, 10 / 255, 0.85)
            border.width: 4
            border.color: Lock.message ? Theme.critical : Lock.checking ? Theme.accent : Theme.lockFg

            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.durationEffects
                }
            }

            transform: Translate {
                id: shakeOffset
            }

            SequentialAnimation {
                id: shake

                NumberAnimation {
                    target: shakeOffset
                    property: "x"
                    to: -14
                    duration: 50
                }
                NumberAnimation {
                    target: shakeOffset
                    property: "x"
                    to: 14
                    duration: 80
                }
                NumberAnimation {
                    target: shakeOffset
                    property: "x"
                    to: -8
                    duration: 80
                }
                NumberAnimation {
                    target: shakeOffset
                    property: "x"
                    to: 0
                    duration: 60
                }
            }

            Connections {
                target: Lock

                function onFailuresChanged(): void {
                    if (Lock.failures > 0) {
                        input.text = "";
                        shake.restart();
                    }
                }

                function onLockedChanged(): void {
                    input.text = "";
                }
            }

            TextInput {
                id: input

                anchors.fill: parent
                anchors.leftMargin: 32
                anchors.rightMargin: 32
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                focus: true
                enabled: !Lock.checking
                echoMode: TextInput.Password
                passwordCharacter: "●"
                renderType: TextInput.NativeRendering
                color: Theme.lockFg
                font.family: Theme.fontFamily
                font.pixelSize: 22
                font.letterSpacing: 4
                cursorVisible: false
                cursorDelegate: Item {}
                Keys.onReturnPressed: Lock.unlock(text)
                Keys.onEnterPressed: Lock.unlock(text)
                Keys.onEscapePressed: text = ""
                // A key while the message shows starts a new attempt.
                onTextChanged: if (text !== "")
                    Lock.message = ""
            }

            StyledText {
                anchors.centerIn: parent
                visible: input.text === ""
                color: Theme.lockFg
                opacity: 0.7
                font.pixelSize: 18
                font.bold: false
                font.italic: true
                text: Lock.checking ? "Checking…" : `\u{f033e}  Logged in as ${Quickshell.env("USER")}`
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: field.bottom
            anchors.topMargin: 20
            visible: Lock.message !== ""
            color: Theme.critical
            font.pixelSize: 18
            text: Lock.failures > 1 ? `${Lock.message} (${Lock.failures})` : Lock.message
        }
    }
}
