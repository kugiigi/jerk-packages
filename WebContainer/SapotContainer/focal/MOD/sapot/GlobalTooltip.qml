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

        hideTimer.startTimer(timeoutToUse)
        show(customText, timeoutToUse)
    }

    timeout: 3000

    // WORKAROUND: Sometimes tooltip won't hide anymore
    // We use this to hide it after the same timeout
    onYChanged: hideTimer.stop()
    onTextChanged: hideTimer.stop()
    onVisibleChanged: {
        if (!visible) {
            hideTimer.stop()
        }
    }
    Timer {
        id: hideTimer

        function startTimer(_timeout) {
            // Add a bit more delay just because?
            interval = _timeout + 100
            restart()
        }

        onTriggered: tooltip.hide()
    }
}
