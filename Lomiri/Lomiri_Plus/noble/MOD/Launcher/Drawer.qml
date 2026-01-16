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

import QtQuick 2.15
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
// ENH236 - Custom drawer search
import QtQuick.Controls 2.15 as QQC2
import ".."
// ENH236 - End

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
    property bool lightMode : false
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
    property bool enableDrawerDock: shell.settings.enableDrawerDock
    // ENH105 - End
    // ENH139 - System Direct Actions
    property alias appModel: appDrawerModel
    // ENH139 - End
    // ENH170 - Adjust top panel based on Drawer and Indicator panels
    property real drawerOpacity: bg.color.a
    property color drawerColor: Qt.hsla(bg.panelColor.hslHue, bg.panelColor.hslSaturation, bg.panelColor.hslLightness, 1)
    // ENH170 - End
    // ENH167 - Behavior changes for custom opacity/color of components
    property color drawerBGColor: bg.color
    // ENH167 - End
    // ENH236 - Custom drawer search
    property bool enableCustomSearch: shell.settings.enableCustomDrawerSearch
    readonly property bool showSearchButton: enableCustomSearch && shell.settings.customDrawerSearchShowButton
    readonly property alias customSearchItem: customSearchLoader.item
    readonly property var customSearchField: customSearchItem ? customSearchItem.searchField : null
    readonly property bool alwaysShowCustomSearchField: !launcherInverted
    readonly property bool showCustomSearchPage: customSearchMode || !launcherInverted // Always show when in Windowed mode
    property bool customSearchMode: false
    property Item searchFieldItem: customSearchField ? customSearchField : searchField
    // ENH236 - End

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
            // ENH233 - Drawer animation options
            // duration: 300
            duration: {
                switch (shell.settings.drawerAnimationSpeed) {
                    case 0:
                        return 300
                    case 1:
                        return 200
                    case 2:
                        return 100
                    case 3:
                        return 10
                }
            }
            // ENH233 - End
            easing.type: Easing.OutCubic
        }
    }

    // ENH105 - Custom app drawer
    onFullyClosedChanged: {
        if (fullyClosed) {
            appList.collapseDock()
            appList.exitEditMode()
            appList.exitAppGridEditMode()
            // ENH236 - Custom drawer search
            root.customSearchMode = false
            if (root.alwaysShowCustomSearchField && root.customSearchItem) {
                root.customSearchItem.reset()
            }
            // ENH236 - End
        }
    }
    // ENH105 - End

    onDraggingHorizontallyChanged: {
        // See refocusInputAfterUserLetsGo()
        if (draggingHorizontally) {
            // ENH236 - Custom drawer search
            // hadFocus = searchField.focus;
            // oldSelectionStart = searchField.selectionStart;
            // oldSelectionEnd = searchField.selectionEnd;
            hadFocus = searchFieldItem.focus;
            oldSelectionStart = searchFieldItem.selectionStart;
            oldSelectionEnd = searchFieldItem.selectionEnd;
            // ENH236 - End
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
        // ENH236 - Custom drawer search
        // root.hideRequested()
        if (root.customSearchMode) {
            root.customSearchMode = false
            if (root.alwaysShowCustomSearchField && root.customSearchItem) {
                root.customSearchItem.reset()
            }
        } else {
            root.hideRequested()
        }
        // ENH236 - End
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
                // ENH236 - Custom drawer search
                // searchField.focus = hadFocus;
                // searchField.select(oldSelectionStart, oldSelectionEnd);
                searchFieldItem.focus = hadFocus;
                searchFieldItem.select(oldSelectionStart, oldSelectionEnd);
                // ENH236 - End
            } else if (fullyOpen || fullyClosed) {
                resetOldFocus();
            }

            if (fullyClosed) {
                searchField.text = "";
                appList.currentIndex = 0;
                // ENH236 - Custom drawer search
                // searchField.focus = false;
                searchFieldItem.focus = false;
                // ENH236 - End
                appList.focus = false;
            }
        }
    }

    // ENH236 - Custom drawer search
    // function focusInput() {
    function focusInput(_searchType = "all") {
    // ENH236 - End
        // ENH105 - Custom app drawer
        unFocusInput() // For some reason, it won't focus again after closing the OSK in focal so do this
        // ENH105 - End
        // ENH236 - Custom drawer search
        if (root.enableCustomSearch) {
            root.customSearchMode = true
            if (root.customSearchItem) {
                root.customSearchItem.setSearchType(_searchType)
            }
        }
        //searchField.selectAll();
        searchFieldItem.selectAll();
        // ENH105 - Custom app drawer
        // searchField.focus = true;
        //searchField.forceActiveFocus();
        searchFieldItem.forceActiveFocus();
        // ENH105 - ENd
        // ENH236 - End
    }

    function unFocusInput() {
        // ENH236 - Custom drawer search
        // searchField.focus = false;
        searchFieldItem.focus = false;
        // ENH236 - End
    }

    Keys.onPressed: {
        // ENH236 - Custom drawer search
        // if (event.text.trim() !== "") {
        // For some reason, backspace also enters a character and it's not eliminated with trim()
        if (event.text.trim() !== "" && event.key !== Qt.Key_Backspace) {
        // ENH236 - End
            focusInput();
            // ENH236 - Custom drawer search
            // searchField.text = event.text;
            searchFieldItem.text = event.text;
            // ENH236 - End
        }
        switch (event.key) {
            case Qt.Key_Right:
            case Qt.Key_Left:
            case Qt.Key_Down:
                // ENH236 - Custom drawer search
                // appList.focus = true;
                if (root.customSearchField && root.customSearchField.focus && root.customSearchMode) {
                    event.accepted = false;
                    return
                } else {
                    if (root.enableCustomSearch && root.customSearchItem && root.customSearchMode) {
                        root.customSearchItem.focusFirstItem();
                    } else {
                        appList.focus = true;
                    }
                }
                    
                // ENH236 - End
                break;
            case Qt.Key_Up:
                focusInput();
                break;
            // ENH236 - Custom drawer search
            case Qt.Key_Space:
                if (root.enableCustomSearch && root.customSearchItem) {
                    focusInput();
                    root.customSearchItem.searchTypeForward()
                }
                break;
            case Qt.Key_Backspace:
                if (root.enableCustomSearch && root.customSearchItem && root.customSearchItem.enabledBackSpaceToggle) {
                    focusInput();
                    root.customSearchItem.searchTypeBackward()
                }
                break;
            // ENH236 - End
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
        // color: root.lightMode ? "#CAFEFEFE" : "#BF000000"
        readonly property color panelColor: shell.settings.useCustomDrawerColor ? shell.settings.customDrawerColor : root.lightMode ? "#CAFEFEFE" : "#BF000000"
        readonly property real colorOpacity: shell.settings.useCustomDrawerOpacity ? shell.settings.customDrawerOpacity : 1
        color: shell.settings.useCustomDrawerColor || shell.settings.useCustomDrawerOpacity
                    ? Qt.hsla(panelColor.hslHue, panelColor.hslSaturation, panelColor.hslLightness, colorOpacity)
                    : root.lightMode ? "#CAFEFEFE" : "#BF000000"
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
            function onLanguageChanged() { appDrawerModel.refresh() }
        }

        // ENH236 - Custom drawer search
        Loader {
            id: customSearchLoader

            asynchronous: true
            active: root.enableCustomSearch
            anchors {
                left: parent.left
                right: drawerHandle.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: root.panelWidth
                topMargin: (launcherInverted ? root.topPanelHeight : 0) + units.gu(1)
            }

            sourceComponent: LPDrawerSearchPage {
                visible: opacity > 0
                opacity: root.showCustomSearchPage ? 1 : 0
                appModel: appDrawerModel
                appDelegateHeight: root.delegateHeight
                appDelegateWidth: root.delegateWidth
                appDelegateSizeMultiplier: root.delegateSizeMultiplier
                launcherInverted: root.launcherInverted
                appContextMenuItem: appList.contextMenuItem
                showCloseButton: root.alwaysShowCustomSearchField && !searchTextIsEmpty
                defaultAppList: appList

                Behavior on opacity { LomiriNumberAnimation {} }

                onVisibleChanged: {
                    if (visible) {
                        if (!root.alwaysShowCustomSearchField) {
                            focusInput()
                        }
                    } else {
                        reset()
                    }
                }
                onApplicationSelected: appList.applicationSelected(appId)
                onApplicationContextMenu: appList.applicationContextMenu(appId, caller, false, false)
                onTextFieldFocusChanged: {
                    if (root.alwaysShowCustomSearchField && searchTextIsEmpty) {
                        root.customSearchMode = focusValue
                    }
                }
                onSearchTextIsEmptyChanged: {
                    if (root.alwaysShowCustomSearchField) {
                        if (searchTextIsEmpty && !searchField.activeFocus) {
                            root.customSearchMode = false
                        } else {
                            root.customSearchMode = true
                        }
                    }
                }
                onExit: {
                    if (root.alwaysShowCustomSearchField) {
                        root.customSearchItem.reset()
                    } else {
                        root.customSearchMode = false
                    }
                }
            }
        }
        // ENH236 - End
        Item {
            id: contentContainer
            anchors {
                left: parent.left
                right: drawerHandle.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: root.panelWidth
            }
            // ENH236 - Custom drawer search
            opacity: {
                if (!(root.enableCustomSearch && root.customSearchMode)) return 1

                if (root.alwaysShowCustomSearchField && root.customSearchItem
                        && !root.customSearchItem.isWebSearch && root.customSearchItem.searchTextIsEmpty) {
                    return 1
                }

                return 0
            }
            visible: opacity > 0
            Behavior on opacity { LomiriNumberAnimation {} }
            // ENH236 - End

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
                        // ENH236 - Custom drawer search
                        //anchors.topMargin: 0
                        anchors.topMargin: root.enableCustomSearch && root.alwaysShowCustomSearchField && root.customSearchItem ? root.customSearchItem.searchFieldBottomY : 0
                        anchors.bottomMargin: customSearchButtonLayout.visible ? customSearchButtonLayout.height + units.gu(3) : 0
                        viewMargin: root.enableCustomSearch && root.alwaysShowCustomSearchField
                                                                ? units.gu(2) 
                                                                : searchFieldContainer.fullyShown ? units.gu(2) : 0
                        // ENH236 - End
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
                        // ENH236 - Custom drawer search
                        //anchors.topMargin: root.topPanelHeight + units.gu(1)
                        anchors.topMargin: root.topPanelHeight + units.gu(1)
                        anchors.bottomMargin: customSearchButtonLayout.visible ? customSearchButtonLayout.height + units.gu(3)
                                                                               : 0
                        viewMargin: searchFieldContainer.fullyShown ? units.gu(2) : 0
                        // ENH236 - End
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
                // ENH236 - Custom drawer search
                //height: root.searchMode || !shell.settings.hideDrawerSearch ? searchField.height : 0
                height: (root.searchMode || !shell.settings.hideDrawerSearch) && !root.enableCustomSearch ? searchField.height : 0
                // ENH236 - End
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
                // ENH236 - Custom drawer search
                showSearchButton: root.showSearchButton && root.launcherInverted && (enableCustomAppGrids || root.enableDrawerDock)
                onCustomSearch: root.focusInput()
                KeyNavigation.up: root.alwaysShowCustomSearchField ? root.searchFieldItem
                                                                   : root.inverted ? null : searchField
                // ENH236 - End
                // ENH105 - Custom app drawer
                launcherInverted: root.launcherInverted
                viewMargin: searchFieldContainer.fullyShown ? units.gu(2) : 0
                drawerHeight: root.height
                rawModel: appDrawerModel
                mouseHoverOfSelectorIndicatorEnabled: !searchSwipeArea.dragging
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
                enableDock: root.enableDrawerDock
                enableCustomAppGrids: shell.settings.enableCustomAppGrid
                fullAppGridLast: shell.settings.placeFullAppGridToLast
                Connections {
                    target: searchField
                    // ENH236 - Custom drawer search
                    enabled: !root.enableCustomSearch
                    // ENH236 - End
                    // Delay showDock change to reduce UI stutter
                    function onTextChanged() { delayHideDock.restart() }
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
            // ENH236 - Custom drawer search
            Loader {
                id: customSearchButtonLayout

                asynchronous: true
                active: root.showSearchButton && !appList.enableCustomAppGrids && !root.enableDrawerDock && root.launcherInverted
                height: active ? units.gu(6) : 0
                visible: active
                anchors {
                    bottom: parent.bottom
                    bottomMargin: units.gu(3)
                    left: parent.left
                    right: parent.right
                }

                sourceComponent: RowLayout {
                    LPDrawerSearchButton {
                        id: customSearchButton

                        Layout.preferredHeight: units.gu(6)
                        Layout.alignment: Qt.AlignCenter
                        text: i18n.tr("Search")
                        icon.name: "find"
                        display: QQC2.AbstractButton.TextBesideIcon
                        backgroundOpacity: 1
                        onClicked: root.focusInput()
                    }
                }
            }
            // ENH236 - End
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
                            // ENH236 - Custom drawer search
                            //root.focusInput()
                            if (root.enableCustomSearch) {
                                root.customSearchMode = true
                                if (root.alwaysShowCustomSearchField) {
                                    root.customSearchItem.focusInput()
                                }
                            } else {
                                root.focusInput()
                            }
                            // ENH236 - End
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

                contentWidth: units.gu(35)
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

                contentWidth: units.gu(35)
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
                    function onFullyOpenChanged() {
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
                    visible: root.enableDrawerDock
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

                    text: isInDirectActions ? "Remove from Quick Actions" : "Add to Quick Actions"
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
                                color: root.lightMode ? LomiriColors.porcelain : LomiriColors.jet
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

    // ENH059 - Redesigned drawer search field
    Item {
        id: searchHoverHandler

        // ENH236 - Custom drawer search
        //visible: shell.hasMouse && shell.settings.hideDrawerSearch
        visible: shell.hasMouse && shell.settings.hideDrawerSearch && !root.enableCustomSearch
        // ENH236 - End
        height: units.gu(2)
        anchors {
            left: parent.left
            right: parent.right
        }

        states: [
            State {
                name: "bottom"
                when: root.inverted
                
                AnchorChanges {
                    target: searchHoverHandler
                    anchors.top: undefined
                    anchors.bottom: parent.bottom
                }
            }
            , State {
                name: "top"
                when: !root.inverted

                AnchorChanges {
                    target: searchHoverHandler
                    anchors.top: parent.top
                    anchors.bottom: undefined
                }
            }
        ]

        HoverHandler {
            id: hoverHandler
        }

        Timer {
            id: delayHoverTimer
            running: hoverHandler.hovered
            interval: 200
            onTriggered: root.focusInput()
        }
    }
    // ENH059 - End
}
