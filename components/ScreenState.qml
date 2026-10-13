import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool utilities
    property bool sidebar

    // Launcher search text to apply on the next open (e.g. to start in window mode)
    property string launcherText

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
