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
        , CustomURI
    }

    enum DisplayType {
        Default
        , Icon
        , CustomIcon
    }

    enum AnimationSpeed {
        Fast
        , Brisk
        , Snap
    }

    readonly property bool actionsShown: directActionsItems.visible
    property bool noSwipeCommit: false
    property real preferredActionItemWidthPhysical: shell.convertFromInch(0.35)
    property real preferredActionItemWidth: units.gu(7)
    property real thresholdWidthForCentered: parent.width
    property alias swipeAreaHeight: swipeAreas.height
    property real swipeAreaWidth: units.gu(2)
    property bool swipeUsePhysicalSize: false
    property bool swipeDynamicPosition: false
    property bool swipeOffsetSelection: true
    property real maximumWidthPhysical: shell.convertFromInch(2.5)
    property real maximumWidth: parent.width
    property real sideMargins: units.gu(2)
    property bool enableVisualHint: true
    property int maximumColumn: 0
    property int swipeAreaSides: 0
    property var actionsList: []
    property int showHideAnimationSpeed: LPDirectActions.AnimationSpeed.Fast
    property bool editMode: false
    property int displayStyle: 0
    /*
     * 0 - Default
     * 1 - Circular
     * 2 - Rounded Square
    */

    signal appOrderChanged(var newAppOrderArray)

    function toggle(_fromLeft = false, _fromTop = false, _relativePoint = Qt.point(0, 0)) {
        // Allow showing and hiding in quick successions
        if (relativePositionShowAnimation.running) {
            relativePositionShowAnimation.stop()
            relativePositionHideAnimation.start()
            return
        }
        if (relativePositionHideAnimation.running) {
            relativePositionHideAnimation.stop()
            relativePositionShowAnimation.start()
            return
        }

        if (!directActionsItems.visible) {
            internal.openedViaToggle = true
            internal.relativePoint = _relativePoint
            directActionsItems.state = _fromLeft ? "left" : "right"
            state = _fromTop ? "top" : "bottom"
            internal.showWithoutSwipe = true
        } else {
            relativePositionHideAnimation.start()
        }
    }

    function openInEditMode(_fromLeft = false, _fromTop = false) {
        editMode = true
        toggle(_fromLeft, _fromTop, Qt.point(directActions.width / 2, directActions.height - units.gu(4)))
    }

    function arrMove(arr, oldIndex, newIndex) {
        if (newIndex >= arr.length) {
            let i = newIndex - arr.length + 1;
            while (i--) {
                arr.push(undefined);
            }
        }
        arr.splice(newIndex, 0, arr.splice(oldIndex, 1)[0]);
        return arr;
    }

    state: "bottom"
    states: [
        State {
            name: "bottom"
            AnchorChanges {
                target: directActionsItems
                anchors.bottom: parent.bottom
                anchors.top: undefined
            }
            PropertyChanges {
                target: directActionsItems
                anchors.bottomMargin: {
                    if (internal.shouldUseRelativePosition) {
                        let _thresholdMargin = directActionsItems.height + directActions.swipeAreaHeight
                        if (_thresholdMargin < internal.relativePoint.y) {
                            return directActions.height - internal.relativePoint.y
                        } else {
                            return directActions.height - _thresholdMargin
                        }
                    }

                    return directActionsItems.defaultVerticalMargin
                }
            }
        }
        , State {
            name: "top"
            AnchorChanges {
                target: directActionsItems
                anchors.bottom: undefined
                anchors.top: parent.top
            }
            PropertyChanges {
                target: directActionsItems
                anchors.topMargin: {
                    if (internal.shouldUseRelativePosition) {
                        let _thresholdMargin = directActions.height - directActionsItems.height - directActions.swipeAreaHeight
                        if (_thresholdMargin > internal.relativePoint.y) {
                            return internal.relativePoint.y
                        } else {
                            return _thresholdMargin
                        }
                    }

                    return directActionsItems.defaultVerticalMargin
                }
            }
        }
    ]

    QtObject {
        id: internal

        property bool openedViaToggle: false
        property bool openedViaSwipe: false
        property point relativePoint: Qt.point(0,0)
        readonly property bool shouldUseRelativePosition: relativePoint !== Qt.point(0, 0)
        property bool showWithoutSwipe: false
        readonly property real highlightMargin: 0
        readonly property real touchVerticalOffset: directActions.swipeDynamicPosition ? directActionsItems.defaultVerticalMargin : directActions.swipeAreaHeight
        readonly property real selectVerticalOffset: directActions.swipeOffsetSelection ? internal.preferredActionItemWidth : 0
        readonly property real mappedVerticalOffset: directActionsItems.defaultVerticalMargin - internal.selectVerticalOffset

        property var highlightedItem: {
            if (!directActions.noSwipeCommit && directActionsItems.isFullyShown) {
                let _mappedPos = Qt.point(-gridLayout.width,-gridLayout.height)

                if (leftSwipeArea.isDragging) {
                    _mappedPos = leftSwipeArea.mapToItem(gridLayout, leftSwipeArea.touchPosition.x, leftSwipeArea.touchPosition.y - touchVerticalOffset - highlightMargin)
                }

                if (rightSwipeArea.isDragging) {
                    _mappedPos = rightSwipeArea.mapToItem(gridLayout, rightSwipeArea.touchPosition.x, rightSwipeArea.touchPosition.y - touchVerticalOffset - highlightMargin)
                }

                let _mappedX = _mappedPos.x
                let _mappedY = _mappedPos.y - mappedVerticalOffset

                // When swipe exceeds on either side, we select the edge item instead
                if (_mappedX > gridLayout.width) {
                    _mappedX = gridLayout.width - 1
                }

                if (_mappedX < 0) {
                    _mappedX = 1
                }

                if (_mappedY > gridLayout.height) {
                    _mappedY = gridLayout.height - 1
                }

                let _found = gridLayout.childAt(_mappedX, _mappedY)
                return _found
            }

            return null
        }
        property bool usePhysicalSize: false
        property real preferredActionItemWidth: usePhysicalSize ? directActions.preferredActionItemWidthPhysical : directActions.preferredActionItemWidth
        property real maximumWidth: usePhysicalSize ? directActions.maximumWidthPhysical : directActions.maximumWidth
        
        onHighlightedItemChanged: {
            titleRec.targetItem = highlightedItem
            if (titleRec.targetItem) {
                delayShow.restart()
            } else {
                if (titleRec.targetItem === null) {
                    delayShow.stop()
                    titleRec.show = false
                }
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
        opacity: directActionsItems.opacity * 0.6
    }

    Component {
        id: visualHintComponent

        Rectangle {
            color: LomiriColors.porcelain
            radius: width * 0.5
            border {
                width: units.dp(1)
                color: LomiriColors.silk
            }
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

        onIsDraggingChanged: {
            if (isDragging) {
                directActions.state = "bottom"
                if (noSwipeCommit) {
                    internal.showWithoutSwipe = true
                }
            }
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

            onPressedChanged: {
                if (pressed && directActions.swipeDynamicPosition) {
                    directActionsItems.swipeVerticalMargin = height - touchPosition.y + internal.selectVerticalOffset
                }
            }
            onDraggingChanged: {
                if (!dragging && internal.highlightedItem && !directActions.noSwipeCommit) {
                    internal.highlightedItem.trigger()
                    shell.haptics.play()
                }
            }

            Loader {
                active: directActions.enableVisualHint && leftSwipeArea.enabled
                asynchronous: true
                sourceComponent: visualHintComponent
                width: units.gu(2)
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                    leftMargin: item ? -item.radius : 0
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

            onPressedChanged: {
                if (pressed && directActions.swipeDynamicPosition) {
                    directActionsItems.swipeVerticalMargin = height - touchPosition.y + internal.selectVerticalOffset
                }
            }
            onDraggingChanged: {
                if (!dragging && internal.highlightedItem && !directActions.noSwipeCommit) {
                    internal.highlightedItem.trigger()
                    shell.haptics.play()
                }
            }

            Loader {
                active: directActions.enableVisualHint && rightSwipeArea.enabled
                asynchronous: true
                sourceComponent: visualHintComponent
                width: units.gu(2)
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                    rightMargin: item ? -item.radius : 0
                }
            }
        }
    }

    Item {
        id: directActionsItems
        
        readonly property bool shouldBeShown: swipeAreas.isDragging || internal.showWithoutSwipe
        readonly property real defaultSideMargin: shouldBeShown || internal.openedViaToggle
                                                            ? internal.openedViaSwipe ? directActions.sideMargins : units.gu(2)
                                                            : -width
        readonly property real defaultVerticalMargin: {
            if (!internal.openedViaSwipe) {
                return units.gu(4)
            }

            if (directActions.swipeDynamicPosition) {
                return swipeVerticalMargin
            }

            return directActions.swipeAreaHeight
        }
        property real swipeVerticalMargin: 0
        readonly property bool isFullyShown: (!internal.openedViaToggle && anchors.leftMargin === defaultSideMargin)
                                                || (!relativePositionShowAnimation.running && opacity === 1)

        property bool delayedAnimation: false
        property real relativePosAnimationScale: 1

        anchors {
            bottom: parent.bottom
            topMargin: defaultVerticalMargin
            bottomMargin: defaultVerticalMargin
            leftMargin: defaultSideMargin
            rightMargin: defaultSideMargin
        }
        height: gridLayout.height
        width: parent.width > directActions.thresholdWidthForCentered ? internal.maximumWidth - directActions.sideMargins : parent.width - (directActions.sideMargins * 2)
        visible: opacity > 0
        opacity: shouldBeShown && !relativePositionHideAnimation.running ? 1 : 0

        Behavior on opacity {
            LomiriNumberAnimation {
                duration: relativePositionShowAnimation.duration
            }
        }
        Behavior on anchors.leftMargin {
            enabled: !internal.openedViaToggle
            LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
        }
        Behavior on anchors.rightMargin {
            enabled: !internal.openedViaToggle
            LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
        }
        
        NumberAnimation {
            id: relativePositionShowAnimation
            property: "relativePosAnimationScale"
            to: 1
            target: directActionsItems
            easing: LomiriAnimation.StandardEasing
            duration: {
                switch (directActions.showHideAnimationSpeed) {
                    case LPDirectActions.AnimationSpeed.Brisk:
                        return LomiriAnimation.BriskDuration
                    case LPDirectActions.AnimationSpeed.Snap:
                        return LomiriAnimation.SnapDuration
                    default:
                        return LomiriAnimation.FastDuration
                }
            }
        }

        NumberAnimation {
            id: relativePositionHideAnimation
            property: "relativePosAnimationScale"
            to: 0
            target: directActionsItems
            easing: LomiriAnimation.StandardEasing
            duration: relativePositionShowAnimation.duration
            onFinished: internal.showWithoutSwipe = false
        }

        transform: Scale {
            origin.x: {
                if (internal.shouldUseRelativePosition) {
                    if (directActionsItems.state === "left") {
                        let _thresholdMargin = directActions.width - directActionsItems.width - directActionsItems.defaultSideMargin
                        if (_thresholdMargin > internal.relativePoint.x) {
                            return 0
                        } else {
                            return Math.abs(directActionsItems.x - internal.relativePoint.x)
                        }
                    } else {
                        let _thresholdMargin = directActionsItems.width + directActionsItems.defaultSideMargin
                        if (_thresholdMargin < internal.relativePoint.x) {
                            return directActionsItems.width
                        } else {
                            return internal.relativePoint.x - directActionsItems.defaultSideMargin
                        }
                    } 
                } else {
                    return directActionsItems.state === "left" ? 0 : directActionsItems.width
                }

                return width / 2
            }
            origin.y: {
                if (internal.shouldUseRelativePosition) {
                    if (directActions.state === "top") {
                        let _thresholdMargin = directActions.height - directActionsItems.height - directActions.swipeAreaHeight
                        if (_thresholdMargin > internal.relativePoint.y) {
                            return 0
                        } else {
                            return Math.abs(directActionsItems.y - internal.relativePoint.y)
                        }
                    } else {
                        let _thresholdMargin = directActionsItems.height + directActions.swipeAreaHeight
                        if (_thresholdMargin < internal.relativePoint.y) {
                            return directActionsItems.height
                        } else {
                            return internal.relativePoint.y - directActions.swipeAreaHeight
                        }
                    } 
                } else {
                    return directActions.state === "top" ? 0 : directActionsItems.height
                }

                return height / 2
            }

            xScale: directActionsItems.relativePosAnimationScale
            yScale: directActionsItems.relativePosAnimationScale
        }

        onVisibleChanged: {
            if (visible) {
                // These make sure changes in sizes and positions won't change until it is completely hidden
                if (swipeAreas.isDragging) {
                    if (directActions.swipeUsePhysicalSize) {
                        internal.usePhysicalSize = true
                    }

                    internal.openedViaSwipe = true
                }
                relativePosAnimationScale = 0

                if (leftSwipeArea.isDragging) {
                    directActionsItems.state = "left"
                }
                if (rightSwipeArea.isDragging) {
                    directActionsItems.state = "right"
                }

                if (internal.openedViaToggle && !relativePositionShowAnimation.running) {
                    relativePositionShowAnimation.start()
                } else {
                    relativePosAnimationScale = 1
                }
            } else {
                internal.relativePoint = Qt.point(0, 0)
                internal.openedViaToggle = false
                directActions.editMode = false
                internal.usePhysicalSize = false
                internal.openedViaSwipe = false
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
                    target: directActionsItems
                    anchors.leftMargin: {
                        if (internal.shouldUseRelativePosition) {
                            let _thresholdMargin = directActions.width - directActionsItems.width - directActionsItems.defaultSideMargin
                            if (_thresholdMargin > internal.relativePoint.x) {
                                return internal.relativePoint.x
                            } else {
                                return _thresholdMargin
                            }
                        }

                        return directActionsItems.defaultSideMargin
                    }
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
                    target: directActionsItems
                    anchors.rightMargin: {
                        if (internal.shouldUseRelativePosition) {
                            let _thresholdMargin = directActionsItems.width + directActionsItems.defaultSideMargin
                            if (_thresholdMargin < internal.relativePoint.x) {
                                return directActions.width - internal.relativePoint.x
                            } else {
                                return directActions.width - _thresholdMargin
                            }
                        }

                        return directActionsItems.defaultSideMargin
                    }
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
            property Item targetItem
            readonly property point mappedHighlightedItemPos: targetItem ? targetItem.mapToItem(directActionsItems, 0, 0) : Qt.point(0, 0)
            readonly property real intendedX: targetItem ? mappedHighlightedItemPos.x - (width / 2) + ((targetItem.width) / 2) : 0

            z: gridLayout.z + 1
            x: {
                if (intendedX + directActionsItems.x < 0) {
                    return -directActionsItems.x
                }

                if (intendedX + width + directActionsItems.x > directActions.width) {
                    return directActions.width - width - directActionsItems.x -  + units.gu(2)
                }

                return intendedX
            }
            y: targetItem ? mappedHighlightedItemPos.y - (height + units.gu(1)) : 0
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
                    text: titleRec.targetItem ? titleRec.targetItem.itemTitle : ""
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

            columns: Math.min(maxColumn, Math.floor(width / internal.preferredActionItemWidth))
            columnSpacing: 0
            rowSpacing: 0
            LayoutMirroring.enabled: rotation == 180
            rotation: directActions.state == "bottom" ? 180 : 0

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: units.gu(1)
            }

            Repeater {
                id: indicatorSwipeRepeater

                model: directActions.actionsList

                delegate: Item {
                    id: itemContainer

                    Layout.fillWidth: true
                    Layout.preferredHeight: internal.preferredActionItemWidth

                    readonly property string itemDragId: itemDelegate.itemId + " - " + itemDelegate.type
                    property var itemData: modelData
                    property int itemIndex: index
                    property alias itemTitle: itemDelegate.itemTitle

                    z: itemDelegate.highlighted ? 2 : 1

                    rotation: gridLayout.rotation

                    function trigger() {
                        itemDelegate.trigger()
                    }

                    LPDirectActionsDelegate {
                        id: itemDelegate

                        readonly property Timer hoverCheckTimer: Timer {
                            interval: 1
                            onTriggered: {
                                if (titleRec.targetItem === itemDelegate) {
                                    titleRec.targetItem = null
                                    delayShow.stop()
                                    titleRec.show = false
                                }
                            }
                        }
                        readonly property Timer delayedAnimationTimer: Timer {
                            interval: 200
                            onTriggered: {
                                if (internal.openedViaToggle) {
                                    directActions.toggle()
                                } else {
                                    internal.showWithoutSwipe = false
                                }
                            }
                        }

                        x: 0
                        y: 0
                        width: parent.width
                        height: parent.height
                        itemId: itemContainer.itemData.actionId
                        type: itemContainer.itemData.type
                        displayType: itemContainer.itemData.displayType ? itemContainer.itemData.displayType : LPDirectActions.DisplayType.Default
                        itemIconName: itemContainer.itemData.iconName ? itemContainer.itemData.iconName : ""
                        itemCustomTitle: itemContainer.itemData.customTitle ? itemContainer.itemData.customTitle : ""
                        editMode: directActions.editMode
                        highlighted: internal.highlightedItem == itemContainer
                        maximumSize: height * 0.8
                        highlightScale: gridLayout.highlightScale
                        displayedTop: directActions.state == "top"
                        displayedLeft: directActionsItems.state == "left"
                        mouseHoverEnabled: !swipeAreas.isDragging
                        enableHaptics: internal.openedViaSwipe
                        displayStyle: directActions.displayStyle
                        
                        states: [
                            State {
                                name: "active"; when: mouseDragArea.activeId == itemContainer.itemDragId
                                PropertyChanges {
                                    target: itemDelegate;
                                    x: gridLayout.rotation === 180 ? mouseDragArea.mouseX - parent.x - width / 2 : mouseDragArea.mouseX - parent.x - width / 2
                                    y: mouseDragArea.mouseY - parent.y - height - units.gu(3)
                                }
                                PropertyChanges {target: itemContainer; z: 10}
                            }
                        ]

                        Behavior on x {
                            LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
                        }
                        Behavior on y {
                            LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
                        }

                        onTrigger: {
                            if (internal.showWithoutSwipe) {
                                delayedAnimationTimer.restart()
                            }
                        }

                        onIsHoveredChanged: {
                            if (!swipeAreas.isDragging) {
                                if (isHovered) {
                                    hoverCheckTimer.stop()
                                    titleRec.targetItem = this
                                    delayShow.restart()
                                } else {
                                    // Delay checking removable of hoevred item
                                    // to handle hovering nothing and moving
                                    // the hover to another item
                                    hoverCheckTimer.restart()
                                }
                            }
                        }

                        onEnterEditMode: directActions.editMode = true
                        onExitEditMode: directActions.editMode = false
                    }
                }
            }
        }

        MouseArea {
            id: mouseDragArea

            property var currentItem: gridLayout.childAt(mouseX, mouseY) //item underneath cursor
            property int index: currentItem ? currentItem.itemIndex : -1 //item underneath cursor
            property string activeId: "" // app Id of active item
            property int activeIndex: -1 //current position of active item
            readonly property bool isDragActive: activeId !== ""

            visible: enabled
            enabled: directActions.editMode
            anchors.fill: gridLayout
            hoverEnabled: true
            propagateComposedEvents: true
            rotation: gridLayout.rotation

            onWheel: wheel.accepted = true
            onPressAndHold: {
                if (currentItem) {
                    activeIndex = index
                    activeId = currentItem.itemDragId
                } else {
                    directActions.editMode = !directActions.editMode
                }
                shell.haptics.play()
            }
            onReleased: {
                activeId = ""
                activeIndex = -1
                directActions.appOrderChanged(indicatorSwipeRepeater.model)
                indicatorSwipeRepeater.model = Qt.binding( function () { return directActions.actionsList } )
            }
            onPositionChanged: {
                if (activeId != "" && index != -1 && index != activeIndex) {
                    indicatorSwipeRepeater.model = directActions.arrMove(indicatorSwipeRepeater.model, activeIndex, activeIndex = index)
                    shell.haptics.playSubtle()
                }
            }
        }

        InverseMouseArea {
            anchors.fill: parent
            visible: internal.showWithoutSwipe
            enabled: visible
            onClicked: {
                if (directActions.editMode) {
                    directActions.editMode = false
                } else {
                    if (internal.openedViaToggle) {
                        directActions.toggle()
                    } else {
                        internal.showWithoutSwipe = false
                    }
                }
            }
        }
    }
}
