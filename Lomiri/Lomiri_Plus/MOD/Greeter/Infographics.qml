/*
 * Copyright (C) 2013-2016 Canonical, Ltd.
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

import "Gradient.js" as Gradient
import QtQuick 2.12
import Ubuntu.Components 1.3
// ENH064 - Dynamic Cove
import "../Components"
import "../LPDynamicCove" as DynamicCove
// ENH064 - End

Item {
    id: infographic

    property var model

    property int animDuration: 10

    property int currentWeekDay
    // ENH032 - Infographics Outer Wilds
    property bool enableOW: false
    // ENH032 - End
    // ENH064 - Dynamic Cove
    readonly property alias dynamicCoveClock: dynamicCove.isClock
    // ENH064 - End

    QtObject {
        id: d
        objectName: "infographicPrivate"
        property bool useDotAnimation: true
        property int circleModifier: useDotAnimation ? 1 : 2
        property bool animating: dotHideAnimTimer.running
                              || dotShowAnimTimer.running
                              || circleChangeAnimTimer.running
    }

    QtObject {
        id: whiteTheme
        property color main: "white"
        property color start: "white"
        property color end: "white"
    }

    Connections {
        target: model
        ignoreUnknownSignals: model === undefined

        onDataAboutToAppear: startHideAnimation() // hide "no data" label
        onDataAppeared: startShowAnimation()

        onDataAboutToChange: startHideAnimation()
        onDataChanged: startShowAnimation()

        onDataAboutToDisappear: startHideAnimation()
        onDataDisappeared: startShowAnimation() // show "no data" label
    }

    LiveTimer {
        frequency: LiveTimer.Hour
        onTrigger: handleTimerTrigger()
    }

    function handleTimerTrigger(){
        var today = new Date().getDay()
        if(infographic.currentWeekDay !== today){
            infographic.currentWeekDay = today
            reloadUserData();
        }
    }

    function reloadUserData(){
        d.useDotAnimation = false
        infographic.model.nextDataSource()
    }

    function startShowAnimation() {
        dotHideAnimTimer.stop()
        notification.hideAnim.stop()

        if (d.useDotAnimation) {
            dotShowAnimTimer.startFromBeginning()
        }
        notification.showAnim.start()
    }

    function startHideAnimation() {
        dotShowAnimTimer.stop()
        circleChangeAnimTimer.stop()
        notification.showAnim.stop()

        if (d.useDotAnimation) {
            dotHideAnimTimer.startFromBeginning()
        } else {
            circleChangeAnimTimer.startFromBeginning()
        }
        notification.hideAnim.start()
    }
    // ENH064 - Dynamic Cove
    // visible: model.username !== ""
    visible: model.username !== "" || shell.settings.enableDynamicCove
    // ENH064 - End

    Component.onCompleted: {
        currentWeekDay = new Date().getDay()
        startShowAnimation()
    }

    Item {
        id: dataCircle
        objectName: "dataCircle"

        property real divisor: 1.5
        // ENH032 - Infographics Outer Wilds
        visible: !infographic.enableOW
        // ENH032 - End

        width: Math.min(parent.height, parent.width) / divisor
        height: width

        anchors.centerIn: parent

        Timer {
            id: circleChangeAnimTimer

            property int pastCircleCounter
            property int presentCircleCounter

            interval: notification.duration
            running: false
            repeat: true
            onTriggered: {
                if (pastCircleCounter < pastCircles.count) {
                    var nextCircle = pastCircles.itemAt(pastCircleCounter++)
                    if (nextCircle !== null) nextCircle.pastCircleChangeAnim.start()
                }
                if (pastCircleCounter > pastCircles.count / 2) {
                    var nextCircle = presentCircles.itemAt(presentCircleCounter++)
                    if (nextCircle !== null) nextCircle.presentCircleChangeAnim.start()
                }
                if (presentCircleCounter > infographic.model.currentDay && pastCircleCounter >= pastCircles.count) {
                    stop()
                }
            }

            function startFromBeginning() {
                circleChangeAnimTimer.pastCircleCounter = 0
                circleChangeAnimTimer.presentCircleCounter = 0
                start()
            }
        }

        MouseArea {
            id: circularMenuMouseArea

            anchors {
                fill: parent
                margins: units.gu(-3)
            }
            hoverEnabled: true
            propagateComposedEvents: true
            
//~             Rectangle {
//~                 id: bg

//~                 anchors.fill: parent
//~                 color: "blue"
//~                 radius: width / 2
//~                 opacity: 0.5
//~             }
        }

        // ENH064 - Dynamic Cove
        Loader {
            id: dynamicCove

            readonly property bool isCDPlayer: sourceComponent == cdPlayerComponent
            readonly property bool isInfographic: sourceComponent == infographicComponent
            readonly property bool isClock: sourceComponent == clockComponent
            readonly property bool isTimer: sourceComponent == timerComponent
            property var model: [
                {"itemid": "infographics", "label": "Infographics", "component": infographicComponent, "iconName": "info"}
                ,{"itemid": "cdplayer", "label": "Media Controls", "component": cdPlayerComponent, "iconName": "stock_music"}
                ,{"itemid": "mediaplayer", "label": "Media Player", "component": mediaPlayerComponent, "iconName": "media-playlist"}
                ,{"itemid": "clock", "label": "Clock", "component": clockComponent, "iconName": "clock"}
                ,{"itemid": "timer", "label": "Timer", "component": timerComponent, "iconName": "timer"}
                ,{"itemid": "stopwatch", "label": "Stopwatch", "component": stopwatchComponent, "iconName": "stopwatch"}
            ]

            asynchronous: true
            anchors.fill: parent
            sourceComponent: !infographics.enableOW && shell.settings.enableDynamicCove ? model[shell.settings.dynamicCoveCurrentItem].component : null
            onSourceComponentChanged: d.useDotAnimation = true
            onIsInfographicChanged: {
                notification.hideAnim.start()
                notification.showAnim.start()
            }
            Component.onCompleted: if (shell.settings.dcShowClockWhenLockscreen) shell.settings.dynamicCoveCurrentItem = 3
        }

        Component {
            id: cdPlayerComponent

            DynamicCove.LPCDPlayer {
                id: cdPlayer

                swipeArea: nextPrevSwipe
                mouseArea: circleMouseArea
            }
        }
        Component {
            id: mediaPlayerComponent

            DynamicCove.LPMediaPlayer {
                id: mediaPlayer

                swipeArea: nextPrevSwipe
                mouseArea: circleMouseArea
            }
        }
        Component {
            id: infographicComponent

            DynamicCove.LPDynamicCoveItem {
                id: infographicItem

                swipeArea: nextPrevSwipe
                mouseArea: circleMouseArea
            }
        }
        Component {
            id: stopwatchComponent

            DynamicCove.LPStopwatchFace {
                id: stopWatchItem

                swipeArea: nextPrevSwipe
                mouseArea: circleMouseArea
            }
        }
        Component {
            id: clockComponent

            DynamicCove.LPClock {
                id: clockItem

                mouseArea: circleMouseArea
            }
        }
        Component {
            id: timerComponent

            DynamicCove.LPTimer {
                id: timerItem

                swipeArea: nextPrevSwipe
                mouseArea: circleMouseArea
                secondaryMouseArea: secondMouseArea
            }
        }
        // ENH064 - End

        Repeater {
            id: pastCircles
            objectName: "pastCircles"
            model: infographic.model.secondMonth

            delegate: ObjectPositioner {
                property alias pastCircleChangeAnim: pastCircleChangeAnim

                index: model.index
                count: pastCircles.count
                radius: dataCircle.width / 2
                halfSize: pastCircle.width / 2
                posOffset: 0.0

                Circle {
                    id: pastCircle
                    objectName: "pastCircle" + index

                    property real divisor: 1.8
                    property real circleOpacity: 0.1

                    width: dataCircle.width / divisor
                    height: dataCircle.height / divisor
                    opacity: 0.0
                    circleScale: 0.0
                    visible: modelData !== undefined
                    color: "transparent"
                    centerCircle: dataCircle

                    SequentialAnimation {
                        id: pastCircleChangeAnim

                        loops: 1
                        ParallelAnimation {
                            PropertyAnimation {
                                target: pastCircle
                                property: "opacity"
                                to: pastCircle.circleOpacity
                                easing.type: Easing.OutCurve
                                duration: circleChangeAnimTimer.interval * d.circleModifier
                            }
                            PropertyAnimation {
                                target: pastCircle
                                property: "circleScale"
                                to: modelData
                                easing.type: Easing.OutCurve
                                duration: circleChangeAnimTimer.interval * d.circleModifier
                            }
                            ColorAnimation {
                                target: pastCircle
                                property: "color"
                                to: Gradient.threeColorByIndex(index, count, whiteTheme)
                                easing.type: Easing.OutCurve
                                duration: circleChangeAnimTimer.interval * d.circleModifier
                            }
                        }
                    }
                }
            }
        }
        // ENH064 - Dynamic Cove
        ListModel {
            id: discoModeModel
            
            signal dataAboutToChange
            signal dataChanged

            function randomNumber(min, max) {
                return Math.random() * (max - min) + min;
            }
            
            function generateRandomNumber(min, max) {
                    return Math.random() * (max - min) + min;
            }

            
            function refillData() {
                dataAboutToChange()
                clear()
                let maxItems = randomNumber(5, 20)
                
                for (let step = 0; step < maxItems; step++) {
                    let randomnum = generateRandomNumber(0, 1)
                    append({"modelData": randomnum})
                }
                dataChanged()
            }

            Component.onCompleted: {
                refillData()
            }

            onDataAboutToChange: infographic.startHideAnimation()
            onDataChanged: infographic.startShowAnimation()
        }

        Timer {
            id: discoTimer

            running: dynamicCove.isCDPlayer && dynamicCove.item && dynamicCove.item.visible
                            && dynamicCove.item.spinAnimation.running && !dynamicCove.item.spinAnimation.paused
            repeat: true
            interval: 5000
            triggeredOnStart: true
            onTriggered: {
                discoModeModel.refillData()
            }
        }
        Connections {
            target: presentCircles
            onModelChanged: {
                if (presentCircles.model == discoModeModel) {
                    discoTimer.restart()
                } else {
                    discoTimer.stop()
                }
            }
        }
        // ENH064 - End
        Repeater {
            id: presentCircles
            objectName: "presentCircles"
            // ENH064 - Dynamic Cove
            // model: infographic.model.firstMonth
            model: dynamicCove.isCDPlayer && shell.settings.enableCDPlayerDisco ? discoModeModel : infographic.model.firstMonth
            // ENH064 - End

            delegate: ObjectPositioner {
                property alias presentCircleChangeAnim: presentCircleChangeAnim

                index: model.index
                count: presentCircles.count
                radius: dataCircle.width / 2
                halfSize: presentCircle.width / 2
                posOffset: 0.0

                Circle {
                    id: presentCircle
                    objectName: "presentCircle" + index

                    property real divisor: 1.8
                    property real circleOpacity: 0.3

                    width: dataCircle.width / divisor
                    height: dataCircle.height / divisor
                    opacity: 0.0
                    circleScale: 0.0
                    visible: modelData !== undefined
                    color: "transparent"
                    centerCircle: dataCircle

                    SequentialAnimation {
                        id: presentCircleChangeAnim

                        loops: 1

                        ParallelAnimation {
                            PropertyAnimation {
                                target: presentCircle
                                property: "opacity"
                                to: presentCircle.circleOpacity
                                easing.type: Easing.OutCurve
                                duration: circleChangeAnimTimer.interval * d.circleModifier
                            }
                            PropertyAnimation {
                                target: presentCircle
                                property: "circleScale"
                                to: modelData
                                easing.type: Easing.OutCurve
                                duration: circleChangeAnimTimer.interval * d.circleModifier
                            }
                            ColorAnimation {
                                target: presentCircle
                                property: "color"
                                // ENH064 - Dynamic Cove
                                // to: Gradient.threeColorByIndex(index, infographic.model.currentDay, whiteTheme)
                                to: dynamicCove.isCDPlayer && shell.settings.enableCDPlayerDisco ? '#'+(0x1000000+Math.random()*0xffffff).toString(16).substr(1,6) // Random color
                                            : Gradient.threeColorByIndex(index, infographic.model.currentDay, whiteTheme)
                                // ENH064 - End
                                easing.type: Easing.OutCurve
                                duration: circleChangeAnimTimer.interval * d.circleModifier
                            }
                        }
                    }
                }
            }
        }

        Timer {
            id: dotShowAnimTimer

            property int dotCounter: 0

            interval: animDuration * 0.5; running: false; repeat: true
            onTriggered: {
                if (dotCounter < dots.count) {
                    var nextDot = dots.itemAt(dotCounter);
                    if (nextDot) {
                        nextDot.unlockAnimation.start();
                        if (++dotCounter == Math.round(dots.count / 2)) {
                            circleChangeAnimTimer.startFromBeginning();
                        }
                    }
                } else {
                    stop()
                }
            }

            function startFromBeginning() {
                if (!dotShowAnimTimer.running)
                    dotCounter = 0

                start()
            }
        }

        Timer {
            id: dotHideAnimTimer

            property int dotCounter

            interval: animDuration * 0.5
            running: false
            repeat: true
            onTriggered: {
                if (dotCounter >= 0) {
                    var nextDot = dots.itemAt(dotCounter--)
                    nextDot.changeAnimation.start()
                } else {
                    stop()
                }
                if (dotCounter == 0) {
                    infographic.model.readyForDataChange()
                }
            }

            function startFromBeginning() {
                if (!dotHideAnimTimer.running)
                    dotCounter = dots.count - 1

                start()
            }
        }

        Repeater {
            id: dots
            objectName: "dots"
            // ENH064 - Dynamic Cove
            // model: infographic.model.firstMonth
            model: !dynamicCove.isClock && !dynamicCove.isTimer ? infographic.model.firstMonth : 12
            onModelChanged: {
                infographics.startHideAnimation()
                infographics.startShowAnimation()
            }
            // ENH064 - End

            delegate: ObjectPositioner {
                property alias unlockAnimation: dotUnlockAnim
                property alias changeAnimation: dotChangeAnim
                // ENH064 - Dynamic Cove
                // property int currentDay: infographic.model.currentDay
                property int currentDay: dynamicCove.isClock ? dynamicCove.item && dynamicCove.item.currentHour ? dynamicCove.item.currentHour : 0
                                                             : dynamicCove.isTimer ? 0 : infographic.model.currentDay
                // ENH064 - End

                index: model.index
                count: dots.count
                radius: dataCircle.width / 2
                halfSize: dot.width / 2
                posOffset: radius / dot.width / 3
                state: dot.state

                Dot {
                    id: dot
                    objectName: "dot" + index

                    property real baseOpacity: 1

                    width: units.dp(5) * parent.radius / 200
                    height: units.dp(5) * parent.radius / 200
                    opacity: 0.0
                    smooth: true
                    state: index < currentDay ? "filled" : index == currentDay ? "pointer" : "unfilled"

                    PropertyAnimation {
                        id: dotUnlockAnim

                        target: dot
                        property: "opacity"
                        to: dot.baseOpacity
                        duration: dotShowAnimTimer.interval
                    }

                    PropertyAnimation {
                        id: dotChangeAnim

                        target: dot
                        property: "opacity"
                        to: 0.0
                        duration: dotHideAnimTimer.interval
                    }
                }
            }
        }

        Label {
            id: notification
            objectName: "label"

            property alias hideAnim: decreaseOpacity
            property alias showAnim: increaseOpacity

            property real baseOpacity: 1
            property real duration: dotShowAnimTimer.interval * 5

            height: 0.7 * dataCircle.width
            width: notification.height
            anchors.centerIn: parent

            text: infographic.model.label

            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: "white"
            // ENH064 - Dynamic Cove
            visible: dynamicCove.isInfographic || !shell.settings.enableDynamicCove
            // ENH064 - End

            PropertyAnimation {
                id: increaseOpacity

                target: notification
                property: "opacity"
                from: 0.0
                to: notification.baseOpacity
                duration: notification.duration * dots.count
            }

            PropertyAnimation {
                id: decreaseOpacity

                target: notification
                property: "opacity"
                from: notification.baseOpacity
                to: 0.0
                duration: notification.duration * dots.count
                onStopped: if (!d.useDotAnimation) infographic.model.readyForDataChange()
            }
        }
    }
    // ENH064 - Dynamic Cove
    /*
    MouseArea {
        anchors.fill: dataCircle
        enabled: notification.text != ""

        onDoubleClicked: {
            if (!d.animating) {
                reloadUserData()
            }
        }
    }
    */

    LPCircularMenu {
        id: circleMenu

        anchors {
            fill: dataCircle
            margins: units.gu(-3)
        }
        model: dynamicCove.model
        mouseArea: circularMenuMouseArea
        enabled: dataCircle.visible && shell.settings.enableDynamicCove
        onSelected: shell.settings.dynamicCoveCurrentItem = selectedIndex
        currentSelectedIndex: shell.settings.dynamicCoveCurrentItem
    }

    LPRoundMouseArea {
        id: circleMouseArea

        anchors.centerIn: dataCircle
        height: 0.7 * dataCircle.width
        width: height
        propagateComposedEvents: true
        hoverEnabled: true

//~         Rectangle {
//~             color: "red"
//~             radius: width / 2
//~             anchors.fill: parent
//~             opacity: 0.5
//~         }

        enabled: dataCircle.visible && ((!dynamicCove.item && notification.text != "") || (dynamicCove.item && dynamicCove.item.enableMouseArea))
        function reloadUSerDataDots() {
            if (!d.animating) {
                reloadUserData()
                // ENH061 - Add haptics
                shell.haptics.playSubtle()
                // ENH061 - End
            }
        }
        onClicked: {
            if (dynamicCove.isInfographic) {
                reloadUSerDataDots()
            }
        }
        onDoubleClicked: {
            if (!dynamicCove.item) {
                reloadUSerDataDots()
            }
        }
    }
    
    LPRoundMouseArea {
        id: secondMouseArea

        enabled: dataCircle.visible && dynamicCove.item && dynamicCove.item.secondaryMouseArea == this
        propagateComposedEvents: true
        anchors.centerIn: dataCircle
        width: dynamicCove.item && dynamicCove.item.secondaryMouseAreaWidth > 0 ? dynamicCove.item.secondaryMouseAreaWidth
                                                                               : dataCircle.width / 2
        height: width
    }

    SwipeArea {
        id: nextPrevSwipe

        // draggingCustom is used for implementing trigger delay
        readonly property real threshold: shell.convertFromInch(0.5) // Old: units.gu(5)
        readonly property bool goingPositive: distance > 0
        readonly property bool goingNegative: distance < 0
        property bool draggingCustom: Math.abs(distance) >=  threshold

        signal triggered

        anchors.centerIn: circleMouseArea
        direction: dynamicCove.item ? dynamicCove.item.swipeAreaDirection : SwipeArea.Vertical
        width: dynamicCove.item && dynamicCove.item.swipeAreaWidth > 0 ? dynamicCove.item.swipeAreaWidth
                                                                               : dataCircle.width
        height: width
        enabled: dataCircle.visible && dynamicCove.item && dynamicCove.item.swipeArea == this && dynamicCove.item.enableSwipeArea && !circleMenu.mouseArea.pressed

        onDraggingChanged: {
            if (!dragging && draggingCustom) {
                triggered()
            }
        }

        onDraggingCustomChanged: {
            if (draggingCustom) {
                shell.haptics.play()
            } else {
                shell.haptics.playSubtle()
            }
        }
    }
    // ENH064 - End
}
