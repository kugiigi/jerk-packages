// ENH215 - Shortcuts bar
import QtQuick 2.9
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import "keys/"


Rectangle{
    id: root

    property alias leadingActions: leadingActionBar.actions
    property alias trailingActions: trailingActionBar.actions
    
    readonly property real actualMaxActionBarWidth: fullScreenItem.convertFromInch(2)
    readonly property real maxActionBarWidth: Math.min(actualMaxActionBarWidth, width / 2)
    readonly property real buttonMinimumWidth: units.gu(4)
	
    color: fullScreenItem.theme.backgroundColor

    // Disable clicking behind the toolbar
    MouseArea {
        anchors.fill: parent
        z: -1
    }

    RowLayout {
        anchors.fill: parent

        MKActionBar {
            id: leadingActionBar

            Layout.fillHeight: true
            Layout.maximumWidth: root.maxActionBarWidth
            Layout.topMargin: units.gu(0.5)
            Layout.bottomMargin: units.gu(0.5)

            buttonMinimumWidth: root.buttonMinimumWidth
        }

        Item {
            Layout.fillWidth: true
        }

        MKActionBar {
            id: trailingActionBar

            Layout.fillHeight: true
            Layout.maximumWidth: root.maxActionBarWidth
            Layout.topMargin: units.gu(0.5)
            Layout.bottomMargin: units.gu(0.5)

            layoutDirection: Qt.RightToLeft
            buttonMinimumWidth: root.buttonMinimumWidth
        }
    }
}
