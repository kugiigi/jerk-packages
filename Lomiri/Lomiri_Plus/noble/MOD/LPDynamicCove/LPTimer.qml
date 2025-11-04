// Based and From https://gitlab.com/Danfro/timer
// ENH064 - Dynamic Cove
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import "Timer"
import "Clock"

LPDynamicCoveItem {
    id: timer

    property bool running: false
    property bool timeFinished: false
    property bool aboutToSwipeAction: swipeArea.dragging && swipeArea.draggingCustom
    property var alarm: shell.alarmItem
    property var alarmModel: shell.alarmItemModel

    enum EditMode {
        Minute,
        Second,
        Hour
    }

    property int editMode: LPTimer.EditMode.Minute

    enableSwipeArea: root_timesetter.canStart || root_timesetter.canReset
    enableMouseArea: !resetHoverHandler.hovered && !startHoverHandler.hovered && root_timesetter.isInteractive
    enableSecondaryMouseArea: !resetHoverHandler.hovered && !startHoverHandler.hovered

    secondaryMouseAreaWidth: centerButton.width
    swipeAreaWidth: centerButton.width
    
    function remainingTime() {
        var start = Date.now()
        var end = new Date(root_timesetter.endTime)
        var remain = end - start

        if (remain >= 0){
            root_timesetter.timelength = remain
            timeFinished = false
        }

        else {
            timeFinished = true
        }
    }

    function tryToStart() {
        timer.running = !timer.running
        if (timer.running) {
            root_timesetter.start()
        } else {
            root_timesetter.stop()
        }
    }

    function changePosition() {
        if (!swipeArea.dragging && timer.enabled) {
            const _centerX = mouseArea.width / 2;
            const _centerY = mouseArea.height / 2;
            const _angle = Math.atan2(mouseArea.mouseY - _centerY, mouseArea.mouseX - _centerX)
            let _strictangle = _angle  * (180 / Math.PI);
            const _moduloVariable = timer.editMode == internal.maxEditMode ? 15 : 6
            const _modulo = _strictangle % _moduloVariable

            let newValue
            let steps = 60
            
            if (timer.editMode == LPTimer.EditMode.Hour) {
                steps = 24
            }

            _strictangle = (_strictangle + 90) % 360
            if (_strictangle < 0) _strictangle += 360
            newValue = (_strictangle - _modulo + _moduloVariable) / _moduloVariable
            if (newValue == steps){ newValue = 0 }
            
            switch (timer.editMode) {
                case LPTimer.EditMode.Second:
                    root_timesetter.s = newValue
                    break
                case LPTimer.EditMode.Minute:
                    root_timesetter.m = newValue
                    break
                case LPTimer.EditMode.Hour:
                    root_timesetter.h = newValue
                    break
            }
        }
    }
    
    onTimeFinishedChanged: {
        if (timeFinished) {
            internal.clearTimers()
            running = false
            shell.settings.dcRunningTimer = 0
        }
    }

    Connections {
        target: swipeArea
        function onTriggered() {
            if (target.goingNegative) {
                root_timesetter.reset()
            } else if (target.goingPositive) {
                timer.tryToStart()
            }
            shell.haptics.play()
        }
    }

    Connections {
        target: secondaryMouseArea
        function onClicked(mouse) {
            if (timer.enabled && !timer.running) {
                if (timer.editMode == internal.maxEditMode) {
                    timer.editMode = LPTimer.EditMode.Minute
                } else {
                    timer.editMode += 1
                }

                shell.haptics.play()
            }
        }
    }

    Connections {
        target: mouseArea
        function onPressed(mouse) { focus = true }
        function onClicked(mouse) { timer.changePosition() }
        function onPositionChanged(mouse) { timer.changePosition() }
    }
    
    Timer {
        id: refreshTimer

        interval: 100
        repeat: true
        running: timer.running

        onTriggered: timer.remainingTime()
    }

    
    Label {
        id: actionLabel

        readonly property string nextText: swipeArea.goingNegative ? "Reset Timer" : timer.running ? "Stop Timer" : "Start Timer"
        readonly property string nextColor: swipeArea.goingNegative ? theme.palette.normal.negative
                                                    : timer.running ? theme.palette.normal.negative : theme.palette.normal.positive
        anchors.centerIn: parent
        textSize: Label.Medium
        opacity: timer.aboutToSwipeAction ? 1 : 0
        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration } }

        Connections {
            target: timer
            function onAboutToSwipeActionChanged() {
                if (target.aboutToSwipeAction) {
                    actionLabel.text = actionLabel.nextText
                    actionLabel.color = actionLabel.nextColor
                } else {
                    delayDataChange.restart()
                }
            }
        }

        Timer {
            id: delayDataChange

            running: false
            interval: LomiriAnimation.SlowDuration
            onTriggered: {
                actionLabel.text = actionLabel.nextText
                actionLabel.color = actionLabel.nextColor
            }
        }
    }
    
    LPClockCircle {
        id: clockCircle

        isFoldVisible: true
        
        anchors.centerIn: parent
        width: units.gu(5)
        height: width
        opacity: timer.aboutToSwipeAction ? 0 : 1

        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration } }
         
        Component.onCompleted: {
            delayOpenAnimation.restart()
            

            if (shell.settings.dcRunningTimer > 0 && shell.settings.dcRunningTimer > Date.now()) {
                root_timesetter.targettime = shell.settings.dcRunningTimer
                root_timesetter.bindHands()
                root_timesetter.endTime = internal.tempEndTime(root_timesetter.h, root_timesetter.m, root_timesetter.s)
                timer.running = true
                timer.timeFinished = false
            } else {
                shell.settings.dcRunningTimer = 0
                if (shell.settings.dcLastTimeTimer > 0) {
                    root_timesetter.timelength = shell.settings.dcLastTimeTimer
                }
            }
        }

        Component.onDestruction: {
            if (timer.running) {
                if (root_timesetter.targettime > 0) {
                    shell.settings.dcRunningTimer = root_timesetter.targettime
                }
            } else {
                shell.settings.dcLastTimeTimer = root_timesetter.timerduration
            }
        }

        // WORKAROUND: Delay to avoid the issue where the animation
        // doesn't seem to execute upong locking the device
        Timer {
            id: delayOpenAnimation

            running: false
            interval: 1
            onTriggered: openAnimation.start()
        }

        LomiriNumberAnimation {
            id: openAnimation

            target: clockCircle
            property: "width"
            to: clockCircle.parent.width
            duration: LomiriAnimation.SlowDuration
        }

        Item {
            id: root_timesetter

            readonly property bool canStart: h > 0 || m > 0 || s > 0
            readonly property bool canReset: h > 0 || m > 0 || s > 0
            property int timelength
            property int h: Math.floor(timelength/1000/60/60)
            property int m: Math.floor(timelength/1000/60)
            property int s: Math.floor(timelength/1000)
            property real targettime: 0
            property real endTime: 0
            property int timerduration: h * 60 * 60 * 1000 + (m >= 60 ? (m % 60) : m) * 60 * 1000 + (s >= 60 ? (s % 60) : s) * 1000
            property bool isInteractive: !timer.running
            property alias hour_hand: timerhandhour
            property string current_clock_theme: "Imitatio" // Imitatio, Standard, Colores

            signal secReleased
            signal minReleased
            signal houReleased
            
            anchors {
                fill: parent
            }
            opacity: parent.width == parent.parent.width ? 1 : 0
            Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration } }
            
            // Make the mousearea a circle
            function contains(x, y, area) {
                var d = (area.width / 2);
                var dx = (x - area.width / 2);
                var dy = (y - area.height / 2);
                return (d * d > dx * dx + dy * dy);
            }

            function bindHands() {
                timelength = Qt.binding( function() { return targettime - Date.now() } )
                h = Qt.binding( function() { return Math.floor(timelength/1000/60/60) } )
                m = Qt.binding( function() { let result = Math.floor(timelength/1000/60); return result >= 60 ? result % 60 : result } )
                s = Qt.binding( function() { let result = Math.floor(timelength/1000); return result >= 60 ? result % 60 : result } )
            }
            
            function start() {
                console.log("Timer started")
                shell.settings.dcLastTimeTimer = root_timesetter.timerduration

                endTime = internal.tempEndTime(root_timesetter.h, root_timesetter.m, root_timesetter.s)
                let targetdt = new Date((new Date()).setTime(endTime))

                targettime = targetdt.getTime()
                timer.alarm.reset()
                timer.alarm.sound = timer.alarm.defaultSound
                timer.alarm.message = timer.alarm.defaultId
                timer.alarm.date = targetdt
                timer.alarm.save()

                if (timer.alarm.error != Alarm.NoError) {
                    console.log("error saving: " + timer.alarm.error)
                } else {
                    bindHands()
                    console.log("Alarm successfully started")
                }
            }
            
            function stop() {
                console.log("Timer stopped")
                internal.clearTimers()
                shell.settings.dcRunningTimer = 0
                root_timesetter.timelength = shell.settings.dcLastTimeTimer
            }

            function reset() {
                timelength = 0
                h = 0
                m = 0
                s = 0
                if (timer.running) {
                    timer.running = false
                    stop()
                }
            }
            
            onHChanged: {
                if (isInteractive) {
                    shell.haptics.playSubtle()
                }
            }
            onMChanged: {
                if (isInteractive) {
                    shell.haptics.playSubtle()
                }
            }
            onSChanged: {
                if (isInteractive) {
                    shell.haptics.playSubtle()
                }
            }

            /* =================== Analog Timer Background Image ======================*/
            Image {
                id: timerback

                source: Qt.resolvedUrl("Timer/images/" + root_timesetter.current_clock_theme + "/secback.svg")
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                anchors.fill: parent
                scale: timer.running && !timer.timeFinished ? 1.2 : 1
                Behavior on scale { LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration } }

                /* =================== Analog Timer Second Hand ======================*/
                Image {
                    id: timerhandsec

                    source: Qt.resolvedUrl("Timer/images/" + root_timesetter.current_clock_theme + "/sechand.svg")
                    asynchronous: true
                    sourceSize.height: units.gu(70)
                    rotation: root_timesetter.s * 6
                    height: timerback.height
                    fillMode: Image.PreserveAspectFit
                    anchors.centerIn: parent
                }

                /* =================== Analog Timer Minute Background ======================*/
                Item {
                    id: minutesback

                    width: timerhandmin.height
                    height: width
                    anchors.centerIn: parent

                    /* =================== Analog Timer Minute Hand ======================*/
                    Image {
                        id: timerhandmin

                        source: Qt.resolvedUrl("Timer/images/" + root_timesetter.current_clock_theme + "/minhand.svg")
                        sourceSize.height: units.gu(60)
                        asynchronous: true
                        width: timerhandsec.width
                        fillMode: Image.PreserveAspectFit
                        rotation: root_timesetter.m * 6
                        anchors.centerIn: parent
                    }

                    /* =================== Analog Timer Hour Backgroud ======================*/
                    Image {
                        id: hourhandbackground

                        source: Qt.resolvedUrl("Timer/images/" + root_timesetter.current_clock_theme + "/hourback.svg")
                        asynchronous: true
                        sourceSize.width: units.gu(40)
                        width: timerback.width/2
                        fillMode: Image.PreserveAspectFit
                        anchors.centerIn: parent

                        /* =================== Analog Timer Hour Hand ======================*/
                        Image {
                            id: timerhandhour

                            source: Qt.resolvedUrl("Timer/images/" + root_timesetter.current_clock_theme + "/hourhand.svg")
                            asynchronous: true
                            sourceSize.height: units.gu(40)
                            width: timerhandsec.width
                            fillMode: Image.PreserveAspectFit
                            rotation: root_timesetter.h * 15
                            anchors.centerIn: parent
                        }
                    }
                }
            }
            
            RowLayout {
                id: timerLabel
                
                readonly property int highlightedItem: !timer.running ? timer.editMode
                                                                      : -1

                anchors {
                    centerIn: parent
                    verticalCenterOffset: centerButton.height
                }
                Label {
                    textSize: Label.Large
                    text: internal.unitsdisplay(root_timesetter.h)
                    color: timerLabel.highlightedItem == LPTimer.EditMode.Hour ? theme.palette.normal.activity : theme.palette.normal.foregroundText
                }
                Label {
                    textSize: Label.Large
                    text: ":"
                    color: theme.palette.normal.foregroundText
                }
                Label {
                    textSize: Label.Large
                    text: internal.unitsdisplay(root_timesetter.m)
                    color: timerLabel.highlightedItem == LPTimer.EditMode.Minute ? theme.palette.normal.activity : theme.palette.normal.foregroundText
                }
                Label {
                    textSize: Label.Large
                    text: ":"
                    color: theme.palette.normal.foregroundText
                }
                Label {
                    textSize: Label.Large
                    text: internal.unitsdisplay(root_timesetter.s)
                    color: timerLabel.highlightedItem == LPTimer.EditMode.Second ? theme.palette.normal.activity : theme.palette.normal.foregroundText
                }
            }

            Item {
                id: centerButton

                anchors.centerIn: parent
                width: units.gu(7)
                height: width

                Rectangle {
                    id: centerbg

                    readonly property color normalColor: theme.palette.normal.foreground
                    anchors.fill: parent
                    color: timer.secondaryMouseArea.nakapindot
                                    || timer.secondaryMouseArea.hovered ? normalColor.hslLightness > 0.1 ? Qt.darker(normalColor, 1.2)
                                                                                                         : Qt.lighter(normalColor, 2.0)
                                                                        : normalColor
                    radius: width / 2
                    opacity: 0.8
                    Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
                }

                ColumnLayout {
                    spacing: 0
                    anchors.centerIn: parent

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: contentHeight
                        Layout.preferredHeight: contentHeight
                        text: "》"
                        rotation: resetIcon.visible ? 0 : -90
                        color: theme.palette.normal.negative
                        horizontalAlignment: Label.AlignHCenter
                        opacity: root_timesetter.canReset ? 1 : 0
                        
                        Rectangle {
                            id: resetIcon

                            anchors.centerIn: parent
                            width: parent.width
                            height: width
                            radius: width / 2
                            color: theme.palette.normal.negative
                            opacity: resetHoverHandler.hovered ? 1 : 0
                            visible: opacity > 0
                            Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }

                            Icon {
                                anchors.centerIn: parent

                                width: parent.width * 0.7
                                name: resetHoverHandler.hovered ? "reset" : ""
                                color: theme.palette.normal.negativeText
                            }
                        }

                        TapHandler {
                            id: resetTapHandler
                            acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Cursor | PointerDevice.Pen
                            //cursorShape: Qt.PointingHandCursor // Needs Qt5.15
                            onSingleTapped: root_timesetter.reset()
                        }

                        HoverHandler {
                            id: resetHoverHandler
                            acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Cursor | PointerDevice.Pen
                        }
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        opacity: !timer.running ? 1 : 0
                        color: theme.palette.normal.activity
                        horizontalAlignment: Label.AlignHCenter
                        text: {
                            switch (timer.editMode) {
                                case LPTimer.EditMode.Second:
                                    return "S"
                                case LPTimer.EditMode.Minute:
                                    return "M"
                                case LPTimer.EditMode.Hour:
                                    return "H"
                            }
                        }
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: contentHeight
                        Layout.preferredHeight: contentHeight
                        text: "《"
                        rotation: startIcon.visible ? 0 : -90
                        horizontalAlignment: Label.AlignHCenter
                        color: timer.running ? theme.palette.normal.negative : theme.palette.normal.positive
                        opacity: root_timesetter.canStart ? 1 : 0

                        Rectangle {
                            id: startIcon

                            anchors.centerIn: parent
                            width: parent.width
                            height: width
                            radius: width / 2
                            color: timer.running ? theme.palette.normal.negative : theme.palette.normal.positive
                            opacity: startHoverHandler.hovered ? 1 : 0
                            visible: opacity > 0
                            Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }

                            Icon {
                                anchors.centerIn: parent

                                width: parent.width * 0.7
                                name: startHoverHandler.hovered ? timer.running ? "stop" : "media-preview-start" : ""
                                color: timer.running ? theme.palette.normal.negativeText : theme.palette.normal.positiveText
                            }
                        }

                        TapHandler {
                            id: startTapHandler
                            acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Cursor | PointerDevice.Pen
                            //cursorShape: Qt.PointingHandCursor // Needs Qt5.15
                            onSingleTapped: timer.tryToStart()
                        }

                        HoverHandler {
                            id: startHoverHandler
                            acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Cursor | PointerDevice.Pen
                        }
                    }
                }
            }
        }
    }

    QtObject {
        id: internal
        
        readonly property int maxEditMode: 2
        readonly property real currentItemWidth: {
            switch (timer.editMode) {
                case LPTimer.EditMode.Second:
                    return timerhandsec.width
                case LPTimer.EditMode.Minute:
                    return timerhandmin.width
                case LPTimer.EditMode.Hour:
                    return timerhandhour.width
            }
        }
        readonly property real currentItemHeight: {
            switch (timer.editMode) {
                case LPTimer.EditMode.Second:
                    return timerhandsec.height
                case LPTimer.EditMode.Minute:
                    return timerhandmin.height
                case LPTimer.EditMode.Hour:
                    return timerhandhour.height
            }
        }

        function addZeroPrefix(str, totalLength) {
            let result = ("00000" + str)
            return result.replace(result.substring(0, 5 + str.length - totalLength), "");
        }

        function tempEndTime(h, m, s) {
            var startTime = Date.now()
            var timeDiff = h * 60 * 60 * 1000 + (m >= 60 ? (m % 60) : m) * 60 * 1000 + (s >= 60 ? (s % 60) : s) * 1000
            var endTime = startTime + timeDiff

            return endTime
        }
        
        function escapeRegExp(stringToGoIntoTheRegex) {
            return stringToGoIntoTheRegex.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
        }

        function unitsdisplay(units) {
            if (units > 59){
                units = (units % 60) - 60
            }
            if (units < 0){
                units = (units % 60) + 60
            }
            if (units === 60){
                units = 0
            }

            return ("0"+units).slice(-2)
        }

        function clearTimers() {
            var modelCount = alarmModel.count
            for (var i = modelCount - 1; i > -1; i--) {
                var alarm = timer.alarmModel.get(i)
                var alarmName = alarm.message

                let regex = new RegExp("^" + internal.escapeRegExp(timer.alarm.defaultId), "g")
                
                if (regex.test(alarmName)) {
                    alarm.cancel()
                    console.log("Deleted: " + alarmName)
                }
            }
        }
    }
}
