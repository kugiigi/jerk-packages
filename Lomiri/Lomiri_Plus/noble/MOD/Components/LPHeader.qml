import QtQuick 2.12
import Lomiri.Components 1.3

Item {
    id: lpHeader

    property real defaultHeight: units.gu(6)
    property real maxHeight:  parent.height * 0.4
    readonly property real expansionThreshold: maxHeight * 0.10

    property bool expandable: true
    property bool expanded: false

    implicitHeight: defaultHeight

    function resetHeight() {
        if (expanded) {
            expandAnimation.restart()
        } else {
            collapseAnimation.restart()
        }
    }

    function expand() {
        if (expandable) {
            expanded = true
        }
    }

    function collapse() {
        expanded = false
    }

    onExpandableChanged: if (!expandable) expanded = false
    onExpandedChanged: {
        if (expanded) {
            expandAnimation.restart()
        } else {
            collapseAnimation.restart()
        }
    }

    LomiriNumberAnimation on height {
        id: expandAnimation

        running: false
        to: maxHeight
        duration: LomiriAnimation.SnapDuration
    }

    LomiriNumberAnimation on height {
        id: collapseAnimation

        running: false
        to: defaultHeight
        duration: LomiriAnimation.SnapDuration
    }
}
