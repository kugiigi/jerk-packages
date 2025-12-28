// ENH238 - Navigation buttons
import QtQuick 2.15
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.15 as QQC2
import "Components" as Components

Components.LPButton {
    id: root

    property string iconName
    property Action customAction

    signal singleClick
    signal doubleClick

    iconName: customAction ? customAction.iconName : ""
    iconRotation: customAction ? customAction.iconRotation : 0

    onSingleClick: if (customAction) customAction.singleClick()
    onDoubleClick: if (customAction) customAction.doubleClick()

    implicitHeight: units.gu(6)
    implicitWidth: units.gu(6)

    icon {
        name: root.iconName
        width: customAction ? customAction.iconSize : units.gu(4)
        height: customAction ? customAction.iconSize : units.gu(4)
    }
    display: QQC2.AbstractButton.IconOnly
    borderColor: "transparent"
    backgroundColor: theme.palette.normal.background
    radius: width / 2

    Timer {
        id: delayTimer

        interval: 200
        onTriggered: root.singleClick()
    }

    onClicked: {
        if (root.customAction && root.customAction.enableDoubleClick) {
            if (delayTimer.running) {
                root.doubleClick()
                delayTimer.stop()
            } else {
                delayTimer.restart()
            }
        } else {
            root.singleClick()
        }
    }
}
