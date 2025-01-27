// ENH203 - I’m awake
import QtQuick 2.12
import Lomiri.Components 1.3
import Powerd 0.1

Item {
    id: root

    readonly property bool noDisabledAlarms: shell.settings.listOfDisabledWakeAlarms.length === 0
    property bool isAwake: true
    property var alarmModel: shell.alarmItemModel
    property string alarmPrefix: "[WAKEUP]"

    function disableAlarms() {
        console.log("Wake up alarms disabled")
        const _modelCount = alarmModel.count
        let _arr = []
        let _latestDate = new Date(0)

        for (let i = _modelCount - 1; i > -1; i--) {
            const _alarm = alarmModel.get(i)
            const _alarmName = _alarm.message
            const _alarmDate = _alarm.date
            const _alarmEnabled = _alarm.enabled

            const _regex = new RegExp("^" + escapeRegExp(alarmPrefix), "g")
            const _now = new Date();

            // Disable all remaining wake up alarms for today
            if (_regex.test(_alarmName) && _alarmEnabled && isToday(_alarmDate)
                    && _alarmDate > _now) {
                _alarm.enabled = false
                _alarm.save()
                _arr.push(_alarmName)

                if (_latestDate.getTime() > 0) {
                    if (_alarmDate > _latestDate) {
                        _latestDate = _alarmDate
                    }
                } else {
                    _latestDate = _alarmDate
                }
            }
        }

        const _latestEpoch = _latestDate.getTime()
        shell.settings.earliestWakeUpAlarm = 0
        shell.settings.latestWakeUpAlarm = _latestEpoch

        shell.settings.listOfDisabledWakeAlarms = _arr.slice()
    }

    function reenableAlarms() {
        console.log("Wake up alarms reenabled")
        const _modelCount = alarmModel.count
        for (let i = _modelCount - 1; i > -1; i--) {
            const _alarm = alarmModel.get(i)
            const _alarmName = _alarm.message
            const _alarmType = _alarm.type
            const _alarmEnabled = _alarm.enabled

            const _regex = new RegExp("^" + escapeRegExp(alarmPrefix), "g")

            // Reenable all the wake up alarms we disabled
            if (_regex.test(_alarmName) && !_alarmEnabled && shell.settings.listOfDisabledWakeAlarms.includes(_alarmName)) {
                /***** THE FOLLOWING CODES ARE FROM THE CLOCK APP ******/
                // HACK : This a temporary fix for the issues of https://gitlab.com/ubports/development/apps/lomiri-clock-app/issues/129 (so people will stop waking up at 4:00AM, that too damn early...)
                const _today = new Date();
                const _date = new Date(_alarm.date.getTime() + (_alarm.date.getTime() % 60 ? -1000 : 1000));
                _date.setFullYear(_today.getFullYear(), _today.getMonth(), _today.getDate());
                /*
                 Calculate the alarm time if it is a one-time alarm.
                 Repeating alarms do this automatically.
                */
                if(_alarmType === Alarm.OneTime) {
                    // TODO : this  was commented out to support an HACK that *temporarly* fix the issue of : https://gitlab.com/ubports/development/apps/lomiri-clock-app/issues/129
                    //var date = new Date()
                    //date.setHours(model.date.getHours(), model.date.getMinutes(), 0)

                    _alarm.daysOfWeek = Alarm.AutoDetect
                    if (_date < new Date()) {
                        const _tomorrow = new Date();
                        _tomorrow.setDate(_today.getDate() + 1);
                        _alarm.daysOfWeek = get_alarm_day(_tomorrow.getDay());
                    }
                    // TODO : this  was commented out to support an HACK that *temporarly* fix the issue of : https://gitlab.com/ubports/development/apps/lomiri-clock-app/issues/129
                    // model.date = date

                }
                // HACK part  of the issue 129 hack date should not normally be updated when enabling the alarm
                _alarm.date = _date

                _alarm.enabled = true
                _alarm.save()
            }
        }

        shell.settings.listOfDisabledWakeAlarms = []
    }

    function getEarliestAlarmToday() {
        const _modelCount = alarmModel.count
        let _earliestDate = new Date(0)

        for (let i = _modelCount - 1; i > -1; i--) {
            const _alarm = alarmModel.get(i)
            const _alarmName = _alarm.message
            const _alarmDate = _alarm.date
            const _alarmEnabled = _alarm.enabled

            const _regex = new RegExp("^" + escapeRegExp(alarmPrefix), "g")

            if (_regex.test(_alarmName) && _alarmEnabled && isToday(_alarmDate) ) {
                if (_earliestDate.getTime() > 0) {
                    if (_alarmDate < _earliestDate) {
                        _earliestDate = _alarmDate
                    }
                } else {
                    _earliestDate = _alarmDate
                }
            }
        }

        const _earliestEpoch = _earliestDate.getTime()
        shell.settings.earliestWakeUpAlarm = _earliestEpoch
    }

    Timer {
        id: getEarliestDelayTimer
        interval: 1000
        onTriggered: {
            root.getEarliestAlarmToday()
        }
    }

    function checkIfDayChanged() {
        if (!isToday(new Date(shell.settings.currentDateForAlarms))) {
            shell.settings.currentDateForAlarms = new Date().getTime()
            getEarliestAlarmToday()
            // Delay it just to make sure the date is actually changed
            getEarliestDelayTimer.restart()

            return true
        }

        return false
    }

    // Prompt the awake button once we are within 1 hour from earliest alarm
    function checkIfNearEarliestAlarm() {
        if (root.isAwake) {
            const _dayHasChanged = checkIfDayChanged() // Execute this since earliest data is set here
            const _today = new Date();
            const _earliestDate = new Date(shell.settings.earliestWakeUpAlarm)
            const _hourFromNow = addMilliseconds(addHours(_today, 1), 1000)

            if (_hourFromNow >= _earliestDate && shell.settings.earliestWakeUpAlarm > 0) {
                isAwake = false
            }
        }
    }

    // Reenable alarms once we are past the latest alarms
    function checkIfPastLatestAlarm() {
        if (shell.settings.latestWakeUpAlarm > 0 && !root.noDisabledAlarms) {
            const _now = new Date();
            const _latestAlarm = new Date(shell.settings.latestWakeUpAlarm)
            const _hourFromLastAlarm = addHours(_latestAlarm, 1)

            // Only renable an hour after the last alarm
            if (_now >= _hourFromLastAlarm) {
                reenableAlarms()
            }
        }
    }

    function escapeRegExp(_stringToGoIntoTheRegex) {
        return _stringToGoIntoTheRegex.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
    }

    function isToday(_date) {
        const _today = new Date();

        if (_today.toDateString() === _date.toDateString()) {
            return true;
        }

        return false;
    }
    
    function addDays(_date, _days) {
        let _newDate = new Date(_date.getTime())
        const _newDay = _newDate.getDate() + _days;
        _newDate.setDate(_newDay);

        return _newDate;
    }

    function addMilliseconds(_date, _ms) {
        let _newDate = new Date(_date.getTime())
        _newDate.setMilliseconds(_newDate.getMilliseconds() + _ms);

        return _newDate;
    }

    function addHours(_date, _hours) {
        let _newDate = new Date(_date.getTime())
        _newDate.setTime(_newDate.getTime() + _hours * 60 * 60 * 1000);

        return _newDate;
    }

    // Function return the alarm dayOfWeek according to the day provided
    function get_alarm_day(day) {
        switch(day) {
        case 0: return Alarm.Sunday
        case 1: return Alarm.Monday
        case 2: return Alarm.Tuesday
        case 3: return Alarm.Wednesday
        case 4: return Alarm.Thursday
        case 5: return Alarm.Friday
        case 6: return Alarm.Saturday
        }
    }

    Connections {
        target: Powerd

        onStatusChanged: {
            if (Powerd.status === Powerd.On) {
                root.checkIfPastLatestAlarm()
                root.checkIfNearEarliestAlarm()
            }
        }
    }

    LiveTimer {
        frequency: Powerd.status === Powerd.On ? LiveTimer.Hour : LiveTimer.Disabled
        onTrigger: {
            root.checkIfPastLatestAlarm()
            root.checkIfNearEarliestAlarm()
        }
    }
}
