/*
 * Copyright (C) 2014-2017 Canonical Ltd.
 * Copyright (C) 2021 UBports Foundation
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
import QtQuick.Window 2.2
import Lomiri.Components 1.3
import QtMir.Application 0.1
import "../Components/PanelState"
import "../Components"
import Utils 0.1
import Lomiri.Gestures 0.1
import GlobalShortcut 1.0
import GSettings 1.0
import "Spread"
import "Spread/MathUtils.js" as MathUtils
import ProcessControl 0.1
import WindowManager 1.0
// ENH032 - Infographics Outer Wilds
import "../OuterWilds"
// ENH032 - End

FocusScope {
    id: root
    anchors.fill: parent

    property QtObject applicationManager
    property QtObject topLevelSurfaceList
    property bool altTabPressed
    property url background
    property alias backgroundSourceSize: wallpaper.sourceSize
    property int dragAreaWidth
    property real nativeHeight
    property real nativeWidth
    property QtObject orientations
    property int shellOrientation
    property int shellOrientationAngle
    property bool spreadEnabled: true // If false, animations and right edge will be disabled
    property bool suspended
    property bool oskEnabled: false
    property rect inputMethodRect
    property real rightEdgePushProgress: 0
    property Item availableDesktopArea
    property PanelState panelState
    // ENH032 - Infographics Outer Wilds
    property bool enableOW: false
    property bool alternateOW: false
    property bool dlcOW: false
    property bool eyeOpened: false
    property bool blinkComplete: false
    // ENH032 - End
    // ENH102 - App suspension indicator
    readonly property string focusedAppName: priv.focusedAppDelegate ? priv.focusedAppDelegate.appName : ""
    readonly property url focusedAppIcon: priv.focusedAppDelegate ? priv.focusedAppDelegate.application.icon : ""
    readonly property string focusedAppId: priv.focusedAppDelegate ? priv.focusedAppDelegate.appId : ""
    // ENH102 - End

    // Whether outside forces say that the Stage may have focus
    property bool allowInteractivity

    readonly property bool interactive: (state === "staged" || state === "stagedWithSideStage" || state === "windowed") && allowInteractivity

    // Configuration
    property string mode: "staged"

    readonly property var temporarySelectedWorkspace: state == "spread" ? screensAndWorkspaces.activeWorkspace : null
    property bool workspaceEnabled: (mode == "windowed" && settings.enableWorkspace) || settings.forceEnableWorkspace

    // Used by the tutorial code
    readonly property real rightEdgeDragProgress: rightEdgeDragArea.dragging ? rightEdgeDragArea.progress : 0 // How far left the stage has been dragged

    // used by the snap windows (edge maximize) feature
    readonly property alias previewRectangle: fakeRectangle

    readonly property bool spreadShown: state == "spread"
    readonly property var mainApp: priv.focusedAppDelegate ? priv.focusedAppDelegate.application : null

    // application windows never rotate independently
    property int mainAppWindowOrientationAngle: shellOrientationAngle

    property bool orientationChangesEnabled: !priv.focusedAppDelegate || priv.focusedAppDelegate.orientationChangesEnabled

    property int supportedOrientations: {
        if (mainApp) {
            switch (mode) {
            case "staged":
                return mainApp.supportedOrientations;
            case "stagedWithSideStage":
                var orientations = mainApp.supportedOrientations;
                orientations |= Qt.LandscapeOrientation | Qt.InvertedLandscapeOrientation;
                if (priv.sideStageItemId) {
                    // If we have a sidestage app, support Portrait orientation
                    // so that it will switch the sidestage app to mainstage on rotate to portrait
                    orientations |= Qt.PortraitOrientation|Qt.InvertedPortraitOrientation;
                }
                return orientations;
            }
        }

        return Qt.PortraitOrientation |
                Qt.LandscapeOrientation |
                Qt.InvertedPortraitOrientation |
                Qt.InvertedLandscapeOrientation;
    }

    GSettings {
        id: settings
        schema.id: "com.lomiri.Shell"
    }

    property int launcherLeftMargin : 0
    // ENH041 - Hide side-stage when main app go fullscreen
    Connections {
        property bool sideStageTempHidden: false
        target: priv.focusedAppDelegate
        onFullscreenChanged: {
            if (target.stage == ApplicationInfoInterface.MainStage) {
                if (target.fullscreen && sideStage.shown) {
                    sideStage.hide()
                    sideStageTempHidden = true
                } else {
                    if (sideStageTempHidden && !sideStage.shown
                            && priv.sideStageEnabled) {
                        sideStage.show()
                        priv.updateMainAndSideStageIndexes()
                    }
                    sideStageTempHidden = false
                }
            }
        }
    }
    // ENH041 - End

    // ENH135 - Show Desktop
    function disableShowDesktop() {
        appContainer.showDesktop = false
    }
    // ENH135 - End
    // ENH139 - System Direct Actions
    function screenShotApp() {
        if (priv.focusedAppDelegate) {
            itemSnapshotRequested(priv.focusedAppDelegate)
        }
    }
    function closeCurrentApp() {
        if (priv.focusedAppDelegate) {
            priv.focusedAppDelegate.close();
        }
    }
    // ENH139 - End
    // ENH133 - Hot corners
    function switchToPreviousApp() {
        if (appRepeater.count > 1) {
            appRepeater.itemAt(1).activate();
        } else if (appRepeater.count > 0) {
            appRepeater.itemAt(0).activate(); // quick alt-tab to the only (minimized) window should still activate it
        }
    }
    // ENH133 - End

    Binding {
        target: topLevelSurfaceList
        property: "rootFocus"
        value: interactive
    }

    onInteractiveChanged: {
        // Stage must have focus before activating windows, including null
        if (interactive) {
            focus = true;
        }
    }

    onAltTabPressedChanged: {
        root.focus = true;
        if (altTabPressed) {
            if (root.spreadEnabled) {
                altTabDelayTimer.start();
            }
        } else {
            // Alt Tab has been released, did we already go to spread?
            if (priv.goneToSpread) {
                priv.goneToSpread = false;
            } else {
                // No we didn't, do a quick alt-tab
                if (appRepeater.count > 1) {
                    appRepeater.itemAt(1).activate();
                } else if (appRepeater.count > 0) {
                    appRepeater.itemAt(0).activate(); // quick alt-tab to the only (minimized) window should still activate it
                }
            }
        }
    }

    Timer {
        id: altTabDelayTimer
        interval: 140
        repeat: false
        onTriggered: {
            if (root.altTabPressed) {
                priv.goneToSpread = true;
            }
        }
    }

    // For MirAL window management
    WindowMargins {
        normal: Qt.rect(0, root.mode === "windowed" ? priv.windowDecorationHeight : 0, 0, 0)
        dialog: normal
    }

    property Item itemConfiningMouseCursor: !spreadShown && priv.focusedAppDelegate && priv.focusedAppDelegate.window && priv.focusedAppDelegate.window.confinesMousePointer ?
                              priv.focusedAppDelegate.clientAreaItem : null;

    signal itemSnapshotRequested(Item item)

    // functions to be called from outside
    function updateFocusedAppOrientation() { /* TODO */ }
    function updateFocusedAppOrientationAnimated() { /* TODO */}

    function closeSpread() {
        spreadItem.highlightedIndex = -1;
        priv.goneToSpread = false;
    }

    onSpreadEnabledChanged: {
        if (!spreadEnabled && spreadShown) {
            closeSpread();
        }
    }

    onRightEdgePushProgressChanged: {
        if (spreadEnabled && rightEdgePushProgress >= 1) {
            priv.goneToSpread = true
        }
    }

    // ENH133 - Hot corners
    function toggleSpread() {
        if (root.spreadEnabled) {
            if (!spreadShown) {
                priv.goneToSpread = true
            } else {
                closeSpread()
            }
        }
    }

    function showDesktop() {
        // Use custom show desktop for now
        appContainer.toggleShowDesktop()
        //priv.minimizeAllWindows()
    }
    // ENH133 - End

    GSettings {
        id: lifecycleExceptions
        schema.id: "com.canonical.qtmir"
    }

    function isExemptFromLifecycle(appId) {
        var shortAppId = appId.split('_')[0];
        for (var i = 0; i < lifecycleExceptions.lifecycleExemptAppids.length; i++) {
            if (shortAppId === lifecycleExceptions.lifecycleExemptAppids[i]) {
                return true;
            }
        }
        return false;
    }
    // ENH102 - App suspension indicator
    function exemptFromLifecycle(_appId) {
        let _shortAppId = _appId.split('_')[0];
        if (! lifecycleExceptions.lifecycleExemptAppids.includes(_shortAppId)) {
            let _tempArr = lifecycleExceptions.lifecycleExemptAppids.slice()
            _tempArr.push(_shortAppId)
            lifecycleExceptions.lifecycleExemptAppids = _tempArr.slice()
        }
    }

    function removeExemptFromLifecycle(_appId) {
        let _shortAppId = _appId.split('_')[0];
        if (lifecycleExceptions.lifecycleExemptAppids.includes(_shortAppId)) {
            let _tempArr = lifecycleExceptions.lifecycleExemptAppids.slice()
            _tempArr.splice(_tempArr.indexOf(_shortAppId), 1)
            lifecycleExceptions.lifecycleExemptAppids = _tempArr.slice()
        }
    }
    // ENH102 - End

    GlobalShortcut {
        id: closeFocusedShortcut
        shortcut: Qt.AltModifier|Qt.Key_F4
        onTriggered: {
            if (priv.focusedAppDelegate) {
                priv.focusedAppDelegate.close();
            }
        }
    }

    GlobalShortcut {
        id: showSpreadShortcut
        shortcut: Qt.MetaModifier|Qt.Key_W
        active: root.spreadEnabled
        onTriggered: priv.goneToSpread = true
    }

    // ENH015 - Add shortcuts for side stage
    GlobalShortcut {
        id: toggleSideStageShortcut
        shortcut: Qt.MetaModifier|Qt.Key_S
        active: priv.sideStageEnabled
        onTriggered: {
           priv.toggleSideStage()
        }
    }
    // ENH015 - End

    GlobalShortcut {
        id: minimizeAllShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_D
        onTriggered: priv.minimizeAllWindows()
        // ENH135 - Show Desktop
        // active: root.state == "windowed"
        active: false // Disable for now since minimize all is broken
        // ENH135 - End
    }
    // ENH135 - Show Desktop
    GlobalShortcut {
        id: showDesktopShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_D
        onTriggered: appContainer.toggleShowDesktop()
        active: true
    }
    // ENH135 - End

    GlobalShortcut {
        id: maximizeWindowShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Up
        onTriggered: priv.focusedAppDelegate.requestMaximize()
        active: root.state == "windowed" && priv.focusedAppDelegate && priv.focusedAppDelegate.canBeMaximized
    }

    GlobalShortcut {
        id: maximizeWindowLeftShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Left
        // ENH015 - Add shortcuts for side stage
        // onTriggered: priv.focusedAppDelegate.requestMaximizeLeft()
        // active: root.state == "windowed" && priv.focusedAppDelegate && priv.focusedAppDelegate.canBeMaximizedLeftRight
        onTriggered: {
            switch (root.mode) {
                case "stagedWithSideStage":
                    if (priv.focusedAppDelegate.stage == ApplicationInfoInterface.SideStage) {
                        priv.focusedAppDelegate.saveStage(ApplicationInfoInterface.MainStage);
                        priv.focusedAppDelegate.focus = true;
                    }
                    break;
                case "windowed":
                    priv.focusedAppDelegate.requestMaximizeLeft()
                    break;
            }
        }
        active: (root.state == "windowed" && priv.focusedAppDelegate && priv.focusedAppDelegate.canBeMaximizedLeftRight)
                    ||  (root.state == "stagedWithSideStage" && priv.focusedAppDelegate 
                                            && priv.focusedAppDelegate.stage == ApplicationInfoInterface.SideStage && priv.sideStageEnabled)
		// ENH015 - End
    }

    GlobalShortcut {
        id: maximizeWindowRightShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Right
        // ENH015 - Add shortcuts for side stage
        // onTriggered: priv.focusedAppDelegate.requestMaximizeRight()
        // active: root.state == "windowed" && priv.focusedAppDelegate && priv.focusedAppDelegate.canBeMaximizedLeftRight
        onTriggered: {
            switch (root.mode) {
                case "stagedWithSideStage":
                    if (priv.focusedAppDelegate.stage == ApplicationInfoInterface.MainStage) {
                        priv.focusedAppDelegate.saveStage(ApplicationInfoInterface.SideStage);
                        priv.focusedAppDelegate.focus = true;
                        sideStage.show();
                        priv.updateMainAndSideStageIndexes()
                    }
                    break;
                case "windowed":
                    priv.focusedAppDelegate.requestMaximizeRight()
                    break;
            }
        }
        active: (root.state == "windowed" && priv.focusedAppDelegate && priv.focusedAppDelegate.canBeMaximizedLeftRight)
                    ||  (root.state == "stagedWithSideStage" && priv.focusedAppDelegate
                                    && priv.focusedAppDelegate.stage == ApplicationInfoInterface.MainStage && priv.sideStageEnabled)
        // ENH015 - End
    }

    GlobalShortcut {
        id: minimizeRestoreShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Down
        onTriggered: {
            if (priv.focusedAppDelegate.anyMaximized) {
                priv.focusedAppDelegate.requestRestore();
            } else {
                priv.focusedAppDelegate.requestMinimize();
            }
        }
        active: root.state == "windowed" && priv.focusedAppDelegate
    }

    GlobalShortcut {
        shortcut: Qt.AltModifier|Qt.Key_Print
        onTriggered: root.itemSnapshotRequested(priv.focusedAppDelegate)
        active: priv.focusedAppDelegate !== null
    }

    GlobalShortcut {
        shortcut: Qt.ControlModifier|Qt.AltModifier|Qt.Key_T
        onTriggered: {
            // try in this order: snap pkg, new deb name, old deb name
            var candidates = ["lomiri-terminal-app_lomiri-terminal-app", "lomiri-terminal-app", "com.lomiri.terminal_terminal"];
            for (var i = 0; i < candidates.length; i++) {
                if (priv.startApp(candidates[i]))
                    break;
            }
        }
    }

    GlobalShortcut {
        id: showWorkspaceSwitcherShortcutLeft
        shortcut: Qt.AltModifier|Qt.ControlModifier|Qt.Key_Left
        active: !workspaceSwitcher.active
        onTriggered: {
            root.focus = true;
            workspaceSwitcher.showLeft()
        }
    }
    GlobalShortcut {
        id: showWorkspaceSwitcherShortcutRight
        shortcut: Qt.AltModifier|Qt.ControlModifier|Qt.Key_Right
        active: !workspaceSwitcher.active
        onTriggered: {
            root.focus = true;
            workspaceSwitcher.showRight()
        }
    }
    GlobalShortcut {
        id: showWorkspaceSwitcherShortcutUp
        shortcut: Qt.AltModifier|Qt.ControlModifier|Qt.Key_Up
        active: !workspaceSwitcher.active
        onTriggered: {
            root.focus = true;
            workspaceSwitcher.showUp()
        }
    }
    GlobalShortcut {
        id: showWorkspaceSwitcherShortcutDown
        shortcut: Qt.AltModifier|Qt.ControlModifier|Qt.Key_Down
        active: !workspaceSwitcher.active
        onTriggered: {
            root.focus = true;
            workspaceSwitcher.showDown()
        }
    }

    QtObject {
        id: priv
        objectName: "DesktopStagePrivate"

        function startApp(appId) {
            if (root.applicationManager.findApplication(appId)) {
                return root.applicationManager.requestFocusApplication(appId);
            } else {
                return root.applicationManager.startApplication(appId) !== null;
            }
        }

        property var focusedAppDelegate: null
        property var foregroundMaximizedAppDelegate: null // for stuff like drop shadow and focusing maximized app by clicking panel

        property bool goneToSpread: false
        property int closingIndex: -1
        property int animationDuration: LomiriAnimation.FastDuration

        function updateForegroundMaximizedApp() {
            var found = false;
            for (var i = 0; i < appRepeater.count && !found; i++) {
                var item = appRepeater.itemAt(i);
                if (item && item.visuallyMaximized) {
                    foregroundMaximizedAppDelegate = item;
                    found = true;
                }
            }
            if (!found) {
                foregroundMaximizedAppDelegate = null;
            }
        }

        function minimizeAllWindows() {
            for (var i = appRepeater.count - 1; i >= 0; i--) {
                var appDelegate = appRepeater.itemAt(i);
                if (appDelegate && !appDelegate.minimized) {
                    appDelegate.requestMinimize();
                }
            }
        }

        readonly property bool sideStageEnabled: root.mode === "stagedWithSideStage" &&
                                                 (root.shellOrientation == Qt.LandscapeOrientation ||
                                                 root.shellOrientation == Qt.InvertedLandscapeOrientation)
        onSideStageEnabledChanged: {
            for (var i = 0; i < appRepeater.count; i++) {
                appRepeater.itemAt(i).refreshStage();
            }
            priv.updateMainAndSideStageIndexes();
        }

        // ENH135 - Show Desktop
        onGoneToSpreadChanged: {
            if (goneToSpread) {
                root.disableShowDesktop()
            }
        }
        // ENH135 - End

        property var mainStageDelegate: null
        property var sideStageDelegate: null
        property int mainStageItemId: 0
        property int sideStageItemId: 0
        property string mainStageAppId: ""
        property string sideStageAppId: ""

        onSideStageDelegateChanged: {
            if (!sideStageDelegate) {
                sideStage.hide();
            }
        }
        // ENH015 - Add shortcuts for side stage
        function toggleSideStage() {
            if (sideStage.shown) {
                sideStage.hide();
            } else  {
                sideStage.show();
                updateMainAndSideStageIndexes()
            }
        }
        // ENH015 - End

        function updateMainAndSideStageIndexes() {
            if (root.mode != "stagedWithSideStage") {
                priv.sideStageDelegate = null;
                priv.sideStageItemId = 0;
                priv.sideStageAppId = "";
                priv.mainStageDelegate = appRepeater.itemAt(0);
                priv.mainStageItemId = topLevelSurfaceList.idAt(0);
                priv.mainStageAppId = topLevelSurfaceList.applicationAt(0) ? topLevelSurfaceList.applicationAt(0).appId : ""
                return;
            }

            var choseMainStage = false;
            var choseSideStage = false;

            if (!root.topLevelSurfaceList)
                return;

            for (var i = 0; i < appRepeater.count && (!choseMainStage || !choseSideStage); ++i) {
                var appDelegate = appRepeater.itemAt(i);
                if (!appDelegate) {
                    // This might happen during startup phase... If the delegate appears and claims focus
                    // things are updated and appRepeater.itemAt(x) still returns null while appRepeater.count >= x
                    // Lets just skip it, on startup it will be generated at a later point too...
                    continue;
                }
                if (sideStage.shown && appDelegate.stage == ApplicationInfoInterface.SideStage
                        && !choseSideStage) {
                    priv.sideStageDelegate = appDelegate
                    priv.sideStageItemId = root.topLevelSurfaceList.idAt(i);
                    priv.sideStageAppId = root.topLevelSurfaceList.applicationAt(i).appId;
                    choseSideStage = true;
                } else if (!choseMainStage && appDelegate.stage == ApplicationInfoInterface.MainStage) {
                    priv.mainStageDelegate = appDelegate;
                    priv.mainStageItemId = root.topLevelSurfaceList.idAt(i);
                    priv.mainStageAppId = root.topLevelSurfaceList.applicationAt(i).appId;
                    choseMainStage = true;
                }
            }
            if (!choseMainStage && priv.mainStageDelegate) {
                priv.mainStageDelegate = null;
                priv.mainStageItemId = 0;
                priv.mainStageAppId = "";
            }
            if (!choseSideStage && priv.sideStageDelegate) {
                priv.sideStageDelegate = null;
                priv.sideStageItemId = 0;
                priv.sideStageAppId = "";
            }
        }

        property int nextInStack: {
            var mainStageIndex = priv.mainStageDelegate ? priv.mainStageDelegate.itemIndex : -1;
            var sideStageIndex = priv.sideStageDelegate ? priv.sideStageDelegate.itemIndex : -1;
            if (sideStageIndex == -1) {
                return topLevelSurfaceList.count > 1 ? 1 : -1;
            }
            if (mainStageIndex == 0 || sideStageIndex == 0) {
                if (mainStageIndex == 1 || sideStageIndex == 1) {
                    return topLevelSurfaceList.count > 2 ? 2 : -1;
                }
                return 1;
            }
            return -1;
        }

        readonly property real virtualKeyboardHeight: root.inputMethodRect.height

        readonly property real windowDecorationHeight: units.gu(3)
    }

    Component.onCompleted: priv.updateMainAndSideStageIndexes()

    Connections {
        target: panelState
        onCloseClicked: { if (priv.focusedAppDelegate) { priv.focusedAppDelegate.close(); } }
        onMinimizeClicked: { if (priv.focusedAppDelegate) { priv.focusedAppDelegate.requestMinimize(); } }
        onRestoreClicked: { if (priv.focusedAppDelegate) { priv.focusedAppDelegate.requestRestore(); } }
    }

    Binding {
        target: panelState
        property: "decorationsVisible"
        value: mode == "windowed" && priv.focusedAppDelegate && priv.focusedAppDelegate.maximized && !root.spreadShown
    }

    Binding {
        target: panelState
        property: "title"
        value: {
            if (priv.focusedAppDelegate !== null) {
                if (priv.focusedAppDelegate.maximized)
                    return priv.focusedAppDelegate.title
                else
                    return priv.focusedAppDelegate.appName
            }
            return ""
        }
        when: priv.focusedAppDelegate
    }

    Binding {
        target: panelState
        property: "focusedPersistentSurfaceId"
        value: {
            if (priv.focusedAppDelegate !== null) {
                if (priv.focusedAppDelegate.surface) {
                    return priv.focusedAppDelegate.surface.persistentId;
                }
            }
            return "";
        }
        when: priv.focusedAppDelegate
    }

    Binding {
        target: panelState
        property: "dropShadow"
        value: priv.focusedAppDelegate && !priv.focusedAppDelegate.maximized && priv.foregroundMaximizedAppDelegate !== null && mode == "windowed"
    }

    Binding {
        target: panelState
        property: "closeButtonShown"
        value: priv.focusedAppDelegate && priv.focusedAppDelegate.maximized
    }

    Component.onDestruction: {
        panelState.title = "";
        panelState.decorationsVisible = false;
        panelState.dropShadow = false;
    }

    Instantiator {
        model: root.applicationManager
        delegate: QtObject {
            id: applicationDelegate
            // TODO: figure out some lifecycle policy, like suspending minimized apps
            //       or something if running windowed.
            // TODO: If the device has a dozen suspended apps because it was running
            //       in staged mode, when it switches to Windowed mode it will suddenly
            //       resume all those apps at once. We might want to avoid that.
            property var requestedState: root.mode === "windowed"
                   || (!root.suspended && model.application && priv.focusedAppDelegate &&
                       (priv.focusedAppDelegate.appId === model.application.appId ||
                        priv.mainStageAppId === model.application.appId ||
                        priv.sideStageAppId === model.application.appId))
                   ? ApplicationInfoInterface.RequestedRunning
                   : ApplicationInfoInterface.RequestedSuspended
            property bool temporaryAwaken: ProcessControl.awakenProcesses.indexOf(model.application.appId) >= 0
            property var stateBinding: Binding {
                target: model.application
                property: "requestedState"

                value: applicationDelegate.requestedState
            }

            property var lifecycleBinding: Binding {
                target: model.application
                property: "exemptFromLifecycle"
                value: model.application
                            ? (!model.application.isTouchApp ||
                               isExemptFromLifecycle(model.application.appId) ||
                               applicationDelegate.temporaryAwaken)
                            : false
            }

            property var focusRequestedConnection: Connections {
                target: model.application

                onFocusRequested: {
                    // Application emits focusRequested when it has no surface (i.e. their processes died).
                    // Find the topmost window for this application and activate it, after which the app
                    // will be requested to be running.

                    for (var i = 0; i < appRepeater.count; i++) {
                        var appDelegate = appRepeater.itemAt(i);
                        if (appDelegate.application.appId === model.application.appId) {
                            appDelegate.activate();
                            return;
                        }
                    }

                    console.warn("Application requested te be focused but no window for it. What should we do?");
                }
            }
        }
    }

    states: [
        State {
            name: "spread"; when: priv.goneToSpread
            PropertyChanges { target: floatingFlickable; enabled: true }
            PropertyChanges { target: root; focus: true }
            PropertyChanges { target: spreadItem; focus: true }
            PropertyChanges { target: hoverMouseArea; enabled: true }
            PropertyChanges { target: rightEdgeDragArea; enabled: false }
            PropertyChanges { target: cancelSpreadMouseArea; enabled: true }
            PropertyChanges { target: noAppsRunningHint; visible: (root.topLevelSurfaceList.count < 1) }
            PropertyChanges { target: blurLayer; visible: true; blurRadius: 32; brightness: .65; opacity: 1 }
            // ENH032 - Infographics Outer Wilds
            // PropertyChanges { target: wallpaper; visible: false }
            // For some reason, when side stage is disabled, wallpaper completely hides
            // but not when it is enabled? Weird
            //PropertyChanges { target: wallpaperItem; visible: false }
            // ENH032 - End
            PropertyChanges { target: screensAndWorkspaces; opacity: 1 }
        },
        State {
            name: "stagedRightEdge"; when: root.spreadEnabled && (rightEdgeDragArea.dragging || rightEdgePushProgress > 0) && root.mode == "staged"
            PropertyChanges {
                target: blurLayer;
                visible: true;
                blurRadius: 32
                brightness: .65
                opacity: 1
            }
            PropertyChanges { target: noAppsRunningHint; visible: (root.topLevelSurfaceList.count < 1) }
        },
        State {
            name: "sideStagedRightEdge"; when: root.spreadEnabled && (rightEdgeDragArea.dragging || rightEdgePushProgress > 0) && root.mode == "stagedWithSideStage"
            extend: "stagedRightEdge"
            PropertyChanges {
                target: sideStage
                opacity: priv.sideStageDelegate && priv.sideStageDelegate.x === sideStage.x ? 1 : 0
                visible: true
            }
        },
        State {
            name: "windowedRightEdge"; when: root.spreadEnabled && (rightEdgeDragArea.dragging || rightEdgePushProgress > 0) && root.mode == "windowed"
            PropertyChanges {
                target: blurLayer;
                visible: true
                blurRadius: 32
                brightness: .65
                opacity: MathUtils.linearAnimation(spreadItem.rightEdgeBreakPoint, 1, 0, 1, Math.max(rightEdgeDragArea.dragging ? rightEdgeDragArea.progress : 0, rightEdgePushProgress))
            }
        },
        State {
            name: "staged"; when: root.mode === "staged"
            PropertyChanges { target: root; focus: true }
            PropertyChanges { target: appContainer; focus: true }
        },
        State {
            name: "stagedWithSideStage"; when: root.mode === "stagedWithSideStage"
            // ENH018 - Immersive mode
            // PropertyChanges { target: triGestureArea; enabled: priv.sideStageEnabled }
            PropertyChanges { target: triGestureArea; enabled: priv.sideStageEnabled && !shell.immersiveMode }
            // ENH018 - End
            PropertyChanges { target: sideStage; visible: true }
            PropertyChanges { target: root; focus: true }
            PropertyChanges { target: appContainer; focus: true }
        },
        State {
            name: "windowed"; when: root.mode === "windowed"
            PropertyChanges { target: root; focus: true }
            PropertyChanges { target: appContainer; focus: true }
        }
    ]
    transitions: [
        Transition {
            from: "stagedRightEdge,sideStagedRightEdge,windowedRightEdge"; to: "spread"
            PropertyAction { target: spreadItem; property: "highlightedIndex"; value: -1 }
            PropertyAction { target: screensAndWorkspaces; property: "activeWorkspace"; value: WMScreen.currentWorkspace }
            PropertyAnimation { target: blurLayer; properties: "brightness,blurRadius"; duration: priv.animationDuration }
            LomiriNumberAnimation { target: screensAndWorkspaces; property: "opacity"; duration: priv.animationDuration }
        },
        Transition {
            to: "spread"
            PropertyAction { target: screensAndWorkspaces; property: "activeWorkspace"; value: WMScreen.currentWorkspace }
            PropertyAction { target: spreadItem; property: "highlightedIndex"; value: appRepeater.count > 1 ? 1 : 0 }
            PropertyAction { target: floatingFlickable; property: "contentX"; value: 0 }
            LomiriNumberAnimation { target: screensAndWorkspaces; property: "opacity"; duration: priv.animationDuration }
        },
        Transition {
            from: "spread"
            SequentialAnimation {
                ScriptAction {
                    script: {
                        var item = appRepeater.itemAt(Math.max(0, spreadItem.highlightedIndex));
                        if (item) {
                            if (item.stage == ApplicationInfoInterface.SideStage && !sideStage.shown) {
                                sideStage.show();
                            }
                            item.playFocusAnimation();
                        }
                    }
                }
                PropertyAction { target: spreadItem; property: "highlightedIndex"; value: -1 }
                PropertyAction { target: floatingFlickable; property: "contentX"; value: 0 }
            }
        },
        Transition {
            to: "stagedRightEdge,sideStagedRightEdge"
            PropertyAction { target: floatingFlickable; property: "contentX"; value: 0 }
        },
        Transition {
            to: "stagedWithSideStage"
            ScriptAction { script: priv.updateMainAndSideStageIndexes(); }
        }

    ]

    MouseArea {
        id: cancelSpreadMouseArea
        anchors.fill: parent
        enabled: false
        onClicked: priv.goneToSpread = false
    }

    FocusScope {
        id: appContainer
        objectName: "appContainer"
        anchors.fill: parent
        focus: true

        // ENH032 - Infographics Outer Wilds
        Item {
            id: wallpaperItem
            anchors.fill: parent
            Wallpaper {
                id: wallpaper
                objectName: "stageBackground"
                // ENH032 - Infographics Outer Wilds
                // anchors.fill: parent
                // ENH034 - Separate wallpaper lockscreen and desktop
                // source: root.background
                fallbackSource: root.background
                states: [
                    State {
                        name: "normal"
                        when: !root.enableOW || !root.alternateOW

                        AnchorChanges {
                            target: wallpaper
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }
                    }
                    , State {
                        name: "alternateOW"
                        when: root.enableOW && root.alternateOW
                        AnchorChanges {
                            target: wallpaper
                            anchors.top: undefined
                            anchors.bottom: undefined
                            anchors.left: undefined
                            anchors.right: undefined
                        }
                        PropertyChanges {
                            target: wallpaper
                            x: 0
                            y: 0
                            height: parent.height * 2
                            width: parent.width
                        }
                    }
                ]

                SequentialAnimation {
                    id: bgMoveAnimation

                    readonly property bool shouldRun: root.enableOW && root.alternateOW && !root.suspended

                    running: shouldRun
                    paused: shouldRun && ((priv.focusedAppDelegate && priv.focusedAppDelegate == priv.mainStageDelegate)
                                            || (priv.focusedAppDelegate == priv.sideStageDelegate && sideStage.shown))
                                            // ENH135 - Show Desktop
                                            && !appContainer.showDesktop
                                            // ENH135 - End
                    onStopped: if (shouldRun) restart()
                    onStarted: if (movingItems.item) movingItems.item.probe.resetAnimation()
                    PropertyAction {
                        target: wallpaper
                        property: "y"
                        value: 0
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: wallpaper
                            property: "y"
                            duration: 50000
                            easing.type: Easing.Linear
                            from: 0
                            to: -(height / 2)
                        }
                        SequentialAnimation {
                            PauseAnimation { duration: 49800 }
                            LomiriNumberAnimation {
                                target: wallpaper
                                property: "opacity"
                                duration: 100
                                from: 1
                                to: 0
                            }
                            LomiriNumberAnimation {
                                target: wallpaper
                                property: "opacity"
                                duration: 100
                                from: 0
                                to: 1
                            }
                        }
                        SequentialAnimation {
                            PauseAnimation { duration: 30000 }
                            PropertyAction {
                                target: movingItems.item ? movingItems.item.attlerock : null
                                property: "visible"
                                value: true
                            }
                            PathAnimation {
                                id: flyByAnim

                                duration: 20000
                                target: movingItems.item ? movingItems.item.attlerock : null
                                anchorPoint: Qt.point(0, 0)
                                path: Path {
                                    startX: movingItems.item ? movingItems.item.attlerock.startPos.x : 0
                                    startY: movingItems.item ? movingItems.item.attlerock.startPos.y : 0

                                    PathLine {
                                       x: movingItems.item ? movingItems.item.attlerock.endPos.x : 0
                                       y: movingItems.item ? movingItems.item.attlerock.endPos.y : 0
                                    }
                                }
                            }
                            PropertyAction {
                                target: movingItems.item ? movingItems.item.attlerock : null
                                property: "visible"
                                value: false
                            }
                        }
                    }
                }
                //source: root.enableOW ? "../OuterWilds/graphics/home.png" : fallbackSource
                source: {
                    if (root.enableOW && root.alternateOW) {
                        return "../OuterWilds/graphics/desktop_timberhearth_tall.png"
                    }
                    if (root.enableOW && root.dlcOW) {
                        return "../OuterWilds/graphics/OWDLCWallpaper.png"
                    }
                    if (root.enableOW) {
                        return "../OuterWilds/graphics/home.png"
                    }

                    return fallbackSource
                }
                // ENH032 - End
                // ENH034 - End
                // Make sure it's the lowest item. Due to the left edge drag we sometimes need
                // to put the dash at -1 and we don't want it behind the Wallpaper
                z: -2
            }

            Loader {
                id: movingItems
                active: root.enableOW && root.alternateOW
                anchors.fill: parent
                asynchronous: true
                z: wallpaper.z + 1
                sourceComponent: Component {
                    Item {
                        readonly property alias probe: probe
                        readonly property alias attlerock: attlerockImg

                        Probe {
                            id: probe
                            wallpaperWidth: wallpaperItem.width
                            wallpaperHeight: wallpaperItem.height
                        }
                        
                        Image {
                            id: attlerockImg

                            readonly property point startPos: Qt.point((parent.width / 2) - width - units.gu(20), -height)
                            readonly property point endPos: Qt.point((parent.width / 2) - (width / 2), parent.height)

                            height: units.gu(20)
                            width: height
                            asynchronous: true
                            source: "../OuterWilds/graphics/attlerock_solo.png"
                        }

                        Image {
                            id: quantumMoon

                            readonly property real defaultHOffset: units.gu(15)
                            readonly property real defaultVOffset: -units.gu(10)

                            height: units.gu(15)
                            width: height
                            asynchronous: true
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                verticalCenter: parent.verticalCenter
                                horizontalCenterOffset: defaultHOffset
                                verticalCenterOffset: defaultVOffset
                            }
                            source: "../OuterWilds/graphics/quantum_moon_solo.png"
                            visible: false
                            function reset() {
                                anchors.horizontalCenterOffset = defaultHOffset
                                anchors.verticalCenterOffset = defaultVOffset
                                visible = false
                            }

                            Connections {
                                target: root
                                onEyeOpenedChanged: {
                                    if (!target.blinkComplete) {
                                        quantumMoon.visible = false
                                    }
                                    if (target.eyeOpened) {
                                        let chance = probe.randomize(1, shell.settings.ow_qmChance)

                                        if (chance == 1) {
                                            quantumMoon.visible = true
                                        }
                                    }
                                }
                                onSuspendedChanged: {
                                    if (target.suspended) {
                                        quantumMoon.reset()
                                    }
                                }
                            }
                            ParallelAnimation {
                                id: qmMoveAnimation
                                running: bgMoveAnimation.running
                                paused: bgMoveAnimation.paused
                                onRunningChanged: {
                                    if (!running) {
                                        quantumMoon.reset()
                                        restart()
                                    }
                                }
                                onStopped: if (bgMoveAnimation.shouldRun) quantumMoon.reset()
                                NumberAnimation {
                                    target: quantumMoon
                                    property: "anchors.horizontalCenterOffset"
                                    duration: 40000
                                    easing.type: Easing.Linear
                                    to: - ((parent.width / 2) + width / 2)
                                }
                                NumberAnimation {
                                    target: quantumMoon
                                    property: "anchors.verticalCenterOffset"
                                    duration: 40000
                                    easing.type: Easing.Linear
                                    to: units.gu(10)
                                }
                            }
                            
                        }
                    }
                }
            }

            Loader {
                active: root.enableOW && !root.alternateOW && !root.dlcOW
                            && !root.suspended && (priv.focusedAppDelegate == priv.sideStageDelegate && !sideStage.shown)
                sourceComponent: scoutComponent
                asynchronous: true
                z: wallpaper.z + 1
            }

            Component {
                id: scoutComponent
                Scout {
                    wallpaperWidth: wallpaperItem.width
                    wallpaperHeight: wallpaperItem.height
                }
            }
            
            Loader {
                id: ow_overlayLoader
                active: root.enableOW && root.alternateOW
                asynchronous: true
                anchors.fill: parent
                z: wallpaper.z + 2
                sourceComponent: Component {
                    Wallpaper {
                        source: "../OuterWilds/graphics/overlay_timberhearth.png"
                    }
                }
            }
        }
        // ENH032 - End

        BlurLayer {
            id: blurLayer
            anchors.fill: parent
            // ENH032 - Infographics Outer Wilds
            // source: wallpaper
            source: wallpaperItem
            // ENH032 - End
            visible: false
        }

        ScreensAndWorkspaces {
            id: screensAndWorkspaces
            anchors { left: parent.left; top: parent.top; right: parent.right; leftMargin: root.launcherLeftMargin }
            height: Math.max(units.gu(30), parent.height * .3)
            background: root.background
            opacity: 0
            visible: workspaceEnabled ? opacity > 0 : false
            enabled: workspaceEnabled
            mode: root.mode
            onCloseSpread: priv.goneToSpread = false;
        }

        Spread {
            id: spreadItem
            objectName: "spreadItem"
            anchors {
                left: parent.left;
                bottom: parent.bottom;
                right: parent.right;
                top: workspaceEnabled ? screensAndWorkspaces.bottom : parent.top;
            }
            leftMargin: root.availableDesktopArea.x
            model: root.topLevelSurfaceList
            spreadFlickable: floatingFlickable
            // ENH143 - Fix spread many apps issue
            // z: 10
            z: root.topLevelSurfaceList.count
            // ENH143 - End

            onLeaveSpread: {
                priv.goneToSpread = false;
            }

            onCloseCurrentApp: {
                appRepeater.itemAt(highlightedIndex).close();
            }

            // ENH135 - Show Desktop
            SwipeArea {
                visible: enabled
                enabled: (priv.goneToSpread && shell.settings.enableShowDesktop)
                                || appContainer.showDesktop
                direction: SwipeArea.Upwards
                z: 999
                height: units.gu(2)
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }

                onDraggingChanged: {
                    shell.haptics.play()

                    if (dragging) {
                        appContainer.toggleShowDesktop()
                        spreadItem.leaveSpread()
                    }
                }
            }
            // ENH135 - End

            FloatingFlickable {
                id: floatingFlickable
                objectName: "spreadFlickable"
                anchors.fill: parent
                enabled: false
                contentWidth: spreadItem.spreadTotalWidth

                function snap(toIndex) {
                    var delegate = appRepeater.itemAt(toIndex)
                    var targetContentX = floatingFlickable.contentWidth / spreadItem.totalItemCount * toIndex;
                    if (targetContentX - floatingFlickable.contentX > spreadItem.rightStackXPos - (spreadItem.spreadItemWidth / 2)) {
                        var offset = (spreadItem.rightStackXPos - (spreadItem.spreadItemWidth / 2)) - (targetContentX - floatingFlickable.contentX)
                        snapAnimation.to = floatingFlickable.contentX - offset;
                        snapAnimation.start();
                    } else if (targetContentX - floatingFlickable.contentX < spreadItem.leftStackXPos + units.gu(1)) {
                        var offset = (spreadItem.leftStackXPos + units.gu(1)) - (targetContentX - floatingFlickable.contentX);
                        snapAnimation.to = floatingFlickable.contentX - offset;
                        snapAnimation.start();
                    }
                }
                LomiriNumberAnimation {id: snapAnimation; target: floatingFlickable; property: "contentX"}
            }

            MouseArea {
                id: hoverMouseArea
                objectName: "hoverMouseArea"
                anchors.fill: parent
                propagateComposedEvents: true
                hoverEnabled: true
                enabled: false
                visible: enabled
                property bool wasTouchPress: false

                property int scrollAreaWidth: width / 3
                property bool progressiveScrollingEnabled: false

                onMouseXChanged: {
                    mouse.accepted = false

                    if (hoverMouseArea.pressed || wasTouchPress) {
                        return;
                    }

                    // Find the hovered item and mark it active
                    for (var i = appRepeater.count - 1; i >= 0; i--) {
                        var appDelegate = appRepeater.itemAt(i);
                        var mapped = mapToItem(appDelegate, hoverMouseArea.mouseX, hoverMouseArea.mouseY)
                        var itemUnder = appDelegate.childAt(mapped.x, mapped.y);
                        if (itemUnder && (itemUnder.objectName === "dragArea" || itemUnder.objectName === "windowInfoItem" || itemUnder.objectName == "closeMouseArea")) {
                            spreadItem.highlightedIndex = i;
                            break;
                        }
                    }

                    if (floatingFlickable.contentWidth > floatingFlickable.width) {
                        var margins = floatingFlickable.width * 0.05;

                        if (!progressiveScrollingEnabled && mouseX < floatingFlickable.width - scrollAreaWidth) {
                            progressiveScrollingEnabled = true
                        }

                        // do we need to scroll?
                        if (mouseX < scrollAreaWidth + margins) {
                            var progress = Math.min(1, (scrollAreaWidth + margins - mouseX) / (scrollAreaWidth - margins));
                            var contentX = (1 - progress) * (floatingFlickable.contentWidth - floatingFlickable.width)
                            floatingFlickable.contentX = Math.max(0, Math.min(floatingFlickable.contentX, contentX))
                        }
                        if (mouseX > floatingFlickable.width - scrollAreaWidth && progressiveScrollingEnabled) {
                            var progress = Math.min(1, (mouseX - (floatingFlickable.width - scrollAreaWidth)) / (scrollAreaWidth - margins))
                            var contentX = progress * (floatingFlickable.contentWidth - floatingFlickable.width)
                            floatingFlickable.contentX = Math.min(floatingFlickable.contentWidth - floatingFlickable.width, Math.max(floatingFlickable.contentX, contentX))
                        }
                    }
                }

                onPressed: {
                    mouse.accepted = false;
                    wasTouchPress = mouse.source === Qt.MouseEventSynthesizedByQt;
                }

                onExited: wasTouchPress = false;
            }
        }

        Label {
            id: noAppsRunningHint
            visible: false
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.fill: parent
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            anchors.leftMargin: root.launcherLeftMargin
            wrapMode: Label.WordWrap
            fontSize: "large"
            text: i18n.tr("No running apps")
        }

        Connections {
            target: root.topLevelSurfaceList
            onListChanged: priv.updateMainAndSideStageIndexes()
        }


        DropArea {
            objectName: "MainStageDropArea"
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: appContainer.width - sideStage.width
            enabled: priv.sideStageEnabled

            onDropped: {
                drop.source.appDelegate.saveStage(ApplicationInfoInterface.MainStage);
                drop.source.appDelegate.focus = true;
            }
            keys: "SideStage"
        }

        SideStage {
            id: sideStage
            objectName: "sideStage"
            shown: false
            height: appContainer.height
            x: appContainer.width - width
            // ENH013 - PR#377
            showHint: !priv.sideStageDelegate
            // ENH013 - End
            // ENH135 - Show Desktop
            opacity: appContainer.appDelegateOpacity
            // ENH135 - End
            visible: false
            Behavior on opacity { LomiriNumberAnimation {} }
            z: {
                if (!priv.mainStageItemId) return 0;

                if (priv.sideStageItemId && priv.nextInStack > 0) {

                    // Due the order in which bindings are evaluated, this might be triggered while shuffling
                    // the list and index doesn't yet match with itemIndex (even though itemIndex: index)
                    // Let's walk the list and compare itemIndex to make sure we have the correct one.
                    var nextDelegateInStack = -1;
                    for (var i = 0; i < appRepeater.count; i++) {
                        if (appRepeater.itemAt(i).itemIndex == priv.nextInStack) {
                            nextDelegateInStack = appRepeater.itemAt(i);
                            break;
                        }
                    }

                    if (nextDelegateInStack.stage ===  ApplicationInfoInterface.MainStage) {
                        // if the next app in stack is a main stage app, put the sidestage on top of it.
                        return 2;
                    }
                    return 1;
                }

                return 1;
            }

            onShownChanged: {
                if (!shown && priv.mainStageDelegate && !root.spreadShown) {
                    priv.mainStageDelegate.activate();
                }
            }
            // ENH019 - Side stage floating mode
            InverseMouseArea {
                id: sideStageCloseMouseArea
                anchors.fill: parent
                enabled: priv.focusedAppDelegate && priv.focusedAppDelegate.stage == ApplicationInfoInterface.MainStage && sideStage.floating && sideStage.shown
                visible: enabled
                onPressed: {
                    mouse.accepted = false;
                    sideStage.hide()
                }
            }
            // ENH019 - End

            DropArea {
                id: sideStageDropArea
                objectName: "SideStageDropArea"
                anchors.fill: parent

                property bool dropAllowed: true

                onEntered: {
                    dropAllowed = drag.keys != "Disabled";
                }
                onExited: {
                    dropAllowed = true;
                }
                onDropped: {
                    if (drop.keys == "MainStage") {
                        drop.source.appDelegate.saveStage(ApplicationInfoInterface.SideStage);
                        drop.source.appDelegate.focus = true;
                    }
                }
                drag {
                    onSourceChanged: {
                        if (!sideStageDropArea.drag.source) {
                            dropAllowed = true;
                        }
                    }
                }
            }
        }

        MirSurfaceItem {
            id: fakeDragItem
            property real previewScale: .5
            height: (screensAndWorkspaces.height - units.gu(8)) / 2
            // w : h = iw : ih
            width: implicitWidth * height / implicitHeight
            surfaceWidth: -1
            surfaceHeight: -1
            opacity: surface != null ? 1 : 0
            Behavior on opacity { LomiriNumberAnimation {} }
            visible: opacity > 0
            enabled: workspaceSwitcher

            Drag.active: surface != null
            Drag.keys: ["application"]

            z: 1000
        }
        // ENH135 - Show Desktop
        property bool showDesktop: false
        readonly property real appDelegateOpacity: appContainer.showDesktop ? 0 : 1
        function toggleShowDesktop() {
            showDesktop = !showDesktop
        }
        // ENH135 - End
        Repeater {
            id: appRepeater
            model: topLevelSurfaceList
            objectName: "appRepeater"

            function indexOf(delegateItem) {
                for (var i = 0; i < count; i++) {
                    if (itemAt(i) === delegateItem) {
                        return i;
                    }
                }
                return -1;
            }

            delegate: FocusScope {
                id: appDelegate
                objectName: "appDelegate_" + model.window.id
                property int itemIndex: index // We need this from outside the repeater
                // z might be overriden in some cases by effects, but we need z ordering
                // to calculate occlusion detection
                property int normalZ: topLevelSurfaceList.count - index
                onNormalZChanged: {
                    if (visuallyMaximized) {
                        priv.updateForegroundMaximizedApp();
                    }
                }
                z: normalZ
                // ENH135 - Show Desktop
                enabled: !appContainer.showDesktop
                // opacity: fakeDragItem.surface == model.window.surface && fakeDragItem.Drag.active ? 0 : 1
                opacity: fakeDragItem.surface == model.window.surface && fakeDragItem.Drag.active ? 0 : appContainer.appDelegateOpacity
                // ENH135 - End
                Behavior on opacity { LomiriNumberAnimation {} }

                // Set these as propertyes as they wont update otherwise
                property real screenOffsetX: Screen.virtualX
                property real screenOffsetY: Screen.virtualY

                // Normally we want x/y where the surface thinks it is. Width/height of our delegate will
                // match what the actual surface size is.
                // Don't write to those, they will be set by states
                // --
                // Here we will also need to remove the screen offset from miral's results
                // as lomiri x,y will be relative to the current screen only
                // FIXME: when proper multiscreen lands
                x: model.window.position.x - clientAreaItem.x - screenOffsetX
                y: model.window.position.y - clientAreaItem.y - screenOffsetY
                width: decoratedWindow.implicitWidth
                height: decoratedWindow.implicitHeight

                // requestedX/Y/width/height is what we ask the actual surface to be.
                // Do not write to those, they will be set by states
                property real requestedX: windowedX
                property real requestedY: windowedY
                property real requestedWidth: windowedWidth
                property real requestedHeight: windowedHeight

                // For both windowed and staged need to tell miral what screen we are on,
                // so we need to add the screen offset to the position we tell miral
                // FIXME: when proper multiscreen lands
                Binding {
                    target: model.window; property: "requestedPosition"
                    // miral doesn't know about our window decorations. So we have to deduct them
                    value: Qt.point(appDelegate.requestedX + appDelegate.clientAreaItem.x + screenOffsetX,
                                    appDelegate.requestedY + appDelegate.clientAreaItem.y + screenOffsetY)
                    when: root.mode == "windowed"
                }
                Binding {
                    target: model.window; property: "requestedPosition"
                    value: Qt.point(screenOffsetX, screenOffsetY)
                    when: root.mode != "windowed"
                }

                // In those are for windowed mode. Those values basically store the window's properties
                // when having a floating window. If you want to move/resize a window in normal mode, this is what you want to write to.
                property real windowedX
                property real windowedY
                property real windowedWidth
                property real windowedHeight

                // unlike windowedX/Y, this is the last known grab position before being pushed against edges/corners
                // when restoring, the window should return to these, not to the place where it was dropped near the edge
                property real restoredX
                property real restoredY

                // Keeps track of the window geometry while in normal or restored state
                // Useful when returning from some maxmized state or when saving the geometry while maximized
                // FIXME: find a better solution
                property real normalX: 0
                property real normalY: 0
                property real normalWidth: 0
                property real normalHeight: 0
                function updateNormalGeometry() {
                    if (appDelegate.state == "normal" || appDelegate.state == "restored") {
                        normalX = appDelegate.requestedX;
                        normalY = appDelegate.requestedY;
                        normalWidth = appDelegate.width;
                        normalHeight = appDelegate.height;
                    }
                }
                function updateRestoredGeometry() {
                    if (appDelegate.state == "normal" || appDelegate.state == "restored") {
                        // save the x/y to restore to
                        restoredX = appDelegate.x;
                        restoredY = appDelegate.y;
                    }
                }

                Connections {
                    target: appDelegate
                    onXChanged: appDelegate.updateNormalGeometry();
                    onYChanged: appDelegate.updateNormalGeometry();
                    onWidthChanged: appDelegate.updateNormalGeometry();
                    onHeightChanged: appDelegate.updateNormalGeometry();
                }

                // True when the Stage is focusing this app and playing its own animation.
                // Stays true until the app is unfocused.
                // If it is, we don't want to play the slide in/out transition from StageMaths.
                // Setting it imperatively is not great, but any declarative solution hits
                // race conditions, causing two animations to play for one focus event.
                property bool inhibitSlideAnimation: false

                Binding {
                    target: appDelegate
                    property: "y"
                    value: appDelegate.requestedY -
                           Math.min(appDelegate.requestedY - root.availableDesktopArea.y,
                                    Math.max(0, priv.virtualKeyboardHeight - (appContainer.height - (appDelegate.requestedY + appDelegate.height))))
                    when: root.oskEnabled && appDelegate.focus && (appDelegate.state == "normal" || appDelegate.state == "restored")
                          && root.inputMethodRect.height > 0
                }

                Behavior on x { id: xBehavior; enabled: priv.closingIndex >= 0; LomiriNumberAnimation { onRunningChanged: if (!running) priv.closingIndex = -1} }

                Connections {
                    target: root
                    onShellOrientationAngleChanged: {
                        // at this point decoratedWindow.surfaceOrientationAngle is the old shellOrientationAngle
                        if (application && application.rotatesWindowContents) {
                            if (root.state == "windowed") {
                                var angleDiff = decoratedWindow.surfaceOrientationAngle - shellOrientationAngle;
                                angleDiff = (360 + angleDiff) % 360;
                                if (angleDiff === 90 || angleDiff === 270) {
                                    var aux = decoratedWindow.requestedHeight;
                                    decoratedWindow.requestedHeight = decoratedWindow.requestedWidth + decoratedWindow.actualDecorationHeight;
                                    decoratedWindow.requestedWidth = aux - decoratedWindow.actualDecorationHeight;
                                }
                            }
                            decoratedWindow.surfaceOrientationAngle = shellOrientationAngle;
                        } else {
                            decoratedWindow.surfaceOrientationAngle = 0;
                        }
                    }
                }

                readonly property alias application: decoratedWindow.application
                readonly property alias minimumWidth: decoratedWindow.minimumWidth
                readonly property alias minimumHeight: decoratedWindow.minimumHeight
                readonly property alias maximumWidth: decoratedWindow.maximumWidth
                readonly property alias maximumHeight: decoratedWindow.maximumHeight
                readonly property alias widthIncrement: decoratedWindow.widthIncrement
                readonly property alias heightIncrement: decoratedWindow.heightIncrement

                readonly property bool maximized: windowState === WindowStateStorage.WindowStateMaximized
                readonly property bool maximizedLeft: windowState === WindowStateStorage.WindowStateMaximizedLeft
                readonly property bool maximizedRight: windowState === WindowStateStorage.WindowStateMaximizedRight
                readonly property bool maximizedHorizontally: windowState === WindowStateStorage.WindowStateMaximizedHorizontally
                readonly property bool maximizedVertically: windowState === WindowStateStorage.WindowStateMaximizedVertically
                readonly property bool maximizedTopLeft: windowState === WindowStateStorage.WindowStateMaximizedTopLeft
                readonly property bool maximizedTopRight: windowState === WindowStateStorage.WindowStateMaximizedTopRight
                readonly property bool maximizedBottomLeft: windowState === WindowStateStorage.WindowStateMaximizedBottomLeft
                readonly property bool maximizedBottomRight: windowState === WindowStateStorage.WindowStateMaximizedBottomRight
                readonly property bool anyMaximized: maximized || maximizedLeft || maximizedRight || maximizedHorizontally || maximizedVertically ||
                                                     maximizedTopLeft || maximizedTopRight || maximizedBottomLeft || maximizedBottomRight

                readonly property bool minimized: windowState & WindowStateStorage.WindowStateMinimized
                readonly property bool fullscreen: windowState === WindowStateStorage.WindowStateFullscreen

                readonly property bool canBeMaximized: canBeMaximizedHorizontally && canBeMaximizedVertically
                readonly property bool canBeMaximizedLeftRight: (maximumWidth == 0 || maximumWidth >= appContainer.width/2) &&
                                                                (maximumHeight == 0 || maximumHeight >= appContainer.height)
                readonly property bool canBeCornerMaximized: (maximumWidth == 0 || maximumWidth >= appContainer.width/2) &&
                                                             (maximumHeight == 0 || maximumHeight >= appContainer.height/2)
                readonly property bool canBeMaximizedHorizontally: maximumWidth == 0 || maximumWidth >= appContainer.width
                readonly property bool canBeMaximizedVertically: maximumHeight == 0 || maximumHeight >= appContainer.height
                readonly property alias orientationChangesEnabled: decoratedWindow.orientationChangesEnabled

                // TODO drop our own windowType once Mir/Miral/Qtmir gets in sync with ours
                property int windowState: WindowStateStorage.WindowStateNormal
                property int prevWindowState: WindowStateStorage.WindowStateRestored

                property bool animationsEnabled: true
                property alias title: decoratedWindow.title
                readonly property string appName: model.application ? model.application.name : ""
                property bool visuallyMaximized: false
                property bool visuallyMinimized: false
                readonly property alias windowedTransitionRunning: windowedTransition.running

                property int stage: ApplicationInfoInterface.MainStage
                function saveStage(newStage) {
                    appDelegate.stage = newStage;
                    WindowStateStorage.saveStage(appId, newStage);
                    priv.updateMainAndSideStageIndexes()
                }

                readonly property var surface: model.window.surface
                readonly property var window: model.window

                readonly property alias focusedSurface: decoratedWindow.focusedSurface
                readonly property bool dragging: touchControls.overlayShown ? touchControls.dragging : decoratedWindow.dragging

                readonly property string appId: model.application.appId
                readonly property alias clientAreaItem: decoratedWindow.clientAreaItem

                // It is Lomiri policy to close any window but the last one during OOM teardown
/*
                Connections {
                    target: model.window.surface
                    onLiveChanged: {
                        if ((!surface.live && application && application.surfaceCount > 1) || !application)
                            topLevelSurfaceList.removeAt(appRepeater.indexOf(appDelegate));
                    }
                }
*/

                function activate() {
                    if (model.window.focused) {
                        updateQmlFocusFromMirSurfaceFocus();
                    } else {
                        if (surface.live) {
                            // Activate the window since it has a surface (with a running app) backing it
                            model.window.activate();
                        } else {
                            // Otherwise, cause a respawn of the app, and trigger it's refocusing as the last window
                            topLevelSurfaceList.raiseId(model.window.id);
                        }
                    }
                }
                function requestMaximize() { model.window.requestState(Mir.MaximizedState); }
                function requestMaximizeVertically() { model.window.requestState(Mir.VertMaximizedState); }
                function requestMaximizeHorizontally() { model.window.requestState(Mir.HorizMaximizedState); }
                function requestMaximizeLeft() { model.window.requestState(Mir.MaximizedLeftState); }
                function requestMaximizeRight() { model.window.requestState(Mir.MaximizedRightState); }
                function requestMaximizeTopLeft() { model.window.requestState(Mir.MaximizedTopLeftState); }
                function requestMaximizeTopRight() { model.window.requestState(Mir.MaximizedTopRightState); }
                function requestMaximizeBottomLeft() { model.window.requestState(Mir.MaximizedBottomLeftState); }
                function requestMaximizeBottomRight() { model.window.requestState(Mir.MaximizedBottomRightState); }
                function requestMinimize() { model.window.requestState(Mir.MinimizedState); }
                function requestRestore() { model.window.requestState(Mir.RestoredState); }

                function claimFocus() {
                    if (root.state == "spread") {
                        spreadItem.highlightedIndex = index
                        // force pendingActivation so that when switching to staged mode, topLevelSurfaceList focus won't got to previous app ( case when apps are launched from outside )
                        topLevelSurfaceList.pendingActivation();
                        priv.goneToSpread = false;
                    }
                    if (root.mode == "stagedWithSideStage") {
                        if (appDelegate.stage == ApplicationInfoInterface.SideStage && !sideStage.shown) {
                            sideStage.show();
                        }
                        priv.updateMainAndSideStageIndexes();
                    }
                    appDelegate.focus = true;
                    // ENH019 - Side stage floating mode
                    if (appDelegate.stage == ApplicationInfoInterface.MainStage && sideStage.floating) {
                        sideStage.hide()
                    }
                    // ENH019 - End

                    // Don't set focusedAppDelegate (and signal mainAppChanged) unnecessarily
                    // which can happen after getting interactive again.
                    if (priv.focusedAppDelegate !== appDelegate)
                        priv.focusedAppDelegate = appDelegate;
                }

                function updateQmlFocusFromMirSurfaceFocus() {
                    if (model.window.focused) {
                        claimFocus();
                        decoratedWindow.focus = true;
                    }
                }

                WindowStateSaver {
                    id: windowStateSaver
                    target: appDelegate
                    screenWidth: appContainer.width
                    screenHeight: appContainer.height
                    leftMargin: root.availableDesktopArea.x
                    minimumY: root.availableDesktopArea.y
                }

                Connections {
                    target: model.window
                    onFocusedChanged: {
                        updateQmlFocusFromMirSurfaceFocus();
                        if (!model.window.focused) {
                            inhibitSlideAnimation = false;
                        }
                    }
                    onFocusRequested: {
                        appDelegate.activate();
                    }
                    onStateChanged: {
                        if (value == Mir.MinimizedState) {
                            appDelegate.minimize();
                        } else if (value == Mir.MaximizedState) {
                            appDelegate.maximize();
                        } else if (value == Mir.VertMaximizedState) {
                            appDelegate.maximizeVertically();
                        } else if (value == Mir.HorizMaximizedState) {
                            appDelegate.maximizeHorizontally();
                        } else if (value == Mir.MaximizedLeftState) {
                            appDelegate.maximizeLeft();
                        } else if (value == Mir.MaximizedRightState) {
                            appDelegate.maximizeRight();
                        } else if (value == Mir.MaximizedTopLeftState) {
                            appDelegate.maximizeTopLeft();
                        } else if (value == Mir.MaximizedTopRightState) {
                            appDelegate.maximizeTopRight();
                        } else if (value == Mir.MaximizedBottomLeftState) {
                            appDelegate.maximizeBottomLeft();
                        } else if (value == Mir.MaximizedBottomRightState) {
                            appDelegate.maximizeBottomRight();
                        } else if (value == Mir.RestoredState) {
                            if (appDelegate.fullscreen && appDelegate.prevWindowState != WindowStateStorage.WindowStateRestored
                                    && appDelegate.prevWindowState != WindowStateStorage.WindowStateNormal) {
                                model.window.requestState(WindowStateStorage.toMirState(appDelegate.prevWindowState));
                            } else {
                                appDelegate.restore();
                            }
                        } else if (value == Mir.FullscreenState) {
                            appDelegate.prevWindowState = appDelegate.windowState;
                            appDelegate.windowState = WindowStateStorage.WindowStateFullscreen;
                        }
                    }
                }

                readonly property bool windowReady: clientAreaItem.surfaceInitialized
                onWindowReadyChanged: {
                    if (windowReady) {
                        var loadedMirState = WindowStateStorage.toMirState(windowStateSaver.loadedState);
                        var state = loadedMirState;

                        if (window.state == Mir.FullscreenState) {
                            // If the app is fullscreen at startup, we should not use saved state
                            // Example of why: if you open game that only requests fullscreen at
                            // Statup, this will automaticly be set to "restored state" since
                            // thats the default value of stateStorage, this will result in the app
                            // having the "restored state" as it will not make a fullscreen
                            // call after the app has started.
                            console.log("Initial window state is fullscreen, not using saved state.");
                            state = window.state;
                        } else if (loadedMirState == Mir.FullscreenState) {
                            // If saved state is fullscreen, we should use app initial state
                            // Example of why: if you open browser with youtube video at fullscreen
                            // and close this app, it will be fullscreen next time you open the app.
                            console.log("Saved window state is fullscreen, using initial window state");
                            state = window.state;
                        }

                        // need to apply the shell chrome policy on top the saved window state
                        var policy;
                        if (root.mode == "windowed") {
                            policy = windowedFullscreenPolicy;
                        } else {
                            policy = stagedFullscreenPolicy
                        }
                        window.requestState(policy.applyPolicy(state, surface.shellChrome));
                    }
                }

                Component.onCompleted: {
                    if (application && application.rotatesWindowContents) {
                        decoratedWindow.surfaceOrientationAngle = shellOrientationAngle;
                    } else {
                        decoratedWindow.surfaceOrientationAngle = 0;
                    }

                    // First, cascade the newly created window, relative to the currently/old focused window.
                    windowedX = priv.focusedAppDelegate ? priv.focusedAppDelegate.windowedX + units.gu(3) : (normalZ - 1) * units.gu(3)
                    windowedY = priv.focusedAppDelegate ? priv.focusedAppDelegate.windowedY + units.gu(3) : normalZ * units.gu(3)
                    // Now load any saved state. This needs to happen *after* the cascading!
                    windowStateSaver.load();

                    updateQmlFocusFromMirSurfaceFocus();

                    refreshStage();
                    _constructing = false;
                }
                Component.onDestruction: {
                    windowStateSaver.save();

                    if (!root.parent) {
                        // This stage is about to be destroyed. Don't mess up with the model at this point
                        return;
                    }

                    if (visuallyMaximized) {
                        priv.updateForegroundMaximizedApp();
                    }
                }

                onVisuallyMaximizedChanged: priv.updateForegroundMaximizedApp()

                property bool _constructing: true;
                onStageChanged: {
                    if (!_constructing) {
                        priv.updateMainAndSideStageIndexes();
                    }
                }
                // ENH135 - Show Desktop
                // visible: (
                visible: ( (
                // ENH135 - End
                          !visuallyMinimized
                          && !greeter.fullyShown
                          && (priv.foregroundMaximizedAppDelegate === null || priv.foregroundMaximizedAppDelegate.normalZ <= z)
                         )
                         || appDelegate.fullscreen
                         || focusAnimation.running || rightEdgeFocusAnimation.running || hidingAnimation.running
                         )
                         // ENH135 - Show Desktop
                         && !appContainer.showDesktop
                         // ENH135 - End

                function close() {
                    model.window.close();
                }

                function maximize(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState = WindowStateStorage.WindowStateMaximized;
                }
                function maximizeLeft(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState = WindowStateStorage.WindowStateMaximizedLeft;
                }
                function maximizeRight(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState = WindowStateStorage.WindowStateMaximizedRight;
                }
                function maximizeHorizontally(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState = WindowStateStorage.WindowStateMaximizedHorizontally;
                }
                function maximizeVertically(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState = WindowStateStorage.WindowStateMaximizedVertically;
                }
                function maximizeTopLeft(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState = WindowStateStorage.WindowStateMaximizedTopLeft;
                }
                function maximizeTopRight(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState = WindowStateStorage.WindowStateMaximizedTopRight;
                }
                function maximizeBottomLeft(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState = WindowStateStorage.WindowStateMaximizedBottomLeft;
                }
                function maximizeBottomRight(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState = WindowStateStorage.WindowStateMaximizedBottomRight;
                }
                function minimize(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState |= WindowStateStorage.WindowStateMinimized; // add the minimized bit
                }
                function restore(animated,state) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState = state || WindowStateStorage.WindowStateRestored;
                    windowState &= ~WindowStateStorage.WindowStateMinimized; // clear the minimized bit
                    prevWindowState = windowState;
                }

                function playFocusAnimation() {
                    if (state == "stagedRightEdge") {
                        // TODO: Can we drop this if and find something that always works?
                        if (root.mode == "staged") {
                            rightEdgeFocusAnimation.targetX = 0
                            rightEdgeFocusAnimation.start()
                        } else if (root.mode == "stagedWithSideStage") {
                            rightEdgeFocusAnimation.targetX = appDelegate.stage == ApplicationInfoInterface.SideStage ? sideStage.x : 0
                            rightEdgeFocusAnimation.start()
                        }
                    } else if (state == "windowedRightEdge" || state == "windowed") {
                        activate();
                    } else {
                        focusAnimation.start()
                    }
                }
                function playHidingAnimation() {
                    if (state != "windowedRightEdge") {
                        hidingAnimation.start()
                    }
                }

                function refreshStage() {
                    var newStage = ApplicationInfoInterface.MainStage;
                    if (priv.sideStageEnabled) { // we're in lanscape rotation.
                        if (application && application.supportedOrientations & (Qt.PortraitOrientation|Qt.InvertedPortraitOrientation)) {
                            var defaultStage = ApplicationInfoInterface.SideStage; // if application supports portrait, it defaults to sidestage.
                            if (application.supportedOrientations & (Qt.LandscapeOrientation|Qt.InvertedLandscapeOrientation)) {
                                // if it supports lanscape, it defaults to mainstage.
                                defaultStage = ApplicationInfoInterface.MainStage;
                            }
                            newStage = WindowStateStorage.getStage(application.appId, defaultStage);
                        }
                    }

                    stage = newStage;
                    if (focus && stage == ApplicationInfoInterface.SideStage && !sideStage.shown) {
                        sideStage.show();
                    }
                }

                LomiriNumberAnimation {
                    id: focusAnimation
                    target: appDelegate
                    property: "scale"
                    from: 0.98
                    to: 1
                    duration: LomiriAnimation.SnapDuration
                    onStarted: {
                        topLevelSurfaceList.pendingActivation();
                        topLevelSurfaceList.raiseId(model.window.id);
                    }
                    onStopped: {
                        appDelegate.activate();
                    }
                }
                ParallelAnimation {
                    id: rightEdgeFocusAnimation
                    property int targetX: 0
                    LomiriNumberAnimation { target: appDelegate; properties: "x"; to: rightEdgeFocusAnimation.targetX; duration: priv.animationDuration }
                    LomiriNumberAnimation { target: decoratedWindow; properties: "angle"; to: 0; duration: priv.animationDuration }
                    LomiriNumberAnimation { target: decoratedWindow; properties: "itemScale"; to: 1; duration: priv.animationDuration }
                    onStarted: {
                        topLevelSurfaceList.pendingActivation();
                        inhibitSlideAnimation = true;
                    }
                    onStopped: {
                        appDelegate.activate();
                    }
                }
                ParallelAnimation {
                    id: hidingAnimation
                    LomiriNumberAnimation { target: appDelegate; property: "opacity"; to: 0; duration: priv.animationDuration }
                    // ENH135 - Show Desktop
                    // onStopped: appDelegate.opacity = 1
                    onStopped: appDelegate.opacity = Qt.binding( function() { return appContainer.appDelegateOpacity } )
                    // ENH135 - End
                }

                SpreadMaths {
                    id: spreadMaths
                    spread: spreadItem
                    itemIndex: index
                    flickable: floatingFlickable
                }
                StageMaths {
                    id: stageMaths
                    sceneWidth: root.width
                    stage: appDelegate.stage
                    thisDelegate: appDelegate
                    mainStageDelegate: priv.mainStageDelegate
                    sideStageDelegate: priv.sideStageDelegate
                    sideStageWidth: sideStage.panelWidth
                    sideStageHandleWidth: sideStage.handleWidth
                    sideStageX: sideStage.x
                    // ENH019 - Side stage floating mode
                    sideStageFloating: sideStage.floating
                    // ENH019 - End
                    itemIndex: appDelegate.itemIndex
                    nextInStack: priv.nextInStack
                    animationDuration: priv.animationDuration
                }

                StagedRightEdgeMaths {
                    id: stagedRightEdgeMaths
                    sceneWidth: root.availableDesktopArea.width
                    sceneHeight: appContainer.height
                    isMainStageApp: priv.mainStageDelegate == appDelegate
                    isSideStageApp: priv.sideStageDelegate == appDelegate
                    sideStageWidth: sideStage.width
                    sideStageOpen: sideStage.shown
                    itemIndex: index
                    nextInStack: priv.nextInStack
                    progress: 0
                    targetHeight: spreadItem.stackHeight
                    targetX: spreadMaths.targetX
                    startY: appDelegate.fullscreen ? 0 : root.availableDesktopArea.y
                    targetY: spreadMaths.targetY
                    targetAngle: spreadMaths.targetAngle
                    targetScale: spreadMaths.targetScale
                    shuffledZ: stageMaths.itemZ
                    breakPoint: spreadItem.rightEdgeBreakPoint
                }

                WindowedRightEdgeMaths {
                    id: windowedRightEdgeMaths
                    itemIndex: index
                    startWidth: appDelegate.requestedWidth
                    startHeight: appDelegate.requestedHeight
                    targetHeight: spreadItem.stackHeight
                    targetX: spreadMaths.targetX
                    targetY: spreadMaths.targetY
                    normalZ: appDelegate.normalZ
                    targetAngle: spreadMaths.targetAngle
                    targetScale: spreadMaths.targetScale
                    breakPoint: spreadItem.rightEdgeBreakPoint
                }

                states: [
                    State {
                        name: "spread"; when: root.state == "spread"
                        StateChangeScript { script: { decoratedWindow.cancelDrag(); } }
                        PropertyChanges {
                            target: decoratedWindow;
                            showDecoration: false;
                            angle: spreadMaths.targetAngle
                            itemScale: spreadMaths.targetScale
                            scaleToPreviewSize: spreadItem.stackHeight
                            scaleToPreviewProgress: 1
                            hasDecoration: root.mode === "windowed"
                            shadowOpacity: spreadMaths.shadowOpacity
                            showHighlight: spreadItem.highlightedIndex === index
                            darkening: spreadItem.highlightedIndex >= 0
                            anchors.topMargin: dragArea.distance
                        }
                        PropertyChanges {
                            target: appDelegate
                            x: spreadMaths.targetX
                            y: spreadMaths.targetY
                            z: index
                            height: spreadItem.spreadItemHeight
                            visible: spreadMaths.itemVisible
                        }
                        PropertyChanges { target: dragArea; enabled: true }
                        PropertyChanges { target: windowInfoItem; opacity: spreadMaths.tileInfoOpacity; visible: spreadMaths.itemVisible }
                        PropertyChanges { target: touchControls; enabled: false }
                        // ENH006 - Rounded app spread
                        PropertyChanges {
                            target: roundedCornerEffect;
                            sourceItem: shell.settings.roundedAppPreview ? decoratedWindow.clientAreaItem : null
							cornerRadius: shell.deviceConfiguration.roundedCornerRadius
                        }
                        // ENH006 - End
                    },
                    State {
                        name: "stagedRightEdge"
                        when: (root.mode == "staged" || root.mode == "stagedWithSideStage") && (root.state == "sideStagedRightEdge" || root.state == "stagedRightEdge" || rightEdgeFocusAnimation.running || hidingAnimation.running)
                        PropertyChanges {
                            target: stagedRightEdgeMaths
                            progress: Math.max(rightEdgePushProgress, rightEdgeDragArea.draggedProgress)
                        }
                        PropertyChanges {
                            target: appDelegate
                            x: stagedRightEdgeMaths.animatedX
                            y: stagedRightEdgeMaths.animatedY
                            z: stagedRightEdgeMaths.animatedZ
                            height: stagedRightEdgeMaths.animatedHeight
                            visible: appDelegate.x < root.width
                        }
                        PropertyChanges {
                            target: decoratedWindow
                            hasDecoration: false
                            angle: stagedRightEdgeMaths.animatedAngle
                            itemScale: stagedRightEdgeMaths.animatedScale
                            scaleToPreviewSize: spreadItem.stackHeight
                            scaleToPreviewProgress: stagedRightEdgeMaths.scaleToPreviewProgress
                            shadowOpacity: .3
                        }
                        // ENH006 - Rounded app spread
                        PropertyChanges {
                            target: roundedCornerEffect;
                            sourceItem: shell.settings.roundedAppPreview ? decoratedWindow.clientAreaItem : null
							cornerRadius: shell.deviceConfiguration.roundedCornerRadius
                        }
                        // ENH006 - End
                        // make sure it's visible but transparent so it fades in when we transition to spread
                        PropertyChanges { target: windowInfoItem; opacity: 0; visible: true }
                    },
                    State {
                        name: "windowedRightEdge"
                        when: root.mode == "windowed" && (root.state == "windowedRightEdge" || rightEdgeFocusAnimation.running || hidingAnimation.running || rightEdgePushProgress > 0)
                        PropertyChanges {
                            target: windowedRightEdgeMaths
                            swipeProgress: rightEdgeDragArea.dragging ? rightEdgeDragArea.progress : 0
                            pushProgress: rightEdgePushProgress
                        }
                        PropertyChanges {
                            target: appDelegate
                            x: windowedRightEdgeMaths.animatedX
                            y: windowedRightEdgeMaths.animatedY
                            z: windowedRightEdgeMaths.animatedZ
                            height: stagedRightEdgeMaths.animatedHeight
                        }
                        PropertyChanges {
                            target: decoratedWindow
                            showDecoration: windowedRightEdgeMaths.decorationHeight
                            angle: windowedRightEdgeMaths.animatedAngle
                            itemScale: windowedRightEdgeMaths.animatedScale
                            scaleToPreviewSize: spreadItem.stackHeight
                            scaleToPreviewProgress: windowedRightEdgeMaths.scaleToPreviewProgress
                            shadowOpacity: .3
                        }
                        PropertyChanges {
                            target: opacityEffect;
                            // ENH135 - Show Desktop
                            // opacityValue: windowedRightEdgeMaths.opacityMask
                            opacityValue: appContainer.showDesktop ? 0 : windowedRightEdgeMaths.opacityMask
                            // ENH135 - End
                            sourceItem: windowedRightEdgeMaths.opacityMask < 1 ? decoratedWindow : null
                        }
                    },
                    State {
                        name: "staged"; when: root.state == "staged"
                        PropertyChanges {
                            target: appDelegate
                            x: stageMaths.itemX
                            y: root.availableDesktopArea.y
                            visuallyMaximized: true
                            visible: appDelegate.x < root.width
                        }
                        PropertyChanges {
                            target: appDelegate
                            requestedWidth: appContainer.width
                            requestedHeight: root.availableDesktopArea.height
                            restoreEntryValues: false
                        }
                        PropertyChanges {
                            target: decoratedWindow
                            hasDecoration: false
                        }
                        PropertyChanges {
                            target: resizeArea
                            enabled: false
                        }
                        PropertyChanges {
                            target: stageMaths
                            animateX: !focusAnimation.running && !rightEdgeFocusAnimation.running && itemIndex !== spreadItem.highlightedIndex && !inhibitSlideAnimation
                        }
                        PropertyChanges {
                            target: appDelegate.window
                            allowClientResize: false
                        }
                    },
                    State {
                        name: "stagedWithSideStage"; when: root.state == "stagedWithSideStage"
                        PropertyChanges {
                            target: stageMaths
                            itemIndex: index
                        }
                        PropertyChanges {
                            target: appDelegate
                            x: stageMaths.itemX
                            y: root.availableDesktopArea.y
                            z: stageMaths.itemZ
                            visuallyMaximized: true
                            visible: appDelegate.x < root.width
                        }
                        PropertyChanges {
                            target: appDelegate
                            requestedWidth: stageMaths.itemWidth
                            requestedHeight: root.availableDesktopArea.height
                            restoreEntryValues: false
                        }
                        PropertyChanges {
                            target: decoratedWindow
                            hasDecoration: false
                        }
                        PropertyChanges {
                            target: resizeArea
                            enabled: false
                        }
                        PropertyChanges {
                            target: appDelegate.window
                            allowClientResize: false
                        }
                    },
                    State {
                        name: "maximized"; when: appDelegate.maximized && !appDelegate.minimized
                        PropertyChanges {
                            target: appDelegate;
                            requestedX: root.availableDesktopArea.x;
                            // ENH002 - Notch/Punch hole fix
                            // requestedY: 0;
                            requestedY: shell.shellTopMargin > 0 ? shell.shellTopMargin - decoratedWindow.decorationHeight
                                                                 : 0;
                            // ENH002 - End
                            visuallyMinimized: false;
                            visuallyMaximized: true
                        }
                        PropertyChanges {
                            target: appDelegate
                            requestedWidth: root.availableDesktopArea.width;
                            // ENH002 - Notch/Punch hole fix
                            // requestedHeight: appContainer.height;
                            requestedHeight: appContainer.height - requestedY;
                            // ENH002 - End
                            restoreEntryValues: false
                        }
                        PropertyChanges { target: touchControls; enabled: true }
                        PropertyChanges { target: decoratedWindow; windowControlButtonsVisible: false }
                    },
                    State {
                        name: "fullscreen"; when: appDelegate.fullscreen && !appDelegate.minimized
                        PropertyChanges {
                            target: appDelegate;
                            requestedX: 0
                            requestedY: 0
                        }
                        PropertyChanges {
                            target: appDelegate
                            requestedWidth: appContainer.width
                            requestedHeight: appContainer.height
                            restoreEntryValues: false
                        }
                        PropertyChanges { target: decoratedWindow; hasDecoration: false }
                    },
                    State {
                        name: "normal";
                        when: appDelegate.windowState == WindowStateStorage.WindowStateNormal
                        PropertyChanges {
                            target: appDelegate
                            visuallyMinimized: false
                        }
                        PropertyChanges { target: touchControls; enabled: true }
                        PropertyChanges { target: resizeArea; enabled: true }
                        PropertyChanges { target: decoratedWindow; shadowOpacity: .3; windowControlButtonsVisible: true}
                        PropertyChanges {
                            target: appDelegate
                            requestedWidth: windowedWidth
                            requestedHeight: windowedHeight
                            restoreEntryValues: false
                        }
                    },
                    State {
                        name: "restored";
                        when: appDelegate.windowState == WindowStateStorage.WindowStateRestored
                        extend: "normal"
                        PropertyChanges {
                            restoreEntryValues: false
                            target: appDelegate;
                            windowedX: restoredX;
                            windowedY: restoredY;
                        }
                    },
                    State {
                        name: "maximizedLeft"; when: appDelegate.maximizedLeft && !appDelegate.minimized
                        extend: "normal"
                        PropertyChanges {
                            target: appDelegate
                            windowedX: root.availableDesktopArea.x
                            windowedY: root.availableDesktopArea.y
                            windowedWidth: root.availableDesktopArea.width / 2
                            windowedHeight: root.availableDesktopArea.height
                        }
                    },
                    State {
                        name: "maximizedRight"; when: appDelegate.maximizedRight && !appDelegate.minimized
                        extend: "maximizedLeft"
                        PropertyChanges {
                            target: appDelegate;
                            windowedX: root.availableDesktopArea.x + (root.availableDesktopArea.width / 2)
                        }
                    },
                    State {
                        name: "maximizedTopLeft"; when: appDelegate.maximizedTopLeft && !appDelegate.minimized
                        extend: "normal"
                        PropertyChanges {
                            target: appDelegate
                            windowedX: root.availableDesktopArea.x
                            windowedY: root.availableDesktopArea.y
                            windowedWidth: root.availableDesktopArea.width / 2
                            windowedHeight: root.availableDesktopArea.height / 2
                        }
                    },
                    State {
                        name: "maximizedTopRight"; when: appDelegate.maximizedTopRight && !appDelegate.minimized
                        extend: "maximizedTopLeft"
                        PropertyChanges {
                            target: appDelegate
                            windowedX: root.availableDesktopArea.x + (root.availableDesktopArea.width / 2)
                        }
                    },
                    State {
                        name: "maximizedBottomLeft"; when: appDelegate.maximizedBottomLeft && !appDelegate.minimized
                        extend: "normal"
                        PropertyChanges {
                            target: appDelegate
                            windowedX: root.availableDesktopArea.x
                            windowedY: root.availableDesktopArea.y + (root.availableDesktopArea.height / 2)
                            windowedWidth: root.availableDesktopArea.width / 2
                            windowedHeight: root.availableDesktopArea.height / 2
                        }
                    },
                    State {
                        name: "maximizedBottomRight"; when: appDelegate.maximizedBottomRight && !appDelegate.minimized
                        extend: "maximizedBottomLeft"
                        PropertyChanges {
                            target: appDelegate
                            windowedX: root.availableDesktopArea.x + (root.availableDesktopArea.width / 2)
                        }
                    },
                    State {
                        name: "maximizedHorizontally"; when: appDelegate.maximizedHorizontally && !appDelegate.minimized
                        extend: "normal"
                        PropertyChanges {
                            target: appDelegate
                            windowedX: root.availableDesktopArea.x; windowedY: windowedY
                            windowedWidth: root.availableDesktopArea.width; windowedHeight: windowedHeight
                        }
                    },
                    State {
                        name: "maximizedVertically"; when: appDelegate.maximizedVertically && !appDelegate.minimized
                        extend: "normal"
                        PropertyChanges {
                            target: appDelegate
                            windowedX: windowedX; windowedY: root.availableDesktopArea.y
                            windowedWidth: windowedWidth; windowedHeight: root.availableDesktopArea.height
                        }
                    },
                    State {
                        name: "minimized"; when: appDelegate.minimized
                        PropertyChanges {
                            target: appDelegate
                            scale: units.gu(5) / appDelegate.width
                            opacity: 0;
                            visuallyMinimized: true
                            visuallyMaximized: false
                            x: -appDelegate.width / 2
                            y: root.height / 2
                        }
                    }
                ]

                transitions: [

                    // These two animate applications into position from Staged to Desktop and back
                    Transition {
                        from: "staged,stagedWithSideStage"
                        to: "normal,restored,maximized,maximizedHorizontally,maximizedVertically,maximizedLeft,maximizedRight,maximizedTopLeft,maximizedBottomLeft,maximizedTopRight,maximizedBottomRight"
                        enabled: appDelegate.animationsEnabled
                        PropertyAction { target: appDelegate; properties: "visuallyMinimized,visuallyMaximized" }
                        LomiriNumberAnimation { target: appDelegate; properties: "x,y,requestedX,requestedY,opacity,requestedWidth,requestedHeight,scale"; duration: priv.animationDuration }
                    },
                    Transition {
                        from: "normal,restored,maximized,maximizedHorizontally,maximizedVertically,maximizedLeft,maximizedRight,maximizedTopLeft,maximizedBottomLeft,maximizedTopRight,maximizedBottomRight"
                        to: "staged,stagedWithSideStage"
                        LomiriNumberAnimation { target: appDelegate; properties: "x,y,requestedX,requestedY,requestedWidth,requestedHeight"; duration: priv.animationDuration}
                    },

                    Transition {
                        from: "normal,restored,maximized,maximizedHorizontally,maximizedVertically,maximizedLeft,maximizedRight,maximizedTopLeft,maximizedBottomLeft,maximizedTopRight,maximizedBottomRight,staged,stagedWithSideStage,windowedRightEdge,stagedRightEdge";
                        to: "spread"
                        // DecoratedWindow wants the scaleToPreviewSize set before enabling scaleToPreview
                        PropertyAction { target: appDelegate; properties: "z,visible" }
                        PropertyAction { target: decoratedWindow; property: "scaleToPreviewSize" }
                        LomiriNumberAnimation { target: appDelegate; properties: "x,y,height"; duration: priv.animationDuration }
                        LomiriNumberAnimation { target: decoratedWindow; properties: "width,height,itemScale,angle,scaleToPreviewProgress"; duration: priv.animationDuration }
                        LomiriNumberAnimation { target: windowInfoItem; properties: "opacity"; duration: priv.animationDuration }
                    },
                    Transition {
                        from: "normal,staged"; to: "stagedWithSideStage"
                        LomiriNumberAnimation { target: appDelegate; properties: "x,y,requestedWidth,requestedHeight"; duration: priv.animationDuration }
                    },
                    Transition {
                        to: "windowedRightEdge"
                        ScriptAction {
                            script: {
                                windowedRightEdgeMaths.startX = appDelegate.requestedX
                                windowedRightEdgeMaths.startY = appDelegate.requestedY

                                if (index == 1) {
                                    var thisRect = { x: appDelegate.windowedX, y: appDelegate.windowedY, width: appDelegate.requestedWidth, height: appDelegate.requestedHeight }
                                    var otherDelegate = appRepeater.itemAt(0);
                                    var otherRect = { x: otherDelegate.windowedX, y: otherDelegate.windowedY, width: otherDelegate.requestedWidth, height: otherDelegate.requestedHeight }
                                    var intersectionRect = MathUtils.intersectionRect(thisRect, otherRect)
                                    var mappedInterSectionRect = appDelegate.mapFromItem(root, intersectionRect.x, intersectionRect.y)
                                    opacityEffect.maskX = mappedInterSectionRect.x
                                    opacityEffect.maskY = mappedInterSectionRect.y
                                    opacityEffect.maskWidth = intersectionRect.width
                                    opacityEffect.maskHeight = intersectionRect.height
                                }
                            }
                        }
                    },
                    Transition {
                        from: "stagedRightEdge"; to: "staged"
                        enabled: rightEdgeDragArea.cancelled // only transition back to state if the gesture was cancelled, in the other cases we play the focusAnimations.
                        SequentialAnimation {
                            ParallelAnimation {
                                LomiriNumberAnimation { target: appDelegate; properties: "x,y,height,width,scale"; duration: priv.animationDuration }
                                LomiriNumberAnimation { target: decoratedWindow; properties: "width,height,itemScale,angle,scaleToPreviewProgress"; duration: priv.animationDuration }
                            }
                            // We need to release scaleToPreviewSize at last
                            PropertyAction { target: decoratedWindow; property: "scaleToPreviewSize" }
                            PropertyAction { target: appDelegate; property: "visible" }
                        }
                    },
                    Transition {
                        from: ",normal,restored,maximized,maximizedLeft,maximizedRight,maximizedTopLeft,maximizedTopRight,maximizedBottomLeft,maximizedBottomRight,maximizedHorizontally,maximizedVertically,fullscreen"
                        to: "minimized"
                        SequentialAnimation {
                            ScriptAction { script: { fakeRectangle.stop(); } }
                            PropertyAction { target: appDelegate; property: "visuallyMaximized" }
                            PropertyAction { target: appDelegate; property: "visuallyMinimized" }
                            LomiriNumberAnimation { target: appDelegate; properties: "x,y,scale,opacity"; duration: priv.animationDuration }
                            PropertyAction { target: appDelegate; property: "visuallyMinimized" }
                        }
                    },
                    Transition {
                        from: "minimized"
                        to: ",normal,restored,maximized,maximizedLeft,maximizedRight,maximizedTopLeft,maximizedTopRight,maximizedBottomLeft,maximizedBottomRight,maximizedHorizontally,maximizedVertically,fullscreen"
                        SequentialAnimation {
                            PropertyAction { target: appDelegate; property: "visuallyMinimized,z" }
                            ParallelAnimation {
                                LomiriNumberAnimation { target: appDelegate; properties: "x"; from: -appDelegate.width / 2; duration: priv.animationDuration }
                                LomiriNumberAnimation { target: appDelegate; properties: "y,opacity"; duration: priv.animationDuration }
                                LomiriNumberAnimation { target: appDelegate; properties: "scale"; from: 0; duration: priv.animationDuration }
                            }
                            PropertyAction { target: appDelegate; property: "visuallyMaximized" }
                        }
                    },
                    Transition {
                        id: windowedTransition
                        from: ",normal,restored,maximized,maximizedLeft,maximizedRight,maximizedTopLeft,maximizedTopRight,maximizedBottomLeft,maximizedBottomRight,maximizedHorizontally,maximizedVertically,fullscreen,minimized"
                        to: ",normal,restored,maximized,maximizedLeft,maximizedRight,maximizedTopLeft,maximizedTopRight,maximizedBottomLeft,maximizedBottomRight,maximizedHorizontally,maximizedVertically,fullscreen"
                        enabled: appDelegate.animationsEnabled
                        SequentialAnimation {
                            ScriptAction { script: {
                                    if (appDelegate.visuallyMaximized) visuallyMaximized = false; // maximized before -> going to restored
                                }
                            }
                            PropertyAction { target: appDelegate; property: "visuallyMinimized" }
                            LomiriNumberAnimation { target: appDelegate; properties: "requestedX,requestedY,windowedX,windowedY,opacity,scale,requestedWidth,requestedHeight,windowedWidth,windowedHeight";
                                duration: priv.animationDuration }
                            ScriptAction { script: {
                                    fakeRectangle.stop();
                                    appDelegate.visuallyMaximized = appDelegate.maximized; // reflect the target state
                                }
                            }
                        }
                    }
                ]

                Binding {
                    target: panelState
                    property: "decorationsAlwaysVisible"
                    value: appDelegate && appDelegate.maximized && touchControls.overlayShown
                }

                WindowResizeArea {
                    id: resizeArea
                    objectName: "windowResizeArea"

                    anchors.fill: appDelegate

                    // workaround so that it chooses the correct resize borders when you drag from a corner ResizeGrip
                    anchors.margins: touchControls.overlayShown ? borderThickness/2 : -borderThickness

                    target: appDelegate
                    boundsItem: root.availableDesktopArea
                    minWidth: units.gu(10)
                    minHeight: units.gu(10)
                    borderThickness: units.gu(2)
                    enabled: false
                    visible: enabled
                    readyToAssesBounds: !appDelegate._constructing

                    onPressed: {
                        appDelegate.activate();
                    }
                }

                DecoratedWindow {
                    id: decoratedWindow
                    objectName: "decoratedWindow"
                    anchors.left: appDelegate.left
                    anchors.top: appDelegate.top
                    application: model.application
                    surface: model.window.surface
                    active: model.window.focused
                    focus: true
                    interactive: root.interactive
                    showDecoration: 1
                    decorationHeight: priv.windowDecorationHeight
                    maximizeButtonShown: appDelegate.canBeMaximized
                    overlayShown: touchControls.overlayShown
                    width: implicitWidth
                    height: implicitHeight
                    highlightSize: windowInfoItem.iconMargin / 2
                    boundsItem: root.availableDesktopArea
                    panelState: root.panelState
                    altDragEnabled: root.mode == "windowed"
                    // ENH006 - Rounded app spread
                    highlightRadius: shell.settings.roundedAppPreview ? shell.deviceConfiguration.roundedCornerRadius - 100 : 0
                    // ENH006 - End

                    requestedWidth: appDelegate.requestedWidth
                    requestedHeight: appDelegate.requestedHeight

                    onCloseClicked: { appDelegate.close(); }
                    onMaximizeClicked: {
                        if (appDelegate.canBeMaximized) {
                            appDelegate.anyMaximized ? appDelegate.requestRestore() : appDelegate.requestMaximize();
                        }
                    }
                    onMaximizeHorizontallyClicked: {
                        if (appDelegate.canBeMaximizedHorizontally) {
                            appDelegate.maximizedHorizontally ? appDelegate.requestRestore() : appDelegate.requestMaximizeHorizontally()
                        }
                    }
                    onMaximizeVerticallyClicked: {
                        if (appDelegate.canBeMaximizedVertically) {
                            appDelegate.maximizedVertically ? appDelegate.requestRestore() : appDelegate.requestMaximizeVertically()
                        }
                    }
                    onMinimizeClicked: { appDelegate.requestMinimize(); }
                    onDecorationPressed: { appDelegate.activate(); }
                    onDecorationReleased: fakeRectangle.visible ? fakeRectangle.commit() : appDelegate.updateRestoredGeometry()

                    property real angle: 0
                    Behavior on angle { enabled: priv.closingIndex >= 0; LomiriNumberAnimation {} }
                    property real itemScale: 1
                    Behavior on itemScale { enabled: priv.closingIndex >= 0; LomiriNumberAnimation {} }

                    transform: [
                        Scale {
                            origin.x: 0
                            origin.y: decoratedWindow.implicitHeight / 2
                            xScale: decoratedWindow.itemScale
                            yScale: decoratedWindow.itemScale
                        },
                        Rotation {
                            origin { x: 0; y: (decoratedWindow.height / 2) }
                            axis { x: 0; y: 1; z: 0 }
                            angle: decoratedWindow.angle
                        }
                    ]

                    // ENH006 - Rounded app spread
                    RoundedCornersMask {
						id: roundedCornerEffect
						anchors.fill: parent
					}
					// ENH006 - End
                }

                OpacityMask {
                    id: opacityEffect
                    anchors.fill: decoratedWindow
                }

                WindowControlsOverlay {
                    id: touchControls
                    anchors.fill: appDelegate
                    target: appDelegate
                    resizeArea: resizeArea
                    enabled: false
                    visible: enabled
                    boundsItem: root.availableDesktopArea

                    onFakeMaximizeAnimationRequested: if (!appDelegate.maximized) fakeRectangle.maximize(amount, true)
                    onFakeMaximizeLeftAnimationRequested: if (!appDelegate.maximizedLeft) fakeRectangle.maximizeLeft(amount, true)
                    onFakeMaximizeRightAnimationRequested: if (!appDelegate.maximizedRight) fakeRectangle.maximizeRight(amount, true)
                    onFakeMaximizeTopLeftAnimationRequested: if (!appDelegate.maximizedTopLeft) fakeRectangle.maximizeTopLeft(amount, true);
                    onFakeMaximizeTopRightAnimationRequested: if (!appDelegate.maximizedTopRight) fakeRectangle.maximizeTopRight(amount, true);
                    onFakeMaximizeBottomLeftAnimationRequested: if (!appDelegate.maximizedBottomLeft) fakeRectangle.maximizeBottomLeft(amount, true);
                    onFakeMaximizeBottomRightAnimationRequested: if (!appDelegate.maximizedBottomRight) fakeRectangle.maximizeBottomRight(amount, true);
                    onStopFakeAnimation: fakeRectangle.stop();
                    onDragReleased: fakeRectangle.visible ? fakeRectangle.commit() : appDelegate.updateRestoredGeometry()
                }

                WindowedFullscreenPolicy {
                    id: windowedFullscreenPolicy
                }
                StagedFullscreenPolicy {
                    id: stagedFullscreenPolicy
                    active: root.mode == "staged" || root.mode == "stagedWithSideStage"
                    surface: model.window.surface
                }

                SpreadDelegateInputArea {
                    id: dragArea
                    objectName: "dragArea"
                    anchors.fill: decoratedWindow
                    enabled: false
                    closeable: true
                    stage: root
                    dragDelegate: fakeDragItem

                    onClicked: {
                        spreadItem.highlightedIndex = index;
                        if (distance == 0) {
                            priv.goneToSpread = false;
                        }
                    }
                    onClose: {
                        priv.closingIndex = index
                        appDelegate.close();
                    }
                }

                WindowInfoItem {
                    id: windowInfoItem
                    objectName: "windowInfoItem"
                    anchors { left: parent.left; top: decoratedWindow.bottom; topMargin: units.gu(1) }
                    title: model.application.name
                    iconSource: model.application.icon
                    height: spreadItem.appInfoHeight
                    opacity: 0
                    z: 1
                    visible: opacity > 0
                    maxWidth: {
                        var nextApp = appRepeater.itemAt(index + 1);
                        if (nextApp) {
                            return Math.max(iconHeight, nextApp.x - appDelegate.x - units.gu(1))
                        }
                        return appDelegate.width;
                    }

                    onClicked: {
                        spreadItem.highlightedIndex = index;
                        priv.goneToSpread = false;
                    }
                }

                MouseArea {
                    id: closeMouseArea
                    objectName: "closeMouseArea"
                    anchors { left: parent.left; top: parent.top; leftMargin: -height / 2; topMargin: -height / 2 + spreadMaths.closeIconOffset }
                    readonly property var mousePos: hoverMouseArea.mapToItem(appDelegate, hoverMouseArea.mouseX, hoverMouseArea.mouseY)
                    readonly property bool shown: dragArea.distance == 0
                             && index == spreadItem.highlightedIndex
                             && mousePos.y < (decoratedWindow.height / 3)
                             && mousePos.y > -units.gu(4)
                             && mousePos.x > -units.gu(4)
                             && mousePos.x < (decoratedWindow.width * 2 / 3)
                    opacity: shown ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }
                    height: units.gu(6)
                    width: height

                    onClicked: {
                        priv.closingIndex = index;
                        appDelegate.close();
                    }
                    Image {
                        id: closeImage
                        source: "graphics/window-close.svg"
                        anchors.fill: closeMouseArea
                        anchors.margins: units.gu(2)
                        sourceSize.width: width
                        sourceSize.height: height
                    }
                }

                Item {
                    // Group all child windows in this item so that we can fade them out together when going to the spread
                    // (and fade them in back again when returning from it)
                    readonly property bool stageOnProperState: root.state === "windowed"
                                                            || root.state === "staged"
                                                            || root.state === "stagedWithSideStage"

                    // TODO: Is it worth the extra cost of layering to avoid the opacity artifacts of intersecting children?
                    //       Btw, will involve more than uncommenting the line below as children won't necessarily fit this item's
                    //       geometry. This is just a reference.
                    //layer.enabled: opacity !== 0.0 && opacity !== 1.0

                    opacity: stageOnProperState ? 1.0 : 0.0
                    visible: opacity !== 0.0 // make it transparent to input as well
                    Behavior on opacity { LomiriNumberAnimation {} }

                    Repeater {
                        id: childWindowRepeater
                        model: appDelegate.surface ? appDelegate.surface.childSurfaceList : null

                        delegate: ChildWindowTree {
                            surface: model.surface

                            // Account for the displacement caused by window decoration in the top-level surface
                            // Ie, the top-level surface is not positioned at (0,0) of this ChildWindow's parent (appDelegate)
                            displacementX: appDelegate.clientAreaItem.x
                            displacementY: appDelegate.clientAreaItem.y

                            boundsItem: root.availableDesktopArea
                            decorationHeight: priv.windowDecorationHeight

                            z: childWindowRepeater.count - model.index

                            onFocusChanged: {
                                if (focus) {
                                    // some child surface in this tree got focus.
                                    // Ensure we also have it at the top-level hierarchy
                                    appDelegate.claimFocus();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    FakeMaximizeDelegate {
        id: fakeRectangle
        target: priv.focusedAppDelegate
        leftMargin: root.availableDesktopArea.x
        appContainerWidth: appContainer.width
        appContainerHeight: appContainer.height
        panelState: root.panelState
    }

    WorkspaceSwitcher {
        id: workspaceSwitcher
        enabled: workspaceEnabled
        anchors.centerIn: parent
        height: units.gu(20)
        width: root.width - units.gu(8)
        background: root.background
        onActiveChanged: {
            if (!active) {
                appContainer.focus = true;
            }
        }
    }

    PropertyAnimation {
        id: shortRightEdgeSwipeAnimation
        property: "x"
        to: 0
        duration: priv.animationDuration
    }

    SwipeArea {
        id: rightEdgeDragArea
        objectName: "rightEdgeDragArea"
        direction: Direction.Leftwards
        // ENH002 - Notch/Punch hole fix
        // anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
        // width: root.dragAreaWidth
        //anchors { top: parent.top; right: parent.right; bottom: parent.bottom; rightMargin: shell.isBuiltInScreen ? -170 : 0 }
        //width: root.dragAreaWidth + (shell.isBuiltInScreen ? 170 : 0)
        anchors { top: parent.top; right: parent.right; bottom: parent.bottom; rightMargin: shell.isBuiltInScreen ? -shell.deviceConfiguration.notchHeightMargin : 0 }
        width: root.dragAreaWidth + (shell.isBuiltInScreen ? shell.deviceConfiguration.notchHeightMargin : 0)
        // ENH002 - End
        // ENH018 - Immersive mode
        // enabled: root.spreadEnabled
        enabled: root.spreadEnabled && !shell.immersiveMode
        // ENH018 - End

        property var gesturePoints: []
        property bool cancelled: false

        property real progress: -touchPosition.x / root.width
        onProgressChanged: {
            if (dragging) {
                draggedProgress = progress;
            }
        }

        property real draggedProgress: 0

        onTouchPositionChanged: {
            gesturePoints.push(touchPosition.x);
            if (gesturePoints.length > 10) {
                gesturePoints.splice(0, gesturePoints.length - 10)
            }
        }

        onDraggingChanged: {
            if (dragging) {
                // A potential edge-drag gesture has started. Start recording it
                gesturePoints = [];
                cancelled = false;
                draggedProgress = 0;
                // ENH135 - Show Desktop
                appContainer.showDesktop = false
                // ENH135 - End
            } else {
                // Ok. The user released. Did he drag far enough to go to full spread?
                if (gesturePoints[gesturePoints.length - 1] < -spreadItem.rightEdgeBreakPoint * spreadItem.width ) {

                    // He dragged far enough, but if the last movement was a flick to the right again, he wants to cancel the spread again.
                    var oneWayFlickToRight = true;
                    var smallestX = gesturePoints[0]-1;
                    for (var i = 0; i < gesturePoints.length; i++) {
                        if (gesturePoints[i] <= smallestX) {
                            oneWayFlickToRight = false;
                            break;
                        }
                        smallestX = gesturePoints[i];
                    }

                    if (!oneWayFlickToRight) {
                        // Ok, the user made it, let's go to spread!
                        priv.goneToSpread = true;
                    } else {
                        cancelled = true;
                    }
                } else {
                    // Ok, the user didn't drag far enough to cross the breakPoint
                    // Find out if it was a one-way movement to the left, in which case we just switch directly to next app.
                    var oneWayFlick = true;
                    var smallestX = rightEdgeDragArea.width;
                    for (var i = 0; i < gesturePoints.length; i++) {
                        if (gesturePoints[i] >= smallestX) {
                            oneWayFlick = false;
                            break;
                        }
                        smallestX = gesturePoints[i];
                    }

                    if (appRepeater.count > 1 &&
                            (oneWayFlick && rightEdgeDragArea.distance > units.gu(2) || rightEdgeDragArea.distance > spreadItem.rightEdgeBreakPoint * spreadItem.width)) {
                        var nextStage = appRepeater.itemAt(priv.nextInStack).stage
                        for (var i = 0; i < appRepeater.count; i++) {
                            if (i != priv.nextInStack && appRepeater.itemAt(i).stage == nextStage) {
                                appRepeater.itemAt(i).playHidingAnimation()
                                break;
                            }
                        }
                        appRepeater.itemAt(priv.nextInStack).playFocusAnimation()
                        if (appRepeater.itemAt(priv.nextInStack).stage == ApplicationInfoInterface.SideStage && !sideStage.shown) {
                            sideStage.show();
                        }

                    } else {
                        cancelled = true;
                    }

                    gesturePoints = [];
                }
            }
        }
    }

    TabletSideStageTouchGesture {
        id: triGestureArea
        objectName: "triGestureArea"
        anchors.fill: parent
        enabled: false
        property Item appDelegate

        dragComponent: dragComponent
        dragComponentProperties: { "appDelegate": appDelegate }

        onPressed: {
            function matchDelegate(obj) { return String(obj.objectName).indexOf("appDelegate") >= 0; }

            var delegateAtCenter = Functions.itemAt(appContainer, x, y, matchDelegate);
            if (!delegateAtCenter) return;

            appDelegate = delegateAtCenter;
        }

        onClicked: {
        // ENH015 - Add shortcuts for side stage
        /*
            if (sideStage.shown) {
                sideStage.hide();
            } else  {
                sideStage.show();
                priv.updateMainAndSideStageIndexes()
            }
		*/
		priv.toggleSideStage()
		// ENH015 - End
        }

        onDragStarted: {
            // If we're dragging to the sidestage.
            if (!sideStage.shown) {
                sideStage.show();
            }
        }
        // ENH012 - PR#376
        onDropped: {
            if (!priv.sideStageDelegate) {
                sideStage.hide();
            }
        }
        // ENH012 - End

        Component {
            id: dragComponent
            SurfaceContainer {
                property Item appDelegate

                surface: appDelegate ? appDelegate.surface : null

                consumesInput: false
                interactive: false
                focus: false
                requestedWidth: appDelegate ? appDelegate.requestedWidth : 0
                requestedHeight: appDelegate ? appDelegate.requestedHeight : 0

                width: units.gu(40)
                height: units.gu(40)

                Drag.hotSpot.x: width/2
                Drag.hotSpot.y: height/2
                // only accept opposite stage.
                Drag.keys: {
                    if (!surface) return "Disabled";

                    if (appDelegate.stage === ApplicationInfo.MainStage) {
                        if (appDelegate.application.supportedOrientations
                                & (Qt.PortraitOrientation|Qt.InvertedPortraitOrientation)) {
                            return "MainStage";
                        }
                        return "Disabled";
                    }
                    return "SideStage";
                }
            }
        }
    }
}
