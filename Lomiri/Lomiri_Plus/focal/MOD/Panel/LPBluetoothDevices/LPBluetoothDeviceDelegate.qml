// ENH204 - Bluetooth device list
import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Settings.Menus 0.1 as Menus
import Lomiri.SystemSettings.Bluetooth 1.0

Menus.EventMenu {
    property int connectionStatus: -1
    property url defaultIconPath
    property string addressName

    signal gotConnected

    highlightWhenPressed: false
    time: connectionStatus == Device.Connected ? i18n.tr("Connected") : ""
    iconSource: defaultIconPath == "image://theme/input-gaming" ? "image://theme/input-gaming-symbolic" : defaultIconPath

    ActivityIndicator {
        visible: connectionStatus == Device.Connecting
        running: visible
        anchors {
            right: parent.right
            rightMargin: units.gu(2)
            verticalCenter: parent.verticalCenter
        }
    }

    onConnectionStatusChanged: {
        if (connectionStatus === Device.Connected && addressName !== "") {
            gotConnected()
        }
    }
}
