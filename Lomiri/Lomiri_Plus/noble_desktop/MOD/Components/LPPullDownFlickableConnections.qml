import QtQuick 2.12

Connections {
    property LPHeader pageHeader

    enabled: pageHeader && pageHeader.expandable ? true : false
    
    onVerticalOvershootChanged: {
        if (target.dragging) {
            if (target.verticalOvershoot < 0 && pageHeader.expandable) {
                if (pageHeader.height < pageHeader.maxHeight) {
                    pageHeader.height = pageHeader.defaultHeight - target.verticalOvershoot
                }
            } else if (pageHeader.expanded) {
                if (pageHeader.height > pageHeader.defaultHeight) {
                    pageHeader.height = pageHeader.maxHeight - target.verticalOvershoot
                }
            }
        }
    }

    onDraggingChanged: {
        if (!target.dragging) {
            if (!pageHeader.expanded && pageHeader.height >= pageHeader.defaultHeight + pageHeader.expansionThreshold) {
                pageHeader.expanded = true
            } else if (pageHeader.expanded && pageHeader.height <= pageHeader.maxHeight - pageHeader.expansionThreshold) {
                pageHeader.expanded = false
            } else {
                pageHeader.resetHeight()
            }
        }
    }

    onContentYChanged: {
        if (pageHeader.expanded && !target.dragging) {
            if (pageHeader.height >= pageHeader.defaultHeight) {
                pageHeader.height = pageHeader.maxHeight - target.contentY
            }

            if (pageHeader.height <= pageHeader.maxHeight - pageHeader.expansionThreshold) {
                pageHeader.expanded = false
            }
        }
    }
}
