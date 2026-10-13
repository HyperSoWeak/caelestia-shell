pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Smoothed time-to-empty from ~/.local/bin/battery-estimate (15 min average draw).
// Falls back to UPower's instantaneous estimate until the script has enough data.
Singleton {
    id: root

    property int smoothedSeconds: -1

    readonly property int timeToEmpty: smoothedSeconds > 0 ? smoothedSeconds : UPower.displayDevice.timeToEmpty

    FileView {
        id: file

        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/battery-estimate.json`
        printErrors: false
        onLoaded: {
            try {
                root.smoothedSeconds = JSON.parse(text()).seconds;
            } catch (e) {
                root.smoothedSeconds = -1;
            }
        }
        onLoadFailed: root.smoothedSeconds = -1
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: file.reload()
    }
}
