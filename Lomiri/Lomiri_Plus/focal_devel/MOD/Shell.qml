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

import QtQuick 2.12
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
import Ubuntu.Components.Pickers 1.3
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
// ENH116 - End


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
    }
    // ENH133 - End

    theme.name: "Lomiri.Components.Themes.SuruDark"

    // ENH002 - Notch/Punch hole fix
    property alias deviceConfiguration: deviceConfiguration
    // ENH036 - Use punchole as battery indicator
    //property real shellMargin: shell.isBuiltInScreen ? deviceConfiguration.notchHeightMargin : 0
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
    // ENH136 - Separate desktop mode per screen
    readonly property bool haveMultipleScreens: Screens.count > 1 && shell.settings && shell.settings.externalDisplayBehavior == 1
    property bool isDesktopMode: false
    // ENH136 - End
    // ENH037 - Manual screen rotation button
    readonly property bool isFullScreen: panel.focusedSurfaceIsFullscreen
    // ENH037 - End
    
    // ENH046 - Lomiri Plus Settings
    property alias settings: lp_settings
    property alias lpsettingsLoader: settingsLoader
    Suru.theme: Suru.Dark
    // ENH046 - End
    // ENH116 - Standalone Dark mode toggle
    property alias themeSettings: themeSettings
    // ENH116 - End
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
    readonly property bool hideTopPanel: isBuiltInScreen && shell.settings.alwaysHideTopPanel
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

    readonly property var topLevelSurfaceList: {
        if (!WMScreen.currentWorkspace) return null;
        return stage.temporarySelectedWorkspace ? stage.temporarySelectedWorkspace.windowModel : WMScreen.currentWorkspace.windowModel
    }

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
    ]
    // ENH028 - End
    // ENH133 - Hot corners
    readonly property var hotcornersIndicatorsModel: {
        return [{ "identifier": "last-opened-indicator", "name": "Last Opened", "icon": "system-devices-panel", "indicatorIndex": -1 }].concat(shell.indicatorsModel)
    }
    // ENH133 - End
    // ENH139 - System Direct Actions
    property alias appModel: launcher.appModel

    function getAppData(_appId) {
        for (var i = 0; i < appModel.rowCount(); ++i) {
            let _modelIndex = appModel.index(i, 0)
            let _currentAppId = appModel.data(_modelIndex, 0)

            if (_currentAppId == _appId) {
                let _currentAppName = appModel.data(_modelIndex, 1)
                let _currentAppIcon = appModel.data(_modelIndex, 2)

                return {"name": _currentAppName, "icon": _currentAppIcon }
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

    function openIndicatorByIndex(index) {
        panel.indicators.openAsInverted(index)
    }

    // Custom actions
    readonly property var customDirectActions: [
        lockScreenAction, lomiriPlusAction, powerDialogAction, screenshotAction, rotateAction, appScreenshotAction
        , closeAppAction, showDesktopAction, appSuspensionAction
    ]
    Action {
        id: lockScreenAction
        name: "lockscreen"
        text: "Lock screen"
        iconName: "lock"
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
        enabled: stage.focusedAppId ? true : false
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
        enabled: stage.focusedAppId ? true : false
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
        id: lomiriPlusAction
        name: "lomiriplus"
        text: "LomiriPlus Settings"
        iconName: "properties"
        onTriggered: showSettings()
    }
    // ENH139 - End

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

    Item {
        id: themeSettings
 
        readonly property string defaultPath: "/home/phablet/.config/lomiri-ui-toolkit/theme.ini"
        readonly property bool isDarkMode: currentTheme == "Lomiri.Components.Themes.SuruDark"
        property string currentTheme: "Lomiri.Components.Themes.Ambiance"

        function checkAutoToggle() {
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
                if (!isDarkMode) {
                    setToDark()
                }
            } else {
                if (isDarkMode) {
                    setToAmbiance()
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
                themeSettings.checkAutoToggle()
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
            case "indicator-transfer":
                return "Transfer/Files"
                break
            case "indicator-location":
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
        property alias externalDisplayBehavior: settingsObj.externalDisplayBehavior
        property alias enablePullDownGesture: settingsObj.enablePullDownGesture
        property alias pullDownHeight: settingsObj.pullDownHeight
        property alias enableColorOverlay: settingsObj.enableColorOverlay
        property alias overlayColor: settingsObj.overlayColor
        property alias colorOverlayOpacity: settingsObj.colorOverlayOpacity
        property alias enableShowDesktop: settingsObj.enableShowDesktop
        property alias enableCustomBlurRadius: settingsObj.enableCustomBlurRadius
        property alias customBlurRadius: settingsObj.customBlurRadius

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
        property alias enableDrawerBottomSwipe: settingsObj.enableDrawerBottomSwipe
        property alias resetAppDrawerWhenClosed: settingsObj.resetAppDrawerWhenClosed
        property alias enableDirectAppInLauncher: settingsObj.enableDirectAppInLauncher
        property alias fasterFlickDrawer: settingsObj.fasterFlickDrawer
        property alias dimWhenLauncherShow: settingsObj.dimWhenLauncherShow
        property alias drawerIconSizeMultiplier: settingsObj.drawerIconSizeMultiplier
        property alias showLauncherAtDesktop: settingsObj.showLauncherAtDesktop

        // Drawer Dock
        property alias enableDrawerDock: settingsObj.enableDrawerDock
        property alias drawerDockType: settingsObj.drawerDockType
        property alias drawerDockApps: settingsObj.drawerDockApps
        property alias drawerDockHideLabels: settingsObj.drawerDockHideLabels
        
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
        property alias enableAutoDarkMode: settingsObj.enableAutoDarkMode
        property alias enableAutoDarkModeToggleIndicator: settingsObj.enableAutoDarkModeToggleIndicator
        property alias immediateDarkModeSwitch: settingsObj.immediateDarkModeSwitch
        property alias autoDarkModeStartTime: settingsObj.autoDarkModeStartTime
        property alias autoDarkModeEndTime: settingsObj.autoDarkModeEndTime
        property alias onlyShowNotificationsIndicatorWhenGreen: settingsObj.onlyShowNotificationsIndicatorWhenGreen
        property alias onlyShowSoundIndicatorWhenSilent: settingsObj.onlyShowSoundIndicatorWhenSilent
        property alias hideTimeIndicatorAlarmIcon: settingsObj.hideTimeIndicatorAlarmIcon
        property alias transparentTopBarOnSpread: settingsObj.transparentTopBarOnSpread
        property alias enablePanelHeaderExpand: settingsObj.enablePanelHeaderExpand

        //Quick Toggles
        property alias enableQuickToggles: settingsObj.enableQuickToggles
        property alias quickToggles: settingsObj.quickToggles
        property alias gestureMediaControls: settingsObj.gestureMediaControls
        property alias autoCollapseQuickToggles: settingsObj.autoCollapseQuickToggles
        property alias quickTogglesCollapsedRowCount: settingsObj.quickTogglesCollapsedRowCount

        // Direct Actions
        property alias enableDirectActions: settingsObj.enableDirectActions
        property alias directActionList: settingsObj.directActionList
        property alias directActionsSwipeAreaHeight: settingsObj.directActionsSwipeAreaHeight
        property alias directActionsMaxWidth: settingsObj.directActionsMaxWidth
        property alias directActionsMaxColumn: settingsObj.directActionsMaxColumn
        property alias directActionsSideMargins: settingsObj.directActionsSideMargins
        property alias directActionsEnableHint: settingsObj.directActionsEnableHint

        // Lockscreen
        property alias useCustomLockscreen: settingsObj.useCustomLockscreen
        property alias useCustomCoverPage: settingsObj.useCustomCoverPage
        property alias hideLockscreenClock: settingsObj.hideLockscreenClock
        property alias useCustomLSClockColor: settingsObj.useCustomLSClockColor
        property alias customLSClockColor: settingsObj.customLSClockColor
        property alias useCustomLSClockFont: settingsObj.useCustomLSClockFont
        property alias customLSClockFont: settingsObj.customLSClockFont
        property alias useCustomInfographicCircleColor: settingsObj.useCustomInfographicCircleColor
        property alias customInfographicsCircleColor: settingsObj.customInfographicsCircleColor
        property alias useCustomDotsColor: settingsObj.useCustomDotsColor
        property alias customDotsColor: settingsObj.customDotsColor

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
        property alias ow_GradientColoredDate: settingsObj.ow_GradientColoredDate
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
        property alias dcBlurredAlbumArt: settingsObj.dcBlurredAlbumArt
        property alias dcCDPlayerSimpleMode: settingsObj.dcCDPlayerSimpleMode
        property alias dcCDPlayerOpacity: settingsObj.dcCDPlayerOpacity

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

        // Stopwatch Data
        property alias dcStopwatchTimeMS: settingsObj.dcStopwatchTimeMS
        property alias dcStopwatchLastEpoch: settingsObj.dcStopwatchLastEpoch

        // Timer Data
        property alias dcRunningTimer: settingsObj.dcRunningTimer
        property alias dcLastTimeTimer: settingsObj.dcLastTimeTimer

        // Non-persistent settings
        property bool enableOW: false
        property bool showInfographics: true
        property bool immersiveMode: false

        Settings {
            id: settingsObj

            // ENH061 - Add haptics
            // ENH056 - Quick toggles
            //Component.onCompleted: shell.haptics.enabled = Qt.binding( function() { return enableHaptics } )
            Component.onCompleted: {
                shell.haptics.enabled = Qt.binding( function() { return enableHaptics } )

                // Add new Quick Toggles in don't exists yet
                let _newItems = [17, 18, 19]
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
        active: false
        z: inputMethod.visible ? inputMethod.z - 1 : cursor.z - 2
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
        }
    }
    Component {
        id: appearancePage
        
        LPSettingsPage {
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
            LPSettingsSwitch {
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
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Displays a button at the bottom right when rotating the screen while auto-rotation is disabled"
                wrapMode: Text.WordWrap
                font.italic: true
                textSize: Label.Small
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Abot Kamay"
                onClicked: settingsLoader.item.stack.push(pullDownPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Color Overlay"
                onClicked: settingsLoader.item.stack.push(colorOverlayPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Direct Actions"
                onClicked: settingsLoader.item.stack.push(directActionsPage, {"title": text})
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
                    i18n.tr("Virtual Touchpad"),
                    i18n.tr("Multi-display")
                    // i18n.tr("Mirrored")
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
        }
    }
    Component {
        id: mousePage
        
        LPSettingsPage {
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
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Hot Corners"
                onClicked: settingsLoader.item.stack.push(hotcornersPage, {"title": text})
            }
        }
    }
    Component {
        id: keyShortcutsPage
        
        LPSettingsPage {
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

            Component {
                id: pro1Page
                
                LPSettingsPage {
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
                    LPSettingsSwitch {
                        id: useCustomLSClockColor
                        Layout.fillWidth: true
                        text: "Custom color"
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
                    LPSettingsCheckBox {
                        id: transparentTopBarOnSpread
                        Layout.fillWidth: true
                        text: "Transparent when in App Spread"
                        onCheckedChanged: shell.settings.transparentTopBarOnSpread = checked
                        Binding {
                            target: transparentTopBarOnSpread
                            property: "checked"
                            value: shell.settings.transparentTopBarOnSpread
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
                        text: "Requires: Right punchholes, Notch Side Margin, Exact Punchhole Width, Punchhole Height From Top"
                        wrapMode: Text.WordWrap
                        font.italic: true
                        textSize: Label.Small
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
                        text: "Swipe up from the bottom or type something with a physical keyboard to search"
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
                id: bfbPage
                
                LPSettingsPage {
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
                    LPSettingsSlider {
                        id: logScale
                        Layout.fillWidth: true
                        Layout.margins: units.gu(2)
                        visible: shell.settings.useCustomLogo
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
                        visible: shell.settings.useCustomLogo
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
            LPSettingsSwitch {
                id: enableColorOverlay
                Layout.fillWidth: true
                text: "Enable"
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
                visible: shell.settings.enableColorOverlay
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
                visible: shell.settings.enableColorOverlay
                title: "Opacity"
                minimumValue: 0.05
                maximumValue: 0.6
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
                text: "Enable"
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
                + "Integrated Dock:\n"
                + " - Displayed at the top of the app drawer or at the bottom when it's inverted\n"
                + ' - Works more like a "Favorites" section than a usual dock\n'
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
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enableDrawerDock
                text: i18n.tr("Dock type")
                model: [
                    i18n.tr("Bottom Dock"),
                    i18n.tr("Integrated Dock")
                ]
                containerHeight: itemHeight * 6
                selectedIndex: shell.settings.drawerDockType
                onSelectedIndexChanged: shell.settings.drawerDockType = selectedIndex
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
            ]
            Component {
                id: selectorDelegate
                OptionSelectorDelegate { text: modelData.name }
            }
            LPSettingsSwitch {
                id: enableTopLeftHotCorner
                Layout.fillWidth: true
                text: i18n.tr("Top Left")
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
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Swipe down from the upper half of the leftmost or rightmost edge to pull down the shell to a more reachable state."
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
                onCheckedChanged: shell.settings.enablePullDownGesture = checked
                Binding {
                    target: enablePullDownGesture
                    property: "checked"
                    value: shell.settings.enablePullDownGesture
                }
            }
            LPSettingsSlider {
                id: pullDownHeight
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: shell.settings.enablePullDownGesture
                title: "Target Height"
                minimumValue: 2
                maximumValue: 5
                stepSize: 0.25
                resetValue: 3
                live: true
                percentageValue: false
                valueIsPercentage: false
                roundValue: true
                unitsLabel: "inch"
                onValueChanged: shell.settings.pullDownHeight = value
                Binding {
                    target: pullDownHeight
                    property: "value"
                    value: shell.settings.pullDownHeight
                }
            }
        }
    }
    Component {
        id: directActionsPage
        
        LPSettingsPage {
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                text: "Swipe from the very bottom of left/right edge to open a floating menu that contains customizable actions\n"
                + "Lifting the swipe will trigger the currently selected action"
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
                onCheckedChanged: shell.settings.enableDirectActions = checked
                Binding {
                    target: enableDirectActions
                    property: "checked"
                    value: shell.settings.enableDirectActions
                }
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Actions List"
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
                + " • Custom: Custom actions that performs specific actions"
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

                text: "Add Action"
                color: theme.palette.normal.positive
                onClicked: PopupUtils.open(addDirectActionDialog)
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
                                    shell.settings.directActionList = _arrNewValues
                                }
                            }
                        ]
                    }
                }

                Component {
                    id: addDirectActionDialog
                    Dialog {
                        id: dialogue

                        property string actionId: {
                            if (actionType == LPDirectActions.Type.App) {
                                let _modelIndex = shell.appModel.index(actionIdSelector.selectedIndex, 0)
                                let _appId = shell.appModel.data(_modelIndex, 0)
                                return _appId ? _appId : ""
                            }

                            let _selectedItem = actionIdSelector.model[actionIdSelector.selectedIndex]
                            if (actionType == LPDirectActions.Type.Custom) {
                                return _selectedItem && _selectedItem.name ? _selectedItem.name : ""
                            }

                            return _selectedItem && _selectedItem.identifier ? _selectedItem.identifier : ""
                        }
                        property int actionType: actionTypeSelector.model[actionTypeSelector.selectedIndex].value

                        OptionSelector {
                             id: actionTypeSelector

                            text: i18n.tr("Action Type")
                            model: [
                                { "name": "Indicator", "value": LPDirectActions.Type.Indicator },
                                { "name": "App", "value": LPDirectActions.Type.App },
                                { "name": "Settings", "value": LPDirectActions.Type.Settings },
                                { "name": "Toggle", "value": LPDirectActions.Type.Toggle },
                                { "name": "Custom", "value": LPDirectActions.Type.Custom },
                            ]
                            containerHeight: itemHeight * 6
                            selectedIndex: LPDirectActions.Type.Indicator
                            delegate: selectorDelegate
                        }
                        Component {
                            id: selectorDelegate
                            OptionSelectorDelegate { text: modelData.name }
                        }
                         OptionSelector {
                             id: actionIdSelector

                            text: i18n.tr("Action")
                            model: {
                                let _model

                                switch(dialogue.actionType) {
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

                                    return _model
                                }
                            }
                            containerHeight: itemHeight * 6
                            selectedIndex: 0
                            delegate: actionSselectorDelegate
                        }
                        Component {
                            id: actionSselectorDelegate
                            OptionSelectorDelegate {
                                text: {
                                    switch(dialogue.actionType) {
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
                                        default:
                                            return "unknown"
                                    }
                                }
                            }
                        }
                        Button {
                             text: "Add"
                             color: theme.palette.normal.positive
                             onClicked: {
                                 let _arrNewValues = shell.settings.directActionList.slice()
                                let _properties = { actionId: dialogue.actionId, type: dialogue.actionType }
                                _arrNewValues.push(_properties)
                                shell.settings.directActionList = _arrNewValues
                                PopupUtils.close(dialogue)
                             }
                         }
                         Button {
                             text: "Cancel"
                             onClicked: PopupUtils.close(dialogue)
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
            LPSettingsCheckBox {
                id: dcCDPlayerSimpleMode
                Layout.fillWidth: true
                text: "Simple Mode CD Player"
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
                text: "Blurred album art"
                visible: shell.settings.enableDynamicCove
                onCheckedChanged: shell.settings.dcBlurredAlbumArt = checked
                Binding {
                    target: dcBlurredAlbumArt
                    property: "checked"
                    value: shell.settings.dcBlurredAlbumArt
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
            LPSettingsSwitch {
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
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: units.gu(4)
                Layout.rightMargin: units.gu(2)
                Layout.bottomMargin: units.gu(2)
                text: "Press and hold to toggle disco mode"
                wrapMode: Text.WordWrap
                visible: enableCDPlayerDiscoCheck.visible
                font.italic: true
                textSize: Label.Small
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

        fileName: "/home/phablet/.config/clock.ubports/clock.ubports.conf"
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
        blackSpaceColor: LomiriColors.silk
        borderColor: {
            if (charging) {
                return theme.palette.normal.positive
            } else {
                switch (true) {
                    case progress <= 25:
                        return theme.palette.normal.negative
                        break
                    case progress <= 50:
                        return LomiriColors.orange
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
                duration: LomiriAnimation.BriskDuration
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

            dragAreaWidth: shell.edgeSize
            background: wallpaperResolver.background
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
            panelState: panelState

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

    // ENH139 - System Direct Actions
    Loader {
        active: shell.settings.enableDirectActions
        asynchronous: true
        anchors.fill: parent
        z: settingsLoader.z + 1
        sourceComponent: LPDirectActions {
            enabled: !shell.immersiveMode
            swipeAreaHeight: shell.convertFromInch(shell.settings.directActionsSwipeAreaHeight)
            swipeAreaWidth: shell.edgeSize
            maximumWidth: shell.convertFromInch(shell.settings.directActionsMaxWidth)
            sideMargins: shell.convertFromInch(shell.settings.directActionsSideMargins)
            maximumColumn: shell.settings.directActionsMaxColumn
            enableVisualHint: shell.settings.directActionsEnableHint
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
            // ENH116 - Standalone Dark mode toggle
            if (shell.settings.enableAutoDarkMode) {
                if (Powerd.status == Powerd.On) {
                    shell.themeSettings.checkAutoToggle()
                }
            }
            // ENH116 - End
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
            // ENH030 - Blurred indicator panel
            // blurSource: settings.enableBlur ? (greeter.shown ? greeter : stages) : null
            blurSource: settings.enableBlur && shell.settings.indicatorBlur ? (greeter.shown ? greeter : stages) : null
            // ENH030 - End

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
            batteryCircleEnabled : batteryCircle.visible
            batteryCircleBorder: batteryCircle.borderWidth
            // ENH036 - End
            // ENH122 - Option to transparent top bar when in spread
            transparentTopBar: shell.settings.transparentTopBarOnSpread
                                    && (stage.spreadShown || stage.rightEdgeDragProgress > 0 || stage.rightEdgePushProgress > 0)
            topBarOpacityOverride: stage.spreadShown ? 0 : 1 - (stage.rightEdgeDragProgress * 2)
            // ENH122 - End
            // ENH046 - Lomiri Plus Settings
            topPanelMargin: shell.isBuiltInScreen && deviceConfiguration.withNotch && shell.orientation == 1 && ! deviceConfiguration.fullyHideNotchInPortrait
                                        ? shell.shellMargin : 0
            // ENH046 - End

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
            inverted: shell.usageScenario !== "desktop"
            superPressed: physicalKeysMapper.superPressed
            superTabPressed: physicalKeysMapper.superTabPressed
            panelWidth: units.gu(settings.launcherWidth)
            // ENH014 - Always hide launcher in lock screen
            // lockedVisible: (lockedByUser || shell.atDesktop) && lockAllowed
            // ENH134 - Option to hide Launcher in desktop
            //lockedVisible: ((lockedByUser && !greeter.locked) || shell.atDesktop) && lockAllowed
            lockedVisible: ((lockedByUser && !greeter.locked) || (shell.atDesktop && shell.settings.showLauncherAtDesktop)) && lockAllowed
            // ENH134 - End
            // ENH014 - End
            // ENH002 - Notch/Punch hole fix
            leftMarginBlur: overlay.anchors.leftMargin
            topMarginBlur: overlay.anchors.topMargin
            // ENH002 - End
            // ENH106 - Separate drawer blur settings
            // blurSource: settings.enableBlur ? (greeter.shown ? greeter : stages) : null
            blurSource: settings.enableBlur && shell.settings.drawerBlur ? (greeter.shown ? greeter : stages) : null
            // ENH106 - End
            topPanelHeight: panel.panelHeight
            drawerEnabled: !greeter.active && tutorial.launcherLongSwipeEnabled
            privateMode: greeter.active
            background: wallpaperResolver.background

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
                if (!active) {
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
            background: wallpaperResolver.background
            privacyMode: greeter.locked && AccountsService.hideNotificationContentWhileLocked

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

        function triggerHotCorner(__actionType, __action) {

            switch (__actionType) {
                case Shell.HotCorner.Drawer:
                    launcher.toggleDrawer(false, false, true)
                    break
                case Shell.HotCorner.SearchDrawer:
                    launcher.toggleDrawer(true, false, true)
                    break
                case Shell.HotCorner.ToggleDesktop:
                    stage.showDesktop()
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
                            actionType == Shell.HotCorner.Indicator
                        )
            edge: LPHotCorner.Edge.TopLeft
            enableVisualFeedback: shell.settings.enableHotCornersVisualFeedback
            onTrigger: overlay.triggerHotCorner(actionType, actionValue)
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
                            actionType == Shell.HotCorner.Indicator
                        )
            edge: LPHotCorner.Edge.TopRight
            enableVisualFeedback: shell.settings.enableHotCornersVisualFeedback
            onTrigger: overlay.triggerHotCorner(actionType, actionValue)
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
                            actionType == Shell.HotCorner.Indicator
                        )
            edge: LPHotCorner.Edge.BottomRight
            enableVisualFeedback: shell.settings.enableHotCornersVisualFeedback
            onTrigger: overlay.triggerHotCorner(actionType, actionValue)
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
                            actionType == Shell.HotCorner.Indicator
                        )
            edge: LPHotCorner.Edge.BottomLeft
            enableVisualFeedback: shell.settings.enableHotCornersVisualFeedback
            onTrigger: overlay.triggerHotCorner(actionType, actionValue)
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

        z: itemGrabber.z + 1
        topBoundaryOffset: panel.panelHeight
        enabled: shell.hasMouse && screenWindow.active
        visible: enabled

        property bool mouseNeverMoved: true
        Binding {
            target: cursor; property: "x"; value: shell.width / 2
            when: cursor.mouseNeverMoved && cursor.visible
        }
        Binding {
            target: cursor; property: "y"; value: shell.height / 2
            when: cursor.mouseNeverMoved && cursor.visible
        }

        confiningItem: stage.itemConfiningMouseCursor

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
}
