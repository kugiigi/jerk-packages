import QtQuick 2.4
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Content 1.3
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.12

Item {
    id: root

    property var activeTransfer

    opacity: internal.isTransferRunning ? 1.0 : 0.0
    
    BaseDialog {
        id: dialog

        modal: true
        parent: QQC2.Overlay.overlay
        height: units.gu(30)
        title: i18n.dtr("content-hub", "Transfer in progress")
        closePolicy: QQC2.Popup.NoAutoClose
        standardButtons: QQC2.Dialog.NoButton

        ColumnLayout {
            spacing: units.gu(5)
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
            }

            ActivityIndicator {
                id: indicator
                Layout.alignment: Qt.AlignHCenter
                anchors.topMargin: units.gu(6)
                running: internal.isTransferRunning
            }

            Button {
                id: cancelTransfer
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                Layout.rightMargin: units.gu(2)
                text: i18n.dtr("content-hub", "Cancel")
                onClicked: {
                    root.activeTransfer.state = ContentTransfer.Aborted
                }
            }
        }
    }

    QtObject {
        id: internal
        property bool isTransferRunning: root.activeTransfer ?
                                             root.activeTransfer.state === ContentTransfer.InProgress || root.activeTransfer.state === ContentTransfer.Initiated
                                           : false

        onIsTransferRunningChanged: {
            if (isTransferRunning) {
                dialog.openNormal();
            } else {
                dialog.close();
            }
        }
    }
}
