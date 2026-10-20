import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

RowLayout {
    id: root

    required property var lock

    spacing: Tokens.spacing.largeIncreased * 2

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Tokens.spacing.medium

        Fetch {
            Layout.fillWidth: true
            rootHeight: root.height
        }

        Media {
            Layout.fillWidth: true
            Layout.fillHeight: true
            lock: root.lock
        }

        Resources {
            Layout.fillWidth: true
        }
    }

    Center {
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignVCenter
        lock: root.lock
    }
}
