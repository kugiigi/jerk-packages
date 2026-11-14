import QtQuick 2.12
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Controls.Suru 2.2
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12

MouseArea {
    id: actionRowMenu

    property list<QQC2.Action> model
    property QQC2.Menu menu
    property bool separatorAtTop: false // Menu separator is at the bottom by default
    property bool hideSeparator: false
    property bool getsFocus: menu.focus

    signal actionTriggered

    height: actionsRow.height
    acceptedButtons: Qt.NoButton
    hoverEnabled: true
    
    onContainsMouseChanged: {
        if (containsMouse) {
            actionRowMenu.menu.currentIndex = -1
        }
    }
    
    Rectangle {
        anchors.fill: parent
        color: Suru.backgroundColor
    }

    RowLayout {
        id: actionsRow

        spacing: 0
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        Repeater {
            id: actionsRepeater

            model: actionRowMenu.model
            delegate: toolButtonDelegate
        }

        Component {
            id: toolButtonDelegate

            MenuToolButton {
                id: toolButton 

                Layout.fillWidth: true

                implicitHeight: units.gu(6)
                enabled: modelData.enabled
                visible: modelData.displayWhenDisabled ? true : enabled
                iconName: modelData.icon.name
                tooltipText: modelData.text
                focusPolicy: actionRowMenu.getsFocus ? Qt.StrongFocus : Qt.NoFocus
                onClicked: {
                    modelData.trigger(toolButton)
                    if (modelData.closeMenuOnTrigger) {
                        actionRowMenu.menu.close()
                    }
                    actionRowMenu.actionTriggered()
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: !actionRowMenu.hideSeparator

        CustomizedMenuSeparator {
            Layout.fillWidth: true
            Layout.alignment: actionRowMenu.separatorAtTop ? Qt.AlignTop : Qt.AlignBottom
        }
    }
}
