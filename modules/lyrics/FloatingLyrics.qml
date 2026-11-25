pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.components.misc
import qs.modules.dashboard.media
import qs.services
import qs.utils

Scope {
    id: root

    function toggle(): void {
        adapter.enabled = !adapter.enabled;
    }

    FileView {
        path: `${Paths.state}/lyrics.json`
        blockLoading: true
        printErrors: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter

            property bool enabled: false
            property string screen: ""
            property real x: -1
            property real y: -1
            property real width: 400
            property real height: 300
            property bool showRomanization: false
            property bool showTranslation: false
        }
    }

    LazyLoader {
        active: adapter.enabled && Players.active !== null

        StyledWindow {
            id: win

            screen: Screens.screens.find(s => s.name === adapter.screen) ?? Screens.screens[0]
            name: "lyrics"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // Fullscreen transparent surface so dragging only moves an item instead of reconfiguring the surface
            mask: Region {
                x: box.x
                y: box.y
                width: box.width
                height: box.height
            }

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            function commitPosition(): void {
                // Box may have been dragged past the edge, so pick the screen containing its centre
                const cx = win.screen.x + box.x + box.width / 2;
                const cy = win.screen.y + box.y + box.height / 2;
                const target = Screens.screens.find(s => cx >= s.x && cx < s.x + s.width && cy >= s.y && cy < s.y + s.height) ?? win.screen;

                adapter.x = Math.max(0, Math.min(cx - box.width / 2 - target.x, target.width - box.width));
                adapter.y = Math.max(0, Math.min(cy - box.height / 2 - target.y, target.height - box.height));
                adapter.screen = target.name;

                box.x = Qt.binding(() => box.restX);
                box.y = Qt.binding(() => box.restY);
            }

            function commitSize(): void {
                adapter.width = box.implicitWidth;
                adapter.height = box.implicitHeight;

                box.implicitWidth = Qt.binding(() => adapter.width);
                box.implicitHeight = Qt.binding(() => adapter.height);
            }

            Timer {
                running: Players.active?.isPlaying ?? false
                interval: GlobalConfig.dashboard.mediaUpdateInterval
                triggeredOnStart: true
                repeat: true
                onTriggered: Players.active?.positionChanged()
            }

            Item {
                id: box

                readonly property real restX: adapter.x < 0 ? win.width - width - Tokens.padding.extraLargeIncreased * 2 : Math.min(adapter.x, win.width - width)
                readonly property real restY: adapter.y < 0 ? Tokens.padding.extraLargeIncreased * 2 : Math.min(adapter.y, win.height - height)

                x: restX
                y: restY
                implicitWidth: adapter.width
                implicitHeight: adapter.height

                Elevation {
                    anchors.fill: parent
                    radius: Tokens.rounding.large
                    level: 2
                }

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.large
                    color: Colours.tPalette.m3surfaceContainer

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.large
                        spacing: Tokens.spacing.small

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: header.implicitHeight

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                drag.target: box
                                drag.threshold: 0
                                onReleased: win.commitPosition()
                            }

                            RowLayout {
                                id: header

                                anchors.left: parent.left
                                anchors.right: parent.right
                                spacing: Tokens.spacing.medium

                                MaterialIcon {
                                    text: "lyrics"
                                    color: Colours.palette.m3primary
                                    fontStyle: Tokens.font.icon.medium
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Players.active?.trackTitle || Tr.tr("No media")
                                        font: Tokens.font.title.small
                                        elide: Text.ElideRight
                                        animate: true
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        visible: text.length > 0
                                        text: Players.active?.trackArtist ?? ""
                                        color: Colours.palette.m3onSurfaceVariant
                                        font: Tokens.font.body.small
                                        elide: Text.ElideRight
                                        animate: true
                                    }
                                }

                                IconButton {
                                    visible: Lyrics.hasRomanization
                                    isRound: true
                                    isToggle: true
                                    checked: adapter.showRomanization
                                    icon: "match_case"
                                    type: IconButton.Text
                                    onClicked: adapter.showRomanization = !adapter.showRomanization
                                }

                                IconButton {
                                    visible: Lyrics.hasTranslation
                                    isRound: true
                                    isToggle: true
                                    checked: adapter.showTranslation
                                    icon: "translate"
                                    type: IconButton.Text
                                    onClicked: adapter.showTranslation = !adapter.showTranslation
                                }

                                IconButton {
                                    isRound: true
                                    icon: "close"
                                    type: IconButton.Text
                                    onClicked: adapter.enabled = false
                                }
                            }
                        }

                        LyricList {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            showRomanization: adapter.showRomanization
                            showTranslation: adapter.showTranslation
                        }
                    }
                }

                MouseArea {
                    property point start
                    property size startSize

                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    implicitWidth: Tokens.padding.large * 2
                    implicitHeight: Tokens.padding.large * 2
                    cursorShape: Qt.SizeFDiagCursor
                    preventStealing: true

                    onPressed: event => {
                        start = mapToItem(win.contentItem, event.x, event.y);
                        startSize = Qt.size(box.implicitWidth, box.implicitHeight);
                    }
                    onPositionChanged: event => {
                        const p = mapToItem(win.contentItem, event.x, event.y);
                        box.implicitWidth = Math.max(260, Math.min(startSize.width + p.x - start.x, win.width - box.x));
                        box.implicitHeight = Math.max(160, Math.min(startSize.height + p.y - start.y, win.height - box.y));
                    }
                    onReleased: win.commitSize()
                }
            }
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "lyrics"
        description: "Toggle floating lyrics"
        onPressed: root.toggle()
    }

    IpcHandler {
        function toggle(): void {
            root.toggle();
        }

        target: "lyrics"
    }
}
