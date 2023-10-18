import QtQuick 2.12

Item {
    id: roundMouseArea

    property alias mouseX: mouseArea.mouseX
    property alias mouseY: mouseArea.mouseY
    property alias enabled: mouseArea.enabled
    property alias propagateComposedEvents: mouseArea.propagateComposedEvents
    property alias containsPress: mouseArea.containsPress
    property alias hoverEnabled: mouseArea.hoverEnabled

    property bool containsMouse: {
        containsMouseBind()
    }
    
    function containsMouseBind() {
        if (!mouseArea.containsMouse) return false;
        
        var x1 = width / 2;
        var y1 = height / 2;
        var x2 = mouseX;
        var y2 = mouseY;
        var distanceFromCenter = Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2);
        var radiusSquared = Math.pow(Math.min(width, height) / 2, 2);
        var isWithinOurRadius = distanceFromCenter < radiusSquared;
        return isWithinOurRadius;
    }

    readonly property bool nakapindot: containsMouse && mouseArea.pressed

    signal clicked
    signal doubleClicked
    signal pressAndHold
    signal pressed (var mouse)
    signal released
    signal positionChanged

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: {
            if (roundMouseArea.containsMouse) {
                roundMouseArea.clicked()
            } else {
                mouse.accepted = false
            }
        }
        onDoubleClicked: {
            if (roundMouseArea.containsMouse) {
                roundMouseArea.doubleClicked()
            } else {
                mouse.accepted = false
            }
        }
        onPressAndHold: {
            if (roundMouseArea.containsMouse) {
                roundMouseArea.pressAndHold()
            } else {
                mouse.accepted = false
            }
        }
        onPressed: {
            roundMouseArea.containsMouse = Qt.binding(function() { return containsMouseBind() })
            if (roundMouseArea.containsMouse) {
                roundMouseArea.pressed(mouse)
            } else {
                mouse.accepted = false
            }
        }
        onReleased: {
            if (roundMouseArea.containsMouse) {
                roundMouseArea.released()
            } else {
                mouse.accepted = false
            }
        }
        onPositionChanged: {
            if (roundMouseArea.containsMouse) {
                roundMouseArea.positionChanged()
            } else {
                mouse.accepted = false
            }
        }
    }
}
