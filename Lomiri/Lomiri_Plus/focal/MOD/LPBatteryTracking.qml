// ENH196 - Battery stats tracking
import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.SystemSettings.Battery 1.0
import Lomiri.Settings.Menus 0.1 as Menus
import QtQuick.Layouts 1.12
import Powerd 0.1

Item {
    id: root

    // ENH217 - Charging state notification
    readonly property string fullChargeAlarmName: "[LOMIRIPLUS] Charging Alarm"
    // ENH217 - ENd
    property bool automaticUpdateValues: true
    property alias primaryBattery: batteryBackend.primaryBattery

    property int lastChargeBatteryLevel: 0 // Battery level when the device was unplugged from power
    property real lastFullChargeDatetime: 0 // Alternative to standard last full charged time

    readonly property string screenOnTimeSinceLastFull: screenOnTimeSinceLastFullValue > -1 ? internal.msToTime(screenOnTimeSinceLastFullValue) : i18n.tr("No data")
    readonly property string screenOffTimeSinceLastFull: screenOffTimeSinceLastFullValue > -1 ? internal.msToTime(screenOffTimeSinceLastFullValue) : i18n.tr("No data")
    readonly property string screenOnTimeSinceLastCharge: screenOnTimeSinceLastChargeValue > -1 ? internal.msToTime(screenOnTimeSinceLastChargeValue) : i18n.tr("No data")
    readonly property string screenOffTimeSinceLastCharge: screenOffTimeSinceLastChargeValue > -1 ? internal.msToTime(screenOffTimeSinceLastChargeValue) : i18n.tr("No data")
    readonly property string screenOnTimeToday: screenOnTimeTodayValue > -1 ? internal.msToTime(screenOnTimeTodayValue) : i18n.tr("No data")
    readonly property string screenOffTimeToday: screenOffTimeTodayValue > -1 ? internal.msToTime(screenOffTimeTodayValue) : i18n.tr("No data")
    readonly property string screenOnTimeYesterday: screenOnTimeYesterdayValue > -1 ? internal.msToTime(screenOnTimeYesterdayValue) : i18n.tr("No data")
    readonly property string screenOffTimeYesterday: screenOffTimeYesterdayValue > -1 ? internal.msToTime(screenOffTimeYesterdayValue) : i18n.tr("No data")

    readonly property string screenOnTimeFullyChargedAverage: screenOnTimeFullyChargedAverageValue > -1 ? internal.msToTime(screenOnTimeFullyChargedAverageValue) : i18n.tr("Not enough data")
    readonly property string screenOffTimeFullyChargedAverage: screenOffTimeFullyChargedAverageValue > -1 ? internal.msToTime(screenOffTimeFullyChargedAverageValue) : i18n.tr("Not enough data")
    readonly property string screenOnTimeLastChargeAverage: screenOnTimeLastChargeAverageValue > -1 ? internal.msToTime(screenOnTimeLastChargeAverageValue) : i18n.tr("Not enough data")
    readonly property string screenOffTimeLastChargeAverage: screenOffTimeLastChargeAverageValue > -1 ? internal.msToTime(screenOffTimeLastChargeAverageValue) : i18n.tr("Not enough data")
    readonly property string screenOnTimeDaysAverage: screenOnTimeDaysAverageValue > -1 ? internal.msToTime(screenOnTimeDaysAverageValue) : i18n.tr("Not enough data")
    readonly property string screenOffTimeDaysAverage: screenOffTimeDaysAverageValue > -1 ? internal.msToTime(screenOffTimeDaysAverageValue) : i18n.tr("Not enough data")

    property var fullyChargedData
    property var lastChargeData
    property var daysData

    property int screenOnTimeSinceLastFullValue: -1
    property int screenOffTimeSinceLastFullValue: -1
    property int screenOnTimeSinceLastChargeValue: -1
    property int screenOffTimeSinceLastChargeValue: -1
    property int screenOnTimeTodayValue: -1
    property int screenOffTimeTodayValue: -1
    property int screenOnTimeYesterdayValue: -1
    property int screenOffTimeYesterdayValue: -1

    property int screenOnTimeFullyChargedAverageValue: -1
    property int screenOffTimeFullyChargedAverageValue: -1
    property int screenOnTimeLastChargeAverageValue: -1
    property int screenOffTimeLastChargeAverageValue: -1
    property int screenOnTimeDaysAverageValue: -1
    property int screenOffTimeDaysAverageValue: -1

    Component.onCompleted: updateScreenTimeValues()

    function msToTime(_duration) {
        return internal.msToTime(_duration)
    }

    function addData(_forcedValue) {
        let _tempArr = shell.settings.batteryTrackingData.slice()
        let _datetime = new Date().getTime()
        let _batteryLevel = primaryBattery.batteryLevel
        let _powerStatus = _forcedValue ? _forcedValue : Powerd.status
        let _batteryState = primaryBattery.state
        let _newItem = {
            datetime: _datetime
            , batteryLevel: _batteryLevel
            , powerStatus: _powerStatus
            , batteryState: _batteryState
        }
        _tempArr.push(_newItem)
        shell.settings.batteryTrackingData = _tempArr.slice()
    }

    function clear() {
        shell.settings.batteryTrackingData = []
        screenOnTimeSinceLastFullValue = -1
        screenOffTimeSinceLastFullValue = -1
        screenOnTimeSinceLastChargeValue = -1
        screenOffTimeSinceLastChargeValue = -1
        screenOnTimeTodayValue = -1
        screenOffTimeTodayValue = -1
        screenOnTimeYesterdayValue = -1
        screenOffTimeYesterdayValue = -1
    }

    function cleanup() {
        let _duration = internal.dayToMs(shell.settings.batteryTrackingDataDuration)
        let _now = new Date().getTime()
        let _arrayLength = shell.settings.batteryTrackingData.length
        let _deleteCount = 0

        for (let i = 0; i < _arrayLength; i++) {
            let _item = shell.settings.batteryTrackingData[i]
            let _diff = _now - _item.datetime

            if (_diff <= _duration) {
                _deleteCount = i
                break
            }
        }

        let _tempArr = shell.settings.batteryTrackingData.slice()
        let _deletedItems = _tempArr.splice(0, _deleteCount)
        console.log("Deleted Battery Log: " + JSON.stringify(_deletedItems))
        shell.settings.batteryTrackingData = _tempArr.slice()
    }

    function updateScreenTimeValues() {
        console.log("Screen Time Stats Updated")

        const _updateAll = shell.settings.showHistoryCharts

        let _arrFullCharged = []
        let _arrCharge = []
        let _arrDays = []
        let _daysAgo = 0

        const _now = new Date().getTime()
        const _todayObj = new Date()
        _todayObj.setHours(0)
        _todayObj.setMinutes(0)
        _todayObj.setSeconds(0)
        _todayObj.setMilliseconds(0)
        const _today = _todayObj.getTime()

        const _yesterdayObj = new Date()
        _yesterdayObj.setDate(new Date().getDate() - 1)
        _yesterdayObj.setHours(0)
        _yesterdayObj.setMinutes(0)
        _yesterdayObj.setSeconds(0)
        _yesterdayObj.setMilliseconds(0)
        const _yesterday = _yesterdayObj.getTime()

        const _yesterdayEndObj = new Date()
        _yesterdayEndObj.setDate(new Date().getDate() - 1)
        _yesterdayEndObj.setHours(23)
        _yesterdayEndObj.setMinutes(59)
        _yesterdayEndObj.setSeconds(59)
        _yesterdayEndObj.setMilliseconds(999)
        const _yesterdayEnd = _yesterdayEndObj.getTime()

        let _arrayLength = shell.settings.batteryTrackingData.length
        let _indexOfLastFullCharged = -1
        let _indexOfLastFullChargedTo = -1
        let _indexOfLastCharge = -1
        let _indexOfLastChargeTo = -1
        let _beforeChargeBatteryLevel = -1
        let _lastChargeBatteryLevel = -1
        let _indexOfDischargeAfterCharge = -1
        let _indexOfDayFrom = -1
        let _indexOfDayTo = -1
        let _indexOfToday = -1
        let _indexOfYesterdayFrom = -1
        let _indexOfYesterdayTo = -1

        let _dayStartObj = new Date()
        _dayStartObj.setDate(new Date().getDate() - _daysAgo)
        _dayStartObj.setHours(0)
        _dayStartObj.setMinutes(0)
        _dayStartObj.setSeconds(0)
        _dayStartObj.setMilliseconds(0)
        let _dayStart = _dayStartObj.getTime()

        let _dayEndObj = new Date()
        _dayEndObj.setDate(new Date().getDate() - _daysAgo)
        _dayEndObj.setHours(23)
        _dayEndObj.setMinutes(59)
        _dayEndObj.setSeconds(59)
        _dayEndObj.setMilliseconds(999)
        let _dayEnd = _dayEndObj.getTime()

        // Find last full charge and last charging
        for (let i = _arrayLength - 1; i >= 0; i--) {
            let _item = shell.settings.batteryTrackingData[i]
            let _datetime = _item.datetime
            let _batteryState = _item.batteryState
            let _batteryLevel = _item.batteryLevel

            if (_arrFullCharged.length === 0 || (_arrFullCharged.length > 0 && _indexOfLastFullChargedTo > -1)) {
                // Disable workaround and see how it works
                //if ((!shell.settings.screenTimeFullyChargedWorkaround && _batteryState == Battery.FullyCharged && _indexOfLastFullCharged === -1)
                //        || (shell.settings.screenTimeFullyChargedWorkaround && _batteryLevel == 100 && _batteryState == Battery.Charging && _indexOfLastFullCharged === -1)) {
                if ((_batteryState == Battery.FullyCharged && _indexOfLastFullCharged === -1)
                        || (_batteryLevel == 100 && _batteryState == Battery.Charging && _indexOfLastFullCharged === -1)) {
                    _indexOfLastFullCharged = i
                    _lastChargeBatteryLevel = _batteryLevel
                    if (_arrFullCharged.length === 0) {
                        lastFullChargeDatetime = _datetime
                    }
                }
            }

            // Get to index of previous last fully charged ranges
            if (_arrFullCharged.length > 0 && _batteryState == Battery.Discharging && _indexOfLastFullChargedTo === -1) {
                _indexOfLastFullChargedTo = i
                _beforeChargeBatteryLevel = _batteryLevel
            }

            // Get last time the state is charging
            if ((_arrCharge.length === 0 && _batteryState == Battery.Charging && _indexOfLastCharge === -1)
                    || (_arrCharge.length > 0 && _batteryState == Battery.Charging && _indexOfLastChargeTo > -1)) {
                _indexOfLastCharge = i
            }

            // Get the first time the state is discharging after battery was last charging
            if (_batteryState == Battery.Discharging && _indexOfLastCharge === -1) {
                _indexOfDischargeAfterCharge = i
                if (_updateAll) {
                    _lastChargeBatteryLevel = _batteryLevel
                } else {
                    lastChargeBatteryLevel = _batteryLevel
                }
            }

            // Get to index of previous last charging ranges
            if (_arrCharge.length > 0 && _batteryState == Battery.Discharging && _indexOfLastChargeTo === -1) {
                _indexOfLastChargeTo = i
                _beforeChargeBatteryLevel = _batteryLevel
            }

            if (_updateAll) {
                if (_datetime >= _dayStart) {
                    _indexOfDayFrom = i
                }

                if (_arrDays.length > 0 && _datetime <= _dayEnd && _indexOfDayTo === -1) {
                    _indexOfDayTo = i
                }

                if ((_arrFullCharged.length === 0 && _indexOfLastFullCharged > -1)
                        || (_arrFullCharged.length > 0 && _indexOfLastFullCharged > -1 && _indexOfLastFullChargedTo > -1)) {
                    _arrFullCharged.push({ from: _indexOfLastFullCharged, to: _indexOfLastFullChargedTo, fromBattery: _lastChargeBatteryLevel, toBattery: _beforeChargeBatteryLevel })
                    _indexOfLastFullCharged = -1
                    _indexOfLastFullChargedTo = -1
                }

                if ((_arrCharge.length === 0 && _indexOfLastCharge > -1 && _indexOfDischargeAfterCharge > -1)
                        || (_arrCharge.length > 0 && _indexOfLastCharge > -1 && _indexOfDischargeAfterCharge > -1 && _indexOfLastChargeTo > -1)) {
                    _arrCharge.push({ from: _indexOfDischargeAfterCharge, to: _indexOfLastChargeTo, fromBattery: _lastChargeBatteryLevel, toBattery: _beforeChargeBatteryLevel })
                    _indexOfLastCharge = -1
                    _indexOfLastChargeTo = -1
                    _indexOfDischargeAfterCharge = -1
                }

                if ((_arrDays.length === 0 && _indexOfDayFrom > -1 && _datetime < _dayStart)
                        || (_arrDays.length > 0 && _indexOfDayFrom > -1 && _indexOfDayTo > -1 && _datetime < _dayStart)) {
                    // Add 1 to the to index since we skipped the actual index from the last loop
                    // because we are only identifying the start of the previous day in this loop
                    _arrDays.push({ from: _indexOfDayFrom, to: _indexOfDayTo > -1 ? _indexOfDayTo + 1 : _indexOfDayTo, fromDate: _dayStart, toDate: _dayEnd })
                    _indexOfDayFrom = -1
                    _indexOfDayTo = -1
                    _daysAgo += 1
                    _dayStartObj.setDate(new Date().getDate() - _daysAgo)
                    _dayStartObj.setHours(0)
                    _dayStartObj.setMinutes(0)
                    _dayStartObj.setSeconds(0)
                    _dayStartObj.setMilliseconds(0)
                    _dayStart = _dayStartObj.getTime()

                    _dayEndObj.setDate(new Date().getDate() - _daysAgo)
                    _dayEndObj.setHours(23)
                    _dayEndObj.setMinutes(59)
                    _dayEndObj.setSeconds(59)
                    _dayEndObj.setMilliseconds(999)
                    _dayEnd = _dayEndObj.getTime()
                }
            } else {
                if (_datetime >= _today) {
                    _indexOfToday = i
                }

                if (_datetime >= _yesterday) {
                    _indexOfYesterdayFrom = i
                }

                if (_datetime <= _yesterdayEnd && _indexOfYesterdayTo === -1) {
                    _indexOfYesterdayTo = i
                }
            }

            if (_indexOfLastFullCharged > -1 && _indexOfLastCharge > -1 && _indexOfDischargeAfterCharge > -1
                    && _indexOfToday > -1 && _indexOfYesterdayFrom > -1 && _datetime < _yesterday
                    && _indexOfYesterdayTo > -1
                    && !_updateAll) {
                break
            }
        }

        let _sinceFullChargedValues = { onValue: -1, offValue: -1 }
        let _sinceLastChargeValues = { onValue: -1, offValue: -1 }
        let _todayValues = { onValue: -1, offValue: -1 }
        let _yesterdayValues = { onValue: -1, offValue: -1 }

        if (_updateAll) {
            if (_arrFullCharged.length > 0) {
                let _item = _arrFullCharged[0]
                _sinceFullChargedValues = internal.getValues(_item.from, _item.to)
            }

            if (_arrCharge.length > 0) {
                let _item = _arrCharge[0]
                _sinceLastChargeValues = internal.getValues(_item.from, _item.to)
                lastChargeBatteryLevel = _item.fromBattery
            }
            
            if (_arrDays.length > 0) {
                let _item = _arrDays[0]
                _todayValues = internal.getValues(_item.from, _item.to, _item.fromDate)
            }

            if (_arrDays.length > 1) {
                let _item = _arrDays[1]
                _yesterdayValues = internal.getValues(_item.from, _item.to, _item.fromDate, _item.toDate)
            }
        } else {
            _sinceFullChargedValues = internal.getValues(_indexOfLastFullCharged)
            _sinceLastChargeValues = internal.getValues(_indexOfDischargeAfterCharge)
            _todayValues = internal.getValues(_indexOfToday, _arrayLength - 1, _today)
            _yesterdayValues = internal.getValues(_indexOfYesterdayFrom, _indexOfYesterdayTo, _yesterday, _yesterdayEnd)
        }

        screenOnTimeSinceLastFullValue = _sinceFullChargedValues.onValue
        screenOffTimeSinceLastFullValue = _sinceFullChargedValues.offValue
        screenOnTimeSinceLastChargeValue = _sinceLastChargeValues.onValue
        screenOffTimeSinceLastChargeValue = _sinceLastChargeValues.offValue
        screenOnTimeTodayValue = _todayValues.onValue
        screenOffTimeTodayValue = _todayValues.offValue
        screenOnTimeYesterdayValue = _yesterdayValues.onValue
        screenOffTimeYesterdayValue = _yesterdayValues.offValue


        let _arrFullyChargedData = []
        let _arrLastChargeData = []
        let _arrDaysData = []

        let _fullyChargedtotalScreenOn = 0
        let _fullyChargedtotalScreenOff = 0
        let _lastChargetotalScreenOn = 0
        let _lastChargetotalScreenOff = 0
        let _daystotalScreenOn = 0
        let _daystotalScreenOff = 0

        const _arrFullChargedLength = _arrFullCharged.length
        const _arrChargeLength = _arrCharge.length
        const _arrDaysLength = _arrDays.length

        for (let i = 0; i < _arrFullChargedLength; i++) {
            let _item = _arrFullCharged[i]
            const _drain = _item.fromBattery - _item.toBattery
            
            // When the setting is enabled, only include data where the battery drain has reached the set threshold
            if (i === 0 || ((shell.settings.onlyIncludePercentageRangeInBatteryChart && _drain >= shell.settings.batteryPercentageRangeToInclude)
                                || !shell.settings.onlyIncludePercentageRangeInBatteryChart)) {
                let _values = internal.getValues(_item.from, _item.to)
                let _data = { onValue: internal.msToHours(_values.onValue), offValue: internal.msToHours(_values.offValue)
                                    , onLabel: internal.msToTime(_values.onValue), offLabel: internal.msToTime(_values.offValue) }
                if (i > 0) { // Do not include current
                    _fullyChargedtotalScreenOn += _values.onValue
                    _fullyChargedtotalScreenOff += _values.offValue
                }

                _arrFullyChargedData.push(_data)
            }
        }

        const _arrFullyChargedDataAverageLength = _arrFullyChargedData.length - 1

        screenOnTimeFullyChargedAverageValue = _fullyChargedtotalScreenOn / _arrFullyChargedDataAverageLength
        screenOffTimeFullyChargedAverageValue = _fullyChargedtotalScreenOff / _arrFullyChargedDataAverageLength

        for (let i = 0; i < _arrChargeLength; i++) {
            let _item = _arrCharge[i]
            const _drain = _item.fromBattery - _item.toBattery

            // When the setting is enabled, only include data where the battery drain has reached the set threshold
            if (i === 0 || ((shell.settings.onlyIncludePercentageRangeInBatteryChart && _drain >= shell.settings.batteryPercentageRangeToInclude)
                                || !shell.settings.onlyIncludePercentageRangeInBatteryChart)) {
                let _values = internal.getValues(_item.from, _item.to)
                let _data = { onValue: internal.msToHours(_values.onValue), offValue: internal.msToHours(_values.offValue)
                                    , onLabel: internal.msToTime(_values.onValue), offLabel: internal.msToTime(_values.offValue) }
                if (i > 0) { // Do not include current
                    _lastChargetotalScreenOn += _values.onValue
                    _lastChargetotalScreenOff += _values.offValue
                }

                _arrLastChargeData.push(_data)
            }
        }

        const _arrChargeLengthAverageLength = _arrLastChargeData.length - 1

        screenOnTimeLastChargeAverageValue = _lastChargetotalScreenOn / _arrChargeLengthAverageLength
        screenOffTimeLastChargeAverageValue = _lastChargetotalScreenOff / _arrChargeLengthAverageLength

        for (let i = 0; i < _arrDaysLength; i++) {
            let _item = _arrDays[i]
            let _values
            if (i === 0){ 
                _values = internal.getValues(_item.from, _item.to, _item.fromDate)
            } else {
                _values = internal.getValues(_item.from, _item.to, _item.fromDate, _item.toDate)
            }
            let _data = { onValue: internal.msToHours(_values.onValue), offValue: internal.msToHours(_values.offValue)
                                , onLabel: internal.msToTime(_values.onValue), offLabel: internal.msToTime(_values.offValue) }
            if (i > 0) { // Do not include current
                _daystotalScreenOn += _values.onValue
                _daystotalScreenOff += _values.offValue
            }
            _arrDaysData.push(_data)
        }

        screenOnTimeDaysAverageValue = _daystotalScreenOn / (_arrDaysLength - 1)
        screenOffTimeDaysAverageValue = _daystotalScreenOff / (_arrDaysLength - 1)

        fullyChargedData = _arrFullyChargedData
        lastChargeData = _arrLastChargeData
        daysData = _arrDaysData

        /* For logging
        for (let i = 0; i < _arrCharge.length; i++) {
            let _item = _arrCharge[i]
            let _values = internal.getValues(_item.from, _item.to, _item.fromDate, _item.toDate)
            let _values = internal.getValues(_item.from, _item.to)
            console.log(i + ": " + internal.msToTime(_values.onValue) + " - " + internal.msToTime(_values.offValue))
            console.log([_item.from, _item.to, _item.fromDate, _item.toDate].join(" - "))
            console.log([_item.from, _item.to].join(" - "))
            console.log([_item.from, _item.to, _item.fromBattery].join(" - "))
        }
        */
    }

    LomiriBatteryPanel {
        id: batteryBackend
    }

    LiveTimer {
        frequency: Powerd.status === Powerd.On ? LiveTimer.Minute : LiveTimer.Disabled
        onTrigger: if (root.automaticUpdateValues) root.updateScreenTimeValues()
    }

    LiveTimer {
        frequency: Powerd.status === Powerd.On ? LiveTimer.Hour : LiveTimer.Disabled
        onTrigger: root.cleanup()
    }

    Connections {
        id: powerConnection
        target: Powerd

        onStatusChanged: {
            root.addData()

            if (Powerd.status === Powerd.On) {
                root.updateScreenTimeValues()
                // ENH217 - Charging state notification
                let _alarmModel = shell.alarmItemModel
                let  _modelCount = _alarmModel.count
                for (let i = _modelCount - 1; i > -1; i--) {
                    let _alarm = _alarmModel.get(i)
                    let _alarmName = _alarm.message

                    let _regex = new RegExp("^" + internal.escapeRegExp(root.fullChargeAlarmName), "g")
                    
                    if (_regex.test(_alarmName)) {
                        _alarm.cancel()
                        console.log("Charging Alarm Deleted: " + _alarmName)
                    }
                }
                // ENH217 - End
            }
        }
    }

    Connections {
        id: batteryConnection
        target: primaryBattery

        onStateChanged: {
            if (primaryBattery.state === Battery.Charging || primaryBattery.state === Battery.Discharging
                    || primaryBattery.state === Battery.FullyCharged) {
                root.addData()
                root.updateScreenTimeValues()
            }
            // ENH217 - Charging state notification
            if (root.promptDialogObj && primaryBattery.state === Battery.Discharging) {
                PopupUtils.close(root.promptDialogObj)
                root.promptDialogObj.destroy()
            }
            if (shell.settings.enableChargingAlarm) {
                if (shell.settings.alwaysPromptchargingAlarm && target.state === Battery.Charging) {
                    if (!root.promptDialogObj) {
                        root.promptDialogObj = promptDialog.createObject(shell.popupParent);
                        root.promptDialogObj.show()
                    }
                }

                if (shell.settings.detectFullyChargedInChargingAlarm
                        && target.state === Battery.FullyCharged
                        && (!shell.settings.alwaysPromptchargingAlarm
                            || (shell.settings.alwaysPromptchargingAlarm && shell.settings.temporaryEnableChargingAlarm
                                    && !shell.settings.temporaryCustomTargetBatteryPercentage))) {
                    internal.createAlarm(30)
                }
            }
            // ENH217 - End
        }
        // ENH217 - Charging state notification
        onBatteryLevelChanged: {
            if (shell.settings.enableChargingAlarm
                    && (
                        (!shell.settings.alwaysPromptchargingAlarm && !shell.settings.detectFullyChargedInChargingAlarm)
                        || (shell.settings.alwaysPromptchargingAlarm && shell.settings.temporaryEnableChargingAlarm
                                && (!shell.settings.detectFullyChargedInChargingAlarm
                                        || (shell.settings.detectFullyChargedInChargingAlarm && shell.settings.temporaryCustomTargetBatteryPercentage)
                                   )
                           )
                       )
               ) {
                let _targetBatteryLevel = shell.settings.alwaysPromptchargingAlarm && shell.settings.temporaryEnableChargingAlarm
                                            && shell.settings.temporaryCustomTargetBatteryPercentage ? shell.settings.temporaryTargetBatteryPercentage
                                                                                           : shell.settings.targetPercentageChargingAlarm
                if (primaryBattery.state === Battery.Charging && primaryBattery.batteryLevel == _targetBatteryLevel) {
                    internal.createAlarm(60)
                }
            }
        }
        // ENH217 - End
    }
    // ENH217 - Charging state notification
    property var promptDialogObj
    Component {
        id: promptDialog
        Dialog {
            id: dialogue
            
            property bool reparentToRootItem: false
            property int minimumTarget: 100
            anchorToKeyboard: false // Handle the keyboard anchor via shell.popupParent

            Component.onCompleted: {
                // Reset temporary values
                shell.settings.temporaryEnableChargingAlarm = false
                shell.settings.temporaryCustomTargetBatteryPercentage = false

                let _newTarget = shell.settings.targetPercentageChargingAlarm
                minimumTarget = primaryBattery.batteryLevel + 1

                if (primaryBattery.batteryLevel >= _newTarget) {
                     _newTarget = minimumTarget
                }

                shell.settings.temporaryTargetBatteryPercentage = _newTarget

                if (shell.settings.chargingAlarmPromptTimesout) {
                    timeoutTimer.restart()
                }
            }

            function accept() {
                shell.settings.temporaryEnableChargingAlarm = true
                root.promptDialogObj.destroy()
            }

            function reject() {
                shell.settings.temporaryEnableChargingAlarm = false
                root.promptDialogObj.destroy()
            }

            Timer {
                id: timeoutTimer
                
                readonly property int timeout: 60 //seconds
                property int currentTime: 60

                interval: 1000

                onTriggered: {
                    currentTime -= 1

                    if (currentTime > 0) {
                        timeoutTimer.restart()
                    } else {
                        if (shell.settings.enableChargingAlarmByDefault) {
                            dialogue.accept()
                        } else {
                            dialogue.reject()
                        }
                    }
                }
            }

            text: i18n.tr("Notify when fully charged?")

            LPSettingsCheckBox {
                id: temporaryCustomTargetBatteryPercentage
                Layout.fillWidth: true
                text: "Custom target"
                onCheckedChanged: shell.settings.temporaryCustomTargetBatteryPercentage = checked
                Binding {
                    target: temporaryCustomTargetBatteryPercentage
                    property: "checked"
                    value: shell.settings.temporaryCustomTargetBatteryPercentage
                }
            }

            LPSettingsSlider {
                id: temporaryTargetBatteryPercentage
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                alwaysUnlocked: true
                visible: shell.settings.temporaryCustomTargetBatteryPercentage
                title: "Custom Target Battery %"
                minimumValue: dialogue.minimumTarget
                maximumValue: 100
                stepSize: 1
                resetValue: 80
                live: true
                roundValue: true
                roundingDecimal: 1
                enableFineControls: true
                unitsLabel: "%"
                onValueChanged: shell.settings.temporaryTargetBatteryPercentage = value
                Binding {
                    target: temporaryTargetBatteryPercentage
                    property: "value"
                    value: shell.settings.temporaryTargetBatteryPercentage
                }
            }

            Button {
                 text: shell.settings.chargingAlarmPromptTimesout && shell.settings.enableChargingAlarmByDefault
                                ? i18n.tr("Notify me (%1)").arg(timeoutTimer.currentTime) : i18n.tr("Notify me")
                 color: theme.palette.normal.positive
                 onClicked: {
                    dialogue.accept()
                 }
             }
             Button {
                 text: shell.settings.chargingAlarmPromptTimesout && !shell.settings.enableChargingAlarmByDefault
                            ? i18n.tr("No (%1)").arg(timeoutTimer.currentTime) : i18n.tr("No")
                 onClicked: dialogue.reject()
             }
         }
    }
    // ENH217 - End

    // Add screen tracking data when Lomiri is loaded and unloaded
    // To properly handle shutting down....I hope
    Connections {
        target: shell

        Component.onCompleted: root.addData(Powerd.On)
        Component.onDestruction: root.addData(Powerd.Off)
    }

    QtObject {
        id: internal

        function msToDay(_value) {
            return _value / 1000 / 60 / 60 / 24
        }

        function msToHours(_value) {
            return (_value / 1000 / 60 / 60)
        }

        function dayToMs(_value) {
            return _value * 24 * 60 * 60 * 1000
        }

        function msToTime(_duration) {
            let _milliseconds = Math.floor((_duration % 1000) / 100)
            let _seconds = Math.floor((_duration / 1000) % 60)
            let _minutes = Math.floor((_duration / (1000 * 60)) % 60) + (_seconds > 50 ? 1 : 0)
            let _hours = Math.floor((_duration / (1000 * 60 * 60))) // We let hours to exceed 24 since we don't put days

            let _txtHours = _hours == 0 ? "" : i18n.tr("%1 hour", "%1 hours", _hours).arg(_hours)
            let _txtMinutes = _minutes == 0 ? "" : i18n.tr("%1 minute", "%1 minutes", _minutes).arg(_minutes)

            let _finalText = _txtHours !== "" || _txtMinutes !== "" ? _txtHours + " " + _txtMinutes : "0 minute"

            return _finalText
        }

        function getValues(_indexFrom, _indexTo = -1, _datetimeFrom = -1, _datetimeTo = -1) {
            const _datetimeFromProvided = _datetimeFrom > -1
            const _datetimeToProvided = _datetimeTo > -1
            const _datetimeRangeProvided = _datetimeFromProvided && _datetimeToProvided

            if (_indexFrom > -1 && (_indexTo === -1 || _indexFrom <= _indexTo)
                && ((!_datetimeRangeProvided) || (_datetimeRangeProvided && _datetimeFrom <= _datetimeTo))) {
                const _now = new Date().getTime()
                let _arrayLength = shell.settings.batteryTrackingData.length
                let _onTime = 0
                let _totalTime = 0

                // Set total time based on index range and/or date time range
                if (_indexTo > -1 && !_datetimeFromProvided && !_datetimeToProvided) {
                    _totalTime = shell.settings.batteryTrackingData[_indexTo].datetime - shell.settings.batteryTrackingData[_indexFrom].datetime
                } else if (_datetimeRangeProvided) {
                    _totalTime = _datetimeTo - _datetimeFrom
                } else if (_datetimeFromProvided) {
                    _totalTime = _now - _datetimeFrom
                } else {
                    _totalTime = _now - shell.settings.batteryTrackingData[_indexFrom].datetime
                }

                let _previousStatus = null
                let _previousDateTime = 0
                let _previousDiff = 0
                let _toIndex = _indexTo > -1 ? _indexTo + 1 : _arrayLength

                for (let i = _indexFrom; i < _toIndex; i++) {
                    let _item = shell.settings.batteryTrackingData[i]
                    let _datetime = _item.datetime
                    let _powerStatus = _item.powerStatus
                    let _diff = 0

                    if (_previousDateTime > 0) {
                        if (_datetimeFromProvided && _onTime === 0 && _previousStatus == Powerd.Off) {
                            // We just assume here that previous item is Powerd.On
                            _diff = _datetime - _datetimeFrom
                        } else {
                            _diff = _datetime - _previousDateTime
                        }
                    }

                    // Consolidate diff as long as we see On
                    if (_powerStatus == Powerd.On && _previousStatus == Powerd.On) {
                        _previousDiff += _diff
                    } else {
                        _previousDiff = 0
                    }

                    if (_powerStatus == Powerd.Off && _previousStatus == Powerd.On) {
                        _onTime += (_diff + _previousDiff)
                    }

                    _previousDateTime = _datetime
                    _previousStatus = _powerStatus

                    if (_powerStatus == Powerd.On) {
                        _previousDiff = _diff
                    }
                }


                // Add time between now and the last log if it was On
                if (_previousStatus == Powerd.On) {
                    if (_datetimeRangeProvided) {
                        _onTime += (_datetimeTo - _previousDateTime)
                    } else if (_indexTo === -1) {
                        _onTime += (_now - _previousDateTime)
                    }
                }

                return { onValue: _onTime, offValue: _totalTime - _onTime }
            } else {
                return { onValue: -1, offValue: -1 }
            }
        }

        function createAlarm(_delayInSec = 30) {
            let _alarm = shell.alarmItem
            let _now = Date.now()
            let _endTime = new Date(_now)
            _endTime.setSeconds(_endTime.getSeconds() + _delayInSec);

            _alarm.reset()
            _alarm.sound = shell.settings.silentChargingAlarm ? "dummy" : _alarm.defaultSound
            _alarm.message = root.fullChargeAlarmName
            _alarm.date = _endTime
            _alarm.save()

            if (_alarm.error != Alarm.NoError) {
                console.log("Failed to create full charge alarm: " + _alarm.error)
            } else {
                console.log("Full charge alarm started")
            }
        }

        function escapeRegExp(stringToGoIntoTheRegex) {
            return stringToGoIntoTheRegex.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
        }
    }
}
