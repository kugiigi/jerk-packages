// ENH238 - Navigation buttons
import QtQuick 2.15
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.15 as QQC2

Item {
    id: root

    readonly property bool isWide: width >= shell.convertFromInch(6)

    property bool rightAligned: true
    property alias model: buttonsRepeater.model
    property int shellRotation: 0

    implicitHeight: units.gu(6)

    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.background
    }

    RowLayout {
        id: buttonsLayout

        readonly property real preferredWidth: units.gu(10)
        readonly property real fitWidth: width / root.model.length
        readonly property real buttonWidth: fitWidth >= preferredWidth ? preferredWidth : fitWidth

        anchors.fill: parent
        spacing: 0

        LPNavigationButton {
            Layout.alignment: Qt.AlignVCenter || Qt.AlignLeft
            Layout.preferredWidth: units.gu(8)

            iconName: "go-first"
            icon {
                width: units.gu(2)
                height: units.gu(2)
            }
            visible: root.isWide && root.rightAligned

            onClicked: root.rightAligned = false
        }

        Item {
            Layout.fillWidth: true
            visible: !root.isWide || (root.isWide && root.rightAligned)
        }

        RowLayout {
            spacing: 0
            Repeater {
                id: buttonsRepeater

                model: []

                delegate: LPNavigationButton {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: buttonsLayout.buttonWidth

                    iconRotation: (customAction ? customAction.iconRotation : 0) + root.shellRotation
                    visible: customAction && customAction.enabled

                    customAction: {
                        const _item = shell.navigationButtonsModel.find((element) => element.id == modelData)
                        if (_item) {
                            return _item.action
                        }

                        return null
                    }
                }
            }
        }
        
        Item {
            Layout.fillWidth: true
            visible: !root.isWide || (root.isWide && !root.rightAligned)
        }

        LPNavigationButton {
            Layout.alignment: Qt.AlignVCenter || Qt.AlignRight
            Layout.preferredWidth: units.gu(8)

            iconName: "go-last"
            icon {
                width: units.gu(2)
                height: units.gu(2)
            }
            visible: root.isWide && !root.rightAligned

            onClicked: root.rightAligned = true
        }
    }
}
