// ENH064 - Dynamic Cove
import QtQuick 2.12
import Lomiri.Components 1.3

Item {
    id: dynamicCOverItem

    property SwipeArea swipeArea
    property real swipeAreaWidth: 0
    property var mouseArea
    property var enableMouseArea: true
    property var secondaryMouseArea
    property real secondaryMouseAreaWidth: 0
    property bool enableSwipeArea: true
    property int swipeAreaDirection: SwipeArea.Vertical
}
