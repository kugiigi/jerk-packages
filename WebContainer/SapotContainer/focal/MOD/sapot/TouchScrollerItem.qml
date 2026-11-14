import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import QtQuick.Window 2.2

Item {
    id: root

    property alias active: loader.active
    property var target
    property string mode: "Down"
    property bool forceHide: false
    property real sideMargin: units.gu(2)
    property real verticalMargin: units.gu(2)
    property real buttonWidth: units.gu(buttonWidthGU)
    property int buttonWidthGU: 8
    property bool doubleAsPositioner: false

    signal pressAndHold

    anchors.fill: parent

    Loader {
        id: loader

        readonly property real scrollPositionY: root.target.scrollPosition.y / Screen.devicePixelRatio
        readonly property real contentHeight: root.target.contentsSize.height / Screen.devicePixelRatio
        readonly property real yFromWebview: (scrollPositionY / (contentHeight - root.target.height)) * (root.height - height - (root.verticalMargin * 2)) + root.verticalMargin

        // Do this otherwise, it will jump around when dragging with touch
        y: dragHandler.active ? y : yFromWebview
        anchors {
            right: parent.right
            rightMargin: root.sideMargin
        }

        onYChanged: {
            if (dragHandler.active) {
                let _y = ((contentHeight - root.target.height) / (root.height - height - (root.verticalMargin * 2))) * (y - root.verticalMargin)
                root.target.scrollTo(root.target.scrollPosition.x, _y)
            }
        }

        sourceComponent: ScrollPositioner {
            id: scrollPositioner

            width: root.buttonWidth
            target: root.target
            mode: root.mode
            forceHide: root.forceHide
            scrollerMode: dragHandler.active
            enableHover: false
            positionerMode: root.doubleAsPositioner
            onPressAndHold: root.pressAndHold()
        }

        DragHandler {
            id: dragHandler

            xAxis.enabled: false
            yAxis {
                enabled: true
                maximum: root.target.height - loader.height - root.verticalMargin
                minimum: root.verticalMargin
            }
            onActiveChanged: {
                if (!active) {
                    loader.y = Qt.binding( function() { return dragHandler.active ? y : loader.yFromWebview } )
                }
            }
        }
    }
}
