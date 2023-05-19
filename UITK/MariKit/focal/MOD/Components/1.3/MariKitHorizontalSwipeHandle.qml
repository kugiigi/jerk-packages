import QtQuick 2.9
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import QtFeedback 5.0
import "." as Local

Local.MariKitSwipeGestureHandler {
    id: horizontalSwipeHandle

    readonly property real swipeProgress: usePhysicalUnit ? Math.min(1.0, Math.max(0.0, Math.abs(distance) / (thresholds[stage] * (Screen.pixelDensity * 25.4))))
                                                    : Math.min(1.0, Math.max(0.0, Math.abs(distance) / (thresholds[stage] * parent.width)))
    readonly property int physicalStageTrigger: 2
    readonly property int defaultStageTrigger: 4

    property bool leftSwipeHoldEnabled: true
    property bool rightSwipeHoldEnabled: true
    property bool leftSwipeEnabled: true
    property bool rightSwipeEnabled: true

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
                            hapticsPlay()
                        rightSwipeHeld()
                        internal.delayedHideActions()
                    } else {
                        // Whem hold is disabled, only trigger after lifting swipe
                        internal.swipeHeld = false
                    }
                } else {
                    rightSwipe()
                    internal.hideActions()
                }
            }
            if (distance < 0 && leftSwipeEnabled) {
                if (swipeHold) {
                    if (leftSwipeHoldEnabled) {
                        rightAction.heldState = true
                        hapticsPlay()
                        leftSwipeHeld()
                        internal.delayedHideActions()
                    } else {
                        // Whem hold is disabled, only trigger after lifting swipe
                        internal.swipeHeld = false
                    }
                } else {
                    leftSwipe()
                    internal.hideActions()
                }
            }
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
                    leftAction.show()
                    if (!leftAction.visible) {
                        hapticsPlay()
                    }
                } else if (distance < 0 && leftSwipeEnabled) {
                    rightAction.show()
                    if (!rightAction.visible) {
                        hapticsPlay()
                    }
                }
            } else {
                internal.hideActions()
                if (leftAction.opacity > 0 || rightAction.opacity > 0) {
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

    Timer {
        id: delayTimer
        interval: 400
        running: false
        onTriggered: {
            internal.hideActions()
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
            delayTimer.restart()
        }
    }
    
    function hapticsPlay() {
        normalHaptics.start()
    }

    function hapticsPlaySubtle() {
        subtleHaptics.start()
    }

    HapticsEffect {
        id: normalHaptics

        attackIntensity: 0.0
        attackTime: 50
        intensity: 1.0
        duration: 10
        fadeTime: 50
        fadeIntensity: 0.0
    }

    HapticsEffect {
        id: subtleHaptics

        attackIntensity: 0.0
        attackTime: 50
        intensity: 1.0
        duration: 3
        fadeTime: 50
        fadeIntensity: 0.0
    }

}
