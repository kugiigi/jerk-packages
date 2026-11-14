import QtQuick 2.4
import Ubuntu.Components 1.3

LPSwipeGestureHandler {
    id: pullUpSwipeGesture

    property bool pullDownState: false
    property int triggerStage: 3

    readonly property bool triggerStageReached: stage >= triggerStage

    signal trigger

    direction: pullDownState ? SwipeArea.Upwards : SwipeArea.Downwards
    immediateRecognition: false
    grabGesture: true

    onTriggerStageReachedChanged: {
        if (dragging) {
            if (triggerStageReached) {
                shell.haptics.play()
            } else {
                shell.haptics.playSubtle()
            }
        }
    }

    onDraggingChanged: {
        if (!dragging && towardsDirection) {
            if (stage >= triggerStage) {
                trigger()
            }
        }
    }
}
