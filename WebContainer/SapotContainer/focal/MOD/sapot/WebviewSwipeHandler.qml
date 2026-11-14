import QtQuick 2.4
import Lomiri.Components 1.3
import "." as Sapot

Sapot.SwipeGestureHandler {
    id: pullUpSwipeGesture

    property bool webviewPullDownState: false
    property int triggerStage: 3

    readonly property bool triggerStageReached: stage >= triggerStage

    signal trigger

    direction: webviewPullDownState ? SwipeArea.Upwards : SwipeArea.Downwards
    immediateRecognition: false
    grabGesture: true

    onTriggerStageReachedChanged: {
        if (dragging) {
            if (triggerStageReached) {
                Sapot.Haptics.play()
            } else {
                Sapot.Haptics.playSubtle()
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
