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

import QtQuick 2.12
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
// ENH046 - Lomiri Plus Settings
import Qt.labs.settings 1.0
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Suru 2.2
// ENH046 - End
// ENH067 - Custom Lockscreen Clock Color
import "LPColorpicker"
// ENH067 - End
// ENH064 - Dynamic Cove
import Ubuntu.MediaScanner 0.1
import QtMultimedia 5.6
// ENH064 - End
// ENH056 - Quick toggles
import QtSystemInfo 5.0
// ENH056 - End


StyledItem {
    id: shell

    theme.name: "Ubuntu.Components.Themes.SuruDark"
    
    // ENH002 - Notch/Punch hole fix
    property alias deviceConfiguration: deviceConfiguration
    // ENH036 - Use punchole as battery indicator
    // property real shellMargin: shell.isBuiltInScreen ? deviceConfiguration.notchHeightMargin : 0
    property real shellMargin: shell.isBuiltInScreen && shell.deviceConfiguration.withNotch
                            ? deviceConfiguration.notchHeightMargin + (orientation == 1 && panel.batteryCircleEnabled ? panel.batteryCircleBorder : 0)
                                : 0
    // ENH036 - End
	property real shellLeftMargin: orientation == 8 ? shellMargin : 0
	property real shellRightMargin: orientation == 2 ? shellMargin : 0
	property real shellBottomMargin: orientation == 4 ? shellMargin : 0
	property real shellTopMargin: orientation == 1 ? shellMargin : 0
    
    readonly property bool isBuiltInScreen: Screen.name == Qt.application.screens[0].name
	// ENH002 - End
    // ENH037 - Manual screen rotation button
    readonly property bool isFullScreen: panel.focusedSurfaceIsFullscreen
    // ENH037 - End
    
    // ENH046 - Lomiri Plus Settings
    property alias settings: lp_settings
    property alias lpsettingsLoader: settingsLoader
    Suru.theme: Suru.Dark
    // ENH046 - End
    // ENH064 - Dynamic Cove
    property alias mediaPlayerIndicator: panel.mediaPlayer
    property alias playbackItemIndicator: panel.playbackItem
    property alias alarmItem: alarm
    property alias alarmItemModel: alarmModel
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
    readonly property bool hideTopPanel: shell.settings.alwaysHideTopPanel
                                                && (
                                                        (shell.settings.onlyHideTopPanelonLandscape
                                                            && (shell.orientation == Qt.LandscapeOrientation
                                                                    || shell.orientation == Qt.InvertedLandscapeOrientation
                                                                )
                                                        )
                                                        || !shell.settings.onlyHideTopPanelonLandscape
                                                    )
    // ENH048 - End
    // ENH100 - Camera button to toggle rotation and OSK
    signal toggleRotation
    // ENH100 - End
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
    // ENH061 - Add haptics
    readonly property alias haptics: hapticsFeedback
    LPHaptics {
        id: hapticsFeedback
    }
    // ENH061 - End
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
    
    readonly property var indicatorsModel: [
        {"identifier": "indicator-session", "name": "System", "icon": "system-devices-panel", "indicatorIndex": sessionIndicatorIndex}
        ,{"identifier": "indicator-datetime", "name": "Time and Date", "icon": "preferences-system-time-symbolic", "indicatorIndex": datetimeIndicatorIndex}
        ,{"identifier": "indicator-network", "name": "Network", "icon": "network-wifi-symbolic", "indicatorIndex": networkIndicatorIndex}
        ,{"identifier": "indicator-power", "name": "Battery", "icon": "battery-full-symbolic", "indicatorIndex": powerIndicatorIndex}
        ,{"identifier": "indicator-sound", "name": "Sound", "icon": "audio-speakers-symbolic", "indicatorIndex": soundIndicatorIndex}
        ,{"identifier": "indicator-rotation-lock", "name": "Rotation", "icon": "orientation-lock", "indicatorIndex": rotationToggleIndex}
        ,{"identifier": "indicator-location", "name": "Location", "icon": "location", "indicatorIndex": locationToggleIndex}
        ,{"identifier": "indicator-bluetooth", "name": "Bluetooth", "icon": "bluetooth-active", "indicatorIndex": bluetoothToggleIndex}
        ,{"identifier": "kugiigi-indicator-darkmode", "name": "Dark Mode", "icon": "night-mode", "indicatorIndex": darkModeToggleIndex}
    ]
    // ENH028 - End

    // ENH056 - Quick toggles
    function findFromArray(_arr, _itemProp, _itemValue) {
        return _arr.find(item => item[_itemProp] == _itemValue)
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

    function indicatorLabel(identifier) {
        switch (identifier) {
            case "indicator-messages":
                return "Notifications"
                break
            case "indicator-rotation-lock":
                return "Rotation"
                break
            case "kugiigi-indicator-immersive":
                return "Immersive Mode"
                break
            case "indicator-keyboard":
                return "Keyboard"
                break
            case "indicator-transfer":
                return "Transfer/Files"
                break
            case "indicator-location":
                return "Location"
                break
            case "indicator-bluetooth":
                return "Bluetooth"
                break
            case "indicator-network":
                return "Network"
                break
            case "indicator-sound":
                return "Sound"
                break
            case "indicator-power":
                return "Battery"
                break
            case "indicator-datetime":
                return "Time and Date"
                break
            case "kugiigi-indicator-darkmode":
                return "Dark Mode"
                break
            case "indicator-session":
                return "System"
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

        // Drawer / Launcher
        property alias drawerBlur: settingsObj.drawerBlur
        property alias drawerBlurFullyOpen: settingsObj.drawerBlurFullyOpen
        property alias invertedDrawer: settingsObj.invertedDrawer
        property alias hideDrawerSearch: settingsObj.hideDrawerSearch
        property alias useLomiriLogo: settingsObj.useLomiriLogo
        property alias useNewLogo: settingsObj.useNewLogo
        property alias useCustomLogo: settingsObj.useCustomLogo
        property alias useCustomBFBColor: settingsObj.useCustomBFBColor
        property alias customLogoScale: settingsObj.customLogoScale
        property alias customLogoColor: settingsObj.customLogoColor
        property alias customBFBColor: settingsObj.customBFBColor
        property alias roundedBFB: settingsObj.roundedBFB
        property alias bigDrawerSearchField: settingsObj.bigDrawerSearchField
        property alias showBottomHintDrawer: settingsObj.showBottomHintDrawer

        // Drawer Dock
        property alias enableDrawerDock: settingsObj.enableDrawerDock
        property alias drawerDockApps: settingsObj.drawerDockApps
        
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
        property alias onlyShowNotificationsIndicatorWhenGreen: settingsObj.onlyShowNotificationsIndicatorWhenGreen
        property alias onlyShowSoundIndicatorWhenSilent: settingsObj.onlyShowSoundIndicatorWhenSilent

        //Quick Toggles
        property alias enableQuickToggles: settingsObj.enableQuickToggles
        property alias quickToggles: settingsObj.quickToggles
        property alias gestureMediaControls: settingsObj.gestureMediaControls
        property alias autoCollapseQuickToggles: settingsObj.autoCollapseQuickToggles

        // Lockscreen
        property alias useCustomLockscreen: settingsObj.useCustomLockscreen
        property alias useCustomCoverPage: settingsObj.useCustomCoverPage
        property alias hideLockscreenClock: settingsObj.hideLockscreenClock
        property alias useCustomLSClockColor: settingsObj.useCustomLSClockColor
        property alias customLSClockColor: settingsObj.customLSClockColor
        property alias useCustomLSClockFont: settingsObj.useCustomLSClockFont
        property alias customLSClockFont: settingsObj.customLSClockFont

        // Pro1-X
        property alias pro1_OSKOrientation: settingsObj.pro1_OSKOrientation
        property alias pro1_OSKToggleKey: settingsObj.pro1_OSKToggleKey
        property alias pro1_orientationToggleKey: settingsObj.pro1_orientationToggleKey
        property alias enableCameraKeyDoublePress: settingsObj.enableCameraKeyDoublePress
        property alias reversedCameraKeyDoubePress: settingsObj.reversedCameraKeyDoubePress
        property alias cameraKeyDoublePressDelay: settingsObj.cameraKeyDoublePressDelay

        // Outer Wilds
        property alias ow_ColoredClock: settingsObj.ow_ColoredClock
        property alias ow_GradientColoredTime: settingsObj.ow_GradientColoredTime
        property alias ow_bfbLogo: settingsObj.ow_bfbLogo
        property alias enableAlternateOW: settingsObj.ow_enableAlternateOW
        property alias ow_theme: settingsObj.ow_theme
        property alias ow_mainMenu: settingsObj.ow_mainMenu
        property alias ow_qmChance: settingsObj.ow_qmChance
        property alias enableEyeFP: settingsObj.lp_enableEyeFP

        // Dynamic Cove
        property alias enableDynamicCove: settingsObj.enableDynamicCove
        property alias dynamicCoveCurrentItem: settingsObj.dynamicCoveCurrentItem
        property alias dcDigitalClockMode: settingsObj.dcDigitalClockMode
        property alias dcShowClockWhenLockscreen: settingsObj.dcShowClockWhenLockscreen
        property alias enableCDPlayer: settingsObj.enableCDPlayer
        property alias enableCDPlayerDisco: settingsObj.enableCDPlayerDisco
        property alias dynamicCoveSelectionDelay: settingsObj.dynamicCoveSelectionDelay
        
        // Stopwatch Data
        property alias dcStopwatchTimeMS: settingsObj.dcStopwatchTimeMS
        property alias dcStopwatchLastEpoch: settingsObj.dcStopwatchLastEpoch

        // Timer Data
        property alias dcRunningTimer: settingsObj.dcRunningTimer
        property alias dcLastTimeTimer: settingsObj.dcLastTimeTimer

        // Non-persistent settings
        property bool enableOW: false
        property bool showInfographics: true

        Settings {
            id: settingsObj

            // ENH061 - Add haptics
            // ENH056 - Quick toggles
            //Component.onCompleted: shell.haptics.enabled = Qt.binding( function() { return enableHaptics } )
            Component.onCompleted: {
                shell.haptics.enabled = Qt.binding( function() { return enableHaptics } )

                // Add new Quick Toggles in don't exists yet
                let _foundItem = shell.findFromArray(quickToggles, "type", 17)
                if (!_foundItem) {
                    let _tempArr = settingsObj.quickToggles.slice()
                    _tempArr.push({"type": 17, "enabled": false})
                    settingsObj.quickToggles = _tempArr.slice()
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
                {"id": 0, "enabled": true} // indicator-session
                ,{"id": 1, "enabled": true} // indicator-datetime
                ,{"id": 2, "enabled": true} // indicator-network
                ,{"id": 3, "enabled": true} // indicator-power
                ,{"id": 4, "enabled": true} // indicator-sound
                ,{"id": 5, "enabled": false} // indicator-rotation-lock
                ,{"id": 6, "enabled": false} // indicator-location
                ,{"id": 7, "enabled": false} // indicator-bluetooth
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
                , "ubuntu-system-settings"
                , "address-book-app"
                , "openstore.openstore-team_openstore"
                , "com.ubuntu.gallery_gallery"
                , "com.ubuntu.camera_camera"
            ]
            property bool showBottomHintDrawer: true
            property bool showMiddleNotchHint: false
            property bool onlyShowNotificationsIndicatorWhenGreen: false
            property bool onlyShowSoundIndicatorWhenSilent: false
            property int ow_theme: 0
            /*
                0 - Main Menu
                1 - Solar System
            */
            property bool onlyShowLomiriSettingsWhenUnlocked: true
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
                                    Layout.preferredWidth: units.gu(10)
                                    Layout.preferredHeight: units.gu(4)
                                    Layout.alignment: Qt.AlignRight
                                    radius: units.gu(1)
                                    color: colorPicker.colorValue
                                    border {
                                        width: units.dp(1)
                                        color: theme.palette.normal.foregroundText
                                    }
                                }
                                QQC2.CheckBox {
                                    id: paletteMode
                                    Layout.alignment: Qt.AlignRight
                                    text: "Palette Mode"
                                    onCheckedChanged: colorPicker.paletteMode = !colorPicker.paletteMode
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
                                            ColorAnimation { duration: UbuntuAnimation.FastDuration }
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
                                QQC2.Button {
                                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                    text: "Close"
                                    onClicked: colorPickerLoader.close()
                                }
                                QQC2.Button {
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    text: colorPicker.savedPaletteIsSelected ? "Delete Palette" : "Save Palette"
                                    onClicked: {
                                        if (colorPicker.savedPaletteIsSelected) {
                                            colorPickerLoader.deletePalette(colorPicker.savedPaletteColor)
                                        } else {
                                            colorPickerLoader.savePalette(colorPicker.colorValue)
                                        }
                                    }
                                }
                                QQC2.Button {
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    text: "Revert"
                                    onClicked: colorPickerLoader.revertColor()
                                }
                                QQC2.Button {
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    text: "Apply"
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
        active: false
        z: inputMethod.visible ? inputMethod.z - 1 : shellBorderLoader.z + 1
        width: Math.min(parent.width, units.gu(40))
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
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: stack.currentItem.title
                                verticalAlignment: Text.AlignVCenter
                                Suru.textLevel: Suru.HeadingThree
                                elide: Text.ElideRight
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
                                        ColorAnimation { duration: UbuntuAnimation.FastDuration }
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
                    
                    QQC2.Button {
                        id: closeButton

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
                text: "Outer Wilds"
                onClicked: settingsLoader.item.stack.push(outerWildsPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "General"
                onClicked: settingsLoader.item.stack.push(generalPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Customizations"
                onClicked: settingsLoader.item.stack.push(customizationsPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Features"
                onClicked: settingsLoader.item.stack.push(featuresPage, {"title": text})
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
        }
    }
    Component {
        id: generalPage
        
        LPSettingsPage {
             QQC2.CheckDelegate {
                id: onlyShowLomiriSettingsWhenUnlocked
                Layout.fillWidth: true
                text: "LP settings only available when unlocked"
                onCheckedChanged: shell.settings.onlyShowLomiriSettingsWhenUnlocked = checked
                Binding {
                    target: onlyShowLomiriSettingsWhenUnlocked
                    property: "checked"
                    value: shell.settings.onlyShowLomiriSettingsWhenUnlocked
                }
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Haptics feedback for button presses and swipe gestures\n"
                + "Only applies to some controls and not all"
                wrapMode: Text.WordWrap
                Suru.textLevel: Suru.Caption
            }
            QQC2.CheckDelegate {
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
            QQC2.CheckDelegate {
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
            QQC2.CheckDelegate {
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
            QQC2.CheckDelegate {
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
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Key Shortcuts"
                onClicked: settingsLoader.item.stack.push(keyShortcutsPage, {"title": text})
            }
        }
    }
    Component {
        id: keyShortcutsPage
        
        LPSettingsPage {
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Ctrl + Period"
                wrapMode: Text.WordWrap
                Suru.textLevel: Suru.HeadingThree
            }
            QQC2.CheckDelegate {
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
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Camera Key function"
                wrapMode: Text.WordWrap
                Suru.textLevel: Suru.HeadingThree
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "This will only work if the camera key is properly mapped in your device's port"
                wrapMode: Text.WordWrap
                Suru.textLevel: Suru.Caption
            }
            QQC2.CheckDelegate {
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
            QQC2.CheckDelegate {
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
            QQC2.CheckDelegate {
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
            QQC2.ItemDelegate {
                Layout.fillWidth: true
                text: "Double press delay"
                visible: enableCameraKeyDoublePress.visible && shell.settings.enableCameraKeyDoublePress
                indicator: QQC2.SpinBox {
                    id: cameraKeyDoublePressDelay
                    anchors {
                        right: parent.right
                        rightMargin: units.gu(2)
                        verticalCenter: parent.verticalCenter
                    }
                    from: 100
                    to: 1000
                    stepSize: 50
                    onValueChanged: shell.settings.cameraKeyDoublePressDelay = value
                    Binding {
                        target: cameraKeyDoublePressDelay
                        property: "value"
                        value: shell.settings.cameraKeyDoublePressDelay
                    }
                }
            }
        }
    }
    Component {
        id: outerWildsPage
        
        LPSettingsPage {
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                color: theme.palette.normal.negative
                text: "May crash Lomiri especially the Solar System theme. Settings is non-persistent to avoid being stuck."
                wrapMode: Text.WordWrap
                Suru.textLevel: Suru.Caption
            }
            QQC2.CheckDelegate {
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
                    i18n.tr("Solar System")
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.ow_theme
                onSelectedIndexChanged: shell.settings.ow_theme = selectedIndex
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableOW && shell.settings.ow_theme == 0
                text: "Higher value means lesser chance to see the Quantum moon upon unlocking (i.e. 100 means your chance is 1 in a hundred)"
                wrapMode: Text.WordWrap
                Suru.textLevel: Suru.Caption
            }
            QQC2.ItemDelegate {
                Layout.fillWidth: true
                visible: shell.settings.enableOW && shell.settings.ow_theme == 0
                text: "Quantum Luck"
                indicator: QQC2.SpinBox {
                    id: ow_qmChance
                    anchors {
                        right: parent.right
                        rightMargin: units.gu(2)
                        verticalCenter: parent.verticalCenter
                    }
                    from: 1
                    to: 500
                    stepSize: 1
                    editable: true
                    onValueChanged: shell.settings.ow_qmChance = value
                    Binding {
                        target: ow_qmChance
                        property: "value"
                        value: shell.settings.ow_qmChance
                    }
                }
            }
            QQC2.CheckDelegate {
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
            QQC2.CheckDelegate {
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
            QQC2.CheckDelegate {
                id: ow_GradientColoredTime
                Layout.fillWidth: true
                visible: shell.settings.ow_ColoredClock
                text: "Gradient Time Text"
                onCheckedChanged: shell.settings.ow_GradientColoredTime = checked
                Binding {
                    target: ow_GradientColoredTime
                    property: "checked"
                    value: shell.settings.ow_GradientColoredTime
                }
            }
            QQC2.CheckDelegate {
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
            QQC2.ItemDelegate {
                id: ow_bfbLogo

                Layout.fillWidth: true
                text: "Logo"
                indicator: QQC2.SpinBox {
                    id: owLogo
                    anchors {
                        right: parent.right
                        rightMargin: units.gu(2)
                        verticalCenter: parent.verticalCenter
                    }
                    from: 0
                    to: 9
                    stepSize: 1
                    textFromValue: function(value, locale) {
                                        switch (value) {
                                            case 0:
                                                return "Disabled"
                                            case 1:
                                                return "Brittle Hollow"
                                            case 2:
                                                return "Dark Bramble"
                                            case 3:
                                                return "Hourglass Twins"
                                            case 4:
                                                return "Interloper"
                                            case 5:
                                                return "Nomai Eye"
                                            case 6:
                                                return "Quantum Moon"
                                            case 7:
                                                return "Stranger Eye"
                                            case 8:
                                                return "Sun"
                                            case 9:
                                                return "Timber Hearth"
                                        }
                                   }
                    valueFromText: function(text, locale) {
                                        switch (text) {
                                            case "None":
                                                return 0
                                            case "Middle":
                                                return 1
                                            case "Left":
                                                return 2
                                            case "Right":
                                                return 3
                                            case "Disabled":
                                                return 0
                                            case "Brittle Hollow":
                                                return 1
                                            case "Dark Bramble":
                                                return 2
                                            case "Hourglass Twins":
                                                return 3
                                            case "Interloper":
                                                return 4
                                            case "Nomai Eye":
                                                return 5
                                            case "Quantum Moon":
                                                return 6
                                            case "Stranger Eye":
                                                return 7
                                            case "Sun":
                                                return 8
                                            case "Timber Hearth":
                                                return 9
                                        }
                                   }
                    onValueChanged: shell.settings.ow_bfbLogo = value
                    Binding {
                        target: owLogo
                        property: "value"
                        value: shell.settings.ow_bfbLogo
                    }
                }
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

            Component {
                id: pro1Page
                
                LPSettingsPage {
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Disables OSK when in the same orientation as the physical keyboard and enables it when in any other orientation"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.Caption
                    }
                    QQC2.CheckDelegate {
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
        id: customizationsPage
        
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
                text: "Top Panel"
                onClicked: settingsLoader.item.stack.push(topPanelpage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "App Drawer"
                onClicked: settingsLoader.item.stack.push(drawerpage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "App Spread"
                onClicked: settingsLoader.item.stack.push(spreadPage, {"title": text})
            }

            Component {
                id: lockscreenPage
                
                LPSettingsPage {
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Filename: ~/Pictures/lomiriplus/lockscreen"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.Caption
                    }
                    QQC2.CheckDelegate {
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
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomLockscreen
                        text: "Filename: ~/Pictures/lomiriplus/coverpage"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.Caption
                    }
                    QQC2.CheckDelegate {
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
                    QQC2.CheckDelegate {
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
                    QQC2.CheckDelegate {
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
                    QQC2.CheckDelegate {
                        id: useCustomLSClockFont
                        Layout.fillWidth: true
                        text: "Custom clock font"
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
                        text: i18n.tr("Custom clock font")
                        model: Qt.fontFamilies()
                        containerHeight: itemHeight * 6
                        selectedIndex: model.indexOf(shell.settings.customLSClockFont)
                        onSelectedIndexChanged: shell.settings.customLSClockFont = model[selectedIndex]
                    }
                }
            }
            Component {
                id: topPanelpage

                LPSettingsPage {
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Indicator Options"
                        onClicked: settingsLoader.item.stack.push(indicatorOptionsPage, {"title": text})
                    }
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
                    QQC2.ItemDelegate {
                        Layout.fillWidth: true
                        text: "Top Panel Opacity"
                        indicator: QQC2.SpinBox {
                            id: topPanelOpacity
                            anchors {
                                right: parent.right
                                rightMargin: units.gu(2)
                                verticalCenter: parent.verticalCenter
                            }
                            from: 10
                            to: 100
                            stepSize: 10
                            onValueChanged: shell.settings.topPanelOpacity = value
                            Binding {
                                target: topPanelOpacity
                                property: "value"
                                value: shell.settings.topPanelOpacity
                            }
                        }
                    }
                    QQC2.CheckDelegate {
                        id: indicatorBlur
                        Layout.fillWidth: true
                        text: "Top Panel Pages Blur"
                        onCheckedChanged: shell.settings.indicatorBlur = checked
                        Binding {
                            target: indicatorBlur
                            property: "checked"
                            value: shell.settings.indicatorBlur
                        }
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Always displays the top panel menu in full width in portrait orientations"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.Caption
                    }
                    QQC2.CheckDelegate {
                        id: alwaysFullWidthTopPanel
                        Layout.fillWidth: true
                        text: "Always full width top panel menu"
                        onCheckedChanged: shell.settings.alwaysFullWidthTopPanel = checked
                        Binding {
                            target: alwaysFullWidthTopPanel
                            property: "checked"
                            value: shell.settings.alwaysFullWidthTopPanel
                        }
                    }
                    QQC2.CheckDelegate {
                        id: widerLandscapeTopPanel
                        Layout.fillWidth: true
                        text: "Wider top panel pages in landscape"
                        onCheckedChanged: shell.settings.widerLandscapeTopPanel = checked
                        Binding {
                            target: widerLandscapeTopPanel
                            property: "checked"
                            value: shell.settings.widerLandscapeTopPanel
                        }
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Top panel will always be hidden unless in the greeter or app spread"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.Caption
                    }
                    QQC2.CheckDelegate {
                        id: alwaysHideTopPanel
                        Layout.fillWidth: true
                        text: "Always Hide Top Panel"
                        onCheckedChanged: shell.settings.alwaysHideTopPanel = checked
                        Binding {
                            target: alwaysHideTopPanel
                            property: "checked"
                            value: shell.settings.alwaysHideTopPanel
                        }
                    }
                    QQC2.CheckDelegate {
                        id: onlyHideTopPanelonLandscape
                        Layout.fillWidth: true
                        text: "Only Hide Top Panel on Landscape"
                        visible: shell.settings.alwaysHideTopPanel
                        onCheckedChanged: shell.settings.onlyHideTopPanelonLandscape = checked
                        Binding {
                            target: onlyHideTopPanelonLandscape
                            property: "checked"
                            value: shell.settings.onlyHideTopPanelonLandscape
                        }
                    }
                }
            }
            Component {
                id: indicatorOptionsPage
                
                LPSettingsPage {
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "System"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.HeadingThree
                    }
                    QQC2.CheckDelegate {
                        id: enableActiveScreenToggleIndicator
                        Layout.fillWidth: true
                        text: "Show active screen toggle"
                        onCheckedChanged: shell.settings.enableActiveScreenToggleIndicator = checked
                        Binding {
                            target: enableActiveScreenToggleIndicator
                            property: "checked"
                            value: shell.settings.enableActiveScreenToggleIndicator
                        }
                    }
                    QQC2.CheckDelegate {
                        id: showActiveScreenIconIndicator
                        Layout.fillWidth: true
                        text: "Display icon indicator for active screen"
                        onCheckedChanged: shell.settings.showActiveScreenIconIndicator = checked
                        Binding {
                            target: showActiveScreenIconIndicator
                            property: "checked"
                            value: shell.settings.showActiveScreenIconIndicator
                        }
                    }
                    QQC2.CheckDelegate {
                        id: enableAppSuspensionToggleIndicator
                        Layout.fillWidth: true
                        text: "Show app suspension toggle"
                        onCheckedChanged: shell.settings.enableAppSuspensionToggleIndicator = checked
                        Binding {
                            target: enableAppSuspensionToggleIndicator
                            property: "checked"
                            value: shell.settings.enableAppSuspensionToggleIndicator
                        }
                    }
                    QQC2.CheckDelegate {
                        id: showAppSuspensionIconIndicator
                        Layout.fillWidth: true
                        text: "Display icon indicator for app suspension"
                        onCheckedChanged: shell.settings.showAppSuspensionIconIndicator = checked
                        Binding {
                            target: showAppSuspensionIconIndicator
                            property: "checked"
                            value: shell.settings.showAppSuspensionIconIndicator
                        }
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Date and Time"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.HeadingThree
                    }
                    QQC2.CheckDelegate {
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
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Battery"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.HeadingThree
                    }
                    QQC2.CheckDelegate {
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
                    QQC2.CheckDelegate {
                        id: hideBatteryIndicatorBracket
                        Layout.fillWidth: true
                        text: "Hide parenthesis in label"
                        onCheckedChanged: shell.settings.hideBatteryIndicatorBracket = checked
                        Binding {
                            target: hideBatteryIndicatorBracket
                            property: "checked"
                            value: shell.settings.hideBatteryIndicatorBracket
                        }
                    }
                    QQC2.CheckDelegate {
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
                    QQC2.CheckDelegate {
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
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Sound"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.HeadingThree
                    }
                    QQC2.CheckDelegate {
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
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Keyboard"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.HeadingThree
                    }
                    QQC2.CheckDelegate {
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
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Notifications"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.HeadingThree
                    }
                    QQC2.CheckDelegate {
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

                        QQC2.CheckDelegate {
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

                        QQC2.CheckDelegate {
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
                    QQC2.CheckDelegate {
                        id: drawerBlur
                        Layout.fillWidth: true
                        text: "Interactive Blur"
                        onCheckedChanged: shell.settings.drawerBlur = checked
                        Binding {
                            target: drawerBlur
                            property: "checked"
                            value: shell.settings.drawerBlur
                        }
                    }
                    QQC2.CheckDelegate {
                        id: invertedDrawer
                        Layout.fillWidth: true
                        text: "Inverted App Drawer"
                        onCheckedChanged: shell.settings.invertedDrawer = checked
                        Binding {
                            target: invertedDrawer
                            property: "checked"
                            value: shell.settings.invertedDrawer
                        }
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Swipe up from the bottom or type something with a physical keyboard to search"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.Caption
                    }
                    QQC2.CheckDelegate {
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
                    QQC2.CheckDelegate {
                        id: showBottomHintDrawer
                        Layout.fillWidth: true
                        text: "Show bottom hint"
                        visible: shell.settings.hideDrawerSearch
                        onCheckedChanged: shell.settings.showBottomHintDrawer = checked
                        Binding {
                            target: showBottomHintDrawer
                            property: "checked"
                            value: shell.settings.showBottomHintDrawer
                        }
                    }
                    QQC2.CheckDelegate {
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
                }
            }
            Component {
                id: spreadPage
                
                LPSettingsPage {
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Requires Notch/Punchhole configuration and Corner Radius"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.Caption
                    }
                    QQC2.CheckDelegate {
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
                }
            }
            Component {
                id: launcherPage
                
                LPSettingsPage {
                    QQC2.CheckDelegate {
                        id: roundedBFB
                        Layout.fillWidth: true
                        text: "Rounded Launcher Button"
                        onCheckedChanged: shell.settings.roundedBFB = checked
                        Binding {
                            target: roundedBFB
                            property: "checked"
                            value: shell.settings.roundedBFB
                        }
                    }
                    QQC2.CheckDelegate {
                        id: useCustomBFBColor
                        Layout.fillWidth: true
                        text: "Custom BFB Color"
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
                    QQC2.CheckDelegate {
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
                    QQC2.CheckDelegate {
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
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Custom Logo Filename: ~/Pictures/lomiriplus/bfb.svg"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.Caption
                    }
                    QQC2.CheckDelegate {
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
                    QQC2.ItemDelegate {
                        Layout.fillWidth: true
                        text: "Logo scale (%)"
                        visible: shell.settings.useCustomLogo
                        indicator: QQC2.SpinBox {
                            id: logScale
                            anchors {
                                right: parent.right
                                rightMargin: units.gu(2)
                                verticalCenter: parent.verticalCenter
                            }
                            from: 5
                            to: 100
                            stepSize: 5
                            onValueChanged: shell.settings.customLogoScale = value
                            Binding {
                                target: logScale
                                property: "value"
                                value: shell.settings.customLogoScale
                            }
                        }
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: customLogoColor.visible
                        text: "Will replace all #ffffff surfaces in the SVG"
                        Suru.textLevel: Suru.Caption
                        wrapMode: Text.WordWrap
                    }

                    LPColorField {
                        id: customLogoColor
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        title: "Logo Color"
                        visible: shell.settings.useCustomLogo
                        onTextChanged: shell.settings.customLogoColor = text
                        onColorPicker: colorPickerLoader.open(this)
                        Binding {
                            target: customLogoColor
                            property: "text"
                            value: shell.settings.customLogoColor
                        }
                    }
                }
            }
        }
    }
    Component {
        id: featuresPage

        LPSettingsPage {
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Quick toggles"
                onClicked: settingsLoader.item.stack.push(quickTogglesPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Dynamic Cove"
                onClicked: settingsLoader.item.stack.push(dynamicCovePage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Indicator Open Gesture"
                onClicked: settingsLoader.item.stack.push(indicatorOpenPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "App Drawer Dock"
                onClicked: settingsLoader.item.stack.push(drawerDockPage, {"title": text})
            }
            QQC2.CheckDelegate {
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
            QQC2.CheckDelegate {
                id: orientationPrompt
                Layout.fillWidth: true
                text: "Screen Rotation Button"
                onCheckedChanged: shell.settings.orientationPrompt = checked
                Binding {
                    target: orientationPrompt
                    property: "checked"
                    value: shell.settings.orientationPrompt
                }
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Requires: Right punchholes, Notch Side Margin, Exact Punchhole Width, Punchhole Height From Top"
                wrapMode: Text.WordWrap
                Suru.textLevel: Suru.Caption
            }
            QQC2.CheckDelegate {
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
        }
    }
    Component {
        id: drawerDockPage
        
        LPSettingsPage {
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Dock of pinned apps displayed at the bottom of the app drawer\n\n"
                + " • Expand/Collapse: Swipe up/down\n"
                + " • Toggle edit mode: Press and hold on empty space to enter/exit. Use context menu to enter. Click on app to exit.\n"
                + " • Rearrange apps: Press, hold and drag on app icons"
                wrapMode: Text.WordWrap
                Suru.textLevel: Suru.Caption
            }
            QQC2.CheckDelegate {
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
        }
    }
    Component {
        id: indicatorOpenPage
        
        LPSettingsPage {
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Swipe from the very bottom of left/right edge to open the application menu/indicator panel\n\n"
                + " • Default: Indicator panel or application menu opens after swiping\n"
                + " • Direct Access (Only for indicators): Swipe and drag to select a specific predefined indicator. Release to select. "
                + "Quick short swipe will open the Notifications/Messages Indicator"
                wrapMode: Text.WordWrap
                Suru.textLevel: Suru.Caption
            }
            QQC2.CheckDelegate {
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
            QQC2.CheckDelegate {
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
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Enables different functions inside the lockscreen circle\n"
                + "Media controls, Timer, Stopwatch, Clock, etc\n\n"
                + "Press and drag on the dotted cirlce to select a function\n"
                + "Short swipe up from bottom to hide or show"
                wrapMode: Text.WordWrap
                Suru.textLevel: Suru.Caption
            }
            QQC2.CheckDelegate {
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
            QQC2.ItemDelegate {
                id: dynamicCoveSelectionDelayItem

                Layout.fillWidth: true
                visible: shell.settings.enableDynamicCove
                text: "Selection delay"
                indicator: QQC2.SpinBox {
                    id: dynamicCoveSelectionDelay
                    anchors {
                        right: parent.right
                        rightMargin: units.gu(2)
                        verticalCenter: parent.verticalCenter
                    }
                    from: 0
                    to: 1000
                    stepSize: 50
                    onValueChanged: shell.settings.dynamicCoveSelectionDelay = value
                    Binding {
                        target: dynamicCoveSelectionDelay
                        property: "value"
                        value: shell.settings.dynamicCoveSelectionDelay
                    }
                }
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Entering the lockscreen will always show the clock\n"
                + "Otherwise, the last selected will be shown"
                wrapMode: Text.WordWrap
                visible: dcShowClockWhenLockscreen.visible
                Suru.textLevel: Suru.Caption
            }
            QQC2.CheckDelegate {
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
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Press and hold to toggle disco mode"
                wrapMode: Text.WordWrap
                visible: enableCDPlayerDiscoCheck.visible
                Suru.textLevel: Suru.Caption
            }
            QQC2.CheckDelegate {
                id: enableCDPlayerDiscoCheck
                Layout.fillWidth: true
                text: "Enable Disco mode in media controls"
                visible: shell.settings.enableDynamicCove
                onCheckedChanged: shell.settings.enableCDPlayerDisco = checked
                Binding {
                    target: enableCDPlayerDiscoCheck
                    property: "checked"
                    value: shell.settings.enableCDPlayerDisco
                }
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDynamicCove
                text: "For playlists to work, create a symlink of the music app's database files\n"
                + "Source: /home/phablet/.local/share/com.ubuntu.music/Databases/\n"
                + "Destination: /home/phablet/.local/share/Canonical/unity8/QML/OfflineStorage/Databases/\n"
                + "Files:"
                + " - 2be3974e34f63282a99a37e9e2077ee4.sqlite\n"
                + " - 2be3974e34f63282a99a37e9e2077ee4.ini\n"
                + " - d332dbaaf4b3a1a7909b1d623eb1d02b.sqlite\n"
                + " - d332dbaaf4b3a1a7909b1d623eb1d02b.ini"
                wrapMode: Text.WordWrap
                Suru.textLevel: Suru.Caption
            }
        }
    }
    Component {
        id: quickTogglesPage
        
        LPSettingsPage {
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Located at the bottom of Top Panel pages\n"
                + "Single click: Toggles the setting\n"
                + "Press and hold: Opens corresponding indicator panel or settings page\n"
                + "Swipe up/down: Expands/Collapses the toggles list\n"
                + "Press and hold on empty space: Enter/Exit edit mode\n"
                + "Press and hold then drag to rearrange items"
                wrapMode: Text.WordWrap
                Suru.textLevel: Suru.Caption
            }
            QQC2.CheckDelegate {
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
            QQC2.CheckDelegate {
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
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: gestureMediaControls.visible
                text: "Single click: Play/Pause\n"
                + "Swipe left/right: Play next/previous song"
                wrapMode: Text.WordWrap
                Suru.textLevel: Suru.Caption
            }
            QQC2.CheckDelegate {
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
        }
    }
    Component {
        id: devicePage
        
        LPSettingsPage {
            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Most configuration only takes effect when your device doesn't have pre-configuration"
                wrapMode: Text.WordWrap
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
                    QQC2.ItemDelegate {
                        id: notchPositionItem
                        readonly property bool notchEnabled: shell.settings.notchPosition > 0
                        Layout.fillWidth: true
                        text: "Notch Position"
                        indicator: QQC2.SpinBox {
                            id: notchPosition
                            anchors {
                                right: parent.right
                                rightMargin: units.gu(2)
                                verticalCenter: parent.verticalCenter
                            }
                            from: 0
                            to: 3
                            stepSize: 1
                            textFromValue: function(value, locale) {
                                                switch (value) {
                                                    case 0:
                                                        return "None"
                                                    case 1:
                                                        return "Middle"
                                                    case 2:
                                                        return "Left"
                                                    case 3:
                                                        return "Right"
                                                }
                                           }
                            valueFromText: function(text, locale) {
                                                switch (text) {
                                                    case "None":
                                                        return 0
                                                    case "Middle":
                                                        return 1
                                                    case "Left":
                                                        return 2
                                                    case "Right":
                                                        return 3
                                                }
                                           }
                            onValueChanged: shell.settings.notchPosition = value
                            Binding {
                                target: notchPosition
                                property: "value"
                                value: shell.settings.notchPosition
                            }
                        }
                    }
                    QQC2.CheckDelegate {
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
                    QQC2.CheckDelegate {
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
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        verticalAlignment: QQC2.Label.AlignVCenter
                        visible: notchPositionItem.notchEnabled
                        text: "Notch Top Margin"
                    }
                    QQC2.SpinBox {
                        id: notchHeightMargin
                        Layout.fillWidth: true
                        Layout.topMargin: 0
                        Layout.margins: units.gu(2)
                        visible: notchPositionItem.notchEnabled
                        editable: true
                        from: 0
                        to: 400
                        stepSize: 10
                        onValueChanged: shell.settings.notchHeightMargin = value
                        Binding {
                            target: notchHeightMargin
                            property: "value"
                            value: shell.settings.notchHeightMargin
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: units.dp(1)
                        color: Suru.neutralColor
                        visible: notchPositionItem.notchEnabled
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        verticalAlignment: QQC2.Label.AlignVCenter
                        visible: notchPositionItem.notchEnabled
                        text: "Notch Width Margin"
                    }
                    QQC2.SpinBox {
                        id: notchWidthMargin
                        Layout.fillWidth: true
                        Layout.topMargin: 0
                        Layout.margins: units.gu(2)
                        visible: notchPositionItem.notchEnabled
                        editable: true
                        from: 0
                        to: 400
                        stepSize: 10
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
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        verticalAlignment: QQC2.Label.AlignVCenter
                        text: "Exact Punchhole Width"
                    }
                    QQC2.SpinBox {
                        id: punchHoleWidth
                        Layout.fillWidth: true
                        Layout.topMargin: 0
                        Layout.margins: units.gu(2)
                        editable: true
                        from: 0
                        to: 300
                        stepSize: 10
                        onValueChanged: shell.settings.punchHoleWidth = value
                        Binding {
                            target: punchHoleWidth
                            property: "value"
                            value: shell.settings.punchHoleWidth
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: units.dp(1)
                        color: Suru.neutralColor
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        verticalAlignment: QQC2.Label.AlignVCenter
                        text: "Punchhole Height From Top"
                    }
                    QQC2.SpinBox {
                        id: punchHoleHeightFromTop
                        Layout.fillWidth: true
                        Layout.topMargin: 0
                        Layout.margins: units.gu(2)
                        editable: true
                        from: 0
                        to: 200
                        stepSize: 5
                        onValueChanged: shell.settings.punchHoleHeightFromTop = value
                        Binding {
                            target: punchHoleHeightFromTop
                            property: "value"
                            value: shell.settings.punchHoleHeightFromTop
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: units.dp(1)
                        color: Suru.neutralColor
                    }
                }
            }
            Component {
                id: cornerPage
                
                LPSettingsPage {
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        text: "Only necessary or has effects when a notch/punchhole is configured"
                        wrapMode: Text.WordWrap
                        Suru.textLevel: Suru.Caption
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        verticalAlignment: QQC2.Label.AlignVCenter
                        text: "Corner Radius"
                    }
                    QQC2.SpinBox {
                        id: roundedCornerRadius
                        Layout.fillWidth: true
                        Layout.topMargin: 0
                        Layout.margins: units.gu(2)
                        editable: true
                        from: 0
                        to: 500
                        stepSize: 10
                        onValueChanged: shell.settings.roundedCornerRadius = value
                        Binding {
                            target: roundedCornerRadius
                            property: "value"
                            value: shell.settings.roundedCornerRadius
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: units.dp(1)
                        color: Suru.neutralColor
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        verticalAlignment: QQC2.Label.AlignVCenter
                        text: "Corner Margin"
                    }
                    QQC2.SpinBox {
                        id: roundedCornerMargin
                        Layout.fillWidth: true
                        Layout.topMargin: 0
                        Layout.margins: units.gu(2)
                        editable: true
                        from: 0
                        to: 200
                        stepSize: 5
                        onValueChanged: shell.settings.roundedCornerMargin = value
                        Binding {
                            target: roundedCornerMargin
                            property: "value"
                            value: shell.settings.roundedCornerMargin
                        }
                    }
                }
            }
        }
    }
    // ENH046 - End
    // ENH064 - Dynamic Cove
    Settings {
        id: clockAppSettings

        fileName: "/home/phablet/.config/com.ubuntu.clock/com.ubuntu.clock.conf"
        Component.onCompleted: alarm.defaultSound = value("defaultAlarmSound", "file:///usr/share/sounds/ubuntu/ringtones/Alarm clock.ogg")
    }
    Alarm {
        id: alarm

        readonly property string defaultId: "[LomiriPlus] Current Timer"
        property url defaultSound: "file:///usr/share/sounds/ubuntu/ringtones/Ubuntu.ogg"

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

                MediaPlayer {
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
        name: applicationArguments.deviceName
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
            onShownChanged: {
                if (!target.shown && stage.topLevelSurfaceList.count == 0) {
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
                    UbuntuNumberAnimation {
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
                    UbuntuNumberAnimation {
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
                    UbuntuNumberAnimation {
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
                    UbuntuNumberAnimation {
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
                    UbuntuNumberAnimation {
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
        z: batteryCircle.z
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
    CircularProgressBar {
        id: batteryCircle

        readonly property bool charging: panel.batteryCharging
        property bool full: finished
        
        visible: shell.isBuiltInScreen && shell.orientation == 1
                        && shell.deviceConfiguration.notchPosition == "right" // && !shell.deviceConfiguration.fullyHideNotchInPortrait
                        && shell.settings.batteryCircle
        z: shellBorderLoader.z + 1
        width: shell.deviceConfiguration.punchHoleWidth + (borderWidth * 4)
        height: width
        progress: panel.batteryLevel
        blackSpaceColor: UbuntuColors.silk
        borderColor: {
            if (charging) {
                return theme.palette.normal.positive
            } else {
                switch (true) {
                    case progress <= 25:
                        return theme.palette.normal.negative
                        break
                    case progress <= 50:
                        return UbuntuColors.orange
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
        anchors {
            right: parent.right
            rightMargin: shell.deviceConfiguration.notchWidthMargin - shell.deviceConfiguration.punchHoleWidth - borderWidth * 2
            top: parent.top 
            topMargin: shell.deviceConfiguration.punchHoleHeightFromTop - shell.deviceConfiguration.punchHoleWidth - borderWidth * 2
        }
        
        Behavior on borderColor {
            ColorAnimation {
                duration: UbuntuAnimation.BriskDuration
            }
        }
    }
    // ENH036 - End
    
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
        // ENH100 - Camera button to toggle rotation and OSK
        onCameraTriggered: {
            if (shell.settings.reversedCameraKeyDoubePress) {
                unity8Settings.alwaysShowOsk = !unity8Settings.alwaysShowOsk
            } else {
                shell.toggleRotation()
            }
        }
        onCameraDoublePressed: {
            if (shell.settings.reversedCameraKeyDoubePress) {
                shell.toggleRotation()
            } else {
                unity8Settings.alwaysShowOsk = !unity8Settings.alwaysShowOsk
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
        // anchors.topMargin: panel.fullscreenMode ? shell.shellTopMargin 
        //anchors.topMargin: panel.fullscreenMode || panel.forceHidePanel ? shell.shellTopMargin 
        anchors.topMargin: panel.fullscreenMode || shell.hideTopPanel ? shell.shellTopMargin 
        // ENH048 - End
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
            // ENH032 - Infographics Outer Wilds
            enableOW: lp_settings.enableOW
            alternateOW: lp_settings.ow_theme == 0
            eyeOpened: eyeBlinkLoader.item ? eyeBlinkLoader.item.eyeOpened : false
            blinkComplete: eyeBlinkLoader.item ? eyeBlinkLoader.item.blinkComplete : false
            // ENH032 - End
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
            // ENH039 - New side-stage enablement logic
            // mode: usageScenario == "phone" ? "staged"
            //          : usageScenario == "tablet" ? "stagedWithSideStage"
            //          : "windowed"
            mode: usageScenario == "phone" || usageScenario == "tablet" ? 
            // ENH046 - Lomiri Plus Settings
                        //((shell.height > shell.width && shell.height / 2 >= units.gu(40)) || (shell.height <= shell.width && shell.width / 2 >= units.gu(40))) ?
                        ((shell.height > shell.width && shell.height / 2 >= units.gu(40)) || (shell.height <= shell.width && shell.width / 2 >= units.gu(40)))
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
    Loader {
        id: indicatorSwipeLoader

        active: shell.settings.indicatorGesture
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

            Behavior on opacity { UbuntuNumberAnimation { duration: UbuntuAnimation.FastDuration } }

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
                    Behavior on scale { UbuntuNumberAnimation { duration: UbuntuAnimation.FastDuration } }

                    onHighlightedChanged: if (highlighted) shell.haptics.playSubtle()

                    Rectangle {
                        id: bgRec

                        color: highlighted ? theme.palette.highlighted.foreground : theme.palette.normal.foreground
                        radius: width / 2
                        width: Math.min(parent.width, indicatorItem.maximumSize)
                        height: width
                        anchors.centerIn: parent
                        Behavior on color { ColorAnimation { duration: UbuntuAnimation.FastDuration } }
                    }
                    Icon {
                        anchors.centerIn: bgRec
                        height: bgRec.height * 0.5
                        width: height
                        name: itemIcon
                        color: highlighted ? theme.palette.normal.activity : theme.palette.normal.foregroundText
                        Behavior on color { ColorAnimation { duration: UbuntuAnimation.FastDuration } }
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
            // ENH058 - Interative Blur (Focal)
            blurSource: shell.settings.indicatorBlur ? (greeter.shown ? greeter : stages) : null
            leftMarginBlur: !greeter.shown ? overlay.anchors.leftMargin : 0
            topMarginBlur: !greeter.shown ? overlay.anchors.topMargin : 0
            // ENH058 - End
            // ENH036 - Use punchole as battery indicator
            batteryCircleEnabled : batteryCircle.visible
            batteryCircleBorder: batteryCircle.borderWidth
            // ENH036 - End

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
            // ENH048 - Always hide panel mode
            fullscreenMode: (focusedSurfaceIsFullscreen && !LightDMService.greeter.active && launcher.progress == 0 && !stage.spreadShown)
                             || greeter.hasLockedApp
            forceHidePanel: shell.hideTopPanel && ((!LightDMService.greeter.active && !stage.spreadShown && stage.rightEdgeDragProgress == 0 && stage.rightEdgePushProgress == 0)
                                                                    || greeter.hasLockedApp)
            // ENH048 - End
            greeterShown: greeter && greeter.shown
            hasKeyboard: shell.hasKeyboard
            supportsMultiColorLed: shell.supportsMultiColorLed
        }

        Launcher {
            id: launcher
            objectName: "launcher"
            // ENH033 - Hide launcher under the top panel
            z: panel.z - 1
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
            inverted: shell.usageScenario !== "desktop"
            superPressed: physicalKeysMapper.superPressed
            superTabPressed: physicalKeysMapper.superTabPressed
            panelWidth: units.gu(settings.launcherWidth)
            // ENH014 - Always hide launcher in lock screen
            // lockedVisible: (lockedByUser || shell.atDesktop) && lockAllowed
            lockedVisible: ((lockedByUser && !greeter.locked) || shell.atDesktop) && lockAllowed
            // ENH014 - End
            // ENH058 - Interative Blur (Focal)
            // blurSource: greeter.shown ? greeter : stages
            blurSource: shell.settings.drawerBlur ? (greeter.shown ? greeter : stages) : null
            // ENH058 - End
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
            // ENH043 - Button to toggle OSK
            GlobalShortcut { // toggle OSK
                shortcut: 0//Qt.Key_WebCam
                onTriggered: {
                    if (shell.settings.pro1_OSKToggleKey) {
                        unity8Settings.alwaysShowOsk = !unity8Settings.alwaysShowOsk
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
                        unity8Settings.alwaysShowOsk = !unity8Settings.alwaysShowOsk
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
            // ENH104 - Mouse edge push settings
            // enabled: !greeter.shown
            enabled: !greeter.shown && !shell.settings.disableRightEdgeMousePush
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

     // ENH114 - Popup holder
    Item {
        id: popupSurface

        z: itemGrabber.z - 1
        anchors.fill: parent
    }
    // ENH114 - End

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
