// ENH243 - Virtual Touchpad Enhancements
import QtQuick 2.15
import QtQuick.Layouts 1.1
import Lomiri.Components 1.3
import Lomiri.Gestures 0.1


TouchGestureArea {
    id: root

    readonly property bool recognizedPress: status == TouchGestureArea.Recognized &&
                                            touchPoints.length >= minimumTouchPoints &&
                                            touchPoints.length <= maximumTouchPoints
    property bool enableDragStep: false
    property real dragStepThreshold: units.gu(5)

    property bool enableDoubleClick: false
    readonly property alias isDoubleClick: priv.isDoubleClick

    readonly property alias prevtp: priv.prevtp
    readonly property alias prevtp2: priv.prevtp2
    readonly property int touchPointCount: touchPoints.length
    readonly property real dragDistance: priv.currentX - priv.startX
    readonly property int dragStep: enableDragStep && recognizedDrag ? Math.floor(dragDistance / dragStepThreshold) : 0
    readonly property bool draggingRight: recognizedDrag && priv.currentX - priv.startX >= dragStepThreshold
    readonly property bool draggingLeft: recognizedDrag && priv.currentX - priv.startX <= -dragStepThreshold

    signal normalHaptics
    signal subtleHaptics
    signal gesturePressed
    signal gestureReleased
    signal clicked
    signal doubleClicked
    signal doubleClickedReleased
    signal dragStarted
    signal dragUpdated(var points)
    signal dragStepUp
    signal dragStepDown
    signal dropped
    signal cancelled

    function setPreviousPoint(_point) {
        priv.prevtp = _point
    }

    function setPreviousPoint2(_point) {
        priv.prevtp2 = _point
    }

    QtObject {
        id: priv

        property bool isDoubleClick: false
        property real startX: 0
        property real currentX: {
            let sum = 0;
            for (let i = 0; i < root.touchPoints.length; i++) {
                sum += root.touchPoints[i].x;
            }
            return sum / root.touchPoints.length;
        }
        property int prevDragStep: 0
        property point prevtp: Qt.point(0, 0)
        property point prevtp2: Qt.point(0, 0)
        property Timer clickTimer: Timer {
            repeat: false
            interval: 200
            onTriggered: {
                root.clicked();
                root.normalHaptics()
            }
            function scheduleClick() {
                start();
            }
        }
    }

    onRecognizedPressChanged: {
        if (recognizedPress) {
            root.gesturePressed()
            
            if (root.enableDoubleClick && priv.clickTimer.running) {
                priv.clickTimer.stop();
                priv.isDoubleClick = true;
                root.doubleClicked()
            }
        } else {

            if (recognizedDrag) {
                dropped();
            } else {
                if (root.enableDoubleClick) {
                    priv.clickTimer.scheduleClick()
                } else {
                    clicked();
                }
            }
            if (priv.isDoubleClick) {
                root.doubleClickedReleased()
                priv.isDoubleClick = false;
            }

            priv.startX = 0
            priv.prevDragStep = 0
            priv.prevtp = Qt.point(0, 0)
            priv.prevtp2 = Qt.point(0, 0)

            root.gestureReleased()
        }
    }

    readonly property bool recognizedDrag: recognizedPress && dragging
    onRecognizedDragChanged: {
        if (recognizedDrag) {
            priv.startX = priv.currentX
            dragStarted()
        }
    }

    onDragStepChanged: {
        if (recognizedPress) {
            const _step = dragStep - priv.prevDragStep
            if (_step < 0) {
                root.dragStepDown()
                root.subtleHaptics()
            } else if (_step > 0) {
                root.dragStepUp()
                root.subtleHaptics()
            }

            priv.prevDragStep = dragStep
        }
    }

    onUpdated: {
        root.dragUpdated(points)
        const _point = points[0];
        priv.prevtp = Qt.point(_point.x, _point.y)

        const _point2 = points[1];
        if (_point2) {
            priv.prevtp2 = Qt.point(_point2.x, _point2.y)
        }
    }
}
