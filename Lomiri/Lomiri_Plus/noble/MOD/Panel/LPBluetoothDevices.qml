// ENH204 - Bluetooth device list
import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Settings.Menus 0.1 as Menus
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12 as QQC2
import Lomiri.Components.Popups 1.3
import Lomiri.SystemSettings.Bluetooth 1.0
import "LPBluetoothDevices"

Item {
    id: root

    readonly property int recentMaxCount: 5

    property var dialogPopupId
    property var currentDevice

    implicitHeight: visible ? columnLayout.height : 0

    function addToRecentList(_addressName) {
        let _arr = shell.settings.recentBlutoothDevicesList.slice()
        let _foundIndex = _arr.findIndex((element) => element == _addressName)
        let _isMaxed = _arr.length >= recentMaxCount

        // if it already exists, remove it first
        if (_foundIndex > -1) {
            _arr.splice(_foundIndex, 1)
        } else if (_isMaxed) {
            // Delete last if already maxed out
            _arr.splice(recentMaxCount - 1)
        }

        _arr.unshift(_addressName)

        shell.settings.recentBlutoothDevicesList = _arr.slice()
    }

    function finishDevicePairing() {
        if (root.dialogPopupId)
            PopupUtils.close(root.dialogPopupId)

        root.dialogPopupId = null
        root.currentDevice = null
    }

    function connectToDevice(_addressName) {
        backend.setSelectedDevice(_addressName)
        if (backend.selectedDevice
            && (backend.selectedDevice.connection == Device.Connected
                || backend.selectedDevice.connection == Device.Connecting)) {
            backend.disconnectDevice();
        } else {
            backend.connectDevice(backend.selectedDevice.address);
        }

        backend.resetSelectedDevice();
    }

    LomiriBluetoothPanel {
        id: backend

        onDevicePairingDone: {
            console.log("Got pairing status notification for device " + device.address)

            if (device != root.currentDevice)
                return

            finishDevicePairing()
        }
    }

    Connections {
        target: shell.settings
        function onRecentBlutoothDevicesListChanged() { recentlyConnectedDevicesModel.refreshFilter() }
    }

    SortFilterModel {
        id: recentlyConnectedDevicesModel

        model: backend.autoconnectDevices
        filter.property: "addressName"

        Component.onCompleted: refreshFilter()

        function refreshFilter() {
            let _arr = shell.settings.recentBlutoothDevicesList.slice()
            let _regexString = ""

            if (_arr.length > 0) {
                _regexString = _arr.join("|")
            } else {
                _regexString = "DUMMY"
            }
            
            filter.pattern = new RegExp(_regexString, "g")
        }
    }

    Timer {
        id: discoverableTimer
        repeat: false
        running: false
        onTriggered: backend.trySetDiscoverable(true)
    }

    /* Disable BT visiblity/discovery when not visible */
    onVisibleChanged: {
        if (visible) {
            discoverableTimer.start()
            backend.unblockDiscovery()
        } else {
            backend.trySetDiscoverable(false)
            backend.blockDiscovery()
        }
    }

    Component {
        id: confirmPasskeyDialog
        ConfirmPasskeyDialog { }
    }

    Component {
        id: providePasskeyDialog
        ProvidePasskeyDialog { }
    }

    Component {
        id: providePinCodeDialog
        ProvidePinCodeDialog { }
    }

    Component {
       id: displayPinCodeDialog
       DisplayPinCodeDialog { }
    }

    Component {
        id: displayPasskeyDialog
        DisplayPasskeyDialog { }
    }

    Component {
        id: authorizationRequestDialog
        AuthorizationRequestDialog { }
    }

    Connections {
        target: backend.agent
        function onCancelNeeded() { finishDevicePairing() }
        function onPasskeyConfirmationNeeded(tag, device, passkey) {
            var request_tag = tag
            var popup = confirmPasskeyDialog.createObject(shell.popupParent, {passkey: passkey, name: device.name});
            popup.canceled.connect(function() {target.confirmPasskey(request_tag, false)})
            popup.confirmed.connect(function() {target.confirmPasskey(request_tag, true)})
            popup.show()
        }
        function onPasskeyNeeded(tag, device) {
            var request_tag = tag
            var popup = providePasskeyDialog.createObject(shell.popupParent, {name: device.name});
            popup.canceled.connect(function() {target.providePasskey(request_tag, false, 0)})
            popup.provided.connect(function(passkey) {target.providePasskey(request_tag, true, passkey)})
            popup.show()
        }
        function onPinCodeNeeded(tag, device) {
            var request_tag = tag
            var popup = providePinCodeDialog.createObject(shell.popupParent, {name: device.name});
            popup.canceled.connect(function() {target.providePinCode(request_tag, false, "")})
            popup.provided.connect(function(pinCode) {target.providePinCode(request_tag, true, pinCode)})
            popup.show()
        }
        function onDisplayPinCodeNeeded(device, pincode) {
            if (!root.dialogPopupId)
            {
                root.currentDevice = device
                root.dialogPopupId = displayPinCodeDialog.createObject(shell.popupParent, {pincode: pincode, name: device.name});
                root.dialogPopupId.canceled.connect(function() {
                    root.dialogPopupId = null
                    if (root.currentDevice) {
                        root.currentDevice.cancelPairing()
                        root.currentDevice = null
                    }
                })
                root.dialogPopupId.show()
            }
            else
            {
                console.warn("Unhandled PIN code request for device " + device.name);
            }
        }
        function onDisplayPasskeyNeeded(device, passkey, entered) {
            if (!root.dialogPopupId)
            {
                root.currentDevice = device
                root.dialogPopupId = displayPasskeyDialog.createObject(shell.popupParent,  {passkey: passkey, name: device.name,
                                                 entered: entered});
                root.dialogPopupId.canceled.connect(function() {
                    root.dialogPopupId = null
                    if (root.currentDevice) {
                        root.currentDevice.cancelPairing()
                        root.currentDevice = null
                    }
                })
                root.dialogPopupId.show()
            }
            else
            {
                root.dialogPopupId.entered = entered
            }
        }
        function onReleaseNeeded() {
            finishDevicePairing()
        }
        function onAuthorizationRequested(tag, device) {
            if (!root.dialogPopupId)
            {
                var request_tag = tag
                root.dialogPopupId = authorizationRequestDialog.createObject(shell.popupParent, {name: device.name});
                root.dialogPopupId.accepted.connect(function() {
                    root.dialogPopupId = null
                    target.authorizationRequestCallback(request_tag, true)
                })
                root.dialogPopupId.declined.connect(function() {
                    root.dialogPopupId = null
                    target.authorizationRequestCallback(request_tag, false)
                })
                root.dialogPopupId.show()
            }
        }
    }

    ColumnLayout {
        id: columnLayout

        spacing: 0

        anchors {
            left: parent.left
            right: parent.right
        }

        LPDevicesList {
            id: actuallyConnectedList

            visible: !isEmpty
            title: i18n.tr("Connected devices (%1)").arg(count)
            model: backend.connectedDevices
            isExpandable: count > 5
            onConnectionRequested: root.connectToDevice(addressName)
        }

        LPDevicesList {
            id: recentlyConnectedList

            visible: !isEmpty
            isExpanded: true
            title: i18n.tr("Recent devices")
            model: recentlyConnectedDevicesModel

            onConnectionRequested: root.connectToDevice(addressName)
            onDeviceConnected: root.addToRecentList(addressName)
        }

        Menus.SeparatorMenu {
            Layout.fillWidth: true
            anchors {
                left: undefined
                right: undefined
            }
            visible: recentlyConnectedList.visible
        }

        Menus.EventMenu {
            readonly property bool isSearching: backend.powered && backend.discovering

            Layout.fillWidth: true
            highlightWhenPressed: !isSearching
            text: isSearching ? i18n.tr("Searching...") : i18n.tr("Scan for devices")
            time: backend.adapterName
            iconSource: isSearching ? "image://theme/stop" : "image://theme/find"
            onTriggered: {
                if (isSearching) {
                    backend.stopDiscovery()
                } else {
                    backend.startDiscovery()
                }
            }
        }

        LPDevicesList {
            title: i18n.tr("Discovered devices (%1)").arg(count)
            model: backend.disconnectedDevices
            onConnectionRequested: root.connectToDevice(addressName)
            onDeviceConnected: root.addToRecentList(addressName)
        }

        LPDevicesList {
            title: i18n.tr("Paired devices (%1)").arg(count)
            model: backend.autoconnectDevices
            onConnectionRequested: root.connectToDevice(addressName)
            onDeviceConnected: root.addToRecentList(addressName)
        }
    }
}
