import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import Lomiri.Components 1.3
import "." as Common

Row {
    id: toolbarActions

    property alias model: repeater.model
    
    spacing: units.gu(2)
    
    Repeater {
        id: repeater

        Common.ToolbarButton {
            id: toolButton

            anchors.bottom: parent.bottom
            tooltipText: modelData.text
            visible: modelData.visible
            height: units.gu(5)
            width: height
            icon.name: modelData ? modelData.iconName : ""
            icon.width: units.gu(5)
            icon.height: iconWidth
            icon.color: theme.palette.normal.foregroundText

            onClicked: {
				modelData.trigger(toolButton)
                Common.Haptics.playSubtle()
			}
        }
    }
}
