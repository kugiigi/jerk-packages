import QtQuick 2.9
import Lomiri.Components 1.3
import QtQuick.Controls 2.2 as QQC2

QQC2.SpinBox {
    id: zoomSpinBox

    property var controller
    property int prevValue

    value: Math.round(controller.currentZoomFactor * 100)
    from: controller.minZoomFactor * 100
    to: controller.maxZoomFactor * 100
    stepSize: 5

    up.indicator.implicitWidth: units.gu(5)
    down.indicator.implicitWidth: units.gu(5)
    textFromValue: function(value, locale) {
        return value + "%";
    }

    Component.onCompleted: prevValue = value

    onValueModified: {
        if (value > prevValue) {
            controller.zoomIn()
        } else {
            controller.zoomOut()
        }
    }
    
    Connections {
        target: controller
        onCurrentZoomFactorChanged: {
            zoomSpinBox.prevValue = Math.round(target.currentZoomFactor * 100)
        }
    }
}
