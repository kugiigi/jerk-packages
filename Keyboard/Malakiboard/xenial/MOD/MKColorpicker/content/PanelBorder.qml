//  Fancy pseudo-3d control border
import QtQuick 2.9
import Ubuntu.Components 1.3 as UITK

Rectangle {
    width : units.gu(15); height : units.gu(5); radius: units.gu(2)
    border.width: units.dp(1); border.color: "#FF101010"
    color: "transparent"
    anchors.leftMargin: units.gu(1); anchors.topMargin: units.gu(2)
    clip: true
    Rectangle {
        anchors.fill: parent; radius: units.gu(2)
        anchors.leftMargin: -units.gu(1); anchors.topMargin: -units.gu(1)
        anchors.rightMargin: 0; anchors.bottomMargin: 0
        border.width: units.dp(1); border.color: "#FF525255"
        color: "transparent"
    }
}


