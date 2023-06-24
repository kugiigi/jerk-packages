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

FocusScope {
    id: root

    property int delegateWidth: units.gu(11)
    property int delegateHeight: units.gu(11)
    property alias delegate: gridView.delegate
    property alias model: gridView.model
    property alias interactive: gridView.interactive
    property alias currentIndex: gridView.currentIndex
    readonly property bool draggingVertically: mainFlickable.interactive ? mainFlickable.draggingVertically : gridView.draggingVertically

    property alias header: gridView.header
    property alias topMargin: gridView.topMargin
    property alias bottomMargin: gridView.bottomMargin
    // ENH007 - Bottom search in drawer
    property alias verticalLayoutDirection: gridView.verticalLayoutDirection
    // ENH007 - End
    // ENH105 - Custom app drawer
    readonly property bool inverted: gridView.verticalLayoutDirection == GridView.BottomToTop
    property var contextMenuItem: null
    property var rawModel
    property bool showDock: false
    readonly property bool isIntegratedDock: shell.settings.drawerDockType == 1
    signal applicationSelected(string appId)
    signal applicationContextMenu(string appId, var caller, bool fromDocked)
    // ENH105 - End

    readonly property int columns: Math.floor(width / delegateWidth)
    readonly property int rows: Math.ceil(gridView.model.count / root.columns)

    property alias refreshing: pullToRefresh.refreshing
    signal refresh();

    // ENH105 - Custom app drawer
    state: "normal"
    states: [
        State {
            name: "bottomdock"
            when: shell.settings.enableDrawerDock && !root.isIntegratedDock
            AnchorChanges {
                target: gridView
                anchors.top: parent.top
                anchors.bottom: parent.bottom
            }
            AnchorChanges {
                target: bottomDockLoader
                anchors.top: undefined
                anchors.bottom: parent.bottom
            }
            PropertyChanges {
                target: gridView

                bottomMargin: bottomDockLoader.item && bottomDockLoader.item.shown ? units.gu(2) : 0
                anchors.bottomMargin: bottomDockLoader.item && bottomDockLoader.item.shown ?
                                                            bottomDockLoader.item.rowHeight + bottomDockLoader.item.verticalPadding
                                                                    + bottomDockLoader.anchors.bottomMargin
                                                : 0
            }
            PropertyChanges {
                target: bottomDockLoader

                anchors.bottomMargin: units.gu(2)
            }
        }
        , State {
            name: "normal"
            when: !root.inverted
            AnchorChanges {
                target: gridView
                anchors.top: bottomDockLoader.bottom
                anchors.bottom: parent.bottom
            }
            AnchorChanges {
                target: bottomDockLoader
                anchors.top: parent.top
                anchors.bottom: undefined
            }
            PropertyChanges {
                target: gridView

                bottomMargin: 0
                anchors.bottomMargin: 0
            }
            PropertyChanges {
                target: bottomDockLoader

                anchors.bottomMargin: 0
            }
        }
        , State {
            name: "inverted"
            when: root.inverted
            AnchorChanges {
                target: gridView
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

                bottomMargin: 0
                anchors.bottomMargin: units.gu(2)
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

    onFocusChanged: {
        if (focus) {
            gridView.forceActiveFocus()
        }
    }

    Flickable {
        id: mainFlickable

        readonly property bool isEnabled: shell.settings.enableDrawerDock && root.isIntegratedDock && root.showDock && !gridView.activeFocus

        clip: true
        focus: true
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        contentHeight: isEnabled ? gridView.contentHeight + gridView.anchors.topMargin + gridView.anchors.bottomMargin
                                                + bottomDockLoader.height + bottomDockLoader.anchors.topMargin + bottomDockLoader.anchors.bottomMargin
                                : height
        contentWidth: parent.width
        interactive: isEnabled && bottomDockLoader.item && !bottomDockLoader.item.editMode
        
        function positionToEnd() {
            contentY = contentHeight - height
        }
        function delayedPositionToEnd() {
            delayScroll.restart()
        }

        // FIXME: Lazy approach for flicking to the end when inverted
        Timer {
            id: delayScroll
            running: false
            interval: 100
            onTriggered: {
                if (root.inverted && mainFlickable.isEnabled) {
                    mainFlickable.positionToEnd()
                }
            }
        }

        GridView {
            id: gridView
            // ENH105 - Custom app drawer
            // anchors.fill: parent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: units.gu(2)

            anchors.leftMargin: bottomDockLoader.item ? bottomDockLoader.item.horizontalPadding + bottomDockLoader.anchors.leftMargin : 0
            anchors.rightMargin: bottomDockLoader.item ? bottomDockLoader.item.horizontalPadding + bottomDockLoader.anchors.rightMargin  : 0
            topMargin: anchors.topMargin
            // ENH105 - End
            focus: true

            readonly property int overflow: width - (root.columns * root.delegateWidth)
            readonly property real spacing: Math.floor(overflow / root.columns)

            cellWidth: root.delegateWidth + spacing
            cellHeight: root.delegateHeight
            // ENH105 - Custom app drawer
            interactive: !mainFlickable.isEnabled
            height: interactive ? implicitHeight : contentHeight
            clip: true
            onMovingChanged: {
                if (moving && bottomDockLoader.item) {
                    bottomDockLoader.item.expanded = false
                }
            }

            /*
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
            */
            PullToRefresh {
                id: pullToRefresh
                parent: mainFlickable.isEnabled ? mainFlickable : gridView
                target: mainFlickable.isEnabled ? mainFlickable : gridView

                readonly property real contentY: mainFlickable.isEnabled ? mainFlickable.contentY - mainFlickable.originY
                                                            : gridView.contentY - gridView.originY
                y: -contentY - units.gu(5)

                readonly property color pullLabelColor: "white"
                style: PullToRefreshScopeStyle {
                    activationThreshold: mainFlickable.isEnabled ? Math.min(units.gu(14), mainFlickable.height / 5)
                                                    : Math.min(units.gu(14), gridView.height / 5)
                }

                onRefresh: root.refresh();
            }
            // ENH105 - End
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
                leftMargin: root.isIntegratedDock ? 0 : units.gu(1)
                rightMargin: root.isIntegratedDock ? 0 : units.gu(1)
            }
            onLoaded: if (mainFlickable.isEnabled) mainFlickable.delayedPositionToEnd()
            sourceComponent: LPDrawerDock {
                shown: root.showDock && !gridView.activeFocus
                isIntegratedDock: root.isIntegratedDock
                inverted: root.inverted
                delegateHeight: root.delegateHeight
                delegateWidth: root.delegateWidth
                rawModel: root.rawModel
                contextMenuItem: root.contextMenuItem

                onShownChanged: if (root.inverted) mainFlickable.delayedPositionToEnd()

                onApplicationSelected: root.applicationSelected(appId)
                onApplicationContextMenu: root.applicationContextMenu(appId, caller, fromDocked)
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
