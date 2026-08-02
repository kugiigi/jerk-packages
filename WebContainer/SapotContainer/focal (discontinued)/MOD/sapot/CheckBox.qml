import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2

QQC2.CheckBox {
    id: checkbox

    property string tooltipText

    focusPolicy: Qt.TabFocus

    QQC2.ToolTip.delay: 1000
    QQC2.ToolTip.visible: hovered
    QQC2.ToolTip.text: checkbox.tooltipText
}
