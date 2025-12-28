// ENH196 - Battery stats tracking
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import Lomiri.Settings.Menus 0.1 as Menus
import "../Components/LPQChart.js" as Charts
import "../Components/" as Components

Item {
    id: root

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
    property bool listViewMode: false

    property string screenOnAverage
    property string screenOffAverage

    signal clicked
    signal toggleMode

    onVisibleChanged: if (visible) chartView.processData()
    onModelDataChanged: chartView.processData()
    onDataToDisplayChanged: chartView.processData()

    Components.LPQChart {
        id: chartView

        visible: !root.listViewMode
        anchors.fill: parent
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
    }

    ListView {
        id: listView

        readonly property real daysColumnWidth: units.gu(10)
        readonly property real sideMargins: units.gu(1)

        visible: root.listViewMode
        anchors {
            fill: parent
            leftMargin: sideMargins
            rightMargin: sideMargins
        }
        clip: true
        model: root.modelData
        header: RowLayout {
            height: units.gu(4)
            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(1)
            }
            Label {
                id: daysHeaderLabel

                Layout.preferredWidth: listView.daysColumnWidth
                text: root.type === LPBatteryChart.Type.Day ? i18n.tr("Days ago") : i18n.tr("Charges ago")
                font.weight: Font.DemiBold
                color: theme.palette.normal.backgroundText
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
             Label {
                id: onHeaderLabel

                Layout.fillWidth: !offHeaderLabel.visible
                Layout.preferredWidth: (listView.width - listView.daysColumnWidth) / 2
                visible: root.dataToDisplay !== LPBatteryChart.DataToDisplay.ScreenOff
                text: i18n.tr("Screen On")
                font.weight: Font.DemiBold
                color: theme.palette.normal.backgroundText
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
            Label {
                id: offHeaderLabel

                Layout.fillWidth: !onHeaderLabel.visible
                Layout.preferredWidth: (listView.width - listView.daysColumnWidth) / 2
                visible: root.dataToDisplay !== LPBatteryChart.DataToDisplay.ScreenOn
                text: i18n.tr("Screen Off")
                font.weight: Font.DemiBold
                color: theme.palette.normal.backgroundText
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
        // TODO: Find a better way to blur or something the background
        //headerPositioning: ListView.PullBackHeader
        delegate: Item {
            height: units.gu(4)
            width: listView.width

            RowLayout {
                anchors.fill: parent

                Label {
                    id: daysLabel
                    Layout.preferredWidth: listView.daysColumnWidth
                    text: {
                        if (index > 0) return index + 1

                        if (root.type === LPBatteryChart.Type.Day) {
                            return i18n.tr("Today")
                        } else {
                            return i18n.tr("Now")
                        }
                    }
                    color: theme.palette.normal.backgroundText
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                Label {
                    id: onLabel
                    Layout.fillWidth: !offLabel.visible
                    Layout.preferredWidth: (listView.width - listView.daysColumnWidth) / 2
                    visible: root.dataToDisplay !== LPBatteryChart.DataToDisplay.ScreenOff
                    text: shell.msToTime(shell.hoursToms(modelData.onValue), false)
                    color: theme.palette.normal.backgroundText
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                Label {
                    id: offLabel
                    Layout.fillWidth: !onLabel.visible
                    Layout.preferredWidth: (listView.width - listView.daysColumnWidth) / 2
                    visible: root.dataToDisplay !== LPBatteryChart.DataToDisplay.ScreenOn
                    text: shell.msToTime(shell.hoursToms(modelData.offValue), false)
                    color: theme.palette.normal.backgroundText
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: {
                    switch (true) {
                        case (mouse.button === Qt.LeftButton):
                            root.clicked()
                            break
                        case (mouse.button === Qt.RightButton):
                            root.toggleMode()
                            break
                    }
                }

                onPressAndHold: {
                    root.toggleMode()
                    shell.haptics.playSubtle()
                }
            }
        }
    }

    Label {
        visible: !root.enoughData
        anchors.centerIn: parent
        text: i18n.tr("Not enough data")
        color: theme.palette.normal.backgroundText
    }

    MouseArea {
        enabled: !root.listViewMode
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: {
            switch (true) {
                case (mouse.button === Qt.LeftButton):
                    root.clicked()
                    break
                case (mouse.button === Qt.RightButton):
                    root.toggleMode()
                    break
            }
        }

        onPressAndHold: {
            root.toggleMode()
            shell.haptics.playSubtle()
        }
    }
}
