// ENH046 - Lomiri Plus Settings
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2

ListItem {
    id: navItem

    property string text

    height: layout.height
    divider.visible: false
    ListItemLayout {
        id: layout
        title.text: navItem.text
        ProgressionSlot {}
    }
}
// ENH046 - End
