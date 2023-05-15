// ENH070 - Keyboard settings
import QtQuick 2.12
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12 as QQC2

ColumnLayout {
    id: sliderItem

    property alias title: titleLabel.text
    property alias minimumValue: slider.minimumValue
    property alias maximumValue: slider.maximumValue
    property alias value: slider.value
    property alias live: slider.live
    property alias stepSize: slider.stepSize
    property bool showCurrentValue: true
    property bool percentageValue: false
    property bool roundValue: true
    property real resetValue: -1

    Label {
        id: titleLabel

        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }

    RowLayout {
        Slider {
            id: slider

            Layout.fillWidth: true

            minimumValue: 0
            maximumValue: 100
            live: true

            // FIXME - to be deprecated in Lomiri.Components.
            // Use this to disable the label, since there is not way to do it on the component.
            function formatValue(v) {
                if (sliderItem.showCurrentValue) {
                    if (sliderItem.percentageValue) {
                        return ("%1 %").arg(Math.round(v * 100))
                    } else {
                        if (sliderItem.roundValue) {
                            return Math.round(v);
                        } else  {
                            return v;
                        }
                    }
                } else {
                    return "";
                }
            }
        }
        QQC2.ToolButton {
            Layout.fillHeight: true
            icon.width: units.gu(2)
            icon.height: units.gu(2)
            visible: sliderItem.resetValue > -1
            enabled: sliderItem.resetValue !== slider.value
            action: QQC2.Action {
                icon.name:  "reset"
                onTriggered: slider.value = sliderItem.resetValue
            }
        }
    }
}
// ENH070 - End
