import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2

QQC2.ToolTip {
    id: tooltip
    
    property string defaultPosition: "BOTTOM"

    function display(customText, customPosition, customTimeout) {
        var position
        if (customPosition) {
            position = customPosition
        } else {
            position = defaultPosition
        }

        switch (position) {
            case "TOP":
                y = units.gu(5);
            break;
            case "BOTTOM":
                y = parent.height - units.gu(10);
            break;
            default:
                y = units.gu(5);
            break;
        }

        let timeoutToUse = customTimeout ? customTimeout : timeout

        show(customText, timeoutToUse)
    }

    timeout: 3000
}
