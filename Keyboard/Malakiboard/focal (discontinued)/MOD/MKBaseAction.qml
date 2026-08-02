// ENH089 - Quick actions
import QtQuick.Controls 2.12 as QQC2

QQC2.Action {
    id: action

    property bool visible: true
    property bool separator: false
    property string tooltipText
    property string iconName
    property color iconColor
    property int iconRotation: 0
    icon.name: iconName
    icon.color: iconColor
    enabled: visible

    signal trigger(bool isBottom, var caller)
    signal pressAndHold(bool isBottom, var caller)
}
// ENH089 - End
