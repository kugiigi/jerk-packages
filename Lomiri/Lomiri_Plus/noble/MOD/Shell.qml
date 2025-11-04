/*
 * Copyright (C) 2013-2016 Canonical Ltd.
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

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Window 2.2
import AccountsService 0.1
import QtMir.Application 0.1
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Gestures 0.1
import Lomiri.Telephony 0.1 as Telephony
import Lomiri.ModemConnectivity 0.1
import Lomiri.Launcher 0.1
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
import "Components/PanelState"
import Lomiri.Notifications 1.0 as NotificationBackend
import Lomiri.Session 0.1
import Lomiri.Indicators 0.1 as Indicators
import Cursor 1.1
import WindowManager 1.0
// ENH046 - Lomiri Plus Settings
import Qt.labs.settings 1.0
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Suru 2.2
import Lomiri.Components.Pickers 1.3
// ENH046 - End
// ENH067 - Custom Lockscreen Clock Color
import "LPColorpicker"
// ENH067 - End
// ENH064 - Dynamic Cove
import MediaScanner 0.1
import QtMultimedia 5.6
// ENH064 - End
// ENH056 - Quick toggles
import QtSystemInfo 5.0
// ENH056 - End
// ENH116 - Standalone Dark mode toggle
import Lomiri.Indicators 0.1 as Indicators
import Qt.labs.platform 1.0 as LabsPlatform
// ENH116 - End
// ENH150 - Sensor gestures
import QtSensors 5.12
// ENH150 - End

StyledItem {
    id: shell

    // ENH133 - Hot corners
    enum HotCorner {
        Drawer
        , SearchDrawer
        , ToggleDesktop
        , Indicator
        , ToggleSpread
        , PreviousApp
        , OpenDirectActions
    }
    readonly property alias directActions: directActionsLoader.item
    // ENH133 - End

    // ENH150 - Sensor gestures
    enum SensorGestures {
        None
        , ToggleMediaPlayback
        , PauseMediaPlayback
        , ToggleFlashlight
        , ToggleOrientation
        , LockScreen
        , ShowDesktop
        , ToggleScreen
    }
    // ENH150 - End

    readonly property bool lightMode: settings.lightMode
    theme.name: lightMode ? "Lomiri.Components.Themes.Ambiance" :
                            "Lomiri.Components.Themes.SuruDark"

    // ENH002 - Notch/Punch hole fix
    property alias deviceConfiguration: deviceConfiguration
    // ENH036 - Use punchole as battery indicator
    //property real shellMargin: shell.isBuiltInScreen ? deviceConfiguration.notchHeightMargin : 0
    property real shellMargin: shell.isBuiltInScreen && shell.deviceConfiguration.withNotch
                            ? deviceConfiguration.notchHeightMargin + (orientation == 1 && panel.batteryCircleEnabled ? panel.batteryCircleBorder : 0)
                                : 0
    readonly property bool isRightNotch: deviceConfiguration.notchPosition == "right"
    readonly property bool isMiddleNotch: deviceConfiguration.notchPosition == "middle"
    readonly property bool isLeftNotch: deviceConfiguration.notchPosition == "left"
    // ENH036 - End
    property real shellLeftMargin: orientation == 8 ? shellMargin : 0
    property real shellRightMargin: orientation == 2 ? shellMargin : 0
    property real shellBottomMargin: orientation == 4 ? shellMargin : 0
    property real shellTopMargin: orientation == 1 ? shellMargin : 0
    
    readonly property bool isBuiltInScreen: Screen.name == Qt.application.screens[0].name
    // ENH002 - End
    // ENH224 - Brightness control in Virtual Touchpad mode
    readonly property bool hasMultipleDisplays: Screens.count > 1
    readonly property bool inVirtualTouchpadMode: hasMultipleDisplays && shell.settings && shell.settings.externalDisplayBehavior == 0
    readonly property bool shouldBeLowBrightness: shell.settings.lowestBrightnessWhenTouchpadMode && inVirtualTouchpadMode && !ShellNotifier.oskDisplayedInTouchpad
    // ENH224 - End
    // ENH136 - Separate desktop mode per screen
    readonly property bool haveMultipleScreens: Screens.count > 1 && shell.settings && shell.settings.externalDisplayBehavior == 1
    property bool isDesktopMode: false
    readonly property bool isFullScreen: panel.focusedSurfaceIsFullscreen
    // ENH136 - End
    
    // ENH046 - Lomiri Plus Settings
    property alias settings: lp_settings
    property alias lpsettingsLoader: settingsLoader
    readonly property bool settingsShown: settingsLoader.active
    Suru.theme: Suru.Dark
    // ENH046 - End
    // ENH216 - Right Edge gesture for Waydroid
    readonly property bool foregroundAppIsWaydroid: stage.focusedAppId === "Waydroid"
    // ENH216 - End
    // ENH216 - End
    // ENH171 - Add blur to Top Panel and Drawer
    property alias lomiriGSettings: settings
    property alias launcher: launcher
    property alias panel: panel
    // ENH171 - End
    // ENH116 - Standalone Dark mode toggle
    property alias themeSettings: themeSettings
    // ENH116 - End
    // ENH064 - Dynamic Cove
    property alias mediaPlayerIndicator: panel.mediaPlayer
    property alias playbackItemIndicator: panel.playbackItem
    property alias alarmItem: alarm
    property alias alarmItemModel: alarmModel
    property alias mediaPlayerLoaderObj: mediaPlayerLoader
    property alias mediaPlayer: mediaPlayerLoader.item
    // ENH064 - End
    // ENH114 - Popup holder
    property alias popupParent: popupSurface
    // ENH114 - End
    // ENH095 - Middle notch support
    readonly property bool adjustForMiddleNotch: shell.isBuiltInScreen && shell.orientation == 1
                                                    && shell.deviceConfiguration.notchPosition == "middle" && !shell.deviceConfiguration.fullyHideNotchInPortrait
                                                        && shell.deviceConfiguration.notchHeightMargin > 0 && shell.deviceConfiguration.notchWidthMargin > 0
    // ENH095 - End
    // ENH048 - Always hide panel mode
    readonly property bool hideTopPanel: isBuiltInScreen && shell.settings.alwaysHideTopPanel
                                                && (
                                                        (shell.settings.onlyHideTopPanelonLandscape
                                                            && (shell.orientation == Qt.LandscapeOrientation
                                                                    || shell.orientation == Qt.InvertedLandscapeOrientation
                                                                )
                                                        )
                                                        || !shell.settings.onlyHideTopPanelonLandscape
                                                    )
                                                && !isWindowedMode
    // ENH048 - End
    // ENH100 - Camera button to toggle rotation and OSK
    signal toggleRotation
    // ENH100 - End
    // ENH226 - Infographics on the desktop
    property alias stageInfographicsArea: stage.infographicsArea
    readonly property bool isPortrait: orientation === 1 || orientation === 4
    // ENH226 - End
    // ENH102 - App suspension indicator
    readonly property bool focusedAppIsExemptFromLifecycle: focusedAppId ? stage.isExemptFromLifecycle(focusedAppId) : false
    readonly property bool isWindowedMode: stage.mode == "windowed"
    readonly property string focusedAppName: stage.focusedAppName
    readonly property url focusedAppIcon: stage.focusedAppIcon
    readonly property string focusedAppId: stage.focusedAppId
    
    function exemptFromLifecycle(_appId) {
        stage.exemptFromLifecycle(_appId)
    }

    function removeExemptFromLifecycle(_appId) {
        stage.removeExemptFromLifecycle(_appId)
    }
    // ENH102 - End
    // ENH220 - Detox mode
    function msToDay(_value) {
        return _value / 1000 / 60 / 60 / 24
    }

    function msToHours(_value) {
        return (_value / 1000 / 60 / 60)
    }

    function dayToMs(_value) {
        return _value * 24 * 60 * 60 * 1000
    }

    function msToTime(_duration) {
        let _milliseconds = Math.floor((_duration % 1000) / 100)
        let _seconds = Math.floor((_duration / 1000) % 60)
        let _minutes = Math.floor((_duration / (1000 * 60)) % 60)
        let _hours = Math.floor((_duration / (1000 * 60 * 60))) // We let hours to exceed 24 since we don't put days

        let _txtHours = _hours == 0 ? "" : i18n.tr("%1 hour", "%1 hours", _hours).arg(_hours)
        let _txtMinutes = _minutes == 0 ? "" : i18n.tr("%1 minute", "%1 minutes", _minutes).arg(_minutes)
        let _txtSeconds = _seconds == 0 ? "" : i18n.tr("%1 second", "%1 seconds", _seconds).arg(_seconds)

        let _finalText = ""

        if (_txtHours !== "") {
            if (_txtSeconds !== "") {
                _finalText = [_txtHours, _txtMinutes, _txtSeconds].join(" ")
            } else if (_txtMinutes !== "") {
                _finalText = [_txtHours, _txtMinutes].join(" ")
            } else {
                _finalText = _txtHours 
            }
        } else if (_txtMinutes !== "") {
            if (_txtSeconds !== "") {
                _finalText = [_txtMinutes, _txtSeconds].join(" ")
            } else {
                _finalText = _txtMinutes 
            }
        } else if (_txtSeconds !== "") {
            _finalText = _txtSeconds
        } else {
            _finalText = "0 second"
        }

        return _finalText
    }

    function checkDetoxModeEnablement() {
        // Check if 24 hours has passed since Detox mode was enabled
        const _now = new Date().getTime()
        const _diff = _now - shell.settings.detoxModeEnabledEpoch
        if (_diff >= 86400000) { // 24 hours
        //if (_diff >= 60000) { // 1 minute For testing
        //if (_diff >= 200000) { // 1 minute For joke video
            return true
        } else {
            return false
        }
    }

    function showCannotDisableDetoxModeDialog() {
        const _dialog = cannotDisableDetoxModeDialog.createObject(shell.popupParent);
        _dialog.show()
    }

    function showDetoxModeEnableDialog() {
        const _dialog = enableDetoxModeDialog.createObject(shell.popupParent);
        let enableDetoxMode = function () {
            shell.settings.detoxModeEnabled = true
        }
        _dialog.show()
        _dialog.accept.connect(enableDetoxMode)
    }

    Component {
        id: cannotDisableDetoxModeDialog

        Dialog {
            id: cannotDisableDetoxModeDialogue

            readonly property bool isJoke: false

            title: "Detox mode can't be disabled"
            text: isJoke ? "You need to do 20,000 steps to disable Detox mode. Press the button below to start recording your steps 👍"
                        : "You can only disable Detox Mode after 24 hours of enabling it ;)"

             Button {
                 visible: isJoke
                 text: "Let's Walk!"
                 color: theme.palette.normal.positive
                 onClicked: PopupUtils.close(cannotDisableDetoxModeDialogue)
             }
             Button {
                 text: isJoke ? "No!!!!!" : "Okay"
                 onClicked: PopupUtils.close(cannotDisableDetoxModeDialogue)
             }
         }
    }
    Component {
        id: enableDetoxModeDialog

        Dialog {
            id: enableDetoxModeDialogue

            title: "This is a commitment!"
            text: "Detox mode can only be disabled after 24 hours of enabling it. Most settings cannot be changed while it is enabled."

            signal accept

            Label {
                text: "Current settings:"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
            }

            Label {
                text: {
                    if (shell.settings.detoxModeBehavior === 0) {
                        return "Fun page shows every %1".arg(shell.msToTime(shell.settings.detoxModeInterval))
                    } else {
                        return "Fun page shows at random times from %1 to %2".arg(shell.msToTime(shell.settings.detoxModeIntervalStart)).arg(shell.msToTime(shell.settings.detoxModeIntervalEnd))
                    }
                }
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
            }

             Button {
                 text: "Let's Go!"
                 color: theme.palette.normal.positive
                 onClicked: {
                     enableDetoxModeDialogue.accept()
                     PopupUtils.close(enableDetoxModeDialogue)
                 }
             }
             Button {
                 text: "Maybe next time"
                 onClicked: PopupUtils.close(enableDetoxModeDialogue)
             }
         }
    }
    // ENH220 - End

    // to be set from outside
    property int orientationAngle: 0
    property int orientation
    property Orientations orientations
    property real nativeWidth
    property real nativeHeight
    property alias panelAreaShowProgress: panel.panelAreaShowProgress
    property string usageScenario: "phone" // supported values: "phone", "tablet" or "desktop"
    property string mode: "full-greeter"
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
        restoreMode: Binding.RestoreBinding
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

    readonly property var topLevelSurfaceList: {
        if (!WMScreen.currentWorkspace) return null;
        return stage.temporarySelectedWorkspace ? stage.temporarySelectedWorkspace.windowModel : WMScreen.currentWorkspace.windowModel
    }

    onMainAppChanged: {
        _onMainAppChanged((mainApp ? mainApp.appId : ""));
    }
    Connections {
        target: ApplicationManager
        function onFocusRequested(appId) {
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

            if (appId === "lomiri-dialer-app" && callManager.hasCalls && greeter.locked) {
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
        if (atDesktop && stage && !stage.workspaceEnabled) {
            stage.closeSpread();
        }
    }

    property real edgeSize: units.gu(settings.edgeDragWidth)
    // ENH117 - Shell reachability
    property alias osk: inputMethod
    property bool pullDownSettingsShown: false
    // ENH117 - End
    // ENH061 - Add haptics
    readonly property alias haptics: hapticsFeedback
    LPHaptics {
        id: hapticsFeedback
    }
    // ENH061 - End
    // ENH185 - Workspace spread UI fixes
    readonly property bool sideStageShown: stage.sideStageShown
    readonly property real sideStageWidth: stage.sideStageWidth
    // ENH185 - Emd
    // ENH028 - Open indicators via gesture
    readonly property int sessionIndicatorIndex: panel.indicators.lockItem ? panel.indicators.lockItem.parentMenuIndex : 0
    readonly property int powerIndicatorIndex: panel.indicators.brightnessSlider ? panel.indicators.brightnessSlider.parentMenuIndex : 0
    readonly property int soundIndicatorIndex: panel.indicators.silentModeToggle ? panel.indicators.silentModeToggle.parentMenuIndex : 0
    readonly property int networkIndicatorIndex: panel.indicators.wifiToggle ? panel.indicators.wifiToggle.parentMenuIndex : 0
    readonly property int datetimeIndicatorIndex: panel.indicators.dateItem ? panel.indicators.dateItem.parentMenuIndex : 0
    readonly property int rotationToggleIndex: panel.indicators.rotationToggle ? panel.indicators.rotationToggle.parentMenuIndex : 0
    readonly property int locationToggleIndex: panel.indicators.locationToggle ? panel.indicators.locationToggle.parentMenuIndex : 0
    readonly property int bluetoothToggleIndex: panel.indicators.bluetoothToggle ? panel.indicators.bluetoothToggle.parentMenuIndex : 0
    readonly property int darkModeToggleIndex: panel.indicators.autoDarkModeToggle ? panel.indicators.autoDarkModeToggle.parentMenuIndex : 0
    readonly property int displayIndicatorIndex: panel.indicators.rotationToggle ? panel.indicators.rotationToggle.parentMenuIndex : 0
    
    readonly property var indicatorsModel: [
        {"identifier": "ayatana-indicator-session", "name": "System", "icon": "system-devices-panel", "indicatorIndex": sessionIndicatorIndex}
        ,{"identifier": "ayatana-indicator-datetime", "name": "Time and Date", "icon": "preferences-system-time-symbolic", "indicatorIndex": datetimeIndicatorIndex}
        ,{"identifier": "indicator-network", "name": "Network", "icon": "network-wifi-symbolic", "indicatorIndex": networkIndicatorIndex}
        ,{"identifier": "ayatana-indicator-power", "name": "Battery", "icon": "battery-full-symbolic", "indicatorIndex": powerIndicatorIndex}
        ,{"identifier": "ayatana-indicator-sound", "name": "Sound", "icon": "audio-speakers-symbolic", "indicatorIndex": soundIndicatorIndex}
        ,{"identifier": "ayatana-indicator-rotation-lock", "name": "Rotation", "icon": "orientation-lock", "indicatorIndex": rotationToggleIndex}
        ,{"identifier": "indicator-location", "name": "Location", "icon": "location", "indicatorIndex": locationToggleIndex}
        ,{"identifier": "ayatana-indicator-bluetooth", "name": "Bluetooth", "icon": "bluetooth-active", "indicatorIndex": bluetoothToggleIndex}
        ,{"identifier": "kugiigi-indicator-darkmode", "name": "Dark Mode", "icon": "night-mode", "indicatorIndex": darkModeToggleIndex}
        ,{"identifier": "ayatana-indicator-messages", "name": "Notifications", "icon": panel.hasNotifications ? "indicator-messages-new" : "indicator-messages", "indicatorIndex": 0}
        ,{"identifier": "ayatana-indicator-display", "name": "Display", "icon": "video-display-symbolic", "indicatorIndex": displayIndicatorIndex}
    ]
    // ENH028 - End
    // ENH133 - Hot corners
    readonly property var hotcornersIndicatorsModel: {
        return [{ "identifier": "last-opened-indicator", "name": "Last Opened", "icon": "system-devices-panel", "indicatorIndex": -1 }].concat(shell.indicatorsModel)
    }
    // ENH133 - End
    // ENH139 - System Direct Actions
    property bool directActionsSettingsShown: false
    property alias appModel: launcher.appModel

    function getAppData(_appId) {
        for (var i = 0; i < appModel.rowCount(); ++i) {
            let _modelIndex = appModel.index(i, 0)
            let _currentAppId = appModel.data(_modelIndex, 0)

            if (_currentAppId == _appId) {
                let _currentAppName = appModel.data(_modelIndex, 1)
                let _currentAppIcon = appModel.data(_modelIndex, 2)

                return {"name": _currentAppName, "icon": _currentAppIcon, "index": i }
            }
        }
        return null
    }

    readonly property alias quickToggleItems: panel.quickToggleItems
    readonly property var settingsPages: [
        { "identifier": "about", "url": "about", "iconName": "info", "name": "About" }
        , { "identifier": "background", "url": "background", "iconName": "preferences-desktop-wallpaper-symbolic", "name": "Background & Appearance" }
        , { "identifier": "battery", "url": "battery", "iconName": "battery-080", "name": "Battery" }
        , { "identifier": "bluetooth", "url": "bluetooth", "iconName": "bluetooth-active", "name": "Bluetooth" }
        , { "identifier": "brightness", "url": "brightness", "iconName": "display-brightness-symbolic", "name": "Brightness" }
        , { "identifier": "gestures", "url": "gestures", "iconName": "gestures", "name": "Gestures" }
        , { "identifier": "hotspot", "url": "hotspot", "iconName": "preferences-network-hotspot-symbolic", "name": "Hotspot" }
        , { "identifier": "language", "url": "language", "iconName": "preferences-desktop-locale-symbolic", "name": "Language & Text" }
        , { "identifier": "launcher", "url": "launcher", "iconName": "preferences-desktop-launcher-symbolic", "name": "Desktop & Launcher" }
        , { "identifier": "mouse", "url": "mouse", "iconName": "input-mouse-symbolic", "name": "Mouse & Touchpad" }
        , { "identifier": "nfc", "url": "nfc", "iconName": "nfc", "name": "NFC" }
        , { "identifier": "notifications", "url": "notifications", "iconName": "preferences-desktop-notifications-symbolic", "name": "Notifications" }
        , { "identifier": "sound", "url": "sound", "iconName": "preferences-desktop-sounds-symbolic", "name": "Sound" }
        , { "identifier": "time-date", "url": "time-date", "iconName": "preferences-system-time-symbolic", "name": "Time and Date" }
        , { "identifier": "vpn", "url": "vpn", "iconName": "network-vpn", "name": "VPN" }
        , { "identifier": "wifi", "url": "wifi", "iconName": "wifi-high", "name": "Wi-Fi" }
    ]

    function openIndicatorByIndex(_index, _inverted=false) {
        panel.indicators.openAsInverted(_index, _inverted)
    }

    // Custom actions
    readonly property var customDirectActions: [
        lockScreenAction, lomiriPlusAction, powerDialogAction, screenshotAction, rotateAction, appScreenshotAction
        , closeAppAction, showDesktopAction, appSuspensionAction, searchDrawerAction, playPauseAction, goNextAction, goPreviousAction
    ]
    Action {
        id: lockScreenAction
        name: "lockscreen"
        text: "Lock screen"
        iconName: "lock"
        enabled: !shell.showingGreeter
        onTriggered: DBusLomiriSessionService.PromptLock();
    }
    Action {
        id: powerDialogAction
        name: "powerDialog"
        text: "Power Dialog"
        iconName: "system-devices-panel"
        onTriggered: dialogs.showPowerDialog()
    }
    Action {
        id: appScreenshotAction
        enabled: stage.focusedAppId && !shell.showingGreeter ? true : false
        name: "appscreenshot"
        text: "App Screenshot"
        iconName: "stock_application"
        onTriggered: stage.screenShotApp()
    }
    Action {
        id: screenshotAction
        name: "screenshot"
        text: "Screenshot"
        iconName: "camera-app-symbolic"
        onTriggered: delayScreenshot.restart()
    }
    Timer {
        id: delayScreenshot
        interval: 100
        onTriggered: itemGrabber.capture(shell);
    }
    Action {
        id: closeAppAction
        enabled: stage.focusedAppId && !shell.showingGreeter ? true : false
        name: "closeapp"
        text: "Close App"
        iconName: "close"
        onTriggered: stage.closeCurrentApp()
    }
    Action {
        id: appSuspensionAction
        enabled: stage.focusedAppId && !shell.isWindowedMode ? true : false
        name: "appsuspension"
        text: "App Suspension"
        iconName: "system-suspend"
        onTriggered: {
            if (shell.focusedAppIsExemptFromLifecycle) {
                shell.removeExemptFromLifecycle(shell.focusedAppId)
            } else {
                shell.exemptFromLifecycle(shell.focusedAppId)
            }
        }
    }
    Action {
        id: showDesktopAction
        name: "showdesktop"
        text: "Show Desktop"
        iconName: "preferences-desktop-launcher-symbolic"
        onTriggered: stage.showDesktop()
    }
    Action {
        id: rotateAction
        name: "rotate"
        text: "Rotate Screen"
        iconName: "view-rotate"
        onTriggered: toggleRotation()
    }
    Action {
        id: searchDrawerAction
        name: "searchdrawer"
        text: "Search Drawer"
        iconName: "search"
        onTriggered: {
            if (greeter.locked) {
                shell.showHome(true)
            } else {
                launcher.searchInDrawer()
            }
        }
    }
    Action {
        id: playPauseAction
        readonly property bool canPlay: shell.playbackItemIndicator && shell.playbackItemIndicator.canPlay ? true : false
        readonly property bool isPlaying: shell.playbackItemIndicator && shell.playbackItemIndicator.playing ? true : false

        name: "playPause"
        enabled: canPlay
        text: isPlaying ? "Pause" : "Play"
        iconName: isPlaying ? "media-playback-pause" : "media-playback-start"
        onTriggered: {
            if (shell.playbackItemIndicator) {
                shell.playbackItemIndicator.play(!isPlaying)
            }
        }
    }
    Action {
        id: goNextAction
        readonly property bool canGoNext: shell.playbackItemIndicator && shell.playbackItemIndicator.canGoNext ? true : false

        name: "goNext"
        enabled: canGoNext && playPauseAction.canPlay
        text: "Go next"
        iconName: "media-skip-forward"
        onTriggered: {
            if (shell.playbackItemIndicator) {
                shell.playbackItemIndicator.next()
            }
        }
    }
    Action {
        id: goPreviousAction
        readonly property bool canGoPrevious: shell.playbackItemIndicator && shell.playbackItemIndicator.canGoPrevious ? true : false

        name: "goPrevious"
        enabled: canGoPrevious && playPauseAction.canPlay
        text: "Go previous"
        iconName: "media-skip-backward"
        onTriggered: {
            if (shell.playbackItemIndicator) {
                shell.playbackItemIndicator.previous()
            }
        }
    }
    Action {
        id: lomiriPlusAction
        name: "lomiriplus"
        text: "LomiriPlus Settings"
        iconName: "properties"
        enabled: shell.settings.onlyShowLomiriSettingsWhenUnlocked ? !shell.showingGreeter : true
        onTriggered: showSettings()
    }
    // ENH139 - End

    // ENH056 - Quick toggles
    function findFromArray(_arr, _itemProp, _itemValue) {
        return _arr.find(item => item[_itemProp] == _itemValue)
    }

    function countFromArray(_arr, _itemProp, _itemValue) {
        let _counter = 0;
        for (let i = 0; i < _arr.length; i++) {
            if (_arr[i][_itemProp] == _itemValue) {
                _counter++;
            }
        }
        return _counter
    }

    function randomNumber(min, max) {
        return Math.random() * (max - min) + min;
    }

    property bool isScreenActive: false

    ScreenSaver {
        id: screen_saver
        screenSaverEnabled: !shell.isScreenActive
    }
    // ENH056 - End

    // ENH064 - Dynamic Cove
    function getFilename(_filepath) {
        let _returnValue = _filepath.split('\\').pop().split('/').pop();
        return _returnValue.replace(/\.[^/.]+$/, "")
    }
    // ENH064 - End

    // ENH116 - Standalone Dark mode toggle
    Indicators.SharedLomiriMenuModel {
        id: timeModel
        objectName: "timeModel"

        busName: "org.ayatana.indicator.datetime"
        actions: { "indicator": "/org/ayatana/indicator/datetime" }
        menuObjectPath: "/org/ayatana/indicator/datetime/phone"
    }

    Indicators.ModelActionRootState {
        menu: timeModel.model
        onUpdated: {
            if (shell.settings.enableAutoDarkMode && shell.settings.immediateDarkModeSwitch) {
                themeSettings.checkAutoToggle()
            }
        }
    }

    // ENH150 - Sensor gestures
    function triggerSensorGesture(_actionType, _action) {
        switch (_actionType) {
            case Shell.SensorGestures.ToggleMediaPlayback:
                if (shell.playbackItemIndicator) {
                    shell.playbackItemIndicator.play(!shell.playbackItemIndicator.playing)
                    shell.haptics.play()
                }
                break
            case Shell.SensorGestures.PauseMediaPlayback:
                if (shell.playbackItemIndicator && shell.playbackItemIndicator.playing) {
                    shell.playbackItemIndicator.play(!shell.playbackItemIndicator.playing)
                    shell.haptics.play()
                }
                break
            case Shell.SensorGestures.ToggleFlashlight:
                panel.indicators.flashlightToggle.clicked()
                shell.haptics.play()
                break
            case Shell.SensorGestures.ToggleOrientation:
                shell.toggleRotation()
                shell.haptics.play()
                break
            case Shell.SensorGestures.LockScreen:
                lockScreenAction.trigger()
                shell.haptics.play()
                break
            case Shell.SensorGestures.ShowDesktop:
                showDesktopAction.trigger()
                shell.haptics.play()
                break
            case Shell.SensorGestures.ToggleScreen:
                if (Powerd.status === Powerd.Off) {
                    Powerd.setStatus(Powerd.On, Powerd.Notification);
                } else {
                    lockScreenAction.trigger()
                }
                shell.haptics.play()
                break
            default:
                break
        }
    }

    SensorGesture {
        id: sensorGesture
        enabled: shell.settings.enableSensorGestures && (!shell.settings.enableSensorGesturesOnlyWhenScreenOn
                                                            || (shell.settings.enableSensorGesturesOnlyWhenScreenOn && Powerd.status === Powerd.On))
        gestures : shell.settings.enabledSensorGestureList
        onDetected:{
            console.log("Sensor Gesture: " + gesture)
            switch (gesture) {
                case "cover":
                    shell.triggerSensorGesture(shell.settings.coverGestureAction)
                    break
                case "shake":
                    shell.triggerSensorGesture(shell.settings.shakeGestureAction)
                    break
                case "pickup":
                    shell.triggerSensorGesture(shell.settings.pickupGestureAction)
                    break
                case "shakeLeft":
                case "shakeRight":
                case "shakeUp":
                case "shakeDown":
                    shell.triggerSensorGesture(shell.settings.shake2GestureAction)
                    break
                case "slam":
                    shell.triggerSensorGesture(shell.settings.slamGestureAction)
                    break
                case "turnover":
                    shell.triggerSensorGesture(shell.settings.turnoverGestureAction)
                    break
                case "twistLeft":
                case "twistRight":
                    shell.triggerSensorGesture(shell.settings.twistGestureAction)
                    break
                case "whip":
                    shell.triggerSensorGesture(shell.settings.whipGestureAction)
                    break
            }
        }
    }
    // ENH150 - End
    // ENH190 - Keypad backlight settings
    function enableKeypadBacklight() {
        if (!shell.settings.enableKeyboardBacklight) {
            shell.settings.enableKeyboardBacklight = true
        }
    }
    function disableKeypadBacklight() {
        if (shell.settings.enableKeyboardBacklight) {
            shell.settings.enableKeyboardBacklight = false
        }
    }
    AmbientLightSensor {
        id: ambientLightSensor
        active: Powerd.status === Powerd.On && shell.settings.keyboardBacklightAutoBehavior === 2
        dataRate: 20
        onReadingChanged: {
            switch (reading.lightLevel) {
                case AmbientLightReading.Dark:
                    shell.enableKeypadBacklight()
                    break
                case AmbientLightReading.Twilight:
                case AmbientLightReading.Light:
                case AmbientLightReading.Bright:
                case AmbientLightReading.Sunny:
                default:
                    shell.disableKeypadBacklight()
                    break
            }
        }
    }
    // ENH190 - End
    // ENH208 - Pause media on bluetooth disconnect
    property var volumeSlider: panel.indicators.volumeSlider

    Loader {
        id: autoPauseLoader

        active: shell.settings.pauseMediaOnBluetoothAudioDisconnect
        asynchronous: true
        sourceComponent: LPAutoPauseBluetooth {
            volumeSlider: shell.volumeSlider
            playbackObj: shell.playbackItemIndicator
        }
    }
    // ENH208 - End
    // ENH206 - Custom auto brightness
    property var brightnessSlider: panel.indicators.brightnessSlider
    Loader {
        id: autoBrightnessLoader

        property bool temporaryDisable: false

        active: shell.settings.enableCustomAutoBrightness
                        && !temporaryDisable
                        && (panel.indicators.autoBrightnessToggle && !panel.indicators.autoBrightnessToggle.checked ? true : false)
        asynchronous: true
        sourceComponent: LPAutoBrightness {
            autoBrightnessData: shell.settings.customAutoBrightnessData
            // ENH224 - Brightness control in Virtual Touchpad mode
            override: shell.shouldBeLowBrightness
            overrideValue: shell.settings.brightnessWhenTouchpadMode / 100
            // ENH224 - End
        }
    }
    // ENH206 - End
    // ENH197 - Light sensor
    property real lightSensorValue: -1
    property alias lightSensorObj: lightSensor
    LightSensor {
        id: lightSensor
        active: Powerd.status === Powerd.On
                    && (shell.settings.enableColorOverlaySensor || shell.settings.enableAutoDarkModeSensor
                            || (shell.settings.enablePocketModeSecurity && shell.showingGreeter)
                            || autoBrightnessLoader.active
                            || autoBrightnessLoader.temporaryDisable)
        dataRate: 20
        onActiveChanged: if (!active) shell.lightSensorValue = -1
    }
    Timer {
        running: lightSensor.active
        repeat: true
        interval: 1000
        onTriggered: {
            shell.lightSensorValue = lightSensor.reading.illuminance >= 0 ? lightSensor.reading.illuminance : -1
        }
    }

    onLightSensorValueChanged: {
        if (shell.settings.enableAutoDarkModeSensor
                && (!shell.settings.enableAutoDarkMode
                        || (shell.settings.enableAutoDarkMode && !themeSettings.checkAutoToggle(true)))
            ) {
            autoDarkModeSensorDelayTimer.restart()
        }
    }

    Timer {
        id: autoDarkModeSensorDelayTimer
        interval: shell.settings.autoDarkModeSensorDelay * 1000
        onTriggered: {
            let _shouldDarkMode = lightSensorValue > -1 && lightSensorValue <= shell.settings.autoDarkModeSensorThreshold

            if (_shouldDarkMode) {
                themeSettings.setToDark()
            } else {
                themeSettings.setToAmbiance()
            }
        }
    }
    // ENH197 - End
    // ENH198 - Pocket Mode
    readonly property bool pocketModeDetected: proximitySensor.active && proximitySensor.reading.near && shell.showingGreeter
                                            && !shell.haveMultipleScreens
                                            && (shell.settings.doNotUseLightSensorInPocketMode || (!shell.settings.doNotUseLightSensorInPocketMode && shell.lightSensorValue == 0))
    property bool isPocketMode: false

    onPocketModeDetectedChanged: {
        if (pocketModeDetected) {
            delayPocketMode.restart()
        } else {
            delayPocketModeDisable.restart()
        }
    }

    Timer {
        id: delayPocketMode

        interval: 200

        onTriggered: {
            // Check if it's still detected
            if (pocketModeDetected) {
                isPocketMode = true
            }
        }
    }

    Timer {
        id: delayPocketModeDisable

        interval: 1000

        onTriggered: {
            // Check if it's still detected
            if (!pocketModeDetected) {
                isPocketMode = false
            }
        }
    }

    property alias proximitySensor: proximitySensor
    ProximitySensor {
        id: proximitySensor
        active: Powerd.status === Powerd.On
                    && (
                        (shell.settings.enablePocketModeSecurity && shell.showingGreeter)
                        ||
                        shell.settings.enableCustomAutoBrightness
                    )
    }
    // ENH198 - End
    // ENH196 - Battery stats tracking
    property alias batteryTracking: batteryTrackingLoader.item

    Loader {
        id: batteryTrackingLoader

        active: shell.settings.enableBatteryTracking || shell.settings.enableBatteryGraphIndicator
        asynchronous: true
        sourceComponent: LPBatteryTracking {
            automaticUpdateValues: false
        }
    }
    // ENH196 - End
    // ENH203 - I’m awake
    property alias awakeTracking: awakeTrackingLoader.item

    Loader {
        id: awakeTrackingLoader

        active: shell.settings.enableImAwake
        asynchronous: true
        sourceComponent: LPAwakeTracking {
            alarmPrefix: shell.settings.wakeUpAlarmPrefix
        }
    }
    // ENH203 - End

    Item {
        id: themeSettings
 
        readonly property string defaultPath: LabsPlatform.StandardPaths.writableLocation(LabsPlatform.StandardPaths.ConfigLocation).toString().replace("file://", "")
                                                    + "/lomiri-ui-toolkit/theme.ini"
        readonly property bool isDarkMode: currentTheme == "Lomiri.Components.Themes.SuruDark"
        property string currentTheme: "Lomiri.Components.Themes.Ambiance"

        // ENH190 - Keypad backlight settings
        onIsDarkModeChanged: {
            if (shell.settings.keyboardBacklightAutoBehavior == 1) {
                if (isDarkMode) {
                    shell.enableKeypadBacklight()
                } else {
                    shell.disableKeypadBacklight()
                }
            }
        }
        // ENH190 - End

        function checkAutoToggle(_checkOnly=false) {
            let _rawStartTime = Date.fromLocaleString(Qt.locale(), shell.settings.autoDarkModeStartTime, "hh:mm")
            let _rawEndTime = Date.fromLocaleString(Qt.locale(), shell.settings.autoDarkModeEndTime, "hh:mm")
            let _currentTime = new Date()
            let _startTime = new Date()
            let _endTime = new Date()

            _startTime.setHours(_rawStartTime.getHours())
            _startTime.setMinutes(_rawStartTime.getMinutes())
            _endTime.setHours(_rawEndTime.getHours())
            _endTime.setMinutes(_rawEndTime.getMinutes())

            let _reverseLogic = _startTime > _endTime
                
            if ( (!_reverseLogic && _currentTime >= _startTime && _currentTime <= _endTime)
                    || (
                            _reverseLogic && ((_currentTime >= _startTime && _currentTime >= _endTime) || (_currentTime <= _startTime && _currentTime <= _endTime))
                       )
               ) {
                if (_checkOnly) {
                    return true
                } else {
                    if (!isDarkMode) {
                        setToDark()
                    }
                }
            } else {
                if (_checkOnly) {
                    return false
                } else {
                    if (isDarkMode) {
                        setToAmbiance()
                    }
                }
            }
        }

        function updateCurrentValue() {
            // Refresh data in case it was changed externally
            themeSettingsObj.fileName = ""
            themeSettingsObj.fileName = defaultPath

            currentTheme = themeSettingsObj.value("theme", "Lomiri.Components.Themes.Ambiance")
        }

        function toggleTheme() {
            updateCurrentValue()

            if (isDarkMode) {
                setToAmbiance()
            } else {
                setToDark()
            }
        }

        function setToAmbiance() {
            themeSettingsObj.setValue("theme", "Lomiri.Components.Themes.Ambiance")
            currentTheme = "Lomiri.Components.Themes.Ambiance"
        }

        function setToDark() {
            themeSettingsObj.setValue("theme", "Lomiri.Components.Themes.SuruDark")
            currentTheme = "Lomiri.Components.Themes.SuruDark"
        }

        Settings {
            id: themeSettingsObj

            fileName: themeSettings.defaultPath

            Component.onCompleted: {
                themeSettings.updateCurrentValue()
                if (shell.settings.enableAutoDarkMode) {
                    themeSettings.checkAutoToggle()
                }
            }
        }
    }
    // ENH116 - End

    // ENH046 - Lomiri Plus Settings
    function convertFromInch(value) {
        return (Screen.pixelDensity * 25.4) * value
    }

    function removeItemFromList(arr, value, isColor) {
        var i = 0;
        while (i < arr.length) {
            if ((isColor && Qt.colorEqual(arr[i], value))
                    || (!isColor && arr[i] === value)) {
                arr.splice(i, 1);
            } else {
                ++i;
            }
        }
        return arr;
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

    function indicatorLabel(identifier) {
        switch (identifier) {
            case "ayatana-indicator-messages":
                return "Notifications"
                break
            case "ayatana-indicator-rotation-lock":
                return "Rotation"
                break
            case "kugiigi-indicator-immersive":
                return "Immersive Mode"
                break
            case "ayatana-indicator-keyboard":
                return "Keyboard"
                break
            case "lomiri-indicator-transfer":
                return "Transfer/Files"
                break
            case "lomiri-indicator-location":
                return "Location"
                break
            case "ayatana-indicator-bluetooth":
                return "Bluetooth"
                break
            case "indicator-network":
                return "Network"
                break
            case "ayatana-indicator-sound":
                return "Sound"
                break
            case "ayatana-indicator-power":
                return "Battery"
                break
            case "ayatana-indicator-datetime":
                return "Time and Date"
                break
            case "kugiigi-indicator-darkmode":
                return "Dark Mode"
                break
            case "ayatana-indicator-session":
                return "System"
                break
            case "ayatana-indicator-display":
                return "Display"
                break
        }

        return identifier
    }
    Item {
        id: lp_settings

        // General
        property alias enableHaptics: settingsObj.enableHaptics
        property alias enableSlimVolume: settingsObj.enableSlimVolume
        property alias enableSideStage: settingsObj.enableSideStage
        property alias orientationPrompt: settingsObj.orientationPrompt
        property alias savedPalettes: settingsObj.savedPalettes
        property alias enableOSKToggleKeyboardShortcut: settingsObj.enableOSKToggleKeyboardShortcut
        property alias disableLeftEdgeMousePush: settingsObj.disableLeftEdgeMousePush
        property alias disableRightEdgeMousePush: settingsObj.disableRightEdgeMousePush
        property alias lessSensitiveEdgeBarriers: settingsObj.lessSensitiveEdgeBarriers
        property alias externalDisplayBehavior: settingsObj.externalDisplayBehavior
        property alias enablePullDownGesture: settingsObj.enablePullDownGesture
        property alias pullDownHeight: settingsObj.pullDownHeight
        property alias pullDownAreaPosition: settingsObj.pullDownAreaPosition
        property alias pullDownAreaCustomHeight: settingsObj.pullDownAreaCustomHeight
        property alias enableColorOverlay: settingsObj.enableColorOverlay
        property alias overlayColor: settingsObj.overlayColor
        property alias colorOverlayOpacity: settingsObj.colorOverlayOpacity
        property alias enableShowDesktop: settingsObj.enableShowDesktop
        property alias enableCustomBlurRadius: settingsObj.enableCustomBlurRadius
        property alias customBlurRadius: settingsObj.customBlurRadius
        property alias touchVisualColor: settingsObj.touchVisualColor
        property alias enableAdvancedKeyboardSnapping: settingsObj.enableAdvancedKeyboardSnapping
        property alias onlyCommitOnReleaseWhenKeyboardSnapping: settingsObj.onlyCommitOnReleaseWhenKeyboardSnapping
        property alias useWallpaperForBlur: settingsObj.useWallpaperForBlur
        property alias enableDelayedStartingAppSuspension: settingsObj.enableDelayedStartingAppSuspension
        property alias delayedStartingAppSuspensionDuration: settingsObj.delayedStartingAppSuspensionDuration
        property alias enableDelayedAppSuspension: settingsObj.enableDelayedAppSuspension
        property alias delayedAppSuspensionDuration: settingsObj.delayedAppSuspensionDuration
        property alias useTimerForBackgroundBlurInWindowedMode: settingsObj.useTimerForBackgroundBlurInWindowedMode
        property alias delayedWorkspaceSwitcherUI: settingsObj.delayedWorkspaceSwitcherUI
        property alias useCustomWindowSnappingRectangleColor: settingsObj.useCustomWindowSnappingRectangleColor
        property alias customWindowSnappingRectangleColor: settingsObj.customWindowSnappingRectangleColor
        property alias useCustomWindowSnappingRectangleBorderColor: settingsObj.useCustomWindowSnappingRectangleBorderColor
        property alias customWindowSnappingRectangleBorderColor: settingsObj.customWindowSnappingRectangleBorderColor
        property alias replaceHorizontalVerticalSnappingWithBottomTop: settingsObj.replaceHorizontalVerticalSnappingWithBottomTop
        property alias disableKeyboardShortcutsOverlay: settingsObj.disableKeyboardShortcutsOverlay
        property alias enableColorOverlaySensor: settingsObj.enableColorOverlaySensor
        property alias colorOverlaySensorThreshold: settingsObj.colorOverlaySensorThreshold
        property alias enableImAwake: settingsObj.enableImAwake
        property alias listOfDisabledWakeAlarms: settingsObj.listOfDisabledWakeAlarms
        property alias currentDateForAlarms: settingsObj.currentDateForAlarms
        property alias earliestWakeUpAlarm: settingsObj.earliestWakeUpAlarm
        property alias latestWakeUpAlarm: settingsObj.latestWakeUpAlarm
        property alias wakeUpAlarmPrefix: settingsObj.wakeUpAlarmPrefix
        property alias enableCustomAutoBrightness: settingsObj.enableCustomAutoBrightness
        property alias customAutoBrightnessData: settingsObj.customAutoBrightnessData
        property alias pauseMediaOnBluetoothAudioDisconnect: settingsObj.pauseMediaOnBluetoothAudioDisconnect
        property alias showNotificationBubblesAtTheBottom: settingsObj.showNotificationBubblesAtTheBottom
        property alias enableAdvancedScreenshot: settingsObj.enableAdvancedScreenshot
        property alias enableSilentScreenshot: settingsObj.enableSilentScreenshot
        property alias tryToStabilizeAutoBrightness: settingsObj.tryToStabilizeAutoBrightness
        property alias disableVolumeWhenCamera: settingsObj.disableVolumeWhenCamera
        property alias lowestBrightnessWhenTouchpadMode: settingsObj.lowestBrightnessWhenTouchpadMode
        property alias brightnessWhenTouchpadMode: settingsObj.brightnessWhenTouchpadMode
        property alias biggerCursorInExternalDisplay: settingsObj.biggerCursorInExternalDisplay
        property alias biggerCursorInExternalDisplayOnlyAirMouse: settingsObj.biggerCursorInExternalDisplayOnlyAirMouse
        property alias biggerCursorInExternalDisplaySize: settingsObj.biggerCursorInExternalDisplaySize
        property alias showInfographicsOnDesktop: settingsObj.showInfographicsOnDesktop
        property alias darkenWallpaperWhenInfographics: settingsObj.darkenWallpaperWhenInfographics
        property alias darkenWallpaperWhenInfographicsOpacity: settingsObj.darkenWallpaperWhenInfographicsOpacity
        property alias lightModeNotificationBubble: settingsObj.lightModeNotificationBubble

        // Privacy/ & Security
        property alias hideNotificationBodyWhenLocked: settingsObj.hideNotificationBodyWhenLocked
        property alias enablePocketModeSecurity: settingsObj.enablePocketModeSecurity
        property alias doNotUseLightSensorInPocketMode: settingsObj.doNotUseLightSensorInPocketMode
        property alias enableSnatchAlarm: settingsObj.enableSnatchAlarm
        property alias snatchAlarmContactName: settingsObj.snatchAlarmContactName
        property alias disablePowerRebootInLockscreen: settingsObj.disablePowerRebootInLockscreen
        property alias enableFingerprintWhileDisplayOff: settingsObj.enableFingerprintWhileDisplayOff
        property alias enableFingerprintHapticWhenFailed: settingsObj.enableFingerprintHapticWhenFailed
        property alias onlyTurnOnDisplayWhenFingerprintDisplayOff: settingsObj.onlyTurnOnDisplayWhenFingerprintDisplayOff
        property alias failedFingerprintAttemptsWhileDisplayOffWontCount: settingsObj.failedFingerprintAttemptsWhileDisplayOffWontCount
        property alias swipeToUnlockFingerprint: settingsObj.swipeToUnlockFingerprint
        property alias swipeToUnlockEnableAutoLockTimeout: settingsObj.swipeToUnlockEnableAutoLockTimeout
        property alias swipeToUnlockAutoLockTimeout: settingsObj.swipeToUnlockAutoLockTimeout

        // Device Config
        property alias fullyHideNotchInNative: settingsObj.fullyHideNotchInNative
        property alias notchHeightMargin: settingsObj.notchHeightMargin
        property alias notchPosition: settingsObj.notchPosition
        property alias notchWidthMargin: settingsObj.notchWidthMargin
        property alias roundedCornerRadius: settingsObj.roundedCornerRadius
        property alias roundedCornerMargin: settingsObj.roundedCornerMargin
        property alias roundedAppPreview: settingsObj.roundedAppPreview
        property alias batteryCircle: settingsObj.batteryCircle
        property alias punchHoleWidth: settingsObj.punchHoleWidth
        property alias punchHoleHeightFromTop: settingsObj.punchHoleHeightFromTop
        property alias showMiddleNotchHint: settingsObj.showMiddleNotchHint
        property alias balanceMiddleNotchMargin: settingsObj.balanceMiddleNotchMargin

        // Window Decoration
        property alias enableWobblyWindows: settingsObj.enableWobblyWindows
        property alias enlargeWindowButtonsWithOverlay: settingsObj.enlargeWindowButtonsWithOverlay
        property alias enableTitlebarMatchAppTopColor: settingsObj.enableTitlebarMatchAppTopColor
        property alias titlebarMatchAppBehavior: settingsObj.titlebarMatchAppBehavior
        property alias retainRoundedWindowWhileMatching: settingsObj.retainRoundedWindowWhileMatching
        property alias noDecorationWindowedMode: settingsObj.noDecorationWindowedMode

        // Drawer / Launcher
        property alias drawerBlur: settingsObj.drawerBlur
        property alias drawerBlurFullyOpen: settingsObj.drawerBlurFullyOpen
        property alias invertedDrawer: settingsObj.invertedDrawer
        property alias hideDrawerSearch: settingsObj.hideDrawerSearch
        property alias hideBFB: settingsObj.hideBFB
        property alias useLomiriLogo: settingsObj.useLomiriLogo
        property alias useNewLogo: settingsObj.useNewLogo
        property alias useCustomLogo: settingsObj.useCustomLogo
        property alias useCustomBFBColor: settingsObj.useCustomBFBColor
        property alias customLogoScale: settingsObj.customLogoScale
        property alias customLogoColor: settingsObj.customLogoColor
        property alias customBFBColor: settingsObj.customBFBColor
        property alias useCustomeBFBLogoAppearance: settingsObj.useCustomeBFBLogoAppearance
        property alias roundedBFB: settingsObj.roundedBFB
        property alias bigDrawerSearchField: settingsObj.bigDrawerSearchField
        property alias showBottomHintDrawer: settingsObj.showBottomHintDrawer
        property alias enableDrawerBottomSwipe: settingsObj.enableDrawerBottomSwipe
        property alias resetAppDrawerWhenClosed: settingsObj.resetAppDrawerWhenClosed
        property alias enableDirectAppInLauncher: settingsObj.enableDirectAppInLauncher
        property alias fasterFlickDrawer: settingsObj.fasterFlickDrawer
        property alias dimWhenLauncherShow: settingsObj.dimWhenLauncherShow
        property alias drawerIconSizeMultiplier: settingsObj.drawerIconSizeMultiplier
        property alias showLauncherAtDesktop: settingsObj.showLauncherAtDesktop
        property alias enableCustomAppGrid: settingsObj.enableCustomAppGrid
        property alias customAppGrids: settingsObj.customAppGrids
        property alias placeFullAppGridToLast: settingsObj.placeFullAppGridToLast
        property alias customAppGridsExpandable: settingsObj.customAppGridsExpandable
        property alias useCustomLauncherColor: settingsObj.useCustomLauncherColor
        property alias customLauncherColor: settingsObj.customLauncherColor
        property alias useCustomLauncherOpacity: settingsObj.useCustomLauncherOpacity
        property alias customLauncherOpacity: settingsObj.customLauncherOpacity
        property alias useCustomDrawerColor: settingsObj.useCustomDrawerColor
        property alias customDrawerColor: settingsObj.customDrawerColor
        property alias useCustomDrawerOpacity: settingsObj.useCustomDrawerOpacity
        property alias customDrawerOpacity: settingsObj.customDrawerOpacity
        property alias customLauncherOpacityBehavior: settingsObj.customLauncherOpacityBehavior
        property alias enableLauncherBottomMargin: settingsObj.enableLauncherBottomMargin
        property alias enableLauncherBlur: settingsObj.enableLauncherBlur
        property alias hideLauncherWhenNarrow: settingsObj.hideLauncherWhenNarrow
        property alias extendDrawerOverTopBar: settingsObj.extendDrawerOverTopBar
        property alias appGridIndicatorExpandedSize: settingsObj.appGridIndicatorExpandedSize
        property alias appGridIndicatorDoNotExpandWithMouse: settingsObj.appGridIndicatorDoNotExpandWithMouse

        // Drawer Dock
        property alias enableDrawerDock: settingsObj.enableDrawerDock
        property alias drawerDockType: settingsObj.drawerDockType
        property alias drawerDockApps: settingsObj.drawerDockApps
        property alias drawerDockHideLabels: settingsObj.drawerDockHideLabels
        property alias enableMaxHeightInDrawerDock: settingsObj.enableMaxHeightInDrawerDock
        property alias drawerDockMaxHeight: settingsObj.drawerDockMaxHeight

        // Indicators/Top Panel
        property alias indicatorBlur: settingsObj.indicatorBlur
        property alias indicatorGesture: settingsObj.indicatorGesture
        property alias specificIndicatorGesture: settingsObj.specificIndicatorGesture
        property alias directAccessIndicators: settingsObj.directAccessIndicators
        property alias topPanelOpacity: settingsObj.topPanelOpacity
        property alias alwaysHideTopPanel: settingsObj.alwaysHideTopPanel
        property alias onlyHideTopPanelonLandscape: settingsObj.onlyHideTopPanelonLandscape
        property alias alwaysHiddenIndicatorIcons: settingsObj.alwaysHiddenIndicatorIcons
        property alias alwaysShownIndicatorIcons: settingsObj.alwaysShownIndicatorIcons
        property alias alwaysFullWidthTopPanel: settingsObj.alwaysFullWidthTopPanel
        property alias widerLandscapeTopPanel: settingsObj.widerLandscapeTopPanel
        property alias hideBatteryIndicatorBracket: settingsObj.hideBatteryIndicatorBracket
        property alias hideBatteryIndicatorPercentage: settingsObj.hideBatteryIndicatorPercentage
        property alias hideBatteryIndicatorIcon: settingsObj.hideBatteryIndicatorIcon
        property alias twoDigitHourDateTimeIndicator: settingsObj.twoDigitHourDateTimeIndicator
        property alias verticalBatteryIndicatorIcon: settingsObj.verticalBatteryIndicatorIcon
        property alias enableOSKToggleInIndicator: settingsObj.enableOSKToggleInIndicator
        property alias enableLomiriSettingsToggleIndicator: settingsObj.enableLomiriSettingsToggleIndicator
        property alias onlyShowLomiriSettingsWhenUnlocked: settingsObj.onlyShowLomiriSettingsWhenUnlocked
        property alias enableAppSuspensionToggleIndicator: settingsObj.enableAppSuspensionToggleIndicator
        property alias enableActiveScreenToggleIndicator: settingsObj.enableActiveScreenToggleIndicator
        property alias showAppSuspensionIconIndicator: settingsObj.showAppSuspensionIconIndicator
        property alias showActiveScreenIconIndicator: settingsObj.showActiveScreenIconIndicator
        property alias enableImmersiveModeToggleIndicator: settingsObj.enableImmersiveModeToggleIndicator
        property alias showImmersiveModeIconIndicator: settingsObj.showImmersiveModeIconIndicator
        property alias enableDarkModeToggleIndicator: settingsObj.enableDarkModeToggleIndicator
        property alias enableBatteryGraphIndicator: settingsObj.enableBatteryGraphIndicator
        property alias enableAutoDarkMode: settingsObj.enableAutoDarkMode
        property alias enableAutoDarkModeSensor: settingsObj.enableAutoDarkModeSensor
        property alias autoDarkModeSensorThreshold: settingsObj.autoDarkModeSensorThreshold
        property alias autoDarkModeSensorDelay: settingsObj.autoDarkModeSensorDelay
        property alias enableAutoDarkModeToggleIndicator: settingsObj.enableAutoDarkModeToggleIndicator
        property alias immediateDarkModeSwitch: settingsObj.immediateDarkModeSwitch
        property alias autoDarkModeStartTime: settingsObj.autoDarkModeStartTime
        property alias autoDarkModeEndTime: settingsObj.autoDarkModeEndTime
        property alias onlyShowNotificationsIndicatorWhenGreen: settingsObj.onlyShowNotificationsIndicatorWhenGreen
        property alias onlyShowSoundIndicatorWhenSilent: settingsObj.onlyShowSoundIndicatorWhenSilent
        property alias hideTimeIndicatorAlarmIcon: settingsObj.hideTimeIndicatorAlarmIcon
        property alias transparentTopBarOnSpread: settingsObj.transparentTopBarOnSpread
        property alias enablePanelHeaderExpand: settingsObj.enablePanelHeaderExpand
        property alias expandPanelHeaderWhenBottom: settingsObj.expandPanelHeaderWhenBottom
        property alias autoExpandWhenThereAreNotif: settingsObj.autoExpandWhenThereAreNotif
        property alias enableShowTouchVisualsToggleIndicator: settingsObj.enableShowTouchVisualsToggleIndicator
        property alias useCustomPanelColor: settingsObj.useCustomPanelColor
        property alias customPanelColor: settingsObj.customPanelColor
        property alias useCustomIndicatorPanelColor: settingsObj.useCustomIndicatorPanelColor
        property alias customIndicatorPanelColor: settingsObj.customIndicatorPanelColor
        property alias useCustomIndicatorPanelOpacity: settingsObj.useCustomIndicatorPanelOpacity
        property alias customIndicatorPanelOpacity: settingsObj.customIndicatorPanelOpacity
        property alias matchTopPanelToDrawerIndicatorPanels: settingsObj.matchTopPanelToDrawerIndicatorPanels
        property alias enableTopPanelBlur: settingsObj.enableTopPanelBlur
        property alias enableTopPanelMatchAppTopColor: settingsObj.enableTopPanelMatchAppTopColor
        property alias enableTransparentTopBarInGreeter: settingsObj.enableTransparentTopBarInGreeter
        property alias topPanelMatchAppBehavior: settingsObj.topPanelMatchAppBehavior
        property alias enableTopPanelMatchAppTopColorWindowed: settingsObj.enableTopPanelMatchAppTopColorWindowed
        property alias useCustomTopBarIconTextColor: settingsObj.useCustomTopBarIconTextColor
        property alias customTopBarIconTextColor: settingsObj.customTopBarIconTextColor
        property alias enableBluetoothDevicesList: settingsObj.enableBluetoothDevicesList
        property alias recentBlutoothDevicesList: settingsObj.recentBlutoothDevicesList
        property alias useIndicatorSelectorForPanelBarWhenInverted: settingsObj.useIndicatorSelectorForPanelBarWhenInverted

        //Quick Toggles
        property alias enableQuickToggles: settingsObj.enableQuickToggles
        property alias quickToggles: settingsObj.quickToggles
        property alias gestureMediaControls: settingsObj.gestureMediaControls
        property alias autoCollapseQuickToggles: settingsObj.autoCollapseQuickToggles
        property alias quickTogglesCollapsedRowCount: settingsObj.quickTogglesCollapsedRowCount
        property alias disableTogglesOnLockscreen: settingsObj.disableTogglesOnLockscreen
        property alias togglesToDisableOnLockscreen: settingsObj.togglesToDisableOnLockscreen
        property alias quickTogglesOnlyShowInNotifications: settingsObj.quickTogglesOnlyShowInNotifications

        // Quick Actions (Previously Direct Actions)
        property alias enableDirectActions: settingsObj.enableDirectActions
        property alias directActionList: settingsObj.directActionList
        property alias directActionsSwipeAreaHeight: settingsObj.directActionsSwipeAreaHeight
        property alias directActionsMaxWidth: settingsObj.directActionsMaxWidth
        property alias directActionsMaxWidthGU: settingsObj.directActionsMaxWidthGU
        property alias directActionsMaxColumn: settingsObj.directActionsMaxColumn
        property alias directActionsSideMargins: settingsObj.directActionsSideMargins
        property alias directActionsEnableHint: settingsObj.directActionsEnableHint
        property alias directActionsSides: settingsObj.directActionsSides
        property alias directActionsNoSwipeCommit: settingsObj.directActionsNoSwipeCommit
        property alias directActionsCustomURIs: settingsObj.directActionsCustomURIs
        property alias directActionsShortcutHorizontalLayout: settingsObj.directActionsShortcutHorizontalLayout
        property alias directActionsShortcutVerticalLayout: settingsObj.directActionsShortcutVerticalLayout
        property alias directActionsAnimationSpeed: settingsObj.directActionsAnimationSpeed
        property alias directActionsUsePhysicalSizeWhenSwiping: settingsObj.directActionsUsePhysicalSizeWhenSwiping
        property alias directActionsOffsetSelectionWhenSwiping: settingsObj.directActionsOffsetSelectionWhenSwiping
        property alias directActionsDynamicPositionWhenSwiping: settingsObj.directActionsDynamicPositionWhenSwiping
        property alias directActionsSwipeOverOSK: settingsObj.directActionsSwipeOverOSK
        property alias directActionsStyle: settingsObj.directActionsStyle

        // Lockscreen
        property alias useCustomLockscreen: settingsObj.useCustomLockscreen
        property alias useCustomCoverPage: settingsObj.useCustomCoverPage
        property alias hideLockscreenClock: settingsObj.hideLockscreenClock
        property alias useCustomLSClockColor: settingsObj.useCustomLSClockColor
        property alias useCustomLSDateColor: settingsObj.useCustomLSDateColor
        property alias customLSClockColor: settingsObj.customLSClockColor
        property alias customLSDateColor: settingsObj.customLSDateColor
        property alias useCustomLSClockFont: settingsObj.useCustomLSClockFont
        property alias customLSClockFont: settingsObj.customLSClockFont
        property alias useCustomInfographicCircleColor: settingsObj.useCustomInfographicCircleColor
        property alias customInfographicsCircleColor: settingsObj.customInfographicsCircleColor
        property alias useCustomDotsColor: settingsObj.useCustomDotsColor
        property alias customDotsColor: settingsObj.customDotsColor
        property alias useCustomAccountIcon: settingsObj.useCustomAccountIcon
        property alias lockScreenClockStyle: settingsObj.lockScreenClockStyle
        property alias lockScreenClockStyleColor: settingsObj.lockScreenClockStyleColor
        property alias lockScreenDateStyle: settingsObj.lockScreenDateStyle
        property alias lockScreenDateStyleColor: settingsObj.lockScreenDateStyleColor
        
        // Sensor Gestures
        property alias enableSensorGestures: settingsObj.enableSensorGestures
        property alias enableSensorGesturesOnlyWhenScreenOn: settingsObj.enableSensorGesturesOnlyWhenScreenOn
        property alias enableCoverGesture: settingsObj.enableCoverGesture
        property alias coverGestureAction: settingsObj.coverGestureAction
        property alias enableShakeGesture: settingsObj.enableShakeGesture
        property alias shakeGestureAction: settingsObj.shakeGestureAction
        property alias enableShake2Gesture: settingsObj.enableShake2Gesture
        property alias shake2GestureAction: settingsObj.shake2GestureAction
        property alias enablePickupGesture: settingsObj.enablePickupGesture
        property alias pickupGestureAction: settingsObj.pickupGestureAction
        property alias enableSlamGesture: settingsObj.enableSlamGesture
        property alias slamGestureAction: settingsObj.slamGestureAction
        property alias enableTurnoverGesture: settingsObj.enableTurnoverGesture
        property alias turnoverGestureAction: settingsObj.turnoverGestureAction
        property alias enableTwistGesture: settingsObj.enableTwistGesture
        property alias twistGestureAction: settingsObj.twistGestureAction
        property alias enableWhipGesture: settingsObj.enableWhipGesture
        property alias whipGestureAction: settingsObj.whipGestureAction
        property var enabledSensorGestureList: []
        
        function toggleInSensorGestureList(_gesture, _toAdd=true) {
            if (_gesture) {
                sensorGesture.enabled = false
                if (_toAdd) {
                    let _tempArr = enabledSensorGestureList.slice()
                    _tempArr.push(_gesture)
                    enabledSensorGestureList = _tempArr.slice()
                } else {
                    if (enabledSensorGestureList.includes(_gesture)) {
                        let _tempArr = enabledSensorGestureList.slice()
                        _tempArr.splice(_tempArr.indexOf(_gesture), 1)
                        enabledSensorGestureList = _tempArr.slice()
                    }
                }
                sensorGesture.enabled = Qt.binding(function() { return shell.settings.enableSensorGestures && (!shell.settings.enableSensorGesturesOnlyWhenScreenOn
                                                            || (shell.settings.enableSensorGesturesOnlyWhenScreenOn && Powerd.status === Powerd.On)) })
            }
        }

        onEnableCoverGestureChanged: toggleInSensorGestureList("QtSensors.cover", enableCoverGesture)
        onEnableShakeGestureChanged: toggleInSensorGestureList("QtSensors.shake", enableShakeGesture)
        onEnableShake2GestureChanged: toggleInSensorGestureList("QtSensors.shake2", enableShake2Gesture)
        onEnablePickupGestureChanged: toggleInSensorGestureList("QtSensors.pickup", enablePickupGesture)
        onEnableSlamGestureChanged: toggleInSensorGestureList("QtSensors.slam", enableSlamGesture)
        onEnableTurnoverGestureChanged: toggleInSensorGestureList("QtSensors.turnover", enableTurnoverGesture)
        onEnableTwistGestureChanged: toggleInSensorGestureList("QtSensors.twist", enableTwistGesture)
        onEnableWhipGestureChanged: toggleInSensorGestureList("QtSensors.whip", enableWhipGesture)

        // ENH201 - Disable toggles in lockscreen
        Timer {
            id: delayedDisableTogglesTimer
            interval: 2000
            onTriggered: lp_settings.updateTogglesForDisabling()
        }

        function updateTogglesForDisabling() {
            let _settingEnabled = shell.settings.disableTogglesOnLockscreen

            let _arr = shell.quickToggleItems.slice()
            let _length = _arr.length
            let _failed = false // When toggle items are not loaded yet

            for (let i = 0; i < _length; i++) {
                let _item = _arr[i]
                let _identifier = _item.identifier
                let _toggleObj = _item.toggleObj
                if (!_toggleObj) {
                    _failed = true
                    break
                }
                let _foundItem = findFromArray(togglesToDisableOnLockscreen, "identifier", _identifier)
                let _when = _foundItem ? _foundItem.when : -1

                if (_when > -1 && _settingEnabled) {
                    if (_toggleObj && _toggleObj.hasOwnProperty("disableOnLockscreenWhen")) {
                        _toggleObj.disableOnLockscreenWhen = _when
                    }
                } else {
                    if (_toggleObj && _toggleObj.hasOwnProperty("disableOnLockscreenWhen")) {
                        _toggleObj.disableOnLockscreenWhen = -1
                    }
                }
            }

            if (_failed) {
                delayedDisableTogglesTimer.restart()
            }
        }
        onDisableTogglesOnLockscreenChanged: updateTogglesForDisabling()
        onTogglesToDisableOnLockscreenChanged: updateTogglesForDisabling()
        // ENH201 - End

        // Pro1-X
        property alias pro1_OSKOrientation: settingsObj.pro1_OSKOrientation
        property alias pro1_OSKToggleKey: settingsObj.pro1_OSKToggleKey
        property alias pro1_orientationToggleKey: settingsObj.pro1_orientationToggleKey
        property alias enableCameraKeyDoublePress: settingsObj.enableCameraKeyDoublePress
        property alias reversedCameraKeyDoubePress: settingsObj.reversedCameraKeyDoubePress
        property alias cameraKeyDoublePressDelay: settingsObj.cameraKeyDoublePressDelay
        property alias enableKeyboardBacklight: settingsObj.enableKeyboardBacklight
        property alias keyboardBacklightAutoBehavior: settingsObj.keyboardBacklightAutoBehavior

        // Device hacks
        property alias enableBottomSwipeDeviceFix: settingsObj.enableBottomSwipeDeviceFix
        property alias enableSpreadTouchFix: settingsObj.enableSpreadTouchFix

        // Outer Wilds
        property alias ow_ColoredClock: settingsObj.ow_ColoredClock
        property alias ow_GradientColoredTime: settingsObj.ow_GradientColoredTime
        property alias ow_GradientColoredDate: settingsObj.ow_GradientColoredDate
        property alias ow_bfbLogo: settingsObj.ow_bfbLogo
        property alias enableAlternateOW: settingsObj.ow_enableAlternateOW
        property alias ow_theme: settingsObj.ow_theme
        property alias ow_mainMenu: settingsObj.ow_mainMenu
        property alias ow_qmChance: settingsObj.ow_qmChance
        property alias enableEyeFP: settingsObj.lp_enableEyeFP
        property alias ow_showSolarSystemOnDesktop: settingsObj.ow_showSolarSystemOnDesktop
        property alias ow_showSolarSystemOnDesktopRunAllTime: settingsObj.ow_showSolarSystemOnDesktopRunAllTime

        // Dynamic Cove
        property alias enableDynamicCove: settingsObj.enableDynamicCove
        property alias dynamicCoveCurrentItem: settingsObj.dynamicCoveCurrentItem
        property alias dcDigitalClockMode: settingsObj.dcDigitalClockMode
        property alias dcShowClockWhenLockscreen: settingsObj.dcShowClockWhenLockscreen
        property alias enableCDPlayer: settingsObj.enableCDPlayer
        property alias enableCDPlayerDisco: settingsObj.enableCDPlayerDisco
        property alias dynamicCoveSelectionDelay: settingsObj.dynamicCoveSelectionDelay
        property alias dcBlurredAlbumArt: settingsObj.dcBlurredAlbumArt
        property alias dcCDPlayerSimpleMode: settingsObj.dcCDPlayerSimpleMode
        property alias dcCDPlayerOpacity: settingsObj.dcCDPlayerOpacity
        property alias enableAmbientModeInCDPlayer: settingsObj.enableAmbientModeInCDPlayer
        property alias hideCDPlayerWhenScreenOff: settingsObj.hideCDPlayerWhenScreenOff
        property alias hideCirclesWhenCDPlayer: settingsObj.hideCirclesWhenCDPlayer

        // Air Mouse
        property alias enableAirMouse: settingsObj.enableAirMouse
        property alias airMouseAlwaysActive: settingsObj.airMouseAlwaysActive
        property alias airMouseSensitivity: settingsObj.airMouseSensitivity
        property alias invertSideMouseScroll: settingsObj.invertSideMouseScroll
        property alias sideMouseScrollSensitivity: settingsObj.sideMouseScrollSensitivity
        property alias sideMouseScrollPosition: settingsObj.sideMouseScrollPosition
        property alias enableSideMouseScrollHaptics: settingsObj.enableSideMouseScrollHaptics

        // Hot Corners
        property alias enableHotCorners: settingsObj.enableHotCorners
        property alias enableHotCornersVisualFeedback: settingsObj.enableHotCornersVisualFeedback
        property alias enableTopLeftHotCorner: settingsObj.enableTopLeftHotCorner
        property alias enableTopRightHotCorner: settingsObj.enableTopRightHotCorner
        property alias enableBottomRightHotCorner: settingsObj.enableBottomRightHotCorner
        property alias enableBottomLeftHotCorner: settingsObj.enableBottomLeftHotCorner
        property alias actionTypeTopLeftHotCorner: settingsObj.actionTypeTopLeftHotCorner
        property alias actionTypeTopRightHotCorner: settingsObj.actionTypeTopRightHotCorner
        property alias actionTypeBottomRightHotCorner: settingsObj.actionTypeBottomRightHotCorner
        property alias actionTypeBottomLeftHotCorner: settingsObj.actionTypeBottomLeftHotCorner
        property alias actionTopLeftHotCorner: settingsObj.actionTopLeftHotCorner
        property alias actionTopRightHotCorner: settingsObj.actionTopRightHotCorner
        property alias actionBottomRightHotCorner: settingsObj.actionBottomRightHotCorner
        property alias actionBottomLeftHotCorner: settingsObj.actionBottomLeftHotCorner

        // Battery Tracking
        property alias enableBatteryTracking: settingsObj.enableBatteryTracking
        property alias batteryTrackingData: settingsObj.batteryTrackingData
        property alias batteryTrackingDataDuration: settingsObj.batteryTrackingDataDuration
        property alias enableBatteryStatsIndicator: settingsObj.enableBatteryStatsIndicator
        property alias showScreenTimeSinceLastFullCharged: settingsObj.showScreenTimeSinceLastFullCharged
        property alias showScreenTimeSinceLastCharge: settingsObj.showScreenTimeSinceLastCharge
        property alias showScreenTimeToday: settingsObj.showScreenTimeToday
        property alias showScreenTimeYesterday: settingsObj.showScreenTimeYesterday
        property alias screenTimeFullyChargedWorkaround: settingsObj.screenTimeFullyChargedWorkaround
        property alias collapsibleScreenTimeIndicators: settingsObj.collapsibleScreenTimeIndicators
        property alias showHistoryCharts: settingsObj.showHistoryCharts
        property alias onlyIncludePercentageRangeInBatteryChart: settingsObj.onlyIncludePercentageRangeInBatteryChart
        property alias batteryPercentageRangeToInclude: settingsObj.batteryPercentageRangeToInclude
        property alias enableChargingAlarm: settingsObj.enableChargingAlarm
        property alias silentChargingAlarm: settingsObj.silentChargingAlarm
        property alias detectFullyChargedInChargingAlarm: settingsObj.detectFullyChargedInChargingAlarm
        property alias targetPercentageChargingAlarm: settingsObj.targetPercentageChargingAlarm
        property alias alwaysPromptchargingAlarm: settingsObj.alwaysPromptchargingAlarm
        property alias chargingAlarmPromptTimesout: settingsObj.chargingAlarmPromptTimesout
        property alias enableChargingAlarmByDefault: settingsObj.enableChargingAlarmByDefault
        property alias batteryTrackingLastDate: settingsObj.batteryTrackingLastDate
        property alias displayChargingTimeInAlarm: settingsObj.displayChargingTimeInAlarm

        // Waydroid Gesture
        property alias disableRigheEdgeForWaydroid: settingsObj.disableRigheEdgeForWaydroid
        property alias disableRigheEdgeForWaydroidEdge: settingsObj.disableRigheEdgeForWaydroidEdge
        property alias disableRigheEdgeForWaydroidHeight: settingsObj.disableRigheEdgeForWaydroidHeight
        property alias disableLeftEdgeForWaydroid: settingsObj.disableLeftEdgeForWaydroid
        property alias disableLeftEdgeForWaydroidEdge: settingsObj.disableLeftEdgeForWaydroidEdge
        property alias disableLeftEdgeForWaydroidHeight: settingsObj.disableLeftEdgeForWaydroidHeight

        // Stopwatch Data
        property alias dcStopwatchTimeMS: settingsObj.dcStopwatchTimeMS
        property alias dcStopwatchLastEpoch: settingsObj.dcStopwatchLastEpoch

        // Timer Data
        property alias dcRunningTimer: settingsObj.dcRunningTimer
        property alias dcLastTimeTimer: settingsObj.dcLastTimeTimer

        // Others
        property alias enableAppSpreadFlickMod: settingsObj.enableAppSpreadFlickMod
        property alias enableVolumeButtonsLogic: settingsObj.enableVolumeButtonsLogic
        property alias workaroundMaxAppsSwitchWorkspace: settingsObj.workaroundMaxAppsSwitchWorkspace
        
        // Detox Mode
        property alias enableDetoxModeToggleIndicator: settingsObj.enableDetoxModeToggleIndicator
        property alias detoxModeEnabled: settingsObj.detoxModeEnabled
        property alias detoxModeEnabledEpoch: settingsObj.detoxModeEnabledEpoch
        property alias detoxModeAppList: settingsObj.detoxModeAppList
        property alias detoxModeBehavior: settingsObj.detoxModeBehavior
        property alias detoxModeInterval: settingsObj.detoxModeInterval
        property alias detoxModeIntervalStart: settingsObj.detoxModeIntervalStart
        property alias detoxModeIntervalEnd: settingsObj.detoxModeIntervalEnd
        property alias detoxModeType: settingsObj.detoxModeType

        // Extras
        property alias blueScreenNotYetShown: settingsObj.blueScreenNotYetShown
        property alias blueScreenDelay: settingsObj.blueScreenDelay

        // Non-persistent settings
        property bool enableOW: false
        property bool showInfographics: true
        property bool immersiveMode: false
        property bool showTouchVisuals: false

        // For Charging Alarm
        property bool temporaryEnableChargingAlarm: false
        property bool temporaryCustomTargetBatteryPercentage: false
        property int temporaryTargetBatteryPercentage: 80
        property bool forceSilentFullyChargedAlarm: false


        Settings {
            id: settingsObj

            // ENH061 - Add haptics
            // ENH056 - Quick toggles
            //Component.onCompleted: shell.haptics.enabled = Qt.binding( function() { return enableHaptics } )
            Component.onCompleted: {
                shell.haptics.enabled = Qt.binding( function() { return enableHaptics } )

                // Add new Quick Toggles if don't exists yet
                let _newItems = [17, 18, 19, 20]
                for (let i = 0; i < _newItems.length; i++) {
                    let _newItem = _newItems[i]
                    let _foundItem = shell.findFromArray(quickToggles, "type", _newItem)
                    if (!_foundItem) {
                        let _tempArr = settingsObj.quickToggles.slice()
                        _tempArr.push({"type": _newItem, "enabled": false})
                        settingsObj.quickToggles = _tempArr.slice()
                    }
                }
            }
            // ENH056 - End
            // ENH061 - End

            category: "lomiriplus"
            property bool lp_enableEyeFP: false
            property bool useCustomLockscreen: false
            property bool indicatorBlur: false
            property bool drawerBlur: false
            property bool drawerBlurFullyOpen: false
            property bool invertedDrawer: false
            property bool enableSideStage: true
            property bool indicatorGesture: true
            property bool orientationPrompt: true
            property bool useLomiriLogo: true
            property bool useNewLogo: false
            property bool useCustomLogo: false
            property bool useCustomBFBColor: false
            property bool roundedBFB: false
            property int customLogoScale: 60 //percentage
            property string customLogoColor: "#ffffff" // HTML format
            property string customBFBColor: "#006ba6" // HTML format
            property int notchPosition: 0
            /*
             0 - none
             1 - middle
             2 - left
             3 - right
            */
            property bool fullyHideNotchInNative: false
            property real notchHeightMargin: 0
            property real notchWidthMargin: 0
            property real roundedCornerRadius: 0
            property real roundedCornerMargin: 0
            property bool roundedAppPreview: false
            property bool batteryCircle: false
            property real punchHoleWidth: 0
            property real punchHoleHeightFromTop: 0
            property bool alwaysHideTopPanel: false
            property int topPanelOpacity: 100

            // Pro1-X
            property bool pro1_OSKOrientation: false
            property bool pro1_OSKToggleKey: false
            property bool pro1_orientationToggleKey: false
            
            // Outer Wilds Persistent Settings
            property bool ow_ColoredClock: false
            property bool ow_GradientColoredTime: false
            property int ow_bfbLogo: 0
            /*
             0 - Disabled
             1 - Brittle Hollow
             2 - Dark Bramble
             3 - Hourglass Twins
             4 - Interloper
             5 - Nomai Eye
             6 - Quantum Moon
             7 - Stranger Eye
             8 - Sun
             9 - Timberhearth
            */
            property bool ow_enableAlternateOW: false
            property bool ow_mainMenu: false
            property int ow_qmChance: 10

            property bool enableQuickToggles: false
            property var quickToggles: [
                {"type": 14, "enabled": true}
                ,{"type": 7, "enabled": true}
                , {"type": 6, "enabled": true}
                , {"type": 8, "enabled": true}
                , {"type": 2, "enabled": true}
                , {"type": 1, "enabled": true}
                , {"type": 4, "enabled": true}
                , {"type": 0, "enabled": false}
                , {"type": 13, "enabled": false}
                , {"type": 12, "enabled": false}
                , {"type": 17, "enabled": false}
                , {"type": 9, "enabled": false}
                , {"type": 11, "enabled": false}
                , {"type": 5, "enabled": false}
                , {"type": 3, "enabled": false}
                , {"type": 10, "enabled": false}
                , {"type": 18, "enabled": false}
                , {"type": 19, "enabled": false}
                , {"type": 20, "enabled": false}
                , {"type": 15, "enabled": false}
                , {"type": 16, "enabled": false}
            ]

            property bool bigDrawerSearchField: false
            property bool enableCDPlayer: true
            property bool enableCDPlayerDisco: false
            property bool useCustomCoverPage: false
            property bool hideDrawerSearch: false
            property var alwaysHiddenIndicatorIcons: []
            property var alwaysShownIndicatorIcons: []
            property bool enableHaptics: false
            property bool enableSlimVolume: false
            property bool gestureMediaControls: false
            property int dynamicCoveCurrentItem: 0
            property bool enableDynamicCove: false
            property bool dcDigitalClockMode: false
            property bool hideLockscreenClock: false
            property int dcStopwatchTimeMS: 0
            property real dcStopwatchLastEpoch: 0
            property real dcRunningTimer: 0
            property int dcLastTimeTimer: 0
            property bool dcShowClockWhenLockscreen: true
            property bool alwaysFullWidthTopPanel: false
            property string customLSClockColor: "#000000" // HTML format
            property bool useCustomLSClockColor: false
            property var savedPalettes: []
            property bool useCustomLSClockFont: false
            property string customLSClockFont: "Ubuntu"
            property bool widerLandscapeTopPanel: false
            property bool specificIndicatorGesture: false
            property var directAccessIndicators: [
                {"id": 0, "enabled": true} // ayatana-indicator-session
                ,{"id": 1, "enabled": true} // ayatana-indicator-datetime
                ,{"id": 2, "enabled": true} // indicator-network
                ,{"id": 3, "enabled": true} // ayatana-indicator-power
                ,{"id": 4, "enabled": true} // ayatana-indicator-sound
                ,{"id": 5, "enabled": false} // ayatana-indicator-rotation-lock
                ,{"id": 6, "enabled": false} // indicator-location
                ,{"id": 7, "enabled": false} // ayatana-indicator-bluetooth
                ,{"id": 8, "enabled": false} // kugiigi-indicator-darkmode
            ]
            property bool onlyHideTopPanelonLandscape: false
            property bool autoCollapseQuickToggles: false
            property bool hideBatteryIndicatorBracket: false
            property bool hideBatteryIndicatorPercentage: false
            property bool hideBatteryIndicatorIcon: false
            property bool twoDigitHourDateTimeIndicator: false
            property bool verticalBatteryIndicatorIcon: false
            property bool enableCameraKeyDoublePress: false
            property bool reversedCameraKeyDoubePress: false
            property int cameraKeyDoublePressDelay: 300
            property bool enableOSKToggleKeyboardShortcut: false
            property bool enableOSKToggleInIndicator: false
            property int dynamicCoveSelectionDelay: 100
            property bool enableLomiriSettingsToggleIndicator: false
            property bool enableAppSuspensionToggleIndicator: false
            property bool enableActiveScreenToggleIndicator: false
            property bool showAppSuspensionIconIndicator: false
            property bool showActiveScreenIconIndicator: false
            property bool disableLeftEdgeMousePush: false
            property bool disableRightEdgeMousePush: false
            property bool enableDrawerDock: false
            property var drawerDockApps: [
                "dialer-app"
                , "messaging-app"
                , "morph-browser"
                , "lomiri-system-settings"
                , "address-book-app"
                , "openstore.openstore-team_openstore"
                , "gallery.ubports_gallery"
                , "camera.ubports_camera"
            ]
            property bool showBottomHintDrawer: true
            property bool showMiddleNotchHint: false
            property int externalDisplayBehavior: 0
            /*
             0 - Virtual Touchpad
             1 - Multi-display
             2 - Mirrored
            */
            property bool enableImmersiveModeToggleIndicator: false
            property bool showImmersiveModeIconIndicator: false
            property bool enableDarkModeToggleIndicator: false
            property bool enableAutoDarkMode: false
            property bool immediateDarkModeSwitch: false
            property string autoDarkModeStartTime: "19:00"
            property string autoDarkModeEndTime: "06:00"
            property bool enableAutoDarkModeToggleIndicator: false
            property bool onlyShowNotificationsIndicatorWhenGreen: false
            property bool onlyShowSoundIndicatorWhenSilent: false
            property int ow_theme: 0
            /*
                0 - Main Menu
                1 - Solar System
                2 - Sealed Vault
            */
            property bool onlyShowLomiriSettingsWhenUnlocked: true
            property bool enablePullDownGesture: false
            property bool hideTimeIndicatorAlarmIcon: false
            property int drawerDockType: 0
            /*
                0 - Bottom Dock
                1 - Integrated Dock
            */
            property bool enableDrawerBottomSwipe: false
            property bool resetAppDrawerWhenClosed: false
            property bool dcBlurredAlbumArt: false
            property bool transparentTopBarOnSpread: false
            property int quickTogglesCollapsedRowCount: 1
            property bool enableDirectAppInLauncher: false
            property bool fasterFlickDrawer: false
            property bool enableColorOverlay: false
            property string overlayColor: "red"
            property real colorOverlayOpacity: 0.1
            property real pullDownHeight: 3 // In inches
            property bool drawerDockHideLabels: false
            property bool dimWhenLauncherShow: false
            property real drawerIconSizeMultiplier: 1
            property bool enableHotCorners: false
            property bool enableHotCornersVisualFeedback: true
            property bool dcCDPlayerSimpleMode: false
            property real dcCDPlayerOpacity: 1
            property bool enablePanelHeaderExpand: true
            property bool showLauncherAtDesktop: true
            property bool enableShowDesktop: false
            property bool enableCustomBlurRadius: false
            property real customBlurRadius: 4 // in GU
            property bool enableDirectActions: false
            property var directActionList: [
                { actionId: "ayatana-indicator-messages", type: LPDirectActions.Type.Indicator }
                , { actionId: "ayatana-indicator-session", type: LPDirectActions.Type.Indicator }
                , { actionId: "ayatana-indicator-datetime", type: LPDirectActions.Type.Indicator }
                , { actionId: "indicator-network", type: LPDirectActions.Type.Indicator }
                , { actionId: "battery", type: LPDirectActions.Type.Settings }
                , { actionId: "flashlight", type: LPDirectActions.Type.Toggle }
                , { actionId: "screenshot", type: LPDirectActions.Type.Custom }
                , { actionId: "lockscreen", type: LPDirectActions.Type.Custom }
                , { actionId: "powerDialog", type: LPDirectActions.Type.Custom }
                , { actionId: "lomiriplus", type: LPDirectActions.Type.Custom }
            ]
            property real directActionsSwipeAreaHeight: 0.3 // In inches
            property real directActionsMaxWidth: 3 // In inches
            property int directActionsMaxColumn: 0 // 0 = not limited
            property real directActionsSideMargins: 0.2 // In inches
            property bool directActionsEnableHint: true
            property string customInfographicsCircleColor: "white" // HTML format
            property bool useCustomInfographicCircleColor: false
            property bool ow_GradientColoredDate: false

            property bool enableAirMouse: true
            property real airMouseSensitivity: 1 // Multiplier so higher means higher sensitivity
            property bool invertSideMouseScroll: false
            property real sideMouseScrollSensitivity: 1 // Multiplier so higher means higher sensitivity
            property int sideMouseScrollPosition: 0
            /*
            0 - Right
            1 - Left
            */
            property bool enableSideMouseScrollHaptics: true
            property bool useCustomDotsColor: false
            property string customDotsColor: "white"
            property bool enableTopLeftHotCorner: true
            property bool enableTopRightHotCorner: true
            property bool enableBottomRightHotCorner: true
            property bool enableBottomLeftHotCorner: true
            property int actionTypeTopLeftHotCorner: Shell.HotCorner.Drawer
            property int actionTypeTopRightHotCorner: Shell.HotCorner.Indicator
            property int actionTypeBottomRightHotCorner: Shell.HotCorner.ToggleSpread
            property int actionTypeBottomLeftHotCorner: Shell.HotCorner.ToggleDesktop
            property int actionTopLeftHotCorner: 0
            property int actionTopRightHotCorner: 0
            property int actionBottomRightHotCorner: 0
            property int actionBottomLeftHotCorner: 0
            property bool airMouseAlwaysActive: true
            property int directActionsSides: 0
            /*
            0 - Both
            1 - Left Only
            2 - Right Only
            */
            property bool hideBFB: false
            property bool useCustomLSDateColor: false
            property string customLSDateColor: "#000000"
            property bool hideNotificationBodyWhenLocked: false
            property bool enableCustomAppGrid: false
            property var customAppGrids: [
                {
                    name: "Default"
                    , icon: "starred"
                    , apps: [
                        "dialer-app"
                        , "messaging-app"
                        , "morph-browser"
                        , "lomiri-system-settings"
                        , "address-book-app"
                        , "openstore.openstore-team_openstore"
                        , "gallery.ubports_gallery"
                        , "camera.ubports_camera"
                    ]
                }
            ]
            property bool placeFullAppGridToLast: false
            property bool customAppGridsExpandable: false
            property bool expandPanelHeaderWhenBottom: true
            property bool enableSensorGestures: false
            property bool enableAppSpreadFlickMod: false
            property bool enableCoverGesture: false
            property int coverGestureAction: Shell.SensorGestures.ToggleMediaPlayback
            property bool enableShakeGesture: false
            property int shakeGestureAction: Shell.SensorGestures.None
            property bool enableShake2Gesture: false
            property int shake2GestureAction: Shell.SensorGestures.None
            property bool enablePickupGesture: false
            property int pickupGestureAction: Shell.SensorGestures.None
            property bool enableSlamGesture: false
            property int slamGestureAction: Shell.SensorGestures.None
            property bool enableTurnoverGesture: false
            property int turnoverGestureAction: Shell.SensorGestures.None
            property bool enableTwistGesture: false
            property int twistGestureAction: Shell.SensorGestures.None
            property bool enableWhipGesture: false
            property int whipGestureAction: Shell.SensorGestures.None
            property bool enableVolumeButtonsLogic: false
            property bool enableShowTouchVisualsToggleIndicator: false
            property string touchVisualColor: "#000000"
            property bool enableWobblyWindows: false
            property bool enableBottomSwipeDeviceFix: false
            property bool enableAdvancedKeyboardSnapping: false
            property bool enableSpreadTouchFix: false
            property bool useCustomeBFBLogoAppearance: false
            property bool enlargeWindowButtonsWithOverlay: false
            property bool useCustomLauncherColor: false
            property color customLauncherColor: "#111111"
            property bool useCustomLauncherOpacity: false
            property real customLauncherOpacity: 0.95
            property bool useCustomPanelColor: false
            property color customPanelColor: "#111111"
            property bool useCustomDrawerColor: false
            property color customDrawerColor: "#000000"
            property bool useCustomDrawerOpacity: false
            property real customDrawerOpacity: 0.75
            property bool useCustomIndicatorPanelColor: false
            property color customIndicatorPanelColor: "#000000"
            property bool useCustomIndicatorPanelOpacity: false
            property real customIndicatorPanelOpacity: 0.85
            property bool useWallpaperForBlur: false
            property bool customLauncherOpacityBehavior: false
            property bool enableLauncherBottomMargin: false
            property bool matchTopPanelToDrawerIndicatorPanels: false
            property bool enableTopPanelBlur: false
            property bool enableLauncherBlur: false
            property bool enableTopPanelMatchAppTopColor: false
            property bool enableTransparentTopBarInGreeter: false
            property int topPanelMatchAppBehavior: 0
            /*
            0 - Top Left side middle of current app
            1 - Top row of Stage
            */
            property bool enableDelayedStartingAppSuspension: false
            property real delayedStartingAppSuspensionDuration: 5
            property bool enableDelayedAppSuspension: false
            property real delayedAppSuspensionDuration: 5
            property bool enableTopPanelMatchAppTopColorWindowed: false
            property bool enableTitlebarMatchAppTopColor: false
            property int titlebarMatchAppBehavior: 0
            /*
            0 - Top Left side middle of current app
            1 - Top row of Stage
            */
            property bool retainRoundedWindowWhileMatching: false
            property bool useTimerForBackgroundBlurInWindowedMode: false
            property bool workaroundMaxAppsSwitchWorkspace: false // Fix for maximized windows restoring when switching workspace
            property bool delayedWorkspaceSwitcherUI: false
            property bool lessSensitiveEdgeBarriers: false
            property bool enableKeyboardBacklight: false // For Fxtec Pro1-X only
            property bool enableSensorGesturesOnlyWhenScreenOn: false
            property bool blueScreenNotYetShown: true
            property bool directActionsNoSwipeCommit: false
            property var directActionsCustomURIs: [
                {
                    name: "Call 911"
                    , uri: "tel://call/911"
                    , iconType: "default"
                    , iconName: "call-start"
                    , appId: ""
                }
                , {
                    name: "Compose new SMS"
                    , uri: "sms://"
                    , iconType: "default"
                    , iconName: "message-new"
                    , appId: ""
                }
                , {
                    name: "Report a bug"
                    , uri: "mailto:kugi_eusebio@protonmail.com?subject=%5DLomiri%20Plus%20Bug%5D"
                    , iconType: "default"
                    , iconName: "mail-mark-important"
                    , appId: ""
                }
            ]
            property int directActionsShortcutHorizontalLayout: 0
            /*
            0 - Left to right
            1 - Right to left
            2 - Dynamic
            */
            property int directActionsShortcutVerticalLayout: 0
            /*
            0 - Top to bottom
            1 - Bottom to top
            2 - Dynamic
            */
            property int directActionsAnimationSpeed: 0
            /*
            0 - Fast
            1 - Brisk
            2 - Snap
            */
            property bool onlyCommitOnReleaseWhenKeyboardSnapping: false
            property bool useCustomWindowSnappingRectangleColor: false
            property color customWindowSnappingRectangleColor: "#ffffff"
            property bool useCustomWindowSnappingRectangleBorderColor: false
            property color customWindowSnappingRectangleBorderColor: "#99ffffff"
            property bool replaceHorizontalVerticalSnappingWithBottomTop: false
            property int keyboardBacklightAutoBehavior: 0
            /*
            0 - Disabled
            1 - Dark Mode
            2 - Ambient Light
            */
            property bool disableKeyboardShortcutsOverlay: false
            property bool hideLauncherWhenNarrow: false
            property real directActionsMaxWidthGU: 40 // In GU
            property bool enableBatteryGraphIndicator: false
            property bool enableBatteryTracking: false
            property var batteryTrackingData: []
            property int batteryTrackingDataDuration: 7
            property bool enableBatteryStatsIndicator: false
            property bool showScreenTimeSinceLastFullCharged: true
            property bool showScreenTimeSinceLastCharge: false
            property bool showScreenTimeToday: false
            property bool showScreenTimeYesterday: false
            property bool screenTimeFullyChargedWorkaround: false
            property bool collapsibleScreenTimeIndicators: false
            property bool showHistoryCharts: false
            property bool enableColorOverlaySensor: false
            property int colorOverlaySensorThreshold: 0
            property bool enableAutoDarkModeSensor: false
            property int autoDarkModeSensorThreshold: 0
            property int autoDarkModeSensorDelay: 1 // In Seconds
            property bool enablePocketModeSecurity: false
            property bool useCustomTopBarIconTextColor: false
            property color customTopBarIconTextColor: theme.palette.normal.backgroundText
            property bool enableAmbientModeInCDPlayer: false
            property bool disableTogglesOnLockscreen: false
            property var togglesToDisableOnLockscreen: [
            /* when
             * 0 - Always
             * 1 - When Turned On
             * 2 - When Turned Off
            */
                {
                    "identifier": "silentmode"
                    , "when": 2
                }
                , {
                    "identifier": "flightmode"
                    , "when": 2
                }
                , {
                    "identifier": "mobiledata"
                    , "when": 1
                }
                , {
                    "identifier": "wifi"
                    , "when": 1
                }
                , {
                    "identifier": "bluetooth"
                    , "when": 1
                }
                , {
                    "identifier": "location"
                    , "when": 1
                }
                , {
                    "identifier": "hotspot"
                    , "when": 1
                }
                , {
                    "identifier": "activescreen"
                    , "when": 0
                }
            ]
            property bool enableMaxHeightInDrawerDock: false
            property real drawerDockMaxHeight: 3 // In inches
            property bool hideCDPlayerWhenScreenOff: true
            property bool onlyIncludePercentageRangeInBatteryChart: true
            property int batteryPercentageRangeToInclude: 80
            property bool enableSnatchAlarm: false
            property string snatchAlarmContactName: ""
            property bool enableImAwake: false
            property var listOfDisabledWakeAlarms: []
            property real currentDateForAlarms: new Date().getTime()
            property string wakeUpAlarmPrefix: "[WAKEUP]"
            property bool doNotUseLightSensorInPocketMode: false
            property real earliestWakeUpAlarm: new Date().getTime()
            property real latestWakeUpAlarm: new Date().getTime()
            property bool enableBluetoothDevicesList: false
            property var recentBlutoothDevicesList: []
            property bool useCustomAccountIcon: false
            property bool enableCustomAutoBrightness: false
            property var customAutoBrightnessData: [
                { light: 0, brightness: 0 }
                , { light: 13, brightness: 0.25 }
                , { light: 45, brightness: 0.40 }
                , { light: 400, brightness: 0.70 }
                , { light: 3000, brightness: 1.0 }
            ]
            property bool pauseMediaOnBluetoothAudioDisconnect: false
            property bool showNotificationBubblesAtTheBottom: false
            property bool enableAdvancedScreenshot: false
            property bool disableRigheEdgeForWaydroid: false
            property int disableRigheEdgeForWaydroidEdge: 0
            /*
             * 0 - Top
             * 1 - Bottom
            */
            property int disableRigheEdgeForWaydroidHeight: 50 // In percentage
            property bool disableLeftEdgeForWaydroid: false
            property int disableLeftEdgeForWaydroidEdge: 0
            /*
             * 0 - Top
             * 1 - Bottom
            */
            property int disableLeftEdgeForWaydroidHeight: 50 // In percentage
            property bool disablePowerRebootInLockscreen: false
            property bool tryToStabilizeAutoBrightness: false
            property bool enableChargingAlarm: false
            property bool silentChargingAlarm: false
            property bool detectFullyChargedInChargingAlarm: true
            property int targetPercentageChargingAlarm: 80
            property bool alwaysPromptchargingAlarm: false
            property bool chargingAlarmPromptTimesout: false
            property bool enableChargingAlarmByDefault: true
            property bool enableFingerprintWhileDisplayOff: false
            property bool enableFingerprintHapticWhenFailed: false
            property bool onlyTurnOnDisplayWhenFingerprintDisplayOff: false
            property bool failedFingerprintAttemptsWhileDisplayOffWontCount: false
            property real batteryTrackingLastDate: new Date().getTime()
            property int pullDownAreaPosition: 0
            /*
             * 0 - Top half
             * 1 - Bottom half
             * 2 - Bottom custom height
            */
            property real pullDownAreaCustomHeight: 2 // In inches
            property bool directActionsUsePhysicalSizeWhenSwiping: true
            property bool directActionsOffsetSelectionWhenSwiping: true
            property bool directActionsDynamicPositionWhenSwiping: false
            property bool directActionsSwipeOverOSK: false
            property bool extendDrawerOverTopBar: false
            property int blueScreenDelay: 0
            property bool detoxModeEnabled: false
            property var detoxModeAppList: []
            property int detoxModeBehavior: 0
            /*
             * 0 - Fixed time
             * 1 - Random times
            */
            property int detoxModeInterval: 300000 // 5 mins 
            property int detoxModeIntervalStart: 60000 // 1 min
            property int detoxModeIntervalEnd: 600000 // 10 mins 
            property bool enableDetoxModeToggleIndicator: true
            property int detoxModeType: 0
            /*
             * 0 - Windows
             * 1 - Linux
             * 2 - Combined
            */
            property real detoxModeEnabledEpoch: 0
            property bool quickTogglesOnlyShowInNotifications: false
            property bool autoExpandWhenThereAreNotif: false
            property bool enableSilentScreenshot: false
            property bool disableVolumeWhenCamera: false
            property bool displayChargingTimeInAlarm: false
            property bool hideCirclesWhenCDPlayer: false
            property bool balanceMiddleNotchMargin: true
            property bool swipeToUnlockFingerprint: false
            property bool swipeToUnlockEnableAutoLockTimeout: false
            property int swipeToUnlockAutoLockTimeout: 30000 // 30 seconds
            property bool lowestBrightnessWhenTouchpadMode: false
            property int brightnessWhenTouchpadMode: 1
            property bool biggerCursorInExternalDisplay: false
            property bool biggerCursorInExternalDisplayOnlyAirMouse: false
            property real biggerCursorInExternalDisplaySize: 2
            property int lockScreenClockStyle: 0
            /*
             * 0 - Text.Normal - the default
               1 - Text.Outline
               2 - Text.Raised
               3 - Text.Sunken

            */
            property color lockScreenClockStyleColor: "#000000"
            property int lockScreenDateStyle: 0
            /*
             * 0 - Text.Normal - the default
               1 - Text.Outline
               2 - Text.Raised
               3 - Text.Sunken

            */
            property color lockScreenDateStyleColor: "#000000"
            property int directActionsStyle: 0
            /*
             * 0 - Default
               1 - Circular
               2 - Rounded Square

            */
            property bool useIndicatorSelectorForPanelBarWhenInverted: false
            property bool noDecorationWindowedMode: false
            property real appGridIndicatorExpandedSize: 5 // In GU
            property bool appGridIndicatorDoNotExpandWithMouse: false
            property bool showInfographicsOnDesktop: false
            property bool darkenWallpaperWhenInfographics: false
            property real darkenWallpaperWhenInfographicsOpacity: 50
            property bool ow_showSolarSystemOnDesktop: false
            property bool ow_showSolarSystemOnDesktopRunAllTime: false
            property bool lightModeNotificationBubble: false
        }
    }

    function showSettings() {
        settingsLoader.active = true
    }
    
    // ENH067 - Custom Lockscreen Clock Color
    Loader {
        id: colorPickerLoader

        property var itemToColor
        property color oldColor

        // Hide together with the settings page
        opacity: settingsLoader.temporarilyHidden ? 0 : 1

        anchors.fill: parent
        z: settingsLoader.z + 1
        active: false

        function open(caller) {
            itemToColor = caller
            oldColor = caller.text
            active = true
        }
        
        function close() {
            active = false
        }
        
        function applyColor() {
            itemToColor.text = item.colorValue
        }

        function revertColor() {
            itemToColor.text = oldColor
            item.setColor(itemToColor.text)
        }
        
        function savePalette(palette) {
            let strPalette = palette.toString()
            let tempArr = shell.settings.savedPalettes.slice()
            tempArr = shell.removeItemFromList(tempArr, strPalette, true)
            tempArr.push(strPalette)
            shell.settings.savedPalettes = tempArr.slice()
        }

        function deletePalette(palette) {
            let paletteDelete = palette
            let tempArr = shell.settings.savedPalettes.slice()
            tempArr = shell.removeItemFromList(tempArr, paletteDelete, true)
            shell.settings.savedPalettes = tempArr.slice()
        }

        onLoaded: {
            item.setColor(itemToColor.text)
        }
        
        sourceComponent: Component {
            Item {
                id: colorPickerContainer

                property alias colorValue: colorPicker.colorValue
                opacity: dragButton.dragActive ? 0.4 : 1
                Behavior on opacity { LomiriNumberAnimation {} }

                function setColor(colorToSet) {
                    colorPicker.setColorValue(colorToSet)
                }

                Rectangle {
                    id: colorPickerFloat

                    x: shell.width / 2 - width / 2
                    y: shell.height - height
                    width: Math.min(units.gu(60), parent.width - units.gu(4))
                    height: units.gu(50)
                    radius: units.gu(2)
                    color: theme.palette.normal.background
                    clip: true

                    // Eater mouse events
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.AllButtons
                        onWheel: wheel.accepted = true;
                    }

                    ColumnLayout {
                        spacing: 0
                        anchors.fill: parent

                        Rectangle {
                            Layout.preferredHeight: units.gu(6)
                            Layout.fillWidth: true
                            color: theme.palette.normal.foreground

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: units.gu(2)
                                    rightMargin: units.gu(2)
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: colorPicker.colorValue
                                    color: theme.palette.normal.foregroundText
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Rectangle {
                                    Layout.preferredWidth: units.gu(8)
                                    Layout.preferredHeight: units.gu(4)
                                    Layout.alignment: Qt.AlignRight
                                    radius: units.gu(1)
                                    color: colorPicker.colorValue
                                    border {
                                        width: units.dp(1)
                                        color: theme.palette.normal.foregroundText
                                    }
                                }
                                LPSettingsCheckBox {
                                    id: paletteMode
                                    Layout.alignment: Qt.AlignRight
                                    Layout.maximumWidth: units.gu(19)
                                    text: "Palette Mode"
                                    inverted: true
                                    onCheckedChanged: colorPicker.paletteMode = checked
                                    Binding {
                                        target: paletteMode
                                        property: "checked"
                                        value: colorPicker.paletteMode
                                    }
                                }
                                MouseArea {
                                    id: dragButton

                                    readonly property bool dragActive: drag.active

                                    Layout.fillHeight: true
                                    Layout.preferredWidth: units.gu(6)
                                    Layout.preferredHeight: width
                                    Layout.alignment: Qt.AlignRight

                                    drag.target: colorPickerFloat
                                    drag.axis: Drag.XAndYAxis
                                    drag.minimumX: 0
                                    drag.maximumX: shell.width - colorPickerFloat.width
                                    drag.minimumY: 0
                                    drag.maximumY: shell.height - colorPickerFloat.height

                                    Rectangle {
                                        anchors.fill: parent
                                        color: dragButton.pressed ? theme.palette.selected.overlay : theme.palette.normal.overlay

                                        Behavior on color {
                                            ColorAnimation { duration: LomiriAnimation.FastDuration }
                                        }

                                        Icon {
                                            id: icon

                                            implicitWidth: dragButton.width * 0.60
                                            implicitHeight: implicitWidth
                                            name: "grip-large"
                                            anchors.centerIn: parent
                                            color: theme.palette.normal.overlayText
                                        }
                                    }
                                }
                            }
                        }
                        Rectangle {
                            color: theme.palette.normal.foregroundText
                            Layout.preferredHeight: units.dp(1)
                            Layout.fillWidth: true
                        }
                        Colorpicker {
                            id: colorPicker

                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            enableDetails: false
                        }
                        Rectangle {
                            color: theme.palette.normal.foregroundText
                            Layout.preferredHeight: units.dp(1)
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: units.gu(6)
                            color: theme.palette.normal.foreground

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: units.gu(2)
                                    rightMargin: units.gu(2)
                                }
                                Button {
                                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                    text: "Close"
                                    onClicked: colorPickerLoader.close()
                                }
                                Button {
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    text: colorPicker.savedPaletteIsSelected ? "Delete Palette" : "Save Palette"
                                    color: colorPicker.savedPaletteIsSelected ? theme.palette.normal.negative : theme.palette.normal.positive
                                    onClicked: {
                                        if (colorPicker.savedPaletteIsSelected) {
                                            colorPickerLoader.deletePalette(colorPicker.savedPaletteColor)
                                        } else {
                                            colorPickerLoader.savePalette(colorPicker.colorValue)
                                        }
                                    }
                                }
                                Button {
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    text: "Revert"
                                    onClicked: colorPickerLoader.revertColor()
                                }
                                Button {
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    text: "Apply"
                                    color: theme.palette.normal.positive
                                    onClicked: colorPickerLoader.applyColor()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    // ENH067 - End

    Loader {
        id: settingsLoader

        property bool temporarilyHidden: false

        opacity: temporarilyHidden ? 0 : 1
        active: false
        z: inputMethod.visible ? inputMethod.z - 1 : cursor.z - 2
        width: Math.min(parent.width, units.gu(45))
        height: inputMethod.visible ? parent.height - inputMethod.visibleRect.height - panel.minimizedPanelHeight
                                    : Math.min(parent.height, units.gu(60))
        onActiveChanged: {
            if (!active) colorPickerLoader.close()
        }

        sourceComponent: Component {
            Rectangle {
                id: lpSettingsRec

                property alias stack: stack
                color: Suru.backgroundColor
                x: shell.width / 2 - width / 2
                y: shell.height - height
                opacity: settingsDragButton.dragActive ? 0.4 : 1
                Behavior on opacity { LomiriNumberAnimation {} }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    QQC2.ToolBar {
                        Layout.fillWidth: true
                        Layout.bottomMargin: units.dp(1)
                        RowLayout {
                            anchors.fill: parent
                            QQC2.ToolButton {
                                Layout.fillHeight: true
                                Layout.preferredWidth: units.gu(4)
                                icon.width: units.gu(2)
                                icon.height: units.gu(2)
                                action: QQC2.Action {
                                    icon.name:  stack.depth > 1 ? "back" : "close"
                                    shortcut: StandardKey.Cancel
                                     onTriggered: {
                                        if (stack.depth > 1) {
                                            stack.pop()
                                        } else {
                                            settingsLoader.active = false
                                        }
                                    }
                                }
                            }
                            Label {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: stack.currentItem.title
                                verticalAlignment: Text.AlignVCenter
                                textSize: Label.Large
                                elide: Text.ElideRight
                            }
                            MouseArea {
                                id: hideButton

                                Layout.fillHeight: true
                                Layout.preferredWidth: units.gu(6)
                                Layout.preferredHeight: width
                                Layout.alignment: Qt.AlignRight

                                onPressed: settingsLoader.temporarilyHidden = true
                                onReleased: settingsLoader.temporarilyHidden = false

                                Rectangle {
                                    anchors.fill: parent
                                    color: hideButton.pressed ? theme.palette.selected.background : theme.palette.normal.background

                                    Behavior on color {
                                        ColorAnimation { duration: LomiriAnimation.FastDuration }
                                    }

                                    Icon {
                                        id: hideIcon

                                        implicitWidth: hideButton.width * 0.60
                                        implicitHeight: implicitWidth
                                        name: "view-off"
                                        anchors.centerIn: parent
                                        color: theme.palette.normal.overlayText
                                    }
                                }
                            }
                            MouseArea {
                                id: settingsDragButton

                                readonly property bool dragActive: drag.active

                                Layout.fillHeight: true
                                Layout.preferredWidth: units.gu(6)
                                Layout.preferredHeight: width
                                Layout.alignment: Qt.AlignRight

                                drag.target: lpSettingsRec
                                drag.axis: Drag.XAndYAxis
                                drag.minimumX: 0
                                drag.maximumX: shell.width - lpSettingsRec.width
                                drag.minimumY: 0
                                drag.maximumY: shell.height - lpSettingsRec.height

                                Rectangle {
                                    anchors.fill: parent
                                    color: settingsDragButton.pressed ? theme.palette.selected.background : theme.palette.normal.background

                                    Behavior on color {
                                        ColorAnimation { duration: LomiriAnimation.FastDuration }
                                    }

                                    Icon {
                                        id: icon

                                        implicitWidth: settingsDragButton.width * 0.60
                                        implicitHeight: implicitWidth
                                        name: "grip-large"
                                        anchors.centerIn: parent
                                        color: theme.palette.normal.overlayText
                                    }
                                }
                            }
                        }
                    }

                    QQC2.StackView {
                        id: stack
                        
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        initialItem: settingsPage
                    }

                    Button {
                        id: closeButton

                        color: theme.palette.normal.foreground
                        text: "Close"
                        Layout.fillWidth: true
                        onClicked: settingsLoader.active = false
                    }
                }
            }
        }
    }
    Component {
        id: settingsPage
        
        LPSettingsPage {
            title: "Lomiri Plus Settings"

            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Security & Privacy"
                onClicked: settingsLoader.item.stack.push(privacyPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Features"
                onClicked: settingsLoader.item.stack.push(featuresPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Outer Wilds"
                onClicked: settingsLoader.item.stack.push(outerWildsPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Appearance"
                onClicked: settingsLoader.item.stack.push(appearancePage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Accessibility"
                onClicked: settingsLoader.item.stack.push(accessibilityPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Convergence"
                onClicked: settingsLoader.item.stack.push(convergencePage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Components"
                onClicked: settingsLoader.item.stack.push(componentsPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Device Configuration"
                onClicked: settingsLoader.item.stack.push(devicePage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Device Specific Hacks"
                onClicked: settingsLoader.item.stack.push(deviceSpecificPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Experimentals/Fixes"
                onClicked: settingsLoader.item.stack.push(experimentalsPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Extras"
                onClicked: settingsLoader.item.stack.push(extrasPage, {"title": text})
            }
        }
    }
    Component {
        id: featuresPage

        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "General"
                wrapMode: Text.WordWrap
                textSize: Label.Large
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Abot Kamay"
                onClicked: settingsLoader.item.stack.push(pullDownPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Advanced Screenshot"
                onClicked: settingsLoader.item.stack.push(advancedScreenshotPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Auto Dark Mode"
                onClicked: settingsLoader.item.stack.push(autoDarkModePage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Auto-Brightness DIY"
                onClicked: settingsLoader.item.stack.push(autoBrightnessPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Color Overlay"
                onClicked: settingsLoader.item.stack.push(colorOverlayPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Detox Mode"
                onClicked: settingsLoader.item.stack.push(detoxModePage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Fully Charged Alarm"
                onClicked: settingsLoader.item.stack.push(chargingAlarmPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Quick Actions"
                onClicked: settingsLoader.item.stack.push(directActionsPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Sensor Gestures"
                onClicked: settingsLoader.item.stack.push(sensorGesturesPage, {"title": text})
            }
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Launcher & App Drawer"
                wrapMode: Text.WordWrap
                textSize: Label.Large
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Launcher Direct Select"
                onClicked: settingsLoader.item.stack.push(directSelectPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Drawer Dock"
                onClicked: settingsLoader.item.stack.push(drawerDockPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "App Grids"
                onClicked: settingsLoader.item.stack.push(appGridsPage, {"title": text})
            }
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Indicators"
                wrapMode: Text.WordWrap
                textSize: Label.Large
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Battery Statistics"
                onClicked: settingsLoader.item.stack.push(batteryStatsPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Quick toggles"
                onClicked: settingsLoader.item.stack.push(quickTogglesPage, {"title": text})
            }
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Lockscreen"
                wrapMode: Text.WordWrap
                textSize: Label.Large
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Dynamic Cove"
                onClicked: settingsLoader.item.stack.push(dynamicCovePage, {"title": text})
            }
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Desktop Mode"
                wrapMode: Text.WordWrap
                textSize: Label.Large
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Air Mouse"
                onClicked: settingsLoader.item.stack.push(airMousePage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Hot Corners"
                onClicked: settingsLoader.item.stack.push(hotcornersPage, {"title": text})
            }
        }
    }
    Component {
        id: chargingAlarmPage

        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "When this is enabled, an alarm will be set once your device is fully charged or reached the percentage you set. The alarm will go off after a minute or so"
                + "\n\nNote that sometimes and/or some device will fail to detect fully charged state. If you encounter this, disable the setting and use the Default Target Battery % settings instead"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSwitch {
                id: enableChargingAlarm
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: shell.settings.enableChargingAlarm = checked
                Binding {
                    target: enableChargingAlarm
                    property: "checked"
                    value: shell.settings.enableChargingAlarm
                }
            }
            LPSettingsCheckBox {
                id: alwaysPromptchargingAlarm
                Layout.fillWidth: true
                text: "Ask upon plugging to power"
                visible: shell.settings.enableChargingAlarm
                onCheckedChanged: shell.settings.alwaysPromptchargingAlarm = checked
                Binding {
                    target: alwaysPromptchargingAlarm
                    property: "checked"
                    value: shell.settings.alwaysPromptchargingAlarm
                }
            }
            LPSettingsCheckBox {
                id: chargingAlarmPromptTimesout
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                text: "Prompt times out after 60s"
                visible: shell.settings.enableChargingAlarm && shell.settings.alwaysPromptchargingAlarm
                onCheckedChanged: shell.settings.chargingAlarmPromptTimesout = checked
                Binding {
                    target: chargingAlarmPromptTimesout
                    property: "checked"
                    value: shell.settings.chargingAlarmPromptTimesout
                }
            }
            LPSettingsCheckBox {
                id: enableChargingAlarmByDefault
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                text: "Enable alarm when prompt times out"
                visible: shell.settings.enableChargingAlarm && shell.settings.alwaysPromptchargingAlarm
                                    && shell.settings.chargingAlarmPromptTimesout
                onCheckedChanged: shell.settings.enableChargingAlarmByDefault = checked
                Binding {
                    target: enableChargingAlarmByDefault
                    property: "checked"
                    value: shell.settings.enableChargingAlarmByDefault
                }
            }
            LPSettingsCheckBox {
                id: silentChargingAlarm
                Layout.fillWidth: true
                text: "Silent alarm"
                visible: shell.settings.enableChargingAlarm
                onCheckedChanged: shell.settings.silentChargingAlarm = checked
                Binding {
                    target: silentChargingAlarm
                    property: "checked"
                    value: shell.settings.silentChargingAlarm
                }
            }
            LPSettingsCheckBox {
                id: displayChargingTimeInAlarm
                Layout.fillWidth: true
                text: "Display charging time alarm name"
                visible: shell.settings.enableChargingAlarm
                onCheckedChanged: shell.settings.displayChargingTimeInAlarm = checked
                Binding {
                    target: displayChargingTimeInAlarm
                    property: "checked"
                    value: shell.settings.displayChargingTimeInAlarm
                }
            }
            LPSettingsCheckBox {
                id: detectFullyChargedInChargingAlarm
                Layout.fillWidth: true
                text: "Detect Fully Charged State"
                visible: shell.settings.enableChargingAlarm
                onCheckedChanged: shell.settings.detectFullyChargedInChargingAlarm = checked
                Binding {
                    target: detectFullyChargedInChargingAlarm
                    property: "checked"
                    value: shell.settings.detectFullyChargedInChargingAlarm
                }
            }
            LPSettingsSlider {
                id: targetPercentageChargingAlarm
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableChargingAlarm && !shell.settings.detectFullyChargedInChargingAlarm
                title: "Default Target Battery %"
                minimumValue: 50
                maximumValue: 100
                stepSize: 1
                resetValue: 80
                live: true
                roundValue: true
                roundingDecimal: 1
                enableFineControls: true
                unitsLabel: "%"
                onValueChanged: shell.settings.targetPercentageChargingAlarm = value
                Binding {
                    target: targetPercentageChargingAlarm
                    property: "value"
                    value: shell.settings.targetPercentageChargingAlarm
                }
            }
        }
    }
    Component {
        id: advancedScreenshotPage

        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "This will show a prompt at the bottom whenever you take a screenshot. The prompt will allow you to do actions such as edit and share."
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSwitch {
                id: enableAdvancedScreenshot
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: shell.settings.enableAdvancedScreenshot = checked
                Binding {
                    target: enableAdvancedScreenshot
                    property: "checked"
                    value: shell.settings.enableAdvancedScreenshot
                }
            }
        }
    }
    Component {
        id: extrasPage

        LPSettingsPage {
            LPSettingsCheckBox {
                id: blueScreenNotYetShown
                Layout.fillWidth: true
                text: "Show Fun Page (next startup)"
                onCheckedChanged: shell.settings.blueScreenNotYetShown = checked
                Binding {
                    target: blueScreenNotYetShown
                    property: "checked"
                    value: shell.settings.blueScreenNotYetShown
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: i18n.tr("Type")
                model: [
                    "Windows"
                    , "Linux"
                    , "Combined"
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.detoxModeType
                onSelectedIndexChanged: shell.settings.detoxModeType = selectedIndex
            }
            Button {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.leftMargin: units.gu(2)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: buruIskunuru.isPending ? "Cancel" : "Show Fun Page"
                onClicked: {
                    if (buruIskunuru.isPending) {
                        buruIskunuru.cancelPending()
                    } else {
                        buruIskunuru.delayedShow(shell.settings.blueScreenDelay)
                    }
                }
            }
            LPSettingsSlider {
                id: blueScreenDelay
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Delay"
                minimumValue: 0
                maximumValue: 10
                stepSize: 0.1
                resetValue: 0
                live: false
                enableFineControls: true
                roundValue: true
                roundingDecimal: 2
                unitsLabel: "minutes"
                onValueChanged: shell.settings.blueScreenDelay = value * 60000
                Binding {
                    target: blueScreenDelay
                    property: "value"
                    value: shell.settings.blueScreenDelay / 60000
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Long press or right click to close the Fun Page"
                wrapMode: Text.WordWrap
                font.italic: true
            }
        }
    }
    Component {
        id: detoxModePage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.topMargin: units.gu(2)
                Layout.leftMargin: units.gu(2)
                Layout.rightMargin: units.gu(2)
                text: "When Detox mode is enabled, a fun fullscreen page appears when any of the apps listed below are in focus or the currently active app.\n\n"
                + " The fun page appears at random times or at fixed interval depending on the settings.\n\n"
                + "Note that Detox mode can only be disabled after 24 hours from the time of enabling it"
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSwitch {
                id: detoxModeEnabled
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: {
                    if (!checked) {
                        const _canBeDisabled = shell.checkDetoxModeEnablement()
                        if (_canBeDisabled) {
                            shell.settings.detoxModeEnabled = checked
                        } else {
                            checked = true
                            shell.showCannotDisableDetoxModeDialog()
                        }
                    } else {
                        if (!shell.settings.detoxModeEnabled) {
                            shell.showDetoxModeEnableDialog()
                            checked = false
                        }
                    }
                }
                Binding {
                    target: detoxModeEnabled
                    property: "checked"
                    value: shell.settings.detoxModeEnabled
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: i18n.tr("Type")
                model: [
                    "Windows"
                    , "Linux"
                    , "Combined"
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.detoxModeType
                onSelectedIndexChanged: shell.settings.detoxModeType = selectedIndex
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                enabled: !shell.settings.detoxModeEnabled
                text: i18n.tr("Behavior")
                model: ["Fixed interval"
                       ,"Random  interval"]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.detoxModeBehavior
                onSelectedIndexChanged: shell.settings.detoxModeBehavior = selectedIndex
            }
            LPSettingsSlider {
                id: detoxModeInterval
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.detoxModeBehavior === 0
                enabled: !shell.settings.detoxModeEnabled
                title: "Every"
                minimumValue: 0.05
                maximumValue: 15
                stepSize: 0.5
                resetValue: 5
                live: false
                enableFineControls: true
                roundValue: true
                roundingDecimal: 2
                onValueChanged: shell.settings.detoxModeInterval = value * 60000
                Binding {
                    target: detoxModeInterval
                    property: "value"
                    value: shell.settings.detoxModeInterval / 60000
                }
                function formatDisplayValue(v) {
                    return shell.msToTime(v * 60000)
                }
            }
            LPSettingsSlider {
                id: detoxModeIntervalStart
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.detoxModeBehavior === 1
                enabled: !shell.settings.detoxModeEnabled
                title: "From"
                minimumValue: 0
                maximumValue: shell.settings.detoxModeIntervalEnd / 60000
                stepSize: 0.5
                resetValue: 1
                live: false
                enableFineControls: true
                roundValue: true
                roundingDecimal: 2
                onValueChanged: shell.settings.detoxModeIntervalStart = value * 60000
                Binding {
                    target: detoxModeIntervalStart
                    property: "value"
                    value: shell.settings.detoxModeIntervalStart / 60000
                }
                function formatDisplayValue(v) {
                    return shell.msToTime(v * 60000)
                }
            }
            LPSettingsSlider {
                id: detoxModeIntervalEnd
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.detoxModeBehavior === 1
                enabled: !shell.settings.detoxModeEnabled
                title: "To"
                minimumValue: (shell.settings.detoxModeIntervalStart / 60000) + 0.03 // Add around 2 seconds so there's bit of an allowance
                maximumValue: 15
                stepSize: 0.5
                resetValue: 10
                live: false
                enableFineControls: true
                roundValue: true
                roundingDecimal: 2
                onValueChanged: shell.settings.detoxModeIntervalEnd = value * 60000
                Binding {
                    target: detoxModeIntervalEnd
                    property: "value"
                    value: shell.settings.detoxModeIntervalEnd / 60000
                }
                function formatDisplayValue(v) {
                    return shell.msToTime(v * 60000)
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                Layout.rightMargin: units.gu(2)
                Layout.topMargin: units.gu(1)
                Layout.bottomMargin: units.gu(1)

                enabled: !shell.settings.detoxModeEnabled
                text: "Add App"
                color: theme.palette.normal.positive
                onClicked: {
                    let _dialogAdd = addDetoxModeAppDialog.createObject(shell.popupParent);
                    _dialogAdd.show()
                }
            }
            ListView {
                id: detoxModeAppListView

                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight

                interactive: false
                model: shell.settings.detoxModeAppList

                delegate: ListItem {
                    id: detoxModelistItem

                    readonly property string appId: modelData

                    enabled: !shell.settings.detoxModeEnabled
                    height: detoxModeLayout.height + (divider.visible ? divider.height : 0)
                    color: dragging ? theme.palette.selected.base : "transparent"

                    ListItemLayout {
                        id: detoxModeLayout

                        readonly property var appData: !shell.appModel.refreshing ? shell.getAppData(modelData) : null

                        title.text: {
                            if (appData) {
                                return appData.name
                            }

                            return "Unknown"
                        }
                        title.wrapMode: Text.WordWrap

                        LomiriShape {
                            SlotsLayout.position: SlotsLayout.Leading
                            source: Image { source: detoxModeLayout.appData ? detoxModeLayout.appData.icon : "" }
                            sourceFillMode: LomiriShape.PreserveAspectFit
                            radius: "medium"
                            height: units.gu(5)
                            width: height
                        }
                    }

                    leadingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "delete"
                                onTriggered: {
                                    let _arrNewValues = shell.settings.detoxModeAppList.slice()
                                    let _indexToDelete = _arrNewValues.findIndex((element) => (element == detoxModelistItem.appId));
                                    _arrNewValues.splice(_indexToDelete, 1)
                                    shell.settings.detoxModeAppList = _arrNewValues.slice()
                                }
                            }
                        ]
                    }
                }

                Component {
                    id: addDetoxModeAppDialog
                    Dialog {
                        id: detoxModeDialogue
                        
                        property bool reparentToRootItem: false
                        anchorToKeyboard: false // Handle the keyboard anchor via shell.popupParent

                        property int selectedIndex: 0
                        property string actionId: {
                            const _app = actionIdSelector.model.get(detoxModeDialogue.selectedIndex)
                            let _appId = _app.appId
                            return _appId ? _appId : ""
                        }

                        SortFilterModel {
                            id: searchAppModel
                            model: shell.appModel
                            sort {
                                property: "name"
                                order: Qt.AscendingOrder
                            }
                            filter {
                                property: "name"
                            }
                        }

                        RowLayout {
                            TextField {
                                id: detoxModeSearchField
                                Layout.fillWidth: true
                                placeholderText: "Type to search apps"
                                inputMethodHints: Qt.ImhNoPredictiveText
                            }
                            Button {
                                Layout.preferredWidth: units.gu(5)
                                iconName: "search"
                                onClicked: {
                                    const _reg = new RegExp(detoxModeSearchField.text, "i");
                                    searchAppModel.filter.pattern = _reg
                                }
                            }
                        }

                        OptionSelector {
                             id: actionIdSelector

                            text: i18n.tr("Apps")

                            model: searchAppModel
                            containerHeight: itemHeight * 6
                            selectedIndex: 0
                            delegate: detoxModeAppsSelectorDelegate
                        }
                        Component {
                            id: detoxModeAppsSelectorDelegate
                            OptionSelectorDelegate {
                                text: model.name
                                iconSource: model.icon
                                constrainImage: true

                                // WORKAROUND: Using the get function of SortFilterModel doesn't get data
                                // in filtered state and instead only in sroted state
                                // so we use this workaround instead
                                onSelectedChanged: detoxModeDialogue.selectedIndex = index
                            }
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.leftMargin: units.gu(2)
                            Layout.rightMargin: units.gu(2)
                            Layout.bottomMargin: units.gu(2)
                            visible: !btnAdd.enabled
                            text: "Essential apps can't be added"
                            wrapMode: Text.WordWrap
                            font.italic: true
                        }
                        Button {
                            id: btnAdd
                             text: "Add"
                             color: theme.palette.normal.positive
                             enabled: detoxModeDialogue.actionId !== "dialer-app" && detoxModeDialogue.actionId !== "messaging-app"
                             onClicked: {
                                 let _arrNewValues = shell.settings.detoxModeAppList.slice()
                                _arrNewValues.push(detoxModeDialogue.actionId)
                                shell.settings.detoxModeAppList = _arrNewValues.slice()
                                PopupUtils.close(detoxModeDialogue)
                             }
                         }
                         Button {
                             text: "Cancel"
                             onClicked: PopupUtils.close(detoxModeDialogue)
                         }
                     }
                }
            }
        }
    }
    Component {
        id: experimentalsPage
        
        LPSettingsPage {
            LPSettingsCheckBox {
                id: enableAppSpreadFlickMod
                Layout.fillWidth: true
                text: "App spread flick mod"
                onCheckedChanged: shell.settings.enableAppSpreadFlickMod = checked
                Binding {
                    target: enableAppSpreadFlickMod
                    property: "checked"
                    value: shell.settings.enableAppSpreadFlickMod
                }
            }
            LPSettingsCheckBox {
                id: workaroundMaxAppsSwitchWorkspace
                Layout.fillWidth: true
                text: "Fix maximized windows are restored when switching workspace"
                onCheckedChanged: shell.settings.workaroundMaxAppsSwitchWorkspace = checked
                Binding {
                    target: workaroundMaxAppsSwitchWorkspace
                    property: "checked"
                    value: shell.settings.workaroundMaxAppsSwitchWorkspace
                }
            }
        }
    }
    Component {
        id: privacyPage
        
        LPSettingsPage {
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Fingerprint"
                onClicked: settingsLoader.item.stack.push(fingerprintPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Disable toggles when locked"
                onClicked: settingsLoader.item.stack.push(disableTogglesPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Snatch Alarm"
                onClicked: settingsLoader.item.stack.push(snatchAlarmPage, {"title": text})
            }
            LPSettingsCheckBox {
                id: onlyShowLomiriSettingsWhenUnlocked
                Layout.fillWidth: true
                text: "Lock Settings when locked"
                onCheckedChanged: shell.settings.onlyShowLomiriSettingsWhenUnlocked = checked
                Binding {
                    target: onlyShowLomiriSettingsWhenUnlocked
                    property: "checked"
                    value: shell.settings.onlyShowLomiriSettingsWhenUnlocked
                }
            }
            LPSettingsCheckBox {
                id: hideNotificationBodyWhenLocked
                Layout.fillWidth: true
                text: "Hide notification content when locked"
                onCheckedChanged: shell.settings.hideNotificationBodyWhenLocked = checked
                Binding {
                    target: hideNotificationBodyWhenLocked
                    property: "checked"
                    value: shell.settings.hideNotificationBodyWhenLocked
                }
            }
            LPSettingsCheckBox {
                id: disablePowerRebootInLockscreen
                Layout.fillWidth: true
                text: "Disable shutdown and reboot in lockscreen"
                onCheckedChanged: shell.settings.disablePowerRebootInLockscreen = checked
                Binding {
                    target: disablePowerRebootInLockscreen
                    property: "checked"
                    value: shell.settings.disablePowerRebootInLockscreen
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "When enabled, shutdown and reboot buttons will do nothing when in the lockscreen. To make them work, swipe both from the left and right edge and press the button."
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSwitch {
                id: enablePocketModeSecurity
                Layout.fillWidth: true
                text: "Enable Pocket Mode detection"
                onCheckedChanged: shell.settings.enablePocketModeSecurity = checked
                Binding {
                    target: enablePocketModeSecurity
                    property: "checked"
                    value: shell.settings.enablePocketModeSecurity
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Any kind of interaction will be disabled when Pocket Mode is detected. It is detected via Proximity (Near) and Light sensors (0)"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsCheckBox {
                id: doNotUseLightSensorInPocketMode
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                visible: shell.settings.enablePocketModeSecurity
                text: "Do not use Light sensor"
                onCheckedChanged: shell.settings.doNotUseLightSensorInPocketMode = checked
                Binding {
                    target: doNotUseLightSensorInPocketMode
                    property: "checked"
                    value: shell.settings.doNotUseLightSensorInPocketMode
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Some devices have non-functioning light sensor so you can disable it and only use proximity sensor"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
        }
    }
    Component {
        id: fingerprintPage

        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "These settings are untested on most devices and may not work properly or at all. These may also impact battery life so use with caution and be observant."
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsCheckBox {
                id: enableFingerprintHapticWhenFailed
                Layout.fillWidth: true
                text: "Haptic feedback on failed attempts"
                onCheckedChanged: shell.settings.enableFingerprintHapticWhenFailed = checked
                Binding {
                    target: enableFingerprintHapticWhenFailed
                    property: "checked"
                    value: shell.settings.enableFingerprintHapticWhenFailed
                }
            }
            LPSettingsCheckBox {
                id: swipeToUnlockFingerprint
                Layout.fillWidth: true
                text: "Require a swipe to fully unlock"
                onCheckedChanged: shell.settings.swipeToUnlockFingerprint = checked
                Binding {
                    target: swipeToUnlockFingerprint
                    property: "checked"
                    value: shell.settings.swipeToUnlockFingerprint
                }
            }
            LPSettingsCheckBox {
                id: swipeToUnlockEnableAutoLockTimeout
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                visible: shell.settings.swipeToUnlockFingerprint
                text: "Automatically lock after a set time"
                onCheckedChanged: shell.settings.swipeToUnlockEnableAutoLockTimeout = checked
                Binding {
                    target: swipeToUnlockEnableAutoLockTimeout
                    property: "checked"
                    value: shell.settings.swipeToUnlockEnableAutoLockTimeout
                }
            }
            LPSettingsSlider {
                id: swipeToUnlockAutoLockTimeout
                Layout.fillWidth: true
                Layout.margins: units.gu(4)
                visible: swipeToUnlockEnableAutoLockTimeout.visible
                title: "To"
                minimumValue: 5000
                maximumValue: 60000
                stepSize: 5000
                resetValue: 30000
                live: false
                enableFineControls: true
                roundValue: true
                roundingDecimal: 2
                onValueChanged: shell.settings.swipeToUnlockAutoLockTimeout = value
                Binding {
                    target: swipeToUnlockAutoLockTimeout
                    property: "value"
                    value: shell.settings.swipeToUnlockAutoLockTimeout
                }
                function formatDisplayValue(v) {
                    return shell.msToTime(v)
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                visible: swipeToUnlockEnableAutoLockTimeout.visible
                text: "Device will lock again after the set time expires without user interaction and will require unlocking with passcode or fingerprint again."
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsCheckBox {
                id: enableFingerprintWhileDisplayOff
                Layout.fillWidth: true
                text: "Enable even while display is off"
                onCheckedChanged: shell.settings.enableFingerprintWhileDisplayOff = checked
                Binding {
                    target: enableFingerprintWhileDisplayOff
                    property: "checked"
                    value: shell.settings.enableFingerprintWhileDisplayOff
                }
            }
            LPSettingsCheckBox {
                id: onlyTurnOnDisplayWhenFingerprintDisplayOff
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                text: "Only turn on display. Do not unlock when display is off"
                visible: shell.settings.enableFingerprintWhileDisplayOff
                onCheckedChanged: shell.settings.onlyTurnOnDisplayWhenFingerprintDisplayOff = checked
                Binding {
                    target: onlyTurnOnDisplayWhenFingerprintDisplayOff
                    property: "checked"
                    value: shell.settings.onlyTurnOnDisplayWhenFingerprintDisplayOff
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                visible: onlyTurnOnDisplayWhenFingerprintDisplayOff.visible
                text: "This can be helpful if you often want to see the lockscreen instead of going straight to unlocked state"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsCheckBox {
                id: failedFingerprintAttemptsWhileDisplayOffWontCount
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                text: "Failed attempts while display off won't count"
                visible: shell.settings.enableFingerprintWhileDisplayOff
                onCheckedChanged: shell.settings.failedFingerprintAttemptsWhileDisplayOffWontCount = checked
                Binding {
                    target: failedFingerprintAttemptsWhileDisplayOffWontCount
                    property: "checked"
                    value: shell.settings.failedFingerprintAttemptsWhileDisplayOffWontCount
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                visible: failedFingerprintAttemptsWhileDisplayOffWontCount.visible
                text: "This means failed attempts while display off won't lock out the fingerprint authentication."
                + " May be helpful to avoid accidental touches to the sensor locking out Fingerprint authentication."
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
        }
    }
    Component {
        id: snatchAlarmPage

        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Set a specific contact name which will make the phone automatically disable silent mode and put the volume to max when a call is received from this contact."
                + "This could be helpful if for example you have a secondary phone and your main phone got snatched, you call it from your secondary phone and your phone will ring at max volume.\n"
                + "Honestly, I don't know if this makes sense. I just thought of it and did anyway because I can LOL"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSwitch {
                id: enableSnatchAlarm
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: shell.settings.enableSnatchAlarm = checked
                Binding {
                    target: enableSnatchAlarm
                    property: "checked"
                    value: shell.settings.enableSnatchAlarm
                }
            }
            TextField {
                id: snatchAlarmContactName

                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                placeholderText: "Contact Name"
                inputMethodHints: Qt.ImhNoPredictiveText
                onTextChanged: shell.settings.snatchAlarmContactName = text
                Binding {
                    target: snatchAlarmContactName
                    property: "text"
                    value: shell.settings.snatchAlarmContactName
                }
            }
        }
    }
    Component {
        id: appearancePage
        
        LPSettingsPage {
            LPSettingsCheckBox {
                id: useWallpaperForBlur
                Layout.fillWidth: true
                text: "Use wallpaper for background blurs"
                onCheckedChanged: shell.settings.useWallpaperForBlur = checked
                Binding {
                    target: useWallpaperForBlur
                    property: "checked"
                    value: shell.settings.useWallpaperForBlur
                }
            }
            LPSettingsCheckBox {
                id: useTimerForBackgroundBlurInWindowedMode
                Layout.fillWidth: true
                text: "Use timer for blur updates (May improve performance)"
                onCheckedChanged: shell.settings.useTimerForBackgroundBlurInWindowedMode = checked
                Binding {
                    target: useTimerForBackgroundBlurInWindowedMode
                    property: "checked"
                    value: shell.settings.useTimerForBackgroundBlurInWindowedMode
                }
            }
            LPSettingsSwitch {
                id: enableCustomBlurRadius
                Layout.fillWidth: true
                text: "Enable custom blur radius"
                onCheckedChanged: shell.settings.enableCustomBlurRadius = checked
                Binding {
                    target: enableCustomBlurRadius
                    property: "checked"
                    value: shell.settings.enableCustomBlurRadius
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Applies to all background blur settings"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSlider {
                id: customBlurRadius
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableCustomBlurRadius
                title: "Blur Radius (Grid Unit)"
                minimumValue: 0.1
                maximumValue: 10
                stepSize: 0.1
                resetValue: 4
                live: false
                roundValue: true
                roundingDecimal: 1
                enableFineControls: true
                unitsLabel: "gu"
                onValueChanged: shell.settings.customBlurRadius = value
                Binding {
                    target: customBlurRadius
                    property: "value"
                    value: shell.settings.customBlurRadius
                }
            }
            LPSettingsCheckBox {
                id: enableSlimVolume
                Layout.fillWidth: true
                text: "Slim slider notification bubble"
                onCheckedChanged: shell.settings.enableSlimVolume = checked
                Binding {
                    target: enableSlimVolume
                    property: "checked"
                    value: shell.settings.enableSlimVolume
                }
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Auto Dark Mode"
                onClicked: settingsLoader.item.stack.push(autoDarkModePage, {"title": text})
            }
        }
    }
    Component {
        id: accessibilityPage
        
        LPSettingsPage {
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "App Lifecycle"
                onClicked: settingsLoader.item.stack.push(lifecyclePage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Abot Kamay"
                onClicked: settingsLoader.item.stack.push(pullDownPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Auto-Brightness DIY"
                onClicked: settingsLoader.item.stack.push(autoBrightnessPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Battery Statistics"
                onClicked: settingsLoader.item.stack.push(batteryStatsPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Color Overlay"
                onClicked: settingsLoader.item.stack.push(colorOverlayPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Fully Charged Alarm"
                onClicked: settingsLoader.item.stack.push(chargingAlarmPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Quick Actions"
                onClicked: settingsLoader.item.stack.push(directActionsPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Sensor Gestures"
                onClicked: settingsLoader.item.stack.push(sensorGesturesPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Wake up Alarms"
                onClicked: settingsLoader.item.stack.push(alarmWakePage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Waydroid Gestures"
                onClicked: settingsLoader.item.stack.push(waydroidGesturesPage, {"title": text})
            }
            LPSettingsSwitch {
                id: enableHaptics
                Layout.fillWidth: true
                text: "Enable haptics"
                onCheckedChanged: shell.settings.enableHaptics = checked
                Binding {
                    target: enableHaptics
                    property: "checked"
                    value: shell.settings.enableHaptics
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Haptics feedback for button presses and swipe gestures\n"
                + "Only applies to some controls and not all"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsCheckBox {
                id: enableShowDesktop
                Layout.fillWidth: true
                text: "Show desktop in App Spread (Swipe Up)"
                onCheckedChanged: shell.settings.enableShowDesktop = checked
                Binding {
                    target: enableShowDesktop
                    property: "checked"
                    value: shell.settings.enableShowDesktop
                }
            }
            LPSettingsCheckBox {
                id: enableVolumeButtonsLogic
                Layout.fillWidth: true
                text: "Disable volume buttons when screen is off"
                onCheckedChanged: shell.settings.enableVolumeButtonsLogic = checked
                Binding {
                    target: enableVolumeButtonsLogic
                    property: "checked"
                    value: shell.settings.enableVolumeButtonsLogic
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Volume buttons will be disabled when screen is off but they will still work if there's an ongoing call or a media is playing."
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsCheckBox {
                id: disableVolumeWhenCamera
                Layout.fillWidth: true
                text: "Disable volume buttons when camera app is in the foreground"
                onCheckedChanged: shell.settings.disableVolumeWhenCamera = checked
                Binding {
                    target: disableVolumeWhenCamera
                    property: "checked"
                    value: shell.settings.disableVolumeWhenCamera
                }
            }
            LPSettingsCheckBox {
                id: pauseMediaOnBluetoothAudioDisconnect
                Layout.fillWidth: true
                text: "Pause media upon bluetooth audio disconnect"
                onCheckedChanged: shell.settings.pauseMediaOnBluetoothAudioDisconnect = checked
                Binding {
                    target: pauseMediaOnBluetoothAudioDisconnect
                    property: "checked"
                    value: shell.settings.pauseMediaOnBluetoothAudioDisconnect
                }
            }
            LPSettingsCheckBox {
                id: enableSilentScreenshot
                Layout.fillWidth: true
                text: "Silent screenshot"
                onCheckedChanged: shell.settings.enableSilentScreenshot = checked
                Binding {
                    target: enableSilentScreenshot
                    property: "checked"
                    value: shell.settings.enableSilentScreenshot
                }
            }
            LPColorField {
                id: touchVisualColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Touch visuals color"
                visible: shell.settings.touchVisualColor
                onTextChanged: shell.settings.touchVisualColor = text
                onColorPicker: colorPickerLoader.open(touchVisualColor)
                Binding {
                    target: touchVisualColor
                    property: "text"
                    value: shell.settings.touchVisualColor
                }
            }
        }
    }
    Component {
        id: waydroidGesturesPage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "This would disable a portion of the left/right edge gestures whenever Waydroid is the focused app."
                + " This could help using gestures-based navigation in Waydroid while still be able to use native edge gestures."
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsCheckBox {
                id: disableRigheEdgeForWaydroid
                Layout.fillWidth: true
                text: "Disable Right Edge"
                onCheckedChanged: shell.settings.disableRigheEdgeForWaydroid = checked
                Binding {
                    target: disableRigheEdgeForWaydroid
                    property: "checked"
                    value: shell.settings.disableRigheEdgeForWaydroid
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.disableRigheEdgeForWaydroid
                text: i18n.tr("Right Edge Section")
                model: [
                    i18n.tr("Top"),
                    i18n.tr("Bottom")
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.disableRigheEdgeForWaydroidEdge
                onSelectedIndexChanged: shell.settings.disableRigheEdgeForWaydroidEdge = selectedIndex
            }
            LPSettingsSlider {
                id: disableRigheEdgeForWaydroidHeight
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.disableRigheEdgeForWaydroid
                title: "Right Edge Height percentage"
                minimumValue: 1
                maximumValue: 100
                stepSize: 5
                resetValue: 50
                live: true
                enableFineControls: true
                percentageValue: true
                valueIsPercentage: true
                roundValue: true
                onValueChanged: shell.settings.disableRigheEdgeForWaydroidHeight = value
                Binding {
                    target: disableRigheEdgeForWaydroidHeight
                    property: "value"
                    value: shell.settings.disableRigheEdgeForWaydroidHeight
                }
            }
            LPSettingsCheckBox {
                id: disableLeftEdgeForWaydroid
                Layout.fillWidth: true
                text: "Disable Left Edge"
                onCheckedChanged: shell.settings.disableLeftEdgeForWaydroid = checked
                Binding {
                    target: disableLeftEdgeForWaydroid
                    property: "checked"
                    value: shell.settings.disableLeftEdgeForWaydroid
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.disableLeftEdgeForWaydroid
                text: i18n.tr("Left Edge Section")
                model: [
                    i18n.tr("Top"),
                    i18n.tr("Bottom")
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.disableLeftEdgeForWaydroidEdge
                onSelectedIndexChanged: shell.settings.disableLeftEdgeForWaydroidEdge = selectedIndex
            }
            LPSettingsSlider {
                id: disableLeftEdgeForWaydroidHeight
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.disableLeftEdgeForWaydroid
                title: "Left Edge Height percentage"
                minimumValue: 1
                maximumValue: 100
                stepSize: 5
                resetValue: 50
                live: true
                enableFineControls: true
                percentageValue: true
                valueIsPercentage: true
                roundValue: true
                onValueChanged: shell.settings.disableLeftEdgeForWaydroidHeight = value
                Binding {
                    target: disableLeftEdgeForWaydroidHeight
                    property: "value"
                    value: shell.settings.disableLeftEdgeForWaydroidHeight
                }
            }
        }
    }
    Component {
        id: autoBrightnessPage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "System auto brightness must be disabled for this to take effect.\n"
                + "Brightness will adjust once the light sensor value reaches the next higher value in the data you set below."
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSwitch {
                id: enableCustomAutoBrightness
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: shell.settings.enableCustomAutoBrightness = checked
                Binding {
                    target: enableCustomAutoBrightness
                    property: "checked"
                    value: shell.settings.enableCustomAutoBrightness
                }
            }
            LPSettingsCheckBox {
                id: tryToStabilizeAutoBrightness
                Layout.fillWidth: true
                text: "Try to stablize by not allowing changes for a few seconds"
                onCheckedChanged: shell.settings.tryToStabilizeAutoBrightness = checked
                Binding {
                    target: tryToStabilizeAutoBrightness
                    property: "checked"
                    value: shell.settings.tryToStabilizeAutoBrightness
                }
            }
            Button {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                Layout.rightMargin: units.gu(2)
                Layout.topMargin: units.gu(1)
                Layout.bottomMargin: units.gu(1)

                text: "Add data"
                color: theme.palette.normal.positive
                onClicked: {
                    // Do not use PopupUtils to fix orientation issues
                    let _dialogAdd = addAutoBrightnessDialog.createObject(shell.popupParent);

                    let _addNewAutoBrightnessData = function (_lightValue, _brightnessValue) {
                        let _tempArr = shell.settings.customAutoBrightnessData.slice()
                        let _itemData = {
                            light: _lightValue
                            , brightness: parseFloat(_brightnessValue.toFixed(2))
                        }
                        _tempArr.push(_itemData)
                        _tempArr.sort((a, b) => a.light - b.light)
                        shell.settings.customAutoBrightnessData = _tempArr.slice()
                    }

                    _dialogAdd.add.connect(_addNewAutoBrightnessData)
                    _dialogAdd.show()
                }
            }
            ListView {
                id: autoBrightnessListView

                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight

                interactive: false
                model: shell.settings.customAutoBrightnessData

                delegate: ListItem {
                    id: listItem

                    property int actionIndex: index
                    property int lightValue: modelData.light
                    property real brightnessValue: modelData.brightness

                    height: layout.height + (divider.visible ? divider.height : 0)
                    color: dragging ? theme.palette.selected.base : "transparent"

                    ListItemLayout {
                        id: layout
                        title.text: i18n.tr("Light: %1").arg(listItem.lightValue)
                        title.wrapMode: Text.WordWrap

                        Label {
                            text: i18n.tr("Brightness: %1%").arg(listItem.brightnessValue * 100)
                            wrapMode: Text.WordWrap
                            SlotsLayout.position: SlotsLayout.Trailing
                        }
                    }

                    leadingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "delete"
                                onTriggered: {
                                    let _arrNewValues = shell.settings.customAutoBrightnessData.slice()
                                    _arrNewValues.splice(listItem.actionIndex, 1)
                                    shell.settings.customAutoBrightnessData = _arrNewValues.slice()
                                }
                            }
                        ]
                    }
                }

                Component {
                    id: addAutoBrightnessDialog

                    Dialog {
                        id: autoBrightnessDialog

                        readonly property int lightValue: lightTextField.isValid ? lightTextField.value : 0
                        readonly property real brightnessValue: brightnessSliderClone.value
                        property bool systemAutoBrightness: false

                        signal add(int lightValue, real brightnessValue)
                        signal close

                        onAdd: close()

                        property bool reparentToRootItem: false

                        title: "New Auto-brightness Data"
                        anchorToKeyboard: false // Handle the keyboard anchor via shell.popupParent

                        Component.onCompleted: {
                            autoBrightnessLoader.temporaryDisable = true

                            autoBrightnessDialog.systemAutoBrightness = panel.indicators.autoBrightnessToggle ? panel.indicators.autoBrightnessToggle.checked : false

                            // Disable system auto brightness while this dialog is displayed
                            if (panel.indicators.autoBrightnessToggle && panel.indicators.autoBrightnessToggle.checked) {
                                panel.indicators.autoBrightnessToggle.clicked()
                            }
                        }

                        onClose: {
                            autoBrightnessLoader.temporaryDisable = false
                            
                            // Restore system auto brightness settings after the dialog is closed
                            if (panel.indicators.autoBrightnessToggle && autoBrightnessDialog.systemAutoBrightness !== panel.indicators.autoBrightnessToggle.checked) {
                                panel.indicators.autoBrightnessToggle.clicked()
                            }
                            PopupUtils.close(autoBrightnessDialog)
                        }

                        TextField {
                            id: lightTextField

                            function isNumber(n) {
                                return !isNaN(parseFloat(n)) && isFinite(n);
                            }

                            readonly property bool isValid: isNumber(text) && value >= 0
                            readonly property int value: Number(text)

                            text: "0"
                            placeholderText: "Light Sensor Value"
                            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhDigitsOnly 
                        }
                        Label {
                            visible: !lightTextField.isValid
                            text: "Please enter a valid number"
                            color: theme.palette.normal.negative
                        }
                        RowLayout {
                            Label {
                                id: currentLightValueLabel

                                readonly property int currentValue: lightSensor.reading.illuminance >= 0 ? lightSensor.reading.illuminance : -1
                                Layout.fillWidth: true
                                text: i18n.tr("Current light value: %1").arg(currentValue)
                            }
                            QQC2.ToolButton {
                                Layout.fillHeight: true
                                icon.width: units.gu(2)
                                icon.height: units.gu(2)
                                action: QQC2.Action {
                                    icon.name:  "go-up"
                                    onTriggered: lightTextField.text = currentLightValueLabel.currentValue
                                }
                            }
                        }
                        LPSettingsSlider {
                            id: brightnessSliderClone

                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            Layout.topMargin: units.gu(4)
                            title: "Brightness value"
                            locked: false
                            minimumValue: 0
                            maximumValue: 1
                            stepSize: 0.01
                            resetValue: 0.5
                            live: true
                            roundValue: true
                            roundingDecimal: 2
                            enableFineControls: true
                            percentageValue: true
                            valueIsPercentage: false
                            onValueChanged: if (shell.brightnessSlider) shell.brightnessSlider.value = value
                            Binding {
                                target: brightnessSliderClone
                                property: "value"
                                value: shell.brightnessSlider.value
                            }
                        }

                        Button {
                            text: "Add"
                            color: theme.palette.normal.positive
                            enabled: lightTextField.isValid

                            onClicked: {
                                let _lightValue = autoBrightnessDialog.lightValue
                                let _brightnessValue = autoBrightnessDialog.brightnessValue

                                autoBrightnessDialog.add(_lightValue, _brightnessValue)
                            }
                        }
                        Button {
                            text: "Cancel"
                            onClicked: autoBrightnessDialog.close()
                        }
                    }
                }
            }
        }
    }
    Component {
        id: alarmWakePage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "When this is enabled, your wake up alarms will be disabled until the next day once you tell that you're awake from the lockscreen. You must set a prefix to identify your wake up alarms."
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSwitch {
                id: enableImAwake
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: shell.settings.enableImAwake = checked
                Binding {
                    target: enableImAwake
                    property: "checked"
                    value: shell.settings.enableImAwake
                }
            }
            TextField {
                id: wakeUpAlarmPrefix

                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                placeholderText: "Alarm Prefix"
                visible: shell.settings.enableImAwake
                inputMethodHints: Qt.ImhNoPredictiveText
                onTextChanged: shell.settings.wakeUpAlarmPrefix = text
                Binding {
                    target: wakeUpAlarmPrefix
                    property: "text"
                    value: shell.settings.wakeUpAlarmPrefix
                }
            }
        }
    }
    Component {
        id: lifecyclePage
        
        LPSettingsPage {
            LPSettingsSwitch {
                id: enableDelayedStartingAppSuspension
                Layout.fillWidth: true
                text: "Delay app suspension upon opening"
                onCheckedChanged: shell.settings.enableDelayedStartingAppSuspension = checked
                Binding {
                    target: enableDelayedStartingAppSuspension
                    property: "checked"
                    value: shell.settings.enableDelayedStartingAppSuspension
                }
            }
            LPSettingsSlider {
                id: delayedStartingAppSuspensionDuration
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDelayedStartingAppSuspension
                title: "Delay Duration"
                minimumValue: 0.1
                maximumValue: 20
                stepSize: 0.5
                resetValue: 5
                live: true
                roundValue: true
                roundingDecimal: 1
                enableFineControls: true
                unitsLabel: "seconds"
                onValueChanged: shell.settings.delayedStartingAppSuspensionDuration = value
                Binding {
                    target: delayedStartingAppSuspensionDuration
                    property: "value"
                    value: shell.settings.delayedStartingAppSuspensionDuration
                }
            }
            LPSettingsSwitch {
                id: enableDelayedAppSuspension
                Layout.fillWidth: true
                text: "Delay app suspension"
                onCheckedChanged: shell.settings.enableDelayedAppSuspension = checked
                Binding {
                    target: enableDelayedAppSuspension
                    property: "checked"
                    value: shell.settings.enableDelayedAppSuspension
                }
            }
            LPSettingsSlider {
                id: delayedAppSuspensionDuration
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDelayedAppSuspension
                title: "Delay Duration"
                minimumValue: 0.1
                maximumValue: 60
                stepSize: 0.5
                resetValue: 5
                live: true
                roundValue: true
                roundingDecimal: 1
                enableFineControls: true
                unitsLabel: "seconds"
                onValueChanged: shell.settings.delayedAppSuspensionDuration = value
                Binding {
                    target: delayedAppSuspensionDuration
                    property: "value"
                    value: shell.settings.delayedAppSuspensionDuration
                }
            }
        }
    }
    Component {
        id: convergencePage
        
        LPSettingsPage {
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Staged Mode"
                onClicked: settingsLoader.item.stack.push(stagedModePage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Windowed Mode"
                onClicked: settingsLoader.item.stack.push(windowedModePage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "External Display"
                onClicked: settingsLoader.item.stack.push(externalDisplayPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Mouse"
                onClicked: settingsLoader.item.stack.push(mousePage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Key Shortcuts"
                onClicked: settingsLoader.item.stack.push(keyShortcutsPage, {"title": text})
            }
        }
    }
    Component {
        id: windowedModePage

        LPSettingsPage {
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Window Snapping"
                onClicked: settingsLoader.item.stack.push(windowSnappingPage, {"title": text})
            }
            LPSettingsCheckBox {
                id: delayedWorkspaceSwitcherUI
                Layout.fillWidth: true
                text: "Delay showing Workspace Switcher UI"
                onCheckedChanged: shell.settings.delayedWorkspaceSwitcherUI = checked
                Binding {
                    target: delayedWorkspaceSwitcherUI
                    property: "checked"
                    value: shell.settings.delayedWorkspaceSwitcherUI
                }
            }
        }
    }
    Component {
        id: windowSnappingPage

        LPSettingsPage {
            LPSettingsCheckBox {
                id: replaceHorizontalVerticalSnappingWithBottomTop
                Layout.fillWidth: true
                text: "Replace Horizontal & Vertical snap with Top and Bottom"
                onCheckedChanged: shell.settings.replaceHorizontalVerticalSnappingWithBottomTop = checked
                Binding {
                    target: replaceHorizontalVerticalSnappingWithBottomTop
                    property: "checked"
                    value: shell.settings.replaceHorizontalVerticalSnappingWithBottomTop
                }
            }
            LPSettingsCheckBox {
                id: enableAdvancedKeyboardSnapping
                Layout.fillWidth: true
                text: "Use advanced behavior that supports quarter snapping"
                onCheckedChanged: shell.settings.enableAdvancedKeyboardSnapping = checked
                Binding {
                    target: enableAdvancedKeyboardSnapping
                    property: "checked"
                    value: shell.settings.enableAdvancedKeyboardSnapping
                }
            }
            LPSettingsCheckBox {
                id: onlyCommitOnReleaseWhenKeyboardSnapping
                Layout.fillWidth: true
                text: "Only commit window snapping upon key release"
                onCheckedChanged: shell.settings.onlyCommitOnReleaseWhenKeyboardSnapping = checked
                Binding {
                    target: onlyCommitOnReleaseWhenKeyboardSnapping
                    property: "checked"
                    value: shell.settings.onlyCommitOnReleaseWhenKeyboardSnapping
                }
            }
        }
    }
    Component {
        id: sensorGesturesPage

        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "CAUTION! These gestures may be unreliable, inconsistent and prone to accidental triggering and will also depend on your device\n\n"
                + "Test each gesture first and see how well they work. Combination of gestures that involves physically moving your device may also cause conflicts when triggering.\n\n"
                + "Some actions such as toggling the flashlight may be dangerous to your device if triggered unknowingly or accidentally.\n\n"
                + "Description of each gesture can be found here: \n"
                + "<a>https://doc.qt.io/qt-5/sensorgesture-plugins-topics.html#qt-sensor-gestures</a>"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSwitch {
                id: enableSensorGestures
                Layout.fillWidth: true
                text: "Enable (May affect standby battery)"
                onCheckedChanged: shell.settings.enableSensorGestures = checked
                Binding {
                    target: enableSensorGestures
                    property: "checked"
                    value: shell.settings.enableSensorGestures
                }
            }
            LPSettingsSwitch {
                id: enableSensorGesturesOnlyWhenScreenOn
                Layout.fillWidth: true
                text: "Disable when screen is off (improves battery)"
                visible: shell.settings.enableSensorGestures
                onCheckedChanged: shell.settings.enableSensorGesturesOnlyWhenScreenOn = checked
                Binding {
                    target: enableSensorGesturesOnlyWhenScreenOn
                    property: "checked"
                    value: shell.settings.enableSensorGesturesOnlyWhenScreenOn
                }
            }
            property var sensorGestureActions: [
                "None"
                , "Toggle Media Playback"
                , "Pause Media Playback"
                , "Toggle Flashlight"
                , "Toggle Orientation"
                , "Lock Screen"
                , "Show Desktop"
                , "Toggle Screen"
            ]
            LPSettingsSwitch {
                id: enableCoverGesture
                Layout.fillWidth: true
                visible: shell.settings.enableSensorGestures
                text: i18n.tr("Cover")
                onCheckedChanged: shell.settings.enableCoverGesture = checked
                Binding {
                    target: enableCoverGesture
                    property: "checked"
                    value: shell.settings.enableCoverGesture
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableSensorGestures && shell.settings.enableCoverGesture
                model: sensorGestureActions
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.coverGestureAction
                onSelectedIndexChanged: shell.settings.coverGestureAction = selectedIndex
            }
            LPSettingsSwitch {
                id: enableShakeGesture
                Layout.fillWidth: true
                visible: shell.settings.enableSensorGestures
                text: i18n.tr("Shake")
                onCheckedChanged: shell.settings.enableShakeGesture = checked
                Binding {
                    target: enableShakeGesture
                    property: "checked"
                    value: shell.settings.enableShakeGesture
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableSensorGestures && shell.settings.enableShakeGesture
                model: sensorGestureActions
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.shakeGestureAction
                onSelectedIndexChanged: shell.settings.shakeGestureAction = selectedIndex
            }
            LPSettingsSwitch {
                id: enableShake2Gesture
                Layout.fillWidth: true
                visible: shell.settings.enableSensorGestures
                text: i18n.tr("Shake2")
                onCheckedChanged: shell.settings.enableShake2Gesture = checked
                Binding {
                    target: enableShake2Gesture
                    property: "checked"
                    value: shell.settings.enableShake2Gesture
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableSensorGestures && shell.settings.enableShake2Gesture
                model: sensorGestureActions
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.shake2GestureAction
                onSelectedIndexChanged: shell.settings.shake2GestureAction = selectedIndex
            }
            LPSettingsSwitch {
                id: enablePickupGesture
                Layout.fillWidth: true
                visible: shell.settings.enableSensorGestures
                text: i18n.tr("Pickup")
                onCheckedChanged: shell.settings.enablePickupGesture = checked
                Binding {
                    target: enablePickupGesture
                    property: "checked"
                    value: shell.settings.enablePickupGesture
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableSensorGestures && shell.settings.enablePickupGesture
                model: sensorGestureActions
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.pickupGestureAction
                onSelectedIndexChanged: shell.settings.pickupGestureAction = selectedIndex
            }
            LPSettingsSwitch {
                id: enableSlamGesture
                Layout.fillWidth: true
                visible: shell.settings.enableSensorGestures
                text: i18n.tr("Slam")
                onCheckedChanged: shell.settings.enableSlamGesture = checked
                Binding {
                    target: enableSlamGesture
                    property: "checked"
                    value: shell.settings.enableSlamGesture
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableSensorGestures && shell.settings.enableSlamGesture
                model: sensorGestureActions
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.slamGestureAction
                onSelectedIndexChanged: shell.settings.slamGestureAction = selectedIndex
            }
            LPSettingsSwitch {
                id: enableTurnoverGesture
                Layout.fillWidth: true
                visible: shell.settings.enableSensorGestures
                text: i18n.tr("Turnover")
                onCheckedChanged: shell.settings.enableTurnoverGesture = checked
                Binding {
                    target: enableTurnoverGesture
                    property: "checked"
                    value: shell.settings.enableTurnoverGesture
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableSensorGestures && shell.settings.enableTurnoverGesture
                model: sensorGestureActions
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.turnoverGestureAction
                onSelectedIndexChanged: shell.settings.turnoverGestureAction = selectedIndex
            }
            LPSettingsSwitch {
                id: enableTwistGesture
                Layout.fillWidth: true
                visible: shell.settings.enableSensorGestures
                text: i18n.tr("Twist")
                onCheckedChanged: shell.settings.enableTwistGesture = checked
                Binding {
                    target: enableTwistGesture
                    property: "checked"
                    value: shell.settings.enableTwistGesture
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableSensorGestures && shell.settings.enableTwistGesture
                model: sensorGestureActions
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.twistGestureAction
                onSelectedIndexChanged: shell.settings.twistGestureAction = selectedIndex
            }
            LPSettingsSwitch {
                id: enableWhipGesture
                Layout.fillWidth: true
                visible: shell.settings.enableSensorGestures
                text: i18n.tr("Whip")
                onCheckedChanged: shell.settings.enableWhipGesture = checked
                Binding {
                    target: enableWhipGesture
                    property: "checked"
                    value: shell.settings.enableWhipGesture
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableSensorGestures && shell.settings.enableWhipGesture
                model: sensorGestureActions
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.whipGestureAction
                onSelectedIndexChanged: shell.settings.whipGestureAction = selectedIndex
            }
        }
    }
    Component {
        id: stagedModePage
        
        LPSettingsPage {
            LPSettingsSwitch {
                id: enableSideStage
                Layout.fillWidth: true
                text: "Side-Stage"
                onCheckedChanged: shell.settings.enableSideStage = checked
                Binding {
                    target: enableSideStage
                    property: "checked"
                    value: shell.settings.enableSideStage
                }
            }
            LPSettingsCheckBox {
                id: forceEnableWorkspace
                Layout.fillWidth: true
                text: "Enable workspaces in Staged mode"
                onCheckedChanged: lomiriSettings.forceEnableWorkspace = checked
                Binding {
                    target: forceEnableWorkspace
                    property: "checked"
                    value: lomiriSettings.forceEnableWorkspace
                }
            }
            
        }
    }
    Component {
        id: externalDisplayPage

        LPSettingsPage {
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: i18n.tr("Behavior")
                model: [
                    i18n.tr("Virtual Touchpad")
                    , i18n.tr("Multi-display")
                    //, i18n.tr("Mirrored")
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.externalDisplayBehavior
                onSelectedIndexChanged: shell.settings.externalDisplayBehavior = selectedIndex
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Air Mouse"
                onClicked: settingsLoader.item.stack.push(airMousePage, {"title": text})
            }
            LPSettingsCheckBox {
                id: lowestBrightnessWhenTouchpadMode
                Layout.fillWidth: true
                enabled: shell.settings.enableCustomAutoBrightness
                text: "Maintain custom brightness when in virtual touchpad mode"
                onCheckedChanged: shell.settings.lowestBrightnessWhenTouchpadMode = checked
                Binding {
                    target: lowestBrightnessWhenTouchpadMode
                    property: "checked"
                    value: shell.settings.lowestBrightnessWhenTouchpadMode
                }
            }
            LPSettingsSlider {
                id: brightnessWhenTouchpadMode
                Layout.fillWidth: true
                Layout.margins: units.gu(4)
                visible: lowestBrightnessWhenTouchpadMode.visible
                title: "Custom brightness"
                minimumValue: 0
                maximumValue: 50
                stepSize: 5
                resetValue: 1
                live: false
                enableFineControls: true
                roundValue: true
                unitsLabel: "%"
                onValueChanged: shell.settings.brightnessWhenTouchpadMode = value
                Binding {
                    target: brightnessWhenTouchpadMode
                    property: "value"
                    value: shell.settings.brightnessWhenTouchpadMode
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                visible: lowestBrightnessWhenTouchpadMode.visible
                text: "Requires Auto-Brightness DIY to be enabled. Normal auto-brightness behavior will occur when the on-screen keyboard is displayed."
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
        }
    }
    Component {
        id: mousePage
        
        LPSettingsPage {
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Hot Corners"
                onClicked: settingsLoader.item.stack.push(hotcornersPage, {"title": text})
            }
            LPSettingsCheckBox {
                id: disableLeftEdgeMousePush
                Layout.fillWidth: true
                text: "Disable left mouse push (Launcher/Drawer)"
                onCheckedChanged: shell.settings.disableLeftEdgeMousePush = checked
                Binding {
                    target: disableLeftEdgeMousePush
                    property: "checked"
                    value: shell.settings.disableLeftEdgeMousePush
                }
            }
            LPSettingsCheckBox {
                id: disableRightEdgeMousePush
                Layout.fillWidth: true
                text: "Disable right mouse push (App spread)"
                onCheckedChanged: shell.settings.disableRightEdgeMousePush = checked
                Binding {
                    target: disableRightEdgeMousePush
                    property: "checked"
                    value: shell.settings.disableRightEdgeMousePush
                }
            }
            LPSettingsCheckBox {
                id: lessSensitiveEdgeBarriers
                Layout.fillWidth: true
                text: "Less sensitive edge barriers (Edges would require more push)"
                onCheckedChanged: shell.settings.lessSensitiveEdgeBarriers = checked
                Binding {
                    target: lessSensitiveEdgeBarriers
                    property: "checked"
                    value: shell.settings.lessSensitiveEdgeBarriers
                }
            }
            LPSettingsCheckBox {
                id: biggerCursorInExternalDisplay
                Layout.fillWidth: true
                text: "Bigger cursor on external displays"
                onCheckedChanged: shell.settings.biggerCursorInExternalDisplay = checked
                Binding {
                    target: biggerCursorInExternalDisplay
                    property: "checked"
                    value: shell.settings.biggerCursorInExternalDisplay
                }
            }
            LPSettingsCheckBox {
                id: biggerCursorInExternalDisplayOnlyAirMouse
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                visible: biggerCursorInExternalDisplay.visible
                text: "Only when in Air Mouse mode"
                onCheckedChanged: shell.settings.biggerCursorInExternalDisplayOnlyAirMouse = checked
                Binding {
                    target: biggerCursorInExternalDisplayOnlyAirMouse
                    property: "checked"
                    value: shell.settings.biggerCursorInExternalDisplayOnlyAirMouse
                }
            }
            LPSettingsSlider {
                id: biggerCursorInExternalDisplaySize
                Layout.fillWidth: true
                Layout.margins: units.gu(4)
                visible: biggerCursorInExternalDisplay.visible
                title: "Scale"
                minimumValue: 1.25
                maximumValue: 5
                stepSize: 0.25
                resetValue: 2
                live: false
                roundValue: true
                roundingDecimal: 2
                enableFineControls: true
                unitsLabel: "x"
                onValueChanged: shell.settings.biggerCursorInExternalDisplaySize = value
                Binding {
                    target: biggerCursorInExternalDisplaySize
                    property: "value"
                    value: shell.settings.biggerCursorInExternalDisplaySize
                }
            }
        }
    }
    Component {
        id: keyShortcutsPage

        LPSettingsPage {
            LPSettingsCheckBox {
                id: disableKeyboardShortcutsOverlay
                Layout.fillWidth: true
                text: "Disable shortcuts overlay when long pressing Super"
                onCheckedChanged: shell.settings.disableKeyboardShortcutsOverlay = checked
                Binding {
                    target: disableKeyboardShortcutsOverlay
                    property: "checked"
                    value: shell.settings.disableKeyboardShortcutsOverlay
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Ctrl + Period"
                wrapMode: Text.WordWrap
                textSize: Label.Large
            }
            LPSettingsCheckBox {
                id: enableOSKToggleKeyboardShortcut
                Layout.fillWidth: true
                text: "Toggle OSK when physical keyboard is present"
                onCheckedChanged: shell.settings.enableOSKToggleKeyboardShortcut = checked
                Binding {
                    target: enableOSKToggleKeyboardShortcut
                    property: "checked"
                    value: shell.settings.enableOSKToggleKeyboardShortcut
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Camera Key function"
                wrapMode: Text.WordWrap
                textSize: Label.Large
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "This will only work if the camera key is properly mapped in your device's port"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsCheckBox {
                id: pro1_orientationToggleKey
                Layout.fillWidth: true
                text: "Use to toggle orientation"
                onCheckedChanged: shell.settings.pro1_orientationToggleKey = checked
                Binding {
                    target: pro1_orientationToggleKey
                    property: "checked"
                    value: shell.settings.pro1_orientationToggleKey
                }
            }
            LPSettingsCheckBox {
                id: enableCameraKeyDoublePress
                Layout.fillWidth: true
                visible: shell.settings.pro1_orientationToggleKey
                text: "Enable single/double press to toggle rotation and OSK"
                onCheckedChanged: shell.settings.enableCameraKeyDoublePress = checked
                Binding {
                    target: enableCameraKeyDoublePress
                    property: "checked"
                    value: shell.settings.enableCameraKeyDoublePress
                }
            }
            LPSettingsCheckBox {
                id: reversedCameraKeyDoubePress
                Layout.fillWidth: true
                visible: enableCameraKeyDoublePress.visible && shell.settings.enableCameraKeyDoublePress
                text: "Reverse single and double press functions"
                onCheckedChanged: shell.settings.reversedCameraKeyDoubePress = checked
                Binding {
                    target: reversedCameraKeyDoubePress
                    property: "checked"
                    value: shell.settings.reversedCameraKeyDoubePress
                }
            }
            LPSettingsSlider {
                id: cameraKeyDoublePressDelay
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: enableCameraKeyDoublePress.visible && shell.settings.enableCameraKeyDoublePress
                title: "Double press delay"
                minimumValue: 100
                maximumValue: 1000
                stepSize: 50
                resetValue: 300
                live: false
                roundValue: true
                unitsLabel: "ms"
                onValueChanged: shell.settings.cameraKeyDoublePressDelay = value
                Binding {
                    target: cameraKeyDoublePressDelay
                    property: "value"
                    value: shell.settings.cameraKeyDoublePressDelay
                }
            }
        }
    }
    Component {
        id: outerWildsPage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                color: theme.palette.normal.negative
                text: "Consumes a lot of memory and may crash Lomiri especially the Solar System theme. Settings is non-persistent to avoid being stuck."
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSwitch {
                id: owTheme
                Layout.fillWidth: true
                text: "Enable Theme"
                onCheckedChanged: shell.settings.enableOW = checked
                Binding {
                    target: owTheme
                    property: "checked"
                    value: shell.settings.enableOW
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: i18n.tr("Theme")
                model: [
                    i18n.tr("Main Menu"),
                    i18n.tr("Solar System"),
                    i18n.tr("Sealed Vault")
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.ow_theme
                onSelectedIndexChanged: shell.settings.ow_theme = selectedIndex
            }
            LPSettingsSlider {
                id: ow_qmChance
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableOW && shell.settings.ow_theme == 0
                title: "Quantum Luck"
                minimumValue: 1
                maximumValue: 500
                stepSize: 1
                resetValue: 10
                live: false
                roundValue: true
                enableFineControls: true
                onValueChanged: shell.settings.ow_qmChance = value
                Binding {
                    target: ow_qmChance
                    property: "value"
                    value: shell.settings.ow_qmChance
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                visible: shell.settings.enableOW && shell.settings.ow_theme == 0
                text: "Higher value means lesser chance to see the Quantum moon upon unlocking (i.e. 100 means your chance is 1 in a hundred)"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSwitch {
                id: eyeFPMarker
                Layout.fillWidth: true
                text: "Eye Fingerprint Marker"
                onCheckedChanged: shell.settings.enableEyeFP = checked
                Binding {
                    target: eyeFPMarker
                    property: "checked"
                    value: shell.settings.enableEyeFP
                }
            }
            LPSettingsCheckBox {
                id: ow_showSolarSystemOnDesktop
                Layout.fillWidth: true
                text: "Display Solar System on the Desktop"
                onCheckedChanged: shell.settings.ow_showSolarSystemOnDesktop = checked
                Binding {
                    target: ow_showSolarSystemOnDesktop
                    property: "checked"
                    value: shell.settings.ow_showSolarSystemOnDesktop
                }
            }
            LPSettingsCheckBox {
                id: ow_showSolarSystemOnDesktopRunAllTime
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                visible: shell.settings.ow_showSolarSystemOnDesktop
                text: "Run all the time without pausing"
                onCheckedChanged: shell.settings.ow_showSolarSystemOnDesktopRunAllTime = checked
                Binding {
                    target: ow_showSolarSystemOnDesktopRunAllTime
                    property: "checked"
                    value: shell.settings.ow_showSolarSystemOnDesktopRunAllTime
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                visible: ow_showSolarSystemOnDesktopRunAllTime.visible && shell.settings.ow_showSolarSystemOnDesktopRunAllTime
                text: "Solar system will run all the time, even when device is locked or when it's not physically visible. This may drain battery more."
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsCheckBox {
                id: ow_ColoredClock
                Layout.fillWidth: true
                text: "Themed Lockscreen Clock"
                onCheckedChanged: shell.settings.ow_ColoredClock = checked
                Binding {
                    target: ow_ColoredClock
                    property: "checked"
                    value: shell.settings.ow_ColoredClock
                }
            }
            LPSettingsCheckBox {
                id: ow_GradientColoredTime
                Layout.fillWidth: true
                text: "Gradient Time Text"
                onCheckedChanged: shell.settings.ow_GradientColoredTime = checked
                Binding {
                    target: ow_GradientColoredTime
                    property: "checked"
                    value: shell.settings.ow_GradientColoredTime
                }
            }
            LPSettingsCheckBox {
                id: ow_GradientColoredDate
                Layout.fillWidth: true
                text: "Gradient Date Text"
                onCheckedChanged: shell.settings.ow_GradientColoredDate = checked
                Binding {
                    target: ow_GradientColoredDate
                    property: "checked"
                    value: shell.settings.ow_GradientColoredDate
                }
            }
            LPSettingsCheckBox {
                id: ow_mainMenu
                Layout.fillWidth: true
                text: "Main Menu"
                onCheckedChanged: shell.settings.ow_mainMenu = checked
                Binding {
                    target: ow_mainMenu
                    property: "checked"
                    value: shell.settings.ow_mainMenu
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: i18n.tr("Logo")
                model: [
                    i18n.tr("Disabled")
                    ,i18n.tr("Brittle Hollow")
                    ,i18n.tr("Dark Bramble")
                    ,i18n.tr("Hourglass Twins")
                    ,i18n.tr("Interloper")
                    ,i18n.tr("Nomai Eye")
                    ,i18n.tr("Quantum Moon")
                    ,i18n.tr("Stranger Eye")
                    ,i18n.tr("Sun")
                    ,i18n.tr("Timber Hearth")
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.ow_bfbLogo
                onSelectedIndexChanged: shell.settings.ow_bfbLogo = selectedIndex
            }
        }
    }
    Component {
        id: deviceSpecificPage
        
        LPSettingsPage {
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Fxtec Pro1-X"
                onClicked: settingsLoader.item.stack.push(pro1Page, {"title": text})
            }

            LPSettingsCheckBox {
                id: enableBottomSwipeDeviceFix
                Layout.fillWidth: true
                text: "Edge swipe fix (rotate to take effect)"
                onCheckedChanged: shell.settings.enableBottomSwipeDeviceFix = checked
                Binding {
                    target: enableBottomSwipeDeviceFix
                    property: "checked"
                    value: shell.settings.enableBottomSwipeDeviceFix
                }
            }
            LPSettingsCheckBox {
                id: enableSpreadTouchFix
                Layout.fillWidth: true
                text: "App spread touch fix (Ubuntu Desktop)"
                onCheckedChanged: shell.settings.enableSpreadTouchFix = checked
                Binding {
                    target: enableSpreadTouchFix
                    property: "checked"
                    value: shell.settings.enableSpreadTouchFix
                }
            }

            Component {
                id: pro1Page
                
                LPSettingsPage {
                    LPSettingsSwitch {
                        id: enableKeyboardBacklight
                        Layout.fillWidth: true
                        text: "Keypad backlight (Needs script to work)"
                        onCheckedChanged: shell.settings.enableKeyboardBacklight = checked
                        Binding {
                            target: enableKeyboardBacklight
                            property: "checked"
                            value: shell.settings.enableKeyboardBacklight
                        }
                    }
                    OptionSelector {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: i18n.tr("Auto toggle keypad backlight")
                        model: [
                            i18n.tr("Disabled"),
                            i18n.tr("Follow Dark Mode"),
                            i18n.tr("Ambient Light Sensor")
                        ]
                        containerHeight: itemHeight * 6
                        selectedIndex: shell.settings.keyboardBacklightAutoBehavior
                        onSelectedIndexChanged: shell.settings.keyboardBacklightAutoBehavior = selectedIndex
                    }
                    LPSettingsCheckBox {
                        id: pro1_OSKOrientation
                        Layout.fillWidth: true
                        text: "Automatically toggle on-screen keyboard"
                        onCheckedChanged: shell.settings.pro1_OSKOrientation = checked
                        Binding {
                            target: pro1_OSKOrientation
                            property: "checked"
                            value: shell.settings.pro1_OSKOrientation
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(4)
                        Layout.rightMargin: units.gu(2)
                        Layout.bottomMargin: units.gu(2)
                        text: "Disables OSK when in the same orientation as the physical keyboard and enables it when in any other orientation"
                        wrapMode: Text.WordWrap
                        font.italic: true
                        textSize: Label.Small
                    }
                    /* Doesn't work anymore
                    QQC2.CheckDelegate {
                        id: pro1_OSKToggleKey
                        Layout.fillWidth: true
                        text: "Use Fn/Yellow Arrow Key to toggle OSK"
                        onCheckedChanged: shell.settings.pro1_OSKToggleKey = checked
                        Binding {
                            target: pro1_OSKToggleKey
                            property: "checked"
                            value: shell.settings.pro1_OSKToggleKey
                        }
                    }
                    */
                }
            }
        }
    }
    Component {
        id: componentsPage
        
        LPSettingsPage {
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Lockscreen"
                onClicked: settingsLoader.item.stack.push(lockscreenPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Launcher"
                onClicked: settingsLoader.item.stack.push(launcherPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "App Drawer"
                onClicked: settingsLoader.item.stack.push(drawerpage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Top Bar / Indicators"
                onClicked: settingsLoader.item.stack.push(topPanelpage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "App Spread"
                onClicked: settingsLoader.item.stack.push(spreadPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Window Decoration"
                onClicked: settingsLoader.item.stack.push(windowDecorationPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Notifications"
                onClicked: settingsLoader.item.stack.push(notificationsPage, {"title": text})
            }

            Component {
                id: notificationsPage

                LPSettingsPage {
                    Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Notification Bubbles"
                        wrapMode: Text.WordWrap
                        textSize: Label.Large
                    }
                    LPSettingsCheckBox {
                        id: lightModeNotificationBubble
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(2)
                        text: "Light mode (pre-Noble theme)"
                        onCheckedChanged: shell.settings.lightModeNotificationBubble = checked
                        Binding {
                            target: lightModeNotificationBubble
                            property: "checked"
                            value: shell.settings.lightModeNotificationBubble
                        }
                    }
                    LPSettingsCheckBox {
                        id: showNotificationBubblesAtTheBottom
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(2)
                        text: "Show at the bottom"
                        onCheckedChanged: shell.settings.showNotificationBubblesAtTheBottom = checked
                        Binding {
                            target: showNotificationBubblesAtTheBottom
                            property: "checked"
                            value: shell.settings.showNotificationBubblesAtTheBottom
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(4)
                        Layout.rightMargin: units.gu(2)
                        Layout.bottomMargin: units.gu(2)
                        text: "** Only applies when screen is narrow or in portrait"
                        wrapMode: Text.WordWrap
                        font.italic: true
                        textSize: Label.Small
                    }
                    LPSettingsCheckBox {
                        id: enableSlimVolume
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(2)
                        text: "Slim slider bubbles"
                        onCheckedChanged: shell.settings.enableSlimVolume = checked
                        Binding {
                            target: enableSlimVolume
                            property: "checked"
                            value: shell.settings.enableSlimVolume
                        }
                    }
                }
            }
            Component {
                id: windowDecorationPage

                LPSettingsPage {
                    LPSettingsSwitch {
                        id: noDecorationWindowedMode
                        Layout.fillWidth: true
                        text: "Clean mode"
                        onCheckedChanged: shell.settings.noDecorationWindowedMode = checked
                        Binding {
                            target: noDecorationWindowedMode
                            property: "checked"
                            value: shell.settings.noDecorationWindowedMode
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(4)
                        Layout.rightMargin: units.gu(2)
                        Layout.bottomMargin: units.gu(2)
                        visible: noDecorationWindowedMode.visible
                        text: "Window borders and titlebar are not displayed. Hovering at the top will display the window buttons"
                        wrapMode: Text.WordWrap
                        font.italic: true
                        textSize: Label.Small
                    }
                    LPSettingsCheckBox {
                        id: enableTitlebarMatchAppTopColor
                        Layout.fillWidth: true
                        text: "Match titlebar with app's color (Affects performance)"
                        onCheckedChanged: shell.settings.enableTitlebarMatchAppTopColor = checked
                        Binding {
                            target: enableTitlebarMatchAppTopColor
                            property: "checked"
                            value: shell.settings.enableTitlebarMatchAppTopColor
                        }
                    }
                    LPSettingsCheckBox {
                        id: retainRoundedWindowWhileMatching
                        Layout.fillWidth: true
                        text: "Retain rounded corners (May affect performance)"
                        visible: shell.settings.enableTitlebarMatchAppTopColor
                        onCheckedChanged: shell.settings.retainRoundedWindowWhileMatching = checked
                        Binding {
                            target: retainRoundedWindowWhileMatching
                            property: "checked"
                            value: shell.settings.retainRoundedWindowWhileMatching
                        }
                    }
                    OptionSelector {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.enableTitlebarMatchAppTopColor
                        text: i18n.tr("Match behavior")
                        model: [
                            i18n.tr("App's Top left side"),
                            i18n.tr("App's Top Row")
                        ]
                        containerHeight: itemHeight * 6
                        selectedIndex: shell.settings.titlebarMatchAppBehavior
                        onSelectedIndexChanged: shell.settings.titlebarMatchAppBehavior = selectedIndex
                    }
                    LPSettingsSwitch {
                        id: enableWobblyWindows
                        Layout.fillWidth: true
                        text: "Wobbly windows"
                        onCheckedChanged: shell.settings.enableWobblyWindows = checked
                        Binding {
                            target: enableWobblyWindows
                            property: "checked"
                            value: shell.settings.enableWobblyWindows
                        }
                    }
                    LPSettingsCheckBox {
                        id: enlargeWindowButtonsWithOverlay
                        Layout.fillWidth: true
                        text: "Enlarge window buttons on drag/resize overlay"
                        onCheckedChanged: shell.settings.enlargeWindowButtonsWithOverlay = checked
                        Binding {
                            target: enlargeWindowButtonsWithOverlay
                            property: "checked"
                            value: shell.settings.enlargeWindowButtonsWithOverlay
                        }
                    }
                    LPSettingsSwitch {
                        id: useCustomWindowSnappingRectangleColor
                        Layout.fillWidth: true
                        text: "Custom Snapping Rectangle Color"
                        onCheckedChanged: shell.settings.useCustomWindowSnappingRectangleColor = checked
                        Binding {
                            target: useCustomWindowSnappingRectangleColor
                            property: "checked"
                            value: shell.settings.useCustomWindowSnappingRectangleColor
                        }
                    }
                    LPColorField {
                        id: customWindowSnappingRectangleColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomWindowSnappingRectangleColor
                        onTextChanged: shell.settings.customWindowSnappingRectangleColor = text
                        onColorPicker: colorPickerLoader.open(customWindowSnappingRectangleColor)
                        Binding {
                            target: customWindowSnappingRectangleColor
                            property: "text"
                            value: shell.settings.customWindowSnappingRectangleColor
                        }
                    }
                    LPSettingsSwitch {
                        id: useCustomWindowSnappingRectangleBorderColor
                        Layout.fillWidth: true
                        text: "Custom Snapping Rectangle Border Color"
                        onCheckedChanged: shell.settings.useCustomWindowSnappingRectangleBorderColor = checked
                        Binding {
                            target: useCustomWindowSnappingRectangleBorderColor
                            property: "checked"
                            value: shell.settings.useCustomWindowSnappingRectangleBorderColor
                        }
                    }
                    LPColorField {
                        id: customWindowSnappingRectangleBorderColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomWindowSnappingRectangleBorderColor
                        onTextChanged: shell.settings.customWindowSnappingRectangleBorderColor = text
                        onColorPicker: colorPickerLoader.open(customWindowSnappingRectangleBorderColor)
                        Binding {
                            target: customWindowSnappingRectangleBorderColor
                            property: "text"
                            value: shell.settings.customWindowSnappingRectangleBorderColor
                        }
                    }
                }
            }
            Component {
                id: lockscreenPage

                LPSettingsPage {
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Clock"
                        onClicked: settingsLoader.item.stack.push(clockPage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Infographics"
                        onClicked: settingsLoader.item.stack.push(infographicsPage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Dynamic Cove"
                        onClicked: settingsLoader.item.stack.push(dynamicCovePage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "User Account"
                        onClicked: settingsLoader.item.stack.push(userAccountPage, {"title": text})
                    }
                    LPSettingsSwitch {
                        id: customLockscreenWP
                        Layout.fillWidth: true
                        text: "Custom Wallpaper"
                        onCheckedChanged: shell.settings.useCustomLockscreen = checked
                        Binding {
                            target: customLockscreenWP
                            property: "checked"
                            value: shell.settings.useCustomLockscreen
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(4)
                        Layout.rightMargin: units.gu(2)
                        Layout.bottomMargin: units.gu(2)
                        text: "Filename: ~/Pictures/lomiriplus/lockscreen"
                        wrapMode: Text.WordWrap
                        font.italic: true
                        textSize: Label.Small
                    }
                    LPSettingsCheckBox {
                        id: useCustomCoverPageWP
                        Layout.fillWidth: true
                        visible: shell.settings.useCustomLockscreen
                        text: "Custom Cover Page Wallpaper"
                        onCheckedChanged: shell.settings.useCustomCoverPage = checked
                        Binding {
                            target: useCustomCoverPageWP
                            property: "checked"
                            value: shell.settings.useCustomCoverPage
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(4)
                        Layout.rightMargin: units.gu(2)
                        Layout.bottomMargin: units.gu(2)
                        visible: shell.settings.useCustomLockscreen
                        text: "Filename: ~/Pictures/lomiriplus/coverpage"
                        wrapMode: Text.WordWrap
                        font.italic: true
                        textSize: Label.Small
                    }
                }
            }
            // ENH205 - Device account personalization
            Component {
                id: userAccountPage

                LPSettingsPage {
                    Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Display name"
                        wrapMode: Text.WordWrap
                    }
                    RowLayout {
                        Layout.leftMargin: units.gu(2)
                        Layout.rightMargin: units.gu(2)

                        TextField {
                            id: deviceNameTextField

                            readonly property string validName: text.trim()
                            readonly property bool unsaved: AccountsService.realName !== validName

                            Layout.fillWidth: true
                            text: AccountsService.realName
                            inputMethodHints: Qt.ImhNoPredictiveText
                        }
                        QQC2.ToolButton {
                            Layout.fillHeight: true
                            visible: deviceNameTextField.unsaved
                            icon.width: units.gu(2)
                            icon.height: units.gu(2)
                            action: QQC2.Action {
                                icon.name:  "ok"
                                onTriggered: AccountsService.realName = deviceNameTextField.validName
                            }
                        }
                        QQC2.ToolButton {
                            Layout.fillHeight: true
                            visible: deviceNameTextField.unsaved
                            icon.width: units.gu(2)
                            icon.height: units.gu(2)
                            action: QQC2.Action {
                                icon.name:  "reset"
                                onTriggered: deviceNameTextField.text = AccountsService.realName
                            }
                        }
                    }
                    LPSettingsSwitch {
                        id: useCustomAccountIcon
                        Layout.fillWidth: true
                        text: "Use custom account icon"
                        onCheckedChanged: shell.settings.useCustomAccountIcon = checked
                        Binding {
                            target: useCustomAccountIcon
                            property: "checked"
                            value: shell.settings.useCustomAccountIcon
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(4)
                        Layout.rightMargin: units.gu(2)
                        Layout.bottomMargin: units.gu(2)
                        text: "Custom Icon Filename: ~/Pictures/lomiriplus/user.svg"
                        wrapMode: Text.WordWrap
                        font.italic: true
                        textSize: Label.Small
                    }
                }
            }
            // ENH205 - End
            Component {
                id: clockPage

                LPSettingsPage {
                    LPSettingsCheckBox {
                        id: hideLockscreenClock
                        Layout.fillWidth: true
                        text: "Hide clock"
                        onCheckedChanged: shell.settings.hideLockscreenClock = checked
                        Binding {
                            target: hideLockscreenClock
                            property: "checked"
                            value: shell.settings.hideLockscreenClock
                        }
                    }
                    OptionSelector {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Clock text style"
                        model: [
                            "Normal",
                            "Outline",
                            "Raised",
                            "Sunken",
                        ]
                        containerHeight: itemHeight * 6
                        selectedIndex: shell.settings.lockScreenClockStyle
                        onSelectedIndexChanged: shell.settings.lockScreenClockStyle = selectedIndex
                    }
                    LPColorField {
                        id: lockScreenClockStyleColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.lockScreenClockStyle > 0
                        onTextChanged: shell.settings.lockScreenClockStyleColor = text
                        onColorPicker: colorPickerLoader.open(lockScreenClockStyleColor)
                        Binding {
                            target: lockScreenClockStyleColor
                            property: "text"
                            value: shell.settings.lockScreenClockStyleColor
                        }
                    }
                    OptionSelector {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Date text style"
                        model: [
                            "Normal",
                            "Outline",
                            "Raised",
                            "Sunken",
                        ]
                        containerHeight: itemHeight * 6
                        selectedIndex: shell.settings.lockScreenDateStyle
                        onSelectedIndexChanged: shell.settings.lockScreenDateStyle = selectedIndex
                    }
                    LPColorField {
                        id: lockScreenDateStyleColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.lockScreenDateStyle > 0
                        onTextChanged: shell.settings.lockScreenDateStyleColor = text
                        onColorPicker: colorPickerLoader.open(lockScreenDateStyleColor)
                        Binding {
                            target: lockScreenDateStyleColor
                            property: "text"
                            value: shell.settings.lockScreenDateStyleColor
                        }
                    }
                    LPSettingsSwitch {
                        id: useCustomLSClockColor
                        Layout.fillWidth: true
                        text: "Custom clock color"
                        onCheckedChanged: shell.settings.useCustomLSClockColor = checked
                        Binding {
                            target: useCustomLSClockColor
                            property: "checked"
                            value: shell.settings.useCustomLSClockColor
                        }
                    }
                    LPColorField {
                        id: customLSClockColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomLSClockColor
                        onTextChanged: shell.settings.customLSClockColor = text
                        onColorPicker: colorPickerLoader.open(customLSClockColor)
                        Binding {
                            target: customLSClockColor
                            property: "text"
                            value: shell.settings.customLSClockColor
                        }
                    }
                    LPSettingsSwitch {
                        id: useCustomLSDateColor
                        Layout.fillWidth: true
                        visible: shell.settings.useCustomLSClockColor
                        text: "Custom date color"
                        onCheckedChanged: shell.settings.useCustomLSDateColor = checked
                        Binding {
                            target: useCustomLSDateColor
                            property: "checked"
                            value: shell.settings.useCustomLSDateColor
                        }
                    }
                    LPColorField {
                        id: customLSDateColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomLSDateColor && shell.settings.useCustomLSClockColor
                        onTextChanged: shell.settings.customLSDateColor = text
                        onColorPicker: colorPickerLoader.open(customLSDateColor)
                        Binding {
                            target: customLSDateColor
                            property: "text"
                            value: shell.settings.customLSDateColor
                        }
                    }
                    LPSettingsSwitch {
                        id: useCustomLSClockFont
                        Layout.fillWidth: true
                        text: "Custom font"
                        onCheckedChanged: shell.settings.useCustomLSClockFont = checked
                        Binding {
                            target: useCustomLSClockFont
                            property: "checked"
                            value: shell.settings.useCustomLSClockFont
                        }
                    }
                    OptionSelector {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomLSClockFont
                        model: Qt.fontFamilies()
                        containerHeight: itemHeight * 6
                        selectedIndex: model.indexOf(shell.settings.customLSClockFont)
                        onSelectedIndexChanged: shell.settings.customLSClockFont = model[selectedIndex]
                    }
                }
            }
            Component {
                id: infographicsPage

                LPSettingsPage {
                    LPSettingsCheckBox {
                        id: showInfographicsOnDesktop
                        Layout.fillWidth: true
                        text: i18n.tr("Show on the desktop when unlocked")
                        onCheckedChanged: shell.settings.showInfographicsOnDesktop = checked
                        Binding {
                            target: showInfographicsOnDesktop
                            property: "checked"
                            value: shell.settings.showInfographicsOnDesktop
                        }
                    }
                    LPSettingsCheckBox {
                        id: darkenWallpaperWhenInfographics
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(2)
                        visible: showInfographicsOnDesktop.visible && shell.settings.showInfographicsOnDesktop
                        text: i18n.tr("Darken wallpaper on the desktop")
                        onCheckedChanged: shell.settings.darkenWallpaperWhenInfographics = checked
                        Binding {
                            target: darkenWallpaperWhenInfographics
                            property: "checked"
                            value: shell.settings.darkenWallpaperWhenInfographics
                        }
                    }
                    LPSettingsSlider {
                        id: darkenWallpaperWhenInfographicsOpacity
                        Layout.fillWidth: true
                        Layout.margins: units.gu(4)
                        visible: darkenWallpaperWhenInfographics.visible && shell.settings.darkenWallpaperWhenInfographics
                        title: "Opacity"
                        minimumValue: 0
                        maximumValue: 100
                        stepSize: 10
                        resetValue: 100
                        live: true
                        percentageValue: true
                        valueIsPercentage: true
                        enableFineControls: true
                        roundValue: true
                        onValueChanged: shell.settings.darkenWallpaperWhenInfographicsOpacity = value
                        Binding {
                            target: darkenWallpaperWhenInfographicsOpacity
                            property: "value"
                            value: shell.settings.darkenWallpaperWhenInfographicsOpacity
                        }
                    }
                    LPSettingsSwitch {
                        id: useCustomInfographicCircleColor
                        Layout.fillWidth: true
                        text: i18n.tr("Custom circle color")
                        onCheckedChanged: shell.settings.useCustomInfographicCircleColor = checked
                        Binding {
                            target: useCustomInfographicCircleColor
                            property: "checked"
                            value: shell.settings.useCustomInfographicCircleColor
                        }
                    }
                    LPColorField {
                        id: customInfographicsCircleColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomInfographicCircleColor
                        onTextChanged: shell.settings.customInfographicsCircleColor = text
                        onColorPicker: colorPickerLoader.open(customInfographicsCircleColor)
                        Binding {
                            target: customInfographicsCircleColor
                            property: "text"
                            value: shell.settings.customInfographicsCircleColor
                        }
                    }
                    LPSettingsSwitch {
                        id: useCustomDotsColor
                        Layout.fillWidth: true
                        text: i18n.tr("Custom dots color")
                        onCheckedChanged: shell.settings.useCustomDotsColor = checked
                        Binding {
                            target: useCustomDotsColor
                            property: "checked"
                            value: shell.settings.useCustomDotsColor
                        }
                    }
                    LPColorField {
                        id: customDotsColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomDotsColor
                        onTextChanged: shell.settings.customDotsColor = text
                        onColorPicker: colorPickerLoader.open(customDotsColor)
                        Binding {
                            target: customDotsColor
                            property: "text"
                            value: shell.settings.customDotsColor
                        }
                    }
                }
            }
            Component {
                id: topPanelpage

                LPSettingsPage {
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Top Bar"
                        onClicked: settingsLoader.item.stack.push(topBarpage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Indicator Panels"
                        onClicked: settingsLoader.item.stack.push(indicatorsPage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Indicator Options"
                        onClicked: settingsLoader.item.stack.push(indicatorOptionsPage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Indicator Open Gesture"
                        onClicked: settingsLoader.item.stack.push(indicatorOpenPage, {"title": text})
                    }
                }
            }
            Component {
                id: topBarpage

                LPSettingsPage {
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Always Hidden Icons"
                        onClicked: settingsLoader.item.stack.push(alwaysHiddenIconsPage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Always Shown Icons"
                        onClicked: settingsLoader.item.stack.push(alwaysShownIconsPage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Appearance"
                        onClicked: settingsLoader.item.stack.push(topPanelAppearancePage, {"title": text})
                    }
                    LPSettingsCheckBox {
                        id: alwaysHideTopPanel
                        Layout.fillWidth: true
                        text: "Always hide"
                        onCheckedChanged: shell.settings.alwaysHideTopPanel = checked
                        Binding {
                            target: alwaysHideTopPanel
                            property: "checked"
                            value: shell.settings.alwaysHideTopPanel
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(4)
                        Layout.rightMargin: units.gu(2)
                        Layout.bottomMargin: units.gu(2)
                        text: "Top bar will always be hidden unless in the greeter or app spread"
                        wrapMode: Text.WordWrap
                        font.italic: true
                        textSize: Label.Small
                    }
                    LPSettingsCheckBox {
                        id: onlyHideTopPanelonLandscape
                        Layout.fillWidth: true
                        text: "Only hide when in landscape"
                        visible: shell.settings.alwaysHideTopPanel
                        onCheckedChanged: shell.settings.onlyHideTopPanelonLandscape = checked
                        Binding {
                            target: onlyHideTopPanelonLandscape
                            property: "checked"
                            value: shell.settings.onlyHideTopPanelonLandscape
                        }
                    }
                    LPSettingsSwitch {
                        id: batteryCircleCheck
                        Layout.fillWidth: true
                        text: "Punchhole Battery Indicator"
                        onCheckedChanged: shell.settings.batteryCircle = checked
                        Binding {
                            target: batteryCircleCheck
                            property: "checked"
                            value: shell.settings.batteryCircle
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(4)
                        Layout.rightMargin: units.gu(2)
                        Layout.bottomMargin: units.gu(2)
                        text: "Requires: Middle or Right punchholes, Notch Side Margin (if Right punchhole), Exact Punchhole Width, Punchhole Height From Top"
                        wrapMode: Text.WordWrap
                        font.italic: true
                        textSize: Label.Small
                    }
                }
            }
            Component {
                id: topPanelAppearancePage

                LPSettingsPage {
                    LPSettingsSwitch {
                        id: useCustomPanelColor
                        Layout.fillWidth: true
                        text: "Use custom color"
                        onCheckedChanged: shell.settings.useCustomPanelColor = checked
                        Binding {
                            target: useCustomPanelColor
                            property: "checked"
                            value: shell.settings.useCustomPanelColor
                        }
                    }
                    LPColorField {
                        id: customPanelColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomPanelColor
                        onTextChanged: shell.settings.customPanelColor = text
                        onColorPicker: colorPickerLoader.open(customPanelColor)
                        Binding {
                            target: customPanelColor
                            property: "text"
                            value: shell.settings.customPanelColor
                        }
                    }
                    LPSettingsSlider {
                        id: topPanelOpacity
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        title: "Opacity"
                        minimumValue: 0
                        maximumValue: 100
                        stepSize: 10
                        resetValue: 100
                        live: true
                        percentageValue: true
                        valueIsPercentage: true
                        roundValue: true
                        onValueChanged: shell.settings.topPanelOpacity = value
                        Binding {
                            target: topPanelOpacity
                            property: "value"
                            value: shell.settings.topPanelOpacity
                        }
                    }
                    LPSettingsCheckBox {
                        id: useCustomTopBarIconTextColor
                        Layout.fillWidth: true
                        text: "Use custom icon/text color in lockscreen"
                        onCheckedChanged: shell.settings.useCustomTopBarIconTextColor = checked
                        Binding {
                            target: useCustomTopBarIconTextColor
                            property: "checked"
                            value: shell.settings.useCustomTopBarIconTextColor
                        }
                    }
                    LPColorField {
                        id: customTopBarIconTextColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomTopBarIconTextColor
                        onTextChanged: shell.settings.customTopBarIconTextColor = text
                        onColorPicker: colorPickerLoader.open(customTopBarIconTextColor)
                        Binding {
                            target: customTopBarIconTextColor
                            property: "text"
                            value: shell.settings.customTopBarIconTextColor
                        }
                    }
                    LPSettingsSwitch {
                        id: enableTopPanelBlur
                        Layout.fillWidth: true
                        text: "Background Blur"
                        onCheckedChanged: shell.settings.enableTopPanelBlur = checked
                        Binding {
                            target: enableTopPanelBlur
                            property: "checked"
                            value: shell.settings.enableTopPanelBlur
                        }
                    }
                    LPSettingsCheckBox {
                        id: matchTopPanelToDrawerIndicatorPanels
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(2)
                        visible: shell.settings.enableTopPanelBlur
                        text: "Match appearance when Drawer or Indicator panels are open"
                        onCheckedChanged: shell.settings.matchTopPanelToDrawerIndicatorPanels = checked
                        Binding {
                            target: matchTopPanelToDrawerIndicatorPanels
                            property: "checked"
                            value: shell.settings.matchTopPanelToDrawerIndicatorPanels
                        }
                    }
                    LPSettingsCheckBox {
                        id: enableTopPanelMatchAppTopColor
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(2)
                        visible: shell.settings.enableTopPanelBlur
                        text: "Match background with app's color (Staged mode)"
                        onCheckedChanged: shell.settings.enableTopPanelMatchAppTopColor = checked
                        Binding {
                            target: enableTopPanelMatchAppTopColor
                            property: "checked"
                            value: shell.settings.enableTopPanelMatchAppTopColor
                        }
                    }
                    OptionSelector {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(6)
                        visible: shell.settings.enableTopPanelBlur && shell.settings.enableTopPanelMatchAppTopColor
                        text: i18n.tr("Match background behavior")
                        model: [
                            i18n.tr("App's Top left side"),
                            i18n.tr("Stage's Top Row")
                        ]
                        containerHeight: itemHeight * 6
                        selectedIndex: shell.settings.topPanelMatchAppBehavior
                        onSelectedIndexChanged: shell.settings.topPanelMatchAppBehavior = selectedIndex
                    }
                    LPSettingsCheckBox {
                        id: enableTopPanelMatchAppTopColorWindowed
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(2)
                        visible: shell.settings.enableTopPanelBlur
                        text: "Match background with fullscreen app's color (Windowed mode)"
                        onCheckedChanged: shell.settings.enableTopPanelMatchAppTopColorWindowed = checked
                        Binding {
                            target: enableTopPanelMatchAppTopColorWindowed
                            property: "checked"
                            value: shell.settings.enableTopPanelMatchAppTopColorWindowed
                        }
                    }
                    LPSettingsCheckBox {
                        id: transparentTopBarOnSpread
                        Layout.fillWidth: true
                        text: "Fully Transparent when in App Spread"
                        onCheckedChanged: shell.settings.transparentTopBarOnSpread = checked
                        Binding {
                            target: transparentTopBarOnSpread
                            property: "checked"
                            value: shell.settings.transparentTopBarOnSpread
                        }
                    }
                    LPSettingsCheckBox {
                        id: enableTransparentTopBarInGreeter
                        Layout.fillWidth: true
                        text: "Fully Transparent when in Lockscreen"
                        onCheckedChanged: shell.settings.enableTransparentTopBarInGreeter = checked
                        Binding {
                            target: enableTransparentTopBarInGreeter
                            property: "checked"
                            value: shell.settings.enableTransparentTopBarInGreeter
                        }
                    }
                }
            }
            Component {
                id: indicatorsPage

                LPSettingsPage {
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Quick toggles"
                        onClicked: settingsLoader.item.stack.push(quickTogglesPage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Disable toggles when locked"
                        onClicked: settingsLoader.item.stack.push(disableTogglesPage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Appearance"
                        onClicked: settingsLoader.item.stack.push(indicatorPanelAppearancePage, {"title": text})
                    }
                    LPSettingsCheckBox {
                        id: enablePanelHeaderExpand
                        Layout.fillWidth: true
                        text: "Expandable header"
                        onCheckedChanged: shell.settings.enablePanelHeaderExpand = checked
                        Binding {
                            target: enablePanelHeaderExpand
                            property: "checked"
                            value: shell.settings.enablePanelHeaderExpand
                        }
                    }
                    LPSettingsCheckBox {
                        id: expandPanelHeaderWhenBottom
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(2)
                        visible: shell.settings.enablePanelHeaderExpand
                        text: "Automatically expand when from bottom gesture"
                        onCheckedChanged: shell.settings.expandPanelHeaderWhenBottom = checked
                        Binding {
                            target: expandPanelHeaderWhenBottom
                            property: "checked"
                            value: shell.settings.expandPanelHeaderWhenBottom
                        }
                    }
                    LPSettingsCheckBox {
                        id: autoExpandWhenThereAreNotif
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(2)
                        visible: shell.settings.enablePanelHeaderExpand && !shell.settings.expandPanelHeaderWhenBottom
                        text: "Exapand when there are notifications and from bottom gesture"
                        onCheckedChanged: shell.settings.autoExpandWhenThereAreNotif = checked
                        Binding {
                            target: autoExpandWhenThereAreNotif
                            property: "checked"
                            value: shell.settings.autoExpandWhenThereAreNotif
                        }
                    }
                    LPSettingsCheckBox {
                        id: alwaysFullWidthTopPanel
                        Layout.fillWidth: true
                        text: "Always display in full width"
                        onCheckedChanged: shell.settings.alwaysFullWidthTopPanel = checked
                        Binding {
                            target: alwaysFullWidthTopPanel
                            property: "checked"
                            value: shell.settings.alwaysFullWidthTopPanel
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(4)
                        Layout.rightMargin: units.gu(2)
                        Layout.bottomMargin: units.gu(2)
                        text: "Always displays the indicator panels in full width when in portrait"
                        wrapMode: Text.WordWrap
                        font.italic: true
                        textSize: Label.Small
                    }
                    LPSettingsCheckBox {
                        id: widerLandscapeTopPanel
                        Layout.fillWidth: true
                        text: "Wider width when in landscape"
                        onCheckedChanged: shell.settings.widerLandscapeTopPanel = checked
                        Binding {
                            target: widerLandscapeTopPanel
                            property: "checked"
                            value: shell.settings.widerLandscapeTopPanel
                        }
                    }
                    LPSettingsCheckBox {
                        id: useIndicatorSelectorForPanelBarWhenInverted
                        Layout.fillWidth: true
                        text: "Use indicator selector when panel is opened from the bottom"
                        onCheckedChanged: shell.settings.useIndicatorSelectorForPanelBarWhenInverted = checked
                        Binding {
                            target: useIndicatorSelectorForPanelBarWhenInverted
                            property: "checked"
                            value: shell.settings.useIndicatorSelectorForPanelBarWhenInverted
                        }
                    }
                }
            }
            Component {
                id: indicatorPanelAppearancePage
                
                LPSettingsPage {
                    LPSettingsSwitch {
                        id: indicatorBlur
                        Layout.fillWidth: true
                        text: "Background Blur"
                        onCheckedChanged: shell.settings.indicatorBlur = checked
                        Binding {
                            target: indicatorBlur
                            property: "checked"
                            value: shell.settings.indicatorBlur
                        }
                    }
                    LPSettingsSwitch {
                        id: useCustomIndicatorPanelColor
                        Layout.fillWidth: true
                        text: "Custom Color"
                        onCheckedChanged: shell.settings.useCustomIndicatorPanelColor = checked
                        Binding {
                            target: useCustomIndicatorPanelColor
                            property: "checked"
                            value: shell.settings.useCustomIndicatorPanelColor
                        }
                    }
                    LPColorField {
                        id: customIndicatorPanelColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomIndicatorPanelColor
                        onTextChanged: shell.settings.customIndicatorPanelColor = text
                        onColorPicker: colorPickerLoader.open(customIndicatorPanelColor)
                        Binding {
                            target: customIndicatorPanelColor
                            property: "text"
                            value: shell.settings.customIndicatorPanelColor
                        }
                    }
                    LPSettingsSwitch {
                        id: useCustomIndicatorPanelOpacity
                        Layout.fillWidth: true
                        text: "Custom opacity"
                        onCheckedChanged: shell.settings.useCustomIndicatorPanelOpacity = checked
                        Binding {
                            target: useCustomIndicatorPanelOpacity
                            property: "checked"
                            value: shell.settings.useCustomIndicatorPanelOpacity
                        }
                    }
                    LPSettingsSlider {
                        id: customIndicatorPanelOpacity
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomIndicatorPanelOpacity
                        title: "Opacity"
                        minimumValue: 0.00
                        maximumValue: 1.0
                        stepSize: 0.05
                        resetValue: 0.85
                        live: true
                        percentageValue: true
                        valueIsPercentage: false
                        roundValue: true
                        onValueChanged: shell.settings.customIndicatorPanelOpacity = value
                        Binding {
                            target: customIndicatorPanelOpacity
                            property: "value"
                            value: shell.settings.customIndicatorPanelOpacity
                        }
                    }
                }
            }
            Component {
                id: indicatorOptionsPage
                
                LPSettingsPage {
                    Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "System"
                        wrapMode: Text.WordWrap
                        textSize: Label.Large
                    }
                    LPSettingsSwitch {
                        id: enableDetoxModeToggleIndicator
                        Layout.fillWidth: true
                        text: "Detox mode toggle"
                        onCheckedChanged: shell.settings.enableDetoxModeToggleIndicator = checked
                        Binding {
                            target: enableDetoxModeToggleIndicator
                            property: "checked"
                            value: shell.settings.enableDetoxModeToggleIndicator
                        }
                    }
                    LPSettingsSwitch {
                        id: enableActiveScreenToggleIndicator
                        Layout.fillWidth: true
                        text: "Active screen toggle"
                        onCheckedChanged: shell.settings.enableActiveScreenToggleIndicator = checked
                        Binding {
                            target: enableActiveScreenToggleIndicator
                            property: "checked"
                            value: shell.settings.enableActiveScreenToggleIndicator
                        }
                    }
                    LPSettingsCheckBox {
                        id: showActiveScreenIconIndicator
                        Layout.fillWidth: true
                        text: "Active screen icon indicator"
                        onCheckedChanged: shell.settings.showActiveScreenIconIndicator = checked
                        Binding {
                            target: showActiveScreenIconIndicator
                            property: "checked"
                            value: shell.settings.showActiveScreenIconIndicator
                        }
                    }
                    LPSettingsSwitch {
                        id: enableAppSuspensionToggleIndicator
                        Layout.fillWidth: true
                        text: "App suspension toggle"
                        onCheckedChanged: shell.settings.enableAppSuspensionToggleIndicator = checked
                        Binding {
                            target: enableAppSuspensionToggleIndicator
                            property: "checked"
                            value: shell.settings.enableAppSuspensionToggleIndicator
                        }
                    }
                    LPSettingsCheckBox {
                        id: showAppSuspensionIconIndicator
                        Layout.fillWidth: true
                        text: "App suspension icon indicator"
                        onCheckedChanged: shell.settings.showAppSuspensionIconIndicator = checked
                        Binding {
                            target: showAppSuspensionIconIndicator
                            property: "checked"
                            value: shell.settings.showAppSuspensionIconIndicator
                        }
                    }
                    LPSettingsCheckBox {
                        id: enableAutoDarkModeToggleIndicator
                        Layout.fillWidth: true
                        text: "Scheduled dark mode toggle"
                        onCheckedChanged: shell.settings.enableAutoDarkModeToggleIndicator = checked
                        Binding {
                            target: enableAutoDarkModeToggleIndicator
                            property: "checked"
                            value: shell.settings.enableAutoDarkModeToggleIndicator
                        }
                    }
                    LPSettingsSwitch {
                        id: enableDarkModeToggleIndicator
                        Layout.fillWidth: true
                        text: "Dark mode toggle"
                        onCheckedChanged: shell.settings.enableDarkModeToggleIndicator = checked
                        Binding {
                            target: enableDarkModeToggleIndicator
                            property: "checked"
                            value: shell.settings.enableDarkModeToggleIndicator
                        }
                    }
                    LPSettingsSwitch {
                        id: enableImmersiveModeToggleIndicator
                        Layout.fillWidth: true
                        text: "Immersive mode toggle"
                        onCheckedChanged: shell.settings.enableImmersiveModeToggleIndicator = checked
                        Binding {
                            target: enableImmersiveModeToggleIndicator
                            property: "checked"
                            value: shell.settings.enableImmersiveModeToggleIndicator
                        }
                    }
                    LPSettingsCheckBox {
                        id: showImmersiveModeIconIndicator
                        Layout.fillWidth: true
                        text: "Immersive mode icon indicator"
                        onCheckedChanged: shell.settings.showImmersiveModeIconIndicator = checked
                        Binding {
                            target: showImmersiveModeIconIndicator
                            property: "checked"
                            value: shell.settings.showImmersiveModeIconIndicator
                        }
                    }
                    LPSettingsSwitch {
                        id: enableShowTouchVisualsToggleIndicator
                        Layout.fillWidth: true
                        text: "Touch visuals toggle"
                        onCheckedChanged: shell.settings.enableShowTouchVisualsToggleIndicator = checked
                        Binding {
                            target: enableShowTouchVisualsToggleIndicator
                            property: "checked"
                            value: shell.settings.enableShowTouchVisualsToggleIndicator
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Bluetooth"
                        wrapMode: Text.WordWrap
                        textSize: Label.Large
                    }
                    LPSettingsSwitch {
                        id: enableBluetoothDevicesList
                        Layout.fillWidth: true
                        text: "Show devices list"
                        onCheckedChanged: shell.settings.enableBluetoothDevicesList = checked
                        Binding {
                            target: enableBluetoothDevicesList
                            property: "checked"
                            value: shell.settings.enableBluetoothDevicesList
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Date and Time"
                        wrapMode: Text.WordWrap
                        textSize: Label.Large
                    }
                    LPSettingsCheckBox {
                        id: twoDigitHourDateTimeIndicator
                        Layout.fillWidth: true
                        text: "2-Digit Hour Format"
                        onCheckedChanged: shell.settings.twoDigitHourDateTimeIndicator = checked
                        Binding {
                            target: twoDigitHourDateTimeIndicator
                            property: "checked"
                            value: shell.settings.twoDigitHourDateTimeIndicator
                        }
                    }
                    LPSettingsCheckBox {
                        id: hideTimeIndicatorAlarmIcon
                        Layout.fillWidth: true
                        text: "Hide alarm icon"
                        onCheckedChanged: shell.settings.hideTimeIndicatorAlarmIcon = checked
                        Binding {
                            target: hideTimeIndicatorAlarmIcon
                            property: "checked"
                            value: shell.settings.hideTimeIndicatorAlarmIcon
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Battery"
                        wrapMode: Text.WordWrap
                        textSize: Label.Large
                    }
                    LPSettingsSwitch {
                        id: enableBatteryGraphIndicator
                        Layout.fillWidth: true
                        text: "Show Battery graph"
                        onCheckedChanged: shell.settings.enableBatteryGraphIndicator = checked
                        Binding {
                            target: enableBatteryGraphIndicator
                            property: "checked"
                            value: shell.settings.enableBatteryGraphIndicator
                        }
                    }
                    LPSettingsSwitch {
                        id: enableBatteryStatsIndicator
                        Layout.fillWidth: true
                        visible: shell.settings.enableBatteryTracking
                        text: "Show Screen Time"
                        onCheckedChanged: shell.settings.enableBatteryStatsIndicator = checked
                        Binding {
                            target: enableBatteryStatsIndicator
                            property: "checked"
                            value: shell.settings.enableBatteryStatsIndicator
                        }
                    }
                    LPSettingsCheckBox {
                        id: verticalBatteryIndicatorIcon
                        Layout.fillWidth: true
                        text: "Vertical icon"
                        onCheckedChanged: shell.settings.verticalBatteryIndicatorIcon = checked
                        Binding {
                            target: verticalBatteryIndicatorIcon
                            property: "checked"
                            value: shell.settings.verticalBatteryIndicatorIcon
                        }
                    }
                    LPSettingsCheckBox {
                        id: hideBatteryIndicatorPercentage
                        Layout.fillWidth: true
                        text: "Hide % in label"
                        onCheckedChanged: shell.settings.hideBatteryIndicatorPercentage = checked
                        Binding {
                            target: hideBatteryIndicatorPercentage
                            property: "checked"
                            value: shell.settings.hideBatteryIndicatorPercentage
                        }
                    }
                    LPSettingsCheckBox {
                        id: hideBatteryIndicatorIcon
                        Layout.fillWidth: true
                        text: "Hide icon"
                        onCheckedChanged: shell.settings.hideBatteryIndicatorIcon = checked
                        Binding {
                            target: hideBatteryIndicatorIcon
                            property: "checked"
                            value: shell.settings.hideBatteryIndicatorIcon
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Sound"
                        wrapMode: Text.WordWrap
                        textSize: Label.Large
                    }
                    LPSettingsCheckBox {
                        id: onlyShowSoundIndicatorWhenSilent
                        Layout.fillWidth: true
                        text: "Only show icon when silent"
                        onCheckedChanged: shell.settings.onlyShowSoundIndicatorWhenSilent = checked
                        Binding {
                            target: onlyShowSoundIndicatorWhenSilent
                            property: "checked"
                            value: shell.settings.onlyShowSoundIndicatorWhenSilent
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Keyboard"
                        wrapMode: Text.WordWrap
                        textSize: Label.Large
                    }
                    LPSettingsSwitch {
                        id: enableOSKToggleInIndicator
                        Layout.fillWidth: true
                        text: "Show OSK toggle"
                        onCheckedChanged: shell.settings.enableOSKToggleInIndicator = checked
                        Binding {
                            target: enableOSKToggleInIndicator
                            property: "checked"
                            value: shell.settings.enableOSKToggleInIndicator
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Notifications"
                        wrapMode: Text.WordWrap
                        textSize: Label.Large
                    }
                    LPSettingsCheckBox {
                        id: onlyShowNotificationsIndicatorWhenGreen
                        Layout.fillWidth: true
                        text: "Only show icon when green"
                        onCheckedChanged: shell.settings.onlyShowNotificationsIndicatorWhenGreen = checked
                        Binding {
                            target: onlyShowNotificationsIndicatorWhenGreen
                            property: "checked"
                            value: shell.settings.onlyShowNotificationsIndicatorWhenGreen
                        }
                    }
                }
            }
            Component {
                id: alwaysHiddenIconsPage
                
                LPSettingsPage {
                    Repeater {
                        model: indicatorsModel

                        LPSettingsCheckBox {
                            id: checkDelegateHidden

                            Layout.fillWidth: true
                            text: shell.indicatorLabel(model.identifier)

                            onCheckedChanged: {
                                // Remove first from always hidden list to avoid duplicate though it doesn't matter :)
                                let tempHiddenArr = shell.settings.alwaysHiddenIndicatorIcons.slice()
                                if (shell.settings.alwaysHiddenIndicatorIcons.includes(model.identifier)) {
                                    tempHiddenArr = shell.removeItemFromList(tempHiddenArr, model.identifier)
                                }

                                if (checked) {
                                    // Make sure it's not in always shown list
                                    if (shell.settings.alwaysShownIndicatorIcons.includes(model.identifier)) {
                                        let tempShownArr = shell.settings.alwaysShownIndicatorIcons.slice()
                                        tempShownArr = shell.removeItemFromList(tempShownArr, model.identifier)
                                        shell.settings.alwaysShownIndicatorIcons = tempShownArr.slice()
                                    }

                                    // Add to always hidden list
                                    tempHiddenArr.push(model.identifier)
                                }

                                shell.settings.alwaysHiddenIndicatorIcons = tempHiddenArr.slice()
                            }
                            Binding {
                                target: checkDelegateHidden
                                property: "checked"
                                value: shell.settings.alwaysHiddenIndicatorIcons.includes(model.identifier)
                            }
                        }
                    }
                }
            }
            Component {
                id: alwaysShownIconsPage
                
                LPSettingsPage {
                    Repeater {
                        model: indicatorsModel

                        LPSettingsCheckBox {
                            id: checkDelegateShown
                            Layout.fillWidth: true
                            text: shell.indicatorLabel(model.identifier)

                            onCheckedChanged: {
                                // Remove first from always shown list to avoid duplicate though it doesn't matter :)
                                let tempShownArr = shell.settings.alwaysShownIndicatorIcons.slice()
                                if (shell.settings.alwaysShownIndicatorIcons.includes(model.identifier)) {
                                    tempShownArr = shell.removeItemFromList(tempShownArr, model.identifier)
                                }

                                if (checked) {
                                    // Make sure it's not in always hidden list
                                    if (shell.settings.alwaysHiddenIndicatorIcons.includes(model.identifier)) {
                                        let tempHiddenArr = shell.settings.alwaysHiddenIndicatorIcons.slice()
                                        tempHiddenArr = shell.removeItemFromList(tempHiddenArr, model.identifier)
                                        shell.settings.alwaysHiddenIndicatorIcons = tempHiddenArr.slice()
                                    }

                                    // Add to always hidden list
                                    tempShownArr.push(model.identifier)
                                }

                                shell.settings.alwaysShownIndicatorIcons = tempShownArr.slice()
                            }
                            Binding {
                                target: checkDelegateShown
                                property: "checked"
                                value: shell.settings.alwaysShownIndicatorIcons.includes(model.identifier)
                            }
                        }
                    }
                }
            }
            Component {
                id: drawerpage
                
                LPSettingsPage {
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Drawer Dock"
                        onClicked: settingsLoader.item.stack.push(drawerDockPage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "App Grids"
                        onClicked: settingsLoader.item.stack.push(appGridsPage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Appearance"
                        onClicked: settingsLoader.item.stack.push(drawerAppearancePage, {"title": text})
                    }
                    LPSettingsCheckBox {
                        id: invertedDrawer
                        Layout.fillWidth: true
                        text: "Inverted"
                        onCheckedChanged: shell.settings.invertedDrawer = checked
                        Binding {
                            target: invertedDrawer
                            property: "checked"
                            value: shell.settings.invertedDrawer
                        }
                    }
                    LPSettingsCheckBox {
                        id: fasterFlickDrawer
                        Layout.fillWidth: true
                        text: "Faster flick velocity"
                        onCheckedChanged: shell.settings.fasterFlickDrawer = checked
                        Binding {
                            target: fasterFlickDrawer
                            property: "checked"
                            value: shell.settings.fasterFlickDrawer
                        }
                    }
                    LPSettingsCheckBox {
                        id: resetAppDrawerWhenClosed
                        Layout.fillWidth: true
                        text: "Reset view upon opening"
                        onCheckedChanged: shell.settings.resetAppDrawerWhenClosed = checked
                        Binding {
                            target: resetAppDrawerWhenClosed
                            property: "checked"
                            value: shell.settings.resetAppDrawerWhenClosed
                        }
                    }
                    LPSettingsCheckBox {
                        id: enableDrawerBottomSwipe
                        Layout.fillWidth: true
                        text: "Bottom swipe up to search"
                        onCheckedChanged: shell.settings.enableDrawerBottomSwipe = checked
                        Binding {
                            target: enableDrawerBottomSwipe
                            property: "checked"
                            value: shell.settings.enableDrawerBottomSwipe
                        }
                    }
                    LPSettingsCheckBox {
                        id: hideDrawerSearch
                        Layout.fillWidth: true
                        text: "Hide search field"
                        onCheckedChanged: shell.settings.hideDrawerSearch = checked
                        Binding {
                            target: hideDrawerSearch
                            property: "checked"
                            value: shell.settings.hideDrawerSearch
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(4)
                        Layout.rightMargin: units.gu(2)
                        Layout.bottomMargin: units.gu(2)
                        text: "Swipe up from the bottom, type something with a physical keyboard to search or hover at the top/bottom"
                        wrapMode: Text.WordWrap
                        font.italic: true
                        textSize: Label.Small
                    }
                    LPSettingsCheckBox {
                        id: showBottomHintDrawer
                        Layout.fillWidth: true
                        text: "Show bottom hint"
                        visible: shell.settings.hideDrawerSearch || shell.settings.enableDrawerBottomSwipe
                        onCheckedChanged: shell.settings.showBottomHintDrawer = checked
                        Binding {
                            target: showBottomHintDrawer
                            property: "checked"
                            value: shell.settings.showBottomHintDrawer
                        }
                    }
                    LPSettingsCheckBox {
                        id: bigDrawerSearchFieldDrawer
                        Layout.fillWidth: true
                        text: "Bigger Search Field"
                        onCheckedChanged: shell.settings.bigDrawerSearchField = checked
                        Binding {
                            target: bigDrawerSearchFieldDrawer
                            property: "checked"
                            value: shell.settings.bigDrawerSearchField
                        }
                    }
                    LPSettingsSlider {
                        id: drawerIconSizeMultiplier
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        title: "Icon size multiplier"
                        minimumValue: 0.5
                        maximumValue: 2
                        stepSize: 0.05
                        resetValue: 1
                        live: true
                        percentageValue: true
                        valueIsPercentage: false
                        enableFineControls: true
                        roundValue: true
                        onValueChanged: shell.settings.drawerIconSizeMultiplier = value
                        Binding {
                            target: drawerIconSizeMultiplier
                            property: "value"
                            value: shell.settings.drawerIconSizeMultiplier
                        }
                    }
                }
            }
            Component {
                id: drawerAppearancePage
                
                LPSettingsPage {
                    LPSettingsCheckBox {
                        id: extendDrawerOverTopBar
                        Layout.fillWidth: true
                        text: "Extend to the top over the Top Bar"
                        onCheckedChanged: shell.settings.extendDrawerOverTopBar = checked
                        Binding {
                            target: extendDrawerOverTopBar
                            property: "checked"
                            value: shell.settings.extendDrawerOverTopBar
                        }
                    }
                    LPSettingsSwitch {
                        id: drawerBlur
                        Layout.fillWidth: true
                        text: "Background Blur"
                        onCheckedChanged: shell.settings.drawerBlur = checked
                        Binding {
                            target: drawerBlur
                            property: "checked"
                            value: shell.settings.drawerBlur
                        }
                    }
                    LPSettingsSwitch {
                        id: useCustomDrawerColor
                        Layout.fillWidth: true
                        text: "Custom Color"
                        onCheckedChanged: shell.settings.useCustomDrawerColor = checked
                        Binding {
                            target: useCustomDrawerColor
                            property: "checked"
                            value: shell.settings.useCustomDrawerColor
                        }
                    }
                    LPColorField {
                        id: customDrawerColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomDrawerColor
                        onTextChanged: shell.settings.customDrawerColor = text
                        onColorPicker: colorPickerLoader.open(customDrawerColor)
                        Binding {
                            target: customDrawerColor
                            property: "text"
                            value: shell.settings.customDrawerColor
                        }
                    }
                    LPSettingsSwitch {
                        id: useCustomDrawerOpacity
                        Layout.fillWidth: true
                        text: "Custom opacity"
                        onCheckedChanged: shell.settings.useCustomDrawerOpacity = checked
                        Binding {
                            target: useCustomDrawerOpacity
                            property: "checked"
                            value: shell.settings.useCustomDrawerOpacity
                        }
                    }
                    LPSettingsSlider {
                        id: customDrawerOpacity
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomDrawerOpacity
                        title: "Opacity"
                        minimumValue: 0.00
                        maximumValue: 1.0
                        stepSize: 0.05
                        resetValue: 0.75
                        live: true
                        percentageValue: true
                        valueIsPercentage: false
                        roundValue: true
                        onValueChanged: shell.settings.customDrawerOpacity = value
                        Binding {
                            target: customDrawerOpacity
                            property: "value"
                            value: shell.settings.customDrawerOpacity
                        }
                    }
                }
            }
            Component {
                id: spreadPage
                
                LPSettingsPage {
                    LPSettingsCheckBox {
                        id: roundedAppPreview
                        Layout.fillWidth: true
                        text: "Rounded App Preview"
                        onCheckedChanged: shell.settings.roundedAppPreview = checked
                        Binding {
                            target: roundedAppPreview
                            property: "checked"
                            value: shell.settings.roundedAppPreview
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(4)
                        Layout.rightMargin: units.gu(2)
                        Layout.bottomMargin: units.gu(2)
                        text: "Requires Notch/Punchhole configuration and Corner Radius"
                        wrapMode: Text.WordWrap
                        font.italic: true
                        textSize: Label.Small
                    }
                }
            }
            Component {
                id: launcherPage
                
                LPSettingsPage {
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Direct Select"
                        onClicked: settingsLoader.item.stack.push(directSelectPage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "BFB"
                        onClicked: settingsLoader.item.stack.push(bfbPage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Appearance"
                        onClicked: settingsLoader.item.stack.push(launcherAppearancePage, {"title": text})
                    }
                    LPSettingsCheckBox {
                        id: customLauncherOpacityBehavior
                        Layout.fillWidth: true
                        text: "Custom opacity behavior when dragging drawer"
                        onCheckedChanged: shell.settings.customLauncherOpacityBehavior = checked
                        Binding {
                            target: customLauncherOpacityBehavior
                            property: "checked"
                            value: shell.settings.customLauncherOpacityBehavior
                        }
                    }
                    LPSettingsCheckBox {
                        id: enableLauncherBottomMargin
                        Layout.fillWidth: true
                        text: "Use rounded corner margin as bottom margin"
                        visible: shell.settings.roundedCornerMargin > 0
                        onCheckedChanged: shell.settings.enableLauncherBottomMargin = checked
                        Binding {
                            target: enableLauncherBottomMargin
                            property: "checked"
                            value: shell.settings.enableLauncherBottomMargin
                        }
                    }
                    LPSettingsCheckBox {
                        id: showLauncherAtDesktop
                        Layout.fillWidth: true
                        text: "Show Launcher when no app is running"
                        onCheckedChanged: shell.settings.showLauncherAtDesktop = checked
                        Binding {
                            target: showLauncherAtDesktop
                            property: "checked"
                            value: shell.settings.showLauncherAtDesktop
                        }
                    }
                    LPSettingsCheckBox {
                        id: hideLauncherWhenNarrow
                        Layout.fillWidth: true
                        text: "Hide Launcher when screen is narrow even if it's locked"
                        onCheckedChanged: shell.settings.hideLauncherWhenNarrow = checked
                        Binding {
                            target: hideLauncherWhenNarrow
                            property: "checked"
                            value: shell.settings.hideLauncherWhenNarrow
                        }
                    }
                    LPSettingsCheckBox {
                        id: dimWhenLauncherShow
                        Layout.fillWidth: true
                        text: "Dim screen when fully open"
                        onCheckedChanged: shell.settings.dimWhenLauncherShow = checked
                        Binding {
                            target: dimWhenLauncherShow
                            property: "checked"
                            value: shell.settings.dimWhenLauncherShow
                        }
                    }
                }
            }
            Component {
                id: launcherAppearancePage
                
                LPSettingsPage {
                    LPSettingsSwitch {
                        id: enableLauncherBlur
                        Layout.fillWidth: true
                        text: "Background Blur"
                        onCheckedChanged: shell.settings.enableLauncherBlur = checked
                        Binding {
                            target: enableLauncherBlur
                            property: "checked"
                            value: shell.settings.enableLauncherBlur
                        }
                    }
                    LPSettingsSwitch {
                        id: useCustomLauncherColor
                        Layout.fillWidth: true
                        text: "Custom Color"
                        onCheckedChanged: shell.settings.useCustomLauncherColor = checked
                        Binding {
                            target: useCustomLauncherColor
                            property: "checked"
                            value: shell.settings.useCustomLauncherColor
                        }
                    }
                    LPColorField {
                        id: customLauncherColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomLauncherColor
                        onTextChanged: shell.settings.customLauncherColor = text
                        onColorPicker: colorPickerLoader.open(customLauncherColor)
                        Binding {
                            target: customLauncherColor
                            property: "text"
                            value: shell.settings.customLauncherColor
                        }
                    }
                    LPSettingsSwitch {
                        id: useCustomLauncherOpacity
                        Layout.fillWidth: true
                        text: "Custom opacity"
                        onCheckedChanged: shell.settings.useCustomLauncherOpacity = checked
                        Binding {
                            target: useCustomLauncherOpacity
                            property: "checked"
                            value: shell.settings.useCustomLauncherOpacity
                        }
                    }
                    LPSettingsSlider {
                        id: customLauncherOpacity
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomLauncherOpacity
                        title: "Opacity"
                        minimumValue: 0.00
                        maximumValue: 1.0
                        stepSize: 0.05
                        resetValue: 0.95
                        live: true
                        percentageValue: true
                        valueIsPercentage: false
                        roundValue: true
                        onValueChanged: shell.settings.customLauncherOpacity = value
                        Binding {
                            target: customLauncherOpacity
                            property: "value"
                            value: shell.settings.customLauncherOpacity
                        }
                    }
                }
            }
            Component {
                id: bfbPage
                
                LPSettingsPage {
                    LPSettingsCheckBox {
                        id: hideBFB
                        Layout.fillWidth: true
                        text: "Hide"
                        onCheckedChanged: shell.settings.hideBFB = checked
                        Binding {
                            target: hideBFB
                            property: "checked"
                            value: shell.settings.hideBFB
                        }
                    }
                    LPSettingsCheckBox {
                        id: roundedBFB
                        Layout.fillWidth: true
                        text: "Rounded Corners"
                        onCheckedChanged: shell.settings.roundedBFB = checked
                        Binding {
                            target: roundedBFB
                            property: "checked"
                            value: shell.settings.roundedBFB
                        }
                    }
                    LPSettingsCheckBox {
                        id: useCustomBFBColor
                        Layout.fillWidth: true
                        text: "Custom Background Color"
                        onCheckedChanged: shell.settings.useCustomBFBColor = checked
                        Binding {
                            target: useCustomBFBColor
                            property: "checked"
                            value: shell.settings.useCustomBFBColor
                        }
                    }
                    LPColorField {
                        id: customBFBColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomBFBColor
                        onTextChanged: shell.settings.customBFBColor = text
                        onColorPicker: colorPickerLoader.open(customBFBColor)
                        Binding {
                            target: customBFBColor
                            property: "text"
                            value: shell.settings.customBFBColor
                        }
                    }
                    LPSettingsCheckBox {
                        id: useNewLogo
                        Layout.fillWidth: true
                        text: "Use New Ubuntu Logo"
                        onCheckedChanged: shell.settings.useNewLogo = checked
                        Binding {
                            target: useNewLogo
                            property: "checked"
                            value: shell.settings.useNewLogo
                        }
                    }
                    LPSettingsCheckBox {
                        id: useLomiriLogo
                        Layout.fillWidth: true
                        text: "Use Lomiri Logo"
                        onCheckedChanged: shell.settings.useLomiriLogo = checked
                        Binding {
                            target: useLomiriLogo
                            property: "checked"
                            value: shell.settings.useLomiriLogo
                        }
                    }
                    LPSettingsCheckBox {
                        id: useCustomLogo
                        Layout.fillWidth: true
                        text: "Custom Logo (SVG)"
                        onCheckedChanged: shell.settings.useCustomLogo = checked
                        Binding {
                            target: useCustomLogo
                            property: "checked"
                            value: shell.settings.useCustomLogo
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(4)
                        Layout.rightMargin: units.gu(2)
                        Layout.bottomMargin: units.gu(2)
                        text: "Custom Logo Filename: ~/Pictures/lomiriplus/bfb.svg"
                        wrapMode: Text.WordWrap
                        font.italic: true
                        textSize: Label.Small
                    }
                    LPSettingsSwitch {
                        id: useCustomeBFBLogoAppearance
                        Layout.fillWidth: true
                        text: "Enable custom Logo settings"
                        onCheckedChanged: shell.settings.useCustomeBFBLogoAppearance = checked
                        Binding {
                            target: useCustomeBFBLogoAppearance
                            property: "checked"
                            value: shell.settings.useCustomeBFBLogoAppearance
                        }
                    }
                    LPSettingsSlider {
                        id: logScale
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomeBFBLogoAppearance
                        title: "Logo scale"
                        minimumValue: 5
                        maximumValue: 100
                        stepSize: 5
                        resetValue: 60
                        live: true
                        percentageValue: true
                        valueIsPercentage: true
                        roundValue: true
                        onValueChanged: shell.settings.customLogoScale = value
                        Binding {
                            target: logScale
                            property: "value"
                            value: shell.settings.customLogoScale
                        }
                    }
                    LPColorField {
                        id: customLogoColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        title: "Logo Color"
                        visible: shell.settings.useCustomeBFBLogoAppearance
                        onTextChanged: shell.settings.customLogoColor = text
                        onColorPicker: colorPickerLoader.open(this)
                        Binding {
                            target: customLogoColor
                            property: "text"
                            value: shell.settings.customLogoColor
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(4)
                        Layout.rightMargin: units.gu(2)
                        Layout.bottomMargin: units.gu(2)
                        visible: customLogoColor.visible
                        text: "Will replace all #ffffff surfaces in the SVG"
                        font.italic: true
                        textSize: Label.Small
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
    Component {
        id: appGridsPage

        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "This adds custom page(s) in the App Drawer where you can place different apps and group them by page\n\n"
                + " • Toggle edit mode: Press and hold on empty space to enter/exit. Use context menu to enter. Click on app to exit.\n"
                + " • Rearrange apps: Press, hold and drag on app icons\n"
                + " • Manage App Grids: In edit mode, you can add, edit, delete and move App Grids. You can also add apps in bulk\n\n"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsSwitch {
                id: enableCustomAppGrid
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: shell.settings.enableCustomAppGrid = checked
                Binding {
                    target: enableCustomAppGrid
                    property: "checked"
                    value: shell.settings.enableCustomAppGrid
                }
            }
            LPSettingsCheckBox {
                id: customAppGridsExpandable
                Layout.fillWidth: true
                text: "Expandable header"
                onCheckedChanged: shell.settings.customAppGridsExpandable = checked
                Binding {
                    target: customAppGridsExpandable
                    property: "checked"
                    value: shell.settings.customAppGridsExpandable
                }
            }
            LPSettingsCheckBox {
                id: placeFullAppGridToLast
                Layout.fillWidth: true
                text: "Move Full App Grid to last page"
                onCheckedChanged: shell.settings.placeFullAppGridToLast = checked
                Binding {
                    target: placeFullAppGridToLast
                    property: "checked"
                    value: shell.settings.placeFullAppGridToLast
                }
            }
            LPSettingsCheckBox {
                id: appGridIndicatorDoNotExpandWithMouse
                Layout.fillWidth: true
                text: "Do not expand indicators with mouse"
                onCheckedChanged: shell.settings.appGridIndicatorDoNotExpandWithMouse = checked
                Binding {
                    target: appGridIndicatorDoNotExpandWithMouse
                    property: "checked"
                    value: shell.settings.appGridIndicatorDoNotExpandWithMouse
                }
            }
            LPSettingsSlider {
                id: appGridIndicatorExpandedSize
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                Layout.leftMargin: units.gu(2)
                title: "Indicators expanded size"
                minimumValue: 2
                maximumValue: 8
                stepSize: 0.5
                resetValue: 5
                live: false
                roundValue: true
                roundingDecimal: 0
                enableFineControls: true
                displayCurrentValue: false
                unitsLabel: ""
                onValueChanged: shell.settings.appGridIndicatorExpandedSize = value
                Binding {
                    target: appGridIndicatorExpandedSize
                    property: "value"
                    value: shell.settings.appGridIndicatorExpandedSize
                }
            }
        }
    }
    Component {
        id: batteryStatsPage

        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Provides extra statistics such as screen on/off time as well as provide additional options for the battery indicator. \n"
                + "Values may not be accurate or completely incorrect 😅"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsSwitch {
                id: enableBatteryTracking
                Layout.fillWidth: true
                text: "Enable Screen time tracking"
                onCheckedChanged: shell.settings.enableBatteryTracking = checked
                Binding {
                    target: enableBatteryTracking
                    property: "checked"
                    value: shell.settings.enableBatteryTracking
                }
            }
            /*
            LPSettingsSwitch {
                id: screenTimeFullyChargedWorkaround
                Layout.fillWidth: true
                visible: shell.settings.enableBatteryTracking
                text: "Last fully charged workaround"
                onCheckedChanged: shell.settings.screenTimeFullyChargedWorkaround = checked
                Binding {
                    target: screenTimeFullyChargedWorkaround
                    property: "checked"
                    value: shell.settings.screenTimeFullyChargedWorkaround
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                visible: screenTimeFullyChargedWorkaround.visible
                text: "Some device doesn't properly detect fully charged state so using this will just check if the battery percentage is 100%"
                font.italic: true
                textSize: Label.Small
                wrapMode: Text.WordWrap
            }
            */

            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                Layout.preferredHeight: units.gu(8)
                text: "Indicators:"
                verticalAlignment: Text.AlignVCenter
            }

            LPSettingsSwitch {
                id: enableBatteryGraphIndicator
                Layout.fillWidth: true
                text: "Battery graph in indicator"
                onCheckedChanged: shell.settings.enableBatteryGraphIndicator = checked
                Binding {
                    target: enableBatteryGraphIndicator
                    property: "checked"
                    value: shell.settings.enableBatteryGraphIndicator
                }
            }
            LPSettingsSwitch {
                id: enableBatteryStatsIndicator
                Layout.fillWidth: true
                visible: shell.settings.enableBatteryTracking
                text: "Screen time in indicator"
                onCheckedChanged: shell.settings.enableBatteryStatsIndicator = checked
                Binding {
                    target: enableBatteryStatsIndicator
                    property: "checked"
                    value: shell.settings.enableBatteryStatsIndicator
                }
            }
            LPSettingsCheckBox {
                id: collapsibleScreenTimeIndicators
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                visible: shell.settings.enableBatteryTracking && shell.settings.enableBatteryStatsIndicator
                text: "Collapsible"
                onCheckedChanged: shell.settings.collapsibleScreenTimeIndicators = checked
                Binding {
                    target: collapsibleScreenTimeIndicators
                    property: "checked"
                    value: shell.settings.collapsibleScreenTimeIndicators
                }
            }
            LPSettingsSwitch {
                id: showScreenTimeSinceLastFullCharged
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                visible: shell.settings.enableBatteryTracking && shell.settings.enableBatteryStatsIndicator
                text: "Since last full charged"
                onCheckedChanged: shell.settings.showScreenTimeSinceLastFullCharged = checked
                Binding {
                    target: showScreenTimeSinceLastFullCharged
                    property: "checked"
                    value: shell.settings.showScreenTimeSinceLastFullCharged
                }
            }
            LPSettingsSwitch {
                id: showScreenTimeSinceLastCharge
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                visible: shell.settings.enableBatteryTracking && shell.settings.enableBatteryStatsIndicator
                text: "Since last charge"
                onCheckedChanged: shell.settings.showScreenTimeSinceLastCharge = checked
                Binding {
                    target: showScreenTimeSinceLastCharge
                    property: "checked"
                    value: shell.settings.showScreenTimeSinceLastCharge
                }
            }
            LPSettingsSwitch {
                id: showScreenTimeToday
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                visible: shell.settings.enableBatteryTracking && shell.settings.enableBatteryStatsIndicator
                text: "Today"
                onCheckedChanged: shell.settings.showScreenTimeToday = checked
                Binding {
                    target: showScreenTimeToday
                    property: "checked"
                    value: shell.settings.showScreenTimeToday
                }
            }
            LPSettingsSwitch {
                id: showScreenTimeYesterday
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                visible: shell.settings.enableBatteryTracking && shell.settings.enableBatteryStatsIndicator
                text: "Yesterday"
                onCheckedChanged: shell.settings.showScreenTimeYesterday = checked
                Binding {
                    target: showScreenTimeYesterday
                    property: "checked"
                    value: shell.settings.showScreenTimeYesterday
                }
            }
            LPSettingsSwitch {
                id: showHistoryCharts
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                visible: shell.settings.enableBatteryTracking && shell.settings.enableBatteryStatsIndicator
                text: "History Charts"
                onCheckedChanged: shell.settings.showHistoryCharts = checked
                Binding {
                    target: showHistoryCharts
                    property: "checked"
                    value: shell.settings.showHistoryCharts
                }
            }
            LPSettingsCheckBox {
                id: onlyIncludePercentageRangeInBatteryChart
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                visible: shell.settings.enableBatteryTracking && shell.settings.enableBatteryStatsIndicator && shell.settings.showHistoryCharts
                text: "Filter charging data based on total battery discharge"
                onCheckedChanged: shell.settings.onlyIncludePercentageRangeInBatteryChart = checked
                Binding {
                    target: onlyIncludePercentageRangeInBatteryChart
                    property: "checked"
                    value: shell.settings.onlyIncludePercentageRangeInBatteryChart
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "When this is enabled, the History charts will only include charging data in which the discharge percentage reached the set percentage value below.\n"
                + "Example: The detected last Charging was at 90% and the next Charging was done at 20%. If the threshold is set to 80%, this won't be included in the charts and the averages.\n"
                + "If the threshold is changed to 70%, this data will now be included."
                wrapMode: Text.WordWrap
                visible: batteryPercentageRangeToInclude.visible
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSlider {
                id: batteryPercentageRangeToInclude
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                Layout.leftMargin: units.gu(4)
                visible: onlyIncludePercentageRangeInBatteryChart.visible && shell.settings.onlyIncludePercentageRangeInBatteryChart
                title: "Battery Discharge Threshold"
                minimumValue: 5
                maximumValue: 100
                stepSize: 5
                resetValue: 80
                live: false
                roundValue: true
                roundingDecimal: 0
                enableFineControls: true
                unitsLabel: "%"
                onValueChanged: shell.settings.batteryPercentageRangeToInclude = value
                Binding {
                    target: batteryPercentageRangeToInclude
                    property: "value"
                    value: shell.settings.batteryPercentageRangeToInclude
                }
            }
            LPSettingsSlider {
                id: batteryTrackingDataDuration
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableBatteryTracking
                title: "Tracking data lifetime"
                minimumValue: 1
                maximumValue: 100
                stepSize: 1
                resetValue: 7
                live: false
                roundValue: true
                roundingDecimal: 1
                enableFineControls: true
                unitsLabel: "days"
                onValueChanged: shell.settings.batteryTrackingDataDuration = value
                Binding {
                    target: batteryTrackingDataDuration
                    property: "value"
                    value: shell.settings.batteryTrackingDataDuration
                }
            }
            Button {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.leftMargin: units.gu(2)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                visible: shell.settings.enableBatteryTracking
                text: "Clear Screen Time Data"
                onClicked: shell.batteryTracking.clear()
            }
        }
    }
    Component {
        id: colorOverlayPage

        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Overlays a color on the whole shell\n"
                + "Cheap work around to simulate night mode, redshift, or color temperature\n"
                + "Also available from quick toggles"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsCheckBox {
                id: enableColorOverlaySensor
                Layout.fillWidth: true
                text: "Toggle based on light sensor"
                onCheckedChanged: shell.settings.enableColorOverlaySensor = checked
                Binding {
                    target: enableColorOverlaySensor
                    property: "checked"
                    value: shell.settings.enableColorOverlaySensor
                }
            }
            LPSettingsSlider {
                id: colorOverlaySensorThreshold
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableColorOverlaySensor
                title: "Light Value Threshold"
                minimumValue: 0
                maximumValue: 100
                stepSize: 1
                resetValue: 0
                live: false
                percentageValue: false
                valueIsPercentage: false
                roundValue: true
                roundingDecimal: 0
                enableFineControls: true
                onValueChanged: shell.settings.colorOverlaySensorThreshold = value
                Binding {
                    target: colorOverlaySensorThreshold
                    property: "value"
                    value: shell.settings.colorOverlaySensorThreshold
                }
            }
            LPSettingsSwitch {
                id: enableColorOverlay
                Layout.fillWidth: true
                text: "Enable now"
                onCheckedChanged: shell.settings.enableColorOverlay = checked
                Binding {
                    target: enableColorOverlay
                    property: "checked"
                    value: shell.settings.enableColorOverlay
                }
            }
            LPColorField {
                id: overlayColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                onTextChanged: shell.settings.overlayColor = text
                onColorPicker: colorPickerLoader.open(overlayColor)
                Binding {
                    target: overlayColor
                    property: "text"
                    value: shell.settings.overlayColor
                }
            }
            LPSettingsSlider {
                id: colorOverlayOpacity
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Opacity"
                minimumValue: 0.05
                maximumValue: 0.7
                stepSize: 0.05
                resetValue: 0.1
                live: true
                percentageValue: true
                valueIsPercentage: false
                roundValue: true
                onValueChanged: shell.settings.colorOverlayOpacity = value
                Binding {
                    target: colorOverlayOpacity
                    property: "value"
                    value: shell.settings.colorOverlayOpacity
                }
            }
        }
    }
    Component {
        id: autoDarkModePage

        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Automatically toggle dark mode based on set start and end time\n\n"
                + " • Immediate: Toggles dark mode in real time\n"
                + " • Delayed: Toggles only on next wake up of the device"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsSwitch {
                id: enableAutoDarkMode
                Layout.fillWidth: true
                text: "Enable Schedule-based"
                onCheckedChanged: shell.settings.enableAutoDarkMode = checked
                Binding {
                    target: enableAutoDarkMode
                    property: "checked"
                    value: shell.settings.enableAutoDarkMode
                }
            }
            LPSettingsCheckBox {
                id: immediateDarkModeSwitch
                Layout.fillWidth: true
                visible: shell.settings.enableAutoDarkMode
                text: "Auto switch immediately"
                onCheckedChanged: shell.settings.immediateDarkModeSwitch = checked
                Binding {
                    target: immediateDarkModeSwitch
                    property: "checked"
                    value: shell.settings.immediateDarkModeSwitch
                }
            }
            LPSettingsTimeItem {
                id: startTimeListitem

                date: Date.fromLocaleString(Qt.locale(), shell.settings.autoDarkModeStartTime, "hh:mm")

                Layout.fillWidth: true
                visible: shell.settings.enableAutoDarkMode
                text: "Start time"
                onDateChanged: shell.settings.autoDarkModeStartTime = date.toLocaleString(Qt.locale(), "hh:mm")
                onClicked: PickerPanel.openDatePicker(startTimeListitem, "date", "Hours|Minutes")
            }
            LPSettingsTimeItem {
                id: endTimeListitem

                date: Date.fromLocaleString(Qt.locale(), shell.settings.autoDarkModeEndTime, "hh:mm")

                Layout.fillWidth: true
                visible: shell.settings.enableAutoDarkMode
                text: "End time"
                onDateChanged: shell.settings.autoDarkModeEndTime = date.toLocaleString(Qt.locale(), "hh:mm")
                onClicked: PickerPanel.openDatePicker(endTimeListitem, "date", "Hours|Minutes")
            }
            LPSettingsSwitch {
                id: enableAutoDarkModeSensor
                Layout.fillWidth: true
                text: "Enable Light Sensor-based"
                onCheckedChanged: shell.settings.enableAutoDarkModeSensor = checked
                Binding {
                    target: enableAutoDarkModeSensor
                    property: "checked"
                    value: shell.settings.enableAutoDarkModeSensor
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Automatically switch between dark and light mode based on light sensor.\n"
                + "When Auto Dark Mode is enabled, this will only take effect when outside the time range set."
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSlider {
                id: autoDarkModeSensorThreshold
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableAutoDarkModeSensor
                title: "Light Value Threshold"
                minimumValue: 0
                maximumValue: 100
                stepSize: 1
                resetValue: 0
                live: false
                percentageValue: false
                valueIsPercentage: false
                roundValue: true
                roundingDecimal: 0
                enableFineControls: true
                onValueChanged: shell.settings.autoDarkModeSensorThreshold = value
                Binding {
                    target: autoDarkModeSensorThreshold
                    property: "value"
                    value: shell.settings.autoDarkModeSensorThreshold
                }
            }
            LPSettingsSlider {
                id: autoDarkModeSensorDelay
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableAutoDarkModeSensor
                title: "Delay Duration"
                minimumValue: 0.1
                maximumValue: 20
                stepSize: 0.5
                resetValue: 1
                live: true
                roundValue: true
                roundingDecimal: 1
                enableFineControls: true
                unitsLabel: i18n.tr("second", "seconds", value)
                onValueChanged: shell.settings.autoDarkModeSensorDelay = value
                Binding {
                    target: autoDarkModeSensorDelay
                    property: "value"
                    value: shell.settings.autoDarkModeSensorDelay
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                visible: autoDarkModeSensorDelay.visible
                text: "How long the sensor value has to stay below the threshold before toggling dark mode"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
        }
    }
    Component {
        id: drawerDockPage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "New section in the app drawer where you can pin or add apps\n\n"
                + " • Toggle edit mode: Press and hold on empty space to enter/exit. Use context menu to enter. Click on app to exit.\n"
                + " • Rearrange apps: Press, hold and drag on app icons\n\n"
                + "Bottom Dock:\n"
                + " - Displayed at the bottom of the app drawer\n"
                + " - Collapsible by swiping up and down\n\n"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsSwitch {
                id: enableDrawerDock
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: shell.settings.enableDrawerDock = checked
                Binding {
                    target: enableDrawerDock
                    property: "checked"
                    value: shell.settings.enableDrawerDock
                }
            }
            LPSettingsCheckBox {
                id: drawerDockHideLabels
                Layout.fillWidth: true
                text: "Hide app labels"
                visible: shell.settings.enableDrawerDock
                onCheckedChanged: shell.settings.drawerDockHideLabels = checked
                Binding {
                    target: drawerDockHideLabels
                    property: "checked"
                    value: shell.settings.drawerDockHideLabels
                }
            }
            LPSettingsCheckBox {
                id: enableMaxHeightInDrawerDock
                Layout.fillWidth: true
                text: "Limit expanded height"
                visible: shell.settings.enableDrawerDock
                onCheckedChanged: shell.settings.enableMaxHeightInDrawerDock = checked
                Binding {
                    target: enableMaxHeightInDrawerDock
                    property: "checked"
                    value: shell.settings.enableMaxHeightInDrawerDock
                }
            }
            LPSettingsSlider {
                id: drawerDockMaxHeight
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDrawerDock && shell.settings.enableMaxHeightInDrawerDock
                title: "Max expanded height"
                minimumValue: 2
                maximumValue: 10
                stepSize: 0.25
                resetValue: 3
                live: false
                percentageValue: false
                valueIsPercentage: false
                roundValue: true
                roundingDecimal: 2
                unitsLabel: i18n.tr("inch", "inches", value)
                enableFineControls: true
                onValueChanged: shell.settings.drawerDockMaxHeight = value
                Binding {
                    target: drawerDockMaxHeight
                    property: "value"
                    value: shell.settings.drawerDockMaxHeight
                }
            }
        }
    }
    Component {
        id: directSelectPage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Select an app from the Launcher by simply swiping, no need for swipe and tap \n"
                + " • While swiping to reveal the Launcher/Drawer, swipe vertically to select between apps in the Launcher\n"
                + " • Activate the selection by lifting the swipe"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsSwitch {
                id: enableDirectAppInLauncher
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: shell.settings.enableDirectAppInLauncher = checked
                Binding {
                    target: enableDirectAppInLauncher
                    property: "checked"
                    value: shell.settings.enableDirectAppInLauncher
                }
            }
        }
    }
    Component {
        id: hotcornersPage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Disables the left and right edge mouse push and instead enable mouse push functions in 4 corners \n"
                + " • Top Left: Open App Drawer\n"
                + " • Bottom Left: Show desktop\n"
                + " • Top Right: Open Indicator panels\n"
                + " • Bottom Right: Open App Spread"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsSwitch {
                id: enableHotCorners
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: shell.settings.enableHotCorners = checked
                Binding {
                    target: enableHotCorners
                    property: "checked"
                    value: shell.settings.enableHotCorners
                }
            }
            LPSettingsCheckBox {
                id: enableHotCornersVisualFeedback
                Layout.fillWidth: true
                text: "Show visual feedback when triggering"
                visible: shell.settings.enableHotCorners
                onCheckedChanged: shell.settings.enableHotCornersVisualFeedback = checked
                Binding {
                    target: enableHotCornersVisualFeedback
                    property: "checked"
                    value: shell.settings.enableHotCornersVisualFeedback
                }
            }
            property var hotcornerActions: [
                "Open Drawer"
                , "Search Drawer"
                , "Toggle Desktop"
                , "Open Indicator"
                , "Toggle Spread"
                , "Switch to previous app"
                , "Quick Actions"
            ]
            Component {
                id: selectorDelegate
                OptionSelectorDelegate { text: modelData.name }
            }
            LPSettingsSwitch {
                id: enableTopLeftHotCorner
                Layout.fillWidth: true
                text: i18n.tr("Top Left")
                visible: shell.settings.enableHotCorners
                onCheckedChanged: shell.settings.enableTopLeftHotCorner = checked
                Binding {
                    target: enableTopLeftHotCorner
                    property: "checked"
                    value: shell.settings.enableTopLeftHotCorner
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableHotCorners && shell.settings.enableTopLeftHotCorner
                model: hotcornerActions
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.actionTypeTopLeftHotCorner
                onSelectedIndexChanged: shell.settings.actionTypeTopLeftHotCorner = selectedIndex
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableHotCorners
                            && shell.settings.enableTopLeftHotCorner
                            && shell.settings.actionTypeTopLeftHotCorner == Shell.HotCorner.Indicator
                model: hotcornersIndicatorsModel
                containerHeight: itemHeight * 6
                delegate: selectorDelegate
                selectedIndex: shell.settings.actionTopLeftHotCorner
                onSelectedIndexChanged: shell.settings.actionTopLeftHotCorner = selectedIndex
            }
            LPSettingsSwitch {
                id: enableTopRightHotCorner
                Layout.fillWidth: true
                text: i18n.tr("Top Right")
                visible: shell.settings.enableHotCorners
                onCheckedChanged: shell.settings.enableTopRightHotCorner = checked
                Binding {
                    target: enableTopRightHotCorner
                    property: "checked"
                    value: shell.settings.enableTopRightHotCorner
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableHotCorners && shell.settings.enableTopRightHotCorner
                model: hotcornerActions
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.actionTypeTopRightHotCorner
                onSelectedIndexChanged: shell.settings.actionTypeTopRightHotCorner = selectedIndex
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableHotCorners
                            && shell.settings.enableTopRightHotCorner
                            && shell.settings.actionTypeTopRightHotCorner == Shell.HotCorner.Indicator
                model: hotcornersIndicatorsModel
                containerHeight: itemHeight * 6
                delegate: selectorDelegate
                selectedIndex: shell.settings.actionTopRightHotCorner
                onSelectedIndexChanged: shell.settings.actionTopRightHotCorner = selectedIndex
            }
            LPSettingsSwitch {
                id: enableBottomRightHotCorner
                Layout.fillWidth: true
                text: i18n.tr("Bottom Right")
                visible: shell.settings.enableHotCorners
                onCheckedChanged: shell.settings.enableBottomRightHotCorner = checked
                Binding {
                    target: enableBottomRightHotCorner
                    property: "checked"
                    value: shell.settings.enableBottomRightHotCorner
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableHotCorners && shell.settings.enableBottomRightHotCorner
                model: hotcornerActions
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.actionTypeBottomRightHotCorner
                onSelectedIndexChanged: shell.settings.actionTypeBottomRightHotCorner = selectedIndex
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableHotCorners
                            && shell.settings.enableBottomRightHotCorner
                            && shell.settings.actionTypeBottomRightHotCorner == Shell.HotCorner.Indicator
                model: hotcornersIndicatorsModel
                containerHeight: itemHeight * 6
                delegate: selectorDelegate
                selectedIndex: shell.settings.actionBottomRightHotCorner
                onSelectedIndexChanged: shell.settings.actionBottomRightHotCorner = selectedIndex
            }
            LPSettingsSwitch {
                id: enableBottomLeftHotCorner
                Layout.fillWidth: true
                text: i18n.tr("Bottom Left")
                visible: shell.settings.enableHotCorners
                onCheckedChanged: shell.settings.enableBottomLeftHotCorner = checked
                Binding {
                    target: enableBottomLeftHotCorner
                    property: "checked"
                    value: shell.settings.enableBottomLeftHotCorner
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableHotCorners && shell.settings.enableBottomLeftHotCorner
                model: hotcornerActions
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.actionTypeBottomLeftHotCorner
                onSelectedIndexChanged: shell.settings.actionTypeBottomLeftHotCorner = selectedIndex
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableHotCorners
                            && shell.settings.enableBottomLeftHotCorner
                            && shell.settings.actionTypeBottomLeftHotCorner == Shell.HotCorner.Indicator
                model: hotcornersIndicatorsModel
                containerHeight: itemHeight * 6
                delegate: selectorDelegate
                selectedIndex: shell.settings.actionBottomLeftHotCorner
                onSelectedIndexChanged: shell.settings.actionBottomLeftHotCorner = selectedIndex
            }
        }
    }
    Component {
        id: airMousePage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Use your device as an air mouse! Toggle by swiping from bottom of the Virtual Touchpad \n"
                + " - Single tap to left click\n"
                + " - Double tap to double click\n"
                + " - Slight swipe down to right click\n"
                + " - Slight swipe up without releasing to drag\n"
                + " - Swipe on the side strip to scroll\n\n"
                + "*** Some settings do not take effect immediately. A reconnect to the external display or Lomiri restart is required."
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsSwitch {
                id: enableAirMouse
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: shell.settings.enableAirMouse = checked
                Binding {
                    target: enableAirMouse
                    property: "checked"
                    value: shell.settings.enableAirMouse
                }
            }
            LPSettingsCheckBox {
                id: airMouseAlwaysActive
                Layout.fillWidth: true
                text: "Always active Gyro"
                visible: shell.settings.enableAirMouse
                onCheckedChanged: shell.settings.airMouseAlwaysActive = checked
                Binding {
                    target: airMouseAlwaysActive
                    property: "checked"
                    value: shell.settings.airMouseAlwaysActive
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "When set to always active, gyro sensor will always move the mouse, otherwise, you have to tap and hold the touchpad"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSlider {
                id: airMouseSensitivity
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableAirMouse
                title: "Sensitivity (Higher means higher sensitivity)"
                minimumValue: 0.1
                maximumValue: 2
                stepSize: 0.1
                resetValue: 1
                live: true
                percentageValue: false
                valueIsPercentage: false
                roundValue: true
                roundingDecimal: 1
                unitsLabel: "x"
                enableFineControls: true
                onValueChanged: shell.settings.airMouseSensitivity = value
                Binding {
                    target: airMouseSensitivity
                    property: "value"
                    value: shell.settings.airMouseSensitivity
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableAirMouse
                text: i18n.tr("Mouse scroll position")
                model: [
                    i18n.tr("Right"),
                    i18n.tr("Left")
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.sideMouseScrollPosition
                onSelectedIndexChanged: shell.settings.sideMouseScrollPosition = selectedIndex
            }
            LPSettingsSlider {
                id: sideMouseScrollSensitivity
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableAirMouse
                title: "Scroll Sensitivity (Higher means higher sensitivity)"
                minimumValue: 0.1
                maximumValue: 2
                stepSize: 0.1
                resetValue: 1
                live: true
                percentageValue: false
                valueIsPercentage: false
                roundValue: true
                roundingDecimal: 1
                unitsLabel: "x"
                enableFineControls: true
                onValueChanged: shell.settings.sideMouseScrollSensitivity = value
                Binding {
                    target: sideMouseScrollSensitivity
                    property: "value"
                    value: shell.settings.sideMouseScrollSensitivity
                }
            }
            LPSettingsCheckBox {
                id: invertSideMouseScroll
                Layout.fillWidth: true
                text: "Invert mouse scroll"
                visible: shell.settings.enableAirMouse
                onCheckedChanged: shell.settings.invertSideMouseScroll = checked
                Binding {
                    target: invertSideMouseScroll
                    property: "checked"
                    value: shell.settings.invertSideMouseScroll
                }
            }
            LPSettingsCheckBox {
                id: enableSideMouseScrollHaptics
                Layout.fillWidth: true
                text: "Enable haptics while scrolling"
                visible: shell.settings.enableAirMouse
                onCheckedChanged: shell.settings.enableSideMouseScrollHaptics = checked
                Binding {
                    target: enableSideMouseScrollHaptics
                    property: "checked"
                    value: shell.settings.enableSideMouseScrollHaptics
                }
            }
        }
    }
    Component {
        id: pullDownPage

        LPSettingsPage {
            // Show gesture area hint when this page is displayed
            Component.onCompleted: if (shell.settings.enablePullDownGesture) shell.pullDownSettingsShown = true
            Component.onDestruction: shell.pullDownSettingsShown = false

            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Swipe down from the top half, bottom half or bottom custom area of the leftmost or rightmost edge to pull down the shell to a more reachable state."
                + " Swipe area is the same width as the swipe area for the side gestures."
                + " It gets disabled when the shell height is not far from the set height\n\n"
                + " • Pull Down: Swipe down and release\n"
                + " • Reset: Swipe up and release"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsSwitch {
                id: enablePullDownGesture
                Layout.fillWidth: true
                text: "Enable"

                onCheckedChanged: {
                    shell.settings.enablePullDownGesture = checked
                    shell.pullDownSettingsShown = checked
                }
                Binding {
                    target: enablePullDownGesture
                    property: "checked"
                    value: shell.settings.enablePullDownGesture
                }
            }
            OptionSelector {
                id: pullDownAreaPosition
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: i18n.tr("Swipe Area Position")
                visible: shell.settings.enablePullDownGesture
                model: [
                    i18n.tr("Top half")
                    ,i18n.tr("Bottom half")
                    ,i18n.tr("Bottom custom height")
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.pullDownAreaPosition
                onSelectedIndexChanged: shell.settings.pullDownAreaPosition = selectedIndex
            }
            LPSettingsSlider {
                id: pullDownAreaCustomHeight
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.pullDownAreaPosition === 2
                title: "Custom Area Height"
                minimumValue: 1
                maximumValue: 5
                stepSize: 0.25
                resetValue: 2
                live: true
                percentageValue: false
                valueIsPercentage: false
                roundValue: true
                roundingDecimal: 2
                unitsLabel: "inch"
                enableFineControls: true
                onValueChanged: shell.settings.pullDownAreaCustomHeight = value
                Binding {
                    target: pullDownAreaCustomHeight
                    property: "value"
                    value: shell.settings.pullDownAreaCustomHeight
                }
            }
            LPSettingsSlider {
                id: pullDownHeight
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Target Height"
                minimumValue: 2
                maximumValue: 5
                stepSize: 0.1
                resetValue: 3
                live: true
                percentageValue: false
                valueIsPercentage: false
                roundValue: true
                roundingDecimal: 1
                enableFineControls: true
                unitsLabel: "inch"
                onValueChanged: shell.settings.pullDownHeight = value
                Binding {
                    target: pullDownHeight
                    property: "value"
                    value: shell.settings.pullDownHeight
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "This also affects all expandable headers like App Grids and Indicator Panel pages"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
        }
    }
    Component {
        id: directActionsPage
        
        LPSettingsPage {
            // Show gesture area hint when this page is displayed
            Component.onCompleted: if (shell.settings.enableDirectActions) shell.directActionsSettingsShown = true
            Component.onDestruction: shell.directActionsSettingsShown = false

            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Swipe from the very bottom of left/right edge to open a floating menu that contains customizable actions\n"
                + "Lifting the swipe will trigger the currently selected action"
                + "\nCan also be access via Hot Corners"
                + "\nCan also be access with Super + Q"
                + "\nEdit mode can be used to rearrange the actions"
                + "\nTo enter Edit mode, use the button from the Actions list page,"
                + "\nLong press or right-click on an Action"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsSwitch {
                id: enableDirectActions
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: {
                    shell.settings.enableDirectActions = checked
                    shell.directActionsSettingsShown = checked
                }
                Binding {
                    target: enableDirectActions
                    property: "checked"
                    value: shell.settings.enableDirectActions
                }
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Actions List"
                visible: shell.settings.enableDirectActions
                onClicked: settingsLoader.item.stack.push(directActionsListPage, {"title": text})
            }
            LPSettingsCheckBox {
                id: directActionsEnableHint
                Layout.fillWidth: true
                text: "Show visual hint"
                visible: shell.settings.enableDirectActions
                onCheckedChanged: shell.settings.directActionsEnableHint = checked
                Binding {
                    target: directActionsEnableHint
                    property: "checked"
                    value: shell.settings.directActionsEnableHint
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDirectActions
                text: i18n.tr("Style")
                model: [
                    i18n.tr("Default"),
                    i18n.tr("Circular"),
                    i18n.tr("Rounded Square")
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.directActionsStyle
                onSelectedIndexChanged: shell.settings.directActionsStyle = selectedIndex
            }
            LPSettingsSlider {
                id: directActionsMaxColumn
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDirectActions
                title: "Max Column Count"
                minimumValue: 0
                maximumValue: 20
                stepSize: 1
                resetValue: 0
                live: false
                percentageValue: false
                valueIsPercentage: false
                roundValue: true
                roundingDecimal: 0
                enableFineControls: true
                onValueChanged: shell.settings.directActionsMaxColumn = value
                Binding {
                    target: directActionsMaxColumn
                    property: "value"
                    value: shell.settings.directActionsMaxColumn
                }
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Swipe"
                visible: shell.settings.enableDirectActions
                onClicked: settingsLoader.item.stack.push(directActionsSwipePage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Shortcut"
                visible: shell.settings.enableDirectActions
                onClicked: settingsLoader.item.stack.push(directActionsShortcutPage, {"title": text})
            }
        }
    }
    Component {
        id: directActionsShortcutPage

        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Press Super + Q to access Quick Actions"
                + "\nOraccess via Hot Corners"
                + "\nCan also be access with Super + Q"
                + "\nRight-click on an item to enter Edit mode"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsSlider {
                id: directActionsMaxWidthGU
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDirectActions
                title: "Max Width"
                minimumValue: 20
                maximumValue: 100
                stepSize: 1
                resetValue: 40
                live: true
                percentageValue: false
                valueIsPercentage: false
                roundValue: true
                roundingDecimal: 1
                unitsLabel: "GU"
                enableFineControls: true
                onValueChanged: shell.settings.directActionsMaxWidthGU = value
                Binding {
                    target: directActionsMaxWidthGU
                    property: "value"
                    value: shell.settings.directActionsMaxWidthGU
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDirectActions
                text: i18n.tr("Horizontal layout (via keyboard shortcut)")
                model: [
                    i18n.tr("Left to Right"),
                    i18n.tr("Right to Left"),
                    i18n.tr("Dynamic")
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.directActionsShortcutHorizontalLayout
                onSelectedIndexChanged: shell.settings.directActionsShortcutHorizontalLayout = selectedIndex
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDirectActions
                text: i18n.tr("Vertical layout (via keyboard shortcut)")
                model: [
                    i18n.tr("Top to Bottom"),
                    i18n.tr("Bottom to Top"),
                    i18n.tr("Dynamic")
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.directActionsShortcutVerticalLayout
                onSelectedIndexChanged: shell.settings.directActionsShortcutVerticalLayout = selectedIndex
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDirectActions
                text: i18n.tr("Animation speed")
                model: [
                    i18n.tr("Fast"),
                    i18n.tr("Brisk"),
                    i18n.tr("Snap")
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.directActionsAnimationSpeed
                onSelectedIndexChanged: shell.settings.directActionsAnimationSpeed = selectedIndex
            }
        }
    }
    Component {
        id: directActionsSwipePage
        
        LPSettingsPage {
            // Show gesture area hint when this page is displayed
            Component.onCompleted: if (shell.settings.enableDirectActions) shell.directActionsSettingsShown = true
            Component.onDestruction: shell.directActionsSettingsShown = false

            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Swipe from the very bottom of left or right edge to access Quick Actions\n"
                + "By default, lifting the swipe will trigger the currently selected action."
                + "\nThere's an option to select an item via click/tap instead."
                + "\nLong press an item to enter Edit mode"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            OptionSelector {
                id: directActionsSidesItem
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: i18n.tr("Swipe Area Edge")
                visible: shell.settings.enableDirectActions
                model: [
                    i18n.tr("Both")
                    ,i18n.tr("Left Only")
                    ,i18n.tr("Right Only")
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.directActionsSides
                onSelectedIndexChanged: shell.settings.directActionsSides = selectedIndex
            }
            LPSettingsSlider {
                id: directActionsSwipeAreaHeight
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDirectActions
                title: "Swipe Area Height"
                minimumValue: 0.1
                maximumValue: 1
                stepSize: 0.1
                resetValue: 0.3
                live: true
                percentageValue: false
                valueIsPercentage: false
                roundValue: true
                roundingDecimal: 1
                unitsLabel: "inch"
                enableFineControls: true
                onValueChanged: shell.settings.directActionsSwipeAreaHeight = value
                Binding {
                    target: directActionsSwipeAreaHeight
                    property: "value"
                    value: shell.settings.directActionsSwipeAreaHeight
                }
            }
            LPSettingsSlider {
                id: directActionsSideMargins
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDirectActions
                title: "Side margins"
                minimumValue: 0.05
                maximumValue: 2
                stepSize: 0.05
                resetValue: 0.2
                live: true
                percentageValue: false
                valueIsPercentage: false
                roundValue: true
                roundingDecimal: 2
                unitsLabel: "inch"
                enableFineControls: true
                onValueChanged: shell.settings.directActionsSideMargins = value
                Binding {
                    target: directActionsSideMargins
                    property: "value"
                    value: shell.settings.directActionsSideMargins
                }
            }
            LPSettingsSlider {
                id: directActionsMaxWidth
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDirectActions
                title: "Max Width"
                minimumValue: 1
                maximumValue: 5
                stepSize: 0.1
                resetValue: 3
                live: true
                percentageValue: false
                valueIsPercentage: false
                roundValue: true
                roundingDecimal: 1
                unitsLabel: "inch"
                enableFineControls: true
                onValueChanged: shell.settings.directActionsMaxWidth = value
                Binding {
                    target: directActionsMaxWidth
                    property: "value"
                    value: shell.settings.directActionsMaxWidth
                }
            }
            LPSettingsCheckBox {
                id: directActionsUsePhysicalSizeWhenSwiping
                Layout.fillWidth: true
                text: "Use physical size"
                visible: shell.settings.enableDirectActions
                onCheckedChanged: shell.settings.directActionsUsePhysicalSizeWhenSwiping = checked
                Binding {
                    target: directActionsUsePhysicalSizeWhenSwiping
                    property: "checked"
                    value: shell.settings.directActionsUsePhysicalSizeWhenSwiping
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Quick action item's size is fixed to an appropriate physical size and won't be affected by UI scaling"
                wrapMode: Text.WordWrap
                visible: directActionsUsePhysicalSizeWhenSwiping.visible
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsCheckBox {
                id: directActionsDynamicPositionWhenSwiping
                Layout.fillWidth: true
                text: "Position dynamically"
                visible: shell.settings.enableDirectActions
                onCheckedChanged: shell.settings.directActionsDynamicPositionWhenSwiping = checked
                Binding {
                    target: directActionsDynamicPositionWhenSwiping
                    property: "checked"
                    value: shell.settings.directActionsDynamicPositionWhenSwiping
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Items are positioned based on where the swipe started, otherwise, always positioned at the top of the swipe area"
                wrapMode: Text.WordWrap
                visible: directActionsOffsetSelectionWhenSwiping.visible
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsCheckBox {
                id: directActionsNoSwipeCommit
                Layout.fillWidth: true
                text: "Trigger actions via clicking/tapping"
                visible: shell.settings.enableDirectActions
                onCheckedChanged: shell.settings.directActionsNoSwipeCommit = checked
                Binding {
                    target: directActionsNoSwipeCommit
                    property: "checked"
                    value: shell.settings.directActionsNoSwipeCommit
                }
            }
            LPSettingsCheckBox {
                id: directActionsOffsetSelectionWhenSwiping
                Layout.fillWidth: true
                text: "Offset selection"
                visible: shell.settings.enableDirectActions && !shell.settings.directActionsNoSwipeCommit
                onCheckedChanged: shell.settings.directActionsOffsetSelectionWhenSwiping = checked
                Binding {
                    target: directActionsOffsetSelectionWhenSwiping
                    property: "checked"
                    value: shell.settings.directActionsOffsetSelectionWhenSwiping
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Select by hovering below an item, otherwise, hover directly over an item"
                wrapMode: Text.WordWrap
                visible: directActionsOffsetSelectionWhenSwiping.visible
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsCheckBox {
                id: directActionsSwipeOverOSK
                Layout.fillWidth: true
                text: "Accessible on top of the OSK"
                visible: shell.settings.enableDirectActions
                onCheckedChanged: shell.settings.directActionsSwipeOverOSK = checked
                Binding {
                    target: directActionsSwipeOverOSK
                    property: "checked"
                    value: shell.settings.directActionsSwipeOverOSK
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Swipe gesture is available even while the onscreen keyboard is displayed, otherwise, swipe won't work while the OSK is displayed"
                wrapMode: Text.WordWrap
                visible: directActionsSwipeOverOSK.visible
                font.italic: true
                textSize: Label.Small
            }
        }
    }
    Component {
        id: directActionsListPage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.topMargin: units.gu(2)
                Layout.leftMargin: units.gu(2)
                text: "Action Types:\n\n"
                + " • Indicator: Opens a specific indicator\n"
                + " • App: Opens a specific app\n"
                + " • Settings: Opens the settings app with a specific page\n"
                + " • Toggle: Toggles an item from the Quick Toggles\n"
                + " • Preset: Actions that are set to perform specific actions\n"
                + " • Custom: Actions that performs user-specified actions"
                + "\n\n\nCustom icons must be placed in ~/Pictures/lomiriplus. Color that can be colorized is #ffffff"
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Custom Actions"
                onClicked: settingsLoader.item.stack.push(customActionsPage, {"title": text})
            }
            Button {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                Layout.rightMargin: units.gu(2)
                Layout.topMargin: units.gu(1)
                Layout.bottomMargin: units.gu(1)

                text: "Add Action"
                color: theme.palette.normal.positive
                onClicked: {
                    const _addQuickAction = function(_actionId, _actionType, _customTitle, _actionDisplayType, _actionIconName) {
                        let _arrNewValues = shell.settings.directActionList.slice()
                        let _properties = { actionId: _actionId, type: _actionType, customTitle: _customTitle, displayType: _actionDisplayType, iconName: _actionIconName }
                        _arrNewValues.push(_properties)
                        shell.settings.directActionList = _arrNewValues.slice()
                    }
                    let _dialogAdd = addDirectActionDialog.createObject(shell.popupParent);
                    _dialogAdd.add.connect(_addQuickAction)
                    _dialogAdd.show()
                }
            }
            Button {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                Layout.rightMargin: units.gu(2)
                Layout.topMargin: units.gu(1)
                Layout.bottomMargin: units.gu(1)

                text: "Open in Edit mode"
                onClicked: if (directActionsLoader.item) directActionsLoader.item.openInEditMode(false, false)
            }
            Button {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                Layout.rightMargin: units.gu(2)
                Layout.topMargin: units.gu(1)
                Layout.bottomMargin: units.gu(1)

                text: directActionsListView.ViewItems.dragMode ? "Exit Rearrange" : "Rearrange"
                onClicked: directActionsListView.ViewItems.dragMode = !directActionsListView.ViewItems.dragMode
            }
            ListView {
                id: directActionsListView

                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight

                interactive: false
                model: shell.settings.directActionList

                ViewItems.dragMode: false
                ViewItems.selectMode: false
                ViewItems.onDragUpdated: {
                    if (event.status == ListItemDrag.Started) {
                        if (model[event.from] == "Immutable")
                            event.accept = false;
                        return;
                    }
                    if (model[event.to] == "Immutable") {
                        event.accept = false;
                        return;
                    }
                    // No instantaneous updates
                    if (event.status == ListItemDrag.Moving) {
                        event.accept = false;
                        return;
                    }
                    if (event.status == ListItemDrag.Dropped) {
                        var fromItem = model[event.from];
                        var list = model;
                        list.splice(event.from, 1);
                        list.splice(event.to, 0, fromItem);
                        shell.settings.directActionList = list;
                    }
                }
                delegate: ListItem {
                    id: listItem

                    property string actionId: modelData.actionId
                    property int actionType: modelData.type
                    property string customTitle: modelData.customTitle ? modelData.customTitle : ""
                    property int displayType: modelData.displayType ? modelData.displayType : LPDirectActions.DisplayType.Default
                    property string customIcon: modelData.iconName ? modelData.iconName : ""
                    readonly property var foundData: {
                        let _found

                        switch(actionType) {
                            case LPDirectActions.Type.Indicator:
                                _found = shell.indicatorsModel.find((element) => element.identifier == actionId);
                                break
                            case LPDirectActions.Type.App:
                                _found = !shell.appModel.refreshing ? shell.getAppData(actionId) : null;
                                break
                            case LPDirectActions.Type.Settings:
                                _found = shell.settingsPages.find((element) => element.identifier == actionId);
                                break
                            case LPDirectActions.Type.Toggle:
                                _found = shell.quickToggleItems.find((element) => element.identifier == actionId);
                                break
                            case LPDirectActions.Type.Custom:
                                _found = shell.customDirectActions.find((element) => element.name == actionId);
                                break
                            case LPDirectActions.Type.CustomURI:
                                _found = shell.settings.directActionsCustomURIs.find((element) => element.name == actionId);
                                break

                            return _found
                        }
                    }
                    readonly property string itemTitle: {
                        if (foundData) {
                            switch(actionType) {
                                case LPDirectActions.Type.Indicator:
                                    return foundData.name
                                case LPDirectActions.Type.App:
                                    return foundData.name
                                case LPDirectActions.Type.Settings:
                                    return foundData.name
                                case LPDirectActions.Type.Toggle:
                                    return foundData.text
                                case LPDirectActions.Type.Custom:
                                    return foundData.text
                                case LPDirectActions.Type.CustomURI:
                                    return foundData.name
                            }
                        }

                        return "Unknown"
                    }
                    readonly property string itemTypeLabel: {
                        switch(actionType) {
                            case LPDirectActions.Type.Indicator:
                                return "Indicator"
                            case LPDirectActions.Type.App:
                                return "App"
                            case LPDirectActions.Type.Settings:
                                return "Settings"
                            case LPDirectActions.Type.Toggle:
                                return "Toggle"
                            case LPDirectActions.Type.Custom:
                                return "Preset"
                            case LPDirectActions.Type.CustomURI:
                                return "Custom"
                        }

                        return "Unknown"
                    }

                    height: layout.height + (divider.visible ? divider.height : 0)
                    color: dragging ? theme.palette.selected.base : "transparent"

                    ListItemLayout {
                        id: layout
                        title.text: "[%1] %2".arg(listItem.itemTypeLabel).arg(listItem.itemTitle)
                        title.wrapMode: Text.WordWrap
                    }

                    leadingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "delete"
                                onTriggered: {
                                    let _arrNewValues = shell.settings.directActionList.slice()
                                    let _indexToDelete = _arrNewValues.findIndex((element) => (element.actionId == listItem.actionId && element.type == listItem.actionType));
                                    _arrNewValues.splice(_indexToDelete, 1)
                                    shell.settings.directActionList = _arrNewValues.slice()
                                }
                            }
                        ]
                    }

                    trailingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "edit"
                                onTriggered: {
                                    // Do not use PopupUtils to fix orientation issues
                                    let _actionId = listItem.actionId
                                    let _actionType = listItem.actionType
                                    let _customTitle = listItem.customTitle
                                    let _displayType = listItem.displayType ? listItem.displayType : "default"
                                    let _iconName = listItem.customIcon ? listItem.customIcon : ""

                                    let dialogEdit = addDirectActionDialog.createObject(shell.popupParent, { "editMode": true, "actionId": _actionId
                                                                                                            , "actionType": _actionType
                                                                                                            , "actionCustomTitle": _customTitle
                                                                                                            , "actionDisplayType": _displayType
                                                                                                            , "actionIconName": _iconName} );

                                    let _editQuickAction = function (_actionId, _actionType, _newCustomTitle, _newDisplayType, _newIconName) {
                                        const _tempArr = shell.settings.directActionList.slice()
                                        const _itemIndex = _tempArr.findIndex((element) => (element.actionId == _actionId && element.type == _actionType));
                                        const _itemData = _tempArr[_itemIndex]
                                        if (_itemData) {
                                            _itemData.customTitle = _newCustomTitle
                                            _itemData.displayType = _newDisplayType
                                            _itemData.iconName = _newIconName
                                            _tempArr[_itemIndex] = _itemData
                                            shell.settings.directActionList = _tempArr.slice()
                                        }
                                    }

                                    dialogEdit.edit.connect(_editQuickAction)
                                    dialogEdit.show()
                                }
                            }
                        ]
                    }
                }

                Component {
                    id: addDirectActionDialog
                    Dialog {
                        id: dialogue
                        
                        property bool reparentToRootItem: false
                        anchorToKeyboard: false // Handle the keyboard anchor via shell.popupParent

                        property bool editMode: false
                        property string actionId: ""
                        readonly property string currentActionId: {
                            if (currentActionType == LPDirectActions.Type.App) {
                                let _modelIndex = shell.appModel.index(actionIdSelector.selectedIndex, 0)
                                let _appId = shell.appModel.data(_modelIndex, 0)
                                return _appId ? _appId : ""
                            }

                            let _selectedItem = actionIdSelector.model[actionIdSelector.selectedIndex]
                            if (currentActionType == LPDirectActions.Type.Custom || currentActionType == LPDirectActions.Type.CustomURI) {
                                return _selectedItem && _selectedItem.name ? _selectedItem.name : ""
                            }

                            return _selectedItem && _selectedItem.identifier ? _selectedItem.identifier : ""
                        }
                        property int actionType
                        readonly property int currentActionType: actionTypeSelector.model[actionTypeSelector.selectedIndex].value
                        readonly property bool showDisplayTypeFields: {
                            switch (currentActionType) {
                                case LPDirectActions.Type.CustomURI:
                                case LPDirectActions.Type.Indicator:
                                case LPDirectActions.Type.Toggle:
                                    return false
                                default:
                                    return true
                            }
                        }
                        property int actionDisplayType
                        property string actionCustomTitle
                        property string actionIconName
                        property string currentIconName
                        property string currentCustomTitle

                        readonly property bool isCustomIcon: currentDisplayType === LPDirectActions.DisplayType.CustomIcon
                        readonly property bool isDefault: currentDisplayType === LPDirectActions.DisplayType.Default
                        readonly property bool isIcon: currentDisplayType === LPDirectActions.DisplayType.Icon


                        readonly property int currentDisplayType: iconTypeSelector.model[iconTypeSelector.selectedIndex].value

                        signal add(string actionId, string actionType, string customTitle, string displayType, string iconName)
                        signal edit(string actionId, string actionType, string customTitle, string displayType, string iconName)

                        onAdd: PopupUtils.close(dialogue)
                        onEdit: PopupUtils.close(dialogue)

                        Component.onCompleted: {
                            if (editMode) {
                                currentIconName = actionIconName
                                customTitleTextField.text = actionCustomTitle
                            }
                        }

                        OptionSelector {
                             id: actionTypeSelector

                            text: i18n.tr("Action Type")
                            enabled: !dialogue.editMode
                            model: [
                                { "name": "Indicator", "value": LPDirectActions.Type.Indicator },
                                { "name": "App", "value": LPDirectActions.Type.App },
                                { "name": "Settings", "value": LPDirectActions.Type.Settings },
                                { "name": "Toggle", "value": LPDirectActions.Type.Toggle },
                                { "name": "Preset Actions", "value": LPDirectActions.Type.Custom },
                                { "name": "Custom Actions", "value": LPDirectActions.Type.CustomURI },
                            ]
                            containerHeight: itemHeight * 6
                            selectedIndex: {
                                if (!dialogue.actionType) return 0

                                const _index = model.findIndex((element) => (element.value == dialogue.actionType));
                                return _index > -1 ? _index : 0
                            }
                            delegate: selectorDelegate
                        }
                        Component {
                            id: selectorDelegate
                            OptionSelectorDelegate { text: modelData.name }
                        }
                        OptionSelector {
                             id: actionIdSelector

                            text: i18n.tr("Action")
                            enabled: !dialogue.editMode
                            model: {
                                let _model

                                switch(dialogue.currentActionType) {
                                    case LPDirectActions.Type.Indicator:
                                        _model = shell.indicatorsModel;
                                        break
                                    case LPDirectActions.Type.App:
                                        _model = shell.appModel;
                                        break
                                    case LPDirectActions.Type.Settings:
                                        _model = shell.settingsPages;
                                        break
                                    case LPDirectActions.Type.Toggle:
                                        _model = shell.quickToggleItems;
                                        break
                                    case LPDirectActions.Type.Custom:
                                        _model = shell.customDirectActions;
                                        break
                                    case LPDirectActions.Type.CustomURI:
                                        _model = shell.settings.directActionsCustomURIs;
                                        break

                                    return _model
                                }
                            }
                            containerHeight: itemHeight * 6
                            selectedIndex: {
                                if (!dialogue.actionId) return 0

                                let _index = 0
                                let _prop = "identifier"

                                if (dialogue.actionType == LPDirectActions.Type.Custom || dialogue.actionType == LPDirectActions.Type.CustomURI) {
                                    _prop = "name"
                                }

                                if (dialogue.actionType == LPDirectActions.Type.App) {
                                    const _count = model.rowCount()
                                    for (let i = 0; i < _count; ++i) {
                                        let _modelIndex = shell.appModel.index(i, 0)
                                        let _appId = model.data(_modelIndex, 0)

                                        if (dialogue.actionId == _appId) {
                                            _index = i
                                            break
                                        }
                                    }
                                } else {
                                    _index = model.findIndex((element) => (element[_prop] == dialogue.actionId));
                                }

                                return _index
                            }
                            delegate: actionSselectorDelegate
                        }
                        Component {
                            id: actionSselectorDelegate
                            OptionSelectorDelegate {
                                text: {
                                    switch(dialogue.currentActionType) {
                                        case LPDirectActions.Type.Indicator:
                                            return modelData.name
                                        case LPDirectActions.Type.App:
                                            return model.name
                                        case LPDirectActions.Type.Settings:
                                            return modelData.name
                                        case LPDirectActions.Type.Toggle:
                                            return modelData.text
                                        case LPDirectActions.Type.Custom:
                                            return modelData.text
                                        case LPDirectActions.Type.CustomURI:
                                            return modelData.name
                                        default:
                                            return "unknown"
                                    }
                                }
                            }
                        }
                        TextField {
                            id: customTitleTextField

                            placeholderText: "Enter custom title"
                            inputMethodHints: Qt.ImhNoPredictiveText
                            onTextChanged: dialogue.currentCustomTitle = text
                        }
                        OptionSelector {
                             id: iconTypeSelector

                            text: i18n.tr("Display Type")
                            visible: dialogue.showDisplayTypeFields
                            model: [
                                { "name": "Default", "value": LPDirectActions.DisplayType.Default },
                                { "name": "Icon", "value": LPDirectActions.DisplayType.Icon },
                                { "name": "Custom Icon", "value": LPDirectActions.DisplayType.CustomIcon },
                            ]
                            containerHeight: itemHeight * 6
                            selectedIndex: {
                                switch (dialogue.actionDisplayType) {
                                    case LPDirectActions.DisplayType.Default: 
                                        return 0
                                    case LPDirectActions.DisplayType.Icon: 
                                        return 1
                                    case LPDirectActions.DisplayType.CustomIcon: 
                                        return 2
                                    default:
                                        return 0
                                }
                            }
                            delegate: selectorIconTypeDelegate
                        }
                        Component {
                            id: selectorIconTypeDelegate
                            OptionSelectorDelegate { text: modelData.name }
                        }

                        TextField {
                            id: iconNameTextField

                            visible: dialogue.showDisplayTypeFields && (dialogue.isIcon || dialogue.isCustomIcon)
                            verticalAlignment: Text.AlignVCenter
                            placeholderText: dialogue.isIcon ? "Type exact icon name" : "Type custom icon's filename"
                            inputMethodHints: Qt.ImhNoPredictiveText
                            text: dialogue.actionIconName
                            onTextChanged: dialogue.currentIconName = text
                        }
                        RowLayout {
                            visible: iconNameTextField.visible
                            height: units.gu(6)

                            Button {
                                id: iconButton

                                Layout.alignment: Qt.AlignVCenter

                                visible: dialogue.isIcon

                                text: "Pick Icon"
                                onClicked: {
                                    // Do not use PopupUtils to fix orientation issues
                                    let _iconMenu = iconMenuComponent.createObject(shell.popupParent, { caller: iconButton, currentIcon: iconNameTextField.text, model: shell.iconsList } );

                                    let _iconSelect = function (_iconName) {
                                        dialogue.currentIconName = _iconName
                                        iconNameTextField.text = _iconName
                                    }

                                    _iconMenu.iconSelected.connect(_iconSelect)
                                    _iconMenu.show()
                                }
                            }
                            Icon {
                                id: actionIconItem
                                Layout.preferredWidth: units.gu(3)
                                Layout.preferredHeight: units.gu(3)
                                name: dialogue.currentIconName
                                asynchronous: true
                                source: {
                                    if (name !== "") {
                                        if (dialogue.isCustomIcon){
                                            return LabsPlatform.StandardPaths.writableLocation(LabsPlatform.StandardPaths.HomeLocation).toString()
                                                    + "/Pictures/lomiriplus/" + dialogue.currentIconName
                                        } else {
                                            return "image://theme/" + name
                                        }
                                    }

                                    return ""
                                }
                                color: theme.palette.normal.backgroundText
                            }
                        }
                        Button {
                             text: dialogue.editMode ? "Save" : "Add"
                             color: theme.palette.normal.positive
                             onClicked: {
                                const _actionId = dialogue.currentActionId
                                const _actionType = dialogue.currentActionType
                                const _customTitle = dialogue.currentCustomTitle
                                const _displayType = dialogue.showDisplayTypeFields ? dialogue.currentDisplayType : LPDirectActions.DisplayType.Default
                                const _iconName = dialogue.showDisplayTypeFields ? dialogue.currentIconName : ""

                                if (dialogue.editMode) {
                                    dialogue.edit(_actionId, _actionType, _customTitle, _displayType, _iconName)
                                } else {
                                    dialogue.add(_actionId, _actionType, _customTitle, _displayType, _iconName)
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
            }
        }
    }
    Component {
        id: customActionsPage

        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.topMargin: units.gu(2)
                Layout.leftMargin: units.gu(2)
                text: "Custom URIs can be anything that any app can handle.\n"
                + "For example, http and https will open in Morph or other browsers you installed\n"
                + "sms:// will open the Messaging app\n"
                + "tel:// will open the Phone app\n"
                + "settings://system/battery will open the battery page in the system settings app\n\n"
                + "Custom icons must be placed in ~/Pictures/lomiriplus. Color that can be colorized is #ffffff"
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Button {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                Layout.rightMargin: units.gu(2)
                Layout.topMargin: units.gu(1)
                Layout.bottomMargin: units.gu(1)

                text: "Add Custom URI"
                color: theme.palette.normal.positive
                onClicked: {
                    // Do not use PopupUtils to fix orientation issues
                    let _dialogAdd = addCustomURIDialog.createObject(shell.popupParent, { "editMode": false });

                    let _addNewCustomURI = function (_actionName, _actionURI, _iconType, _iconName, _appId) {
                        let _tempArr = shell.settings.directActionsCustomURIs.slice()
                        let _itemData = {
                            name: _actionName
                            , uri: _actionURI
                            , iconType: _iconType
                            , iconName: _iconName
                            , appId: _appId
                        }
                        _tempArr.push(_itemData)
                        shell.settings.directActionsCustomURIs = _tempArr.slice()
                    }

                    _dialogAdd.add.connect(_addNewCustomURI)
                    _dialogAdd.show()
                }
            }
            ListView {
                id: directActionsListView

                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight

                interactive: false
                model: shell.settings.directActionsCustomURIs

                delegate: ListItem {
                    id: listItem

                    property int actionIndex: index
                    property string actionName: modelData.name
                    property string actionURI: modelData.uri
                    property string iconType: modelData.iconType
                    property string iconName: modelData.iconName
                    property string appId: modelData.appId

                    height: layout.height + (divider.visible ? divider.height : 0)
                    color: dragging ? theme.palette.selected.base : "transparent"

                    ListItemLayout {
                        id: layout
                        title.text: listItem.actionName
                        title.wrapMode: Text.WordWrap
                    }

                    leadingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "delete"
                                onTriggered: {
                                    // Delete corresponding Direct Action
                                    let _arrNewValuesDA = shell.settings.directActionList.slice()
                                    let _indexToDelete = _arrNewValuesDA.findIndex((element) => (element.actionId == listItem.actionName && element.type == LPDirectActions.Type.CustomURI));
                                    if (_indexToDelete > -1) {
                                        _arrNewValuesDA.splice(_indexToDelete, 1)
                                    }
                                    shell.settings.directActionList = _arrNewValuesDA.slice()

                                    let _arrNewValues = shell.settings.directActionsCustomURIs.slice()
                                    _arrNewValues.splice(listItem.actionIndex, 1)
                                    shell.settings.directActionsCustomURIs = _arrNewValues.slice()
                                }
                            }
                        ]
                    }
                    trailingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "edit"
                                onTriggered: {
                                    // Do not use PopupUtils to fix orientation issues
                                    let _actionName = listItem.actionName
                                    let _actionURI = listItem.actionURI
                                    let _iconName = listItem.iconName
                                    let _iconType = listItem.iconType
                                    let _appId = listItem.appId
                                    let dialogEdit = addCustomURIDialog.createObject(shell.popupParent, { "editMode": true, "actionIndex": listItem.actionIndex
                                                                                                            , "actionName": _actionName, "actionURI": _actionURI
                                                                                                            , "actionIconName": _iconName , "actionIconType": _iconType
                                                                                                            , "actionAppId": _appId } );

                                    let _editCustomURI = function (_newName, _newURI, _newIconType, _newIconName, _newAppId) {
                                        let _tempArr = shell.settings.directActionsCustomURIs.slice()
                                        let _itemData = _tempArr[listItem.actionIndex]
                                        if (_itemData) {
                                            // Update corresponding Direct Action
                                            let _arrNewValuesDA = shell.settings.directActionList.slice()
                                            let _indexToUpdate = _arrNewValuesDA.findIndex((element) => (element.actionId == listItem.actionName && element.type == LPDirectActions.Type.CustomURI));
                                            let _itemDataDA = _arrNewValuesDA[_indexToUpdate]
                                            if (_itemDataDA) {
                                                _itemDataDA.actionId = _newName
                                                _arrNewValuesDA[_indexToUpdate] = _itemDataDA
                                            }
                                            shell.settings.directActionList = _arrNewValuesDA.slice()

                                            _itemData.name = _newName
                                            _itemData.uri = _newURI
                                            _itemData.iconType = _newIconType
                                            _itemData.iconName = _newIconName
                                            _itemData.appId = _newAppId
                                            _tempArr[listItem.actionIndex] = _itemData
                                            shell.settings.directActionsCustomURIs = _tempArr.slice()
                                        }
                                    }

                                    dialogEdit.edit.connect(_editCustomURI)
                                    dialogEdit.show()
                                }
                            }
                        ]
                    }
                }

                Component {
                    id: addCustomURIDialog
                    Dialog {
                        id: dialogue

                        readonly property bool nameIsValid: actionNameTextField.text.trim() !== ""
                                                    && (
                                                            (!editMode && shell.findFromArray(shell.settings.directActionsCustomURIs, "name", currentName) == undefined)
                                                            ||
                                                            (editMode && nameHasChanged && shell.countFromArray(shell.settings.directActionsCustomURIs, "name", currentName) === 0)
                                                            ||
                                                            (editMode && !nameHasChanged && shell.countFromArray(shell.settings.directActionsCustomURIs, "name", currentName) < 2)
                                                        )
                        readonly property bool nameHasChanged: editMode && actionName !== currentName
                        readonly property bool isAppIcon: currentAppId.trim() !== ""
                        readonly property bool isCustomIcon: currentIconType === "custom"
                        readonly property bool isDefaultIcon: !isCustomIcon
                        property bool editMode: false
                        property int actionIndex
                        property string actionName
                        property string actionURI
                        property string actionIconType
                        property string actionIconName
                        property string actionAppId
                        property string currentName
                        property string currentURI
                        readonly property string currentIconType: iconTypeSelector.model[iconTypeSelector.selectedIndex].value
                        property string currentIconName
                        readonly property string currentAppId: {
                            if (useAppIcon) {
                                let _modelIndex = shell.appModel.index(actionAppIdSelector.selectedIndex, 0)
                                let _appId = shell.appModel.data(_modelIndex, 0)
                                return _appId ? _appId : ""
                            }

                            return ""
                        }
                        property bool useAppIcon: false

                        signal add(string actionName, string actionURI, string iconType, string iconName, string appId)
                        signal edit(string actionName, string actionURI, string iconType, string iconName, string appId)

                        onAdd: PopupUtils.close(dialogue)
                        onEdit: PopupUtils.close(dialogue)

                        property bool reparentToRootItem: false

                        title: editMode ? 'Edit "%1"'.arg(actionName) : "New Custom URI"
                        anchorToKeyboard: false // Handle the keyboard anchor via shell.popupParent

                        Component.onCompleted: {
                            if (editMode) {
                                actionNameTextField.text = actionName
                                actionURITextField.text = actionURI
                                iconNameTextField.text = currentIconName
                                currentName = actionName
                                currentURI = actionURI
                                currentIconName = actionIconName
                                useAppIcon = (actionAppId !== "")

                                if (useAppIcon) {
                                    let _appData = !shell.appModel.refreshing ? shell.getAppData(actionAppId) : null
                                    actionAppIdSelector.selectedIndex = _appData ? _appData.index : 0
                                }
                            }
                        }

                        TextField {
                            id: actionNameTextField

                            placeholderText: "Name of the Custom URI"
                            inputMethodHints: Qt.ImhNoPredictiveText
                            onTextChanged: dialogue.currentName = text
                        }
                        Label {
                            id: errorLabel
                            visible: actionNameTextField.text.trim() !== "" && !dialogue.nameIsValid
                            text: "Name already exists"
                            color: theme.palette.normal.negative
                        }
                        TextField {
                            id: actionURITextField

                            placeholderText: "Type the URI (i.e. tel://0123456789)"
                            inputMethodHints: Qt.ImhNoPredictiveText
                            onTextChanged: dialogue.currentURI = text
                        }
                        OptionSelector {
                             id: iconTypeSelector

                            text: i18n.tr("Icon Type")
                            model: [
                                { "name": "Default", "value": "default" },
                                { "name": "Custom", "value": "custom" },
                            ]
                            containerHeight: itemHeight * 6
                            selectedIndex: dialogue.actionIconType === "custom" ? 1 : 0
                            delegate: selectorIconTypeDelegate
                        }
                        Component {
                            id: selectorIconTypeDelegate
                            OptionSelectorDelegate { text: modelData.name }
                        }

                        TextField {
                            id: iconNameTextField

                            visible: dialogue.isDefaultIcon || dialogue.isCustomIcon
                            verticalAlignment: Text.AlignVCenter
                            placeholderText: dialogue.isDefaultIcon ?"Type exact icon name" : "Type custom icon's filename"
                            inputMethodHints: Qt.ImhNoPredictiveText
                            text: dialogue.actionIconName
                            onTextChanged: dialogue.currentIconName = text
                        }
                        RowLayout {
                            height: units.gu(6)

                            Button {
                                id: iconButton

                                Layout.alignment: Qt.AlignVCenter

                                visible: dialogue.isDefaultIcon

                                text: "Pick Icon"
                                onClicked: {
                                    // Do not use PopupUtils to fix orientation issues
                                    let _iconMenu = iconMenuComponent.createObject(shell.popupParent, { caller: iconButton, currentIcon: iconNameTextField.text, model: shell.iconsList } );

                                    let _iconSelect = function (_iconName) {
                                        dialogue.currentIconName = _iconName
                                        iconNameTextField.text = _iconName
                                    }

                                    _iconMenu.iconSelected.connect(_iconSelect)
                                    _iconMenu.show()
                                }
                            }
                            Icon {
                                id: actionIconItem
                                Layout.preferredWidth: units.gu(3)
                                Layout.preferredHeight: units.gu(3)
                                name: dialogue.currentIconName
                                asynchronous: true
                                source: {
                                    if (name !== "") {
                                        if (dialogue.isCustomIcon){
                                            return LabsPlatform.StandardPaths.writableLocation(LabsPlatform.StandardPaths.HomeLocation).toString()
                                                    + "/Pictures/lomiriplus/" + dialogue.currentIconName
                                        } else {
                                            return "image://theme/" + name
                                        }
                                    }

                                    return ""
                                }
                                color: theme.palette.normal.backgroundText
                            }
                        }

                        LPSettingsCheckBox {
                            id: useAppIconCheckBox
                            text: "Display as an App"
                            onCheckedChanged: dialogue.useAppIcon = checked
                            Binding {
                                target: useAppIconCheckBox
                                property: "checked"
                                value: dialogue.useAppIcon
                            }
                        }

                        OptionSelector {
                             id: actionAppIdSelector

                            visible: dialogue.useAppIcon
                            text: i18n.tr("App ID")
                            model: shell.appModel
                            containerHeight: itemHeight * 6
                            selectedIndex: 0
                            delegate: actionAppIdselectorDelegate
                        }
                        Component {
                            id: actionAppIdselectorDelegate
                            OptionSelectorDelegate {
                                text: model.name
                            }
                        }

                        Button {
                            text: dialogue.editMode ? "Save" : "Add"
                            color: theme.palette.normal.positive
                            enabled: dialogue.nameIsValid
                            onClicked: {
                                let _actionName = dialogue.currentName
                                let _actionURI = dialogue.currentURI
                                let _actionIconType = dialogue.currentIconType
                                let _actionIconName = dialogue.currentIconName
                                let _actionAppId = dialogue.useAppIcon ? dialogue.currentAppId : ""

                                if (dialogue.editMode) {
                                    dialogue.edit(_actionName, _actionURI, _actionIconType, _actionIconName, _actionAppId)
                                } else {
                                    dialogue.add(_actionName, _actionURI, _actionIconType, _actionIconName, _actionAppId)
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
            }
        }
    }
    Component {
        id: indicatorOpenPage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Swipe from the very bottom of left/right edge to open the application menu/indicator panel\n\n"
                + " • Default: Indicator panel or application menu opens after swiping\n"
                + " • Direct Access (Only for indicators): Swipe and drag to select a specific predefined indicator. Release to select. "
                + "Quick short swipe will open the Notifications/Messages Indicator"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsSwitch {
                id: indicatorGesture
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: shell.settings.indicatorGesture = checked
                Binding {
                    target: indicatorGesture
                    property: "checked"
                    value: shell.settings.indicatorGesture
                }
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Direct Access"
                onClicked: settingsLoader.item.stack.push(directAccessPage, {"title": text})
            }
        }
    }
    Component {
        id: directAccessPage
        
        LPSettingsPage {
            LPSettingsSwitch {
                id: specificIndicatorGesture
                Layout.fillWidth: true
                text: "Enable"
                visible: shell.settings.indicatorGesture
                onCheckedChanged: shell.settings.specificIndicatorGesture = checked
                Binding {
                    target: specificIndicatorGesture
                    property: "checked"
                    value: shell.settings.specificIndicatorGesture
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                Layout.preferredHeight: units.gu(8)
                text: "Indicators:\n"
                + "Click the item and not the checkbox :)\n"
                + "Avoid enabling too many items"
                verticalAlignment: Text.AlignVCenter
            }
            ListView {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                Layout.preferredHeight: contentHeight

                interactive: false
                model: shell.settings.directAccessIndicators

                ViewItems.dragMode: true
                ViewItems.selectMode: true
                ViewItems.onDragUpdated: {
                    if (event.status == ListItemDrag.Started) {
                        if (model[event.from] == "Immutable")
                            event.accept = false;
                        return;
                    }
                    if (model[event.to] == "Immutable") {
                        event.accept = false;
                        return;
                    }
                    // No instantaneous updates
                    if (event.status == ListItemDrag.Moving) {
                        event.accept = false;
                        return;
                    }
                    if (event.status == ListItemDrag.Dropped) {
                        var fromItem = model[event.from];
                        var list = model;
                        list.splice(event.from, 1);
                        list.splice(event.to, 0, fromItem);
                        shell.settings.directAccessIndicators = list;
                    }
                }
                delegate: ListItem {
                    height: layout.height + (divider.visible ? divider.height : 0)
                    color: dragging ? theme.palette.selected.base : "transparent"
                    selected: modelData.enabled
                    onClicked: {
                        let arrNewValues = shell.settings.directAccessIndicators.slice()
                        arrNewValues[model.index].enabled = !selected
                        shell.settings.directAccessIndicators = arrNewValues
                    }

                    ListItemLayout {
                        id: layout
                        title.text:  shell.indicatorLabel(shell.indicatorsModel[modelData.id].identifier)
                    }
                }
            }
        }
    }
    Component {
        id: dynamicCovePage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Enables different functions inside the lockscreen circle\n"
                + "Media controls, Timer, Stopwatch, Clock, etc\n\n"
                + "Press and drag on the dotted cirlce to select a function\n"
                + "Short swipe up from bottom to hide or show"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsSwitch {
                id: enableDynamicCove
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: shell.settings.enableDynamicCove = checked
                Binding {
                    target: enableDynamicCove
                    property: "checked"
                    value: shell.settings.enableDynamicCove
                }
            }
            LPSettingsCheckBox {
                id: showInfographicsOnDesktop
                Layout.fillWidth: true
                text: i18n.tr("Show on the desktop when unlocked")
                onCheckedChanged: shell.settings.showInfographicsOnDesktop = checked
                Binding {
                    target: showInfographicsOnDesktop
                    property: "checked"
                    value: shell.settings.showInfographicsOnDesktop
                }
            }
            LPSettingsCheckBox {
                id: darkenWallpaperWhenInfographics
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                visible: showInfographicsOnDesktop.visible && shell.settings.showInfographicsOnDesktop
                text: i18n.tr("Darken wallpaper on the desktop")
                onCheckedChanged: shell.settings.darkenWallpaperWhenInfographics = checked
                Binding {
                    target: darkenWallpaperWhenInfographics
                    property: "checked"
                    value: shell.settings.darkenWallpaperWhenInfographics
                }
            }
            LPSettingsSlider {
                id: darkenWallpaperWhenInfographicsOpacity
                Layout.fillWidth: true
                Layout.margins: units.gu(4)
                visible: darkenWallpaperWhenInfographics.visible && shell.settings.darkenWallpaperWhenInfographics
                title: "Opacity"
                minimumValue: 0
                maximumValue: 100
                stepSize: 10
                resetValue: 100
                live: true
                percentageValue: true
                valueIsPercentage: true
                enableFineControls: true
                roundValue: true
                onValueChanged: shell.settings.darkenWallpaperWhenInfographicsOpacity = value
                Binding {
                    target: darkenWallpaperWhenInfographicsOpacity
                    property: "value"
                    value: shell.settings.darkenWallpaperWhenInfographicsOpacity
                }
            }
            LPSettingsSlider {
                id: dynamicCoveSelectionDelay
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDynamicCove
                title: "Selection delay"
                minimumValue: 0
                maximumValue: 1000
                stepSize: 50
                resetValue: 100
                live: false
                roundValue: true
                unitsLabel: "ms"
                onValueChanged: shell.settings.dynamicCoveSelectionDelay = value
                Binding {
                    target: dynamicCoveSelectionDelay
                    property: "value"
                    value: shell.settings.dynamicCoveSelectionDelay
                }
            }
            LPSettingsCheckBox {
                id: dcShowClockWhenLockscreen
                Layout.fillWidth: true
                text: "Always prefer to show clock"
                visible: shell.settings.enableDynamicCove
                onCheckedChanged: shell.settings.dcShowClockWhenLockscreen = checked
                Binding {
                    target: dcShowClockWhenLockscreen
                    property: "checked"
                    value: shell.settings.dcShowClockWhenLockscreen
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Entering the lockscreen will always show the clock\n"
                + "Otherwise, the last selected will be shown"
                wrapMode: Text.WordWrap
                visible: dcShowClockWhenLockscreen.visible
                font.italic: true
                textSize: Label.Small
            }
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDynamicCove
                text: "Media Controls"
                wrapMode: Text.WordWrap
                textSize: Label.Large
            }
            LPSettingsCheckBox {
                id: dcCDPlayerSimpleMode
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                text: "Simple Mode"
                visible: shell.settings.enableDynamicCove
                onCheckedChanged: shell.settings.dcCDPlayerSimpleMode = checked
                Binding {
                    target: dcCDPlayerSimpleMode
                    property: "checked"
                    value: shell.settings.dcCDPlayerSimpleMode
                }
            }
            LPSettingsSlider {
                id: dcCDPlayerOpacity
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                Layout.leftMargin: units.gu(4)
                visible: shell.settings.enableDynamicCove
                title: "CD Player Opacity"
                minimumValue: 0.1
                maximumValue: 1
                stepSize: 0.1
                resetValue: 1
                live: false
                percentageValue: true
                roundValue: true
                enableFineControls: true
                onValueChanged: shell.settings.dcCDPlayerOpacity = value
                Binding {
                    target: dcCDPlayerOpacity
                    property: "value"
                    value: shell.settings.dcCDPlayerOpacity
                }
            }
            LPSettingsCheckBox {
                id: dcBlurredAlbumArt
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                text: "Blurred album art"
                visible: shell.settings.enableDynamicCove
                onCheckedChanged: shell.settings.dcBlurredAlbumArt = checked
                Binding {
                    target: dcBlurredAlbumArt
                    property: "checked"
                    value: shell.settings.dcBlurredAlbumArt
                }
            }
            LPSettingsSwitch {
                id: enableAmbientModeInCDPlayer
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                text: "Ambient Mode"
                visible: shell.settings.enableDynamicCove
                onCheckedChanged: shell.settings.enableAmbientModeInCDPlayer = checked
                Binding {
                    target: enableAmbientModeInCDPlayer
                    property: "checked"
                    value: shell.settings.enableAmbientModeInCDPlayer
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(6)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Displays the album art around the CD player in subtle style"
                wrapMode: Text.WordWrap
                visible: enableAmbientModeInCDPlayer.visible
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsCheckBox {
                id: hideCDPlayerWhenScreenOff
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                text: "Hide CD Player when screen is off"
                visible: shell.settings.enableDynamicCove
                onCheckedChanged: shell.settings.hideCDPlayerWhenScreenOff = checked
                Binding {
                    target: hideCDPlayerWhenScreenOff
                    property: "checked"
                    value: shell.settings.hideCDPlayerWhenScreenOff
                }
            }
            LPSettingsSwitch {
                id: enableCDPlayerDiscoCheck
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                text: "Enable Disco mode in CD Player"
                visible: shell.settings.enableDynamicCove
                onCheckedChanged: shell.settings.enableCDPlayerDisco = checked
                Binding {
                    target: enableCDPlayerDiscoCheck
                    property: "checked"
                    value: shell.settings.enableCDPlayerDisco
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(6)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Press and hold to toggle disco mode"
                wrapMode: Text.WordWrap
                visible: enableCDPlayerDiscoCheck.visible
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsCheckBox {
                id: hideCirclesWhenCDPlayer
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(2)
                text: "Hide inforgraphics circles"
                visible: shell.settings.enableDynamicCove
                onCheckedChanged: shell.settings.hideCirclesWhenCDPlayer = checked
                Binding {
                    target: hideCirclesWhenCDPlayer
                    property: "checked"
                    value: shell.settings.hideCirclesWhenCDPlayer
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDynamicCove
                text: "For playlists to work, create a symlink of the music app's database files\n"
                + "Source: /home/phablet/.local/share/music.ubports/Databases/\n"
                + "Destination: /home/phablet/.local/share/UBports/lomiri/QML/OfflineStorage/Databases/\n"
                + "Files:"
                + " - 2be3974e34f63282a99a37e9e2077ee4.sqlite\n"
                + " - 2be3974e34f63282a99a37e9e2077ee4.ini\n"
                + " - d332dbaaf4b3a1a7909b1d623eb1d02b.sqlite\n"
                + " - d332dbaaf4b3a1a7909b1d623eb1d02b.ini"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
        }
    }
    Component {
        id: disableTogglesPage

        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "List toggles that will be disabled when the device is locked. \n"
                + "This will affect the standard indicator toggles as well as Quick Toggles and Quick Actions.\n"
                + "They can be set to be disabled always, only when turned on or only when turned off"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsSwitch {
                id: disableTogglesOnLockscreen
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: shell.settings.disableTogglesOnLockscreen = checked
                Binding {
                    target: disableTogglesOnLockscreen
                    property: "checked"
                    value: shell.settings.disableTogglesOnLockscreen
                }
            }
            ColumnLayout {
                visible: shell.settings.disableTogglesOnLockscreen

                Button {
                    Layout.fillWidth: true
                    Layout.leftMargin: units.gu(2)
                    Layout.rightMargin: units.gu(2)
                    Layout.topMargin: units.gu(1)
                    Layout.bottomMargin: units.gu(1)

                    text: "Add"
                    color: theme.palette.normal.positive
                    onClicked: {
                        let _dialogAdd = addToggleDialog.createObject(shell.popupParent);
                        _dialogAdd.show()
                    }
                }

                ListView {
                    id: disabledTogglesListView

                    Layout.fillWidth: true
                    Layout.preferredHeight: contentHeight

                    interactive: false
                    model: shell.settings.togglesToDisableOnLockscreen

                    delegate: ListItem {
                        id: listItem

                        property string identifier: modelData.identifier
                        property int disableWhen: modelData.when
                        readonly property var foundData: {
                            let _found = shell.quickToggleItems.find((element) => element.identifier == identifier);
                            return _found
                        }
                        readonly property string itemTitle: {
                            if (foundData) {
                                return foundData.text
                            }

                            return "Unknown"
                        }
                        readonly property string itemWhenLabel: {
                            switch (disableWhen) {
                                case 0:
                                    return "Always"
                                case 1:
                                    return "When On"
                                case 2:
                                    return "When Off"
                                default:
                                    return "Never"
                            }
                        }

                        height: layout.height + (divider.visible ? divider.height : 0)
                        color: "transparent"

                        function changeWhen() {
                            let _arrNewValues = shell.settings.togglesToDisableOnLockscreen.slice()
                            let _indexToChange = _arrNewValues.findIndex((element) => (element.identifier == listItem.identifier));
                            let _currentItem = _arrNewValues[_indexToChange]
                            let _currentWhen = _currentItem.when
                            _currentItem.when = _currentWhen == 2 ? 0 : _currentWhen + 1
                            _arrNewValues[_indexToChange] = _currentItem
                            shell.settings.togglesToDisableOnLockscreen = _arrNewValues.slice()
                        }

                        onClicked: changeWhen()

                        ListItemLayout {
                            id: layout
                            title.text: listItem.itemTitle
                            title.wrapMode: Text.WordWrap

                            Label {
                                SlotsLayout.position: SlotsLayout.Trailing

                                text: listItem.itemWhenLabel
                                wrapMode: Text.WordWrap
                            }
                        }

                        leadingActions: ListItemActions {
                            actions: [
                                Action {
                                    iconName: "delete"
                                    onTriggered: {
                                        let _arrNewValues = shell.settings.togglesToDisableOnLockscreen.slice()
                                        let _indexToDelete = _arrNewValues.findIndex((element) => (element.identifier == listItem.identifier));
                                        _arrNewValues.splice(_indexToDelete, 1)
                                        shell.settings.togglesToDisableOnLockscreen = _arrNewValues.slice()
                                    }
                                }
                            ]
                        }
                    }

                    Component {
                        id: addToggleDialog
                        Dialog {
                            id: toggleDialogue
                            
                            property bool reparentToRootItem: false
                            anchorToKeyboard: false // Handle the keyboard anchor via shell.popupParent

                            property string identifier: togglesSelector.model[togglesSelector.selectedIndex].identifier
                            property int disableWhen: whenSelector.model[whenSelector.selectedIndex].value

                            Component.onCompleted: {
                                // Filter already added toggles
                                let _filteredModel = []
                                let _togglesList = shell.quickToggleItems
                                let _disabledTogglesList = shell.settings.togglesToDisableOnLockscreen
                                let _arrLength = _togglesList.length

                                for (let i = 0; i < _arrLength; ++i) {
                                    let _currentItem = _togglesList[i]
                                    let _currentText = _currentItem.text
                                    let _currentIdentifier = _currentItem.identifier

                                    if (!shell.findFromArray(_disabledTogglesList, "identifier", _currentIdentifier)
                                            && !(_currentText == "Media Player" || _currentText == "Brightness" || _currentText == "Volume")) {
                                        _filteredModel.push(_currentItem)
                                    }
                                }

                                togglesSelector.model = _filteredModel.slice()
                            }

                            OptionSelector {
                                 id: togglesSelector

                                text: i18n.tr("Action")
                                containerHeight: itemHeight * 6
                                selectedIndex: 0
                                delegate: toggleSselectorDelegate
                            }
                            Component {
                                id: toggleSselectorDelegate
                                OptionSelectorDelegate {
                                    text: modelData.text
                                }
                            }
                            OptionSelector {
                                 id: whenSelector

                                text: i18n.tr("Action")
                                model: [
                                    { text: "Always", value: 0 }
                                    ,{ text: "When On", value: 1 }
                                    ,{ text: "When Off", value: 2 }
                                ]
                                containerHeight: itemHeight * 6
                                selectedIndex: 0
                                delegate: whenSselectorDelegate
                            }
                            Component {
                                id: whenSselectorDelegate
                                OptionSelectorDelegate {
                                    text: modelData.text
                                }
                            }
                            Button {
                                 text: "Add"
                                 color: theme.palette.normal.positive
                                 onClicked: {
                                     let _arrNewValues = shell.settings.togglesToDisableOnLockscreen.slice()
                                    let _properties = { identifier: toggleDialogue.identifier, when: toggleDialogue.disableWhen }
                                    _arrNewValues.push(_properties)
                                    shell.settings.togglesToDisableOnLockscreen = _arrNewValues.slice()
                                    PopupUtils.close(toggleDialogue)
                                 }
                             }
                             Button {
                                 text: "Cancel"
                                 onClicked: PopupUtils.close(toggleDialogue)
                             }
                         }
                    }
                }
            }
        }
    }
    Component {
        id: quickTogglesPage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Located at the bottom of Top Panel pages\n"
                + "Single click: Toggles the setting\n"
                + "Press and hold: Opens corresponding indicator panel or settings page\n"
                + "Swipe up/down: Expands/Collapses the toggles list\n"
                + "Press and hold on empty space: Enter/Exit edit mode\n"
                + "Press and hold then drag to rearrange items"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsSwitch {
                id: quickTogglesTopPanel
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: shell.settings.enableQuickToggles = checked
                Binding {
                    target: quickTogglesTopPanel
                    property: "checked"
                    value: shell.settings.enableQuickToggles
                }
            }
            LPSettingsSlider {
                id: quickTogglesCollapsedRowCount
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableQuickToggles
                title: "Collapsed Row Count"
                minimumValue: 1
                maximumValue: 5
                stepSize: 1
                resetValue: 1
                live: false
                roundValue: true
                enableFineControls: true
                onValueChanged: shell.settings.quickTogglesCollapsedRowCount = value
                Binding {
                    target: quickTogglesCollapsedRowCount
                    property: "value"
                    value: shell.settings.quickTogglesCollapsedRowCount
                }
            }
            LPSettingsCheckBox {
                id: quickTogglesOnlyShowInNotifications
                Layout.fillWidth: true
                visible: shell.settings.enableQuickToggles
                text: "Only display in Notifications/Messages Panel"
                onCheckedChanged: shell.settings.quickTogglesOnlyShowInNotifications = checked
                Binding {
                    target: quickTogglesOnlyShowInNotifications
                    property: "checked"
                    value: shell.settings.quickTogglesOnlyShowInNotifications
                }
            }
            LPSettingsCheckBox {
                id: autoCollapseQuickToggles
                Layout.fillWidth: true
                visible: shell.settings.enableQuickToggles
                text: "Collapse on panel close"
                onCheckedChanged: shell.settings.autoCollapseQuickToggles = checked
                Binding {
                    target: autoCollapseQuickToggles
                    property: "checked"
                    value: shell.settings.autoCollapseQuickToggles
                }
            }
            LPSettingsCheckBox {
                id: gestureMediaControls
                Layout.fillWidth: true
                text: "Gesture-mode media controls"
                visible: shell.settings.enableQuickToggles
                onCheckedChanged: shell.settings.gestureMediaControls = checked
                Binding {
                    target: gestureMediaControls
                    property: "checked"
                    value: shell.settings.gestureMediaControls
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                visible: gestureMediaControls.visible
                text: "Single click: Play/Pause\n"
                            + "Swipe left/right: Play next/previous song"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
        }
    }
    Component {
        id: devicePage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Most configuration only takes effect when your device doesn't have pre-configuration"
                font.italic: true
                wrapMode: Text.WordWrap
                textSize: Label.Small
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: units.dp(1)
                color: Suru.neutralColor
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Notch / Punchhole"
                onClicked: settingsLoader.item.stack.push(notchpage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Punchhole Battery (Experimental)"
                onClicked: settingsLoader.item.stack.push(punchPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Rounded Corners"
                onClicked: settingsLoader.item.stack.push(cornerPage, {"title": text})
            }

            Component {
                id: notchpage
                
                LPSettingsPage {
                    OptionSelector {
                        id: notchPositionItem
                        readonly property bool notchEnabled: shell.settings.notchPosition > 0
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: i18n.tr("Notch Position")
                        model: [
                            i18n.tr("None")
                            ,i18n.tr("Middle")
                            ,i18n.tr("Left")
                            ,i18n.tr("Right")
                        ]
                        containerHeight: itemHeight * 6
                        selectedIndex: shell.settings.notchPosition
                        onSelectedIndexChanged: shell.settings.notchPosition = selectedIndex
                    }
                    LPSettingsCheckBox {
                        id: balanceMiddleNotchMargin
                        Layout.fillWidth: true
                        visible: shell.settings.notchPosition == 1
                        text: "Balanced icon spacing for the middle notch"
                        onCheckedChanged: shell.settings.balanceMiddleNotchMargin = checked
                        Binding {
                            target: balanceMiddleNotchMargin
                            property: "checked"
                            value: shell.settings.balanceMiddleNotchMargin
                        }
                    }
                    LPSettingsCheckBox {
                        id: showMiddleNotchHint
                        Layout.fillWidth: true
                        visible: shell.settings.notchPosition == 1
                        text: "Show middle notch hint"
                        onCheckedChanged: shell.settings.showMiddleNotchHint = checked
                        Binding {
                            target: showMiddleNotchHint
                            property: "checked"
                            value: shell.settings.showMiddleNotchHint
                        }
                    }
                    LPSettingsCheckBox {
                        id: fullyHideNotchInNative
                        Layout.fillWidth: true
                        visible: notchPositionItem.notchEnabled
                        text: "Fully hide notch in native orientation"
                        onCheckedChanged: shell.settings.fullyHideNotchInNative = checked
                        Binding {
                            target: fullyHideNotchInNative
                            property: "checked"
                            value: shell.settings.fullyHideNotchInNative
                        }
                    }
                    LPSettingsSlider {
                        id: notchHeightMargin
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: notchPositionItem.notchEnabled
                        title: "Notch Top Margin"
                        enableFineControls: true
                        minimumValue: 0
                        maximumValue: 400
                        stepSize: 1
                        resetValue: 0
                        live: true
                        roundValue: true
                        unitsLabel: "px"
                        onValueChanged: shell.settings.notchHeightMargin = value
                        Binding {
                            target: notchHeightMargin
                            property: "value"
                            value: shell.settings.notchHeightMargin
                        }
                    }
                    LPSettingsSlider {
                        id: notchWidthMargin
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: notchPositionItem.notchEnabled
                        title: "Notch Width Margin"
                        enableFineControls: true
                        minimumValue: 0
                        maximumValue: 400
                        stepSize: 1
                        resetValue: 0
                        live: true
                        roundValue: true
                        unitsLabel: "px"
                        onValueChanged: shell.settings.notchWidthMargin = value
                        Binding {
                            target: notchWidthMargin
                            property: "value"
                            value: shell.settings.notchWidthMargin
                        }
                    }
                }
            }
            Component {
                id: punchPage
                
                LPSettingsPage {
                    LPSettingsSlider {
                        id: punchHoleWidth
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        title: "Exact Punchhole Width"
                        enableFineControls: true
                        minimumValue: 0
                        maximumValue: 300
                        stepSize: 1
                        resetValue: 0
                        live: true
                        roundValue: true
                        unitsLabel: "px"
                        onValueChanged: shell.settings.punchHoleWidth = value
                        Binding {
                            target: punchHoleWidth
                            property: "value"
                            value: shell.settings.punchHoleWidth
                        }
                    }
                    LPSettingsSlider {
                        id: punchHoleHeightFromTop
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        title: "Punchhole Height From Top"
                        enableFineControls: true
                        minimumValue: 0
                        maximumValue: 200
                        stepSize: 1
                        resetValue: 0
                        unitsLabel: "px"
                        live: true
                        roundValue: true
                        onValueChanged: shell.settings.punchHoleHeightFromTop = value
                        Binding {
                            target: punchHoleHeightFromTop
                            property: "value"
                            value: shell.settings.punchHoleHeightFromTop
                        }
                    }
                }
            }
            Component {
                id: cornerPage
                
                LPSettingsPage {
                    LPSettingsSlider {
                        id: roundedCornerMargin
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        title: "Corner Margin"
                        enableFineControls: true
                        minimumValue: 0
                        maximumValue: 200
                        stepSize: 1
                        resetValue: 0
                        live: true
                        roundValue: true
                        unitsLabel: "px"
                        onValueChanged: shell.settings.roundedCornerMargin = value
                        Binding {
                            target: roundedCornerMargin
                            property: "value"
                            value: shell.settings.roundedCornerMargin
                        }
                    }
                    LPSettingsSlider {
                        id: roundedCornerRadius
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        title: "Corner Radius"
                        enableFineControls: true
                        minimumValue: 0
                        maximumValue: 500
                        stepSize: 1
                        resetValue: 0
                        live: true
                        roundValue: true
                        unitsLabel: "px"
                        onValueChanged: shell.settings.roundedCornerRadius = value
                        Binding {
                            target: roundedCornerRadius
                            property: "value"
                            value: shell.settings.roundedCornerRadius
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: units.gu(4)
                        Layout.rightMargin: units.gu(2)
                        Layout.bottomMargin: units.gu(2)
                        text: "Only necessary or has effects when a notch/punchhole is configured"
                        wrapMode: Text.WordWrap
                        font.italic: true
                        textSize: Label.Small
                    }
                }
            }
        }
    }
    // ENH046 - End
    // ENH064 - Dynamic Cove
    Settings {
        id: clockAppSettings

        fileName: LabsPlatform.StandardPaths.writableLocation(LabsPlatform.StandardPaths.ConfigLocation).toString().replace("file://", "")
                                                    + "/clock.ubports/clock.ubports.conf"
        Component.onCompleted: alarm.defaultSound = value("defaultAlarmSound", "file:///usr/share/sounds/lomiri/ringtones/Alarm clock.ogg")
    }
    Alarm {
        id: alarm

        readonly property string defaultId: "[LomiriPlus] Current Timer"
        property url defaultSound: "file:///usr/share/sounds/lomiri/ringtones/Ubuntu.ogg"

        onStatusChanged: {
            if (status !== Alarm.Ready)
                return
            if ((operation > Alarm.NoOperation)
                    && (operation < Alarm.Reseting)) {
                reset()
            }
        }
    }

    AlarmModel {
        id: alarmModel
    }

    Loader {
        id: mediaPlayerLoader

        function reloadSource() {
            active = false
            active = true
            active = Qt.binding(function() { return shell.settings.enableDynamicCove } )
            console.log("Media Player reloaded!!!!!!")
        }

        active: shell.settings.enableDynamicCove
        asynchronous: true
        sourceComponent: Component {
            Item {
                id: mediaPlayer

                readonly property bool isReady: allSongsModelModel.status === SongsModel.Ready
                readonly property alias musicStore: musicStore
                readonly property bool isPlaying: mediaPlayerObject.playbackState == MediaPlayer.PlayingState
                readonly property bool isPaused: mediaPlayerObject.playbackState == MediaPlayer.PausedState
                readonly property bool isStopped: mediaPlayerObject.playbackState == MediaPlayer.StoppedState
                readonly property bool noMedia: mediaPlayerObject.status == MediaPlayer.NoMedia

                property string currentPlaylist: ""

                // Clear the queue and play a random track from this model
                // - user has selected "Shuffle" in album/artists or "Tap to play random"
                function playRandomSong(model) {
                    // If no model is given use all the tracks
                    if (model === undefined) {
                        model = allSongsModel;
                    }

                    mediaPlayerObject.playlist.clearWrapper();
                    mediaPlayerObject.playlist.addItemsFromModel(model);

                    // Once the model count has been reached in the queue
                    // shuffle the model
                    mediaPlayerObject.playlist.setPendingShuffle(model.count);
                }

                function play() {
                    mediaPlayerObject.play()
                }

                function clear() {
                    mediaPlayerObject.playlist.clearWrapper()
                }

                MediaStore {
                    id: musicStore
                }

                SortFilterModel {
                    id: allSongsModel

                    property alias rowCount: allSongsModelModel.rowCount
                    model: SongsModel {
                        id: allSongsModelModel

                        store: musicStore
                    }
                    sort.property: "title"
                    sort.order: Qt.AscendingOrder
                    sortCaseSensitivity: Qt.CaseInsensitive
                }

                Audio {
                    id: mediaPlayerObject

                    playlist: Playlist {
                        id: mediaPlayerPlaylist

                        playbackMode: Playlist.Random

                        readonly property int count: itemCount  // header actions etc depend on the model having 'count'
                        readonly property bool empty: itemCount === 0
                        property int pendingCurrentIndex: -1
                        property var pendingCurrentState: null
                        property int pendingShuffle: -1
                        
                        // as that doesn't emit changes
                        readonly property bool canGoPrevious: {  // FIXME: pad.lv/1517580 use previousIndex() > -1 after mh implements it
                            currentIndex !== 0 ||
                            mediaPlayerObject.position > 5000
                        }
                        readonly property bool canGoNext: {  // FIXME: pad.lv/1517580 use nextIndex() > -1 after mh implements it
                            currentIndex !== (itemCount - 1)
                        }

                        function addItemsFromModel(model) {
                            var items = []

                            // TODO: remove once playlists uses U1DB
                            if (model.hasOwnProperty("linkLibraryListModel")) {
                                model = model.linkLibraryListModel;
                            }

                            for (var i=0; i < model.rowCount; i++) {
                                items.push(Qt.resolvedUrl(model.get(i, model.RoleModelData).filename));
                            }

                            mediaPlayerObject.playlist.addItems(items);
                        }

                        // Wrap the clear() method because we need to call stop first
                        function clearWrapper() {
                            // Stop the current playback (this ensures that play is run later)
                            if (mediaPlayerObject.playbackState === MediaPlayer.PlayingState) {
                                mediaPlayerObject.stop();
                            }

                            return console.log("Clear Playlist: " + clear())
                        }

                        // Replicates a model.get() on a ms2 model
                        function get(index, role) {
                            return metaForSource(itemSource(index));
                        }

                        // Wrap the next() method so we can check canGoNext
                        function nextWrapper() {
                            if (canGoNext) {
                                next();
                            }
                        }

                        // Wrap the previous() method so we can check canGoPrevious
                        function previousWrapper() {
                            if (canGoPrevious) {
                                previous();
                            }
                        }

                        // Process the pending current PlaybackState
                        function processPendingCurrentState() {
                            if (pendingCurrentState === MediaPlayer.PlayingState) {
                                console.debug("Loading pending state play()");
                                mediaPlayerObject.play();
                            } else if (pendingCurrentState === MediaPlayer.PausedState) {
                                console.debug("Loading pending state pause()");
                                mediaPlayerObject.pause();
                            } else if (pendingCurrentState === MediaPlayer.StoppedState) {
                                console.debug("Loading pending state stop()");
                                mediaPlayerObject.stop();
                            }

                            pendingCurrentState = null;
                        }

                        function setPendingShuffle(modelSize) {
                            // Run next() and play() when the modelSize is reached
                            if (modelSize <= itemCount) {
                                mediaPlayerPlaylist.nextWrapper();  // find a random track
                                mediaPlayerObject.play();  // next does not enforce play
                            } else {
                                pendingShuffle = modelSize;
                            }
                        }
                    }

                    property bool endOfMedia: false

                    onStatusChanged: {
                        if (status == MediaPlayer.EndOfMedia && settings.repeat == "none") {
                            console.debug("End of media, stopping.")

                            // Tells the onStopped to set the curentIndex = 0
                            endOfMedia = true;

                            stop();
                        }
                    }

                    function toggle() {
                        if (playbackState === MediaPlayer.PlayingState) {
                            pause();
                        } else {
                            play();
                        }
                    }
                }
            }
        }
    }
    // ENH064 - End
    
    // ENH002 - Notch/Punch hole fix
    DeviceConfiguration {
        id: deviceConfiguration
        //name: applicationArguments.deviceName // Removed in focal since it causes an error
        // ENH046 - Lomiri Plus Settings
        shell: shell
        // ENH046 - End
    }

    // ENH032 - Infographics Outer Wilds
    Loader {
        id: eyeBlinkLoader
        active: false
        asynchronous: true
        z: 1000 
        anchors {
            fill: parent
        }
        Connections {
            target: greeter
            function onShownChanged() {
                // ENH135 - Show Desktop
                //if (!target.shown && stage.topLevelSurfaceList.count == 0) {
                if (!target.shown && (stage.topLevelSurfaceList.count == 0 || stage.desktopShown)) {
                // ENH135 - End
                    eyeBlinkLoader.active = lp_settings.enableOW && lp_settings.ow_theme == 0
                }
            }
        }
        sourceComponent: Component {
            Rectangle {
                id: blinkRec

                property bool eyeOpened: false
                property bool blinkComplete: false

                color: "black"
                Component.onCompleted: blinkAnimation.restart()
                SequentialAnimation {
                    running: false
                    id: blinkAnimation
                    
                    onStopped: eyeBlinkLoader.active = false

                    PauseAnimation { duration: 800 }
                    PropertyAction {
                        target: blinkRec
                        property: "eyeOpened"
                        value: true
                    }
                    LomiriNumberAnimation {
                        target: blinkRec
                        property: "opacity"
                        to: 0
                        duration: 300
                    }
                    PauseAnimation { duration: 100 }
                    PropertyAction {
                        target: blinkRec
                        property: "eyeOpened"
                        value: false
                    }
                    LomiriNumberAnimation {
                        target: blinkRec
                        property: "opacity"
                        to: 1
                        duration: 50
                    }
                    PropertyAction {
                        target: blinkRec
                        property: "eyeOpened"
                        value: true
                    }
                    LomiriNumberAnimation {
                        target: blinkRec
                        property: "opacity"
                        to: 0
                        duration: 50
                    }
                    PauseAnimation { duration: 100 }
                    PropertyAction {
                        target: blinkRec
                        property: "eyeOpened"
                        value: false
                    }
                    LomiriNumberAnimation {
                        target: blinkRec
                        property: "opacity"
                        to: 1
                        duration: 100
                    }
                    PauseAnimation { duration: 300 }
                    PropertyAction {
                        target: blinkRec
                        properties: "eyeOpened,blinkComplete"
                        value: true
                    }
                    LomiriNumberAnimation {
                        target: blinkRec
                        property: "opacity"
                        to: 0
                        duration: 500
                    }
                }
            }
        }
    }
    // ENH032 - End

    Loader {
        id: shellBorderLoader
        active: shell.isBuiltInScreen && deviceConfiguration.withNotch
        asynchronous: true
        z: 1000
        anchors {
            fill: parent
        }
        states: [
            State {
                name: "portrait"
                when: orientation == 1

                PropertyChanges {
                    target: shellBorderLoader
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
                    target: shellBorderLoader
                    anchors.topMargin: -shell.shellMargin
                    anchors.rightMargin: -shell.shellMargin
                    anchors.leftMargin: -shell.shellMargin
                }
            }
            ,State {
                name: "landscape"
                when: orientation == 2

                PropertyChanges {
                    target: shellBorderLoader
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
                    target: shellBorderLoader
                    anchors.topMargin: -shell.shellMargin
                    anchors.bottomMargin: -shell.shellMargin
                    anchors.rightMargin: -shell.shellMargin
                    anchors.leftMargin: 0
                }
            }
        ]
        sourceComponent: Component {
            Rectangle {
                id: shellBorder

                color: "transparent"
                radius: deviceConfiguration.roundedCornerRadius

                
                border {
                    color: "black"
                    width: shell.shellMargin
                }

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
        }
    }
    // ENH002 - End
    // ENH095 - Middle notch support
    Loader {
        active: shell.settings.notchPosition == 1 && shell.settings.showMiddleNotchHint
        asynchronous: true
        z: batteryCircleLoader.z
        anchors {
            top: parent.top
            topMargin: - (height / 2)
            horizontalCenter: parent.horizontalCenter
        }
        sourceComponent: Rectangle {
            color: "gray"
            opacity: 0.5
            height: shell.deviceConfiguration.notchHeightMargin * 2
            width: shell.deviceConfiguration.notchWidthMargin
            radius: units.gu(2)
        }
    }
    // ENH095 - End
    // ENH036 - Use punchole as battery indicator
    Loader {
        id: batteryCircleLoader

        readonly property real borderWidth: item ? item.borderWidth : 0

        active: shell.isBuiltInScreen && shell.orientation == 1
                            && ( shell.isRightNotch || shell.isMiddleNotch) // && !shell.deviceConfiguration.fullyHideNotchInPortrait
                            && shell.settings.batteryCircle
        z: shellBorderLoader.z + 1
        anchors {
            right: parent.right
            rightMargin: shell.deviceConfiguration.notchWidthMargin - shell.deviceConfiguration.punchHoleWidth - borderWidth * 2
            top: parent.top 
            topMargin: shell.deviceConfiguration.punchHoleHeightFromTop - shell.deviceConfiguration.punchHoleWidth - borderWidth * 2
        }

        states: [
            State {
                name: "right"
                when: shell.isRightNotch
                AnchorChanges {
                    target: batteryCircleLoader
                    anchors.right: parent.right
                    anchors.horizontalCenter: undefined
                }
            }
            , State {
                name: "middle"
                when: shell.isMiddleNotch
                AnchorChanges {
                    target: batteryCircleLoader
                    anchors.right: undefined
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        ]

        sourceComponent: CircularProgressBar {
            id: batteryCircle

            readonly property bool charging: panel.batteryCharging

            property bool full: finished

            width: shell.deviceConfiguration.punchHoleWidth + (borderWidth * 4)
            height: width
            progress: panel.batteryLevel

            borderColor: {
                if (charging) {
                    return theme.palette.normal.positive
                } else {
                    switch (true) {
                        case progress <= 25:
                            return theme.palette.normal.negative
                            break
                        case progress <= 50:
                            return "#F5D412"
                            break
                        case progress <= 75:
                            return theme.palette.normal.activity
                            break
                        default:
                            return theme.palette.normal.backgroundText
                            break
                    }
                }
            }

            borderWidth: 10

            Behavior on borderColor {
                ColorAnimation {
                    duration: LomiriAnimation.BriskDuration
                }
            }
        }
    }
    // ENH036 - End
    
    // ENH018 - Immersive mode
    /* Detect Immersive mode */
    // ENH115 - Standalone Immersive mode
    //property bool immersiveMode: settings.edgeDragWidth == 0
    property bool immersiveMode: settings.edgeDragWidth == 0 || shell.settings.immersiveMode
    // ENH115 - End
    // ENH018 - End

    ImageResolver {
        id: wallpaperResolver
        objectName: "wallpaperResolver"

        readonly property url defaultBackground: "file://" + Constants.defaultWallpaper
        readonly property bool hasCustomBackground: resolvedImage != defaultBackground
        readonly property string gsettingsBackgroundPictureUri: ((shell.showingGreeter == true)
                                                             ||  (shell.mode === "full-greeter")
                                                             ||  (shell.mode === "greeter"))
                                                              ? backgroundGreeterSettings.backgroundPictureUri
                                                              : backgroundShellSettings.backgroundPictureUri

        GSettings {
            id: backgroundShellSettings
            schema.id: "com.lomiri.Shell"
        }
        GSettings {
            id: backgroundGreeterSettings
            schema.id: "com.lomiri.Shell.Greeter"
        }

        candidates: [
            AccountsService.backgroundFile,
            gsettingsBackgroundPictureUri,
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
        // ENH135 - Show Desktop
        stage.disableShowDesktop()
        // ENH135 - End
    }

    function activateURL(url) {
        SessionBroadcast.requestUrlStart(AccountsService.user, url);
        greeter.notifyUserRequestedApp();
        panel.indicators.hide();
    }

    function startApp(appId) {
        if (!ApplicationManager.findApplication(appId)) {
            ApplicationManager.startApplication(appId);
        }
        ApplicationManager.requestFocusApplication(appId);
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
        restoreMode: Binding.RestoreBinding
        property: "applicationManager"
        value: ApplicationManager
    }

    Component.onCompleted: {
        finishStartUpTimer.start();
    }

    VolumeControl {
        id: volumeControl
    }

    // ENH202 - Caller Alarm
    property bool temporaryDisableVolumeControl: false
    // ENH202 - End
    PhysicalKeysMapper {
        id: physicalKeysMapper
        objectName: "physicalKeysMapper"

        onPowerKeyLongPressed: dialogs.showPowerDialog();
        // ENH151 - Volume buttons when locked
        // onVolumeDownTriggered: volumeControl.volumeDown();
        // onVolumeUpTriggered: volumeControl.volumeUp();
        onVolumeDownTriggered: {
            // ENH222 - Option to disable volume buttons in camera
            if (shell.settings.disableVolumeWhenCamera && stage.focusedAppId === "camera.ubports_camera")
                return
            // ENH222 - End
            // ENH202 - Caller Alarm
            //if (!shell.settings.enableVolumeButtonsLogic || Powerd.status === Powerd.On || shell.playbackItemIndicator.playing || callManager.hasCalls) {
            if ((!shell.settings.enableVolumeButtonsLogic || Powerd.status === Powerd.On || shell.playbackItemIndicator.playing || callManager.hasCalls)
                    && !shell.temporaryDisableVolumeControl) {
            // ENH202 - End
                volumeControl.volumeDown();
            }
        }
        onVolumeUpTriggered: {
            // ENH222 - Option to disable volume buttons in camera
            if (shell.settings.disableVolumeWhenCamera && stage.focusedAppId === "camera.ubports_camera")
                return
            // ENH222 - End
            // ENH202 - Caller Alarm
            //if (!shell.settings.enableVolumeButtonsLogic || Powerd.status === Powerd.On || shell.playbackItemIndicator.playing || callManager.hasCalls) {
            if ((!shell.settings.enableVolumeButtonsLogic || Powerd.status === Powerd.On || shell.playbackItemIndicator.playing || callManager.hasCalls)
                    && !shell.temporaryDisableVolumeControl) {
            // ENH202 - End
                volumeControl.volumeUp();
            }
        }
        // ENH151 - End
        onScreenshotTriggered: itemGrabber.capture(shell);
        // ENH100 - Camera button to toggle rotation and OSK
        onCameraTriggered: {
            if (shell.settings.reversedCameraKeyDoubePress) {
                lomiriSettings.alwaysShowOsk = !lomiriSettings.alwaysShowOsk
            } else {
                shell.toggleRotation()
            }
        }
        onCameraDoublePressed: {
            if (shell.settings.reversedCameraKeyDoubePress) {
                shell.toggleRotation()
            } else {
                lomiriSettings.alwaysShowOsk = !lomiriSettings.alwaysShowOsk
            }
        }
        // ENH100 - End
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
        // ENH048 - Always hide panel mode
        //anchors.topMargin: panel.fullscreenMode ? shell.shellTopMargin 
        //anchors.topMargin: panel.fullscreenMode || panel.forceHidePanel ? shell.shellTopMargin 
        anchors.topMargin: panel.fullscreenMode || shell.hideTopPanel ? shell.shellTopMargin 
        // ENH048 - End
                                    : deviceConfiguration.fullyHideNotchInPortrait ? shell.shellTopMargin + panel.minimizedPanelHeight
                                                    : panel.minimizedPanelHeight// in portrait, there's a top margin even in fullscreen mode
        // `x` (= anchors.leftMargin) property is used for the left margin
        // and `width` for the available width in Stage
        // Because of this, we can't add shellLeftMargin to the leftMargin as it will be calculated twice in Stage
        // when availableDesktopAreaItem.x is used
        // And because of that, the width of this item doesn't correctly represent the actual available width for apps, etc
        // Use rightMargin to correct the calculated width for use in Stage
        anchors.leftMargin: launcher.lockedByUser && !greeter.locked && launcher.lockAllowed ? launcher.panelWidth : 0
        anchors.rightMargin: shell.shellLeftMargin > 0 ? shell.shellRightMargin + shell.shellLeftMargin : shell.shellRightMargin
        anchors.bottomMargin: shell.shellBottomMargin
        // ENH002 - End
    }

    GSettings {
        id: settings
        schema.id: "com.lomiri.Shell"
    }

    PanelState {
        id: panelState
        objectName: "panelState"
    }

    Item {
        id: stages
        objectName: "stages"
        // ENH002 - Notch/Punch hole fix
        // width: parent.width
        // height: parent.height
        anchors {
            fill: parent
            leftMargin: shell.shellLeftMargin
            rightMargin: shell.shellRightMargin
            bottomMargin: shell.shellBottomMargin
        }
        // ENH002 - End

        Stage {
            id: stage
            objectName: "stage"
            anchors.fill: parent
            // ENH032 - Infographics Outer Wilds
            enableOW: lp_settings.enableOW
            alternateOW: lp_settings.ow_theme == 0
            dlcOW: lp_settings.ow_theme == 2
            eyeOpened: eyeBlinkLoader.item ? eyeBlinkLoader.item.eyeOpened : false
            blinkComplete: eyeBlinkLoader.item ? eyeBlinkLoader.item.blinkComplete : false
            // ENH032 - End
            focus: true
            lightMode: shell.lightMode

            dragAreaWidth: shell.edgeSize
            background: wallpaperResolver.resolvedImage
            backgroundSourceSize: shell.largestScreenDimension

            applicationManager: ApplicationManager
            topLevelSurfaceList: shell.topLevelSurfaceList
            inputMethodRect: inputMethod.visibleRect
            rightEdgePushProgress: rightEdgeBarrier.progress
            availableDesktopArea: availableDesktopAreaItem
            launcherLeftMargin: launcher.visibleWidth

            property string usageScenario: shell.usageScenario === "phone" || greeter.hasLockedApp
                                                       ? "phone"
                                                       : shell.usageScenario

            // ENH039 - New side-stage enablement logic
            // mode: usageScenario == "phone" ? "staged"
            //          : usageScenario == "tablet" ? "stagedWithSideStage"
            //          : "windowed"
            mode: usageScenario == "phone" || usageScenario == "tablet" ? 
            // ENH046 - Lomiri Plus Settings
                        (Screen.width / 2 >= stage.sideStageWidth || Screen.height / 2 >= stage.sideStageWidth)
                        && shell.settings.enableSideStage ?
            // ENH046 - End
                            "stagedWithSideStage" : "staged"
                    : "windowed"
            // ENH039 - End

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
            panelState: panelState

            onSpreadShownChanged: {
                panel.indicators.hide();
                panel.applicationMenus.hide();
            }
        }

        TouchGestureArea {
            anchors.fill: stage

            minimumTouchPoints: 4
            // ENH154 - Workspace switcher gesture
            // maximumTouchPoints: minimumTouchPoints
            maximumTouchPoints: 5
            // ENH154 - End
            // ENH018 - Immersive mode
            enabled: !shell.immersiveMode
            // ENH018 - End

            readonly property bool recognisedPress: status == TouchGestureArea.Recognized &&
                                                    touchPoints.length >= minimumTouchPoints &&
                                                    touchPoints.length <= maximumTouchPoints
            property bool wasPressed: false

            // ENH154 - Workspace switcher gesture
            property bool enableDrag: stage.workspaceEnabled
            readonly property bool recognisedDrag: wasPressed && dragging
            property bool wasRecognisedDrag: false
            property real startX: 0
            property real currentX: {
                var sum = 0;
                for (var i = 0; i < touchPoints.length; i++) {
                    sum += touchPoints[i].x;
                }
                return sum/touchPoints.length;
            }
            readonly property real dragDistance: currentX - startX
            readonly property real dragThreshold: units.gu(30)
            readonly property int dragStep: Math.floor(dragDistance / dragThreshold)
            property int prevDragStep: 0
            property bool draggingRight: wasRecognisedDrag && currentX - startX >= units.gu(5)
            property bool draggingLeft: wasRecognisedDrag && currentX - startX <= units.gu(-5)

            signal pressed(int x, int y)
            signal clicked
            signal dragStarted
            signal dropped
            signal cancelled

            onDragStepChanged: {
                if (wasRecognisedDrag) {
                    const _step = prevDragStep - dragStep
                    if (_step < 0) {
                        if (touchPoints.length === 4) {
                            stage.switchWorkspaceRight()
                        } else {
                            stage.switchWorkspaceRightMoveApp()
                        }
                        shell.haptics.playSubtle()
                    } else if (_step > 0) {
                        if (touchPoints.length === 4) {
                            stage.switchWorkspaceLeft()
                        } else {
                            stage.switchWorkspaceLeftMoveApp()
                        }
                        shell.haptics.playSubtle()
                    }

                    prevDragStep = dragStep
                }
            }

            onClicked: launcher.toggleDrawer(true);

            onEnabledChanged: {
                if (!enabled) {
                    wasRecognisedDrag = false;
                    wasPressed = false;
                }
            }
            onRecognisedDragChanged: {
                if (enableDrag && recognisedDrag) {
                    startX = currentX
                    wasRecognisedDrag = true;
                    dragStarted()
                }
            }

            onDropped: {
                stage.commitWorkspaceSwitch()
            }
            // ENH154 - End

            onRecognisedPressChanged: {
                if (recognisedPress) {
                    wasPressed = true;
                }
            }

            // ENH154 - Workspace switcher gesture
            /*
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
            */
            onStatusChanged: {
                if (status != TouchGestureArea.Recognized) {
                    if (status == TouchGestureArea.Rejected) {
                        cancelled();
                    } else if (status == TouchGestureArea.WaitingForTouch) {
                        if (wasPressed) {
                            if (!wasRecognisedDrag) {
                                clicked();
                            } else {
                                dropped();
                            }
                        }
                    }
                    wasRecognisedDrag = false;
                    wasPressed = false;
                    startX = 0
                    prevDragStep = 0
                }
            }
            // ENH154 - End
        }
    }

    // ENH139 - System Direct Actions
    Loader {
        id: directActionsLoader
        active: shell.settings.enableDirectActions
        asynchronous: true
        anchors.fill: parent
        z: shell.settings.directActionsSwipeOverOSK ? itemGrabber.z - 1 : settingsLoader.z + 1
        sourceComponent: LPDirectActions {
            enabled: !shell.immersiveMode
            noSwipeCommit: shell.settings.directActionsNoSwipeCommit
            swipeAreaHeight: shell.convertFromInch(shell.settings.directActionsSwipeAreaHeight)
            swipeAreaWidth: shell.edgeSize
            maximumWidthPhysical: shell.convertFromInch(shell.settings.directActionsMaxWidth)
            maximumWidth: units.gu(shell.settings.directActionsMaxWidthGU)
            sideMargins: shell.convertFromInch(shell.settings.directActionsSideMargins)
            preferredActionItemWidthPhysical: shell.convertFromInch(0.35)
            thresholdWidthForCentered: shell.convertFromInch(4)
            maximumColumn: shell.settings.directActionsMaxColumn
            enableVisualHint: shell.settings.directActionsEnableHint || shell.directActionsSettingsShown
            swipeAreaSides: shell.settings.directActionsSides
            actionsList: shell.settings.directActionList
            showHideAnimationSpeed: shell.settings.directActionsAnimationSpeed
            swipeDynamicPosition: shell.settings.directActionsDynamicPositionWhenSwiping
            swipeOffsetSelection: shell.settings.directActionsOffsetSelectionWhenSwiping
            swipeUsePhysicalSize: shell.settings.directActionsUsePhysicalSizeWhenSwiping
            displayStyle: shell.settings.directActionsStyle

            onAppOrderChanged: shell.settings.directActionList = newAppOrderArray.slice()

            GlobalShortcut {
                shortcut: Qt.MetaModifier | Qt.Key_Q
                onTriggered: {
                    let _fromLeft = shell.settings.directActionsShortcutHorizontalLayout == 2 ? cursor.x <= shell.width / 2
                                        : shell.settings.directActionsShortcutHorizontalLayout === 0
                    let _fromTop = shell.settings.directActionsShortcutVerticalLayout == 2 ? cursor.y <= shell.height / 2
                                        : shell.settings.directActionsShortcutVerticalLayout === 0

                    shell.directActions.toggle(_fromLeft, _fromTop, Qt.point(cursor.x, cursor.y))
                }
            }
        }
    }
    // ENH139 - End

    // ENH028 - Open indicators via gesture
    Loader {
        id: indicatorSwipeLoader

        active: shell.settings.indicatorGesture && !shell.settings.enableDirectActions
        asynchronous: true
        height: shell.convertFromInch(0.3) // 0.3 inch
        width: shell.edgeSize
        z: greeter.fullyShown ? greeter.z + 1 : overlay.z - 1
        anchors {
            right: parent.right
            bottom: parent.bottom
        }

        sourceComponent: SwipeArea {
            id: indicatorsBottomSwipe
            
            // draggingCustom is used for implementing trigger delay
            readonly property bool partialWidth: thresholdWidth == maxThresholdWidth
            readonly property real customThreshold: shell.convertFromInch(0.2) // 0.2 inch
            readonly property real maxThresholdWidth: shell.convertFromInch(3) // 3 inches //units.gu(50)
            readonly property real thresholdWidth: Math.min(shell.width, maxThresholdWidth)
            readonly property int stagesCount: indicatorBottomItemsLoader.model.length
            readonly property real stageWidth: thresholdWidth / stagesCount
            readonly property bool fineControl: shell.settings.specificIndicatorGesture
            readonly property var highlightedItem: indicatorBottomItemsLoader.item
                                    ? indicatorBottomItemsLoader.item.childAt(indicatorBottomItemsLoader.item.width
                                                                              - indicatorSwipeLoader.item.distance
                                                                              + customThreshold
                                                                              , 0)
                                    : null
            property bool draggingCustom: distance >= customThreshold
            property bool triggerDirectAccess: false

            enabled: !shell.immersiveMode
            direction: SwipeArea.Leftwards
            immediateRecognition: true

            onDraggingCustomChanged: {
                if(dragging && !fineControl){
                    trigger(-1)
                }   
            }

            onDraggingChanged: {
                if (!dragging) {
                    if (fineControl && draggingCustom) {
                        if (highlightedItem && triggerDirectAccess) {
                            trigger(shell.indicatorsModel[highlightedItem.itemId].indicatorIndex)
                        } else {
                            trigger(0)
                        }
                    }
                    triggerDirectAccess = false
                    swipeTriggerDelay.stop()
                } else {
                    swipeTriggerDelay.restart()
                }
            }

            function trigger(index) {
                panel.indicators.openAsInverted(index)
                shell.haptics.play()
            }

            // Delay showing direct access to enable quick short swipe to always open notifications
            // and quick access to quick toggles
            Timer {
                id: swipeTriggerDelay

                interval: 200
                running: false
                onTriggered: indicatorsBottomSwipe.triggerDirectAccess = true
            }

            Rectangle {
                // Visualize
                visible: false
                color: "blue"
                anchors.fill: parent
            }
        }
    }

    Loader {
        id: indicatorBottomItemsLoader

        property var model: shell.settings.directAccessIndicators
        property int enabledCount: 0

        active: shell.settings.indicatorGesture && shell.settings.specificIndicatorGesture
                    && !shell.settings.enableDirectActions
        asynchronous: true
        z: overlay.z + 1
        anchors {
            bottom: parent.bottom
            bottomMargin: indicatorSwipeLoader.item ? indicatorSwipeLoader.item.height : 0
            right: parent.right
            rightMargin: indicatorSwipeLoader.item ? indicatorSwipeLoader.item.customThreshold : 0
            left: parent.left
            leftMargin: anchors.rightMargin
        }

        onModelChanged: {
            enabledCount = 0

            if (model) {
                for (let i = 0; i < model.length; i++) {
                    if (model[i].enabled) {
                      enabledCount += 1
                    }
                }
            }
        }

        state: "full"
        states: [
            State {
                name: "full"
                AnchorChanges {
                    target: indicatorBottomItemsLoader
                    anchors.left: parent.left
                }
                PropertyChanges {
                    target: indicatorBottomItemsLoader
                    anchors.leftMargin: anchors.rightMargin
                }
            }
            , State {
                name: "partial"
                when: indicatorSwipeLoader.item && indicatorSwipeLoader.item.partialWidth
                AnchorChanges {
                    target: indicatorBottomItemsLoader
                    anchors.left: undefined
                }
                PropertyChanges {
                    target: indicatorBottomItemsLoader
                    width: indicatorSwipeLoader.item ? indicatorSwipeLoader.item.thresholdWidth : parent.width - indicatorBottomItemsLoader.anchors.rightMargin
                    anchors.leftMargin: 0
                }
            }
        ]

        sourceComponent: RowLayout {
            id: indicatorOptions

            layoutDirection: Qt.RightToLeft
            visible: opacity > 0
            spacing: 0
            opacity: indicatorSwipeLoader.item && indicatorSwipeLoader.item.triggerDirectAccess
                                    && indicatorSwipeLoader.item.draggingCustom ? 1 : 0

            Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }

            Repeater {
                id: indicatorSwipeRepeater

                model: indicatorBottomItemsLoader.model

                Item {
                    id: indicatorItem

                    readonly property real preferredSize: (indicatorBottomItemsLoader.width / indicatorBottomItemsLoader.enabledCount)
                    readonly property real maximumSize: units.gu(6)

                    readonly property string itemId: modelData.id
                    readonly property string itemIcon: shell.indicatorsModel[modelData.id].icon
                    readonly property bool highlighted: indicatorSwipeLoader.item && indicatorSwipeLoader.item.highlightedItem == this
                                                            && indicatorOptions.visible

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: preferredSize
                    Layout.preferredHeight: preferredSize
                    Layout.maximumHeight: maximumSize

                    visible: modelData.enabled
                    z: highlighted ? 2 : 1
                    scale: highlighted ? 1.3 : 1
                    Behavior on scale { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }

                    onHighlightedChanged: {
                        if (highlighted) {
                            delayHaptics.restart()
                        } else {
                            delayHaptics.stop()
                        }
                    }

                    Timer {
                        id: delayHaptics

                        running: false
                        interval: 100
                        onTriggered: {
                            if (indicatorItem.highlighted) {
                                shell.haptics.playSubtle()
                            }
                        }
                    }

                    Rectangle {
                        id: bgRec

                        color: highlighted ? theme.palette.highlighted.foreground : theme.palette.normal.foreground
                        radius: width / 2
                        width: Math.min(parent.width, indicatorItem.maximumSize)
                        height: width
                        anchors.centerIn: parent
                        Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
                    }
                    Icon {
                        anchors.centerIn: bgRec
                        asynchronous: true
                        height: bgRec.height * 0.5
                        width: height
                        name: itemIcon
                        color: highlighted ? theme.palette.normal.activity : theme.palette.normal.foregroundText
                        Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
                    }
                }
            }
        }
    }
    
    Loader {
        active: shell.settings.indicatorGesture
        asynchronous: true
        height: shell.convertFromInch(0.3) // 0.3 inch
        width: shell.edgeSize
        z: panel.applicationMenus.fullyOpened ? overlay.z - 1 : overlay.z + 1
        anchors {
            left: parent.left
            bottom: parent.bottom
        }
        sourceComponent: SwipeArea {
            id: appMenuBottomSwipe
            
            // draggingCustom is used for implementing trigger delay
            property bool draggingCustom: distance >= units.gu(4) 
            
            signal triggered
            enabled: !shell.immersiveMode && panel.applicationMenus.available && panel.applicationMenus.model
            direction: SwipeArea.Rightwards
            immediateRecognition: true
            
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
        sourceComponent: {
            if (shell.mode != "shell") {
                if (screenWindow.primary) return integratedGreeter;
                return secondaryGreeter;
            }
            return Qt.createComponent(Qt.resolvedUrl("Greeter/ShimGreeter.qml"));
        }
        onLoaded: {
            item.objectName = "greeter"
        }
        property bool toggleDrawerAfterUnlock: false
        // ENH139 - System Direct Actions
        property bool searchDrawerAfterUnlock: false
        // ENH139 - End
        Connections {
            target: greeter
            function onActiveChanged() {
                if (greeter.active)
                    return

                // Show drawer in case showHome() requests it
                if (greeterLoader.toggleDrawerAfterUnlock) {
                    // ENH139 - System Direct Actions
                    // launcher.toggleDrawer(false);
                    if (greeterLoader.searchDrawerAfterUnlock) {
                        launcher.searchInDrawer()
                        greeterLoader.searchDrawerAfterUnlock = false;
                    } else {
                        launcher.toggleDrawer(false);
                    }
                    // ENH139 - End
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
            background: wallpaperResolver.resolvedImage
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

            onEmergencyCall: startLockedApp("lomiri-dialer-app")

            // Quit the greeter as soon as a session has been started
            onSessionStarted: {
                if (shell.mode == "greeter")
                    Qt.quit();
            }
        }
    }

    Component {
        id: secondaryGreeter
        SecondaryGreeter {
            hides: [launcher, panel.indicators]
        }
    }

    Timer {
        // See powerConnection for why this is useful
        id: showGreeterDelayed
        interval: 1
        onTriggered: {
            // Go through the dbus service, because it has checks for whether
            // we are even allowed to lock or not.
            DBusLomiriSessionService.PromptLock();
        }
    }

    Connections {
        id: callConnection
        target: callManager

        function onHasCallsChanged() {
            if (greeter.locked && callManager.hasCalls && greeter.lockedApp !== "lomiri-dialer-app") {
                // We just received an incoming call while locked.  The
                // indicator will have already launched lomiri-dialer-app for
                // us, but there is a race between "hasCalls" changing and the
                // dialer starting up.  So in case we lose that race, we'll
                // start/focus the dialer ourselves here too.  Even if the
                // indicator didn't launch the dialer for some reason (or maybe
                // a call started via some other means), if an active call is
                // happening, we want to be in the dialer.
                startLockedApp("lomiri-dialer-app")
            }
        }
    }

    Connections {
        id: powerConnection
        target: Powerd

        function onStatusChanged(reason) {
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
            // ENH116 - Standalone Dark mode toggle
            if (shell.settings.enableAutoDarkMode) {
                if (Powerd.status == Powerd.On) {
                    shell.themeSettings.checkAutoToggle()
                }
            }
            // ENH116 - End
        }
    }

// ENH139 - System Direct Actions
    // function showHome() {
    function showHome(_search = false) {
// ENH139 - End
        greeter.notifyUserRequestedApp();

        if (shell.mode === "greeter") {
            SessionBroadcast.requestHomeShown(AccountsService.user);
        } else {
            if (!greeter.active) {
                launcher.toggleDrawer(false);
            } else {
                // ENH139 - System Direct Actions
                if (_search) {
                    greeterLoader.searchDrawerAfterUnlock = true;
                }
                // ENH139 - End
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
        SwipeArea {
            objectName: "fullscreenSwipeDown"
            enabled: panel.state === "offscreen"
            direction: SwipeArea.Downwards
            immediateRecognition: false
            height: units.gu(2)
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            onDraggingChanged: {
                if (dragging) {
                    panel.temporarilyShow()
                }
            }
        }

        Panel {
            id: panel
            objectName: "panel"
            anchors.fill: parent //because this draws indicator menus
            // ENH030 - Blurred indicator panel
            // blurSource: settings.enableBlur ? (greeter.shown ? greeter : stages) : null
            // ENH168 - Settings to use wallpaper as blur source
            //blurSource: settings.enableBlur && shell.settings.indicatorBlur ? (greeter.shown ? greeter : stages) : null
            blurSource: settings.enableBlur && shell.settings.indicatorBlur ? shell.settings.useWallpaperForBlur ? stage.wallpaperSurface
                                                                                                                 : (greeter.shown ? greeter : stages)
                                                                            : null
            // ENH168 - End
            // ENH030 - End
            lightMode: shell.lightMode
            // ENH171 - Add blur to Top Panel and Drawer
            // Only for greeter for somne reason?
            topPanelBlurSource: {
                if (settings.enableBlur) {
                    if (shell.settings.enableTopPanelBlur && greeter.shown) {
                        return shell.settings.useWallpaperForBlur ? stage.wallpaperSurface : greeter
                    }
                }
                                        
                return null
            }
            // ENH171 - End

            mode: shell.usageScenario == "desktop" ? "windowed" : "staged"
            // ENH002 - Notch/Punch hole fix
            /* Height of the panel bar */
            // minimizedPanelHeight: units.gu(3)
            // expandedPanelHeight: units.gu(7)
            minimizedPanelHeight: shell.isBuiltInScreen && deviceConfiguration.withNotch && shell.orientation == 1 && ! deviceConfiguration.fullyHideNotchInPortrait
                                        ? shell.shellMargin : units.gu(3)
            expandedPanelHeight: shell.isBuiltInScreen && deviceConfiguration.withNotch && shell.orientation == 1 && ! deviceConfiguration.fullyHideNotchInPortrait
                                        ? shell.shellMargin * 1.5 : units.gu(7)
            leftMarginBlur: !greeter.shown ? overlay.anchors.leftMargin : 0
            topMarginBlur: !greeter.shown ? overlay.anchors.topMargin : 0
            // ENH002 - End
            applicationMenuContentX: launcher.lockedVisible ? launcher.panelWidth : 0
            // ENH036 - Use punchole as battery indicator
            batteryCircleEnabled : batteryCircleLoader.active
            batteryCircleBorder: batteryCircleLoader.borderWidth
            // ENH036 - End
            // ENH122 - Option to transparent top bar when in spread
            transparentTopBar: shell.settings.transparentTopBarOnSpread
                                    && (stage.spreadShown || stage.rightEdgeDragProgress > 0 || stage.rightEdgePushProgress > 0)
            topBarOpacityOverride: stage.spreadShown ? 0 : 1 - (stage.rightEdgeDragProgress * 2)
            // ENH170 - Adjust top panel based on Drawer and Indicator panels
            spreadShown: stage.spreadShown
            spreadDragProgress: stage.rightEdgeDragProgress
            // ENH170 - End
            // ENH122 - End
            // ENH046 - Lomiri Plus Settings
            topPanelMargin: shell.isBuiltInScreen && deviceConfiguration.withNotch && shell.orientation == 1 && ! deviceConfiguration.fullyHideNotchInPortrait
                                        ? shell.shellMargin : 0
            // ENH046 - End
            // ENH170 - Adjust top panel based on Drawer and Indicator panels
            drawerProgress: launcher.drawerProgress
            drawerOpacity: launcher.drawerOpacity
            drawerColor: launcher.drawerColor
            // ENH170 - End

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

            readonly property bool focusedSurfaceIsFullscreen: shell.topLevelSurfaceList.focusedWindow
                ? shell.topLevelSurfaceList.focusedWindow.state == Mir.FullscreenState
                : false
            fullscreenMode: (focusedSurfaceIsFullscreen && !LightDMService.greeter.active && launcher.progress == 0 && !stage.spreadShown)
                            || greeter.hasLockedApp
            // ENH048 - Always hide panel mode
            forceHidePanel: shell.hideTopPanel && ((!LightDMService.greeter.active && !stage.spreadShown && stage.rightEdgeDragProgress == 0 && stage.rightEdgePushProgress == 0)
                                                                    || greeter.hasLockedApp)
            // ENH048 - End
            greeterShown: greeter && greeter.shown
            hasKeyboard: shell.hasKeyboard
            panelState: panelState
            supportsMultiColorLed: shell.supportsMultiColorLed
        }

        Launcher {
            id: launcher
            objectName: "launcher"
            // ENH033 - Hide launcher under the top panel
            // z: panel.z - 1
            // ENH033 - End
            anchors.top: parent.top
            anchors.topMargin: inverted ? 0 : panel.panelHeight
            anchors.bottom: parent.bottom
            width: parent.width
            dragAreaWidth: shell.edgeSize
            available: tutorial.launcherEnabled
                    && (!greeter.locked || AccountsService.enableLauncherWhileLocked)
                    && !greeter.hasLockedApp
                    && !shell.waitingOnGreeter
                    && shell.mode !== "greeter"
            visible: shell.mode !== "greeter"
            inverted: shell.usageScenario !== "desktop"
            superPressed: physicalKeysMapper.superPressed
            superTabPressed: physicalKeysMapper.superTabPressed
            panelWidth: units.gu(settings.launcherWidth)
            // ENH014 - Always hide launcher in lock screen
            // lockedVisible: (lockedByUser || shell.atDesktop) && lockAllowed
            // ENH134 - Option to hide Launcher in desktop
            //lockedVisible: ((lockedByUser && !greeter.locked) || shell.atDesktop) && lockAllowed
            // ENH226 - Infographics on the desktop
            //lockedVisible: ((lockedByUser && !greeter.locked) || (shell.atDesktop && shell.settings.showLauncherAtDesktop)) && lockAllowed
            lockedVisible: ((lockedByUser && !greeter.locked)
                                || (shell.atDesktop && shell.settings.showLauncherAtDesktop && !(shell.settings.showInfographicsOnDesktop && shell.isPortrait))
                           ) && lockAllowed
            // ENH226 - End
            // ENH134 - End
            // ENH014 - End
            // ENH002 - Notch/Punch hole fix
            leftMarginBlur: overlay.anchors.leftMargin
            topMarginBlur: overlay.anchors.topMargin
            // ENH002 - End
            // ENH106 - Separate drawer blur settings
            // blurSource: settings.enableBlur ? (greeter.shown ? greeter : stages) : null
            // ENH168 - Settings to use wallpaper as blur source
            //blurSource: settings.enableBlur && shell.settings.drawerBlur ? (greeter.shown ? greeter : stages) : null
            blurSource: settings.enableBlur && shell.settings.drawerBlur ? shell.settings.useWallpaperForBlur ? stage.wallpaperSurface
                                                                                                              : (greeter.shown ? greeter : stages)
                                                                         : null
            // ENH168 - End
            // ENH106 - End
            topPanelHeight: panel.panelHeight
            lightMode: shell.lightMode
            drawerEnabled: !greeter.active && tutorial.launcherLongSwipeEnabled
            privateMode: greeter.active
            background: wallpaperResolver.resolvedImage

            // It can be assumed that the Launcher and Panel would overlap if
            // the Panel is open and taking up the full width of the shell
            readonly property bool collidingWithPanel: panel && (!panel.fullyClosed && !panel.partialWidth)

            // The "autohideLauncher" setting is only valid in desktop mode
            readonly property bool lockedByUser: (shell.usageScenario == "desktop" && !settings.autohideLauncher)

            // The Launcher should absolutely not be locked visible under some
            // conditions
            readonly property bool lockAllowed: !collidingWithPanel && !panel.fullscreenMode && !wizard.active && !tutorial.demonstrateLauncher
            // ENH146 - Hide launcher when narrow
                                                        && ((shell.settings.hideLauncherWhenNarrow && stages.width >= units.gu(60))
                                                                || !shell.settings.hideLauncherWhenNarrow)
            // ENH146 - End

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
            // ENH043 - Button to toggle OSK
            GlobalShortcut { // toggle OSK
                shortcut: 0//Qt.Key_WebCam
                onTriggered: {
                    if (shell.settings.pro1_OSKToggleKey) {
                        lomiriSettings.alwaysShowOsk = !lomiriSettings.alwaysShowOsk
                    }
                }
            }
            // ENH043 - End
            // ENH101 - Toggle OSK with shortcut
            GlobalShortcut { // toggle OSK
                shortcut: Qt.ControlModifier | Qt.Key_Period
                enabled: shell.settings.enableOSKToggleKeyboardShortcut
                onTriggered: {
                    if (shell.settings.enableOSKToggleKeyboardShortcut) {
                        lomiriSettings.alwaysShowOsk = !lomiriSettings.alwaysShowOsk
                    }
                }
            }
            // ENH101 - End

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
                    // ENH191 - Keyboard shortcuts overlay settings
                    && !shell.settings.disableKeyboardShortcutsOverlay
                    // ENH191 - End
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: launcher.lockedVisible ? launcher.panelWidth/2 : 0
            anchors.verticalCenterOffset: panel.panelHeight/2
            visible: opacity > 0
            opacity: enabled ? 0.95 : 0

            Behavior on opacity {
                LomiriNumberAnimation {}
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
                if (!active && shell.mode !== "greeter") {
                    ModemConnectivity.unlockAllModems();
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
            background: wallpaperResolver.resolvedImage
            privacyMode: greeter.locked && AccountsService.hideNotificationContentWhileLocked

            y: topmostIsFullscreen ? 0 : panel.panelHeight
            // ENH209 - Notifications at the bottom
            readonly property real defaultBottomMargin: units.gu(5)
            // height: parent.height - (topmostIsFullscreen ? 0 : panel.panelHeight)
            height: {
                let _height = parent.height - (topmostIsFullscreen ? 0 : panel.panelHeight)
                let _margin = 0

                if (inverted) {
                    // Anchors to the OSK only when at the bottom
                    _margin = Qt.inputMethod.visible ? (Qt.inputMethod.keyboardRectangle.height) : 0

                    if (shell.isBuiltInScreen) {
                        _margin += Math.max(shell.settings.roundedCornerRadius / 2, defaultBottomMargin)
                    } else {
                        _margin += defaultBottomMargin
                    }
                }

                return _height - _margin
            }
            // ENH209 - End

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
            // ENH104 - Mouse edge push settings
            // enabled: !greeter.shown
            // ENH133 - Hot corners
            //enabled: !greeter.shown && !shell.settings.disableRightEdgeMousePush
            enabled: !greeter.shown && !shell.settings.disableRightEdgeMousePush
            // ENH133 - End
            // ENH104 - End

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

        // ENH133 - Hot corners
        readonly property bool drawerEnabled: launcher.drawerEnabled && panel.indicators.fullyClosed
        readonly property bool spreadEnabled: stage.spreadEnabled && panel.indicators.fullyClosed
        readonly property bool desktopEnabled: panel.indicators.fullyClosed && !shell.atDesktop && !shell.showingGreeter
        readonly property bool previousAppEnabled: !shell.showingGreeter

        function triggerHotCorner(__actionType, __action, _edge) {

            switch (__actionType) {
                case Shell.HotCorner.Drawer:
                    launcher.toggleDrawer(false, false, true)
                    break
                case Shell.HotCorner.SearchDrawer:
                    launcher.toggleDrawer(true, false, true)
                    break
                case Shell.HotCorner.ToggleDesktop:
                    stage.showDesktop()
                    break
                case Shell.HotCorner.PreviousApp:
                    stage.switchToPreviousApp()
                    break
                case Shell.HotCorner.ToggleSpread:
                    stage.toggleSpread()
                    break
                case Shell.HotCorner.Indicator:
                    if (panel.indicators.fullyClosed) {
                        let _index = shell.hotcornersIndicatorsModel[__action].indicatorIndex
                        panel.indicators.openAsInverted(_index, false)
                    } else {
                        panel.indicators.hide()
                    }
                    break
                case Shell.HotCorner.OpenDirectActions:
                    let _fromLeft = _edge === LPHotCorner.Edge.TopLeft || _edge === LPHotCorner.Edge.BottomLeft
                    let _fromTop = _edge === LPHotCorner.Edge.TopLeft || _edge === LPHotCorner.Edge.TopRight
                    if (shell.directActions) shell.directActions.toggle(_fromLeft, _fromTop)
                    break
            }
        }

        LPHotCorner {
            id: topLeftHotCorner

            actionType: shell.settings.actionTypeTopLeftHotCorner
            actionValue: shell.settings.actionTopLeftHotCorner
            enabled: shell.settings.enableHotCorners
                        && shell.settings.enableTopLeftHotCorner
                        && (
                            (
                                (actionType == Shell.HotCorner.Drawer || actionType == Shell.HotCorner.SearchDrawer)
                                && overlay.drawerEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.ToggleSpread
                                && overlay.spreadEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.ToggleDesktop
                                && overlay.desktopEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.PreviousApp
                                && overlay.previousAppEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.OpenDirectActions
                                && shell.directActions
                            )
                            ||
                            actionType == Shell.HotCorner.Indicator
                        )
            edge: LPHotCorner.Edge.TopLeft
            enableVisualFeedback: shell.settings.enableHotCornersVisualFeedback
            onTrigger: overlay.triggerHotCorner(actionType, actionValue, edge)
        }

        LPHotCorner {
            id: topRightHotCorner

            actionType: shell.settings.actionTypeTopRightHotCorner
            actionValue: shell.settings.actionTopRightHotCorner
            enabled: shell.settings.enableHotCorners
                        && shell.settings.enableTopRightHotCorner
                        && (
                            (
                                (actionType == Shell.HotCorner.Drawer || actionType == Shell.HotCorner.SearchDrawer)
                                && overlay.drawerEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.ToggleSpread
                                && overlay.spreadEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.ToggleDesktop
                                && overlay.desktopEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.PreviousApp
                                && overlay.previousAppEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.OpenDirectActions
                                && shell.directActions
                            )
                            ||
                            actionType == Shell.HotCorner.Indicator
                        )
            edge: LPHotCorner.Edge.TopRight
            enableVisualFeedback: shell.settings.enableHotCornersVisualFeedback
            onTrigger: overlay.triggerHotCorner(actionType, actionValue, edge)
        }

        LPHotCorner {
            id: bottomRightHotCorner

            actionType: shell.settings.actionTypeBottomRightHotCorner
            actionValue: shell.settings.actionBottomRightHotCorner
            enabled: shell.settings.enableHotCorners
                        && shell.settings.enableBottomRightHotCorner
                        && (
                            (
                                (actionType == Shell.HotCorner.Drawer || actionType == Shell.HotCorner.SearchDrawer)
                                && overlay.drawerEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.ToggleSpread
                                && overlay.spreadEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.ToggleDesktop
                                && overlay.desktopEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.PreviousApp
                                && overlay.previousAppEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.OpenDirectActions
                                && shell.directActions
                            )
                            ||
                            actionType == Shell.HotCorner.Indicator
                        )
            edge: LPHotCorner.Edge.BottomRight
            enableVisualFeedback: shell.settings.enableHotCornersVisualFeedback
            onTrigger: overlay.triggerHotCorner(actionType, actionValue, edge)
        }

        LPHotCorner {
            id: bottomLeftHotCorner

            actionType: shell.settings.actionTypeBottomLeftHotCorner
            actionValue: shell.settings.actionBottomLeftHotCorner
            enabled: shell.settings.enableHotCorners
                        && shell.settings.enableBottomLeftHotCorner
                        && (
                            (
                                (actionType == Shell.HotCorner.Drawer || actionType == Shell.HotCorner.SearchDrawer)
                                && overlay.drawerEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.ToggleSpread
                                && overlay.spreadEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.ToggleDesktop
                                && overlay.desktopEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.PreviousApp
                                && overlay.previousAppEnabled
                            )
                            ||
                            (
                                actionType == Shell.HotCorner.OpenDirectActions
                                && shell.directActions
                            )
                            ||
                            actionType == Shell.HotCorner.Indicator
                        )
            edge: LPHotCorner.Edge.BottomLeft
            enableVisualFeedback: shell.settings.enableHotCornersVisualFeedback
            onTrigger: overlay.triggerHotCorner(actionType, actionValue, edge)
        }
        // ENH133 - End
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
        function onShowHome() { if (shell.mode !== "greeter") showHome() }
    }

    URLDispatcher {
        id: urlDispatcher
        objectName: "urlDispatcher"
        active: shell.mode === "greeter"
        onUrlRequested: shell.activateURL(url)
    }

    // ENH210 - Advanced screenshot
    // ItemGrabber {
    LPScreenshotHandler {
        advancedMode: shell.settings.enableAdvancedScreenshot
        silentMode: shell.settings.enableSilentScreenshot
        topPanelHeight: panel.panelHeight
        anchors.leftMargin: shell.shellLeftMargin
        anchors.rightMargin: shell.shellRightMargin
        anchors.topMargin: shell.shellTopMargin
        anchors.bottomMargin: shell.shellBottomMargin
    // ENH210 - End
        id: itemGrabber
        anchors.fill: parent
        z: dialogs.z + 10
        GlobalShortcut { shortcut: Qt.Key_Print; onTriggered: itemGrabber.capture(shell) }
        Connections {
            target: stage
            ignoreUnknownSignals: true
            function onItemSnapshotRequested(item) { itemGrabber.capture(item) }
        }
    }

    Timer {
        id: cursorHidingTimer
        interval: 3000
        running: panel.focusedSurfaceIsFullscreen && cursor.opacity > 0
        onTriggered: cursor.opacity = 0;
    }

    // ENH114 - Popup holder
    Item {
        id: popupSurface

        z: itemGrabber.z - 1
        anchors.fill: parent
        anchors.bottomMargin: Qt.inputMethod.visible ? (Qt.inputMethod.keyboardRectangle.height) : 0
    }
    // ENH114 - End

    Cursor {
        id: cursor
        objectName: "cursor"

        z: itemGrabber.z + 1
        topBoundaryOffset: panel.panelHeight
        enabled: shell.hasMouse && screenWindow.active
        visible: enabled

        property bool mouseNeverMoved: true
        Binding {
            target: cursor; property: "x"; value: shell.width / 2
            restoreMode: Binding.RestoreBinding
            when: cursor.mouseNeverMoved && cursor.visible
        }
        Binding {
            target: cursor; property: "y"; value: shell.height / 2
            restoreMode: Binding.RestoreBinding
            when: cursor.mouseNeverMoved && cursor.visible
        }

        confiningItem: stage.itemConfiningMouseCursor

        height: units.gu(3)
        // ENH141 - Air mouse in virtual touchpad
        readonly property bool enableBigScale: {
            if (!shell.settings.biggerCursorInExternalDisplay || shell.isBuiltInScreen)
                return false

            if (shell.settings.biggerCursorInExternalDisplayOnlyAirMouse) {
                return ShellNotifier.inAirMouseMode
            } else {
                return true
            }
        }
        scale: enableBigScale ? shell.settings.biggerCursorInExternalDisplaySize : 1
        transformOrigin: Item.TopLeft
        // ENH141 - End

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

        Behavior on opacity { LomiriNumberAnimation {} }
    }

    // non-visual objects
    KeymapSwitcher {
        focusedSurface: shell.topLevelSurfaceList.focusedWindow ? shell.topLevelSurfaceList.focusedWindow.surface : null
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
                    DBusLomiriSessionService.shutdown();
                }
            }
        }
    }

    // ENH152 - Touch visuals
    MouseArea {
        id: touchMouseArea

        enabled: shell.settings.showTouchVisuals
        visible: enabled
        z: Number.MAX_VALUE
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onPressed: {
            touchRec.show()
            mouse.accepted = false
        }
        onReleased: mouse.accepted = false
        onClicked: mouse.accepted = false
        onDoubleClicked: mouse.accepted = false
        onPressAndHold: mouse.accepted = false
        onWheel: wheel.accepted = false
        onPositionChanged: {
            touchRec.show()
        }
    }

    Timer {
        id: touchRecTimer
        interval: 200
        onTriggered: touchRec.opacity = 0
    }

    Loader {
        id: touchRec

        readonly property real visibleOpacity: 0.8
        readonly property real centerX: width / 2
        readonly property real centerY: height / 2

        z: touchMouseArea.z
        asynchronous: true
        active: touchMouseArea.enabled
        opacity: 0
        width: units.gu(5)
        height: width
        x: touchMouseArea.mouseX - centerX
        y: touchMouseArea.mouseY - centerY

        function show() {
            touchRecTimer.stop()
            opacity = visibleOpacity
            touchRecTimer.restart()
        }

        Behavior on opacity { LomiriNumberAnimation {} }

        sourceComponent: Rectangle {
            color: shell.settings.touchVisualColor !== "" ? shell.settings.touchVisualColor : "white"
            radius: width / 2
        }
    }
    // ENH152 - End
    // ENH186 - BSOD prank
    Connections {
        target: shell
        Component.onCompleted: {
            if (shell.settings.blueScreenNotYetShown) {
                buruIskunuru.delayedShow()
            }
        }
    }

    Loader {
        id: buruIskunuru

        // Do not show or hide when there's a notification except if it's just the volume
        // This makes sure the phone can still be used when there's a call or a notification
        readonly property bool doNotShow: notifications.thereIsNotificationButNotVolume || shell.showingGreeter

        readonly property int defaultDuration: 35000
        readonly property int detoxModeDuration: 15000
        readonly property int defaultTo100Duration: 30000
        readonly property int detoxModeTo100Duration: 13000

        readonly property Timer delayShow: Timer {
            interval: 5000
            onTriggered: buruIskunuru.show()
        }
        readonly property bool isPending: delayShow.running
        readonly property Timer delayHide: Timer {
            interval: buruIskunuru.defaultDuration
            onTriggered: buruIskunuru.hide()
        }

        property bool dismissEnabled: true
        property int to100duration: buruIskunuru.detoxModeDuration
 
        z: Number.MAX_VALUE
        anchors.fill: parent
        visible: item ? true : false
        active: false

        onDoNotShowChanged: {
            if (doNotShow) {
                buruIskunuru.hide()
            }
        }

        function delayedShow(_delay = 5000, _detoxMode = false) {
            if(_detoxMode) {
                dismissEnabled = false
                to100duration = buruIskunuru.detoxModeTo100Duration
                delayHide.interval = buruIskunuru.detoxModeDuration
            } else {
                dismissEnabled = true
                to100duration = buruIskunuru.defaultTo100Duration
                delayHide.interval = buruIskunuru.defaultDuration
            }
            delayShow.interval = _delay
            delayShow.restart()
        }

        function cancelPending() {
            delayShow.stop()
        }

        function showDetoxMode() {
            let _interval = shell.settings.detoxModeInterval
            if (shell.settings.detoxModeBehavior === 1) {
                _interval = shell.randomNumber(shell.settings.detoxModeIntervalStart, shell.settings.detoxModeIntervalEnd)
            }
            console.log("Detox Timer: %1 mins".arg(_interval / 60000))
            buruIskunuru.delayedShow(_interval, true)
        }

        function show() {
            if (!doNotShow) {
                buruIskunuru.active = true
                buruIskunuru.delayHide.restart()
            } else {
                hide()
            }
        }

        function hide() {
            console.log("BSOD CLOSED! ::)")
            active = false
            shell.settings.blueScreenNotYetShown = false
            buruIskunuru.delayHide.stop()

            // Restart timer if in Detox mode and the current app is still in the list
            if (shell.settings.detoxModeEnabled && shell.settings.detoxModeAppList.includes(stage.focusedAppId)) {
                showDetoxMode()
            }
        }

        sourceComponent: {
            switch(shell.settings.detoxModeType) {
                case 0: // Windows
                    return buruComponent
                case 1: // Linux
                    return ttyComponent
                case 2: // Combined
                default:
                    return combinedComponent
            }
        }

        Component {
            id: buruComponent

            LPBlueScreen {
                dismissEnabled: buruIskunuru.dismissEnabled
                duration: buruIskunuru.to100duration
                onClose: buruIskunuru.hide()
            }
        }
        Component {
            id: ttyComponent

            LPTTYPage {
                dismissEnabled: buruIskunuru.dismissEnabled
                onClose: buruIskunuru.hide()
            }
        }
        Component {
            id: combinedComponent

            LPCombinedFunPage {
                dismissEnabled: buruIskunuru.dismissEnabled
                duration: buruIskunuru.to100duration
                onClose: buruIskunuru.hide()
            }
        }

        Connections {
            enabled: shell.settings.detoxModeEnabled
            target: stage
            function onFocusedAppIdChanged() {
                if (shell.settings.detoxModeAppList.includes(target.focusedAppId)) {
                    buruIskunuru.showDetoxMode()
                } else {
                    buruIskunuru.cancelPending()
                }
            }
        }
        Connections {
            target: shell.settings
            function onDetoxModeEnabledChanged() {
                if (shell.settings.detoxModeEnabled) {
                    if (shell.settings.detoxModeAppList.includes(stage.focusedAppId)) {
                        buruIskunuru.showDetoxMode()
                    }
                    shell.settings.detoxModeEnabledEpoch = new Date().getTime()
                } else {
                    buruIskunuru.cancelPending()
                    buruIskunuru.hide()
                    shell.settings.detoxModeEnabledEpoch = 0
                }
            }
        }
    }
    // ENH186 - End
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
