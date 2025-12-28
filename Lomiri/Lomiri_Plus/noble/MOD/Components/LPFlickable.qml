import QtQuick 2.12
import Lomiri.Components 1.3

Flickable {
    id: baseFlickable

    property LPHeader pageHeader

    boundsBehavior: Flickable.DragOverBounds
    boundsMovement: Flickable.StopAtBounds
    maximumFlickVelocity: units.gu(600)

    function scrollToItem(item, topMargin=0,  bottomMargin=0, atTheTop=false) {
        let _mappedY = 0
        let _itemHeightY = 0
        let _currentViewport = 0
        let _intendedContentY = 0
        let _maxContentY = 0
        let _targetContentY = contentY

        _mappedY = item.mapToItem(baseFlickable.contentItem, 0, 0).y
        _itemHeightY = _mappedY + item.height
        _currentViewport = baseFlickable.contentY - baseFlickable.originY + baseFlickable.height - baseFlickable.bottomMargin + baseFlickable.topMargin

        if (_itemHeightY > _currentViewport) {
            _maxContentY = baseFlickable.contentHeight - baseFlickable.height + baseFlickable.bottomMargin
            _intendedContentY = _itemHeightY - baseFlickable.height + item.height + baseFlickable.bottomMargin + bottomMargin

            if (_intendedContentY > _maxContentY) {
                _targetContentY = _maxContentY
            } else {
                _targetContentY = _intendedContentY
            }
        } else if (_mappedY < baseFlickable.contentY) {
            _targetContentY = _mappedY - topMargin - baseFlickable.topMargin
        }

        if (atTheTop) {
            _targetContentY = _mappedY
        }

        scrollAnimation.startAnimation(_targetContentY)
    }

    LomiriNumberAnimation {
        id: scrollAnimation

        target: baseFlickable
        property: "contentY"
        duration: LomiriAnimation.FastDuration

        function startAnimation(targetContentY) {
            to = targetContentY
            restart()
        }
    }

    LPPullDownFlickableConnections {
        pageHeader: baseFlickable.pageHeader
        target: baseFlickable
    }
}
