import QtQuick 2.12
import Lomiri.Components 1.3

Item {
    id: hotCorner

    enum Edge {
        TopLeft
        , TopRight
        , BottomLeft
        , BottomRight
    }

    property int edge: LPHotCorner.Edge.TopLeft
    property bool enableVisualFeedback: true

    signal trigger

    anchors.top: (edge == LPHotCorner.Edge.TopLeft || edge == LPHotCorner.Edge.TopRight) ? parent.top : undefined
    anchors.bottom: (edge == LPHotCorner.Edge.BottomLeft || edge == LPHotCorner.Edge.BottomRight) ? parent.bottom : undefined
    anchors.left: (edge == LPHotCorner.Edge.TopLeft || edge == LPHotCorner.Edge.BottomLeft) ? parent.left : undefined
    anchors.right: (edge == LPHotCorner.Edge.TopRight || edge == LPHotCorner.Edge.BottomRight) ? parent.right : undefined

    width: units.dp(1)
    height: width

    onTrigger: {
        if (enableVisualFeedback) {
            pulseRec.animate()
        }
    }
    
    HoverHandler {
        id: hoverHandler

        enabled: hotCorner.enabled
        acceptedPointerTypes: PointerDevice.Cursor | PointerDevice.GenericPointer | PointerDevice.Pen
        onHoveredChanged: {
            if ( hovered) {
                delayTriggerTimer.restart()
            } else {
                delayTriggerTimer.stop()
            }
        }
    }

    Timer {
        id: delayTriggerTimer

        running: false
        interval: 100
        onTriggered: {
            if (hoverHandler.hovered) {
                hotCorner.trigger()
            }
        }
    }

    Rectangle {
        id: pulseRec

        color: theme.palette.normal.overlay
        width: units.gu(5)
        height: width
        radius: width / 2
        opacity: 0
        anchors {
            centerIn: parent
            verticalCenterOffset: (edge == LPHotCorner.Edge.TopLeft || edge == LPHotCorner.Edge.TopRight) ? units.gu(2) : -units.gu(2)
            horizontalCenterOffset: (edge == LPHotCorner.Edge.TopLeft || edge == LPHotCorner.Edge.BottomLeft) ? units.gu(2) : -units.gu(2)
        }

        function animate() {
            pulseAnimation.restart()
        }

        SequentialAnimation {
            id: pulseAnimation

            readonly property int defaultDuration: LomiriAnimation.BriskDuration
            readonly property int easingType: Easing.InOutQuint

            ParallelAnimation {
                LomiriNumberAnimation {
                    target: pulseRec
                    property: "scale"
                    to: 3
                    duration: pulseAnimation.defaultDuration
                    easing.type: pulseAnimation.easingType
                }

                LomiriNumberAnimation {
                    target: pulseRec
                    property: "opacity"
                    to: 0.6
                    duration: pulseAnimation.defaultDuration
                    easing.type: pulseAnimation.easingType
                }
            }

            ParallelAnimation {
                LomiriNumberAnimation {
                    target: pulseRec
                    property: "scale"
                    to: 1
                    duration: pulseAnimation.defaultDuration
                    easing.type: pulseAnimation.easingType
                }

                LomiriNumberAnimation {
                    target: pulseRec
                    property: "opacity"
                    to: 0
                    duration: pulseAnimation.defaultDuration
                    easing.type: pulseAnimation.easingType
                }
            }
        }
    }
}
