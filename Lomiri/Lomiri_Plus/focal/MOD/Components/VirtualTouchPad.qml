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

import QtQuick 2.12
import QtQuick.Layouts 1.1
import Lomiri.Components 1.3
import Qt.labs.settings 1.0
import UInput 0.1
import "../Components"
// ENH141 - Air mouse in virtual touchpad
import QtSensors 5.12
import QtFeedback 5.0
// ENH141 - End

Item {
    id: root

    property bool oskEnabled: false
    // ENH141 - Air mouse in virtual touchpad
    readonly property bool gyroMode: enableGyroMode && settingsObj
                                    && (
                                        (typeof settingsObj.value("enableAirMouse", 0) === "string" && settingsObj.value("enableAirMouse", 0) === "true")
                                        ||
                                        (typeof settingsObj.value("enableAirMouse", 0) === "boolean" && settingsObj.value("enableAirMouse", 0) === true)
                                    )
    property bool enableGyroMode: false
    // ENH141 - End

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

    Settings {
        id: settingsObj

        category: "lomiriplus"
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
        intensity: 0.5
        duration: 2
        fadeTime: 50
        fadeIntensity: 0.0
    }

    Gyroscope {
        id: gyro

        // Mouse position relative to initial press on the touchpad
        property point relativeMousePos: Qt.point(0, 0)

        active: root.gyroMode

        onReadingChanged: {
            if (reading
                    && 
                    (
                        (settingsObj
                            && (
                                (typeof settingsObj.value("airMouseAlwaysActive", 0) === "string" && settingsObj.value("airMouseAlwaysActive", 0) === "true")
                                ||
                                (typeof settingsObj.value("airMouseAlwaysActive", 0) === "boolean" && settingsObj.value("airMouseAlwaysActive", 0) === true)
                               )
                        )
                        ||
                        multiTouchArea.touchPoints[0].pressed
                    )
                ) {
                let _sensitivityMultiplier = settingsObj ? settingsObj.value("airMouseSensitivity", 0) : 1
                let _newMouseX = 0 - reading.z * _sensitivityMultiplier
                let _newMouseY = 0 - reading.x * _sensitivityMultiplier

                // Consolidate all mouse movements after pressing the touchpad
                // then reset it to 0 on press release
                if (multiTouchArea.touchPoints[0].pressed) {
                    relativeMousePos = Qt.point(relativeMousePos.x + reading.z, relativeMousePos.y + reading.x)
                } else {
                    relativeMousePos = Qt.point(0, 0)
                }

                // Get the distance of the consolidated mouse movements from point 0
                // to get the distance the mouse has traveled since pressing the touchpad
                if (multiTouchArea.isClick &&
                        root.calculatePointDistance(Qt.point(0, 0), relativeMousePos) > multiTouchArea.clickThreshold) {
                    multiTouchArea.isClick = false;
                    multiTouchArea.isDrag = true;
                }

                UInput.moveMouse(_newMouseX, _newMouseY);
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
                subtleHaptics.start()
            }
        }
    // ENH141 - End
        objectName: "touchPadArea"
        anchors.fill: parent
        enabled: !tutorial.running || tutorial.paused

        // FIXME: Once we have Qt DPR support, this should be Qt.styleHints.startDragDistance
        readonly property int clickThreshold: internalGu * 1.5
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
                let _distance = _point.y - _point.startY

                if (Math.abs(_distance) > clickSwipeThreshold) {
                    isSwipe = true
                    if (_distance < 0) {
                        isSwipeUp = true
                        isClick = false;
                        isDrag = true;
                        UInput.pressMouse(UInput.ButtonLeft)
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
                    clickTimer.scheduleClick(point1.pressed ? UInput.ButtonRight : UInput.ButtonLeft)
                }
                // ENH141 - End
            }
            isClick = false;
            isDrag = false;
            // ENH141 - Air mouse in virtual touchpad
            isSwipe = false;
            isSwipeUp = false;

            if (
                (typeof settingsObj.value("airMouseAlwaysActive", 0) === "string" && settingsObj.value("airMouseAlwaysActive", 0) === "false")
                ||
                (typeof settingsObj.value("airMouseAlwaysActive", 0) === "boolean" && settingsObj.value("airMouseAlwaysActive", 0) === false)
               ) {
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
                normalHaptics.start()
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

            UInput.scrollMouse(dh, dv);
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

    // ENH141 - Air mouse in virtual touchpad
    MultiPointTouchArea {
        id: mouseScrollStrip

        readonly property bool positionToRight: settingsObj && settingsObj.value("sideMouseScrollPosition", 0) == 0
        width: internalGu * 10
        anchors {
            bottom: bottomButtons.top
            top: parent.top
            margins: internalGu * 2
            topMargin: oskButton.anchors.topMargin + oskButton.height + (internalGu * 2)
        }
        state: settingsObj && settingsObj.value("sideMouseScrollPosition", 0) == 0 ? "right" : "left"
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

        onPressed: if (settingsObj && settingsObj.value("enableSideMouseScrollHaptics", 0)) subtleHaptics.start()
        onUpdated: {
            let tp = touchPoints[0];
            let dh = tp.x - tp.previousX;
            let dv = tp.y - tp.previousY;

            dh /= 2;
            dv /= 2;

            let _invertScroll = (typeof settingsObj.value("invertSideMouseScroll", 0) === "string" && settingsObj.value("invertSideMouseScroll", 0) === "true")
                                ||
                                (typeof settingsObj.value("invertSideMouseScroll", 0) === "boolean" && settingsObj.value("invertSideMouseScroll", 0) === true)
            if (_invertScroll == true) {
                dh = 0 - dh
                dv = 0 - dv
            }
            let _sensitivity = settingsObj ? settingsObj.value("sideMouseScrollSensitivity", 0) : 1
            UInput.scrollMouse(dh * _sensitivity, dv * _sensitivity);

            if (settingsObj && settingsObj.value("enableSideMouseScrollHaptics", 0)) {
                subtleHaptics.start()
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
        height: internalGu * (root.gyroMode ? 20 : 10)
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
        id: oskButton
        objectName: "oskButton"
        anchors { right: parent.right; top: parent.top; margins: internalGu * 2 }
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
        }
    }

    // ENH141 - Air mouse in virtual touchpad
    SwipeArea {
        readonly property bool customDragging: distance >= internalGu * 5
        enabled: settingsObj && settingsObj.value("enableAirMouse", 0)
        direction: SwipeArea.Upwards
        height: internalGu * 1
        immediateRecognition: true
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        onCustomDraggingChanged: {
            if (customDragging) {
                normalHaptics.start()
                root.enableGyroMode = !root.enableGyroMode
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
