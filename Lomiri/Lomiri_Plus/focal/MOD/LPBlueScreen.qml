// ENH186 - BSOD prank
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12

Rectangle {
    id: rootRec

    readonly property bool isCompact: width <= units.gu(80)

    signal close

    color: "#0078d7"

    ColumnLayout {
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            leftMargin: rootRec.isCompact ? units.gu(5) : units.gu(20)
            rightMargin: rootRec.isCompact ? units.gu(5) : rootRec.width * 0.4
        }

        Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft

            text: "::("
            font.pixelSize: rootRec.isCompact ? units.gu(15) : Math.min(rootRec.height * 0.3, units.gu(20))
        }

        Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft

            text: "Your device ran into a problem and needs a restart. We're just collecting your personal and private data and we'll sell them for you"
            wrapMode: Text.WordWrap
            textSize: Label.XLarge
        }

        Label {
            Layout.topMargin: units.gu(4)
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft

            property int percentage: 0
            text: percentage + "% complete"
            wrapMode: Text.WordWrap
            textSize: Label.XLarge
            NumberAnimation on percentage {
                to: 100
                duration: 30000
                easing.type: Easing.OutInExpo
            }
        }

        RowLayout {
            Layout.topMargin: units.gu(4)
            Layout.fillWidth: true

            Image {
                readonly property real preferredSize: rootRec.isCompact ? units.gu(15) : units.gu(25)
                Layout.preferredHeight: preferredSize
                Layout.preferredWidth: preferredSize
                source: "graphics/qrcode.png"
            }

            Label {
                Layout.fillHeight: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                textSize: rootRec.isCompact ? Label.Medium : Label.Large
                text: "For more information about this issue and possible fixes, visit your doctor, https://www.kugiverse.com\n\nif you call a support person, give them this info:\nPrank code: LOMIRI_PLUS_LIED"
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onLongPressed: {
            rootRec.close()
            shell.haptics.playSubtle()
        }

        onSingleTapped: {
            if ((eventPoint.event.device.pointerType === PointerDevice.Cursor || eventPoint.event.device.pointerType == PointerDevice.GenericPointer)
                    && eventPoint.event.button === Qt.RightButton) {
                rootRec.close()
            }
        }
    }
}
