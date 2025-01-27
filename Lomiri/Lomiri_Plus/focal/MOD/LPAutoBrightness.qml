// ENH206 - Custom auto brightness
import QtQuick 2.12
import Lomiri.Components 1.3
import Powerd 0.1

Item {
    id: root

    property real valueToSet: -1

    property var autoBrightnessData: [
        { light: 0, brightness: 0 }
        , { light: 6, brightness: 0.25 }
        , { light: 45, brightness: 0.40 }
        , { light: 400, brightness: 0.70 }
        , { light: 3000, brightness: 1.0 }
    ]

    function setBrightness(_value) {
        if (shell.brightnessSlider) {
            //brightnessAnimation.startAnimation(_value)
            valueToSet = _value 
            // We delay setting the brightness to make sure it's stable first and doesn't fluctuate
            delayChangeTimer.execute(_value)
        }
    }

    property bool actuallyAllowChange: !shell.settings.tryToStabilizeAutoBrightness || (shell.settings.tryToStabilizeAutoBrightness && allowChange)
    property bool allowChange: true

    Timer {
        id: stabilityDelayTimer

        interval: 3000
        onTriggered: {
            root.allowChange = true
            if (Powerd.status === Powerd.On) {
                root.applyNewBrightness(shell.lightSensorValue)
            }
        }
    }

    Timer {
        id: delayChangeTimer
        
        property real valueToSet: -1

        interval: 400

        function execute(_value) {
            valueToSet = _value
            restart()
        }

        onTriggered: {
            if (root.valueToSet === valueToSet && root.actuallyAllowChange) {
                brightnessAnimation.startAnimation(valueToSet)

                if (shell.settings.tryToStabilizeAutoBrightness) {
                    // Do not allow any more changes until a few seconds past
                    root.allowChange = false
                    stabilityDelayTimer.restart()
                }
            }
        }
    }

    function getNewBrightness(_lightValue) {
        let _arr = root.autoBrightnessData.slice()
        let _retunValue = 0.5

        let i = 0
        let _arrLength = _arr.length

        while (i < _arrLength) {
            let _item = _arr[i]
            let _light = _item.light
            let _brightness = _item.brightness

            if (_lightValue >= _light) {
                _retunValue = _brightness
            } else {
                break
            }

            i++
        }

        return _retunValue
    }

    function applyNewBrightness(_lightValue) {
        let _newBrightness = getNewBrightness(_lightValue)
        setBrightness(_newBrightness)
    }

    LomiriNumberAnimation {
        id: brightnessAnimation

        function startAnimation(_to) {
            to = _to
            restart()
        }

        target: shell.brightnessSlider
        property: "value"
        duration: LomiriAnimation.BriskDuration
    }

    Connections {
        target: Powerd
        
        onStatusChanged: {
            if (Powerd.status === Powerd.On) {
                let _lightValue = shell.lightSensorObj.reading.illuminance >= 0 ? shell.lightSensorObj.reading.illuminance : -1
                root.applyNewBrightness(_lightValue)
            }
        }
    }

    Connections {
        target: shell
        
        onLightSensorValueChanged: {
            if (Powerd.status === Powerd.On && lightSensorValue > -1) {
                root.applyNewBrightness(target.lightSensorValue)
            }
        }
    }
}
