// Based and From https://gitlab.com/Danfro/timer
// ENH064 - Dynamic Cove
import QtQuick 2.9
import Ubuntu.Components 1.3
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
    enabled: root_timesetter.isInteractive

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
    
    onTimeFinishedChanged: {
        if (timeFinished) {
            internal.clearTimers()
            running = false
            shell.settings.dcRunningTimer = 0
        }
    }

    Connections {
        target: swipeArea
        onTriggered: {
            if (target.goingNegative) {
                root_timesetter.reset()
            } else if (target.goingPositive) {
                timer.running = !timer.running
                if (timer.running) {
                    root_timesetter.start()
                } else {
                    root_timesetter.stop()
                }
            }
            shell.haptics.play()
        }
    }

    Connections {
        target: secondaryMouseArea
        onClicked: {
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
        onPressed: {
            focus = true
        }
        onPositionChanged: {
            if (!swipeArea.dragging && timer.enabled) {
                let newValue
                let steps = 60
                
                if (timer.editMode == LPTimer.EditMode.Hour) {
                    steps = 24
                }

                if (internal.angle < 0){
                    newValue = (internal.strictangle - internal.modulo + 360) / internal.moduloVariable
                    if (newValue == steps) { newValue = 0 }
                }
                else {
                    newValue = (internal.strictangle - internal.modulo + internal.moduloVariable) / internal.moduloVariable
                    if (newValue == steps){ newValue = 0 }
                }
                
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
        Behavior on opacity { UbuntuNumberAnimation { duration: UbuntuAnimation.SlowDuration } }

        Connections {
            target: timer
            onAboutToSwipeActionChanged: {
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
            interval: UbuntuAnimation.SlowDuration
            onTriggered: {
                actionLabel.text = actionLabel.nextText
                actionLabel.color = actionLabel.nextColor
            }
        }
    }
    
    LPClockCircle {
        isFoldVisible: true
        
        anchors.centerIn: parent
        width: units.gu(5)
        height: width
        opacity: timer.aboutToSwipeAction ? 0 : 1

        Behavior on opacity { UbuntuNumberAnimation { duration: UbuntuAnimation.SlowDuration } }
        Behavior on width { UbuntuNumberAnimation { duration: UbuntuAnimation.SlowDuration } }
         
        Component.onCompleted: {
            width = parent.width

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
            Behavior on opacity { UbuntuNumberAnimation { duration: UbuntuAnimation.SlowDuration } }
            
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
                Behavior on scale { UbuntuNumberAnimation { duration: UbuntuAnimation.SlowDuration } }

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
                    Behavior on color { ColorAnimation { duration: UbuntuAnimation.FastDuration } }
                }

                ColumnLayout {
                    spacing: 0
                    anchors.centerIn: parent

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "》"
                        rotation: -90
                        color: theme.palette.normal.negative
                        horizontalAlignment: Label.AlignHCenter
                        opacity: root_timesetter.canReset ? 1 : 0
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
                        text: "《"
                        rotation: -90
                        horizontalAlignment: Label.AlignHCenter
                        color: timer.running ? theme.palette.normal.negative : theme.palette.normal.positive
                        opacity: root_timesetter.canStart ? 1 : 0
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
        property real truex: mouseArea.mouseX - timer.width / 2
        property real truey: timer.height / 2 - mouseArea.mouseY
        property real angle: Math.atan2(truex, truey)
        property real strictangle: Number(angle * 180 / Math.PI)
        property real moduloVariable: timer.editMode == internal.maxEditMode ? 15 : 6
        property real modulo: strictangle % moduloVariable

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
