import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Controls.Suru 2.2

ListItem {
    id: checkboxItem

    property string text
    property alias checked: checkbox.checked
    property bool inverted: false
    property bool showDivider: true
    readonly property alias contentHeight: layout.height

    height: layout.height
    divider.visible: false
    onClicked: checkbox.checked = !checkbox.checked

    SlotsLayout {
        id: layout

        mainSlot: Label {
            text: checkboxItem.text
            wrapMode: Text.WordWrap
        }

        QQC2.CheckBox {
            id: checkbox
            SlotsLayout.position: checkboxItem.inverted ? SlotsLayout.Leading : SlotsLayout.Trailing
            checked: true
        }
    }
    Rectangle {
        visible: checkboxItem.showDivider
        anchors.bottom: parent.bottom
        width: parent.width
        height: units.dp(1)
        color: Suru.neutralColor
    }
}
