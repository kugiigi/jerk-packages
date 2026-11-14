import QtQuick 2.9
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import "." as Local

Local.SwipeGestureHandler {
    id: horizontalSwipeHandle

    readonly property real swipeProgress: usePhysicalUnit ? Math.min(1.0, Math.max(0.0, Math.abs(distance) / (thresholds[physicalStageTrigger - 1] * (Screen.pixelDensity * 25.4))))
                                                    : Math.min(1.0, Math.max(0.0, Math.abs(distance) / (thresholds[defaultStageTrigger - 1] * parent.width)))
    readonly property int physicalStageTrigger: 2
    readonly property int defaultStageTrigger: 4

    property bool leftSwipeHoldEnabled: true
    property bool rightSwipeHoldEnabled: true

    // Enable/Disable actual swipes
    property bool leftSwipeEnabled: true 
    property bool rightSwipeEnabled: true

    // Enable/disable triggering the signal and taking action to swipes
    property bool leftSwipeActionEnabled: true
    property bool rightSwipeActionEnabled: true

    property var leftAction
    property var rightAction

    signal leftSwipe
    signal rightSwipe
    signal leftSwipeHeld
    signal rightSwipeHeld

    direction: SwipeArea.Horizontal

    function assessAction(swipeHold) {
        if ( (usePhysicalUnit && stage >= physicalStageTrigger)
             || (!usePhysicalUnit && stage >= defaultStageTrigger)
           ) {
            if (distance > 0 && rightSwipeEnabled) {
                if (swipeHold) {
                    if (rightSwipeHoldEnabled) {
                        leftAction.heldState = true
                        Local.Haptics.play()
                        rightSwipeHeld()
                        internal.delayedHideActions()
                    } else {
                        // Whem hold is disabled, only trigger after lifting swipe
                        internal.swipeHeld = false
                    }
                } else if (rightSwipeActionEnabled) {
                    rightSwipe()
                    internal.delayedHideActions()
                } else {
                    internal.hideActions()
                }
            }
            if (distance < 0 && leftSwipeEnabled) {
                if (swipeHold) {
                    if (leftSwipeHoldEnabled) {
                        rightAction.heldState = true
                        Local.Haptics.play()
                        leftSwipeHeld()
                        internal.delayedHideActions()
                    } else {
                        // Whem hold is disabled, only trigger after lifting swipe
                        internal.swipeHeld = false
                    }
                } else if (leftSwipeActionEnabled) {
                    leftSwipe()
                    internal.delayedHideActions()
                } else {
                    internal.hideActions()
                }
            }
        } else {
            internal.hideActions()
        }
    }

    onSwipeHeld: {
        internal.swipeHeld = true
        assessAction(true)
    }

    onStageChanged: {
        if (dragging) {
            if ( (usePhysicalUnit && stage >= physicalStageTrigger)
                 || (!usePhysicalUnit && stage >= defaultStageTrigger)
               ) {
                if (distance > 0 && rightSwipeEnabled) {
                    leftAction.show()
                    if (!leftAction.visible) {
                        Local.Haptics.play()
                    }
                } else if (distance < 0 && leftSwipeEnabled) {
                    rightAction.show()
                    if (!rightAction.visible) {
                        Local.Haptics.play()
                    }
                }
            } else {
                internal.hideActions()
                if (leftAction.opacity > 0 || rightAction.opacity > 0) {
                    Local.Haptics.playSubtle()
                }
            }
        }
    }

    onDraggingChanged: {
        if (!dragging) {
            if (!internal.swipeHeld) {
                assessAction(false)
            } else {
                internal.hideActions()
            }

            // Reset the flag
            internal.swipeHeld = false
        }
    }

    QtObject {
        id: internal
        property bool swipeHeld: false // Use to cancel normal left and right swipe

        function hideActions() {
            horizontalSwipeHandle.leftAction.hide()
            horizontalSwipeHandle.rightAction.hide()
        }

        function delayedHideActions() {
            if (horizontalSwipeHandle.leftAction.visible) {
                horizontalSwipeHandle.leftAction.delayedHide()
            }
            if (horizontalSwipeHandle.rightAction.visible) {
                horizontalSwipeHandle.rightAction.delayedHide()
            }
        }
    }
}
