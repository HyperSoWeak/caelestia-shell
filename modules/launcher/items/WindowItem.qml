import QtQuick
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.modelData?.onClicked(root.list)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        IconImage {
            id: icon

            asynchronous: true
            source: Icons.getAppIcon(root.modelData?.appClass ?? "", "image-missing")
            implicitSize: parent.height * 0.8

            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width - workspace.width
            implicitHeight: name.implicitHeight + desc.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.title ?? ""
                font: Tokens.font.body.medium

                elide: Text.ElideRight
                width: root.width - icon.width - workspace.width - Tokens.rounding.extraLargeIncreased
            }

            StyledText {
                id: desc

                text: root.modelData?.appClass ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: name.width

                anchors.top: name.bottom
            }
        }

        StyledText {
            id: workspace

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right

            text: root.modelData?.workspace ?? ""
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}
