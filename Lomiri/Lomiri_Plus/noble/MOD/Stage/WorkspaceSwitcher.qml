/*
 * Copyright (C) 2014-2016 Canonical Ltd.
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
import "Spread"
import WindowManager 1.0
import QtMir.Application 0.1

Item {
    id: root

    opacity: d.shown ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { LomiriNumberAnimation {} }

    property var screensProxy: Screens.createProxy();
    property string background
    property Item availableDesktopArea
    // ENH185 - Workspace spread UI fixes
    property bool sideStageEnabled: false
    // ENH185 - End

    readonly property alias active: d.active
    // ENH257 - Workspace redesign
    readonly property alias currentSurface: d.currentAppSurface
    // For debugging why sometimes it won't hide
    onFocusChanged: console.log("Switcher Focus - active: " + focus + " - " + d.active)
    // ENH257 - End
    // ENH259 - Option to disable workspace switcher UI
    property bool hideScreenUI: false
    // ENH259 - End
    // ENH154 - Workspace switcher gesture
    property bool biggerUI: false
    // ENH184 - Delay workspace switcher UI
    //function switchLeft() {
    function switchLeft(_delayed=false) {
        d.delayedShow = _delayed
    // ENH184 - End
        if (visible) {
            d.previousWorkspace();
        } else {
            showLeft();
        }
    }
    // ENH184 - Delay workspace switcher UI
    //function switchRight() {
    function switchRight(_delayed=false) {
        d.delayedShow = _delayed
    // ENH184 - End
        if (visible) {
            d.nextWorkspace();
        } else {
            showRight();
        }
    }

    function switchLeftMoveApp(_delayed=false, appDelegate) {
        d.delayedShow = _delayed
        d.currentAppSurface = appDelegate.surface
        // ENH257 - Workspace redesign
        appDelegate.saveWindowState();
        // ENH257 - End
        if (visible) {
            d.previousWorkspace();
        } else {
            showLeft();
        }
    }

    function switchRightMoveApp(_delayed=false, appDelegate) {
        d.delayedShow = _delayed
        d.currentAppSurface = appDelegate.surface
        // ENH257 - Workspace redesign
        appDelegate.saveWindowState();
        // ENH257 - End
        if (visible) {
            d.nextWorkspace();
        } else {
            showRight();
        }
    }
    // ENH244 - Workspace switch spread fix #150
    signal workspaceSelected(var selectedWorkspace)
    // ENH244 - End
    function actuallySelect() {
        d.active = false;
        d.altPressed = false;
        d.ctrlPressed = false;
        // ENH181 - Shortcut for moving app to another workspace
        if (d.currentAppSurface) {
            d.shiftPressed = false;
        }
        // ENH181 - End
        if (d.currentAppSurface) {
            let _workspace = screensProxy.get(d.highlightedScreenIndex).workspaces.get(d.highlightedWorkspaceIndex)
            WorkspaceManager.moveSurfaceToWorkspace(d.currentAppSurface, _workspace);
            d.currentAppSurface = null
        }
        hideTimer.start();
        focus = false;
        const _workspace = screensProxy.get(d.highlightedScreenIndex).workspaces.get(d.highlightedWorkspaceIndex)
        _workspace.activate();
        workspaceSelected(_workspace)
    }

    // ENH154 - End
    // ENH154 - Workspace switcher gesture
    // function showLeft() {
        // show();
    function showLeft(_commit = false, _tease = false) {
        d.switchImmediately = _commit;
        show(_tease);
    // ENH154 - End
        d.previousWorkspace();
    }
    // ENH154 - Workspace switcher gesture
    // function showRight() {
        // show();
    function showRight(_commit = false, _tease = false) {
        d.switchImmediately = _commit;
        show(_tease);
    // ENH154 - End
        d.nextWorkspace();
    }
    function showUp() {
        show();
        d.previousScreen();
    }
    function showDown() {
        show();
        d.nextScreen();
    }

    // ENH154 - Workspace switcher gesture
    /*
    function showLeftMoveApp(appSurface) {
        d.currentAppSurface = appSurface
        show();
        d.previousWorkspace();
    }
    function showRightMoveApp(appSurface) {
        d.currentAppSurface = appSurface
        show();
        d.nextWorkspace();
    }
    function showUpMoveApp(appSurface) {
        d.currentAppSurface = appSurface
        show();
        d.previousScreen();
    }
    function showDownMoveApp(appSurface) {
        d.currentAppSurface = appSurface
        show();
        d.nextScreen();
    }
    */
    function showLeftMoveApp(appDelegate, _switchImmediately = false, _tease = false) {
        d.switchImmediately = _switchImmediately;
        d.currentAppSurface = appDelegate.surface;
        // ENH257 - Workspace redesign
        appDelegate.saveWindowState();
        // ENH257 - End
        show(_tease);
        d.previousWorkspace();
    }

    function showRightMoveApp(appDelegate, _switchImmediately = false, _tease = false) {
        d.switchImmediately = _switchImmediately;
        d.currentAppSurface = appDelegate.surface;
        // ENH257 - Workspace redesign
        appDelegate.saveWindowState();
        // ENH257 - End
        show(_tease);
        d.nextWorkspace();
    }
    function showUpMoveApp(appDelegate) {
        d.currentAppSurface = appDelegate.surface;
        // ENH257 - Workspace redesign
        appDelegate.saveWindowState();
        // ENH257 - End
        show();
        d.previousScreen();
    }
    function showDownMoveApp(appDelegate) {
        d.currentAppSurface = appDelegate.surface;
        // ENH257 - Workspace redesign
        appDelegate.saveWindowState();
        // ENH257 - End
        show();
        d.nextScreen();
    }
    // ENH154 - End

    // ENH154 - Workspace switcher gesture
    // function show() {
    function show(_tease = false) {
    // ENH154 - End
        hideTimer.stop();
        d.altPressed = true;
        d.ctrlPressed = true;
        if (d.currentAppSurface) {
            d.shiftPressed = true;
        }
        d.active = true;
        // ENH184 - Delay workspace switcher UI
        // d.shown = true;
        if (d.delayedShow) {
            delayedShowTimer.restart()
        } else {
            d.shown = true;
        }
        // ENH184 - End
        focus = true;

        d.highlightedScreenIndex = screensProxy.activeScreen;
        var activeScreen = screensProxy.get(screensProxy.activeScreen);
        d.highlightedWorkspaceIndex = activeScreen.workspaces.indexOf(activeScreen.currentWorkspace)
        // ENH154 - Workspace switcher gesture
        if (_tease) {
            hideTimer.restart();
        }
        // ENH154 - End
    }

    QtObject {
        id: d

        property bool active: false
        property bool shown: false
        property bool altPressed: false
        property bool ctrlPressed: false
        property bool shiftPressed: false
        property var currentAppSurface: null
        // ENH184 - Delay workspace switcher UI
        property bool delayedShow: shell.settings.delayedWorkspaceSwitcherUI
        // ENH184 - End
        // ENH259 - Option to disable workspace switcher UI
        property bool switchImmediately: false

        function commitSwitchToWorkspace() {
            const selectedWorkspace = screensProxy.get(d.highlightedScreenIndex).workspaces.get(d.highlightedWorkspaceIndex);
            // No need since workspaceSelected also activate it
            //selectedWorkspace.activate();
            workspaceSelected(selectedWorkspace)
        }
        // ENH259 - End

        property int rowHeight: root.height - units.gu(4)

        property int highlightedScreenIndex: -1
        property int highlightedWorkspaceIndex: -1

        function previousWorkspace() {
            highlightedWorkspaceIndex = Math.max(highlightedWorkspaceIndex - 1, 0);
            // ENH259 - Option to disable workspace switcher UI
            if (switchImmediately) {
                commitSwitchToWorkspace()
            }
            // ENH259 - End
        }
        function nextWorkspace() {
            var screen = screensProxy.get(highlightedScreenIndex);
            highlightedWorkspaceIndex = Math.min(highlightedWorkspaceIndex + 1, screen.workspaces.count - 1);
            // ENH259 - Option to disable workspace switcher UI
            if (switchImmediately) {
                commitSwitchToWorkspace()
            }
            // ENH259 - End
        }
        function previousScreen() {
            highlightedScreenIndex = Math.max(highlightedScreenIndex - 1, 0);
            var screen = screensProxy.get(highlightedScreenIndex);
            highlightedWorkspaceIndex = Math.min(highlightedWorkspaceIndex, screen.workspaces.count - 1)
        }
        function nextScreen() {
            highlightedScreenIndex = Math.min(highlightedScreenIndex + 1, screensProxy.count - 1);
            var screen = screensProxy.get(highlightedScreenIndex);
            highlightedWorkspaceIndex = Math.min(highlightedWorkspaceIndex, screen.workspaces.count - 1)
        }
    }

    // ENH184 - Delay workspace switcher UI
    Timer {
        id: delayedShowTimer
        interval: 800
        onTriggered: d.shown = true;
    }
    // ENH184 - End
    Timer {
        id: hideTimer
        interval: 300
        // ENH184 - Delay workspace switcher UI
        // onTriggered: d.shown = false;
        onTriggered: {
            d.shown = false;
            d.delayedShow = shell.settings.delayedWorkspaceSwitcherUI
            delayedShowTimer.stop()
        }
        // ENH184 - End
        // ENH259 - Option to disable workspace switcher UI
        onRunningChanged: {
            if (running) {
                d.active = false;
                focus = false;
            }
        }
        // ENH259 - End
    }

    Keys.onPressed: {
        switch (event.key) {
        case Qt.Key_Left:
            d.previousWorkspace();
            break;
        case Qt.Key_Right:
            d.nextWorkspace()
            break;
        case Qt.Key_Up:
            d.previousScreen();
            break;
        case Qt.Key_Down:
            d.nextScreen();
        }
        // ENH184 - Delay workspace switcher UI
        if (shell.settings.delayedWorkspaceSwitcherUI) {
            switch (event.key) {
            case Qt.Key_Left:
            case Qt.Key_Right:
            case Qt.Key_Up:
            case Qt.Key_Down:
                delayedShowTimer.stop()
                d.shown = true
            }
        }
        // ENH184 - End
    }
    Keys.onReleased: {
        switch (event.key) {
        case Qt.Key_Alt:
            d.altPressed = false;
            break;
        case Qt.Key_Control:
            d.ctrlPressed = false;
            break;
        case Qt.Key_Shift:
            d.shiftPressed = false;
            break;
        }

        if (!d.altPressed && !d.ctrlPressed && !d.shiftPressed) {
            if (d.currentAppSurface) {
                let _workspace = screensProxy.get(d.highlightedScreenIndex).workspaces.get(d.highlightedWorkspaceIndex)
                WorkspaceManager.moveSurfaceToWorkspace(d.currentAppSurface, _workspace);
                d.currentAppSurface = null
            }
            // ENH259 - Option to disable workspace switcher UI
            // Do these when hideTimer starts and also moved to the end
            // d.active = false;
            // hideTimer.start();
            hideTimer.restart();
            // focus = false;
            // ENH259 - End
            // ENH244 - Workspace switch spread fix #150
            // screensProxy.get(d.highlightedScreenIndex).workspaces.get(d.highlightedWorkspaceIndex).activate();
            // ENH259 - Option to disable workspace switcher UI
            //const selectedWorkspace = screensProxy.get(d.highlightedScreenIndex).workspaces.get(d.highlightedWorkspaceIndex);
            //selectedWorkspace.activate();
            //workspaceSelected(selectedWorkspace)
            if (!d.switchImmediately) {
                d.commitSwitchToWorkspace()
            }
            d.switchImmediately = false;
            // ENH244 - End
        }
    }

    LomiriShape {
        // ENH154 - Workspace switcher gesture
        // backgroundColor: "#F2111111"
        backgroundColor: LomiriColors.inkstone
        // ENH154 - End
        clip: true
        width: Math.min(parent.width, screensColumn.width + units.gu(4))
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.height

        Column {
            id: screensColumn
            anchors {
                top: parent.top; topMargin: units.gu(2) - d.highlightedScreenIndex * (d.rowHeight + screensColumn.spacing)
                left: parent.left; leftMargin: units.gu(2)
            }
            width: screensRepeater.itemAt(d.highlightedScreenIndex).width
            spacing: units.gu(2)
            Behavior on anchors.topMargin { LomiriNumberAnimation {} }
            Behavior on width { LomiriNumberAnimation {} }

            Repeater {
                id: screensRepeater
                model: screensProxy

                delegate: Item {
                    height: d.rowHeight
                    width: workspaces.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: d.highlightedScreenIndex == index ? 1 : 0
                    Behavior on opacity { LomiriNumberAnimation {} }

                    LomiriShape {
                        id: header
                        anchors { left: parent.left; top: parent.top; right: parent.right }
                        // ENH154 - Workspace switcher gesture
                        // height: units.gu(4)
                        // backgroundColor: "white"
                        // ENH259 - Option to disable workspace switcher UI
                        //height: root.biggerUI ? units.gu(6) : units.gu(4)
                        height: root.hideScreenUI ? 0 : root.biggerUI ? units.gu(6) : units.gu(4)
                        visible: !root.hideScreenUI
                        // ENH259 - End
                        backgroundColor: LomiriColors.silk
                        // ENH154 - End

                        Label {
                            anchors { left: parent.left; top: parent.top; right: parent.right; margins: units.gu(1) }
                            text: model.screen.name
                            // ENH154 - Workspace switcher gesture
                            // color: LomiriColors.ash
                            color: LomiriColors.inkstone
                            textSize: root.biggerUI ? Label.Large : Label.Medium
                            // ENH154 - End
                        }
                    }

                    Workspaces {
                        id: workspaces
                        // ENH154 - Workspace switcher gesture
                        // height: parent.height - header.height - units.gu(2)
                        // ENH259 - Option to disable workspace switcher UI
                        //height: root.biggerUI ? parent.height - header.height - units.gu(4) : parent.height - header.height - units.gu(2)
                        height: root.hideScreenUI ? parent.height - header.height - units.gu(2)
                                    : root.biggerUI ? parent.height - header.height - units.gu(4) : parent.height - header.height - units.gu(2)
                        // ENH259 - End
                        // ENH154 - End
                        width: Math.min(implicitWidth, root.width - units.gu(4))

                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(1)
                        anchors.horizontalCenter: parent.horizontalCenter
                        screen: model.screen
                        background: root.background
                        selectedIndex: d.highlightedScreenIndex == index ? d.highlightedWorkspaceIndex : -1

                        workspaceModel: model.screen.workspaces
                        // ENH154 - Workspace switcher gesture
                        activeWorkspace: WMScreen.currentWorkspace
                        // ENH154 - End
                        // ENH185 - Workspace spread UI fixes
                        sideStageEnabled: root.sideStageEnabled
                        // ENH185 - End
                        availableDesktopArea: root.availableDesktopArea
                    }
                }
            }
        }
    }
}
