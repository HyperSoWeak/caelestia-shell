pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.containers
import qs.components.misc
import qs.services

Scope {
    LazyLoader {
        id: root

        property bool freeze
        property bool closing
        property bool clipboardOnly
        property bool menuMode: false
        property string captureMode: "menu"

        Variants {
            model: Screens.screens

            StyledWindow {
                id: win

                required property ShellScreen modelData

                screen: modelData
                name: "area-picker"
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: root.closing ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
                mask: root.closing ? empty : null

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                Region {
                    id: empty
                }

                Picker {
                    loader: root
                    screen: win.modelData
                }
            }
        }
    }

    IpcHandler {
        function open(): void {
            root.menuMode = false;
            root.freeze = false;
            root.closing = false;
            root.clipboardOnly = false;
            root.activeAsync = true;
        }

        function openFreeze(): void {
            root.menuMode = false;
            root.freeze = true;
            root.closing = false;
            root.clipboardOnly = false;
            root.activeAsync = true;
        }

        function openClip(): void {
            root.menuMode = false;
            root.freeze = false;
            root.closing = false;
            root.clipboardOnly = true;
            root.activeAsync = true;
        }

        function openFreezeClip(): void {
            root.menuMode = false;
            root.freeze = true;
            root.closing = false;
            root.clipboardOnly = true;
            root.activeAsync = true;
        }

        function openFreezeMenu(): void {
            root.menuMode = true;
            root.captureMode = "menu";
            root.freeze = true;
            root.closing = false;
            root.clipboardOnly = false;
            root.activeAsync = true;
        }

        function closeMenu(): void {
            if (root.menuMode)
                root.activeAsync = false;
        }

        target: "picker"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "screenshot"
        description: "Open screenshot tool"
        onPressed: {
            root.menuMode = false;
            root.freeze = false;
            root.closing = false;
            root.clipboardOnly = false;
            root.activeAsync = true;
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "screenshotFreeze"
        description: "Open screenshot tool (freeze mode)"
        onPressed: {
            root.menuMode = false;
            root.freeze = true;
            root.closing = false;
            root.clipboardOnly = false;
            root.activeAsync = true;
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "screenshotClip"
        description: "Open screenshot tool (clipboard)"
        onPressed: {
            root.menuMode = false;
            root.freeze = false;
            root.closing = false;
            root.clipboardOnly = true;
            root.activeAsync = true;
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "screenshotFreezeClip"
        description: "Open screenshot tool (freeze mode, clipboard)"
        onPressed: {
            root.menuMode = false;
            root.freeze = true;
            root.closing = false;
            root.clipboardOnly = true;
            root.activeAsync = true;
        }
    }
}
