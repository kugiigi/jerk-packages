import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import Lomiri.Components 1.3
import "." as Common

QQC2.ToolButton {
    id: toolButton

    property string tooltipText
    property string iconName
    property real iconWidth
    property real iconHeight
    property color iconColor

    height: units.gu(5)
    width: height
    focusPolicy: Qt.TabFocus
    icon.width: units.gu(2)
    icon.height: units.gu(2)

    onClicked: Common.Haptics.playSubtle()

    QQC2.ToolTip.delay: 1000
    QQC2.ToolTip.visible: hovered
    QQC2.ToolTip.text: toolButton.tooltipText
}
