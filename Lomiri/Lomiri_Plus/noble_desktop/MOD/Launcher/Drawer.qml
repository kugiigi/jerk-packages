/*
 * Copyright (C) 2016 Canonical Ltd.
 * Copyright (C) 2020-2021 UBports Foundation
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
import Lomiri.Launcher 0.1
import Utils 0.1
import "../Components"
import Qt.labs.settings 1.0
import GSettings  1.0
import AccountsService 0.1
import QtGraphicalEffects 1.0
// ENH105 - Custom app drawer
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.12
// ENH105 - End
// ENH139 - System Direct Actions
import ".." as Root
// ENH139 - End

FocusScope {
    id: root

    property int panelWidth: 0
    readonly property bool moving: (appList && appList.moving) ? true : false
    readonly property Item searchTextField: searchField
    // ENH132 - App drawer icon size settings
    // readonly property real delegateWidth: units.gu(10)
    readonly property real delegateWidth: units.gu(10) * delegateSizeMultiplier
    readonly property real delegateHeight: units.gu(11)
    readonly property real delegateSizeMultiplier: shell.settings.drawerIconSizeMultiplier
    // ENH132 - End
    property url background
    visible: x > -width
    property var fullyOpen: x === 0
    property var fullyClosed: x === -width
    // ENH007 - Bottom search in drawer
    property bool inverted
    // ENH007 - End
    // ENH059 - Redesigned drawer search field
    property bool searchMode: false
    // ENH059 - End
    // ENH131 - Extend drawer to behind top panel
    property real topPanelHeight: 0
    // ENH131 - End
    // ENH105 - Custom app drawer
    property bool launcherInverted: false
    // ENH105 - End
    // ENH139 - System Direct Actions
    property alias appModel: appDrawerModel
    // ENH139 - End
    // ENH170 - Adjust top panel based on Drawer and Indicator panels
    property real drawerOpacity: bg.colorOpacity
    property color drawerColor: bg.panelColor
    // ENH170 - End
    // ENH167 - Behavior changes for custom opacity/color of components
    property color drawerBGColor: bg.color
    // ENH167 - End

    signal applicationSelected(string appId)

    // Request that the Drawer is opened fully, if it was partially closed then
    // brought back
    signal openRequested()

    // Request that the Drawer (and maybe its parent) is hidden, normally if
    // the Drawer has been dragged away.
    signal hideRequested()

    property bool allowSlidingAnimation: false
    property bool draggingHorizontally: false
    property int dragDistance: 0

    property var hadFocus: false
    property var oldSelectionStart: null
    property var oldSelectionEnd: null

    anchors {
        onRightMarginChanged: refocusInputAfterUserLetsGo()
    }

    Behavior on anchors.rightMargin {
        enabled: allowSlidingAnimation && !draggingHorizontally
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    // ENH105 - Custom app drawer
    onFullyClosedChanged: {
        if (fullyClosed) {
            appList.collapseDock()
            appList.exitEditMode()
            appList.exitAppGridEditMode()
        }
    }
    // ENH105 - End

    onDraggingHorizontallyChanged: {
        // See refocusInputAfterUserLetsGo()
        if (draggingHorizontally) {
            hadFocus = searchField.focus;
            oldSelectionStart = searchField.selectionStart;
            oldSelectionEnd = searchField.selectionEnd;
            // ENH105 - Custom app drawer
            // Avoid lagging when the searchfield is at the bottom
            // searchField.focus = false;
            // ENH105 - End
        } else {
            if (x < -units.gu(10)) {
                hideRequested();
            } else {
                openRequested();
            }
            refocusInputAfterUserLetsGo();
        }
    }

    Keys.onEscapePressed: {
        root.hideRequested()
    }

    onDragDistanceChanged: {
        anchors.rightMargin = Math.max(-drawer.width, anchors.rightMargin + dragDistance);
    }

    function resetOldFocus() {
        hadFocus = false;
        oldSelectionStart = null;
        oldSelectionEnd = null;
    }

    function refocusInputAfterUserLetsGo() {
        if (!draggingHorizontally) {
            if (fullyOpen && hadFocus) {
                searchField.focus = hadFocus;
                searchField.select(oldSelectionStart, oldSelectionEnd);
            } else if (fullyOpen || fullyClosed) {
                resetOldFocus();
            }

            if (fullyClosed) {
                searchField.text = "";
                appList.currentIndex = 0;
                searchField.focus = false;
                appList.focus = false;
            }
        }
    }

    function focusInput() {
        unFocusInput() // For some reason, it won't focus again after closing the OSK in focal so do this
        searchField.selectAll();
        searchField.forceActiveFocus();
    }

    function unFocusInput() {
        searchField.focus = false;
    }

    Keys.onPressed: {
        if (event.text.trim() !== "") {
            focusInput();
            searchField.text = event.text;
        }
        switch (event.key) {
            case Qt.Key_Right:
            case Qt.Key_Left:
            case Qt.Key_Down:
                appList.focus = true;
                break;
            case Qt.Key_Up:
                focusInput();
                break;
        }
        // Catch all presses here in case the navigation lets something through
        // We never want to end up in the launcher with focus
        event.accepted = true;
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onWheel: wheel.accepted = true
    }

    Rectangle {
        // ENH170 - Adjust top panel based on Drawer and Indicator panels
        id: bg
        // ENH170 - End
        anchors.fill: parent
        // ENH165 - Drawer appearance settings
        // color: "#BF000000"
        readonly property color panelColor: shell.settings.useCustomDrawerColor ? shell.settings.customDrawerColor : "#000000"
        readonly property real colorOpacity: shell.settings.useCustomDrawerOpacity ? shell.settings.customDrawerOpacity : 0.75
        color: shell.settings.useCustomDrawerColor || shell.settings.useCustomDrawerOpacity ? Qt.hsla(panelColor.hslHue, panelColor.hslSaturation, panelColor.hslLightness, colorOpacity)
                    : "#BF000000"
        // ENH165 - End

        MouseArea {
            id: drawerHandle
            objectName: "drawerHandle"
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            width: units.gu(2)
            property int oldX: 0

            onPressed: {
                handle.active = true;
                oldX = mouseX;
            }
            onMouseXChanged: {
                var diff = oldX - mouseX;
                root.draggingHorizontally |= diff > units.gu(2);
                if (!root.draggingHorizontally) {
                    return;
                }
                root.dragDistance += diff;
                oldX = mouseX
            }
            onReleased: reset()
            onCanceled: reset()

            function reset() {
                root.draggingHorizontally = false;
                handle.active = false;
                root.dragDistance = 0;
            }

            Handle {
                id: handle
                anchors.fill: parent
                active: parent.pressed
                // ENH054 - Transparent drag handle
                transparentBackground: true
                // ENH054 - End
            }
        }

        AppDrawerModel {
            id: appDrawerModel
        }

        AppDrawerProxyModel {
            id: sortProxyModel
            source: appDrawerModel
            filterString: searchField.displayText
            sortBy: AppDrawerProxyModel.SortByAToZ
        }

        Connections {
            target: i18n
            onLanguageChanged: appDrawerModel.refresh()
        }

        Item {
            id: contentContainer
            anchors {
                left: parent.left
                right: drawerHandle.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: root.panelWidth
            }

            // ENH007 - Bottom search in drawer
            state: root.inverted ? "Inverted" : "Normal"
            states: [
                State {
                    name: "Normal"
                    AnchorChanges {
                        target: searchFieldContainer
                        anchors.bottom: undefined
                        anchors.top: parent.top
                    }
                    AnchorChanges {
                        target: appList
                        anchors.bottom: parent.bottom
                        anchors.top: searchFieldContainer.bottom
                    }
                    // ENH131 - Extend drawer to behind top panel
                    PropertyChanges {
                        target: searchFieldContainer
                        anchors.topMargin: (launcherInverted ? root.topPanelHeight : 0) + units.gu(1)
                    }
                    PropertyChanges {
                        target: appList
                        anchors.topMargin: 0
                    }
                    // ENH131 - End
                }
                ,State {
                    name: "Inverted"
                    AnchorChanges {
                        target: searchFieldContainer
                        anchors.bottom: keyboard.target.visible ? keyboardRec.top : parent.bottom
                        anchors.top: undefined
                    }
                    AnchorChanges {
                        target: appList
                        anchors.bottom: searchFieldContainer.top
                        anchors.top: parent.top
                    }
                    // ENH131 - Extend drawer to behind top panel
                    PropertyChanges {
                        target: searchFieldContainer
                        anchors.topMargin: units.gu(1)
                    }
                    PropertyChanges {
                        target: appList
                        anchors.topMargin: root.topPanelHeight + units.gu(1)
                    }
                    // ENH131 - End
                }
            ]
            // ENH007 - End

            Item {
                id: searchFieldContainer
                // ENH105 - Custom app drawer
                readonly property bool fullyShown: height == searchField.height
                // ENH105 - End
                // ENH007 - Bottom search in drawer
                // height: units.gu(4)
                // anchors { left: parent.left; top: parent.top; right: parent.right; margins: units.gu(1) }
                // ENH059 - Redesigned drawer search field
                //height: shell.settings.bigDrawerSearchField ? units.gu(5) : units.gu(4)
                height: root.searchMode || !shell.settings.hideDrawerSearch ? searchField.height : 0
                Behavior on height {
                    enabled: root.fullyOpen
                    LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
                }
                // ENH059 - End
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: units.gu(1)
                }
                transitions: Transition {
                    AnchorAnimation { duration: LomiriAnimation.FastDuration }
                }
                // ENH007 - End

                TextField {
                    id: searchField
                    objectName: "searchField"
                    inputMethodHints: Qt.ImhNoPredictiveText; //workaround to get the clear button enabled without the need of a space char event or change in focus
                    // ENH059 - Redesigned drawer search field
                    anchors {
                        left: parent.left
                        // top: parent.top
                        right: parent.right
                        bottom: parent.bottom
                    }
                    opacity: searchFieldContainer.height > 0 ? 1 : 0
                    visible: opacity > 0
                    height: shell.settings.bigDrawerSearchField ? units.gu(5) : units.gu(4)
                    // ENH059 - End
                    placeholderText: i18n.tr("Search…")
                    z: 100

                    // ENH007 - Bottom search in drawer
                    // KeyNavigation.down: appList
                    font.pixelSize: parent.height * 0.5
                    KeyNavigation.down: root.inverted ? null : appList
                    KeyNavigation.up: root.inverted ? appList : null
                    // ENH007 - End
                    // ENH059 - Redesigned drawer search field
                    onFocusChanged: root.searchMode = focus
                    // ENH059 - End

                    onAccepted: {
                        if (searchField.displayText != "" && appList) {
                            // In case there is no currentItem (it might have been filtered away) lets reset it to the first item
                            if (!appList.currentItem) {
                                appList.currentIndex = 0;
                            }
                            root.applicationSelected(appList.getFirstAppId());
                        }
                    }
                }
            }

            DrawerGridView {
                id: appList
                objectName: "drawerAppList"
                anchors {
                    left: parent.left
                    right: parent.right
                    top: searchFieldContainer.bottom
                    bottom: parent.bottom
                }
                height: rows * delegateHeight
                clip: true
                // ENH007 - Bottom search in drawer
                verticalLayoutDirection: contentContainer.state == "Inverted" ? GridView.BottomToTop : GridView.TopToBottom
                // ENH007 - End

                model: sortProxyModel
                delegateWidth: root.delegateWidth
                // ENH132 - App drawer icon size settings
                // delegateHeight: units.gu(11)
                delegateHeight: root.delegateHeight
                delegateSizeMultiplier: root.delegateSizeMultiplier
                // ENH132 - End
                // ENH105 - Custom app drawer
                launcherInverted: root.launcherInverted
                viewMargin: searchFieldContainer.fullyShown ? units.gu(2) : 0
                rawModel: appDrawerModel
                onApplicationSelected: root.applicationSelected(appId)
                onApplicationContextMenu: {
                    // PopupUtils is not used because it doesn't follow the orientation properly and not shown in screenshots
                    //contextMenuItem = PopupUtils.open(contextMenuComponent, caller, {"appId": appId, "fromDocked": fromDocked})
                    contextMenuItem = contextMenuComponent.createObject(shell.popupParent, { "caller": caller, "appId": appId, "fromDocked": fromDocked, "fromCustomAppGrid": fromCustomAppGrid });
                    contextMenuItem.z = Number.MAX_VALUE
                    contextMenuItem.show()
                    shell.haptics.playSubtle()
                }
                // delegate: drawerDelegateComponent
                delegate: LPDrawerAppDelegate {
                    focused: (index === GridView.view.currentIndex && GridView.view.activeFocus)
                                        || (appList.contextMenuItem && appList.contextMenuItem.appId == model.appId && !appList.contextMenuItem.fromDocked)
                    width: GridView.view.cellWidth
                    // ENH132 - App drawer icon size settings
                    // height: units.gu(11)
                    height: GridView.view.cellHeight
                    // ENH132 - End
                    objectName: "drawerItem_" + model.appId
                    delegateWidth: root.delegateWidth
                    appId: model.appId
                    appName: model.name
                    iconSource: model.icon
                    // ENH132 - App drawer icon size settings
                    delegateSizeMultiplier: root.delegateSizeMultiplier
                    // ENH132 - End

                    onApplicationSelected: appList.applicationSelected(appId)
                    onApplicationContextMenu: appList.applicationContextMenu(appId, this, false, false)
                }
                showDock: true
                showCustomAppGrids: shell.settings.enableCustomAppGrid
                fullAppGridLast: shell.settings.placeFullAppGridToLast
                Connections {
                    target: searchField
                    // Delay showDock change to reduce UI stutter
                    onTextChanged: delayHideDock.restart()
                }
                Timer {
                    id: delayHideDock
                    property int previousAppGridIndex: -1
                    interval: 100
                    onTriggered: {
                        if (searchField.text == "") {
                            appList.showDock = true
                            if (previousAppGridIndex > -1) {
                                appList.showAppGrid(previousAppGridIndex)
                                previousAppGridIndex = -1
                            }
                        } else {
                            appList.showDock = false
                            if (previousAppGridIndex === -1) {
                                previousAppGridIndex = appList.currentPageIndex
                            }
                            appList.showFullAppGrid()
                        }
                    }
                }
                // ENH105 - End
                onDraggingVerticallyChanged: {
                    if (draggingVertically) {
                        unFocusInput();
                    }
                }

                refreshing: appDrawerModel.refreshing
                onRefresh: {
                    appDrawerModel.refresh();
                }
            }
            // ENH007 - Bottom search in drawer
            Item {
                id: keyboardRec
                height: root.fullyOpen ? keyboard.target.keyboardRectangle.height : 0
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                Behavior on height {
                    NumberAnimation {
                        duration: LomiriAnimation.FastDuration; easing.type: Easing.OutCubic
                    }
                }
            }
            Connections {
                id: keyboard
                target: Qt.inputMethod
            }
            // ENH007 - End
            // ENH059 - Redesigned drawer search field
            Icon {
                id: bottomHintSearch
                visible: searchSwipeArea.enabled && shell.settings.showBottomHintDrawer
                name: "toolkit_bottom-edge-hint"
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                height: units.gu(3)
                width: height
            }

            SwipeArea {
                id: searchSwipeArea

                readonly property real longSwipeThreshold: shell.convertFromInch(1)
                readonly property real shortSwipeThreshold: shell.convertFromInch(0.5)
                readonly property bool longSwipe: distance > longSwipeThreshold
                readonly property bool shortSwipe: distance > shortSwipeThreshold

                direction: SwipeArea.Upwards
                height: units.gu(2)
                enabled: shell.settings.hideDrawerSearch || shell.settings.enableDrawerBottomSwipe
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }
                onLongSwipeChanged: {
                    if (longSwipe) {
                        shell.haptics.playSubtle()
                    }
                }
                onDraggingChanged: {
                    if (!dragging) {
                        if (longSwipe) {
                            root.focusInput()
                            shell.haptics.play()
                        }
                    }
                }
            }
            Rectangle {
                color: theme.palette.normal.foreground
                radius: width / 2
                height: units.gu(6)
                width: height
                visible: opacity > 0
                opacity: searchSwipeArea.dragging && searchSwipeArea.longSwipe ? 1 : 0
                Behavior on opacity { LomiriNumberAnimation {} }
                anchors {
                    bottom: searchSwipeArea.top
                    bottomMargin: searchSwipeArea.longSwipeThreshold + height + units.gu(2)
                    horizontalCenter: searchSwipeArea.horizontalCenter
                }

                Icon {
                    anchors.centerIn: parent
                    width: units.gu(3)
                    height: width
                    name: "search"
                    color: theme.palette.normal.foregroundText
                }
            }
            // ENH059 - End
        }
        // ENH105 - Custom app drawer
        Component {
            id: appGridsComponent

            ActionSelectionPopover {
                id: appGridMenu

                property var appId
                property bool skipCheckExists: false

                actions: actionList
                grabDismissAreaEvents: true
                automaticOrientation: false
                delegate: ListItem {
                    onClicked: PopupUtils.close(appGridMenu)
                    ListItemLayout {
                       title.text: action.text
                       Icon {
                            name: action.iconName
                            SlotsLayout.position: SlotsLayout.Leading;
                            width: units.gu(3)
                            color: theme.palette.normal.foregroundText
                        }
                   }
                }

                ActionList {
                    id: actionList
                }

                Component.onCompleted: {
                    let _appGridList = []
                    let _hasCustomAppGrid = shell.settings.customAppGrids.length > 0
                    if (appGridMenu.appId && _hasCustomAppGrid) {
                        for (let i = 0; i < shell.settings.customAppGrids.length; i++) {
                            let _foundItem = shell.settings.customAppGrids[i]
                            if (_foundItem) {
                                if (!_foundItem.apps.includes(appGridMenu.appId) || appGridMenu.skipCheckExists) {
                                    let _gridItem = { "name": _foundItem.name, "iconName": _foundItem.icon, "itemIndex": shell.settings.customAppGrids.indexOf(_foundItem) }
                                    _appGridList.push(_gridItem)
                                }
                            }
                        }
                    }

                    appGridsRepeater.model = _appGridList.slice()
                }

                Instantiator {
                    id: appGridsRepeater
                    asynchronous: true
                    delegate: Action {
                        id: appGridAction

                        text: modelData.name
                        iconName: modelData.iconName ? modelData.iconName : ""
                        onTriggered: {
                            appList.addToAppGrid(modelData.itemIndex, appGridMenu.appId)
                        }
                    }

                    onObjectAdded: {
                        // For some reason an empty action is added
                        if (object.text.trim() !== "") {
                            actionList.addAction(object)
                        }
                    }
                }
            }
        }
        Component {
            id: contextMenuComponent

            ActionSelectionPopover {
                id: contextMenu

                property string appId
                property bool fromDocked: false
                property bool fromCustomAppGrid: false

                grabDismissAreaEvents: true
                automaticOrientation: false
                actions: [ openStoreAction, addToDockAction, addToAppGridAction, removeAppGridAction, pinToLauncherAction, addToDirectActionsAction, editDockAction, editAppGridAction, addAllToAppGridAction ]
                callerMargin: units.gu(3)

                function findFromPinnedApps(model, _appId) {
                    for (var i = 0; i < model.rowCount(); ++i) {
                        let _currentApp = model.get(i)
                        if (_currentApp.pinned && _currentApp.appId == _appId) {
                           return _currentApp
                        }
                    }
                    return null
                }

                function closePopup() {
                    hide()
                    destroy()
                    appList.contextMenuItem = null
                }

                onVisibleChanged: {
                    if (!visible) {
                        contextMenu.closePopup()
                    }
                }

                Connections {
                    target: root
                    onFullyOpenChanged: {
                        if (!target.fullyOpen) {
                            contextMenu.closePopup()
                        }
                    }
                }
                
                Action {
                    id: openStoreAction

                    text: "View in OpenStore"
                    iconName: "ubuntu-store-symbolic"
                    visible: enabled
                    enabled: contextMenu.appId.includes(".") // Open OpenStore page if app is a click
                    onTriggered: {
                        let _appId = contextMenu.appId
                        var splitAppId = _appId.split("_");
                        Qt.openUrlExternally("https://open-store.io/app/" + _appId.replace("_" + splitAppId[splitAppId.length-1],"") + "/");
                    }
                }
                Action {
                    id: addToDockAction

                    readonly property bool isDocked: contextMenu.appId ? shell.settings.drawerDockApps.includes(contextMenu.appId) : false

                    text: isDocked ? "Remove from Dock" : "Add to Dock"
                    iconName: isDocked ? "non-starred" : "starred"
                    visible: shell.settings.enableDrawerDock
                    onTriggered: {
                        let _appId = contextMenu.appId
                        if (isDocked) {
                            appList.removeFromDock(_appId)
                        } else {
                            appList.addToDock(_appId)
                        }
                    }
                }
                Action {
                    id: addToAppGridAction

                    readonly property bool canStillBeAdded: {
                        let _isCurrentlyInFullGrid = appList.currentCustomPageIndex === -1
                        let _hasCustomAppGrid = shell.settings.customAppGrids.length > 0
                        if (contextMenu.appId && _hasCustomAppGrid) {
                            for (let i = 0; i < shell.settings.customAppGrids.length; i++) {
                                let _foundItem = shell.settings.customAppGrids[i]
                                if (_foundItem && !_foundItem.apps.includes(contextMenu.appId)) {
                                    return true
                                }
                            }
                        }

                        return false
                    }

                    text: "Add to App Grid"
                    iconName: "view-grid-symbolic"
                    visible: shell.settings.enableCustomAppGrid && canStillBeAdded
                    onTriggered: {
                        let _appId = contextMenu.appId
                        if (shell.settings.customAppGrids.length === 1) {
                            appList.addToAppGrid(0, _appId)
                        } else {
                            let _appGridsMenuItem = appGridsComponent.createObject(shell.popupParent, { "caller": root, "appId": appId });
                            _appGridsMenuItem.z = Number.MAX_VALUE
                            _appGridsMenuItem.show()
                        }
                    }
                }
                Action {
                    id: addAllToAppGridAction

                    text: "Add Dock Apps to App Grid"
                    iconName: "view-grid-symbolic"
                    visible: shell.settings.enableCustomAppGrid && contextMenu.fromDocked
                    onTriggered: {
                        let _appId = contextMenu.appId
                        if (shell.settings.customAppGrids.length === 1) {
                            appList.addToAppGrid(0, shell.settings.drawerDockApps)
                        } else {
                            let _appGridsMenuItem = appGridsComponent.createObject(shell.popupParent, { "caller": root, "appId": shell.settings.drawerDockApps, "skipCheckExists": true });
                            _appGridsMenuItem.z = Number.MAX_VALUE
                            _appGridsMenuItem.show()
                        }
                    }
                }
                Action {
                    id: removeAppGridAction

                    readonly property bool canBeRemoved: {
                        let _isCurrentlyInFullGrid = appList.currentCustomPageIndex === -1
                        let _hasCustomAppGrid = shell.settings.customAppGrids.length > 0
                        if (contextMenu.appId && appList.currentCustomPageIndex > -1 && _hasCustomAppGrid && !_isCurrentlyInFullGrid) {
                            let _foundItem = shell.settings.customAppGrids[appList.currentCustomPageIndex]
                            if (_foundItem) {
                                return _foundItem.apps.includes(contextMenu.appId)
                            }
                        }

                        return false
                    }

                    text: "Remove from this App Grid"
                    iconName: "list-remove"
                    visible: shell.settings.enableCustomAppGrid && canBeRemoved
                    onTriggered: {
                        let _appId = contextMenu.appId
                        appList.removeFromAppGrid(appList.currentCustomPageIndex, _appId)
                    }
                }
                Action {
                    id: addToDirectActionsAction

                    readonly property bool isInDirectActions: contextMenu.appId ? shell.settings.directActionList.findIndex(
                                                                         (element) => (element.actionId == contextMenu.appId && element.type == Root.LPDirectActions.Type.App)) > -1
                                                            : false

                    text: isInDirectActions ? "Remove from Direct Actions" : "Add to Direct Actions"
                    iconName: isInDirectActions ? "list-remove" : "add"
                    visible: shell.settings.enableDirectActions
                    onTriggered: {
                        let _appId = contextMenu.appId
                        if (isInDirectActions) {
                            appList.removeFromDirectActions(_appId)
                        } else {
                            appList.addToDirectActions(_appId)
                        }
                    }
                }
                Action {
                    id: editDockAction

                    text: "Edit Dock"
                    iconName: "edit"
                    visible: contextMenu.fromDocked
                    onTriggered: {
                        appList.enterEditMode(contextMenu.appId)
                    }
                }
                Action {
                    id: editAppGridAction

                    text: "Edit App Grid"
                    iconName: "edit"
                    visible: contextMenu.fromCustomAppGrid
                    onTriggered: {
                        appList.enterAppGridEditMode()
                    }
                }
                Action {
                    id: pinToLauncherAction

                    readonly property bool isPinned: contextMenu.appId ? contextMenu.findFromPinnedApps(LauncherModel, contextMenu.appId) : false

                    text: isPinned ? "Unpin from Launcher" : "Pin to Launcher"
                    iconName: "preferences-desktop-launcher-symbolic"
                    
                    onTriggered: {
                        let _appId = contextMenu.appId
                        if (isPinned) {
                            LauncherModel.requestRemove(_appId)
                        } else {
                            LauncherModel.pin(_appId, -1)
                        }
                    }
                }

                delegate: ListItem {
                    visible: action.visible && action.enabled
                    height: visible ? implicitHeight : 0
                    color: hoverMouseArea.containsMouse ? theme.palette.highlighted.background : "transparent"

                    MouseArea {
                        id: hoverMouseArea

                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: units.gu(2)
                        Icon {
                            id: iconItem2
                            Layout.leftMargin: units.gu(2)
                            implicitWidth: units.gu(2)
                            implicitHeight: implicitWidth
                            visible: name !== ""
                            name: action.iconName
                            color: theme.palette.normal.foregroundText
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.rightMargin: units.gu(2)
                            text: action.text
                            horizontalAlignment: iconItem2.visible ? Text.AlignLeft : Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
                    }
                    onClicked: contextMenu.closePopup()
                }
            }
        }
        /*
        Component {
            id: drawerDelegateComponent
            AbstractButton {
                id: drawerDelegate
                width: GridView.view.cellWidth
                height: units.gu(11)
                objectName: "drawerItem_" + model.appId

                readonly property bool focused: index === GridView.view.currentIndex && GridView.view.activeFocus

                onClicked: root.applicationSelected(model.appId)
                onPressAndHold: {
                  if (model.appId.includes(".")) { // Open OpenStore page if app is a click
                    var splitAppId = model.appId.split("_");
                    Qt.openUrlExternally("https://open-store.io/app/" + model.appId.replace("_" + splitAppId[splitAppId.length-1],"") + "/");
                  }
                }
                z: loader.active ? 1 : 0

                Column {
                    width: units.gu(9)
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: childrenRect.height
                    spacing: units.gu(1)

                    LomiriShape {
                        id: appIcon
                        width: units.gu(6)
                        height: 7.5 / 8 * width
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: "medium"
                        borderSource: 'undefined'
                        source: Image {
                            id: sourceImage
                            asynchronous: true
                            sourceSize.width: appIcon.width
                            source: model.icon
                        }
                        sourceFillMode: LomiriShape.PreserveAspectCrop

                        StyledItem {
                            styleName: "FocusShape"
                            anchors.fill: parent
                            StyleHints {
                                visible: drawerDelegate.focused
                                radius: units.gu(2.55)
                            }
                        }
                    }

                    Label {
                        id: label
                        text: model.name
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: Text.AlignHCenter
                        fontSize: "small"
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight

                        Loader {
                            id: loader
                            x: {
                                var aux = 0;
                                if (item) {
                                    aux = label.width / 2 - item.width / 2;
                                    var containerXMap = mapToItem(contentContainer, aux, 0).x
                                    if (containerXMap < 0) {
                                        aux = aux - containerXMap;
                                        containerXMap = 0;
                                    }
                                    if (containerXMap + item.width > contentContainer.width) {
                                        aux = aux - (containerXMap + item.width - contentContainer.width);
                                    }
                                }
                                return aux;
                            }
                            y: -units.gu(0.5)
                            active: label.truncated && (drawerDelegate.hovered || drawerDelegate.focused)
                            sourceComponent: Rectangle {
                                color: LomiriColors.jet
                                width: fullLabel.contentWidth + units.gu(1)
                                height: fullLabel.height + units.gu(1)
                                radius: units.dp(4)
                                Label {
                                    id: fullLabel
                                    width: Math.min(root.delegateWidth * 2, implicitWidth)
                                    wrapMode: Text.Wrap
                                    horizontalAlignment: Text.AlignHCenter
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    anchors.centerIn: parent
                                    text: model.name
                                    fontSize: "small"
                                }
                            }
                        }
                    }
                }
            }
        }
        */
        // ENH105 - End
    }
}
