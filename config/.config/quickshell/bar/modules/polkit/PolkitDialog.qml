pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// Polkit authentication agent, replacing polkit-gnome: when something asks for authorization
// (pkexec, systemctl, a GUI's "unlock" button) a password card comes up over the focused screen,
// in the session menu's dimmed overlay. Enter submits; Esc, Cancel or a click beside the card
// cancels. A wrong password shakes the field and polkit asks again.
Scope {
    id: root

    readonly property AuthFlow flow: agent.flow
    readonly property bool open: agent.isActive && flow !== null
    // Submitted, waiting for polkit's verdict.
    readonly property bool busy: open && !flow.isResponseRequired && !flow.isCompleted
    // caelestia's offsetScale: 0 = open, 1 = closed (faded out, card a little smaller).
    property real offsetScale: open ? 0 : 1
    // Frozen while open, so moving the pointer to another monitor doesn't drag the card along.
    property ShellScreen screen
    property string error

    function submit(): void {
        if (flow?.isResponseRequired) {
            error = "";
            flow.submit(input.text);
        }
    }

    function cancel(): void {
        flow?.cancelAuthenticationRequest();
    }

    onOpenChanged: {
        if (open) {
            screen = Hypr.focusedScreen;
            error = "";
            input.text = "";
        }
    }

    Behavior on offsetScale {
        EffectsAnim {}
    }

    PolkitAgent {
        id: agent
    }

    Connections {
        target: root.flow

        function onAuthenticationFailed(): void {
            root.error = "Wrong password";
            input.text = "";
            shake.restart();
        }

        function onIsResponseRequiredChanged(): void {
            if (root.flow.isResponseRequired)
                input.forceActiveFocus();
        }
    }

    PanelWindow {
        screen: root.screen
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: root.open || root.offsetScale < 1
        WlrLayershell.namespace: "quickshell-polkit"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: {
            if (visible)
                input.forceActiveFocus();
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.sessionBg
            opacity: 1 - root.offsetScale
        }

        // Clicks beside the card cancel.
        MouseArea {
            anchors.fill: parent
            onClicked: root.cancel()
        }

        Rectangle {
            id: card

            anchors.centerIn: parent
            width: Theme.polkitWidth
            height: content.implicitHeight + Theme.popupPadding * 4
            color: Theme.popupBg
            radius: Theme.dashRadius
            border.width: 2
            border.color: Theme.tooltipBorder
            opacity: 1 - root.offsetScale
            scale: 1 - 0.04 * root.offsetScale

            // Keeps clicks on the card from reaching the cancel area behind it.
            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: content

                x: Theme.popupPadding * 2
                y: Theme.popupPadding * 2
                width: parent.width - Theme.popupPadding * 4
                spacing: Theme.popupSpacing * 1.5

                Row {
                    spacing: 12

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 32
                        source: Quickshell.iconPath(root.flow?.iconName ?? "", "dialog-password")
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.accent
                        text: "Authentication required"
                    }
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.bold: false
                    text: root.flow?.message ?? ""
                }

                Label {
                    visible: text !== ""
                    width: parent.width
                    elide: Text.ElideRight
                    color: Theme.dim
                    text: {
                        const name = root.flow?.selectedIdentity?.displayName ?? "";
                        return name ? `Authenticating as ${name}` : "";
                    }
                }

                // Password field
                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 10
                    color: Theme.surface
                    border.width: 2
                    border.color: root.error ? Theme.critical : input.activeFocus ? Theme.accent : Theme.surfaceHover

                    transform: Translate {
                        id: shakeOffset
                    }

                    SequentialAnimation {
                        id: shake

                        NumberAnimation {
                            target: shakeOffset
                            property: "x"
                            to: -10
                            duration: 50
                        }
                        NumberAnimation {
                            target: shakeOffset
                            property: "x"
                            to: 10
                            duration: 80
                        }
                        NumberAnimation {
                            target: shakeOffset
                            property: "x"
                            to: -6
                            duration: 80
                        }
                        NumberAnimation {
                            target: shakeOffset
                            property: "x"
                            to: 0
                            duration: 60
                        }
                    }

                    TextInput {
                        id: input

                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        enabled: !root.busy
                        echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        renderType: TextInput.NativeRendering
                        color: Theme.fg
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.wsFg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popupFontSize + 1
                        Keys.onReturnPressed: root.submit()
                        Keys.onEnterPressed: root.submit()
                        Keys.onEscapePressed: root.cancel()

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === ""
                            color: Theme.dim
                            font.bold: false
                            text: root.busy ? "Authenticating…" : (root.flow?.inputPrompt ?? "Password").replace(/:\s*$/, "")
                        }
                    }
                }

                // Polkit's own messages (e.g. a fingerprint prompt), or ours after a failed attempt.
                Label {
                    visible: text !== ""
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.bold: false
                    color: root.error || root.flow?.supplementaryIsError ? Theme.critical : Theme.dim
                    text: root.error || (root.flow?.supplementaryMessage ?? "")
                }

                Row {
                    anchors.right: parent.right
                    spacing: Theme.popupSpacing

                    Button {
                        text: "Cancel"
                        onClicked: root.cancel()
                    }
                    Button {
                        text: "Authenticate"
                        primary: true
                        enabled: !root.busy && input.text !== ""
                        onClicked: root.submit()
                    }
                }
            }
        }
    }

    component Button: MouseArea {
        id: button

        property alias text: label.text
        property bool primary

        implicitWidth: label.implicitWidth + 32
        implicitHeight: 36
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        opacity: enabled ? 1 : 0.5

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: button.primary ? Theme.accent : button.containsMouse ? Theme.surfaceHover : Theme.surface
            opacity: button.primary && button.containsMouse ? 0.85 : 1
        }

        Label {
            id: label

            anchors.centerIn: parent
            color: button.primary ? Theme.wsFg : Theme.fg
        }
    }

    component Label: StyledText {
        font.pixelSize: Theme.popupFontSize
    }
}
