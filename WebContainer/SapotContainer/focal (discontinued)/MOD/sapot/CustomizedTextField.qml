import QtQuick 2.12
import QtQuick.Controls 2.2 as QQC2
import Lomiri.Components 1.3

QQC2.TextField {
    id: textField

    readonly property IconGroupedProperties leftIcon: IconGroupedProperties {
        width: units.gu(2)
        height: units.gu(2)
        color: theme.palette.normal.foregroundText
    }

    property alias rightComponent: rightComponentLoader.sourceComponent

    leftPadding: leftIconItem.width + units.gu(2)
    rightPadding: rightComponentLoader.item ? rightComponentLoader.item.width + units.gu(2) : units.gu(2)

    Icon {
        id: leftIconItem

        name: leftIcon.name
        width: leftIcon.width
        height: leftIcon.height
        color: leftIcon.color
        anchors{
            left: parent.left
            verticalCenter: parent.verticalCenter
            margins: units.gu(1)
        }
    }

    Loader {
        id: rightComponentLoader

        active: true
        asynchronous: true
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: units.gu(1)
        }
    }
}
