/*
 * Copyright (C) 2015-2016 Canonical Ltd
 *
 * This file is part of Ubuntu Clock App
 *
 * Ubuntu Clock App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * Ubuntu Clock App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// ENH064 - Dynamic Cove
import QtQuick 2.12
import Lomiri.Components 1.3
import QtSystemInfo 5.0
import "Clock"

LPDynamicCoveItem {
    id: stopWatch

    readonly property alias running: timer.running
    
    onScreenIsOffChanged: {
        if (screenIsOff) {
            if (running) {
                stopwatchCircle.saveTime(true)
            }
        } else {
            stopwatchCircle.restoreTime()
        }
    }

    ScreenSaver {
        id: screenSaver
        // Disable screen dimming/off when stopwatch is running
        screenSaverEnabled: !timer.running
    }

    Connections {
        target: mouseArea
        function onClicked(mouse) {
            if (!stopWatch.running) {
                stopwatchCircle.start()
            } else {
                stopwatchCircle.pause()
            }
            shell.haptics.play()
        }
    }

    Connections {
        target: swipeArea
        function onTriggered() {
            stopwatchCircle.clear()
        }
    }

    Rectangle {
        id: pressedBg

        anchors.fill: stopwatchCircle
        radius: width / 2
        opacity: 0.3
        color: stopWatch.mouseArea.containsPress ? theme.palette.highlighted.foreground : theme.palette.normal.foreground
        Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
    }

    LPClockCircle {
        id: stopwatchCircle

        readonly property bool isCleared: milliseconds === 0
        // Property to hold the total time (in milliseconds)
        property int milliseconds: 0
        property bool aboutToClear: (stopWatch.swipeArea.dragging && stopWatch.swipeArea.draggingCustom) || (clearHoverHandler.hovered && !isCleared)
        
        function start() {
            timer.restart()
        }

        function pause() {
            timer.stop()
        }

        function clear() {
            pause()
            milliseconds = 0
        }

        function restoreTime() {
            if (shell.settings.dcStopwatchLastEpoch > 0) {
                milliseconds = shell.settings.dcStopwatchTimeMS + (new Date().getTime() - shell.settings.dcStopwatchLastEpoch)
                start()
            } else {
                milliseconds = shell.settings.dcStopwatchTimeMS
            }
        }

        function saveTime(_pauseTimer = false) {
            shell.settings.dcStopwatchTimeMS = milliseconds
            if (stopWatch.running) {
                shell.settings.dcStopwatchLastEpoch = new Date().getTime()
            } else {
                shell.settings.dcStopwatchLastEpoch = 0
            }
            if (_pauseTimer) {
                pause()
            }
        }

        isFoldVisible: true

        anchors.centerIn: parent
        width: units.gu(5)
        height: width
        Component.onCompleted: {
            delayOpenAnimation.restart()
            restoreTime()
        }
        Component.onDestruction: {
            screenSaver.screenSaverEnabled = true
            saveTime()
        }
        Behavior on width { LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration } }

        // WORKAROUND: Delay to avoid the issue where the animation
        // doesn't seem to execute upong locking the device
        Timer {
            id: delayOpenAnimation

            running: false
            interval: 1
            onTriggered: stopwatchCircle.width = stopwatchCircle.parent.width
        }
        
        Timer {
            id: timer

            running: false
            interval: 45
            repeat: true
            onTriggered: {
                stopwatchCircle.milliseconds += interval
            }
        }

        Item {
            id: stopwatchFormatTime
            
            function millisToTimeString(millis, showHours) {
                let timeString = ""

                let hours = Math.floor((millis%(1000 * 60 * 60 * 24))/(1000 * 60 * 60));
                let minutes = Math.floor((millis % (1000 * 60 * 60)) / (1000 * 60));
                let seconds = Math.floor((millis % (1000 * 60)) / 1000);

                if (showHours)
                {
                    if (hours < 10)
                    {
                        timeString += addZeroPrefix(hours.toString(), 2) + ":";
                    }

                    else {
                        timeString += hours + ":";
                    }
                }

                timeString += addZeroPrefix(minutes.toString(), 2) + ":";
                timeString += addZeroPrefix(seconds.toString(), 2);
                return timeString;
            }

            function millisToString(millis) {
                return addZeroPrefix(millis.toString(), 3);
            }
            
            function addZeroPrefix(str, totalLength) {
                let result = ("00000" + str)
                return result.replace(result.substring(0, 5 + str.length - totalLength), "");
            }
        }
        
        Label {
            anchors {
                bottom: time.top
                bottomMargin: units.gu(6)
                horizontalCenter: parent.horizontalCenter
            }
            text: "》"
            rotation: -90
            color: theme.palette.normal.negative
            opacity: (stopwatchCircle.aboutToClear && !clearHoverHandler.hovered) || stopwatchCircle.isCleared ? 0 : 0.8

            Behavior on opacity {
                LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration }
            }

            TapHandler {
                id: clearTapHandler
                acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Cursor | PointerDevice.Pen
                //cursorShape: Qt.PointingHandCursor // Needs Qt5.15
                onSingleTapped: stopwatchCircle.clear()
            }

            HoverHandler {
                id: clearHoverHandler
                acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Cursor | PointerDevice.Pen
            }
            Binding {
                target: stopWatch
                property: "enableMouseArea"
                value: !clearHoverHandler.hovered
            }
        }
        
        Label {
            text: "Clear"
            color: theme.palette.normal.negative
            anchors.centerIn: parent
            textSize: Label.Medium
            opacity: stopwatchCircle.aboutToClear ? 1 : 0
            Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration } }
        }

        Label {
            id: time
            objectName: "stopwatchTime"

            text: stopwatchFormatTime.millisToTimeString(stopwatchCircle.milliseconds, true)
            font.pixelSize: units.dp(36)
            anchors.centerIn: parent
            color: stopWatch.running ? theme.palette.normal.activity : theme.palette.normal.baseText
            opacity: !stopwatchCircle.aboutToClear && stopwatchCircle.width == stopwatchCircle.parent.width ? 1 : 0
            Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration } }
            Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
        }

        Label {
            id: miliseconds
            objectName: "stopwatchMilliseconds"

            text: stopwatchFormatTime.millisToString(stopwatchCircle.milliseconds)
            textSize: Label.Large
            color: time.color
            anchors {
                top: time.bottom
                topMargin: units.gu(1.5)
                horizontalCenter: parent.horizontalCenter
            }
            opacity: !stopwatchCircle.aboutToClear && stopwatchCircle.width == stopwatchCircle.parent.width ? 1 : 0
            Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration } }
            Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
        }

    }
}
