// ENH139 - System Direct Actions
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12

Item {
    id: directActions

    enum Type {
        Indicator
        , App
        , Settings
        , Toggle
        , Custom
    }

    readonly property real preferredActionItemWidth: units.gu(7)
    property alias swipeAreaHeight: swipeAreas.height
    property real swipeAreaWidth: units.gu(2)
    property real maximumWidth: parent.width
    property real sideMargins: units.gu(2)
    property bool enableVisualHint: true
    property int maximumColumn: 0
    property int swipeAreaSides: 0
    property var actionsList: []

    QtObject {
        id: internal

        readonly property real highlightMargin: 0
        property var highlightedItem: {
            let _mappedPos = Qt.point(-gridLayout.width,-gridLayout.height)

            if (leftSwipeArea.isDragging) {
                _mappedPos = leftSwipeArea.mapToItem(gridLayout, leftSwipeArea.touchPosition.x, leftSwipeArea.touchPosition.y - swipeAreaHeight - highlightMargin)
            }

            if (rightSwipeArea.isDragging) {
                _mappedPos = rightSwipeArea.mapToItem(gridLayout, rightSwipeArea.touchPosition.x, rightSwipeArea.touchPosition.y - swipeAreaHeight - highlightMargin)
            }

            let _found = gridLayout.childAt(_mappedPos.x, _mappedPos.y)
            return _found
        }
        
        onHighlightedItemChanged: {
            if (highlightedItem) {
                delayShow.restart()
            } else {
                delayShow.stop()
                titleRec.show = false
            }
        }
    }

    // Eater mouse events
    MouseArea {
        enabled: swipeAreas.isDragging
        visible: enabled
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: directActionsItems.visible ? 0.6 : 0
        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }
    }

    Component {
        id: visualHintComponent

        Rectangle {
            color: theme.palette.normal.selection
            radius: width * 0.2
        }
    }

    Item {
        id: swipeAreas

        readonly property bool isDragging: leftSwipeArea.isDragging || rightSwipeArea.isDragging

        height: units.gu(5)
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        SwipeArea {
            id: leftSwipeArea

            property bool isDragging: dragging && distance >= directActions.sideMargins

            enabled: directActions.enabled && !rightSwipeArea.dragging
                        && (directActions.swipeAreaSides == 0 || directActions.swipeAreaSides == 1)
            direction: SwipeArea.Rightwards
            immediateRecognition: true
            width: directActions.swipeAreaWidth
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }

            onDraggingChanged: {
                if (!dragging && internal.highlightedItem) {
                    internal.highlightedItem.trigger()
                    shell.haptics.play()
                }
            }

            Loader {
                active: directActions.enableVisualHint && leftSwipeArea.enabled
                asynchronous: true
                sourceComponent: visualHintComponent
                width: parent.width * 2
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                }
            }
        }

        SwipeArea {
            id: rightSwipeArea

            property bool isDragging: dragging && distance >= directActions.sideMargins

            enabled: directActions.enabled && !leftSwipeArea.dragging
                        && (directActions.swipeAreaSides == 0 || directActions.swipeAreaSides == 2)
            direction: SwipeArea.Leftwards
            immediateRecognition: true
            width: directActions.swipeAreaWidth
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }

            onDraggingChanged: {
                if (!dragging && internal.highlightedItem) {
                    internal.highlightedItem.trigger()
                    shell.haptics.play()
                }
            }

            Loader {
                active: directActions.enableVisualHint && rightSwipeArea.enabled
                asynchronous: true
                sourceComponent: visualHintComponent
                width: parent.width * 2
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }
            }
        }
    }

    Item {
        id: directActionsItems
        
        anchors {
            bottom: parent.bottom
            bottomMargin: directActions.swipeAreaHeight
            leftMargin: swipeAreas.isDragging ? directActions.sideMargins : -width
            rightMargin: swipeAreas.isDragging ? directActions.sideMargins : -width
        }
        height: gridLayout.height
        width: Math.min(directActions.maximumWidth - directActions.sideMargins, parent.width - (directActions.sideMargins * 2))
        visible: opacity > 0
        opacity: swipeAreas.isDragging ? 1 : 0

        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }
        Behavior on anchors.leftMargin { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }
        Behavior on anchors.rightMargin { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }

        onVisibleChanged: {
            if (visible) {
                if (leftSwipeArea.isDragging) {
                    directActionsItems.state = "left"
                }
                if (rightSwipeArea.isDragging) {
                    directActionsItems.state = "right"
                }
            }
        }

        state: "left"
        states: [
            State {
                name: "left"
                AnchorChanges {
                    target: directActionsItems
                    anchors.left: parent.left
                    anchors.right: undefined
                }

                PropertyChanges {
                    target: gridLayout
                    layoutDirection: Qt.LeftToRight
                }
            }
            , State {
                name: "right"
                AnchorChanges {
                    target: directActionsItems
                    anchors.left: undefined
                    anchors.right: parent.right
                }

                PropertyChanges {
                    target: gridLayout
                    layoutDirection: Qt.RightToLeft
                }
            }
        ]

        Rectangle {
            id: titleRec

            property bool show
            readonly property point mappedHighlightedItemPos: internal.highlightedItem ? internal.highlightedItem.mapToItem(directActionsItems, 0, 0) : Qt.point(0, 0)
            readonly property real intendedX: internal.highlightedItem ? mappedHighlightedItemPos.x - (width / 2) + ((internal.highlightedItem.width * gridLayout.highlightScale) / 2) : 0

            z: gridLayout.z + 1
            x: {
                if (intendedX + directActionsItems.anchors.leftMargin < 0) {
                    return -directActionsItems.anchors.leftMargin
                }

                if (intendedX + width + directActionsItems.anchors.rightMargin > directActions.width) {
                    return directActions.width - width - directActionsItems.anchors.rightMargin -  + units.gu(2)
                }

                return intendedX
            }
            y: internal.highlightedItem ? mappedHighlightedItemPos.y - (height + units.gu(1)) : 0
            implicitWidth: rowLayout.width
            implicitHeight: rowLayout.height
            radius: height / 4
            color: theme.palette.highlighted.foreground
            opacity: show ? 1 : 0
            visible: opacity > 0 && x !==0 && y !== 0

            RowLayout {
                id: rowLayout

                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.bottomMargin: units.gu(0.5)
                    Layout.topMargin: units.gu(0.5)
                    Layout.leftMargin: units.gu(1)
                    Layout.rightMargin: units.gu(1)
                    textSize: Label.Large
                    color: theme.palette.highlighted.foregroundText
                    text: internal.highlightedItem ? internal.highlightedItem.itemTitle : ""
                }
            }

            Timer {
                id: delayShow
                interval: 400
                onTriggered: titleRec.show = true
            }

            Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.BriskDuration } }
        }

        GridLayout {
            id: gridLayout

            readonly property int maxColumn: directActions.maximumColumn > 0 ? directActions.maximumColumn : 99 // "Do not limit" column when set to 0
            property real highlightScale: 1.3

            columns: Math.min(maxColumn, Math.floor(width / directActions.preferredActionItemWidth))
            columnSpacing: 0
            rowSpacing: 0
            LayoutMirroring.enabled: rotation == 180
            rotation: 180

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: units.gu(1)
            }

            Repeater {
                id: indicatorSwipeRepeater

                model: directActions.actionsList

                delegate: LPDirectActionsDelegate {
                    id: itemDelegate

                    Layout.fillWidth: true
                    Layout.preferredHeight: directActions.preferredActionItemWidth

                    itemId: modelData.actionId
                    type: modelData.type
                    highlighted: internal.highlightedItem == itemDelegate
                    highlightScale: gridLayout.highlightScale
                    rotation: gridLayout.rotation
                }
            }
        }
    }
}
