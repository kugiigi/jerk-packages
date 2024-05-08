import QtQuick 2.4
import Lomiri.Components 1.3
import QtQuick.Window 2.2

SwipeArea {
    id: swipeGestureHandler

    direction: SwipeArea.Upwards

    readonly property real dragFraction: direction == SwipeArea.Vertical || direction == SwipeArea.Horizontal ? 
                                                internal.isVerticalDirection ? Math.min(1.0, Math.max(0.0, Math.abs(distance) / parent.height))
                                                             : Math.min(1.0, Math.max(0.0, Math.abs(distance) / parent.width))
                                                : internal.isVerticalDirection ? Math.min(1.0, Math.max(0.0, distance / parent.height))
                                                             : Math.min(1.0, Math.max(0.0, distance / parent.width))

    // TODO:  Find a way to make the thresholds infinite instead of hardcoded array
    readonly property var thresholds: usePhysicalUnit ? [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5
                                                        , 10, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 14, 14.5, 15, 15.5, 16, 16.5, 17, 17.5
                                                        , 18, 18.5, 19, 19.5, 20, 20.5, 21, 21.5, 22, 22.5, 23, 23.5, 24, 24.5, 25, 25.5
                                                        , 26, 26.5, 27, 27.5, 28, 28.5, 29, 29.5, 30] // Inches
                                                      : [0, 0.05, 0.18, 0.36, 0.54, 1.0] // Height percentages

    readonly property int stage: usePhysicalUnit ? direction == SwipeArea.Vertical || direction == SwipeArea.Horizontal ? 
                                                                    thresholds.map(function(t) { return Math.abs(distance) <= ((Screen.pixelDensity * 25.4) * t) }).indexOf(true)
                                                                    : thresholds.map(function(t) { return distance <= ((Screen.pixelDensity * 25.4) * t) }).indexOf(true)
                                                 : thresholds.map(function(t) { return dragFraction <= t }).indexOf(true)
    readonly property real stageValue: thresholds[stage] ? thresholds[stage] : -1 // In inch when usePhysicalUnit is true, otherwise, height percentage
    readonly property alias towardsDirection: internal.towardsDirection

    property bool usePhysicalUnit: false
    property alias swipeHoldDuration: swipeHoldTimer.interval // In ms

    signal swipeHeld(int stage)

    immediateRecognition: true

    onDistanceChanged: {
        if (Math.abs(internal.prevDistance - distance) >= internal.distanceThreshold) {
            if (internal.prevDistance < distance) {
                internal.towardsDirection = true
            } else {
                internal.towardsDirection = false
            }
            internal.prevDistance = distance
        }
    }

    onStageChanged: {
        swipeHoldTimer.restart()
    }

    onDraggingChanged: if (!dragging) swipeHoldTimer.stop()

    Timer {
        id: swipeHoldTimer

        running: false
        interval: 1000
        onTriggered: swipeGestureHandler.swipeHeld(swipeGestureHandler.stage)
    }

    QtObject {
        id: internal

        readonly property real distanceThreshold: units.gu(1)
        readonly property bool isVerticalDirection: direction == SwipeArea.Vertical || direction == SwipeArea.Downwards || direction == SwipeArea.Upwards
        property real prevDistance
        property bool towardsDirection: false
    }
}
