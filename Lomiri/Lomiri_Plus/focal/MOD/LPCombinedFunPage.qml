import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12

Item {
    id: defaultScene

    property bool dismissEnabled: true
    property int duration: 30000

    property bool bsodAlreadyShown: false
    property int openDelayForBSOD: ttyPage.startDelay
    property int closeDelayForBSOD: 100000

    signal close

    Component.onCompleted: {
        if (openDelayForBSOD > 0) {
            buruIskunuru.delayShow.restart()
        } else {
            buruIskunuru.show()
        }
    }

    LPTTYPage {
        id: ttyPage

        anchors.fill: parent
        dismissEnabled: defaultScene.dismissEnabled
        visible: !defaultScene.bsodAlreadyShown
        onClose: {
            defaultScene.requestRestore()
            defaultScene.done()
        }
    }

    Loader {
        id: buruIskunuru
        
        readonly property Timer delayShow: Timer {
            interval: defaultScene.openDelayForBSOD
            onTriggered: buruIskunuru.show()
        }
        readonly property Timer delayHide: Timer {
            interval: defaultScene.closeDelayForBSOD
            onTriggered: buruIskunuru.hide()
        }
        z: Number.MAX_VALUE
        anchors.fill: parent
        visible: item ? true : false
        active: false

        // Workaround for vertical centering in shorter devices
        onLoaded: {
            anchors.margins = 1
            anchors.margins = 0
        }

        function show() {
            buruIskunuru.active = true
            buruIskunuru.delayHide.restart()
            defaultScene.bsodAlreadyShown = true
        }

        function hide() {
            active = false
            defaultScene.close()
        }

        sourceComponent: LPBlueScreen {
            dismissEnabled: defaultScene.dismissEnabled
            duration: defaultScene.duration
            onClose: buruIskunuru.hide()
        }
    }
}
