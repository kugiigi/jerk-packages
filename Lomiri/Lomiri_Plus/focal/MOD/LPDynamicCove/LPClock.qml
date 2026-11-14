/*
 * Copyright (C) 2014-2016 Canonical Ltd
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
import "Clock"

LPDynamicCoveItem {
    id: clock

    property date currentDate: new Date()
    readonly property int currentHour24h: currentDate.getHours()
    property int currentHour: currentHour24h > 12 ? currentHour24h - 12 : currentHour24h
    property bool initialOpen: true

    Connections {
        target: mouseArea

        onPressAndHold: {
            _clockContainer.flipClock()
            shell.haptics.play()
        }
    }
    
    LiveTimer {
        frequency: clock.visible && !clock.screenIsOff ? LiveTimer.Second : LiveTimer.Disabled
        onTrigger: currentDate = new Date()
    }

    Item {
        id: _clockContainer

        // String with not localized date and time in format "yyyy:MM:dd:hh:mm:ss", eg.: "2016:10:05:16:10:15"
        property string notLocalizedDateTimeString: Qt.formatDateTime(clock.currentDate,"yyyy:MM:dd:hh:mm:ss")

        // String with localized time, eg.: "4:10 PM"
        property string localizedTimeString: Qt.formatTime(clock.currentDate,"h:mm AP")

        // String with localized date, eg.: "Thursday, 17 September 2016"
        property string localizedDateString: Qt.formatDate(clock.currentDate, Qt.DefaultLocaleLongDate)

        // Property to keep track of the clock mode
        property alias isDigital: clockModeFlipable.isDigital

        // Properties to set the dimension of the clock like the font size, width etc
        property int fontSize: units.dp(44)
        property int periodFontSize: units.dp(12)
        property int maxDateFontSize: units.dp(24)
        property int innerCircleWidth: parent.width

        // Property to set if the component is the parent or the child
        property bool isMainClock: true

        // Properties to expose the analog and digital modes
        property alias digitalModeLoader: _digitalModeLoader
        property alias analogModeLoader: _analogModeLoader
        
        // Property to keep track of the cold start status of the app
        property bool isColdStart: true

        anchors.centerIn: parent
        width: units.gu(5)
        height: width

        // Signal which is triggered whenever the flip animation is started
        signal triggerFlip();
        
        Component.onCompleted: {
            clockOpenAnimation.start()
        }

        function flipClock() {
            clockFlipAnimation.start()
        }

        LPShadow {
            id: upperShadow
            rotation: 0
            width: _clockContainer.innerCircleWidth - units.gu(0.5)
            z: clockModeFlipable.z + 2
            anchors.centerIn: clockModeFlipable
            anchors.verticalCenterOffset: -width/4
        }

        LPShadow {
            id: bottomShadow
            rotation: 180
            width: upperShadow.width
            z: clockModeFlipable.z + 2
            anchors.centerIn: clockModeFlipable
            anchors.verticalCenterOffset: width/4
        }

        Flipable {
            id: clockModeFlipable

            // Property to switch between digital and analog mode
            property bool isDigital: shell.settings.dcDigitalClockMode ? true : false

            width: _clockContainer.innerCircleWidth
            height: width
            anchors.centerIn: parent

            front: Loader {
                id: _analogModeLoader
                anchors.centerIn: parent
                active: !clockModeFlipable.isDigital
                sourceComponent: LPAnalogMode {
                    maxWidth: _clockContainer.innerCircleWidth
                    width: _clockContainer.innerCircleWidth
                    showSeconds: _clockContainer.isMainClock
                    localDateTime: _clockContainer.notLocalizedDateTimeString
                }
                onLoaded: {
                    if (!clockModeFlipable.isDigital && clock.initialOpen) {
                        item.startAnimation()
                        clock.initialOpen = false
                    }
                }
            }

            back: Loader {
                id: _digitalModeLoader
                anchors.centerIn: parent
                active: clockModeFlipable.isDigital
                sourceComponent: LPDigitalMode {
                    width: _clockContainer.innerCircleWidth
                    timeFontSize: _clockContainer.fontSize
                    timePeriodFontSize: _clockContainer.periodFontSize
                    localizedTimeString: _clockContainer.localizedTimeString
                    localizedDateString: _clockContainer.localizedDateString
                }
                onLoaded: {
                    if (clockModeFlipable.isDigital && clock.initialOpen) {
                        item.startAnimation()
                        clock.initialOpen = false
                    }
                }
            }

            transform: Rotation {
                id: rotation
                origin.x: clockModeFlipable.width/2
                origin.y: clockModeFlipable.height/2
                axis.x: 1; axis.y: 0; axis.z: 0
                angle: 0
            }

            states: State {
                name: "Digital"
                when: clockModeFlipable.isDigital
                PropertyChanges {
                    target: rotation
                    angle: 180
                }
            }
        }

        /*
          The clockFlipAnimation is executed during every switch between
          analog and digital modes.
        */
        SequentialAnimation {
            id: clockFlipAnimation

            ScriptAction {
                script: {
                    _clockContainer.triggerFlip()
                }
            }

            LomiriNumberAnimation {
                target: bottomShadow
                property: "opacity"
                duration: 166
                from: 1
                to: 0
            }

            LomiriNumberAnimation {
                target: upperShadow
                property: "opacity"
                duration: 166
                from: 0
                to: 1
            }

            /*
              Script to clean up after the flip animation is complete which
              involves (in the order listed below)
                - Hiding the shadows
                - Toggling clock mode and unloading the hidden mode
                - Unloading the analog and digital shadow required to show the
                  paper effect
            */

            ScriptAction {
                script: {
                    upperShadow.opacity = bottomShadow.opacity = 0
                    _clockContainer.isDigital = !_clockContainer.isDigital

                    if(_clockContainer.isMainClock) {
                        shell.settings.dcDigitalClockMode = !shell.settings.dcDigitalClockMode
                    }
                }
            }
        }
        
        /*
          The clockOpenAnimation is only executed once when the clock app is
          opened.
        */
        SequentialAnimation {
            id: clockOpenAnimation


            LomiriNumberAnimation {
                target: _clockContainer
                property: "width"
                to: _clockContainer.parent.width
                duration: LomiriAnimation.SlowDuration
            }
        }
    }
}
