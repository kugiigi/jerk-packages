// ENH070 - Keyboard settings
import QtQuick 2.12
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.12

ColumnLayout {
    id: sliderItem

    property alias title: titleLabel.text
    property alias minimumValue: slider.minimumValue
    property alias maximumValue: slider.maximumValue
    property alias value: slider.value
    property alias live: slider.live
    property bool showCurrentValue: true
    property bool percentageValue: false
    property bool roundValue: true

    Label {
        id: titleLabel

        Layout.fillWidth: true
    }
    
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
}
// ENH070 - End
