import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12 as QQC2

Item {
    id: root

    property bool dismissEnabled: true
    property int duration: 5000
    property int currentIndex: 0

    readonly property var model: [
        "blackface_scare.jpg"
        , "eye_scare.jpg"
        , "lady_scare.gif"
        , "lady2_scare.gif"
    ]

    signal close

    Component.onCompleted: {
        currentIndex = shell.randomWholeNumber(0, model.length - 1)
        image.source = "LPGraphics/" + model[currentIndex]
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    // Eat mouse events when taphandler is disabled
    MouseArea {
        enabled: !root.dismissEnabled
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onWheel: wheel.accepted = true;
    }

    AnimatedImage {
        id: image
        //fillMode: Image.PreserveAspectFit
        anchors.fill: parent
        onStatusChanged: playing = (status == AnimatedImage.Ready)
    }
    
    TapHandler {
        enabled: root.dismissEnabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onLongPressed: {
            root.close()
            Haptics.play()
        }

        onSingleTapped: {
            if ((eventPoint.event.device.pointerType === PointerDevice.Cursor || eventPoint.event.device.pointerType == PointerDevice.GenericPointer)
                    && eventPoint.event.button === Qt.RightButton) {
                root.close()
            }
        }
    }
}
