// ENH204 - Bluetooth device list
import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Settings.Menus 0.1 as Menus
import Lomiri.SystemSettings.Bluetooth 1.0
import QtQuick.Layouts 1.12

ColumnLayout {
    id: root

    readonly property color headerColor: theme.palette.normal.foreground
    readonly property color expansionButtonColor: Qt.hsla(headerColor.hslHue, headerColor.hslSaturation, headerColor.hslLightness, 0.5)
    readonly property alias count: repeater.count
    readonly property bool isEmpty: count === 0

    property bool isExpandable: true
    property alias title: headerMenu.text
    property alias model: repeater.model
    property bool isExpanded: false

    signal connectionRequested(string addressName)
    signal deviceConnected(string addressName)

    spacing: 0

    Menus.StandardMenu {
        id: headerMenu

        Layout.fillWidth: true
        visible: root.isExpandable
        iconSource: root.isExpanded ? "image://theme/go-up" : "image://theme/go-down"
        backColor: root.expansionButtonColor
        onTriggered: root.isExpanded = !root.isExpanded
        Behavior on backColor { LomiriNumberAnimation {} } 
    }

    ColumnLayout {
        id: columnLayout

        visible: !root.isEmpty && (root.isExpanded || !root.isExpandable)
        spacing: 0

        Repeater {
            id: repeater

            Layout.fillWidth: true

            delegate: LPBluetoothDeviceDelegate {
                Layout.fillWidth: true

                text: model.displayName
                defaultIconPath: model.iconPath
                connectionStatus: model.connection
                addressName: model.addressName

                onTriggered: root.connectionRequested(addressName)
                onGotConnected: root.deviceConnected(addressName)
            }
        }
    }
}
