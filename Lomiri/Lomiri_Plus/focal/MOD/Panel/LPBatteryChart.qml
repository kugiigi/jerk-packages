// ENH196 - Battery stats tracking
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import Lomiri.Settings.Menus 0.1 as Menus
import "../Components/LPQChart.js" as Charts
import "../Components/" as Components

Components.LPQChart {
    id: chartView

    enum DataToDisplay {
        Both
        , ScreenOn
        , ScreenOff
    }

    enum Type {
        FullyCharged
        , LastCharge
        , Day
    }

    readonly property color gridColor: theme.palette.normal.base
    readonly property bool enoughData: modelData && modelData.length > 1
    property var modelData
    property int dataToDisplay: LPBatteryChart.DataToDisplay.Both
    property int type: LPBatteryChart.Type.Day

    property string screenOnAverage
    property string screenOffAverage

    signal clicked

    chartType: Charts.ChartType.BAR
    chartAnimated: true
    chartAnimationEasing: Easing.InBounce
    chartAnimationDuration: LomiriAnimation.BriskDuration
    chartOptions: {
        "scaleFontColor": theme.palette.normal.backgroundSecondaryText
        , "scaleGridLineColor": Qt.hsla(gridColor.hslHue, gridColor.hslSaturation, gridColor.hslLightness, 0.5)
        , "scaleOverlay": true
        , "scaleFontSize": units.gu(1.5)
        , "pointDotRadius": units.dp(1)
        , "pointDotStrokeWidth": units.dp(1)
    }

    function randomScalingFactor() {
        return Math.random().toFixed(1);
    }

    function processData() {
        if (enoughData) {
            let _arrLength = modelData ? modelData.length : 0
            let _arrLabels = []
            let _arrDatasets = []
            let _screenOnData = {
                label: i18n.tr("Screen On"),
                fillColor : theme.palette.normal.backgroundText,
                strokeColor : theme.palette.normal.backgroundText,
                data: []
            }
            let _screenOffData = {
                label: i18n.tr("Screen Off"),
                fillColor : theme.palette.normal.base,
                strokeColor : theme.palette.normal.base,
                data: []
            }
            let _arrScreenOnData = []
            let _arrScreenOffData = []

            const _includeScreenOn = dataToDisplay === LPBatteryChart.DataToDisplay.Both || dataToDisplay === LPBatteryChart.DataToDisplay.ScreenOn
            const _includeScreenOff = dataToDisplay === LPBatteryChart.DataToDisplay.Both || dataToDisplay === LPBatteryChart.DataToDisplay.ScreenOff

            for (let i = _arrLength - 1; i >= 0; i--) {
                let _item = modelData[i]
                let _label = ""
                if (i > 0) {
                    _label = i
                } else if (type === LPBatteryChart.Type.Day) {
                    _label = i18n.tr("Today")
                } else {
                    _label = i18n.tr("Now")
                }

                _arrLabels.push(_label)

                if (_includeScreenOn) {
                    _arrScreenOnData.push(_item.onValue)
                }

                if (_includeScreenOff) {
                    _arrScreenOffData.push(_item.offValue)
                }
            }
            _screenOnData.data = _arrScreenOnData
            _screenOffData.data = _arrScreenOffData

            if (_includeScreenOn) {
                _arrDatasets.push(_screenOnData)
            }

            if (_includeScreenOff) {
                _arrDatasets.push(_screenOffData)
            }
            chartData = {
                labels: _arrLabels
                , datasets: _arrDatasets
            }
        }
    }

    onVisibleChanged: if (visible) processData()
    onModelDataChanged: processData()
    onDataToDisplayChanged: processData()

    Label {
        visible: !chartView.enoughData
        anchors.centerIn: parent
        text: i18n.tr("Not enough data")
        color: theme.palette.normal.backgroundText
    }

    TapHandler {
        onSingleTapped: chartView.clicked()
    }
}
