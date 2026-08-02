import QtQuick 2.12
import QtQuick.Controls 2.2 as QQC2
import Lomiri.Components 1.3
import QtQuick.Controls.Suru 2.2

QQC2.ToolButton {
    id: headerToolButton

    property string tooltipText

    visible: (action && action.visible) || !action
    display: QQC2.AbstractButton.IconOnly
    icon {
        width: units.gu(2)
        height: units.gu(2)
        color: Suru.foregroundColor
    }

    onClicked: {
        if (action) {
            action.trigger(false, headerToolButton)
        }
    }

    QQC2.ToolTip.delay: 1000
    QQC2.ToolTip.visible: hovered && (headerToolButton.text !== "" || headerToolButton.tooltipText !== "")
    QQC2.ToolTip.text: headerToolButton.tooltipText ? headerToolButton.tooltipText : headerToolButton.text
}
