import QtQuick 2.4
import Lomiri.Components 1.3
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Controls.Suru 2.2
import Lomiri.Content 1.3
import "MimeTypeMapper.js" as MimeTypeMapper
import "."

QQC2.Dialog {
    id: baseContentDialog

    default property alias data: contentPickerItem.data

    property real maximumWidth: units.gu(90)
    property real preferredWidth: parent.width

    property real maximumHeight: units.gu(80)
    property real preferredHeight: parent.height > maximumHeight ? parent.height * 0.7 : parent.height
    
    property alias headerTitle: header.title
    property alias headerSubtitle: header.subtitle
    property alias leadingActionBar: header.leadingActionBar
    property alias trailingActionBar: header.trailingActionBar

    width: preferredWidth > maximumWidth ? maximumWidth : preferredWidth
    height: preferredHeight > maximumHeight ? maximumHeight : preferredHeight
    x: (parent.width - width) / 2
    parent: QQC2.Overlay.overlay
    topPadding: units.gu(0.2)
    leftPadding: units.gu(0.2)
    rightPadding: units.gu(0.2)
    bottomPadding: units.gu(0.2)
    closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
    modal: true

    QQC2.Overlay.modal: Rectangle {
        color: Suru.overlayColor
        Behavior on opacity { NumberAnimation { duration: Suru.animations.FastDuration } }
    }

    onAboutToShow: y = Qt.binding(function(){return parent.width >= units.gu(90) ? (parent.height - height) / 2 : (parent.height - height)})

    Item {
        anchors.fill: parent

        PageHeader {
            id: header

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            leadingActionBar.actions: [
                Action {
                    iconName: "close"
                    text: i18n.tr("Close")
                    onTriggered: baseContentDialog.close()
                }
            ]
        }

        Item {
            id: contentPickerItem

            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
        }
    }
}
