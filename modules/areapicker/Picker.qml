pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

MouseArea {
    id: root

    required property LazyLoader loader
    required property ShellScreen screen

    property bool onClient
    readonly property string captureMode: loader.menuMode ? loader.captureMode : "auto"
    readonly property bool snapshotReady: screencopy.item ? screencopy.item.hasContent : false
    property int menuIndex: 0

    function chooseMode(index: int): void {
        if (!snapshotReady)
            return;
        if (index === 0) {
            loader.captureMode = "fullscreen";
            onClient = false;
            sx = sy = 0;
            ex = screen.width;
            ey = screen.height;
            save();
        } else {
            loader.captureMode = index === 1 ? "window" : "region";
        }
    }

    onCaptureModeChanged: {
        if (captureMode === "region") {
            onClient = false;
            sx = sy = ex = ey = 0;
        } else if (captureMode === "window") {
            onClient = false;
            checkClientRects(mouseX, mouseY);
        }
    }

    property real realBorderWidth: onClient ? (Hypr.options["general:border_size"] ?? 1) : 2
    property real realRounding: onClient ? (Hypr.options["decoration:rounding"] ?? 0) : 0

    property real ssx
    property real ssy

    property real sx: 0
    property real sy: 0
    property real ex: screen.width
    property real ey: screen.height

    property real rsx: Math.min(sx, ex)
    property real rsy: Math.min(sy, ey)
    property real sw: Math.abs(sx - ex)
    property real sh: Math.abs(sy - ey)

    property list<var> clients: {
        const mon = Hypr.monitorFor(screen);
        if (!mon)
            return [];

        const special = mon.lastIpcObject?.specialWorkspace;
        const wsId = special?.name ? special.id : mon.activeWorkspace?.id;
        if (wsId === undefined)
            return [];

        return Hypr.toplevelsForWs(wsId).sort((a, b) => {
            // Pinned first, then fullscreen, then floating, then any other
            const ac = a?.lastIpcObject;
            const bc = b?.lastIpcObject;
            if (!ac || !bc)
                return !ac - !bc; // Missing IPC last
            return (bc.pinned - ac.pinned) || ((bc.fullscreen !== 0) - (ac.fullscreen !== 0)) || (bc.floating - ac.floating);
        });
    }

    function checkClientRects(x: real, y: real): void {
        if (captureMode === "menu" || captureMode === "region" || captureMode === "fullscreen")
            return;
        if (captureMode === "window") {
            onClient = false;
            sx = sy = ex = ey = 0;
        }
        for (const client of clients) {
            if (!client)
                continue;

            const ipc = client.lastIpcObject;
            if (!ipc?.at || !ipc?.size)
                continue;

            let {
                at: [cx, cy],
                size: [cw, ch]
            } = ipc;
            cx -= screen.x;
            cy -= screen.y;
            if (cx <= x && cy <= y && cx + cw >= x && cy + ch >= y) {
                onClient = true;
                sx = cx;
                sy = cy;
                ex = cx + cw;
                ey = cy + ch;
                break;
            }
        }
    }

    function save(): void {
        const tmpfile = Qt.resolvedUrl(`/tmp/caelestia-picker-${Quickshell.processId}-${Date.now()}.png`);
        CUtils.saveItem(screencopy, tmpfile, Qt.rect(Math.ceil(rsx), Math.ceil(rsy), Math.floor(sw), Math.floor(sh)), path => {
            if (root.loader.clipboardOnly) {
                Quickshell.execDetached(["sh", "-c", "wl-copy --type image/png < " + path]);
                Quickshell.execDetached(["notify-send", "-a", "caelestia-cli", "-i", path, Tr.tr("Screenshot taken"), Tr.tr("Screenshot copied to clipboard")]);
            } else {
                Quickshell.execDetached(["swappy", "-f", path]);
            }
            closeAnim.start();
        });
    }

    onClientsChanged: checkClientRects(mouseX, mouseY)

    anchors.fill: parent
    opacity: 0
    hoverEnabled: true
    cursorShape: Qt.CrossCursor

    Component.onCompleted: {
        Hypr.extras.refreshOptions();

        // Break binding if frozen
        if (loader.freeze)
            clients = clients;

        opacity = 1;

        const ipc = clients[0]?.lastIpcObject;
        if (ipc?.at && ipc?.size) {
            const cx = ipc.at[0] - screen.x;
            const cy = ipc.at[1] - screen.y;
            onClient = true;
            sx = cx;
            sy = cy;
            ex = cx + ipc.size[0];
            ey = cy + ipc.size[1];
        } else {
            sx = screen.width / 2 - 100;
            sy = screen.height / 2 - 100;
            ex = screen.width / 2 + 100;
            ey = screen.height / 2 + 100;
        }
    }

    onPressed: event => {
        if (captureMode === "menu" || captureMode === "window")
            return;
        ssx = event.x;
        ssy = event.y;
    }

    onReleased: {
        if (closeAnim.running || captureMode === "menu" || (captureMode === "window" && !onClient) || sw < 1 || sh < 1)
            return;

        if (root.loader.freeze) {
            save();
        } else {
            overlay.visible = border.visible = false;
            screencopy.visible = false;
            screencopy.active = true;
        }
    }

    onPositionChanged: event => {
        const x = event.x;
        const y = event.y;

        if (captureMode === "menu")
            return;
        if (captureMode === "window") {
            checkClientRects(x, y);
            return;
        }
        if (pressed) {
            onClient = false;
            sx = ssx;
            sy = ssy;
            ex = x;
            ey = y;
        } else {
            checkClientRects(x, y);
        }
    }

    focus: true
    Keys.onEscapePressed: closeAnim.start()
    Keys.onPressed: event => {
        if (captureMode !== "menu")
            return;
        if (event.key === Qt.Key_Down) {
            menuIndex = (menuIndex + 1) % 3;
        } else if (event.key === Qt.Key_Up) {
            menuIndex = (menuIndex + 2) % 3;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            chooseMode(menuIndex);
        } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_3) {
            chooseMode(event.key - Qt.Key_1);
        } else {
            return;
        }
        event.accepted = true;
    }

    SequentialAnimation {
        id: closeAnim

        PropertyAction {
            target: root.loader
            property: "closing"
            value: true
        }
        ParallelAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: Anim.StandardLarge
            }
            Anim {
                target: root
                properties: "rsx,rsy"
                to: 0
            }
            Anim {
                target: root
                property: "sw"
                to: root.screen.width
            }
            Anim {
                target: root
                property: "sh"
                to: root.screen.height
            }
        }
        PropertyAction {
            target: root.loader
            property: "activeAsync"
            value: false
        }
    }

    Process {
        running: true
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const pos = JSON.parse(text);
                root.checkClientRects(pos.x - root.screen.x, pos.y - root.screen.y);
            }
        }
    }

    Loader {
        id: screencopy

        asynchronous: true
        anchors.fill: parent

        active: root.loader.freeze

        sourceComponent: ScreencopyView {
            captureSource: root.screen

            onHasContentChanged: {
                if (hasContent && !root.loader.freeze) {
                    overlay.visible = border.visible = true;
                    root.save();
                }
            }
        }
    }

    StyledRect {
        id: overlay

        anchors.fill: parent
        color: root.captureMode === "menu" ? Colours.palette.m3scrim : Colours.palette.m3secondaryContainer
        opacity: root.captureMode === "menu" ? 0.32 : 0.3

        // The chooser dims the whole screen; selection modes reveal the crop.
        layer.enabled: root.captureMode !== "menu"
        layer.effect: Mask {
            maskSource: selectionWrapper
            maskInverted: true
        }
    }

    Item {
        id: selectionWrapper

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            id: selectionRect

            radius: root.realRounding
            x: root.rsx
            y: root.rsy
            implicitWidth: root.sw
            implicitHeight: root.sh
        }
    }

    Rectangle {
        id: border

        visible: root.captureMode !== "menu" && root.sw > 0 && root.sh > 0
        color: "transparent"
        radius: root.realRounding > 0 ? root.realRounding + root.realBorderWidth : 0
        border.width: root.realBorderWidth
        border.color: Colours.palette.m3primary

        x: selectionRect.x - root.realBorderWidth
        y: selectionRect.y - root.realBorderWidth
        implicitWidth: selectionRect.implicitWidth + root.realBorderWidth * 2
        implicitHeight: selectionRect.implicitHeight + root.realBorderWidth * 2

        Behavior on border.color {
            CAnim {}
        }
    }

    Elevation {
        id: captureMenu

        anchors.centerIn: parent
        implicitWidth: Math.max(260, menuContent.implicitWidth + Tokens.padding.medium * 2)
        implicitHeight: menuContent.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.large
        level: 2
        visible: root.captureMode === "menu" && root.snapshotReady

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerLow

            ColumnLayout {
                id: menuContent

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: Tokens.spacing.small
                    text: "Screenshot"
                    font: Tokens.font.title.small
                }

                Repeater {
                    model: [
                        { label: "Full screen", icon: "desktop_windows" },
                        { label: "Window", icon: "select_window" },
                        { label: "Region", icon: "crop_free" }
                    ]

                    delegate: IconTextButton {
                        id: option

                        required property int index
                        required property var modelData

                        Layout.fillWidth: true
                        text: modelData.label
                        icon: modelData.icon
                        type: IconTextButton.Filled
                        isToggle: true
                        checked: root.menuIndex === index
                        // Keep matching foreground/background pairs in both states.
                        activeColour: Colours.palette.m3primary
                        activeOnColour: Colours.palette.m3onPrimary
                        inactiveColour: Colours.palette.m3surfaceContainerHigh
                        inactiveOnColour: Colours.palette.m3onSurface
                        verticalPadding: Tokens.padding.medium
                        onClicked: root.chooseMode(index)

                        Connections {
                            target: option.stateLayer
                            function onEntered(): void {
                                root.menuIndex = option.index;
                            }
                        }
                    }
                }
            }
        }
    }

    Behavior on opacity {
        Anim {
            type: Anim.StandardLarge
        }
    }

    Behavior on rsx {
        enabled: !root.pressed && !root.loader.menuMode

        Anim {}
    }

    Behavior on rsy {
        enabled: !root.pressed && !root.loader.menuMode

        Anim {}
    }

    Behavior on sw {
        enabled: !root.pressed && !root.loader.menuMode

        Anim {}
    }

    Behavior on sh {
        enabled: !root.pressed && !root.loader.menuMode

        Anim {}
    }
}
