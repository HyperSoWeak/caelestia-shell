import QtQuick
import Quickshell

QtObject {
    property string currentName
    property bool hasCurrent
    property ShellScreen screen

    signal detachRequested(mode: string)
}
