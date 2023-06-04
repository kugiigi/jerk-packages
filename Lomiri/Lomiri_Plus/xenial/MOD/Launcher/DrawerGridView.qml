/*
 * Copyright (C) 2016 Canonical, Ltd.
 * Copyright (C) 2020 UBports Foundation.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import Ubuntu.Components 1.3
import "../Components"
// ENH105 - Custom app drawer
import QtQuick.Layouts 1.12
// ENH105 - End

FocusScope {
    id: root

    property int delegateWidth: units.gu(11)
    property int delegateHeight: units.gu(11)
    property alias delegate: gridView.delegate
    property alias model: gridView.model
    property alias interactive: gridView.interactive
    property alias currentIndex: gridView.currentIndex
    property alias draggingVertically: gridView.draggingVertically

    property alias header: gridView.header
    property alias topMargin: gridView.topMargin
    property alias bottomMargin: gridView.bottomMargin
    // ENH007 - Bottom search in drawer
    property alias verticalLayoutDirection: gridView.verticalLayoutDirection
    // ENH007 - End
    // ENH105 - Custom app drawer
    property var contextMenuItem: null
    property var rawModel
    property bool showDock: false
    signal applicationSelected(string appId)
    signal applicationContextMenu(string appId, var caller, bool fromDocked)
    // ENH105 - End

    readonly property int columns: Math.floor(width / delegateWidth)
    readonly property int rows: Math.ceil(gridView.model.count / root.columns)

    property alias refreshing: pullToRefresh.refreshing
    signal refresh();

    GridView {
        id: gridView
        anchors.fill: parent
        anchors.topMargin: units.gu(2)
        // ENH105 - Custom app drawer
        anchors.bottomMargin: bottomDockLoader.item && bottomDockLoader.item.shown ?
                                        bottomDockLoader.item.expanded && bottomDockLoader.item.expandingFinished ? bottomDockLoader.height + bottomDockLoader.anchors.bottomMargin
                                                 : bottomDockLoader.item.rowHeight + bottomDockLoader.item.verticalPadding
                                                            + bottomDockLoader.anchors.bottomMargin
                                    : 0
        anchors.leftMargin: bottomDockLoader.item ? bottomDockLoader.item.horizontalPadding + bottomDockLoader.anchors.leftMargin : 0
        anchors.rightMargin: bottomDockLoader.item ? bottomDockLoader.item.horizontalPadding + bottomDockLoader.anchors.rightMargin  : 0
        bottomMargin: bottomDockLoader.item && bottomDockLoader.item.shown ? units.gu(2) : 0
        // ENH105 - End
        focus: true

        readonly property int overflow: width - (root.columns * root.delegateWidth)
        readonly property real spacing: Math.floor(overflow / root.columns)

        cellWidth: root.delegateWidth + spacing
        cellHeight: root.delegateHeight
        // ENH105 - Custom app drawer
        clip: true
        // ENH105 - End

        PullToRefresh {
            id: pullToRefresh
            parent: gridView
            target: gridView

            readonly property real contentY: gridView.contentY - gridView.originY
            y: -contentY - units.gu(5)

            readonly property color pullLabelColor: "white"
            style: PullToRefreshScopeStyle {
                activationThreshold: Math.min(units.gu(14), gridView.height / 5)
            }

            onRefresh: root.refresh();
        }
    }

    // ENH105 - Custom app drawer
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

    function addToDock(_appId) {
        if (!shell.settings.drawerDockApps.includes(_appId)) {
            let _tempArr = shell.settings.drawerDockApps.slice()
            _tempArr.push(_appId)
            shell.settings.drawerDockApps = _tempArr.slice()
        }
    }
    function removeFromDock(_appId) {
        if (shell.settings.drawerDockApps.includes(_appId)) {
            let _tempArr = shell.settings.drawerDockApps.slice()
            _tempArr.splice(_tempArr.indexOf(_appId), 1)
            shell.settings.drawerDockApps = _tempArr.slice()
        }
    }
    
    function enterEditMode() {
        if (bottomDockLoader.item) {
            bottomDockLoader.item.editMode = true
        }
    }

    function collapseDock() {
        if (bottomDockLoader.item) {
            bottomDockLoader.item.expanded = false
        }
    }
    
    Loader {
        id: bottomDockLoader
        active: shell.settings.enableDrawerDock
        asynchronous: true
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: units.gu(1)
            rightMargin: units.gu(1)
            bottom: parent.bottom
            bottomMargin: units.gu(2)
        }
        sourceComponent: bottomDockComponent
    }

    Component {
        id: bottomDockComponent

        Item {
            id: bottomDock

            readonly property bool shown: root.showDock
            readonly property real verticalPadding: units.gu(4)
            readonly property real horizontalPadding: units.gu(1)
            readonly property alias rowHeight: dockedAppGrid.rowHeight
            property bool editMode: false
            property bool expanded: false
            property bool expandingFinished: false

            height: dockedAppGrid.height + verticalPadding
            visible: shown
            
            Rectangle {
                id: bg
                color: theme.palette.normal.foreground
                opacity: 0.8
                radius: units.gu(3)
                anchors.fill: parent
            }

            Icon {
                z: wheelMouseArea.z + 1
                visible: dockedAppGrid.multiRows && !bottomDock.editMode
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

                readonly property real toggleHeight: root.delegateHeight
                readonly property real rowHeight: root.delegateHeight
                readonly property real rowMargins: 0
                readonly property bool multiRows: rowHeight + rowMargins !== gridLayout.height + rowMargins

                z: 2
                hoverEnabled: true
                acceptedButtons: Qt.AllButtons
                clip: !bottomDock.editMode

                height: {
                    if (bottomDock.expanded || bottomDock.editMode) {
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

                            property var appData: modelData ? root.getAppItem(modelData) : null
                            property string appId: modelData
                            property int itemIndex: index

                            Layout.fillWidth: true
                            Layout.preferredHeight: dockedAppGrid.rowHeight

                            Connections {
                                target: root.rawModel
                                onRefreshingChanged: {
                                    if (!refreshing) {
                                        itemContainer.appData = Qt.binding( function() { return itemContainer.appId ? root.getAppItem(itemContainer.appId) : null } )
                                    }
                                }
                            }

                            LPDrawerAppDelegate {
                                id: toggleContainer

                                focused: root.contextMenuItem && root.contextMenuItem.appId == itemContainer.appId && root.contextMenuItem.fromDocked
                                objectName: "drawerDockItem_" + itemContainer.appId
                                delegateWidth: root.delegateWidth
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
                                        root.applicationSelected(appId)
                                    } else {
                                        bottomDock.editMode = false
                                    }
                                }
                                onApplicationContextMenu: root.applicationContextMenu(appId, this, true)
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
                    property int activeIndex //current position of active item
                    readonly property bool isDragActive: activeId > -1

                    enabled: bottomDock.editMode
                    anchors.fill: gridLayout
                    hoverEnabled: true
                    propagateComposedEvents: true

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
                        activeId = -1
                        shell.settings.drawerDockApps = appsRepeater.model.slice()
                        appsRepeater.model = Qt.binding( function () { return shell.settings.drawerDockApps } )
                    }
                    onPositionChanged: {
                        if (activeId != -1 && index != -1 && index != activeIndex) {
                            appsRepeater.model = dockedAppGrid.arrMove(appsRepeater.model, activeIndex, activeIndex = index)
                            shell.haptics.playSubtle()
                        }
                    }
                }

                SwipeArea {
                    enabled: !bottomDock.editMode
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
    }
    // ENH105 - End

    ProgressBar {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        visible: refreshing
        indeterminate: true
    }

    function getFirstAppId() {
        return model.appId(0);
    }
}
