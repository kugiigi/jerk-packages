import QtQuick 2.9
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import "key_constants.js" as UI
// ENH215 - Shortcuts bar
import ".." as Root
// ENH215 - End

AbstractButton {
    id: toolbarButton

    // ENH215 - Shortcuts bar
    property real minimumWidth: fullLayout ? buttonsRow.width + units.gu(1) : buttonsRow.width + units.gu(1)
    property real maximumWidth: !forceHide ? fullLayout ? buttonsRow.width + units.gu(2) : buttonsRow.width + units.gu(4)
                                          : 0
    property real preferredWidth: fullLayout ? buttonsRow.width + units.gu(2) : buttonsRow.width + units.gu(4)

    property Root.MKBaseAction customAction

    property bool forceHide: false
    opacity: forceHide ? 0 : 1
    // ENH215 - End

    /* design */
    property string normalColor: fullScreenItem.theme.backgroundColor
    property string pressedColor: fullScreenItem.theme.charKeyPressedColor

    property bool fullLayout: false

    // ENH215 - Shortcuts bar
    /*
    anchors {
        top: parent ? parent.top : undefined
        bottom: parent ? parent.bottom : undefined
    }

    */
    // ENH215 - End
    implicitWidth: fullLayout ? buttonsRow.width + units.gu(2) : buttonsRow.width + units.gu(4)
    // ENH215 - Shortcuts bar
    // action: modelData
    visible: customAction.visible
    enabled: customAction.enabled && !forceHide
    // ENH215 - End

    onClicked: {
        fullScreenItem.keyFeedback();
        fullScreenItem.timerSwipe.restart();
        // ENH215 - Shortcuts bar
        customAction.trigger(false ,toolbarButton)
        // ENH215 - End
    }

    onPressAndHold: {
        customAction.pressAndHold(false ,toolbarButton)
        fullScreenItem.keyFeedback()
    }

    style: Rectangle {
        color: normalColor

        Connections {
            target: toolbarButton
            onPressedChanged:{
                if (target.pressed) {
                    color = pressedColor
                } else {
                    color = Qt.binding(function(){return normalColor})
                }
            }
        }

        Behavior on color {
            ColorAnimation {
                easing: LomiriAnimation.StandardEasing
                duration: LomiriAnimation.BriskDuration
            }
        }
    }

    // ENH215 - Shortcuts bar
    /*
    RowLayout {
        id: buttonsRow

        spacing: units.gu(0.5)
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        
        Icon {
            id: icon

            Layout.preferredWidth: label.visible ? toolbarButton.height * 0.4 : toolbarButton.height * 0.5
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            
            name: action.iconName
            visible: action.iconName
            color: action.checked ? fullScreenItem.theme.selectionColor : fullScreenItem.theme.fontColor
        }
        
        Label {
            id: label
            
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            
            visible: fullLayout
            font.pixelSize: units.dp(fullScreenItem.tablet ? UI.tabletWordRibbonFontSize : UI.phoneWordRibbonFontSize)
            font.family: UI.fontFamily
            font.weight: Font.Normal
            text: action.text
            elide: Text.ElideRight
            color: action.checked ? fullScreenItem.theme.selectionColor : fullScreenItem.theme.fontColor
        }
    }
    */
    RowLayout {
        id: buttonsRow

        spacing: units.gu(0.5)
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        
        Icon {
            id: icon

            Layout.preferredWidth: label.visible ? toolbarButton.height * 0.4 : toolbarButton.height * 0.5
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            
            name: customAction.iconName
            visible: customAction.iconName
            color: customAction.checked ? fullScreenItem.theme.selectionColor : fullScreenItem.theme.fontColor
        }
        
        Label {
            id: label
            
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            
            visible: fullLayout
            font.pixelSize: units.dp(fullScreenItem.tablet ? UI.tabletWordRibbonFontSize : UI.phoneWordRibbonFontSize)
            font.family: UI.fontFamily
            font.weight: Font.Normal
            text: customAction.text
            elide: Text.ElideRight
            color: customAction.checked ? fullScreenItem.theme.selectionColor : fullScreenItem.theme.fontColor
        }
    }
    // ENH215 - End
}
