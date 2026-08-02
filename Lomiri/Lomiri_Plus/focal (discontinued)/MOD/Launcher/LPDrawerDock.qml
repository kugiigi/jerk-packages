// ENH105 - Custom app drawer
import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.3 as ListItems
import QtQuick.Layouts 1.12
import "../Components" as Components

Item {
    id: bottomDock

    readonly property real swipeThreshold: units.gu(5)
    property real verticalPadding: units.gu(4)
    readonly property real horizontalPadding: isIntegratedDock ? 0 : units.gu(0.5)
    readonly property alias rowHeight: dockedAppGrid.rowHeight
    property bool shown: false
    property bool inverted: false
    property bool isIntegratedDock: false
    property bool editMode: false
    property bool showThinDivider: false
    readonly property bool appDragIsActive: editMode && gridArea.isDragActive
    property bool expanded: false
    property bool expandingFinished: false
    property real availableHeight: units.gu(60)
    property real delegateHeight: units.gu(10)
    property real delegateWidth: units.gu(10)
    property var rawModel
    property var appModel
    property var contextMenuItem: null
    property bool hideLabel: false
    property alias columns: gridLayout.columns
    property int currentIndex: -1
    // ENH132 - App drawer icon size settings
    property real delegateSizeMultiplier: 1
    // ENH132 - End

    signal applicationSelected(string appId)
    signal applicationContextMenu(string appId, var caller)
    signal appOrderChanged(var newAppOrderArray)

    function getAppItem(_appId) {
        for (var i = 0; i < rawModel.rowCount(); ++i) {
            let _modelIndex = rawModel.index(i, 0)
            let _currentAppId = rawModel.data(_modelIndex, 0)

            if (_currentAppId == _appId) {
                let _currentAppName = rawModel.data(_modelIndex, 1)
                let _currentAppIcon = rawModel.data(_modelIndex, 2)

                return {"name": _currentAppName, "icon": _currentAppIcon }
            }
        }
        return null
    }

    height: shown ? dockedAppGrid.height : 0
    visible: shown

    onShownChanged: {
        if (!shown) {
            expanded = false
        }
    }

    onExpandedChanged: if (!expanded) drawerDockFlickable.reset()

    Loader {
        active: showThinDivider
        asynchronous: true
        height: units.dp(2)
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
        }
        sourceComponent: ListItems.ThinDivider {
            id: divider

            state: "normal"
            states: [
                State {
                    name: "normal"
                    when: !bottomDock.inverted
                    AnchorChanges {
                        target: divider
                        anchors.top: undefined
                        anchors.bottom: parent.bottom
                    }
                }
                , State {
                    name: "inverted"
                    when: bottomDock.inverted
                    AnchorChanges {
                        target: divider
                        anchors.top: parent.top
                        anchors.bottom: undefined
                    }
                }
            ]
        }
    }

    Rectangle {
        id: bg
        color: theme.palette.normal.foreground
        opacity: bottomDock.expanded ? 1 : 0.6
        visible: !bottomDock.isIntegratedDock
        radius: units.gu(3)
        anchors {
            fill: parent
            topMargin: dockedAppGrid.anchors.verticalCenterOffset
        }

        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }
    }

    Icon {
        z: wheelMouseArea.z + 1
        visible: dockedAppGrid.multiRows && !bottomDock.editMode && !bottomDock.isIntegratedDock
        name: bottomDock.expanded ? "down" : "up"
        height: units.gu(1.5)
        width: height
        color: theme.palette.normal.backgroundText
        asynchronous: true
        anchors {
            top: bg.top
            horizontalCenter: parent.horizontalCenter
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: bottomDock.expanded = !bottomDock.expanded
        }
    }

    MouseArea {
        id: wheelMouseArea
        z: dockedAppGrid.z + 1
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onWheel: {
            let _deltaY = wheel.angleDelta.y
            if (_deltaY >= 120) {
                bottomDock.expanded = true
            } else if (_deltaY <= -120) {
                bottomDock.expanded = false
            }
            wheel.accepted = true;
        }
    }

    MouseArea {
        id: dockedAppGrid

        readonly property real toggleHeight: bottomDock.delegateHeight
        readonly property real rowHeight: bottomDock.delegateHeight
        readonly property real rowMargins: 0
        readonly property bool multiRows: rowHeight + rowMargins !== gridLayout.height + rowMargins
        readonly property real expandedHeight: Math.min(gridLayout.height + rowMargins + bottomDock.verticalPadding / 2, maxHeight)
        readonly property real collapsedHeight: rowHeight + rowMargins + bottomDock.verticalPadding / 2
        readonly property real availableHeight: bottomDock.availableHeight - bottomDock.verticalPadding
        readonly property real maxHeightFromSettings: shell.convertFromInch(shell.settings.drawerDockMaxHeight)
        readonly property real maxHeight: shell.settings.enableMaxHeightInDrawerDock ?  Math.min(maxHeightFromSettings, availableHeight) : availableHeight

        z: 2
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        clip: !bottomDock.editMode

        height: {
            if (bottomDock.isIntegratedDock) return gridLayout.height + rowMargins + bottomDock.verticalPadding / 2

            if (swipeArea.dragging) {
                let _height = expanded ? expandedHeight - swipeArea.distance : collapsedHeight + swipeArea.distance
                let _defaultHeight = expanded ? expandedHeight : collapsedHeight

                if (_height <= expandedHeight && _height >= collapsedHeight) {
                    return _height
                } else if (_height > expandedHeight) {
                    return expandedHeight
                } else if (_height < collapsedHeight) {
                    return collapsedHeight
                } else {
                    return _defaultHeight
                }
            }
            if (drawerDockFlickable.interactive && drawerDockFlickable.verticalOvershoot < 0) {
                let _height = expandedHeight + drawerDockFlickable.verticalOvershoot
                let _defaultHeight = expandedHeight

                if (_height <= expandedHeight && _height >= collapsedHeight) {
                    return _height
                } else if (_height > expandedHeight) {
                    return expandedHeight
                } else if (_height < collapsedHeight) {
                    return collapsedHeight
                } else {
                    return _defaultHeight
                }
            }

            if (bottomDock.expanded || bottomDock.editMode) {
                return expandedHeight
            } else {
                return collapsedHeight
            }
        }
        onHeightChanged: {
            if (height == gridLayout.height + rowMargins) {
                bottomDock.expandingFinished = true
            } else {
                bottomDock.expandingFinished = false
            }
        }
        anchors {
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: -(bottomDock.verticalPadding / 4)
            left: parent.left
            right: parent.right
        }

        Behavior on height {
            enabled: !bottomDock.isIntegratedDock
            LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
        }

        onClicked: mouse.accepted = true

        onPressAndHold: {
            bottomDock.editMode = !bottomDock.editMode
            shell.haptics.playSubtle()
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

        Flickable {
            id: drawerDockFlickable

            anchors.fill: parent
            bottomMargin: units.gu(1)
            boundsBehavior: Flickable.DragOverBounds
            boundsMovement: Flickable.StopAtBounds
            contentHeight: gridLayout.height
            interactive: bottomDock.expanded && contentHeight > dockedAppGrid.maxHeight && !gridArea.isDragActive

            function reset() {
                contentY = 0
            }

            onDraggingChanged: {
                if (!dragging && verticalOvershoot <= -bottomDock.swipeThreshold) {
                    bottomDock.expanded = false
                }
            }

            GridLayout  {
                id: gridLayout

                columnSpacing: 0
                rowSpacing: 0
                LayoutMirroring.enabled: rotation == 180
                rotation: bottomDock.isIntegratedDock && bottomDock.inverted ? 180 : 0

                anchors {
                    top: parent.top
                    topMargin: bottomDock.verticalPadding / 2
                    left: parent.left
                    right: parent.right
                    leftMargin: bottomDock.horizontalPadding
                    rightMargin: bottomDock.horizontalPadding
                }

                Repeater {
                    id: appsRepeater

                    model: bottomDock.appModel

                    delegate: Item {
                        id: itemContainer

                        property var appData: modelData ? bottomDock.getAppItem(modelData) : null
                        property string appId: modelData
                        property int itemIndex: index

                        Layout.fillWidth: true
                        Layout.preferredHeight: dockedAppGrid.rowHeight
                        // Very slow when rotating and toggling
                        //Layout.preferredHeight: bottomDock.hideLabel && bottomDock.isIntegratedDock ? width : dockedAppGrid.rowHeight
                        // Slightly slow when rotating and toggling but not sure if it's actually square
                        //Layout.preferredHeight: bottomDock.hideLabel && bottomDock.isIntegratedDock ? bottomDock.delegateWidth : dockedAppGrid.rowHeight

                        rotation: gridLayout.rotation

                        Connections {
                            target: bottomDock.rawModel
                            onRefreshingChanged: {
                                if (!target.refreshing) {
                                    itemContainer.appData = Qt.binding( function() { return itemContainer.appId ? bottomDock.getAppItem(itemContainer.appId) : null } )
                                }
                            }
                        }

                        LPDrawerAppDelegate {
                            id: toggleContainer

                            focused: (bottomDock.contextMenuItem && bottomDock.contextMenuItem.appId == itemContainer.appId
                                            && (
                                                    (!bottomDock.isIntegratedDock && bottomDock.contextMenuItem.fromDocked)
                                                    ||
                                                    (bottomDock.isIntegratedDock && bottomDock.contextMenuItem.fromCustomAppGrid)
                                                )
                                     )
                                     ||
                                     itemContainer.itemIndex == bottomDock.currentIndex
                            objectName: "drawerDockItem_" + itemContainer.appId
                            delegateWidth: bottomDock.delegateWidth
                            appId: itemContainer.appId
                            appName: itemContainer.appData ? itemContainer.appData.name : itemContainer.appId
                            iconSource: itemContainer.appData ? itemContainer.appData.icon : ""
                            x: 0
                            y: 0
                            width: parent.width
                            height: parent.height
                            editMode: bottomDock.editMode
                            hideLabel: bottomDock.hideLabel
                            // ENH132 - App drawer icon size settings
                            delegateSizeMultiplier: bottomDock.delegateSizeMultiplier
                            // ENH132 - End

                            states: [
                                State {
                                    name: "active"; when: gridArea.activeId == itemContainer.appId
                                    PropertyChanges {target: toggleContainer; x: gridArea.mouseX - parent.x - width / 2; y: gridArea.mouseY - parent.y - height - units.gu(3); z: 10}
                                }
                            ]
                            
                            Behavior on x {
                                LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
                            }
                            Behavior on y {
                                LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
                            }

                            onApplicationSelected: {
                                if (!editMode) {
                                    bottomDock.applicationSelected(appId)
                                } else {
                                    bottomDock.editMode = false
                                }
                            }

                            onApplicationContextMenu: bottomDock.applicationContextMenu(appId, this)
                        }
                    }
                }
            }

            MouseArea {
                id: gridArea

                property var currentItem: gridLayout.childAt(mouseX, mouseY) //item underneath cursor
                // For offset to the top
                //property var currentItem: isDragActive ? gridLayout.childAt(mouseX, mouseY - dockedAppGrid.toggleHeight) : gridLayout.childAt(mouseX, mouseY) //item underneath cursor
                property int index: currentItem ? currentItem.itemIndex : -1 //item underneath cursor
                property string activeId: "" // app Id of active item
                property int activeIndex: -1 //current position of active item
                readonly property bool isDragActive: activeId !== ""

                enabled: bottomDock.editMode
                anchors.fill: gridLayout
                hoverEnabled: true
                propagateComposedEvents: true
                rotation: gridLayout.rotation

                onWheel: wheel.accepted = true
                onPressAndHold: {
                    if (currentItem) {
                        activeIndex = index
                        activeId = currentItem.appId
                    } else {
                        bottomDock.editMode = !bottomDock.editMode
                    }
                    shell.haptics.play()
                }
                onReleased: {
                    activeId = ""
                    activeIndex = -1
                    bottomDock.appOrderChanged(appsRepeater.model)
                    appsRepeater.model = Qt.binding( function () { return bottomDock.appModel } )
                }
                onPositionChanged: {
                    if (activeId != "" && index != -1 && index != activeIndex) {
                        appsRepeater.model = dockedAppGrid.arrMove(appsRepeater.model, activeIndex, activeIndex = index)
                        shell.haptics.playSubtle()
                    }
                }
            }
        }

        Components.LPSwipeGestureHandler {
            id: swipeArea

            enabled: !bottomDock.editMode && !bottomDock.isIntegratedDock && !drawerDockFlickable.interactive
            anchors.fill: parent
            immediateRecognition: false
            direction: bottomDock.expanded ? SwipeArea.Downwards : SwipeArea.Upwards
            onDraggingChanged: {
                if (!dragging && towardsDirection && distance >= bottomDock.swipeThreshold) {
                    bottomDock.expanded = !bottomDock.expanded
                }
            }
        }
    }
}
