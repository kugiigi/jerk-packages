import QtQuick 2.9
import Lomiri.Components 1.3

Icon {
    id: swipeIndicator

    property string iconName
    property real dragDistance
    property bool enabled: true
    property bool heldState: false
    property real defaultWidth: units.gu(1)
    property real expandedWidth: units.gu(3)

    visible: opacity > 0
    opacity: 0
    name: iconName
    color: heldState ? theme.palette.normal.activity : theme.palette.normal.foregroundText
    width: defaultWidth
    height: width

    function show() {
        opacity = enabled ? 1 : 0.2
        width = Qt.binding( function() { return defaultWidth + (Math.min(dragDistance != 0 ? Math.abs(dragDistance) : 0), expandedWidth) } )
    }

    function hide() {
        opacity = 0
        width = defaultWidth
        heldState = false
    }

    Behavior on width {
        SpringAnimation { spring: 2; damping: 0.2 }
    }

    Behavior on opacity {
        LomiriNumberAnimation {
            duration: LomiriAnimation.FastDuration
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: LomiriAnimation.FastDuration
        }
    }
}
