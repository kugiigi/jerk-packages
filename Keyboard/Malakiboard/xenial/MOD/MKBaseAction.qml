// ENH089 - Quick actions
import QtQuick.Controls 2.12 as QQC2

QQC2.Action {
    id: action

    property bool visible: true
    property bool separator: false
    property string tooltipText
    property string iconName
    property int iconRotation: 0
    icon.name: iconName
    enabled: visible

    signal trigger(bool isBottom, var caller)
}
// ENH089 - End
