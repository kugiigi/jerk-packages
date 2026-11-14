// ENH046 - Lomiri Plus Settings
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2

ListItem {
    id: timePickerItem

    property string text
    property date date

    height: layout.height
    divider.visible: false

    SlotsLayout {
        id: layout

        mainSlot: Label {
            text: timePickerItem.text
            wrapMode: Text.WordWrap
        }
        Label {
            text: timePickerItem.date.toLocaleTimeString(Qt.locale(),Locale.ShortFormat)
            SlotsLayout.position: SlotsLayout.Trailing
        }
    }
}// ENH046 - End
