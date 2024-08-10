import QtQuick 2.12
import Lomiri.Components 1.3

Flickable {
    id: baseFlickable

    property LPHeader pageHeader

    boundsBehavior: Flickable.DragOverBounds
    boundsMovement: Flickable.StopAtBounds
    maximumFlickVelocity: units.gu(600)

    LPPullDownFlickableConnections {
        pageHeader: baseFlickable.pageHeader
        target: baseFlickable
    }
}
