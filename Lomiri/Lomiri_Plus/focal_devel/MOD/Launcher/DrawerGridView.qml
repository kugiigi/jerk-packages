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
    property real viewMargin: 0
    property var contextMenuItem: null
    property var rawModel
    property bool showDock: false
    property bool showCustomAppGrids: false
    property bool fullAppGridLast: false
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
                        let _iconMenu = iconMenuComponent.createObject(shell.popupParent, { caller: iconButton, currentIcon: gridIconLabel.text } );

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

                Popover {
                    id: iconMenu

                    readonly property string selectedIcon: iconGridView.model[iconGridView.currentIndex]
                    property string currentIcon
                    signal iconSelected(string iconName)

                    grabDismissAreaEvents: true
                    automaticOrientation: false
                    contentHeight: parent.height * 0.7
                    contentWidth: parent.width * 0.7
                    
                    onSelectedIconChanged: iconSelected(selectedIcon)
                    Component.onCompleted: {
                        if (currentIcon) {
                            let _foundIndex = iconGridView.model.indexOf(currentIcon)
                            if (_foundIndex > -1) {
                                iconGridView.currentIndex = _foundIndex
                            }
                        }
                    }
                    
                    GridView {
                        id: iconGridView

                        anchors {
                            left: parent.left
                            top: parent.top
                            right: parent.right
                        }
                        height: iconMenu.contentHeight
                        cellWidth: width / 6
                        cellHeight: cellWidth
                        snapMode: GridView.SnapToRow
                        model: root.iconsList
                        delegate: QQC2.ToolButton {
                            width: iconGridView.cellWidth
                            height: width
                            highlighted: iconGridView.currentIndex === index
                            icon {
                                name: modelData
                                width: units.gu(3)
                                height: units.gu(3)
                            }
                            onClicked: {
                                iconGridView.currentIndex = index
                                PopupUtils.close(iconMenu)
                            }
                        }
                    }
                }
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
         Dialog {
            id: addAppToAppGridDialog
             
            property string gridName
            property var selectApps: []
            property bool selectAll: false // select all dirty hack LOL

            signal confirm(var appsList)

            onConfirm: PopupUtils.close(addAppToAppGridDialog)

            property bool reparentToRootItem: false

            title: 'Add Apps to "%1"'.arg(gridName)
            anchorToKeyboard: false // Handle the keyboard anchor via shell.popupParent

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

            Button {
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
                text: "Cancel"
                onClicked: PopupUtils.close(addAppToAppGridDialog)
            }
            RowLayout {
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

                anchors {
                    left: parent.left
                    right: parent.right
                }
                textSize: Label.Large
                visible: appListView.count === 0
                text: "No app to add"
                height: units.gu(10)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            ListView {
                id: appListView

                height: contentHeight
                interactive: false
                clip: true

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

            onEditModeChanged: {
                // WORKAROUND: Store current contentHeight when entering editMode so that it won't flick when moving an app
                if (editMode) {
                    customGridView.contentHeightInEditMode = customGridView.contentHeight
                    customGridView.resetHeader()
                }
            }

            LPHeader {
                id: labelHeader

                // Ideally we have 4 inches from the bottom of the screen so top items are more reachable.
                readonly property real idealRechableHeight: shell.convertFromInch(3.5)
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
                        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }

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
                focus: true
                contentHeight: {
                    if (!customAppGridItem.editMode) {
                        let _availableHeight = height - topMargin - bottomMargin
                        let _heightDiff = _availableHeight - customGridLoader.height
                        if (_heightDiff >= 0) {
                            return _availableHeight
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
                                    customGridView.positionToEnd()
                                } else {
                                    customGridView.positionToBeginning()
                                }
                            }

                            if (!inverted) {
                                customGridView.expandHeader()
                            }
                        }
                    }
                }
                
                TapHandler {
                    acceptedPointerTypes: PointerDevice.Finger | PointerDevice.Pen
                    onLongPressed: {
                        if (customAppGridItem.editMode) {
                            customAppGridItem.exitEditMode()
                        } else {
                            customAppGridItem.enterEditMode()
                        }

                        shell.haptics.playSubtle()
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

                    sourceComponent: LPDrawerDock {
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
        readonly property real defaultBottomMargin: units.gu(1)
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
            bottomMargin: (swipeSelectMode ? shell.convertFromInch(0.3) : 0) + defaultBottomMargin
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
    // ENH105 - Custom app drawer
    readonly property var iconsList: [
        "account","active-call","add","add-to-call","add-to-playlist","alarm-clock","appointment","appointment-new","attachment","back","bookmark","bookmark-new","broadcast","browser-tabs","burn-after-read"
        ,"bot","favorite-selected", "favorite-unselected", "filter", "properties", "horizontal_distance", "hud", "gestures"
        ,"calendar","calendar-holidays","calendar-today","call-end","call-start","call-stop","camcorder","camera-flip","camera-grid","camera-self-timer","cancel","clock","close","compose","contact","contact-group"
        ,"contact-new","contextual-menu","crop","delete","document-open","document-preview","document-print","document-save","document-save-as","down","edit","edit-clear","edit-copy","edit-cut","edit-delete"
        ,"edit-find","edit-paste","edit-redo","edit-select-all","edit-undo","email","erase","event","event-new","external-link","filters","find","finish","flash-auto","flash-off","flash-on","flash-redeyes"
        ,"go-down","go-first","go-home","go-last","go-next","go-previous","go-up","grip-large","gtk-add","help","help-contents","history","home","image-quality","import","inbox","inbox-all","incoming-call"
        ,"info","insert-image","insert-link","junk","keyboard-caps-disabled","keyboard-caps-enabled","keyboard-caps-locked","keyboard-enter","keyboard-spacebar","keyboard-tab","language-chooser","like","list-add"
        ,"list-remove","livetv","location","lock","lock-broken","mail-forward","mail-forwarded","mail-mark-important","mail-read","mail-replied","mail-replied-all","mail-reply","mail-reply-all","mail-unread"
        ,"media-eject","media-playback-pause","media-playback-start","media-playback-start-rtl","media-playback-stop","media-playlist","media-playlist-repeat","media-playlist-repeat-one","media-playlist-shuffle"
        ,"media-preview-pause","media-preview-start","media-preview-start-rtl","media-record","media-seek-backward","media-seek-forward","media-skip-backward","media-skip-forward","merge","message","message-new"
        ,"message-received","message-sent","missed-call","navigation-menu","next","night-mode","non-starred","note","note-new","notebook","notebook-new","notification","ok","other-actions","outgoing-call","pinned"
        ,"previous","private-browsing","private-browsing-exit","private-tab-new","redo","reload","reload_all_tabs","reload_page","reminder","reminder-new","remove","remove-from-call","remove-from-group","reset"
        ,"retweet","revert","rotate-left","rotate-right","save","save-as","save-to","scope-manager","security-alert","select","select-none","select-undefined","send","settings","share","slideshow","sort-listitem"
        ,"starred","start","stock_alarm-clock","stock_application","stock_appointment","stock_contact","stock_document","stock_document-landscape","stock_ebook","stock_email","stock_event","stock_image","stock_key","stock_link","stock_lock","stock_message","stock_music","stock_note","stock_notebook","stock_notification","stock_reminder","stock_ringtone","stock_store","stock_usb","stock_video","stock_website","stop","stopwatch","stopwatch-lap","swap","sync","system-lock-screen","system-log-out","system-restart","system-shutdown","system-suspend","tab-new","tag","thumb-down","thumb-up","tick","timer","torch-off","torch-on","undo","unlike","unpinned","up","user-admin","user-switch","view-collapse","view-expand","view-fullscreen","view-grid-symbolic","view-list-symbolic","view-off","view-on","view-refresh","view-restore","view-rotate","voicemail","zoom-in","zoom-out","address-book-app-symbolic","amazon-symbolic","calculator-app-symbolic","calendar-app-symbolic","camera-app-symbolic","clock-app-symbolic","dekko-app-symbolic","dialer-app-symbolic","docviewer-app-symbolic","dropbox-symbolic","ebay-symbolic","evernote-symbolic","facebook-symbolic","feedly-symbolic","fitbit-symbolic","gallery-app-symbolic","gmail-symbolic","google-calendar-symbolic","google-maps-symbolic","google-plus-symbolic","googleplus-symbolic","maps-app-symbolic","mediaplayer-app-symbolic","messaging-app-symbolic","music-app-symbolic","notes-app-symbolic","pinterest-symbolic","pocket-symbolic","preferences-color-symbolic","preferences-desktop-accessibility-symbolic","preferences-desktop-accounts-symbolic","preferences-desktop-media-symbolic","preferences-desktop-display-symbolic","preferences-desktop-keyboard-shortcuts-symbolic","preferences-desktop-launcher-symbolic","preferences-desktop-locale-symbolic","preferences-desktop-login-items-symbolic","preferences-desktop-notifications-symbolic","preferences-desktop-sounds-symbolic","preferences-desktop-wallpaper-symbolic","preferences-network-bluetooth-active-symbolic","preferences-network-bluetooth-disabled-symbolic","preferences-network-cellular-symbolic","preferences-network-hotspot-symbolic","preferences-network-wifi-active-symbolic","preferences-network-wifi-no-connection-symbolic","preferences-system-battery-000-charging-symbolic","preferences-system-battery-010-charging-symbolic","preferences-system-battery-020-charging-symbolic","preferences-system-battery-030-charging-symbolic","preferences-system-battery-040-charging-symbolic","preferences-system-battery-050-charging-symbolic","preferences-system-battery-060-charging-symbolic","preferences-system-battery-070-charging-symbolic","preferences-system-battery-080-charging-symbolic","preferences-system-battery-090-charging-symbolic","preferences-system-battery-100-charging-symbolic","preferences-system-battery-charged-symbolic","preferences-system-phone-symbolic","preferences-system-privacy-symbolic","preferences-system-time-symbolic","preferences-system-updates-symbolic","rssreader-app-symbolic","skype-symbolic","songkick-symbolic","soundcloud-symbolic","spotify-symbolic","system-settings-symbolic","system-users-symbolic","telegram-symbolic","terminal-app-symbolic","twc-symbolic","twitter-symbolic","ubuntu-logo-symbolic","ubuntu-sdk-symbolic","ubuntu-store-symbolic","ubuntuone-symbolic","vimeo-symbolic","weather-app-symbolic","webbrowser-app-symbolic","wechat-symbolic","wikipedia-symbolic","youtube-symbolic","audio-carkit-symbolic","audio-headphones-symbolic","audio-headset-symbolic","audio-input-microphone-muted-symbolic","audio-input-microphone-symbolic","audio-speakers-bluetooth-symbolic","audio-speakers-muted-symbolic","audio-speakers-symbolic","camera-photo-symbolic","camera-web-symbolic","computer-laptop-symbolic","computer-symbolic","drive-harddisk-symbolic","drive-optical-symbolic","drive-removable-symbolic","input-dialpad-hidden-symbolic","input-dialpad-symbolic","input-gaming-symbolic","input-keyboard-symbolic","input-mouse-symbolic","input-tablet-symbolic","input-touchpad-symbolic","media-flash-symbolic","media-optical-symbolic","media-removable-symbolic","multimedia-player-symbolic","network-printer-symbolic","network-wifi-symbolic","network-wired-symbolic","phone-apple-iphone-symbolic","phone-cellular-symbolic","phone-smartphone-symbolic","phone-symbolic","phone-uncategorized-symbolic","printer-symbolic","sdcard-symbolic","simcard","smartwatch-symbolic","tablet-symbolic","video-display-symbolic","wireless-display-symbolic","application-pdf-symbolic","application-x-archive-symbolic","audio-x-generic-symbolic","empty-symbolic","image-x-generic-symbolic","package-x-generic-symbolic","text-css-symbolic","text-html-symbolic","text-x-generic-symbolic","text-xml-symbolic","video-x-generic-symbolic","x-office-document-symbolic","x-office-presentation-symbolic","x-office-spreadsheet-symbolic","distributor-logo","folder-symbolic","network-server-symbolic","airplane-mode","airplane-mode-disabled","alarm","alarm-missed","audio-input-microphone-high","audio-input-microphone-high-symbolic","audio-input-microphone-low-symbolic","audio-input-microphone-low-zero","audio-input-microphone-low-zero-panel","audio-input-microphone-medium-symbolic","audio-input-microphone-muted-symbolic","audio-output-none","audio-output-none-panel","audio-volume-high","audio-volume-high-panel","audio-volume-low","audio-volume-low-panel","audio-volume-low-zero","audio-volume-low-zero-panel","audio-volume-medium","audio-volume-medium-panel","audio-volume-muted","audio-volume-muted-blocking-panel","audio-volume-muted-panel","battery-000","battery-000-charging","battery-010","battery-010-charging","battery-020","battery-020-charging","battery-030","battery-030-charging","battery-040","battery-040-charging","battery-050","battery-050-charging","battery-060","battery-060-charging","battery-070","battery-070-charging","battery-080","battery-080-charging","battery-090","battery-090-charging","battery-100","battery-100-charging","battery-caution","battery-caution-charging-symbolic","battery-caution-symbolic","battery-charged","battery-empty-charging-symbolic","battery-empty-symbolic","battery-full-charged-symbolic","battery-full-charging-symbolic","battery-full-symbolic","battery-good-charging-symbolic","battery-good-symbolic","battery-low-charging-symbolic","battery-low-symbolic","battery-missing-symbolic","battery_charged","battery_empty","battery_full","bluetooth-active","bluetooth-disabled","bluetooth-paired","dialog-error-symbolic","dialog-question-symbolic","dialog-warning-symbolic","display-brightness-max","display-brightness-min","display-brightness-symbolic","gpm-battery-000","gpm-battery-000-charging","gpm-battery-010","gpm-battery-010-charging","gpm-battery-020","gpm-battery-020-charging","gpm-battery-030","gpm-battery-030-charging","gpm-battery-040","gpm-battery-040-charging","gpm-battery-050","gpm-battery-050-charging","gpm-battery-060","gpm-battery-060-charging","gpm-battery-070","gpm-battery-070-charging","gpm-battery-080","gpm-battery-080-charging","gpm-battery-090","gpm-battery-090-charging","gpm-battery-100","gpm-battery-100-charging","gpm-battery-charged","gpm-battery-empty","gpm-battery-missing","gps","gps-disabled","gsm-3g-disabled","gsm-3g-full","gsm-3g-full-secure","gsm-3g-high","gsm-3g-high-secure","gsm-3g-low","gsm-3g-low-secure","gsm-3g-medium","gsm-3g-medium-secure","gsm-3g-no-service","gsm-3g-none","gsm-3g-none-secure","hotspot-active","hotspot-connected","hotspot-disabled","indicator-messages","indicator-messages-new","location-active","location-disabled","location-idle","messages","messages-new","microphone-sensitivity-high","microphone-sensitivity-high-symbolic","microphone-sensitivity-low","microphone-sensitivity-low-symbolic","microphone-sensitivity-low-zero","microphone-sensitivity-medium","microphone-sensitivity-medium-symbolic","microphone-sensitivity-muted-symbolic","multimedia-volume-high","multimedia-volume-low","network-cellular-3g","network-cellular-4g","network-cellular-edge","network-cellular-hspa","network-cellular-hspa-plus","network-cellular-lte","network-cellular-none","network-cellular-pre-edge","network-cellular-roaming","network-secure","network-vpn","network-vpn-connected","network-vpn-connecting","network-vpn-disabled","network-vpn-error","network-wired","network-wired-active","network-wired-connected","network-wired-connecting","network-wired-disabled","network-wired-error","network-wired-offline","nm-adhoc","nm-no-connection","nm-signal-00","nm-signal-00-secure","nm-signal-100","nm-signal-100-secure","nm-signal-25","nm-signal-25-secure","nm-signal-50","nm-signal-50-secure","nm-signal-75","nm-signal-75-secure","no-simcard","orientation-lock","orientation-lock-disabled","printer-error-symbolic","ringtone-volume-high","ringtone-volume-low","simcard-1","simcard-2","simcard-error","simcard-locked","stock_volume-max","stock_volume-min","sync-error","sync-idle","sync-offline","sync-paused","sync-updating","system-devices-panel","system-devices-panel-alert","system-devices-panel-information","transfer-error","transfer-none","transfer-paused","transfer-progress","transfer-progress-download","transfer-progress-upload","volume-max","volume-min","weather-chance-of-rain","weather-chance-of-snow","weather-chance-of-storm","weather-chance-of-wind","weather-clear-night-symbolic","weather-clear-symbolic","weather-clouds-night-symbolic","weather-clouds-symbolic","weather-few-clouds-night-symbolic","weather-few-clouds-symbolic","weather-flurries-symbolic","weather-fog-symbolic","weather-hazy-symbolic","weather-overcast-symbolic","weather-severe-alert-symbolic","weather-showers-scattered-symbolic","weather-showers-symbolic","weather-sleet-symbolic","weather-snow-symbolic","weather-storm-symbolic","wifi-connecting","wifi-full","wifi-full-secure","wifi-high","wifi-high-secure","wifi-low","wifi-low-secure","wifi-medium","wifi-medium-secure","wifi-no-connection","wifi-none","wifi-none-secure","Toolkit","toolkit_arrow-down","toolkit_arrow-left","toolkit_arrow-right","toolkit_arrow-up","toolkit_bottom-edge-hint","toolkit_chevron-down_1gu","toolkit_chevron-down_2gu","toolkit_chevron-down_3gu","toolkit_chevron-down_4gu","toolkit_chevron-ltr_1gu","toolkit_chevron-ltr_2gu","toolkit_chevron-ltr_3gu","toolkit_chevron-ltr_4gu","toolkit_chevron-rtl_1gu","toolkit_chevron-rtl_2gu","toolkit_chevron-rtl_3gu","toolkit_chevron-rtl_4gu","toolkit_chevron-up_1gu","toolkit_chevron-up_2gu","toolkit_chevron-up_3gu","toolkit_chevron-up_4gu","toolkit_cross","toolkit_input-clear","toolkit_input-search","toolkit_scrollbar-stepper","toolkit_tick"
    ]
    // ENH105 - End
}
