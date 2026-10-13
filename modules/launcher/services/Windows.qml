pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.services
import qs.utils

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}window `.length);
    }

    // Most recently focused first; the current window goes last so Enter switches to the previous one
    list: [...variants.instances].sort((a, b) => a.order - b.order)
    keys: ["title", "appClass"]
    weights: [0.6, 0.4]
    useFuzzy: GlobalConfig.launcher.useFuzzy.actions

    function selector(item: var): string {
        return `${item.title} ${item.appClass}`;
    }

    Variants {
        id: variants

        // Hyprland also reports unmapped XWayland helper windows (Steam, IME, ...) with no workspace
        model: Hypr.toplevels.values.filter(t => t.workspace)

        Window {}
    }

    component Window: QtObject {
        required property HyprlandToplevel modelData
        readonly property string title: modelData.title
        readonly property string appClass: modelData.lastIpcObject.class ?? ""
        readonly property string workspace: Hypr.trimWsName(modelData.workspace?.name ?? "")
        readonly property int order: {
            const id = modelData.lastIpcObject.focusHistoryID ?? 999;
            return id === 0 ? 1000 : id;
        }

        function onClicked(list: var): void {
            list.screenState.launcher = false;
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "address:0x${modelData.address}" })` : `focuswindow address:0x${modelData.address}`);
        }
    }
}
