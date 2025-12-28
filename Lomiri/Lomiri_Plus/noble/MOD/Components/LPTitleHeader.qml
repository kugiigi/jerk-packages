// ENH236 - Custom drawer search
import QtQuick 2.15
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import Lomiri.Components.ListItems 1.3 as ListItems

LPHeader {
    id: root

    property real idealRechableHeight: shell.isBuiltInScreen ? shell.convertFromInch(shell.settings.pullDownHeight)
                                                    : containerItem.height * 0.7
    property real idealMaxHeight: containerItem.height - idealRechableHeight
    property real idealExpandableHeight: idealRechableHeight + units.gu(10)
    property var containerItem: root.parent

    property alias iconName: iconItem.name
    property alias iconSource: iconItem.source
    property alias iconColor: iconItem.color

    property alias text: labelItem.text
    property alias textColor: labelItem.color

    expandable: containerItem.height >= idealExpandableHeight
    defaultHeight: 0
    maxHeight: idealMaxHeight

    Rectangle {
        color: "transparent"
        anchors.fill: parent

        RowLayout {
            anchors {
                fill: parent
                bottomMargin: units.gu(2)
            }
            opacity: root.height - root.defaultHeight < root.maxHeight * 0.2 ? 0
                                : 1 - ((root.maxHeight - root.height) / ((root.maxHeight * 0.8) - root.defaultHeight))
            visible: opacity > 0

            Item {
                Layout.fillWidth: true
            }

            Icon {
                id: iconItem

                Layout.preferredWidth: units.gu(3)
                Layout.preferredHeight: units.gu(3)

                color: theme.palette.normal.backgroundText
                visible: name !== "" || source.toString() !== ""
            }

            Label {
                id: labelItem

                textSize: Label.XLarge
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: theme.palette.normal.backgroundText
            }

            Item {
                Layout.fillWidth: true
            }
        }

        ListItems.ThinDivider {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
        }
    }
}
