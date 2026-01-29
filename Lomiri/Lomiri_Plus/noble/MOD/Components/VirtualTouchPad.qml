/*
 * Copyright (C) 2015 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.15
import QtQuick.Layouts 1.1
import Lomiri.Components 1.3
import Qt.labs.settings 1.0
import Aethercast 1.0
import UInput 0.1
import "../Components"
// ENH141 - Air mouse in virtual touchpad
import QtQuick.Window 2.2
import QtSensors 5.12
import QtFeedback 5.0
import ".." 0.1
// ENH141 - End
// ENH243 - Virtual Touchpad Enhancements
import Lomiri.Gestures 0.1
import QtMir.Application 0.1
import "../Stage"
// ENH243 - End

Item {
    id: root

    property bool oskEnabled: false
    // ENH241 - Rotate button in Virtual Touchpad
    property int contentRotation: 0
    signal rotate
    // ENH241 - End
    // ENH243 - Virtual Touchpad Enhancements
    readonly property bool appDragGestureIsActive: (gestureArea.recognizedDrag && !gestureArea.isResizeMode)
                                                        || gyro.appIsBeingDragged
    onAppDragGestureIsActiveChanged: ShellNotifier.appDragGestureIsActive = appDragGestureIsActive
    // ENH243 - End
    // ENH141 - Air mouse in virtual touchpad
    readonly property bool gyroMode: enableGyroMode && ShellNotifier.enableAirMouse
    property bool enableGyroMode: false
    onGyroModeChanged: ShellNotifier.inAirMouseMode = gyroMode

    function convertFromInch(value) {
        let _density = Screen.pixelDensity
        return (_density * 25.4) * value
    }

    function leftClick() {
        leftPress();
        leftRelease();
        ShellNotifier.normalHaptics()
    }

    function leftPress() {
        UInput.pressMouse(UInput.ButtonLeft);
    }

    function leftRelease() {
        UInput.releaseMouse(UInput.ButtonLeft);
    }

    function rightClick() {
        rightPress();
        rightRelease();
        ShellNotifier.normalHaptics();
    }

    function rightPress() {
        UInput.pressMouse(UInput.ButtonRight);
    }

    function rightRelease() {
        UInput.releaseMouse(UInput.ButtonRight);
    }

    function doubleLeftClick() {
        leftClick();
        doubleClickTimer.restart();
        ShellNotifier.normalHaptics();
    }
    Timer {
        id: doubleClickTimer
        interval: 200
        onTriggered: root.leftClick();
    }
    // ENH141 - End

    AethercastDisplays {
        id: aethercastDisplays
    }

    Component.onCompleted: {
        UInput.createMouse();
        if (!settings.touchpadTutorialHasRun) {
            root.runTutorial()
        }
    }
    Component.onDestruction: UInput.removeMouse()

    function runTutorial() {
        // If the tutorial animation is started too early, e.g. in Component.onCompleted,
        // root width & height might be reported as 0x0 still. As animations read their
        // values at startup and won't update them, lets make sure to only start once
        // we have some actual size.
        if (root.width > 0 && root.height > 0) {
            tutorial.start();
        } else {
            tutorialTimer.start();
        }
    }

    Timer {
        id: tutorialTimer
        interval: 50
        repeat: false
        running: false
        onTriggered: root.runTutorial();
    }

    readonly property bool pressed: point1.pressed || point2.pressed || leftButton.pressed || rightButton.pressed

    property var settings: Settings {
        objectName: "virtualTouchPadSettings"
        property bool touchpadTutorialHasRun: false
        property bool oskEnabled: true
    }

    // ENH141 - Air mouse in virtual touchpad
    function calculatePointDistance(__point1, __point2) {
        let _x = __point1.x - __point2.x;
        let _y = __point1.y - __point2.y;

        return Math.sqrt( (_x * _x) + (_y * _y) );
    }

    Connections {
        target: ShellNotifier

        function onLeftClick() {
            root.leftClick()
        }

        function onRightClick() {
            root.rightClick()
        }

        function onLeftPress() {
            root.leftPress()
        }

        function onRightPress() {
            root.rightPress()
        }

        function onLeftRelease() {
            root.leftRelease()
        }

        function onRightRelease() {
            root.rightRelease()
        }
    }

    Gyroscope {
        id: gyro

        // Mouse position relative to initial press on the touchpad
        property point relativeMousePos: Qt.point(0, 0)
        property bool appIsBeingDragged: false

        active: root.gyroMode

        onReadingChanged: {
            if (reading
                    && 
                    (
                        ShellNotifier.airMouseAlwaysActive
                        || (!ShellNotifier.enableCustomClickBehavior && multiTouchArea.touchPoints[0].pressed)
                        || (ShellNotifier.enableCustomClickBehavior && (customMouseArea.pressed || customMouseArea.dragInProgress))
                    )
                ) {

                const _sensitivityMultiplier = ShellNotifier.airMouseSensitivity
                const _readingZ = reading.z
                const _readingX = reading.x
                const _readingY = reading.y

                // ENH241 - Rotate button in Virtual Touchpad
                let _readingForMouseX = 0
                let _readingForMouseY = 0
                switch (root.contentRotation) {
                    case 90:
                        _readingForMouseX = _readingZ
                        _readingForMouseY = -_readingY
                        break
                    case 180:
                        _readingForMouseX = _readingZ
                        _readingForMouseY = -_readingX
                        break
                    case 270:
                        _readingForMouseX = _readingZ
                        _readingForMouseY = _readingY
                        break
                    case 0:
                    default:
                        _readingForMouseX = _readingZ
                        _readingForMouseY = _readingX
                }
                //let _newMouseX = 0 - _readingZ * _sensitivityMultiplier
                //let _newMouseY = 0 - _readingX * _sensitivityMultiplier
                let _newMouseX = 0 - _readingForMouseX * _sensitivityMultiplier
                let _newMouseY = 0 - _readingForMouseY * _sensitivityMultiplier
                // ENH241 - End

                // Consolidate all mouse movements after pressing the touchpad
                // then reset it to 0 on press release
                if (multiTouchArea.touchPoints[0].pressed) {
                    // ENH241 - Rotate button in Virtual Touchpad
                    //relativeMousePos = Qt.point(relativeMousePos.x + _readingZ, relativeMousePos.y + _readingX)
                    relativeMousePos = Qt.point(relativeMousePos.x + _readingForMouseX, relativeMousePos.y + _readingForMouseY)
                    // ENH241 - End
                } else {
                    relativeMousePos = Qt.point(0, 0)
                }

                // Get the distance of the consolidated mouse movements from point 0
                // to get the distance the mouse has traveled since pressing the touchpad
                if (multiTouchArea.isClick &&
                        root.calculatePointDistance(Qt.point(0, 0), relativeMousePos) > internalGu * 2) {
                    multiTouchArea.isClick = false;
                    multiTouchArea.isDrag = true;
                }

                UInput.moveMouse(_newMouseX, _newMouseY);

                if (multiTouchArea.isSwipeUp && priv.appToDrag !== null) {
                    moveHandler.handlePositionChanged(priv.mousePoint)
                }
            }
        }
    }

    MultiPointTouchArea {
        id: multiTouchArea

        readonly property real clickSwipeThreshold: internalGu * 10
        property bool isSwipe: false
        property bool isSwipeUp: false
        onIsSwipeChanged: {
            if (isSwipe) {
                ShellNotifier.subtleHaptics()
            }
        }
    // ENH141 - End
        objectName: "touchPadArea"
        anchors.fill: parent
        // ENH141 - Air mouse in virtual touchpad
        // enabled: !tutorial.running || tutorial.paused
        enabled: (!tutorial.running || tutorial.paused) && !(root.enableGyroMode && ShellNotifier.enableCustomClickBehavior)
        // ENH243 - Virtual Touchpad Enhancements
                    && !(gestureArea.recognisedPress || fourFiveGetsureArea.recognisedPress)
        // ENH243 - End
        // ENH141 - End

        // FIXME: Once we have Qt DPR support, this should be Qt.styleHints.startDragDistance
        // ENH243 - Virtual Touchpad Enhancements
        // readonly property int clickThreshold: internalGu * 1.5
        readonly property int clickThreshold: ShellNotifier.enableVirtualTouchpadLowerClickThreshold ? internalGu * 0.5 : internalGu * 1.5
        // ENH243 - End
        property bool isClick: false
        property bool isDoubleClick: false
        property bool isDrag: false

        onPressed: {
            if (tutorial.paused) {
                tutorial.resume();
                return;
            }

            // If double-tapping *really* fast, it could happen that we end up having only point2 pressed
            // Make sure we check for both combos, only point1 or only point2
            if (((point1.pressed && !point2.pressed) || (!point1.pressed && point2.pressed))
                    && clickTimer.running) {
                clickTimer.stop();
                UInput.pressMouse(UInput.ButtonLeft)
                isDoubleClick = true;
            }
            isClick = true;
        }

        onUpdated: {
            // ENH141 - Air mouse in virtual touchpad
            /*
            switch (touchPoints.length) {
            case 1:
                moveMouse(touchPoints);
                return;
            case 2:
                scroll(touchPoints);
                return;
            }
            */
            if (!root.gyroMode) {
                switch (touchPoints.length) {
                case 1:
                    moveMouse(touchPoints);
                    return;
                case 2:
                    scroll(touchPoints);
                    return;
                }
            } else {
                let _point = touchPoints[0]
                //let _distance = _point.y - _point.startY // Vertical
                let _distance = _point.x - _point.startX // Horizontal

                if (Math.abs(_distance) > clickSwipeThreshold) {
                    isSwipe = true
                    if (_distance < 0) {
                        isSwipeUp = true
                        isClick = false;
                        isDrag = true;

                        //root.leftPress()
                        if (priv.appToDrag === null) {
                            ShellNotifier.getAppToDrag()
                        }
                        if (priv.appToDrag !== null && !moveHandler.dragging) {
                            moveHandler.handlePressedChanged(pressed, Qt.LeftButton, priv.mousePoint.x, priv.mousePoint.y)
                            gyro.appIsBeingDragged = true;
                        }
                    } else {
                        isSwipeUp = false
                    }
                } else {
                    isSwipe = false
                }
            }
            // ENH141 - End
        }

        onReleased: {
            if (isSwipeUp) {
                moveHandler.handlePressedChanged(false, Qt.LeftButton);
                moveHandler.handleReleased(true);
                ShellNotifier.appForDragging = null
                gyro.appIsBeingDragged = false;
            }
            if (isDoubleClick || isDrag) {
                UInput.releaseMouse(UInput.ButtonLeft)
                isDoubleClick = false;
            }
            if (isClick) {
                // ENH141 - Air mouse in virtual touchpad
                // clickTimer.scheduleClick(point1.pressed ? UInput.ButtonRight : UInput.ButtonLeft)
                if (root.gyroMode) {
                    if (isSwipe) {
                        if (!isSwipeUp) {
                            clickTimer.scheduleClick(UInput.ButtonRight)
                        }
                    } else {
                        clickTimer.scheduleClick(UInput.ButtonLeft)
                    }
                } else {
                    // Do not trigger right-click when custom gesture area is enabled
                    let _button = UInput.ButtonLeft
                    if (customTwoFingerGestureArea.enabled) {
                        if (!point1.pressed) {
                            clickTimer.scheduleClick(_button)
                        }
                    } else {
                        if (point1.pressed) {
                            _button = UInput.ButtonRight
                        }
                        clickTimer.scheduleClick(_button)
                    }
                }
                // ENH141 - End
            }
            isClick = false;
            isDrag = false;
            // ENH141 - Air mouse in virtual touchpad
            isSwipe = false;
            isSwipeUp = false;

            if (!ShellNotifier.airMouseAlwaysActive) {
                gyro.relativeMousePos = Qt.point(0, 0)
            }
            // ENH141 - End
        }

        Timer {
            id: clickTimer
            repeat: false
            interval: 200
            property int button: UInput.ButtonLeft
            onTriggered: {
                UInput.pressMouse(button);
                UInput.releaseMouse(button);
                // ENH141 - Air mouse in virtual touchpad
                ShellNotifier.normalHaptics()
                // ENH141 - End
            }
            function scheduleClick(button) {
                clickTimer.button = button;
                clickTimer.start();
            }
        }

        function moveMouse(touchPoints) {
            var tp = touchPoints[0];
            if (isClick &&
                    (Math.abs(tp.x - tp.startX) > clickThreshold ||
                     Math.abs(tp.y - tp.startY) > clickThreshold)) {
                isClick = false;
                isDrag = true;
            }

            UInput.moveMouse(tp.x - tp.previousX, tp.y - tp.previousY);
        }

        function scroll(touchPoints) {
            var dh = 0;
            var dv = 0;
            var tp = touchPoints[0];
            if (isClick &&
                    (Math.abs(tp.x - tp.startX) > clickThreshold ||
                     Math.abs(tp.y - tp.startY) > clickThreshold)) {
                isClick = false;
            }
            dh += tp.x - tp.previousX;
            dv += tp.y - tp.previousY;

            tp = touchPoints[1];
            if (isClick &&
                    (Math.abs(tp.x - tp.startX) > clickThreshold ||
                     Math.abs(tp.y - tp.startY) > clickThreshold)) {
                isClick = false;
            }
            dh += tp.x - tp.previousX;
            dv += tp.y - tp.previousY;

            // As we added up the movement of the two fingers, let's divide it again by 2
            dh /= 2;
            dv /= 2;
            // ENH243 - Virtual Touchpad Enhancements
            if (ShellNotifier.invertMouseScroll) {
                dh = -dh;
                dv = -dv;
            }

            // UInput.scrollMouse(dh, dv);
            const _sensitivity = ShellNotifier.virtualTouchpadScrollSensitivity
            UInput.scrollMouse(dh * _sensitivity, dv * _sensitivity);
            // ENH243 - End
        }

        touchPoints: [
            TouchPoint {
                id: point1
            },
            TouchPoint {
                id: point2
            }
        ]
    }
    // ENH243 - Virtual Touchpad Enhancements
    QtObject {
        id: priv

        readonly property real dragWindowSensitivity: ShellNotifier.dragWindowSensitivity
        readonly property Item appToDrag: ShellNotifier.appForDragging
        readonly property point mousePoint: ShellNotifier.cursorPoint
        // Commented out since it's not need anymore
        // but retained in case I need these again
        /*
        readonly property point mousePoint: {
            const _x = ShellNotifier.cursorPoint.x
            const _y = ShellNotifier.cursorPoint.y
            let _translatedX = _x
            let _translatedY = _y

            switch (root.contentRotation) {
                case 90:
                    _translatedX = _y
                    _translatedY = -_x
                    break
                case 180:
                    _translatedX = -_x
                    _translatedY = -_y
                    break
                case 270:
                    _translatedX = -_y
                    _translatedY = _x
                    break
                case 0:
                default:
                    break
            }

            return Qt.point(_translatedX, _translatedY)
        }
        */

        onAppToDragChanged: {
            if (appToDrag) {
                appToDrag.activate();
            }
        }

        function toggleAppControlsOverlay() {
            if (appToDrag) {
                appToDrag.toggleControlsOverlay()
            }
        }

        // TODO: Possibly not needed anymore
        /*
        function getSensingPoints() {
            var xPoints = [];
            var yPoints = [];
            for (var i = 0; i < gestureArea.touchPoints.length; i++) {
                var pt = gestureArea.touchPoints[i];
                xPoints.push(pt.x);
                yPoints.push(pt.y);
            }

            var leftmost = Math.min.apply(Math, xPoints);
            var rightmost = Math.max.apply(Math, xPoints);
            var topmost = Math.min.apply(Math, yPoints);
            var bottommost = Math.max.apply(Math, yPoints);

            return {
                left: mapToItem(gestureArea.target.parent, leftmost, (topmost+bottommost)/2),
                top: mapToItem(gestureArea.target.parent, (leftmost+rightmost)/2, topmost),
                right: mapToItem(gestureArea.target.parent, rightmost, (topmost+bottommost)/2),
                topLeft: mapToItem(gestureArea.target.parent, leftmost, topmost),
                topRight: mapToItem(gestureArea.target.parent, rightmost, topmost),
                bottomLeft: mapToItem(gestureArea.target.parent, leftmost, bottommost),
                bottomRight: mapToItem(gestureArea.target.parent, rightmost, bottommost)
            }
        }
        */
    }

    MoveHandler {
        id: moveHandler
        objectName: "moveHandler"
        target: gestureArea.target

        boundsItem: ShellNotifier.availableDesktopArea
        touchpadMode: true

        onFakeMaximizeAnimationRequested: ShellNotifier.fakeMaximizeAnimationRequested(target, amount)
        onFakeMaximizeLeftAnimationRequested: ShellNotifier.fakeMaximizeLeftAnimationRequested(target, amount)
        onFakeMaximizeRightAnimationRequested: ShellNotifier.fakeMaximizeRightAnimationRequested(target, amount)
        onFakeMaximizeTopLeftAnimationRequested: ShellNotifier.fakeMaximizeTopLeftAnimationRequested(target, amount)
        onFakeMaximizeTopRightAnimationRequested: ShellNotifier.fakeMaximizeTopRightAnimationRequested(target, amount)
        onFakeMaximizeBottomLeftAnimationRequested: ShellNotifier.fakeMaximizeBottomLeftAnimationRequested(target, amount)
        onFakeMaximizeBottomRightAnimationRequested: ShellNotifier.fakeMaximizeBottomRightAnimationRequested(target, amount)
        onStopFakeAnimation: ShellNotifier.stopFakeAnimation()
    }

    // Custom 2-finger for right click
    LPMultiTouchGestureArea {
        id: customTwoFingerGestureArea

        anchors.fill: parent

        enabled: !root.gyroMode && ShellNotifier.enableCustomOneTwoGestureBehavior && (!tutorial.running || tutorial.paused)
        enableDragStep: false
        enableDoubleClick: true
        minimumTouchPoints: 2
        maximumTouchPoints: 2

        onNormalHaptics: ShellNotifier.normalHaptics()
        onSubtleHaptics: ShellNotifier.subtleHaptics()

        onDoubleClicked: UInput.pressMouse(UInput.ButtonRight)
        onDoubleClickedReleased: UInput.releaseMouse(UInput.ButtonRight)
        onClicked: {
            if (!recognizedDrag) {
                root.rightClick()
            }
        }

        onDragUpdated: {
            if (recognizedDrag) {
                if (isDoubleClick) {
                    if (recognizedDrag) {
                        const _point = points[0];
                        if (prevtp !== Qt.point(0, 0)) {
                            const _newX = (_point.x - prevtp.x)
                            const _newY = (_point.y - prevtp.y)
                            UInput.moveMouse(_newX, _newY);
                        }
                    }
                } else {
                    scroll(points)
                }
            }
        }

        function scroll(touchPoints) {
            var dh = 0;
            var dv = 0;
            var tp = touchPoints[0];
            var tp2 = touchPoints[1];

            dh += tp.x - prevtp.x;
            dv += tp.y - prevtp.y;
            dh += tp2.x - prevtp2.x;
            dv += tp2.y - prevtp2.y;

            // As we added up the movement of the two fingers, let's divide it again by 2
            dh /= 2;
            dv /= 2;

            if (ShellNotifier.invertMouseScroll) {
                dh = -dh;
                dv = -dv;
            }

            const _sensitivity = ShellNotifier.virtualTouchpadScrollSensitivity
            UInput.scrollMouse(dh * _sensitivity, dv * _sensitivity);
        }
    }
    // For moving windows
    LPMultiTouchGestureArea {
        id: gestureArea

        readonly property Item target: priv.appToDrag
        readonly property Item boundsItem: ShellNotifier.availableDesktopArea
        readonly property bool isResizeMode: target && target.touchOverlayShown

        readonly property bool appIsInSideStage: target && target.stage == ApplicationInfoInterface.SideStage
        readonly property bool switchingStageIsAvailable: target !== null && !ShellNotifier.inWindowedMode
        readonly property bool toTheRight: recognizedPress && dragStep >=  2 && !appIsInSideStage && target !== null
        readonly property bool toTheLeft: recognizedPress && dragStep <=  -2 && appIsInSideStage && target !== null
        readonly property bool inBetween: !toTheRight && !toTheLeft

        anchors.fill: parent
        enabled: ShellNotifier.enableAdvancedGestures
        dragStepThreshold: internalGu * 10
        enableDragStep: true
        minimumTouchPoints: 3
        maximumTouchPoints: minimumTouchPoints

        onToTheRightChanged: {
            if (switchingStageIsAvailable) {
                if (toTheRight && !appIsInSideStage) {
                    ShellNotifier.hintMoveAppToSideStage()
                    ShellNotifier.subtleHaptics()
                }
            }
        }
        onToTheLeftChanged: {
            if (switchingStageIsAvailable) {
                if (toTheLeft && appIsInSideStage) {
                    ShellNotifier.hintMoveAppToMainStage()
                    ShellNotifier.subtleHaptics()
                }
            }
        }
        onInBetweenChanged: {
            if (switchingStageIsAvailable) {
                if (inBetween) {
                    ShellNotifier.cancelMoveToStage()
                }
            }
        }
        onDropped: {
            if (ShellNotifier.inWindowedMode) {
                if (isResizeMode) {
                    target.toggleAppResizeFromCursor(false)
                } else {
                    moveHandler.handlePressedChanged(false, Qt.LeftButton);
                    moveHandler.handleReleased(true);
                }
            } else {
                if (switchingStageIsAvailable && !inBetween) {
                    const _toSideStage = toTheRight ? true : !toTheLeft
                    ShellNotifier.commitAppSwitchStage(_toSideStage)
                }
            }
        }

        onGesturePressed: ShellNotifier.getAppToDrag();
        onGestureReleased: ShellNotifier.appForDragging = null
        onRecognizedPressChanged: {
            if (!recognizedPress) {
                // Make sure this happens after clicked or anything that still uses appForDragging
                ShellNotifier.appForDragging = null                
            }
        }

        onTargetChanged: {
            if (target) {
                setPreviousPoint(Qt.point(target.windowedX, target.windowedY))
            }
        }

        onClicked: {
            if (ShellNotifier.inWindowedMode) {
                if (target && !target.anyMaximized) {
                    priv.toggleAppControlsOverlay()
                }
            } else {
                ShellNotifier.toggleSideStage()
            }
        }

        onDragStarted: {
            if (target !== null) {
                if (ShellNotifier.inWindowedMode) {
                    if (isResizeMode) {
                        target.toggleAppResizeFromCursor(true)
                    } else {
                        moveHandler.handlePressedChanged(recognizedPress, Qt.LeftButton, priv.mousePoint.x, priv.mousePoint.y)
                    }
                }
            }
        }

        onDragUpdated: {
            const _point = points[0];
            if (ShellNotifier.inWindowedMode) {
                if (recognizedDrag) {
                    if (prevtp !== Qt.point(0, 0)) {
                        const _newX = (_point.x - prevtp.x) * priv.dragWindowSensitivity
                        const _newY = (_point.y - prevtp.y) * priv.dragWindowSensitivity
                        UInput.moveMouse(_newX, _newY);
                    }

                    if (isResizeMode) {
                        target.updateAppResizeFromCursor()
                    } else {
                        moveHandler.handlePositionChanged(priv.mousePoint);
                    }
                }
            }
        }
    }
    
    // For Search Drawer (tap) and Workspace (swipe/drag)
    LPMultiTouchGestureArea {
        id: fourFiveGetsureArea

        anchors.fill: parent

        enabled: ShellNotifier.enableAdvancedGestures
        minimumTouchPoints: 4
        maximumTouchPoints: 5
        enableDragStep: true
        dragStepThreshold: internalGu * 10

        onNormalHaptics: ShellNotifier.normalHaptics()
        onSubtleHaptics: ShellNotifier.subtleHaptics()
        onDragStepUp: {
            if (touchPointCount === 4) {
                ShellNotifier.switchWorkspaceRight()
            } else {
                ShellNotifier.switchWorkspaceRightMoveApp()
            }
        }
        onDragStepDown: {
            if (touchPointCount === 4) {
                ShellNotifier.switchWorkspaceLeft()
            } else {
                ShellNotifier.switchWorkspaceLeftMoveApp()
            }
        }

        onClicked: ShellNotifier.showDrawer(true);
        onDropped: ShellNotifier.commitWorkspaceSwitch()
    }
    // ENH243 - End
    // ENH141 - Air mouse in virtual touchpad
    MouseArea {
        id: customMouseArea

        readonly property bool dragInProgress: dragSwipeArea.dragging && dragSwipeArea.customDragging

        property bool pressAndHoldInProgress: false

        enabled: ShellNotifier.enableCustomClickBehavior && root.enableGyroMode
        // ENH243 - Virtual Touchpad Enhancements
                    && !(gestureArea.recognisedPress || fourFiveGetsureArea.recognisedPress)
        // ENH243 - End
        visible: enabled
        anchors.fill: parent

        onClicked: {
            if (ShellNotifier.airMouseAlwaysActive) {
                root.leftClick()
            }
        }
        onPressAndHold: {
            if (ShellNotifier.airMouseAlwaysActive) {
                pressAndHoldInProgress = true
                root.leftPress()
            }
        }
        onReleased: {
            if (pressAndHoldInProgress) {
                root.leftRelease()
                pressAndHoldInProgress = false
            }
        }

        SwipeArea {
            readonly property bool customDragging: distance >= internalGu * 5
            direction: SwipeArea.Leftwards
            immediateRecognition: false
            anchors.fill: parent

            onCustomDraggingChanged: {
                if (customDragging) {
                    root.rightClick()
                }
            }
        }
        SwipeArea {
            readonly property bool customDragging: distance >= internalGu * 5
            direction: SwipeArea.Rightwards
            immediateRecognition: false
            anchors.fill: parent

            onCustomDraggingChanged: {
                if (customDragging) {
                    root.leftClick()
                }
            }
        }
        SwipeArea {
            readonly property bool customDragging: distance >= internalGu * 5
            direction: SwipeArea.Upwards
            immediateRecognition: false
            anchors.fill: parent

            onCustomDraggingChanged: {
                if (customDragging) {
                    root.doubleLeftClick()
                }
            }
        }
        SwipeArea {
            id: dragSwipeArea

            readonly property bool customDragging: distance >= internalGu * 5
            direction: SwipeArea.Downwards
            immediateRecognition: false
            anchors.fill: parent

            onCustomDraggingChanged: {
                if (customDragging) {
                    root.leftPress()
                    ShellNotifier.subtleHaptics()
                }
            }

            onDraggingChanged: {
                if (!dragging) {
                    root.leftRelease()
                    ShellNotifier.subtleHaptics()
                }
            }
        }
    }
    MultiPointTouchArea {
        id: mouseScrollStrip

        readonly property bool positionToRight: ShellNotifier.sideMouseScrollPosition == 0
        width: internalGu * 8
        anchors {
            bottom: bottomButtons.top
            top: parent.top
            margins: internalGu * 2
            topMargin: oskButton.anchors.topMargin + oskButton.height + (internalGu * 2)
        }

        state: ShellNotifier.sideMouseScrollPosition == 0 ? "right" : "left"
        states: [
            State {
                name: "right"
                AnchorChanges {
                    target: mouseScrollStrip
                    anchors.left: undefined
                    anchors.right: parent.right
                }
            }
            , State {
                name: "left"
                AnchorChanges {
                    target: mouseScrollStrip
                    anchors.left: parent.left
                    anchors.right: undefined
                }
            }
        ]
        enabled: root.gyroMode && (!tutorial.running || tutorial.paused)
        visible: enabled

        onPressed: if (ShellNotifier.enableSideMouseScrollHaptics) ShellNotifier.subtleHaptics()
        onUpdated: {
            let tp = touchPoints[0];
            let dh = tp.x - tp.previousX;
            let dv = tp.y - tp.previousY;

            dh /= 2;
            dv /= 2;

            let _invertScroll = ShellNotifier.invertSideMouseScroll
            if (_invertScroll == true) {
                dh = 0 - dh
                dv = 0 - dv
            }

            let _sensitivity = ShellNotifier.sideMouseScrollSensitivity
            UInput.scrollMouse(dh * _sensitivity, dv * _sensitivity);

            if (ShellNotifier.enableSideMouseScrollHaptics) {
                ShellNotifier.subtleHaptics()
            }
        }
        Rectangle {
            radius: internalGu * 4
            anchors.fill: parent
            color: theme.palette.normal.base
        }
    }

    RowLayout {
        id: bottomButtons
    // ENH141 - End
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: -internalGu * 1 }
        // ENH141 - Air mouse in virtual touchpad
        // height: internalGu * 10
        height: visible ? internalGu * (root.gyroMode ? 20 : 10) : 0
        visible: !ShellNotifier.hideBottomButtons || (ShellNotifier.hideBottomButtons && ShellNotifier.hideBottomButtonsOnlyAirMouse && !root.gyroMode)
        // ENH141 - End
        spacing: internalGu * 1

        MouseArea {
            id: leftButton
            objectName: "leftButton"
            Layout.fillWidth: true
            Layout.fillHeight: true
            onPressed: UInput.pressMouse(UInput.ButtonLeft);
            onReleased: UInput.releaseMouse(UInput.ButtonLeft);
            property bool highlight: false
            LomiriShape {
                anchors.fill: parent
                backgroundColor: leftButton.highlight || leftButton.pressed ? LomiriColors.ash : LomiriColors.inkstone
                Behavior on backgroundColor { ColorAnimation { duration: LomiriAnimation.FastDuration } }
            }
        }

        MouseArea {
            id: rightButton
            objectName: "rightButton"
            Layout.fillWidth: true
            Layout.fillHeight: true
            onPressed: UInput.pressMouse(UInput.ButtonRight);
            onReleased: UInput.releaseMouse(UInput.ButtonRight);
            property bool highlight: false
            LomiriShape {
                anchors.fill: parent
                backgroundColor: rightButton.highlight || rightButton.pressed ? LomiriColors.ash : LomiriColors.inkstone
                Behavior on backgroundColor { ColorAnimation { duration: LomiriAnimation.FastDuration } }
            }
        }
    }

    AbstractButton {
        id: disconnectButton
        objectName: "disconnectButton"
        anchors { right: parent.right; top: parent.top; margins: internalGu * 2 }
        height: internalGu * 6
        width: visible ? height : 0
        visible: aethercastDisplays.state === "connected"

        onClicked: {
            aethercastDisplays.enabled = false
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: LomiriColors.inkstone
        }

        Icon {
            anchors.fill: parent
            anchors.margins: internalGu * 1.5
            name: "close"
            color: "red"
        }
    }

    AbstractButton {
        id: oskButton
        objectName: "oskButton"
        anchors { right: disconnectButton.left; top: parent.top; margins: internalGu * 2 }
        height: internalGu * 6
        width: height

        onClicked: {
            settings.oskEnabled = !settings.oskEnabled
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: LomiriColors.inkstone
        }

        Icon {
            anchors.fill: parent
            anchors.margins: internalGu * 1.5
            name: "input-keyboard-symbolic"
            // ENH242 - Virtual touchpad keyboard enablement hint
            color: settings.oskEnabled ? LomiriColors.porcelain : LomiriColors.red
            // ENH242 - End
        }
    }
    // ENH241 - Rotate button in Virtual Touchpad
    AbstractButton {
        id: rotateButton
        objectName: "rotateButton"
        anchors { right: oskButton.left; top: parent.top; margins: internalGu * 2 }
        height: internalGu * 6
        width: height

        onClicked: root.rotate()

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: LomiriColors.inkstone
        }

        Icon {
            anchors.fill: parent
            anchors.margins: internalGu * 1.5
            name: "view-rotate"
            color: LomiriColors.porcelain
        }
    }
    // ENH241 - End

    // ENH141 - Air mouse in virtual touchpad
    AbstractButton {
        id: gyroButton
        objectName: "gyroButton"
        anchors { right: rotateButton.left; top: parent.top; margins: internalGu * 2 }
        height: internalGu * 6
        width: visible ? height : 0
        visible: ShellNotifier.enableAirMouse

        onClicked: root.enableGyroMode = !root.enableGyroMode

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: LomiriColors.inkstone
        }

        Icon {
            anchors.fill: parent
            anchors.margins: internalGu * 1.5
            name: root.enableGyroMode ? "input-touchpad-symbolic" : "phone-smartphone-symbolic"
            color: LomiriColors.porcelain
        }
    }
    SwipeArea {
        id: bottomSwipeArea

        readonly property bool customDragging: distance >= internalGu * 5

        enabled: ShellNotifier.enableSideGestures
        direction: SwipeArea.Upwards
        height: internalGu * 2
        immediateRecognition: true
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        onCustomDraggingChanged: {
            if (customDragging) {
                ShellNotifier.toggleQuickActions(true)
                ShellNotifier.normalHaptics()
            }
        }
    }
    SwipeArea {
        id: topSwipeArea

        readonly property bool customDragging: distance >= internalGu * 5

        enabled: ShellNotifier.enableSideGestures
        direction: SwipeArea.Downwards
        height: internalGu * 2
        immediateRecognition: true
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        onCustomDraggingChanged: {
            if (customDragging) {
                ShellNotifier.toggleIndicators()
                ShellNotifier.normalHaptics()
            }
        }
    }
    SwipeArea {
        id: rightSwipeArea

        readonly property bool shortDragging: distance >= internalGu * 5
        readonly property bool longDragging: distance >= internalGu * 15

        enabled: ShellNotifier.enableSideGestures
        direction: SwipeArea.Leftwards
        width: internalGu * ShellNotifier.sideGesturesWidth
        immediateRecognition: true
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }

        onShortDraggingChanged: if (shortDragging) ShellNotifier.subtleHaptics()
        onLongDraggingChanged: if (longDragging) ShellNotifier.subtleHaptics()

        onDraggingChanged: {
            if (!dragging) {
                if (longDragging) {
                    ShellNotifier.showSpread()
                } else if (shortDragging) {
                    ShellNotifier.switchToPrevApp()
                }
            }
        }
    }
    SwipeArea {
        id: leftSwipeArea

        readonly property bool customDragging: distance >= internalGu * 5
        enabled: ShellNotifier.enableSideGestures
        direction: SwipeArea.Rightwards
        width: internalGu * ShellNotifier.sideGesturesWidth
        immediateRecognition: true
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }

        onCustomDraggingChanged: {
            if (customDragging) {
                ShellNotifier.normalHaptics()
                ShellNotifier.showDrawer(false)
            }
        }
    }
    SwipeArea {
        id: quickActionsSwipeArea

        property bool isDragging: dragging && distance >= ShellNotifier.quickActionsSideMargins

        enabled: ShellNotifier.enableSideGestures
        direction: SwipeArea.Leftwards
        width: internalGu * ShellNotifier.sideGesturesWidth
        height: root.convertFromInch(ShellNotifier.quickActionsHeight)
        immediateRecognition: true
        anchors {
            bottom: parent.bottom
            right: parent.right
        }

        onDraggingChanged: {
            if (dragging) {
                ShellNotifier.toggleQuickActions(false)
                ShellNotifier.quickActionsSwipeArea = quickActionsSwipeArea
            } else {
                ShellNotifier.selectQuickAction()
            }
        }
    }
    // ENH141 - End

    InputMethod {
        id: inputMethod
        // Don't resize when there is only one screen to avoid resize clashing with the InputMethod in the Shell.
        enabled: root.oskEnabled && settings.oskEnabled && !tutorial.running
        objectName: "inputMethod"
        anchors.fill: parent
        // ENH224 - Brightness control in Virtual Touchpad mode
        onVisibleChanged: ShellNotifier.oskDisplayedInTouchpad = visible
        // ENH224 - End
    }

    Label {
        id: tutorialLabel
        objectName: "tutorialLabel"
        anchors { left: parent.left; top: parent.top; right: parent.right; margins: internalGu * 4; topMargin: internalGu * 10 }
        opacity: 0
        visible: opacity > 0
        font.pixelSize: 2 * internalGu
        color: "white"
        wrapMode: Text.WordWrap
    }

    Icon {
        id: tutorialImage
        objectName: "tutorialImage"
        height: internalGu * 8
        width: height
        name: "input-touchpad-symbolic"
        color: "white"
        opacity: 0
        visible: opacity > 0
        anchors { top: tutorialLabel.bottom; horizontalCenter: parent.horizontalCenter; margins: internalGu * 2 }
    }

    Item {
        id: tutorialFinger1
        objectName: "tutorialFinger1"
        width: internalGu * 5
        height: width
        property real scale: 1
        opacity: 0
        visible: opacity > 0
        Rectangle {
            width: parent.width * parent.scale
            height: width
            anchors.centerIn: parent
            radius: width / 2
            color: LomiriColors.inkstone
        }
    }

    Item {
        id: tutorialFinger2
        objectName: "tutorialFinger2"
        width: internalGu * 5
        height: width
        property real scale: 1
        opacity: 0
        visible: opacity > 0
        Rectangle {
            width: parent.width * parent.scale
            height: width
            anchors.centerIn: parent
            radius: width / 2
            color: LomiriColors.inkstone
        }
    }

    SequentialAnimation {
        id: tutorial
        objectName: "tutorialAnimation"

        PropertyAction { targets: [leftButton, rightButton, oskButton]; property: "enabled"; value: false }
        PropertyAction { targets: [leftButton, rightButton, oskButton]; property: "opacity"; value: 0 }
        PropertyAction { target: tutorialLabel; property: "text"; value: i18n.tr("Your device is now connected to an external display. Use this screen as a touch pad to interact with the pointer.") }
        LomiriNumberAnimation { targets: [tutorialLabel, tutorialImage]; property: "opacity"; to: 1; duration: LomiriAnimation.FastDuration }
        PropertyAction { target: tutorial; property: "paused"; value: true }
        PauseAnimation { duration: 500 } // it takes a bit until pausing actually takes effect
        LomiriNumberAnimation { targets: [tutorialLabel, tutorialImage]; property: "opacity"; to: 0; duration: LomiriAnimation.FastDuration }

        LomiriNumberAnimation { target: leftButton; property: "opacity"; to: 1 }
        LomiriNumberAnimation { target: rightButton; property: "opacity"; to: 1 }

        PauseAnimation { duration: LomiriAnimation.SleepyDuration }
        PropertyAction { target: tutorialLabel; property: "text"; value: i18n.tr("Tap left button to click.") }
        LomiriNumberAnimation { target: tutorialLabel; property: "opacity"; to: 1; duration: LomiriAnimation.FastDuration }
        SequentialAnimation {
            loops: 2
            PropertyAction { target: leftButton; property: "highlight"; value: true }
            PauseAnimation { duration: LomiriAnimation.FastDuration }
            PropertyAction { target: leftButton; property: "highlight"; value: false }
            PauseAnimation { duration: LomiriAnimation.SleepyDuration }
        }
        LomiriNumberAnimation { target: tutorialLabel; property: "opacity"; to: 0; duration: LomiriAnimation.FastDuration }

        PauseAnimation { duration: LomiriAnimation.SleepyDuration }
        PropertyAction { target: tutorialLabel; property: "text"; value: i18n.tr("Tap right button to right click.") }
        LomiriNumberAnimation { target: tutorialLabel; property: "opacity"; to: 1; duration: LomiriAnimation.FastDuration }
        SequentialAnimation {
            loops: 2
            PropertyAction { target: rightButton; property: "highlight"; value: true }
            PauseAnimation { duration: LomiriAnimation.FastDuration }
            PropertyAction { target: rightButton; property: "highlight"; value: false }
            PauseAnimation { duration: LomiriAnimation.SleepyDuration }
        }
        LomiriNumberAnimation { target: tutorialLabel; property: "opacity"; to: 0; duration: LomiriAnimation.FastDuration }

        PauseAnimation { duration: LomiriAnimation.SleepyDuration }
        PropertyAction { target: tutorialLabel; property: "text"; value: i18n.tr("Swipe with two fingers to scroll.") }
        LomiriNumberAnimation { target: tutorialLabel; property: "opacity"; to: 1; duration: LomiriAnimation.FastDuration }
        PropertyAction { target: tutorialFinger1; property: "x"; value: root.width / 2 - tutorialFinger1.width - internalGu * 1 }
        PropertyAction { target: tutorialFinger2; property: "x"; value: root.width / 2 + tutorialFinger1.width + internalGu * 1 - tutorialFinger2.width }
        PropertyAction { target: tutorialFinger1; property: "y"; value: root.height / 2 - internalGu * 10 }
        PropertyAction { target: tutorialFinger2; property: "y"; value: root.height / 2 - internalGu * 10 }
        SequentialAnimation {
            ParallelAnimation {
                LomiriNumberAnimation { target: tutorialFinger1; property: "opacity"; to: 1; duration: LomiriAnimation.FastDuration }
                LomiriNumberAnimation { target: tutorialFinger2; property: "opacity"; to: 1; duration: LomiriAnimation.FastDuration }
                LomiriNumberAnimation { target: tutorialFinger1; property: "scale"; from: 0; to: 1; duration: LomiriAnimation.FastDuration }
                LomiriNumberAnimation { target: tutorialFinger2; property: "scale"; from: 0; to: 1; duration: LomiriAnimation.FastDuration }
            }
            ParallelAnimation {
                LomiriNumberAnimation { target: tutorialFinger1; property: "y"; to: root.height / 2 + internalGu * 10; duration: LomiriAnimation.SleepyDuration }
                LomiriNumberAnimation { target: tutorialFinger2; property: "y"; to: root.height / 2 + internalGu * 10; duration: LomiriAnimation.SleepyDuration }
            }
            ParallelAnimation {
                LomiriNumberAnimation { target: tutorialFinger1; property: "opacity"; to: 0; duration: LomiriAnimation.FastDuration }
                LomiriNumberAnimation { target: tutorialFinger2; property: "opacity"; to: 0; duration: LomiriAnimation.FastDuration }
                LomiriNumberAnimation { target: tutorialFinger1; property: "scale"; from: 1; to: 0; duration: LomiriAnimation.FastDuration }
                LomiriNumberAnimation { target: tutorialFinger2; property: "scale"; from: 1; to: 0; duration: LomiriAnimation.FastDuration }
            }
            PauseAnimation { duration: LomiriAnimation.SlowDuration }
            ParallelAnimation {
                LomiriNumberAnimation { target: tutorialFinger1; property: "opacity"; to: 1; duration: LomiriAnimation.FastDuration }
                LomiriNumberAnimation { target: tutorialFinger2; property: "opacity"; to: 1; duration: LomiriAnimation.FastDuration }
                LomiriNumberAnimation { target: tutorialFinger1; property: "scale"; from: 0; to: 1; duration: LomiriAnimation.FastDuration }
                LomiriNumberAnimation { target: tutorialFinger2; property: "scale"; from: 0; to: 1; duration: LomiriAnimation.FastDuration }
            }
            ParallelAnimation {
                LomiriNumberAnimation { target: tutorialFinger1; property: "y"; to: root.height / 2 - internalGu * 10; duration: LomiriAnimation.SleepyDuration }
                LomiriNumberAnimation { target: tutorialFinger2; property: "y"; to: root.height / 2 - internalGu * 10; duration: LomiriAnimation.SleepyDuration }
            }
            ParallelAnimation {
                LomiriNumberAnimation { target: tutorialFinger1; property: "opacity"; to: 0; duration: LomiriAnimation.FastDuration }
                LomiriNumberAnimation { target: tutorialFinger2; property: "opacity"; to: 0; duration: LomiriAnimation.FastDuration }
                LomiriNumberAnimation { target: tutorialFinger1; property: "scale"; from: 1; to: 0; duration: LomiriAnimation.FastDuration }
                LomiriNumberAnimation { target: tutorialFinger2; property: "scale"; from: 1; to: 0; duration: LomiriAnimation.FastDuration }
            }
            PauseAnimation { duration: LomiriAnimation.SlowDuration }
        }
        LomiriNumberAnimation { target: tutorialLabel; property: "opacity"; to: 0; duration: LomiriAnimation.FastDuration }

        PauseAnimation { duration: LomiriAnimation.SleepyDuration }
        PropertyAction { target: tutorialLabel; property: "text"; value: i18n.tr("Find more settings in the system settings.") }
        LomiriNumberAnimation { target: tutorialLabel; property: "opacity"; to: 1; duration: LomiriAnimation.FastDuration }
        PauseAnimation { duration: 2000 }
        LomiriNumberAnimation { target: tutorialLabel; property: "opacity"; to: 0; duration: LomiriAnimation.FastDuration }

        LomiriNumberAnimation { target: oskButton; property: "opacity"; to: 1 }
        PropertyAction { targets: [leftButton, rightButton, oskButton]; property: "enabled"; value: true }

        PropertyAction { target: settings; property: "touchpadTutorialHasRun"; value: true }
    }
}
