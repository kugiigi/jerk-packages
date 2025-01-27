/*
 * Copyright (C) 2016 Canonical Ltd.
 * Copyright (C) 2020 UBports Foundation
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
import Lomiri.Components 1.3
import "../Components"
// ENH139 - System Direct Actions
import ".." as Root
// ENH139 - End
// ENH105 - Custom app drawer
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
import Lomiri.Components.Popups 1.3
import Lomiri.Components.ListItems 1.3 as ListItems
import ".."
// ENH105 - End

FocusScope {
    id: root

    property int delegateWidth: units.gu(11)
    property int delegateHeight: units.gu(11)
    property alias delegate: gridView.delegate
    property alias model: gridView.model
    // ENH105 - Custom app drawer
    // property alias interactive: gridView.interactive
    property alias currentIndex: gridView.currentIndex
    // property alias draggingVertically: gridView.draggingVertically
    readonly property bool interactive: swipeView.currentItem.interactive
    readonly property bool draggingVertically: swipeView.currentItem.draggingVertically
    readonly property bool moving: swipeView.currentItem.moving
    // ENH105 - End

    property alias header: gridView.header
    property alias topMargin: gridView.topMargin
    property alias bottomMargin: gridView.bottomMargin
    // ENH132 - App drawer icon size settings
    property real delegateSizeMultiplier: 1
    // ENH132 - End
    // ENH007 - Bottom search in drawer
    property alias verticalLayoutDirection: gridView.verticalLayoutDirection
    // ENH007 - End
    // ENH105 - Custom app drawer
    readonly property bool inverted: gridView.verticalLayoutDirection == GridView.BottomToTop
    property bool launcherInverted: false
    property real viewMargin: 0
    property var contextMenuItem: null
    property var rawModel
    property bool showDock: false
    property bool showCustomAppGrids: false
    property bool fullAppGridLast: false
    property bool mouseHoverOfSelectorIndicatorEnabled: true
    readonly property bool appGridEditMode: swipeView.currentItem && swipeView.currentItem.editMode
    readonly property var customAppGridsList: shell.settings.customAppGrids
    readonly property int currentPageIndex: swipeView.currentIndex
    readonly property int currentCustomPageIndex: {
        if (fullAppGridLast) {
            if (swipeView.currentIndex === swipeView.count - 1) {
                return -1
            } else {
                return swipeView.currentIndex
            }
        } else {
            if (swipeView.currentIndex === 0) {
                return -1
            } else {
                return swipeView.currentIndex - 1
            }
        }
    }

    signal applicationSelected(string appId)
    signal applicationContextMenu(string appId, var caller, bool fromDocked, bool fromCustomAppGrid)
    // ENH105 - End

    // ENH105 - Custom app drawer
    // readonly property int columns: Math.floor(width / delegateWidth)
    readonly property int columns: showDock ? Math.floor((width - (gridView.anchors.leftMargin + gridView.anchors.rightMargin)) / delegateWidth)
                                            : Math.floor(width / delegateWidth)
    // ENH105 - End
    readonly property int rows: Math.ceil(gridView.model.count / root.columns)

    property alias refreshing: pullToRefresh.refreshing
    signal refresh();

    // ENH105 - Custom app drawer
    state: "normal"
    states: [
        State {
            name: "bottomdock"
            when: shell.settings.enableDrawerDock

            AnchorChanges {
                target: swipeView
                anchors.top: parent.top
                anchors.bottom: parent.bottom
            }
            PropertyChanges {
                target: gridView

                bottomMargin: (appGridIndicatorLoader.viewBottomMargin)
                                + (bottomDockLoader.item && bottomDockLoader.item.shown ? units.gu(2) : 0)
            }
            PropertyChanges {
                target: swipeView

                anchors.bottomMargin: bottomDockLoader.item && bottomDockLoader.item.shown ?
                                                            bottomDockLoader.item.rowHeight + bottomDockLoader.item.verticalPadding / 2
                                                                    + bottomDockLoader.anchors.bottomMargin
                                                : 0
            }
            PropertyChanges {
                target: bottomDockLoader

                anchors.bottomMargin: units.gu(2)
            }
        }
        , State {
            name: "inverted"
            when: !shell.settings.enableDrawerDock

            AnchorChanges {
                target: swipeView
                anchors.top: parent.top
                anchors.bottom: bottomDockLoader.top
            }
            AnchorChanges {
                target: bottomDockLoader
                anchors.top: undefined
                anchors.bottom: parent.bottom
            }
            PropertyChanges {
                target: gridView

                bottomMargin: root.viewMargin + appGridIndicatorLoader.viewBottomMargin
            }
            PropertyChanges {
                target: swipeView

                anchors.bottomMargin: root.showDock ? units.gu(2) : 0
            }
            PropertyChanges {
                target: bottomDockLoader

                anchors.bottomMargin: 0
            }
        }
    ]

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

    function addToDirectActions(_appId) {
        if (shell.settings.directActionList.findIndex(
                                (element) => (element.actionId == _appId && element.type == Root.LPDirectActions.Type.App)) == -1
                ) {
            let _arrNewValues = shell.settings.directActionList.slice()
            let _properties = { actionId: _appId, type: Root.LPDirectActions.Type.App }
            _arrNewValues.push(_properties)
            shell.settings.directActionList = _arrNewValues
        }
    }
    function removeFromDirectActions(_appId) {
        let _foundIndex = shell.settings.directActionList.findIndex((element) => (element.actionId == _appId && element.type == Root.LPDirectActions.Type.App))
        if (_foundIndex > -1) {
            let _tempArr = shell.settings.directActionList.slice()
            _tempArr.splice(_foundIndex, 1)
            shell.settings.directActionList = _tempArr.slice()
        }
    }
    
    function enterEditMode() {
        if (bottomDockLoader.item) {
            bottomDockLoader.item.editMode = true
        }
    }

    function exitEditMode() {
        if (bottomDockLoader.item) {
            bottomDockLoader.item.editMode = false
        }
    }

    function collapseDock() {
        if (bottomDockLoader.item) {
            bottomDockLoader.item.expanded = false
        }
    }

    function enterAppGridEditMode() {
        if (typeof swipeView.currentItem.enterEditMode === "function") { 
            swipeView.currentItem.enterEditMode()
        }
    }

    function exitAppGridEditMode() {
        if (typeof swipeView.currentItem.exitEditMode === "function") { 
            swipeView.currentItem.exitEditMode()
        }
    }

    function addToAppGrid(_index, _appId) {
        if (!shell.settings.customAppGrids[_index].apps.includes(_appId)) {
            let _tempMainArr = shell.settings.customAppGrids.slice()
            let _appGridItem = shell.settings.customAppGrids[_index]
            if (_appGridItem) {
                let _tempArr = _appGridItem.apps.slice()

                // Also include QML list which lists from settings is
                if (Array.isArray(_appId) || typeof _appId == "object") {
                    let _appIdLength = _appId.length
                    for (let i = 0; i < _appIdLength; i++) {
                        let _currentApp = _appId[i]
                        if (!_tempArr.includes(_currentApp)) {
                            _tempArr.push(_appId[i])
                        }
                    }
                    _appGridItem.apps = _tempArr.slice()
                    _tempMainArr[_index].apps = _appGridItem.apps
                } else {
                    if (!_tempArr.includes(_appId)) {
                        _tempArr.push(_appId)
                        _appGridItem.apps = _tempArr.slice()
                        _tempMainArr[_index].apps = _appGridItem.apps
                    }
                }
                shell.settings.customAppGrids = _tempMainArr.slice()
            }
        }
    }

    function removeFromAppGrid(_index, _appId) {
        if (shell.settings.customAppGrids[_index].apps.includes(_appId)) {
            let _tempMainArr = shell.settings.customAppGrids.slice()
            let _appGridItem = shell.settings.customAppGrids[_index]
            if (_appGridItem) {
                let _tempArr = _appGridItem.apps.slice()
                _tempArr.splice(_tempArr.indexOf(_appId), 1)
                _appGridItem.apps = _tempArr.slice()
                _tempMainArr[_index].apps = _appGridItem.apps
                shell.settings.customAppGrids = _tempMainArr.slice()
            }
        }
    }

    function refreshAppGrids() {
        if (showCustomAppGrids) {
            let _currentModel = root.customAppGridsList
            let _currentModelLength = _currentModel.length
            if (swipeView.count - 1 !== _currentModelLength) {
                clearCustomAppGrids()
                for (let h = _currentModelLength - 1; h >= 0; h--) {
                    let _currentItem = customAppGridComponent.createObject(root, { "appGridIndex": h });
                    if (fullAppGridLast) {
                        swipeView.insertItem(0, _currentItem)
                    } else {
                        swipeView.insertItem(1, _currentItem)
                    }
                }
            }
        }
    }

    function clearCustomAppGrids() {
        let _currentCount = swipeView.count
        for (let i = _currentCount - 1; i >= 0; i--) {
            // Do not remove the full app grid
            let _currentItem = swipeView.itemAt(i)
            if (_currentItem !== fullGridViewItem) {
                swipeView.removeItem(_currentItem)
            }
        }
    }

    function moveFullAppGrid() {
        let _swipeViewCount = swipeView.count
        if (_swipeViewCount > 1) {
            for (let i = 0; i < _swipeViewCount; i++) {
                let _currentItem = swipeView.itemAt(i)
                if (_currentItem === fullGridViewItem) {
                    if (fullAppGridLast) {
                        swipeView.moveItem(i, _swipeViewCount - 1)
                    } else {
                        swipeView.moveItem(i, 0)
                    }

                    return
                }
            }
        }
    }

    function addNewAppGrid() {
        // Do not use PopupUtils to fix orientation issues
        let dialogAdd = addAppGridDialogComponent.createObject(shell.popupParent);

        let addNew = function (gridName, gridIcon) {
            let _tempArr = shell.settings.customAppGrids.slice()
            let _itemData = {
                name: gridName
                , icon: gridIcon
                , apps: []
            }
            _tempArr.push(_itemData)
            shell.settings.customAppGrids = _tempArr.slice()
            addToAppGrids(shell.settings.customAppGrids.length - 1)
        }

        dialogAdd.add.connect(addNew)
        dialogAdd.show()
    }

    function addToAppGrids(_index) {
        if (showCustomAppGrids) {
            let _currentItem = customAppGridComponent.createObject(root, { "appGridIndex": _index });
            if (fullAppGridLast) {
                swipeView.insertItem(swipeView.count - 1, _currentItem)
            } else {
                swipeView.addItem(_currentItem)
            }
        }
    }

    function addAppsToAppGrid(_index) {
        // Do not use PopupUtils to fix orientation issues
        let _gridName = root.customAppGridsList[_index].name
        let dialogAddApps = addAppToAppGridDialogComponent.createObject(shell.popupParent, { "gridName": _gridName });

        let _addAppToAppGrid = function (_appsList) {
            if (_index >= 0 && _index <= shell.settings.customAppGrids.length - 1) {
                addToAppGrid(_index, _appsList)
            } else {
                console.log("Cannot add apps to app grid: invalid index %1".arg(_index))
            }
        }

        dialogAddApps.confirm.connect(_addAppToAppGrid)
        dialogAddApps.show()
    }

    function deleteAppGrid(_index) {
        // Do not use PopupUtils to fix orientation issues
        let _gridName = root.customAppGridsList[_index].name
        let dialogDelete = deleteAppGridDialogComponent.createObject(shell.popupParent, { "gridName": _gridName });

        let _deleteAppGrid = function () {
            if (_index >= 0 && _index <= shell.settings.customAppGrids.length - 1) {
                deleteFromAppGrids(_index)
                let _tempArr = shell.settings.customAppGrids.slice()
                _tempArr.splice(_index, 1)
                shell.settings.customAppGrids = _tempArr.slice()
            } else {
                console.log("Cannot delete app grid: invalid index %1".arg(_index))
            }
        }

        dialogDelete.confirm.connect(_deleteAppGrid)
        dialogDelete.show()
    }

    function deleteFromAppGrids(_index) {
        if (showCustomAppGrids) {
            let _swipeViewItemIndex = _index
            if (!fullAppGridLast) {
                _swipeViewItemIndex = _index + 1
            }
            let _item = swipeView.itemAt(_swipeViewItemIndex)
            if (_item !== fullGridViewItem) {
                swipeView.removeItem(_item)
            }

            // Update app grid index of app grids after the deleted app grid
            let _swipeViewCount = swipeView.count
            for (let i = _swipeViewItemIndex; i < _swipeViewCount; i++) {
                let _currentItem = swipeView.itemAt(i)
                if (_currentItem !== fullGridViewItem) {
                    _currentItem.appGridIndex -= 1 
                }
            }
        }
    }

    function editAppGrid(_index) {
        // Do not use PopupUtils to fix orientation issues
        let _appGrid = root.customAppGridsList[_index]
        let _gridName = _appGrid.name
        let _gridIcon = _appGrid.icon
        let dialogEdit = addAppGridDialogComponent.createObject(shell.popupParent, { "editMode": true, "gridName": _gridName, "gridIndex": _index, "gridIcon": _gridIcon } );

        let _editAppGrid = function (gridIndex, newName, newIcon) {
            let _tempArr = shell.settings.customAppGrids.slice()
            let _itemData = _tempArr[gridIndex]
            if (_itemData) {
                _itemData.name = newName
                _itemData.icon = newIcon
                _tempArr[gridIndex] = _itemData
                shell.settings.customAppGrids = _tempArr.slice()
            }
        }

        dialogEdit.edit.connect(_editAppGrid)
        dialogEdit.show()
    }

    function moveAppGrid(_index, _newIndex) {
        if (_index >= 0 && _index <= shell.settings.customAppGrids.length - 1
                && _newIndex >= 0 && _newIndex <= shell.settings.customAppGrids.length - 1
                && _index !== _newIndex) {
            shell.settings.customAppGrids = shell.arrMove(shell.settings.customAppGrids, _index, _newIndex)

            let _newSwipeViewItemIndex = _newIndex
            if (!fullAppGridLast) {
                _newSwipeViewItemIndex = _newIndex + 1
            }
            swipeView.setCurrentIndex(_newSwipeViewItemIndex)
        } else {
            console.log("Cannot move app grid: invalid index %1 to %2".arg(_index).arg(_newIndex))
        }
    }

    function moveAppGridInSwipeView(_index, _newIndex) {
        let _swipeViewItemIndex = _index
        let _newSwipeViewItemIndex = _newIndex
        if (!fullAppGridLast) {
            _swipeViewItemIndex = _index + 1
            _newSwipeViewItemIndex = _newIndex + 1
        }

        swipeView.moveItem(_swipeViewItemIndex, _newSwipeViewItemIndex)
    }

    function showFullAppGrid() {
        if (fullAppGridLast) {
            swipeView.setCurrentIndex(swipeView.count - 1)
        } else {
            swipeView.setCurrentIndex(0)
        }
    }

    function showAppGrid(_index) {
        swipeView.setCurrentIndex(_index)
    }

    onFocusChanged: {
        if (focus) {
            swipeView.currentItem.appGridItem.forceActiveFocus()
        }
    }

    onVisibleChanged: {
        if (visible && shell.settings.resetAppDrawerWhenClosed) {
            if (inverted) {
                gridView.positionViewAtBeginning()
                // Dirty hack to properly move to the start/end when inverted
                gridView.contentY += gridView.bottomMargin
            } else {
                gridView.contentY = 0 - gridView.topMargin
            }
        }
    }

    onShowCustomAppGridsChanged: {
        if (showCustomAppGrids) {
            refreshAppGrids()
        } else{
            clearCustomAppGrids()
        }
    }

    onFullAppGridLastChanged: moveFullAppGrid()

    Component.onCompleted: refreshAppGrids()

    Component {
         id: addAppGridDialogComponent
         Dialog {
            id: dialogue

            readonly property bool nameIsValid: gridNameTextField.text.trim() !== ""
                                                    && (
                                                            (!editMode && shell.findFromArray(shell.settings.customAppGrids, "name", currentName) == undefined)
                                                            ||
                                                            (editMode && nameHasChanged && shell.countFromArray(shell.settings.customAppGrids, "name", currentName) === 0)
                                                            ||
                                                            (editMode && !nameHasChanged && shell.countFromArray(shell.settings.customAppGrids, "name", currentName) < 2)
                                                        )
            readonly property bool nameHasChanged: editMode && gridName !== currentName
            property bool editMode: false
            property int gridIndex
            property string gridName
            property string gridIcon
            property string currentName
            property string currentIcon

            signal add(string gridName, string gridIcon)
            signal edit(string gridName, string newName, string gridIcon)

            onAdd: PopupUtils.close(dialogue)
            onEdit: PopupUtils.close(dialogue)

            property bool reparentToRootItem: false

            title: editMode ? 'Edit "%1"'.arg(gridName) : "New App Grid"
            anchorToKeyboard: false // Handle the keyboard anchor via shell.popupParent

            Component.onCompleted: {
                if (editMode) {
                    gridNameTextField.text = gridName
                    currentName = gridName
                    currentIcon = gridIcon
                }
            }

            TextField {
                id: gridNameTextField

                placeholderText: "Name of the App Grid"
                inputMethodHints: Qt.ImhNoPredictiveText
                onTextChanged: dialogue.currentName = text
            }
            Label {
                id: errorLabel
                visible: gridNameTextField.text.trim() !== "" && !dialogue.nameIsValid
                text: "Name already exists"
                color: theme.palette.normal.negative
            }

            RowLayout {
                height: units.gu(6)

                Button {
                    id: iconButton

                    Layout.alignment: Qt.AlignVCenter

                    text: "Pick Icon"
                    onClicked: {
                        // Do not use PopupUtils to fix orientation issues
                        let _iconMenu = iconMenuComponent.createObject(shell.popupParent, { caller: iconButton, currentIcon: gridIconLabel.text, model: shell.iconsList } );

                        let _iconSelect = function (_iconName) {
                            dialogue.currentIcon = _iconName
                        }

                        _iconMenu.iconSelected.connect(_iconSelect)
                        _iconMenu.show()
                    }
                }
                Icon {
                    id: gridIconItem
                    Layout.preferredWidth: units.gu(3)
                    Layout.preferredHeight: units.gu(3)
                    name: dialogue.currentIcon
                    color: theme.palette.normal.backgroundText
                }
                Label {
                    id: gridIconLabel

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignVCenter
                    text: dialogue.currentIcon
                    wrapMode: Text.WordWrap
                }
            }

            Button {
                text: dialogue.editMode ? "Save" : "Add"
                color: theme.palette.normal.positive
                enabled: dialogue.nameIsValid
                onClicked: {
                    let _gridName = dialogue.currentName
                    let _gridIcon = dialogue.currentIcon
                    if (dialogue.editMode) {
                        dialogue.edit(dialogue.gridIndex, _gridName, _gridIcon)
                    } else {
                        dialogue.add(_gridName, _gridIcon)
                    }
                }
            }
            Button {
                text: "Cancel"
                onClicked: PopupUtils.close(dialogue)
            }
            Component {
                id: iconMenuComponent

                LPIconSelector {}
            }
         }
    }

    Component {
         id: deleteAppGridDialogComponent
         Dialog {
            id: deleteDialog
             
            property string gridName

            signal confirm

            onConfirm: PopupUtils.close(deleteDialog)

            property bool reparentToRootItem: false

            title: 'Delete "%1"'.arg(gridName)
            anchorToKeyboard: false // Handle the keyboard anchor via shell.popupParent

            Button {
                text: "Delete"
                color: theme.palette.normal.negative
                onClicked: deleteDialog.confirm()
            }
            Button {
                text: "Cancel"
                onClicked: PopupUtils.close(deleteDialog)
            }
        }
    }

    Component {
         id: addAppToAppGridDialogComponent

        Rectangle {
            id: addAppToAppGridDialog
             
            property string gridName
            property var selectApps: []
            property bool selectAll: false // select all dirty hack LOL

            signal confirm(var appsList)

            anchors.centerIn: parent
            width: Math.min(parent.width * 0.7, units.gu(60))
            height: Math.min(parent.height * 0.8, units.gu(90))
            z: 1000
            visible: false
            color: theme.palette.normal.base
            radius: units.gu(3)

            function show() {
                visible = true
            }

            function hide() {
                visible = false
                destroy()
            }

            onConfirm: hide()

            Component.onCompleted: {
                let _filteredModel = []
                let _appsModel = root.rawModel
                let _currentAppList = root.customAppGridsList[root.currentCustomPageIndex].apps

                for (let i = 0; i < _appsModel.rowCount(); ++i) {
                    let _modelIndex = _appsModel.index(i, 0)
                    let _currentItemAppid = _appsModel.data(_modelIndex, 0)

                    if (!_currentAppList.includes(_currentItemAppid)) {
                        let _currentAppName = _appsModel.data(_modelIndex, 1)
                        let _currentAppIcon = _appsModel.data(_modelIndex, 2)
                        _filteredModel.push( { name: _currentAppName, icon: _currentAppIcon, appId: _currentItemAppid } )
                    }
                }

                appListView.model = _filteredModel.slice()
            }

            InverseMouseArea {
               anchors.fill: parent
               acceptedButtons: Qt.LeftButton
               onPressed: addAppToAppGridDialog.hide()
            }
            
            Rectangle {
                parent: addAppToAppGridDialog.parent
                z: addAppToAppGridDialog.z - 1
                color: theme.palette.normal.background
                opacity: 0.6
                anchors.fill: parent
            }
            
            ColumnLayout {
                id: columnLayout
                anchors {
                    margins: units.gu(2)
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                
                Label {
                    Layout.fillWidth: true
                    textSize: Label.Large
                    text: 'Add Apps to "%1"'.arg(addAppToAppGridDialog.gridName)
                    height: units.gu(10)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Button {
                    Layout.fillWidth: true
                    text: "Add"
                    enabled: !noAppLabel.visible
                    color: theme.palette.normal.positive
                    onClicked: {
                        if (addAppToAppGridDialog.selectApps.length > 0) {
                            addAppToAppGridDialog.confirm(addAppToAppGridDialog.selectApps)
                        }
                    }
                }
                Button {
                    Layout.fillWidth: true
                    text: "Cancel"
                    onClicked: addAppToAppGridDialog.hide()
                }
                RowLayout {
                    Layout.fillWidth: true
                    visible: !noAppLabel.visible
                    Button {
                        Layout.fillWidth: true
                        text: "Select All"
                        onClicked: {
                            addAppToAppGridDialog.selectAll = true
                        }
                    }
                    Button {
                        Layout.fillWidth: true
                        text: "Deselect All"
                        onClicked: {
                            addAppToAppGridDialog.selectAll = false
                        }
                    }
                }

                Label {
                    id: noAppLabel

                    Layout.fillWidth: true
                    Layout.preferredHeight: units.gu(15)
                    textSize: Label.Large
                    visible: appListView.count === 0
                    text: "No app to add"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            ListView {
                id: appListView

                clip: true
                cacheBuffer: 100000
                anchors {
                    top: columnLayout.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: units.gu(2)
                }

                delegate: ListItem {
                    id: appListItem

                    selectMode: true
                    onClicked: selected = !selected
                    onSelectedChanged: {
                        if (selected) {
                            addAppToAppGridDialog.selectApps.push(modelData.appId)
                        } else {
                            let _foundIndex = addAppToAppGridDialog.selectApps.indexOf(modelData.appId)
                            if (_foundIndex > -1) {
                                addAppToAppGridDialog.selectApps.splice(_foundIndex)
                            }
                        }
                    }
                    
                    Connections {
                        target: addAppToAppGridDialog
                        onSelectAllChanged: {
                            if (target.selectAll) {
                                appListItem.selected = true
                            } else {
                                appListItem.selected = false
                            }
                        }
                    }

                    ListItemLayout {
                       title.text: modelData.name
                        LomiriShape {
                            id: appIcon

                            width: units.gu(4)
                            height: 7.5 / 8 * width
                            radius: "medium"
                            borderSource: 'undefined'
                            SlotsLayout.position: SlotsLayout.Leading;
                            source: Image {
                                id: sourceImage
                                asynchronous: true
                                sourceSize.width: appIcon.width
                                source: modelData.icon
                            }
                            sourceFillMode: LomiriShape.PreserveAspectCrop
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: swipeView.currentItem
        onEditModeChanged: {
            let _swipeViewCount = swipeView.count
            for (let i = 0; i < _swipeViewCount; i++) {
                // Do not remove the full app grid
                let _currentItem = swipeView.itemAt(i)
                if (_currentItem !== target) {
                    if (target.editMode) {
                        _currentItem.enterEditMode()
                    } else {
                        _currentItem.exitEditMode()
                    }
                }
            }
        }
    }

    Component {
        id: customAppGridComponent

        Item {
            id: customAppGridItem

            readonly property bool editMode: customGridLoader.item && customGridLoader.item.editMode
            readonly property var appGridData: shell.settings.customAppGrids[appGridIndex]
            readonly property bool appDragIsActive: customGridLoader.item && customGridLoader.item.appDragIsActive
            readonly property alias appGridItem: customGridLoader
            property int appGridIndex: -1

            property string gridName: appGridData.name
            property string iconName: appGridData.icon

            // FLickable Properties
            property bool interactive: customGridView.interactive
            property bool moving: customGridView.moving
            property bool draggingVertically: customGridView.draggingVertically
            property int currentIndex: customGridView.currentIndex

            function enterEditMode() {
                if (customGridLoader.item) {
                    customGridLoader.item.editMode = true
                }
            }

            function exitEditMode() {
                if (customGridLoader.item) {
                    customGridLoader.item.editMode = false
                }
            }

            function toggleEditMode() {
                if (customAppGridItem.editMode) {
                    customAppGridItem.exitEditMode()
                } else {
                    customAppGridItem.enterEditMode()
                }
            }

            onEditModeChanged: {
                // WORKAROUND: Store current contentHeight when entering editMode so that it won't flick when moving an app
                if (editMode) {
                    customGridView.contentHeightInEditMode = customGridView.contentHeight
                    customGridView.resetHeader()
                }
            }

            LPHeader {
                id: labelHeader

                readonly property real idealRechableHeight: shell.convertFromInch(shell.settings.pullDownHeight)
                readonly property real idealMaxHeight: root.height - idealRechableHeight
                readonly property real idealExpandableHeight: idealRechableHeight + units.gu(10)

                expandable: root.height >= idealExpandableHeight && shell.settings.customAppGridsExpandable
                defaultHeight: 0
                maxHeight: idealMaxHeight

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                Rectangle {
                    color: "transparent"
                    anchors.fill: parent

                    RowLayout {
                        anchors {
                            fill: parent
                            bottomMargin: units.gu(2)
                        }
                        opacity: labelHeader.height - labelHeader.defaultHeight < labelHeader.maxHeight * 0.2 ? 0
                                            : 1 - ((labelHeader.maxHeight - labelHeader.height) / ((labelHeader.maxHeight * 0.8) - labelHeader.defaultHeight))
                        visible: opacity > 0

                        Item {
                            Layout.fillWidth: true
                        }
                        Icon {
                            name: customAppGridItem.iconName
                            Layout.preferredWidth: units.gu(3)
                            Layout.preferredHeight: units.gu(3)

                            color: timeDateLabel.color
                        }
                        Label {
                            id: timeDateLabel

                            textSize: Label.XLarge
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: customAppGridItem.gridName
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                    }

                    ListItems.ThinDivider {
                        anchors {
                            bottom: parent.bottom
                            bottomMargin: units.gu(2)
                            left: parent.left
                            right: parent.right
                        }
                    }
                }
            }

            LPCollapseHeaderSwipeArea {
                pageHeader: labelHeader
                z: customGridView.z + 1
                enabled: pageHeader.expandable && pageHeader.expanded
                anchors.fill: parent
            }

            LPFlickable {
                id: customGridView

                property real contentHeightInEditMode
                property int currentIndex: -1

                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                    top: labelHeader.bottom
                    leftMargin: bottomDockLoader.item ? bottomDockLoader.item.horizontalPadding : 0
                    rightMargin: bottomDockLoader.item ? bottomDockLoader.item.horizontalPadding  : 0
                }
                pageHeader: labelHeader
                topMargin: gridView.topMargin
                bottomMargin: gridView.bottomMargin
                interactive: !(customGridLoader.item && customGridLoader.item.appDragIsActive)
                                && !labelHeader.expanded
                focus: true
                contentHeight: {
                    if (!customAppGridItem.editMode) {
                        let _availableHeight = height - topMargin - bottomMargin
                        let _heightDiff = _availableHeight - customGridLoader.height
                        if (_heightDiff >= 0) {
                            // WORKAROUND: (For desktops) Adds more height so app grids that cannot be scrolled can still be expanded
                            return _availableHeight + units.gu(0.5)
                        }

                        return customGridLoader.height
                    }

                    return contentHeightInEditMode
                }

                // ENH127 - Increase max flick velocity
                maximumFlickVelocity: shell.settings.fasterFlickDrawer ? units.gu(600) : units.gu(312.5)
                // ENH127 - End
                clip: true

                function expandHeader() {
                    if (labelHeader.expandable) {
                        labelHeader.expanded = true
                    }
                }
                function resetHeader() {
                    labelHeader.expanded = false
                }
                function positionToBeginning() {
                    contentY = -topMargin
                }
                function positionToEnd() {
                    contentY = contentHeight - height + bottomMargin
                }
                function delayedPositionToEnd() {
                    delayScroll.restart()
                }

                onMovingChanged: {
                    if (moving && bottomDockLoader.item) {
                        bottomDockLoader.item.expanded = false
                    }
                }

                // FIXME: Lazy approach for flicking to the end when inverted
                Timer {
                    id: delayScroll
                    running: false
                    interval: 100
                    onTriggered: {
                        if (root.inverted) {
                            customGridView.positionToEnd()
                        }
                    }
                }

                Connections {
                    target: bottomDockLoader
                    onLoaded: customGridView.delayedPositionToEnd()
                }
                Connections {
                    target: root
                    onVisibleChanged: {
                        if (target.visible) {
                            if (shell.settings.resetAppDrawerWhenClosed) {
                                if (inverted) {
                                    customGridView.resetHeader()
                                    customGridView.positionToEnd()
                                } else {
                                    customGridView.positionToBeginning()
                                }
                            }

                            if (!inverted) {
                                if (root.launcherInverted) {
                                    customGridView.expandHeader()
                                } else {
                                    customGridView.resetHeader()
                                }
                            }
                        }
                    }
                }
                
                TapHandler {
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onLongPressed: {
                        customAppGridItem.toggleEditMode()
                        shell.haptics.playSubtle()
                    }

                    onSingleTapped: {
                        if ((eventPoint.event.device.pointerType === PointerDevice.Cursor || eventPoint.event.device.pointerType == PointerDevice.GenericPointer)
                                && eventPoint.event.button === Qt.RightButton) {
                            customAppGridItem.toggleEditMode()
                        }
                    }
                }

                Loader {
                    id: customGridLoader

                    active: true
                    asynchronous: true
                    focus: false
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: units.gu(1)
                        rightMargin: units.gu(1)
                    }
                    state: "default"
                    states: [
                        State {
                            name: "default"
                            when: !root.inverted
                            
                            AnchorChanges {
                                target: customGridLoader
                                anchors.bottom: undefined
                                anchors.top: parent.top
                            }
                        }
                        , State {
                            name: "inverted"
                            when: root.inverted
                            
                            AnchorChanges {
                                target: customGridLoader
                                anchors.bottom: parent.bottom
                                anchors.top: undefined
                            }
                        }
                    ]

                    /*
                    onActiveFocusChanged: {
                        if (activeFocus && customGridLoader.item) {
                            if (customGridLoader.item.currentIndex === -1) {
                                customGridLoader.item.currentIndex = 0
                            }
                        }
                    }
                    */

                    sourceComponent: LPAppGrid {
                        // ENH132 - App drawer icon size settings
                        delegateSizeMultiplier: root.delegateSizeMultiplier
                        // ENH132 - End
                        columns: root.columns
                        shown: true
                        isIntegratedDock: true
                        inverted: root.inverted
                        verticalPadding: 0
                        delegateHeight: root.delegateHeight
                        delegateWidth: root.delegateWidth
                        rawModel: root.rawModel
                        appModel: shell.settings.customAppGrids[customAppGridItem.appGridIndex].apps
                        contextMenuItem: root.contextMenuItem

                        onApplicationSelected: root.applicationSelected(appId)
                        onApplicationContextMenu: root.applicationContextMenu(appId, caller, false, true)
                        onAppOrderChanged: {
                            let _index = customAppGridItem.appGridIndex
                            let _tempMainArr = shell.settings.customAppGrids.slice()
                            let _appGridItem = shell.settings.customAppGrids[_index]
                            if (_appGridItem) {
                                _appGridItem.apps = newAppOrderArray.slice()
                                _tempMainArr[_index].apps = _appGridItem.apps
                                shell.settings.customAppGrids = _tempMainArr.slice()
                            }
                        }
                    }
                }
            }
        }
    }

    // ENH105 - Custom app drawer
    QQC2.SwipeView {
        id: swipeView

        readonly property bool editMode: currentItem && currentItem.editMode ? true : false

        currentIndex: 0
        interactive: !currentItem.appDragIsActive
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        onCurrentIndexChanged: root.collapseDock()

        Item {
            id: fullGridViewItem

            property bool editMode: false
            property string gridName: "All"
            property string iconName: "ubuntu-store-symbolic"
            readonly property bool appDragIsActive: false
            readonly property alias appGridItem: gridView

            // Flickable Properties
            property bool interactive: gridView.interactive
            property bool moving: gridView.moving
            property bool draggingVertically: gridView.draggingVertically
            property int currentIndex: gridView.currentIndex
            
            // Dummy functions
            function enterEditMode() {
                editMode = true
            }

            function exitEditMode() {
                editMode = false
            }

    // ENH105 - End
            GridView {
                id: gridView
                anchors.fill: parent
                // ENH105 - Custom app drawer
                // anchors.topMargin: units.gu(2)

                anchors.leftMargin: bottomDockLoader.item ? bottomDockLoader.item.horizontalPadding + bottomDockLoader.anchors.leftMargin : 0
                anchors.rightMargin: bottomDockLoader.item ? bottomDockLoader.item.horizontalPadding + bottomDockLoader.anchors.rightMargin  : 0
                topMargin: root.viewMargin
                // ENH105 - End
                focus: true

                // ENH105 - Custom app drawer
                // Reverted back to original for now since there are instances where the gridview isn't properly centered
                readonly property int overflow: width - (root.columns * root.delegateWidth)
                readonly property real spacing: Math.floor(overflow / root.columns)
                //readonly property real overflow: width - (root.columns * root.delegateWidth)
                //readonly property real spacing: overflow / root.columns
                // ENH105 - End

                cellWidth: root.delegateWidth + spacing
                cellHeight: root.delegateHeight
                // ENH127 - Increase max flick velocity
                maximumFlickVelocity: shell.settings.fasterFlickDrawer ? units.gu(600) : units.gu(312.5)
                // ENH127 - End
                // ENH105 - Custom app drawer
                clip: true
                onMovingChanged: {
                    if (moving && bottomDockLoader.item) {
                        bottomDockLoader.item.expanded = false
                    }
                }
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
        }
    }
    // ENH105 - End

    // ENH105 - Custom app drawer
    Loader {
        id: appGridIndicatorLoader
        
        readonly property bool swipeSelectMode: item && item.swipeSelectMode
        readonly property bool isHovered: item && item.isHovered
        readonly property real defaultBottomMargin: bottomDockLoader.active ? units.gu(3) : units.gu(1)
        //bottomMargin for views
        readonly property real viewBottomMargin: item ? (swipeSelectMode ? item.storedHeightBeforeSwipeSelectMode : height) + appGridIndicatorLoader.defaultBottomMargin
                                                      : 0

        active: shell.settings.enableCustomAppGrid
        asynchronous: true
        height: item ? item.height : 0 // Since height doesn't reset when inactive
        focus: false
        anchors {
            left: parent.left
            right: parent.right
            bottom: bottomDockLoader.top
            bottomMargin: (swipeSelectMode && !isHovered ? shell.convertFromInch(0.3) : 0) + defaultBottomMargin
            leftMargin: units.gu(1)
            rightMargin: units.gu(1)
        }
        Behavior on anchors.bottomMargin { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }

        sourceComponent: LPAppGridIndicator {
            dataModel: swipeView
            editMode: swipeView.editMode
            fullAppGridLast: root.fullAppGridLast
            model: swipeView.count
            currentIndex: swipeView.currentIndex
            mouseHoverEnabled: root.mouseHoverOfSelectorIndicatorEnabled
            onNewIndexSelected: root.showAppGrid(newIndex)
            onAddNewAppGrid: root.addNewAppGrid()
            onAddAppsToCurrentGrid: root.addAppsToAppGrid(root.currentCustomPageIndex)
            onDeleteCurrentAppGrid: root.deleteAppGrid(root.currentCustomPageIndex)
            onEditCurrentAppGrid: root.editAppGrid(root.currentCustomPageIndex)
            onMoveAppGridToLeft: root.moveAppGrid(root.currentCustomPageIndex, root.currentCustomPageIndex - 1)
            onMoveAppGridToRight: root.moveAppGrid(root.currentCustomPageIndex, root.currentCustomPageIndex + 1)
        }
    }

    Loader {
        id: bottomDockLoader
        active: shell.settings.enableDrawerDock
        asynchronous: true
        height: item ? item.height : 0 // Since height doesn't reset when inactive
        focus: false
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: units.gu(1)
            rightMargin: units.gu(1)
        }

        sourceComponent: LPDrawerDock {
            // ENH132 - App drawer icon size settings
            delegateSizeMultiplier: root.delegateSizeMultiplier
            // ENH132 - End
            columns: root.columns
            shown: root.showDock && !gridView.activeFocus
            isIntegratedDock: false
            inverted: root.inverted
            availableHeight: root.height
            delegateHeight: root.delegateHeight
            delegateWidth: root.delegateWidth
            rawModel: root.rawModel
            appModel: shell.settings.drawerDockApps
            contextMenuItem: root.contextMenuItem
            hideLabel: shell.settings.drawerDockHideLabels

            onApplicationSelected: root.applicationSelected(appId)
            onApplicationContextMenu: root.applicationContextMenu(appId, caller, true, false)
            onAppOrderChanged: shell.settings.drawerDockApps = newAppOrderArray.slice()
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
