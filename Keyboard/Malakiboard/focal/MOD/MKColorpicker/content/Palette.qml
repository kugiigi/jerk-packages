import QtQuick 2.4
import QtQuick.Controls 2.4
import Lomiri.Components 1.3 as UITK
import QtQuick.Controls.Suru 2.2

CheckBox {
    id: control
    text: ""
    transformOrigin: Item.Center
    property color target_color : "#21be2b"
    property color border_color : Suru.foregroundColor
    property color selected_border_color : Suru.highlightColor
    padding: 0

    indicator: Rectangle {
        anchors.centerIn: parent
        height: control.width - units.gu(1.5)
        width: control.width - units.gu(1.5)
        color: target_color
        radius: units.gu(1)
        border.color: (control.checked ? selected_border_color : border_color)
        border.width: control.checked ? units.gu(0.5) : units.gu(0.3)
    }
}
