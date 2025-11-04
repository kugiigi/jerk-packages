import QtQuick 2.12
import Lomiri.Components 1.3

SwipeArea {
    id: swipeHeaderRevert

    property LPHeader pageHeader

    enabled: pageHeader.expanded
    immediateRecognition: false
    grabGesture: true
    direction: SwipeArea.Upwards

    onDraggingChanged: {
        if (!dragging && pageHeader.expanded && pageHeader.height <= pageHeader.maxHeight - pageHeader.expansionThreshold * 2) {
            pageHeader.expanded = false
        }
    }

    onDistanceChanged: {
        if (dragging && pageHeader.height > pageHeader.defaultHeight
                && pageHeader.height <= pageHeader.maxHeight
            ) {

            let newValue = pageHeader.maxHeight - distance

            switch (true) {
                case newValue <= pageHeader.defaultHeight:
                    pageHeader.height = pageHeader.defaultHeight
                    break
                case newValue >= pageHeader.maxHeight:
                    pageHeader.height = pageHeader.maxHeight
                    break
                default:
                    pageHeader.height = newValue
                    break
            }
        }
    }
}
