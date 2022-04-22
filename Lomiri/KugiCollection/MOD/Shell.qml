/*
 * Copyright (C) 2013-2016 Canonical, Ltd.
 * Copyright (C) 2019-2021 UBports Foundation
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

import QtQuick 2.8
import QtQuick.Window 2.2
import AccountsService 0.1
import Unity.Application 0.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Gestures 0.1
import Ubuntu.Telephony 0.1 as Telephony
import Unity.Connectivity 0.1
import Unity.Launcher 0.1
import GlobalShortcut 1.0 // has to be before Utils, because of WindowInputFilter
import GSettings 1.0
import Utils 0.1
import Powerd 0.1
import SessionBroadcast 0.1
import "Greeter"
import "Launcher"
import "Panel"
import "Components"
import "Notifications"
import "Stage"
import "Tutorial"
import "Wizard"
import Unity.Notifications 1.0 as NotificationBackend
import Unity.Session 0.1
import Unity.Indicators 0.1 as Indicators
import Cursor 1.1
import WindowManager 1.0


StyledItem {
    id: shell

    theme.name: "Ubuntu.Components.Themes.SuruDark"
    
    // ENH002 - Notch/Punch hole fix
    property alias deviceConfiguration: deviceConfiguration   
    //property real shellMargin: shell.isBuiltInScreen ? 160 : 0 //units.gu(6.5)
    property real shellMargin: shell.isBuiltInScreen ? deviceConfiguration.notchHeightMargin : 0 //units.gu(6.5)
	property real shellLeftMargin: orientation == 8 ? shellMargin : 0
	property real shellRightMargin: orientation == 2 ? shellMargin : 0
	property real shellBottomMargin: orientation == 4 ? shellMargin : 0
	property real shellTopMargin: orientation == 1 ? shellMargin : 0
    readonly property bool isBuiltInScreen: Screen.name == Qt.application.screens[0].name
	// ENH002 - End

    // to be set from outside
    property int orientationAngle: 0
    property int orientation
    property Orientations orientations
    property real nativeWidth
    property real nativeHeight
    property alias panelAreaShowProgress: panel.panelAreaShowProgress
    property string usageScenario: "phone" // supported values: "phone", "tablet" or "desktop"
    property string mode: "full-greeter"
    property bool interactiveBlur: false
    property alias oskEnabled: inputMethod.enabled
    function updateFocusedAppOrientation() {
        stage.updateFocusedAppOrientation();
    }
    function updateFocusedAppOrientationAnimated() {
        stage.updateFocusedAppOrientationAnimated();
    }
    property bool hasMouse: false
    property bool hasKeyboard: false
    property bool hasTouchscreen: false
    property bool supportsMultiColorLed: true

    // The largest dimension, in pixels, of all of the screens this Shell is
    // operating on.
    // If a script sets the shell to 240x320 when it was 320x240, we could
    // end up in a situation where our dimensions are 240x240 for a short time.
    // Notifying the Wallpaper of both events would make it reload the image
    // twice. So, we use a Binding { delayed: true }.
    property real largestScreenDimension
    Binding {
        target: shell
        delayed: true
        property: "largestScreenDimension"
        value: Math.max(nativeWidth, nativeHeight)
    }

    // Used by tests
    property alias lightIndicators: indicatorsModel.light

    // to be read from outside
    readonly property int mainAppWindowOrientationAngle: stage.mainAppWindowOrientationAngle

    readonly property bool orientationChangesEnabled: panel.indicators.fullyClosed
            && stage.orientationChangesEnabled
            && (!greeter.animating)

    readonly property bool showingGreeter: greeter && greeter.shown

    property bool startingUp: true
    Timer { id: finishStartUpTimer; interval: 500; onTriggered: startingUp = false }

    property int supportedOrientations: {
        if (startingUp) {
            // Ensure we don't rotate during start up
            return Qt.PrimaryOrientation;
        } else if (notifications.topmostIsFullscreen) {
            return Qt.PrimaryOrientation;
        } else {
            return shell.orientations ? shell.orientations.map(stage.supportedOrientations) : Qt.PrimaryOrientation;
        }
    }

    readonly property var mainApp: stage.mainApp

    onMainAppChanged: {
        _onMainAppChanged((mainApp ? mainApp.appId : ""));
    }
    Connections {
        target: ApplicationManager
        onFocusRequested: {
            if (shell.mainApp && shell.mainApp.appId === appId) {
                _onMainAppChanged(appId);
            }
        }
    }

    // Calls attention back to the most important thing that's been focused
    // (ex: phone calls go over Wizard, app focuses go over indicators, greeter
    // goes over everything if it is locked)
    // Must be called whenever app focus changes occur, even if the focus change
    // is "nothing is focused".  In that case, call with appId = ""
    function _onMainAppChanged(appId) {

        if (appId !== "") {
            if (wizard.active) {
                // If this happens on first boot, we may be in the
                // wizard while receiving a call.  A call is more
                // important than the wizard so just bail out of it.
                wizard.hide();
            }

            if (appId === "dialer-app" && callManager.hasCalls && greeter.locked) {
                // If we are in the middle of a call, make dialer lockedApp. The
                // Greeter will show it when it's notified of the focus.
                // This can happen if user backs out of dialer back to greeter, then
                // launches dialer again.
                greeter.lockedApp = appId;
            }

            panel.indicators.hide();
            launcher.hide(launcher.ignoreHideIfMouseOverLauncher);
        }

        // *Always* make sure the greeter knows that the focused app changed
        if (greeter) greeter.notifyAppFocusRequested(appId);
    }

    // For autopilot consumption
    readonly property string focusedApplicationId: ApplicationManager.focusedApplicationId

    // Note when greeter is waiting on PAM, so that we can disable edges until
    // we know which user data to show and whether the session is locked.
    readonly property bool waitingOnGreeter: greeter && greeter.waiting

    // True when the user is logged in with no apps running
    readonly property bool atDesktop: topLevelSurfaceList && greeter && topLevelSurfaceList.count === 0 && !greeter.active

    onAtDesktopChanged: {
        if (atDesktop && stage) {
            stage.closeSpread();
        }
    }

    property real edgeSize: units.gu(settings.edgeDragWidth)
    
    // ENH002 - Notch/Punch hole fix
    DeviceConfiguration {
        id: deviceConfiguration
        name: applicationArguments.deviceName
    }

    Rectangle {
		id: shellBorder
		z: 1000
		color: "transparent"
		//radius: 270
		radius: deviceConfiguration.roundedCornerRadius
        //visible: shell.isBuiltInScreen
        visible: shell.isBuiltInScreen && deviceConfiguration.withNotch
		anchors {
			fill: parent
		}
		border {
			color: "black"
			width: shell.shellMargin
		}
		states: [
			State {
				name: "portrait"
				when: orientation == 1

				PropertyChanges {
					target: shellBorder
					visible: deviceConfiguration.fullyHideNotchInPortrait
                    anchors.bottomMargin: -shell.shellMargin
					anchors.rightMargin: -shell.shellMargin
					anchors.leftMargin: -shell.shellMargin
				}
			}
			,State {
				name: "invertedportrait"
				when: orientation == 4

				PropertyChanges {
					target: shellBorder
					anchors.topMargin: -shell.shellMargin
					anchors.rightMargin: -shell.shellMargin
					anchors.leftMargin: -shell.shellMargin
				}
			}
			,State {
				name: "landscape"
				when: orientation == 2

				PropertyChanges {
					target: shellBorder
					anchors.topMargin: -shell.shellMargin
					anchors.bottomMargin: -shell.shellMargin
					anchors.rightMargin: 0
					anchors.leftMargin: -shell.shellMargin
				}
			}
			,State {
				name: "invertedlandscape"
				when: orientation == 8

				PropertyChanges {
					target: shellBorder
					anchors.topMargin: -shell.shellMargin
					anchors.bottomMargin: -shell.shellMargin
					anchors.rightMargin: -shell.shellMargin
					anchors.leftMargin: 0
				}
			}
		]

        Rectangle {
            // so screenshots can be clean
            id: blackBorder
            color: "transparent"
            anchors.fill: parent
            border {
                color: "black"
                width: shell.shellMargin
            }
        }
	}
    // ENH002 - End
    
    // ENH018 - Immersive mode
    /* Detect Immersive mode */
    property bool immersiveMode: settings.edgeDragWidth == 0
    // ENH018 - End

    WallpaperResolver {
        id: wallpaperResolver
        objectName: "wallpaperResolver"

        readonly property url defaultBackground: "file://" + Constants.defaultWallpaper
        readonly property bool hasCustomBackground: background != defaultBackground

        GSettings {
            id: backgroundSettings
            schema.id: "org.gnome.desktop.background"
        }

        candidates: [
            AccountsService.backgroundFile,
            backgroundSettings.pictureUri,
            defaultBackground
        ]
    }

    readonly property alias greeter: greeterLoader.item

    function activateApplication(appId) {
        topLevelSurfaceList.pendingActivation();

        // Either open the app in our own session, or -- if we're acting as a
        // greeter -- ask the user's session to open it for us.
        if (shell.mode === "greeter") {
            activateURL("application:///" + appId + ".desktop");
        } else {
            startApp(appId);
        }
        stage.focus = true;
    }

    function activateURL(url) {
        SessionBroadcast.requestUrlStart(AccountsService.user, url);
        greeter.notifyUserRequestedApp();
        panel.indicators.hide();
    }

    function startApp(appId) {
        if (ApplicationManager.findApplication(appId)) {
            ApplicationManager.requestFocusApplication(appId);
        } else {
            ApplicationManager.startApplication(appId);
        }
    }

    function startLockedApp(app) {
        topLevelSurfaceList.pendingActivation();

        if (greeter.locked) {
            greeter.lockedApp = app;
        }
        startApp(app); // locked apps are always in our same session
    }

    Binding {
        target: LauncherModel
        property: "applicationManager"
        value: ApplicationManager
    }

    Component.onCompleted: {
        finishStartUpTimer.start();
    }

    VolumeControl {
        id: volumeControl
    }

    PhysicalKeysMapper {
        id: physicalKeysMapper
        objectName: "physicalKeysMapper"

        onPowerKeyLongPressed: dialogs.showPowerDialog();
        onVolumeDownTriggered: volumeControl.volumeDown();
        onVolumeUpTriggered: volumeControl.volumeUp();
        onScreenshotTriggered: itemGrabber.capture(shell);
    }

    GlobalShortcut {
        // dummy shortcut to force creation of GlobalShortcutRegistry before WindowInputFilter
    }

    WindowInputFilter {
        id: inputFilter
        Keys.onPressed: physicalKeysMapper.onKeyPressed(event, lastInputTimestamp);
        Keys.onReleased: physicalKeysMapper.onKeyReleased(event, lastInputTimestamp);
    }

    WindowInputMonitor {
        objectName: "windowInputMonitor"
        onHomeKeyActivated: {
            // Ignore when greeter is active, to avoid pocket presses
            if (!greeter.active) {
                launcher.toggleDrawer(/* focusInputField */  false,
                                      /* onlyOpen */         false,
                                      /* alsoToggleLauncher */ true);
            }
        }
        onTouchBegun: { cursor.opacity = 0; }
        onTouchEnded: {
            // move the (hidden) cursor to the last known touch position
            var mappedCoords = mapFromItem(null, pos.x, pos.y);
            cursor.x = mappedCoords.x;
            cursor.y = mappedCoords.y;
            cursor.mouseNeverMoved = false;
        }
    }

    AvailableDesktopArea {
        id: availableDesktopAreaItem
        anchors.fill: parent
        // ENH002 - Notch/Punch hole fix
        // anchors.topMargin: panel.fullscreenMode ? 0 : panel.minimizedPanelHeight
        // anchors.leftMargin: launcher.lockedVisible ? launcher.panelWidth : 0
        anchors.topMargin: panel.fullscreenMode ? shell.shellTopMargin 
                                    : deviceConfiguration.fullyHideNotchInPortrait ? shell.shellTopMargin + panel.minimizedPanelHeight
                                                    : panel.minimizedPanelHeight// in portrait, there's a top margin even in fullscreen mode
        anchors.leftMargin: (launcher.lockedVisible ? launcher.panelWidth : 0) + shell.shellLeftMargin
        anchors.rightMargin: shell.shellRightMargin
        anchors.bottomMargin: shell.shellBottomMargin
        // ENH002 - End
    }

    GSettings {
        id: settings
        schema.id: "com.canonical.Unity8"
    }

    Item {
        id: stages
        objectName: "stages"
        width: parent.width
        height: parent.height

        SurfaceManager {
            id: surfaceMan
            objectName: "surfaceManager"
        }
        TopLevelWindowModel {
            id: topLevelSurfaceList
            objectName: "topLevelSurfaceList"
            applicationManager: ApplicationManager // it's a singleton
            surfaceManager: surfaceMan
        }

        Stage {
            id: stage
            objectName: "stage"
            anchors.fill: parent
            // ENH002 - Notch/Punch hole fix
			anchors.leftMargin: shell.shellLeftMargin
			anchors.rightMargin: shell.shellRightMargin
			anchors.bottomMargin: shell.shellBottomMargin
			// ENH002 - End
            focus: true

            dragAreaWidth: shell.edgeSize
            background: wallpaperResolver.background
            backgroundSourceSize: shell.largestScreenDimension

            applicationManager: ApplicationManager
            topLevelSurfaceList: topLevelSurfaceList
            inputMethodRect: inputMethod.visibleRect
            rightEdgePushProgress: rightEdgeBarrier.progress
            availableDesktopArea: availableDesktopAreaItem
            launcherLeftMargin: launcher.visibleWidth

            property string usageScenario: shell.usageScenario === "phone" || greeter.hasLockedApp
                                                       ? "phone"
                                                       : shell.usageScenario
            // ENH026 - Enable side-stage
            // mode: usageScenario == "phone" ? "staged"
            mode: usageScenario == "phone" ? "stagedWithSideStage"
            // ENH026 - End
                     : usageScenario == "tablet" ? "stagedWithSideStage"
                     : "windowed"

            shellOrientation: shell.orientation
            shellOrientationAngle: shell.orientationAngle
            orientations: shell.orientations
            nativeWidth: shell.nativeWidth
            nativeHeight: shell.nativeHeight

            allowInteractivity: (!greeter || !greeter.shown)
                                && panel.indicators.fullyClosed
                                && !notifications.useModal
                                && !launcher.takesFocus

            suspended: greeter.shown
            altTabPressed: physicalKeysMapper.altTabPressed
            oskEnabled: shell.oskEnabled
            spreadEnabled: tutorial.spreadEnabled && (!greeter || (!greeter.hasLockedApp && !greeter.shown))

            onSpreadShownChanged: {
                panel.indicators.hide();
                panel.applicationMenus.hide();
            }
        }

        TouchGestureArea {
            anchors.fill: stage

            minimumTouchPoints: 4
            maximumTouchPoints: minimumTouchPoints
            // ENH018 - Immersive mode
            enabled: !shell.immersiveMode
            // ENH018 - End

            readonly property bool recognisedPress: status == TouchGestureArea.Recognized &&
                                                    touchPoints.length >= minimumTouchPoints &&
                                                    touchPoints.length <= maximumTouchPoints
            property bool wasPressed: false

            onRecognisedPressChanged: {
                if (recognisedPress) {
                    wasPressed = true;
                }
            }

            onStatusChanged: {
                if (status !== TouchGestureArea.Recognized) {
                    if (status === TouchGestureArea.WaitingForTouch) {
                        if (wasPressed && !dragging) {
                            launcher.toggleDrawer(true);
                        }
                    }
                    wasPressed = false;
                }
            }
        }
    }

    // ENH028 - Open indicators via gesture
    SwipeArea {
        id: indicatorsBottomSwipe
        
        // draggingCustom is used for implementing trigger delay
        property bool draggingCustom: distance >= units.gu(4) 
        
        signal triggered
        enabled: !shell.immersiveMode
        direction: SwipeArea.Upwards
        height: units.gu(5)
        width: units.gu(6)
        z: greeter.fullyShown ? greeter.z + 1 : overlay.z - 1
        anchors {
            right: parent.right
            rightMargin: -(width / 2)
            bottom: parent.bottom
            bottomMargin: -(height / 2)
        }
        immediateRecognition: true
        transform: Rotation { origin.x: indicatorsBottomSwipe.width / 2; origin.y: indicatorsBottomSwipe.height / 2; angle: -80}
        
        onDraggingCustomChanged: {
            if(dragging){
                triggered()
            }	
        }
        
        onTriggered: panel.indicators.openAsInverted()

        Rectangle {
            // Visualize
            visible: false
            color: "blue"
            anchors.fill: parent
        }
    }
    SwipeArea {
        id: appMenuBottomSwipe
        
        // draggingCustom is used for implementing trigger delay
        property bool draggingCustom: distance >= units.gu(4) 
        
        signal triggered
        enabled: !shell.immersiveMode && panel.applicationMenus.available && panel.applicationMenus.model
        direction: SwipeArea.Upwards
        height: units.gu(5)
        width: units.gu(6)
        z: panel.applicationMenus.fullyOpened ? overlay.z - 1 : overlay.z + 1
        anchors {
            left: parent.left
            leftMargin: -(width / 2)
            bottom: parent.bottom
            bottomMargin: -(height / 2)
        }
        immediateRecognition: true
        transform: Rotation { origin.x: appMenuBottomSwipe.width / 2; origin.y: appMenuBottomSwipe.height / 2; angle: 80}
        
        onDraggingCustomChanged: {
            if(dragging){
                triggered()
            }	
        }
        
        onTriggered: panel.applicationMenus.openAsInverted()

        Rectangle {
            // Visualize
            visible: false
            color: "blue"
            anchors.fill: parent
        }
    }
    // ENH028 - End

    InputMethod {
        id: inputMethod
        objectName: "inputMethod"
        anchors {
            fill: parent
            topMargin: panel.panelHeight
            // ENH002 - Notch/Punch hole fix
            // leftMargin: (launcher.lockedByUser && launcher.lockAllowed) ? launcher.panelWidth : 0
            // ENH014 - Always hide launcher in lock screen
            //-leftMargin: ((launcher.lockedByUser && launcher.lockAllowed) ? launcher.panelWidth : 0) + shell.shellLeftMargin
            //leftMargin: (launcher.lockedVisible && greeter.shown ? launcher.panelWidth : 0) + shell.shellLeftMargin
            leftMargin: (launcher.lockedByUser && launcher.lockAllowed && launcher.shown ? launcher.panelWidth : 0) + shell.shellLeftMargin
            // ENH014 - End
			rightMargin: shell.shellRightMargin
			bottomMargin: shell.shellBottomMargin
			// ENH002 - End
        }
        z: notifications.useModal || panel.indicators.shown || wizard.active || tutorial.running || launcher.drawerShown ? overlay.z + 1 : overlay.z - 1
    }

    Loader {
        id: greeterLoader
        objectName: "greeterLoader"
        anchors.fill: parent
        // ENH002 - Notch/Punch hole fix
        anchors.topMargin: deviceConfiguration.fullyHideNotchInPortrait ? shell.shellTopMargin : 0
		anchors.leftMargin: shell.shellLeftMargin
		anchors.rightMargin: shell.shellRightMargin
		anchors.bottomMargin: shell.shellBottomMargin
		// ENH002 - End
        sourceComponent: shell.mode != "shell" ? integratedGreeter :
            Qt.createComponent(Qt.resolvedUrl("Greeter/ShimGreeter.qml"));
        onLoaded: {
            item.objectName = "greeter"
        }
        property bool toggleDrawerAfterUnlock: false
        Connections {
            target: greeter
            onActiveChanged: {
                if (greeter.active)
                    return

                // Show drawer in case showHome() requests it
                if (greeterLoader.toggleDrawerAfterUnlock) {
                    launcher.toggleDrawer(false);
                    greeterLoader.toggleDrawerAfterUnlock = false;
                } else {
                    launcher.hide();
                }
            }
        }
    }

    Component {
        id: integratedGreeter
        Greeter {

            enabled: panel.indicators.fullyClosed // hides OSK when panel is open
            hides: [launcher, panel.indicators, panel.applicationMenus]
            tabletMode: shell.usageScenario != "phone"
            usageMode: shell.usageScenario
            orientation: shell.orientation
            forcedUnlock: wizard.active || shell.mode === "full-shell"
            background: wallpaperResolver.background
            backgroundSourceSize: shell.largestScreenDimension
            hasCustomBackground: wallpaperResolver.hasCustomBackground
            inputMethodRect: inputMethod.visibleRect
            hasKeyboard: shell.hasKeyboard
            allowFingerprint: !dialogs.hasActiveDialog &&
                              !notifications.topmostIsFullscreen &&
                              !panel.indicators.shown
            panelHeight: panel.panelHeight

            // avoid overlapping with Launcher's edge drag area
            // FIXME: Fix TouchRegistry & friends and remove this workaround
            //        Issue involves launcher's DDA getting disabled on a long
            //        left-edge drag
            dragHandleLeftMargin: launcher.available ? launcher.dragAreaWidth + 1 : 0

            onTease: {
                if (!tutorial.running) {
                    launcher.tease();
                }
            }

            onEmergencyCall: startLockedApp("dialer-app")
        }
    }

    Timer {
        // See powerConnection for why this is useful
        id: showGreeterDelayed
        interval: 1
        onTriggered: {
            // Go through the dbus service, because it has checks for whether
            // we are even allowed to lock or not.
            DBusUnitySessionService.PromptLock();
        }
    }

    Connections {
        id: callConnection
        target: callManager

        onHasCallsChanged: {
            if (greeter.locked && callManager.hasCalls && greeter.lockedApp !== "dialer-app") {
                // We just received an incoming call while locked.  The
                // indicator will have already launched dialer-app for us, but
                // there is a race between "hasCalls" changing and the dialer
                // starting up.  So in case we lose that race, we'll start/
                // focus the dialer ourselves here too.  Even if the indicator
                // didn't launch the dialer for some reason (or maybe a call
                // started via some other means), if an active call is
                // happening, we want to be in the dialer.
                startLockedApp("dialer-app")
            }
        }
    }

    Connections {
        id: powerConnection
        target: Powerd

        onStatusChanged: {
            if (Powerd.status === Powerd.Off && reason !== Powerd.Proximity &&
                    !callManager.hasCalls && !wizard.active) {
                // We don't want to simply call greeter.showNow() here, because
                // that will take too long.  Qt will delay button event
                // handling until the greeter is done loading and may think the
                // user held down the power button the whole time, leading to a
                // power dialog being shown.  Instead, delay showing the
                // greeter until we've finished handling the event.  We could
                // make the greeter load asynchronously instead, but that
                // introduces a whole host of timing issues, especially with
                // its animations.  So this is simpler.
                showGreeterDelayed.start();
            }
        }
    }

    function showHome() {
        greeter.notifyUserRequestedApp();

        if (shell.mode === "greeter") {
            SessionBroadcast.requestHomeShown(AccountsService.user);
        } else {
            if (!greeter.active) {
                launcher.toggleDrawer(false);
            } else {
                greeterLoader.toggleDrawerAfterUnlock = true;
            }
        }
    }

    Item {
        id: overlay
        z: 10

        anchors.fill: parent
        // ENH002 - Notch/Punch hole fix
        anchors.topMargin: deviceConfiguration.fullyHideNotchInPortrait ? shell.shellTopMargin : 0
        anchors.leftMargin: shell.shellLeftMargin
		anchors.rightMargin: shell.shellRightMargin
		anchors.bottomMargin: shell.shellBottomMargin
        
        Rectangle {
            // Black out top part when in fullscreen
            visible: panel.fullscreenMode && shell.shellTopMargin > 0
            color: "black"
            anchors {
                topMargin: -parent.anchors.topMargin
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: shell.shellTopMargin
        }
		// ENH002 - End

        Panel {
            id: panel
            objectName: "panel"
            anchors.fill: parent //because this draws indicator menus

            mode: shell.usageScenario == "desktop" ? "windowed" : "staged"
            // ENH002 - Notch/Punch hole fix
            /* Height of the panel bar */
            // minimizedPanelHeight: units.gu(3)
            // expandedPanelHeight: units.gu(7)
            minimizedPanelHeight: shell.isBuiltInScreen && deviceConfiguration.withNotch && shell.orientation == 1 && ! deviceConfiguration.fullyHideNotchInPortrait
                                        ? shell.shellMargin : units.gu(3)
            expandedPanelHeight: shell.isBuiltInScreen && deviceConfiguration.withNotch && shell.orientation == 1 && ! deviceConfiguration.fullyHideNotchInPortrait
                                        ? shell.shellMargin * 1.5 : units.gu(7)
            // ENH002 - End
            applicationMenuContentX: launcher.lockedVisible ? launcher.panelWidth : 0
            // ENH030 - Blurred indicator panel
            blurSource: greeter.shown ? greeter : stages
            interactiveBlur: shell.interactiveBlur
            leftMarginBlur: overlay.anchors.leftMargin
            topMarginBlur: overlay.anchors.topMargin
            // ENH030 - End

            indicators {
                hides: [launcher]
                available: tutorial.panelEnabled
                        && ((!greeter || !greeter.locked) || AccountsService.enableIndicatorsWhileLocked)
                        && (!greeter || !greeter.hasLockedApp)
                        && !shell.waitingOnGreeter
                        && settings.enableIndicatorMenu

                model: Indicators.IndicatorsModel {
                    id: indicatorsModel
                    // tablet and phone both use the same profile
                    // FIXME: use just "phone" for greeter too, but first fix
                    // greeter app launching to either load the app inside the
                    // greeter or tell the session to load the app.  This will
                    // involve taking the url-dispatcher dbus name and using
                    // SessionBroadcast to tell the session.
                    profile: shell.mode === "greeter" ? "desktop_greeter" : "phone"
                    Component.onCompleted: {
                        load();
                    }
                }
            }

            applicationMenus {
                hides: [launcher]
                available: (!greeter || !greeter.shown)
                        && !shell.waitingOnGreeter
                        && !stage.spreadShown
            }

            readonly property bool focusedSurfaceIsFullscreen: topLevelSurfaceList.focusedWindow
                ? topLevelSurfaceList.focusedWindow.state == Mir.FullscreenState
                : false
            fullscreenMode: (focusedSurfaceIsFullscreen && !LightDMService.greeter.active && launcher.progress == 0 && !stage.spreadShown)
                            || greeter.hasLockedApp
            greeterShown: greeter && greeter.shown
            hasKeyboard: shell.hasKeyboard
            supportsMultiColorLed: shell.supportsMultiColorLed
        }

        Launcher {
            id: launcher
            objectName: "launcher"

            anchors.top: parent.top
            anchors.topMargin: inverted ? 0 : panel.panelHeight
            anchors.bottom: parent.bottom
            width: parent.width
            dragAreaWidth: shell.edgeSize
            available: tutorial.launcherEnabled
                    && (!greeter.locked || AccountsService.enableLauncherWhileLocked)
                    && !greeter.hasLockedApp
                    && !shell.waitingOnGreeter
            inverted: shell.usageScenario !== "desktop"
            superPressed: physicalKeysMapper.superPressed
            superTabPressed: physicalKeysMapper.superTabPressed
            panelWidth: units.gu(settings.launcherWidth)
            // ENH014 - Always hide launcher in lock screen
            // lockedVisible: (lockedByUser || shell.atDesktop) && lockAllowed
            lockedVisible: ((lockedByUser && !greeter.locked) || shell.atDesktop) && lockAllowed
            // ENH014 - End
            blurSource: greeter.shown ? greeter : stages
            interactiveBlur: shell.interactiveBlur
            // ENH031 - Blur behavior in Drawer
            leftMarginBlur: overlay.anchors.leftMargin
            topMarginBlur: overlay.anchors.topMargin
            // ENH031 - End
            topPanelHeight: panel.panelHeight
            drawerEnabled: !greeter.active && tutorial.launcherLongSwipeEnabled
            privateMode: greeter.active
            background: wallpaperResolver.background
            backgroundSourceSize: shell.largestScreenDimension

            // It can be assumed that the Launcher and Panel would overlap if
            // the Panel is open and taking up the full width of the shell
            readonly property bool collidingWithPanel: panel && (!panel.fullyClosed && !panel.partialWidth)

            // The "autohideLauncher" setting is only valid in desktop mode
            readonly property bool lockedByUser: (shell.usageScenario == "desktop" && !settings.autohideLauncher)

            // The Launcher should absolutely not be locked visible under some
            // conditions
            readonly property bool lockAllowed: !collidingWithPanel && !panel.fullscreenMode && !wizard.active && !tutorial.demonstrateLauncher

            onShowDashHome: showHome()
            onLauncherApplicationSelected: {
                greeter.notifyUserRequestedApp();
                shell.activateApplication(appId);
            }
            onShownChanged: {
                if (shown) {
                    panel.indicators.hide();
                    panel.applicationMenus.hide();
                }
            }
            onDrawerShownChanged: {
                if (drawerShown) {
                    panel.indicators.hide();
                    panel.applicationMenus.hide();
                }
            }
            onFocusChanged: {
                if (!focus) {
                    stage.focus = true;
                }
            }

            GlobalShortcut {
                shortcut: Qt.MetaModifier | Qt.Key_A
                onTriggered: {
                    launcher.toggleDrawer(true);
                }
            }
            GlobalShortcut {
                shortcut: Qt.AltModifier | Qt.Key_F1
                onTriggered: {
                    launcher.openForKeyboardNavigation();
                }
            }
            GlobalShortcut {
                shortcut: Qt.MetaModifier | Qt.Key_0
                onTriggered: {
                    if (LauncherModel.get(9)) {
                        activateApplication(LauncherModel.get(9).appId);
                    }
                }
            }
            Repeater {
                model: 9
                GlobalShortcut {
                    shortcut: Qt.MetaModifier | (Qt.Key_1 + index)
                    onTriggered: {
                        if (LauncherModel.get(index)) {
                            activateApplication(LauncherModel.get(index).appId);
                        }
                    }
                }
            }
        }

        KeyboardShortcutsOverlay {
            objectName: "shortcutsOverlay"
            enabled: launcher.shortcutHintsShown && width < parent.width - (launcher.lockedVisible ? launcher.panelWidth : 0) - padding
                     && height < parent.height - padding - panel.panelHeight
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: launcher.lockedVisible ? launcher.panelWidth/2 : 0
            anchors.verticalCenterOffset: panel.panelHeight/2
            visible: opacity > 0
            opacity: enabled ? 0.95 : 0

            Behavior on opacity {
                UbuntuNumberAnimation {}
            }
        }

        Tutorial {
            id: tutorial
            objectName: "tutorial"
            anchors.fill: parent

            paused: callManager.hasCalls || !greeter || greeter.active || wizard.active
                    || !hasTouchscreen // TODO #1661557 something better for no touchscreen
            delayed: dialogs.hasActiveDialog || notifications.hasNotification ||
                     inputMethod.visible ||
                     (launcher.shown && !launcher.lockedVisible) ||
                     panel.indicators.shown || stage.rightEdgeDragProgress > 0
            usageScenario: shell.usageScenario
            lastInputTimestamp: inputFilter.lastInputTimestamp
            launcher: launcher
            panel: panel
            stage: stage
        }

        Wizard {
            id: wizard
            objectName: "wizard"
            anchors.fill: parent
            deferred: shell.mode === "greeter"

            function unlockWhenDoneWithWizard() {
                if (!active) {
                    Connectivity.unlockAllModems();
                }
            }

            Component.onCompleted: unlockWhenDoneWithWizard()
            onActiveChanged: unlockWhenDoneWithWizard()
        }

        MouseArea { // modal notifications prevent interacting with other contents
            anchors.fill: parent
            visible: notifications.useModal
            enabled: visible
        }

        Notifications {
            id: notifications

            model: NotificationBackend.Model
            margin: units.gu(1)
            hasMouse: shell.hasMouse
            background: wallpaperResolver.background

            y: topmostIsFullscreen ? 0 : panel.panelHeight
            height: parent.height - (topmostIsFullscreen ? 0 : panel.panelHeight)

            states: [
                State {
                    name: "narrow"
                    when: overlay.width <= units.gu(60)
                    AnchorChanges {
                        target: notifications
                        anchors.left: parent.left
                        anchors.right: parent.right
                    }
                },
                State {
                    name: "wide"
                    when: overlay.width > units.gu(60)
                    AnchorChanges {
                        target: notifications
                        anchors.left: undefined
                        anchors.right: parent.right
                    }
                    PropertyChanges { target: notifications; width: units.gu(38) }
                }
            ]
        }

        EdgeBarrier {
            id: rightEdgeBarrier
            enabled: !greeter.shown

            // NB: it does its own positioning according to the specified edge
            edge: Qt.RightEdge

            onPassed: {
                panel.indicators.hide()
            }

            material: Component {
                Item {
                    Rectangle {
                        width: parent.height
                        height: parent.width
                        rotation: 90
                        anchors.centerIn: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0.16,0.16,0.16,0.5)}
                            GradientStop { position: 1.0; color: Qt.rgba(0.16,0.16,0.16,0)}
                        }
                    }
                }
            }
        }
    }

    Dialogs {
        id: dialogs
        objectName: "dialogs"
        anchors.fill: parent
        visible: hasActiveDialog
        z: overlay.z + 10
        usageScenario: shell.usageScenario
        hasKeyboard: shell.hasKeyboard
        onPowerOffClicked: {
            shutdownFadeOutRectangle.enabled = true;
            shutdownFadeOutRectangle.visible = true;
            shutdownFadeOut.start();
        }
    }

    Connections {
        target: SessionBroadcast
        onShowHome: if (shell.mode !== "greeter") showHome()
    }

    URLDispatcher {
        id: urlDispatcher
        objectName: "urlDispatcher"
        active: shell.mode === "greeter"
        onUrlRequested: shell.activateURL(url)
    }

    ItemGrabber {
        id: itemGrabber
        anchors.fill: parent
        z: dialogs.z + 10
        GlobalShortcut { shortcut: Qt.Key_Print; onTriggered: itemGrabber.capture(shell) }
        Connections {
            target: stage
            ignoreUnknownSignals: true
            onItemSnapshotRequested: itemGrabber.capture(item)
        }
    }

    Timer {
        id: cursorHidingTimer
        interval: 3000
        running: panel.focusedSurfaceIsFullscreen && cursor.opacity > 0
        onTriggered: cursor.opacity = 0;
    }

    Cursor {
        id: cursor
        objectName: "cursor"
        visible: shell.hasMouse
        z: itemGrabber.z + 1
        topBoundaryOffset: panel.panelHeight

        confiningItem: stage.itemConfiningMouseCursor

        property bool mouseNeverMoved: true
        Binding {
            target: cursor; property: "x"; value: shell.width / 2
            when: cursor.mouseNeverMoved && cursor.visible
        }
        Binding {
            target: cursor; property: "y"; value: shell.height / 2
            when: cursor.mouseNeverMoved && cursor.visible
        }

        height: units.gu(3)

        readonly property var previewRectangle: stage.previewRectangle.target &&
                                                stage.previewRectangle.target.dragging ?
                                                stage.previewRectangle : null

        onPushedLeftBoundary: {
            if (buttons === Qt.NoButton) {
                launcher.pushEdge(amount);
            } else if (buttons === Qt.LeftButton && previewRectangle && previewRectangle.target.canBeMaximizedLeftRight) {
                previewRectangle.maximizeLeft(amount);
            }
        }

        onPushedRightBoundary: {
            if (buttons === Qt.NoButton) {
                rightEdgeBarrier.push(amount);
            } else if (buttons === Qt.LeftButton && previewRectangle && previewRectangle.target.canBeMaximizedLeftRight) {
                previewRectangle.maximizeRight(amount);
            }
        }

        onPushedTopBoundary: {
            if (buttons === Qt.LeftButton && previewRectangle && previewRectangle.target.canBeMaximized) {
                previewRectangle.maximize(amount);
            }
        }
        onPushedTopLeftCorner: {
            if (buttons === Qt.LeftButton && previewRectangle && previewRectangle.target.canBeCornerMaximized) {
                previewRectangle.maximizeTopLeft(amount);
            }
        }
        onPushedTopRightCorner: {
            if (buttons === Qt.LeftButton && previewRectangle && previewRectangle.target.canBeCornerMaximized) {
                previewRectangle.maximizeTopRight(amount);
            }
        }
        onPushedBottomLeftCorner: {
            if (buttons === Qt.LeftButton && previewRectangle && previewRectangle.target.canBeCornerMaximized) {
                previewRectangle.maximizeBottomLeft(amount);
            }
        }
        onPushedBottomRightCorner: {
            if (buttons === Qt.LeftButton && previewRectangle && previewRectangle.target.canBeCornerMaximized) {
                previewRectangle.maximizeBottomRight(amount);
            }
        }
        onPushStopped: {
            if (previewRectangle) {
                previewRectangle.stop();
            }
        }

        onMouseMoved: {
            mouseNeverMoved = false;
            cursor.opacity = 1;
        }

        Behavior on opacity { UbuntuNumberAnimation {} }
    }

    // non-visual objects
    KeymapSwitcher {
        focusedSurface: topLevelSurfaceList.focusedWindow ? topLevelSurfaceList.focusedWindow.surface : null
    }
    BrightnessControl {}

    Rectangle {
        id: shutdownFadeOutRectangle
        z: cursor.z + 1
        enabled: false
        visible: false
        color: "black"
        anchors.fill: parent
        opacity: 0.0
        NumberAnimation on opacity {
            id: shutdownFadeOut
            from: 0.0
            to: 1.0
            onStopped: {
                if (shutdownFadeOutRectangle.enabled && shutdownFadeOutRectangle.visible) {
                    DBusUnitySessionService.shutdown();
                }
            }
        }
    }
}
