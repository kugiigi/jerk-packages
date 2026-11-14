import QtQuick 2.9
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import QtFeedback 5.0
import "." as Local

Local.MariKitSwipeGestureHandler {
    id: horizontalSwipeHandle

    readonly property real swipeProgress: usePhysicalUnit ? Math.min(1.0, Math.max(0.0, Math.abs(distance) / (thresholds[physicalStageTrigger - 1] * (Screen.pixelDensity * 25.4))))
                                                    : Math.min(1.0, Math.max(0.0, Math.abs(distance) / (thresholds[defaultStageTrigger - 1] * parent.width)))
    readonly property int physicalStageTrigger: 2
    readonly property int defaultStageTrigger: 4

    property bool leftSwipeHoldEnabled: true
    property bool rightSwipeHoldEnabled: true
    property bool leftSwipeEnabled: true
    property bool rightSwipeEnabled: true

    // Enable/disable triggering the signal and taking action to swipes
    property bool leftSwipeActionEnabled: true
    property bool rightSwipeActionEnabled: true

    property bool delayHideOfActions: false

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
                        if (leftAction) {
                            leftAction.heldState = true
                        }
                        hapticsPlay()
                        rightSwipeHeld()
                        if (horizontalSwipeHandle.delayHideOfActions) {
                            internal.delayedHideActions()
                        } else {
                            internal.hideActions()
                        }
                    } else {
                        // Whem hold is disabled, only trigger after lifting swipe
                        internal.swipeHeld = false
                    }
                } else if (rightSwipeActionEnabled) {
                    rightSwipe()
                    if (horizontalSwipeHandle.delayHideOfActions) {
                            internal.delayedHideActions()
                        } else {
                            internal.hideActions()
                        }
                } else {
                    internal.hideActions()
                }
            }
            if (distance < 0 && leftSwipeEnabled) {
                if (swipeHold) {
                    if (leftSwipeHoldEnabled) {
                        if (rightAction) {
                            rightAction.heldState = true
                        }
                        hapticsPlay()
                        leftSwipeHeld()
                        if (horizontalSwipeHandle.delayHideOfActions) {
                            internal.delayedHideActions()
                        } else {
                            internal.hideActions()
                        }
                    } else {
                        // Whem hold is disabled, only trigger after lifting swipe
                        internal.swipeHeld = false
                    }
                } else if (leftSwipeActionEnabled) {
                    leftSwipe()
                    if (horizontalSwipeHandle.delayHideOfActions) {
                        internal.delayedHideActions()
                    } else {
                        internal.hideActions()
                    }
                } else {
                    internal.hideActions()
                }
            }
        } else {
            internal.hideActions()
        }
    }

    onPressedChanged: if (pressed) hapticsPlaySubtle()

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
                    if (leftAction) {
                        leftAction.show()
                        if (!leftAction.visible) {
                            hapticsPlay()
                        }
                    }
                } else if (distance < 0 && leftSwipeEnabled) {
                    if (rightAction) {
                        rightAction.show()
                        if (!rightAction.visible) {
                            hapticsPlay()
                        }
                    }
                }
            } else {
                internal.hideActions()
                if ((leftAction && leftAction.opacity > 0) || (rightAction && rightAction.opacity > 0)) {
                    hapticsPlaySubtle()
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
            if (horizontalSwipeHandle.leftAction) {
                horizontalSwipeHandle.leftAction.hide()
            }
            if (horizontalSwipeHandle.rightAction) {
                horizontalSwipeHandle.rightAction.hide()
            }
        }

        function delayedHideActions() {
            if (horizontalSwipeHandle.leftAction && horizontalSwipeHandle.leftAction.visible) {
                horizontalSwipeHandle.leftAction.delayedHide()
            }
            if (horizontalSwipeHandle.rightAction && horizontalSwipeHandle.rightAction.visible) {
                horizontalSwipeHandle.rightAction.delayedHide()
            }
        }
    }
    
    function hapticsPlay() {
        Haptics.play()
    }

    function hapticsPlaySubtle() {
        Haptics.play({duration: 3})
    }
}
