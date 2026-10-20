pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.effects
import qs.services
import qs.utils

StyledRect {
    id: root

    required property real rootHeight
    readonly property int cBoxSize: Tokens.font.body.medium.pointSize * 2
    readonly property var info: {
        // Flat key/value pairs for the 2-column grid
        const items = [Tr.tr("OS"), SysInfo.osPrettyName || SysInfo.osName, Tr.tr("WM"), SysInfo.wm, Tr.tr("USER"), SysInfo.user, Tr.tr("UP"), SysInfo.uptimeShort];

        if (UPower.displayDevice.isLaptopBattery) {
            const charging = [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state);
            const pct = Math.round(UPower.displayDevice.percentage * 100);
            items.push(Tr.tr("BATT"), charging ? `${pct}% (+)` : `${pct}%`);
        }

        return items;
    }

    implicitHeight: layout.implicitHeight + Tokens.padding.extraLarge * 2
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraLarge
        spacing: Tokens.spacing.large

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Tokens.spacing.extraLarge

            Loader {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: height
                Layout.preferredHeight: infoGrid.implicitHeight * 0.75

                asynchronous: true
                sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : distroIcon
            }

            GridLayout {
                id: infoGrid

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                columns: 2
                columnSpacing: Tokens.spacing.large
                rowSpacing: Tokens.spacing.small

                Repeater {
                    model: root.info

                    MonoText {
                        required property string modelData
                        required property int index

                        Layout.fillWidth: index % 2 === 1
                        text: modelData
                        color: index % 2 === 0 ? Colours.palette.m3primary : Colours.palette.m3onSurface
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Loader {
            Layout.alignment: Qt.AlignHCenter
            active: root.rootHeight > Tokens.sizes.lock.showColourBoxRowHeight
            visible: active
            asynchronous: true

            sourceComponent: RowLayout {
                id: coloursRow

                spacing: Tokens.spacing.largeIncreased

                Repeater {
                    model: CUtils.clamp(Math.floor((layout.width + coloursRow.spacing) / (root.cBoxSize + coloursRow.spacing)), 0, 8)

                    StyledRect {
                        required property int index

                        implicitWidth: implicitHeight
                        implicitHeight: root.cBoxSize
                        color: Colours.palette[`term${index}`]
                        radius: Tokens.rounding.medium
                    }
                }
            }
        }
    }

    Component {
        id: caelestiaLogo

        Logo {
            width: height
        }
    }

    Component {
        id: distroIcon

        ColouredIcon {
            source: SysInfo.osLogo
            implicitSize: height
            colour: Colours.palette.m3primary
            layer.enabled: Config.lock.recolourLogo
        }
    }

    component MonoText: StyledText {
        font: root.width > Tokens.sizes.lock.largeFontWidth ? Tokens.font.mono.large : Tokens.font.mono.medium
    }
}
