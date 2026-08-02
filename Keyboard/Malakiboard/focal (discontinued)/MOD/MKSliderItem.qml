// ENH070 - Keyboard settings
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Controls.Suru 2.2

ColumnLayout {
    id: sliderItem

    property alias title: titleLabel.text
    property alias minimumValue: slider.minimumValue
    property alias maximumValue: slider.maximumValue
    property alias value: slider.value
    property alias live: slider.live
    property alias stepSize: slider.stepSize
    property bool displayCurrentValue: true
    property bool showCurrentValue: true
    property bool percentageValue: false
    property bool valueIsPercentage: false
    property bool roundValue: true
    property int roundingDecimal: 0
    property bool enableFineControls: false
    property real resetValue: -1
    property string unitsLabel: percentageValue ? "%" : ""
    property bool locked: !alwaysUnlocked
    property bool alwaysUnlocked: false
    property bool showDivider: true

    function formatDisplayValue(v) {
        if (sliderItem.percentageValue) {
            if (sliderItem.valueIsPercentage) {
                return ("%1 %2").arg(Math.round(v)).arg(sliderItem.unitsLabel)
            } else {
                return ("%1 %2").arg(Math.round(v * 100)).arg(sliderItem.unitsLabel)
            }
        } else {
            if (sliderItem.roundValue) {
                return ("%1 %2").arg(parseFloat(v.toFixed(sliderItem.roundingDecimal))).arg(sliderItem.unitsLabel)
            } else  {
                return ("%1 %2").arg(v).arg(sliderItem.unitsLabel)
            }
        }
    }

    RowLayout {
        Label {
            id: titleLabel

            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Label {
            Layout.alignment: Qt.AlignRight
            visible: sliderItem.displayCurrentValue
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignRight
            font.weight: Font.DemiBold
            text: sliderItem.formatDisplayValue(slider.value)
        }
    }

    RowLayout {
        QQC2.ToolButton {
            Layout.fillHeight: true
            visible: sliderItem.enableFineControls && !sliderItem.locked
            enabled: slider.value > slider.minimumValue && !sliderItem.locked
            icon.width: units.gu(2)
            icon.height: units.gu(2)
            action: QQC2.Action {
                icon.name:  "go-previous"
                onTriggered: slider.value -= slider.stepSize
            }
        }
        Slider {
            id: slider

            Layout.fillWidth: true

            enabled: !sliderItem.locked
            minimumValue: 0
            maximumValue: 100
            live: true

            // FIXME - to be deprecated in Lomiri.Components.
            // Use this to disable the label, since there is not way to do it on the component.
            function formatValue(v) {
                if (sliderItem.showCurrentValue) {
                    return sliderItem.formatDisplayValue(v)
                } else {
                    return "";
                }
            }
        }
        QQC2.ToolButton {
            Layout.fillHeight: true
            visible: sliderItem.enableFineControls && !sliderItem.locked
            enabled: slider.value < slider.maximumValue && !sliderItem.locked
            icon.width: units.gu(2)
            icon.height: units.gu(2)
            action: QQC2.Action {
                icon.name:  "go-next"
                onTriggered: slider.value += slider.stepSize
            }
        }
        QQC2.ToolButton {
            Layout.fillHeight: true
            icon.width: units.gu(2)
            icon.height: units.gu(2)
            visible: sliderItem.resetValue > -1 && !sliderItem.locked
            enabled: sliderItem.resetValue !== slider.value && !sliderItem.locked
            action: QQC2.Action {
                icon.name:  "reset"
                onTriggered: slider.value = sliderItem.resetValue
            }
        }
        QQC2.ToolButton {
            Layout.fillHeight: true
            icon.width: units.gu(2)
            icon.height: units.gu(2)
            action: QQC2.Action {
                icon.name:  sliderItem.locked ? "lock-broken" : "lock"
                onTriggered: sliderItem.locked = !sliderItem.locked
            }
        }
    }
    Rectangle {
        visible: sliderItem.showDivider
        Layout.fillWidth: true
        implicitHeight: units.dp(1)
        color: Suru.neutralColor
    }
}
// ENH070 - End
