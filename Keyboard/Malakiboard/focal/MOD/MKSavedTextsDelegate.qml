// ENH120 - Saved Texts
import QtQuick 2.4
import Lomiri.Components 1.3
import "keys/key_constants.js" as UI
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12


ListItem {
    id: root

    readonly property real verticalMargins: labelDescr.visible ? units.gu(1) : units.gu(1.5)
    readonly property real horizontalMargins: units.gu(2)

    property alias text: label.text
    property alias descr: labelDescr.text
    
    signal deleteItem

    height: layout.height + verticalMargins * 2

    divider {
        colorFrom: fullScreenItem.theme.fontColor
        colorTo: fullScreenItem.theme.popupBorderColor
    }
    highlightColor: fullScreenItem.theme.backgroundColor

    ColumnLayout {
        id: layout

        anchors {
            top: parent.top
            topMargin: root.verticalMargins
            left: parent.left
            leftMargin: root.horizontalMargins
            right: parent.right
            rightMargin: root.horizontalMargins
        }

        Label {
            id: labelDescr

            Layout.fillWidth: true

            visible: text.trim() !== ""
            font.pixelSize: label.font.pixelSize * 1.1
            font.family: UI.fontFamily
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            color: fullScreenItem.theme.fontColor
            wrapMode: Text.WordWrap
            maximumLineCount: 1
            verticalAlignment: Text.AlignVCenter
        }

        Label {
            id: label

            Layout.fillWidth: true

            font.pixelSize: units.dp(fullScreenItem.tablet ? UI.tabletWordRibbonFontSize : UI.phoneWordRibbonFontSize)
            font.family: UI.fontFamily
            font.weight: Font.Normal
            elide: Text.ElideRight
            color: fullScreenItem.theme.fontColor
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            verticalAlignment: Text.AlignVCenter
        }
    }

    leadingActions: ListItemActions {
       actions: [
           Action {
               iconName: "delete"
               onTriggered: root.deleteItem()
           }
       ]
    }
}
