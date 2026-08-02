// ENH046 - Lomiri Plus Settings
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2

ListItem {
    id: checkboxItem

    property string text
    property alias checked: checkbox.checked
    property bool inverted: false

    height: layout.height
    divider.visible: false
    onClicked: checkbox.checked = !checkbox.checked

    SlotsLayout {
        id: layout

        mainSlot: Label {
            text: checkboxItem.text
            wrapMode: Text.WordWrap
        }
        CheckBox {
            id: checkbox
            SlotsLayout.position: checkboxItem.inverted ? SlotsLayout.Leading : SlotsLayout.Trailing
            checked: true
        }
    }
}
// ENH046 - End
