// ENH105 - Custom app drawer
import QtQuick 2.12
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import QtQuick.Layouts 1.12

Item {
    id: bottomDock

    readonly property real verticalPadding: units.gu(4)
    readonly property real horizontalPadding: isIntegratedDock ? 0 : units.gu(1)
    readonly property alias rowHeight: dockedAppGrid.rowHeight
    property bool shown: false
    property bool inverted: false
    property bool isIntegratedDock: false
    property bool editMode: false
    property bool expanded: false
    property bool expandingFinished: false
    property real delegateHeight: units.gu(10)
    property real delegateWidth: units.gu(10)
    property var rawModel
    property var contextMenuItem: null

    signal applicationSelected(string appId)
    signal applicationContextMenu(string appId, var caller, bool fromDocked)

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

    height: shown ? dockedAppGrid.height + verticalPadding : 0
    visible: shown

    onShownChanged: {
        if (!shown) {
            expanded = false
        }
    }

    ListItems.ThinDivider {
        id: divider

        visible: bottomDock.isIntegratedDock
        height: units.dp(2)
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
        }
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

    Rectangle {
        id: bg
        color: theme.palette.normal.foreground
        opacity: bottomDock.expanded ? 1 : 0.6
        visible: !bottomDock.isIntegratedDock
        radius: units.gu(3)
        anchors.fill: parent
        Behavior on opacity { UbuntuNumberAnimation { duration: UbuntuAnimation.FastDuration } }
    }

    Icon {
        z: wheelMouseArea.z + 1
        visible: dockedAppGrid.multiRows && !bottomDock.editMode && !bottomDock.isIntegratedDock
        name: bottomDock.expanded ? "down" : "up"
        height: units.gu(1.5)
        width: height
        color: theme.palette.normal.backgroundText
        anchors {
            top: parent.top
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

        z: 2
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        clip: !bottomDock.editMode

        height: {
            if (bottomDock.isIntegratedDock || bottomDock.expanded || bottomDock.editMode) {
                return gridLayout.height + rowMargins
            } else {
                return rowHeight + rowMargins
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
            left: parent.left
            right: parent.right
        }

        Behavior on height { UbuntuNumberAnimation { duration: UbuntuAnimation.FastDuration } }

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

        GridLayout  {
            id: gridLayout

            columns: Math.floor(gridView.width / gridView.cellWidth)
            columnSpacing: 0
            rowSpacing: 0
            LayoutMirroring.enabled: rotation == 180
            rotation: bottomDock.isIntegratedDock && bottomDock.inverted ? 180 : 0

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                leftMargin: bottomDock.horizontalPadding
                rightMargin: bottomDock.horizontalPadding
            }

            Repeater {
                id: appsRepeater

                model: shell.settings.drawerDockApps

                delegate: Item {
                    id: itemContainer

                    property var appData: modelData ? bottomDock.getAppItem(modelData) : null
                    property string appId: modelData
                    property int itemIndex: index

                    Layout.fillWidth: true
                    Layout.preferredHeight: dockedAppGrid.rowHeight

                    rotation: gridLayout.rotation

                    Connections {
                        target: bottomDock.rawModel
                        onRefreshingChanged: {
                            if (!refreshing) {
                                itemContainer.appData = Qt.binding( function() { return itemContainer.appId ? bottomDock.getAppItem(itemContainer.appId) : null } )
                            }
                        }
                    }

                    LPDrawerAppDelegate {
                        id: toggleContainer

                        focused: bottomDock.contextMenuItem && bottomDock.contextMenuItem.appId == itemContainer.appId && bottomDock.contextMenuItem.fromDocked
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

                        states: [
                            State {
                                name: "active"; when: gridArea.activeId == itemContainer.appId
                                PropertyChanges {target: toggleContainer; x: gridArea.mouseX - parent.x - width / 2; y: gridArea.mouseY - parent.y - height - units.gu(3); z: 10}
                            }
                        ]
                        
                        Behavior on x {
                            UbuntuNumberAnimation { duration: UbuntuAnimation.FastDuration }
                        }
                        Behavior on y {
                            UbuntuNumberAnimation { duration: UbuntuAnimation.FastDuration }
                        }

                        onApplicationSelected: {
                            if (!editMode) {
                                bottomDock.applicationSelected(appId)
                            } else {
                                bottomDock.editMode = false
                            }
                        }
                        onApplicationContextMenu: bottomDock.applicationContextMenu(appId, this, true)
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
            readonly property bool isDragActive: activeId > -1

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
                shell.settings.drawerDockApps = appsRepeater.model.slice()
                appsRepeater.model = Qt.binding( function () { return shell.settings.drawerDockApps } )
            }
            onPositionChanged: {
                if (activeId != "" && index != -1 && index != activeIndex) {
                    appsRepeater.model = dockedAppGrid.arrMove(appsRepeater.model, activeIndex, activeIndex = index)
                    shell.haptics.playSubtle()
                }
            }
        }

        SwipeArea {
            enabled: !bottomDock.editMode && !bottomDock.isIntegratedDock
            anchors.fill: parent
            direction: bottomDock.expanded ? SwipeArea.Downwards : SwipeArea.Upwards
            onDraggingChanged: {
                if (dragging) {
                    bottomDock.expanded = !bottomDock.expanded
                }
            }
        }
    }
}
