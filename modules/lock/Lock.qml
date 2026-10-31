pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Services
import qs.components.misc
import qs.services

Scope {
    id: root

    property alias lock: lock

    function wakeDisplays(): void {
        dpmsOffDelay.stop();
        Hypr.setDpms(true);
    }

    WlSessionLock {
        id: lock

        signal unlock

        LockSurface {
            lock: lock
            pam: pam
        }
    }

    Pam {
        id: pam

        lock: lock
    }

    Connections {
        function onLockedChanged(): void {
            if (lock.locked)
                dpmsOffDelay.restart();
            else
                root.wakeDisplays();
        }

        function onUnlock(): void {
            root.wakeDisplays();
        }

        target: lock
    }

    Connections {
        function onResumed(): void {
            if (lock.locked)
                root.wakeDisplays();
        }

        target: SessionManager
    }

    Timer {
        id: dpmsOffDelay

        // Let the lock surface capture the screen first, and the key release from the lock bind pass
        interval: 1000
        onTriggered: Hypr.setDpms(false)
    }

    // Input wakes the displays while locked, so turn them back off once it stops
    IdleMonitor {
        enabled: lock.locked
        timeout: 30
        respectInhibitors: false
        onIsIdleChanged: {
            if (isIdle)
                Hypr.setDpms(false);
        }
    }

    Loader {
        asynchronous: true
        active: true
        onLoaded: active = false

        // Force a load of a screencopy so the one in the lock works
        // My guess is the ICC backend loads async on first request, which if the lock is
        // the first request it fails to capture (because it's async and the compositor
        // refuses capture when locked)
        sourceComponent: ScreencopyView {
            captureSource: Quickshell.screens[0]
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "lock"
        description: "Lock the current session"
        onPressed: lock.locked = true
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "unlock"
        description: "Unlock the current session"
        onPressed: lock.unlock()
    }

    IpcHandler {
        function lock(): void {
            lock.locked = true;
        }

        function unlock(): void {
            lock.unlock();
        }

        function isLocked(): bool {
            return lock.locked;
        }

        target: "lock"
    }
}
