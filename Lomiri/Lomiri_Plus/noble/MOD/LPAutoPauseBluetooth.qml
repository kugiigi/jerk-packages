// ENH208 - Pause media on bluetooth disconnect
import QtQuick 2.12
import Lomiri.Components 1.3

Item {
    id: root

    property bool bluetoothAudioConnected: false
    property var volumeSlider
    property var playbackObj

    onBluetoothAudioConnectedChanged: {
        if (!bluetoothAudioConnected) {
            console.log("BLUETOOTH DISCONNECTED!!!!!!!!!!!!!!!!!!")
            if (playbackObj && playbackObj.playing) {
                console.log("PAUSED!!!!!!!!!!!!!!!!!!")
                playbackObj.play(false)
            }
        }
    }

    Connections {
        target: root.volumeSlider ? root.volumeSlider : null
        ignoreUnknownSignals: true
        function onTextChanged() {
            if (target.text.includes(i18n.tr("Bluetooth"))) {
                root.bluetoothAudioConnected = true
            } else {
                root.bluetoothAudioConnected = false
            }
        }
    }
}
