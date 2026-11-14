import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12

Item {
    id: scrollPositionerItem

    enum Position {
        Right
        , Left
        , Middle
    }
    property alias active: loader.active
    property var target
    property string mode: "Down"
    property bool forceHide: false
    property int position: ScrollPositionerItem.Position.Right
    property real sideMargin: units.gu(2)
    property real bottomMargin: units.gu(3)
    property real buttonWidth: units.gu(buttonWidthGU)
    property int buttonWidthGU: 8

    signal pressAndHold

    anchors.fill: parent

    Loader {
        id: loader

        state: "right"
        states:[
            State {
                name: "right"
                when: scrollPositionerItem.position === ScrollPositionerItem.Position.Right
                AnchorChanges {
                    target: loader
                    anchors.right: parent.right
                    anchors.left: undefined
                    anchors.horizontalCenter: undefined
                }
            }
            , State {
                name: "left"
                when: scrollPositionerItem.position === ScrollPositionerItem.Position.Left
                AnchorChanges {
                    target: loader
                    anchors.right: undefined
                    anchors.left: parent.left
                    anchors.horizontalCenter: undefined
                }
            }
            , State {
                name: "middle"
                when: scrollPositionerItem.position === ScrollPositionerItem.Position.Middle
                AnchorChanges {
                    target: loader
                    anchors.right: undefined
                    anchors.left: undefined
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        ]
        anchors {
            rightMargin: scrollPositionerItem.sideMargin
            leftMargin: scrollPositionerItem.sideMargin
            bottom: parent.bottom
            bottomMargin: scrollPositionerItem.bottomMargin
        }

        sourceComponent: ScrollPositioner {
            id: scrollPositioner

            width: scrollPositionerItem.buttonWidth
            target: scrollPositionerItem.target
            mode: scrollPositionerItem.mode
            forceHide: scrollPositionerItem.forceHide
            onPressAndHold: scrollPositionerItem.pressAndHold()
        }
    }
}
