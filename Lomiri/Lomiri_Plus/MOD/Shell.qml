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
// ENH046 - Lomiri Plus Settings
import Qt.labs.settings 1.0
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Suru 2.2
// ENH046 - End


StyledItem {
    id: shell

    theme.name: "Ubuntu.Components.Themes.SuruDark"
    
    // ENH002 - Notch/Punch hole fix
    property alias deviceConfiguration: deviceConfiguration
    // ENH036 - Use punchole as battery indicator
    // property real shellMargin: shell.isBuiltInScreen ? deviceConfiguration.notchHeightMargin : 0
    property real shellMargin: shell.isBuiltInScreen
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
    // ENH046 - End

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

    // ENH046 - Lomiri Plus Settings
    Item {
        id: lp_settings

        property alias enableEyeFP: settingsObj.lp_enableEyeFP
        property alias useCustomLockscreen: settingsObj.useCustomLockscreen
        property alias indicatorBlur: settingsObj.indicatorBlur
        property alias drawerBlur: settingsObj.drawerBlur
        property alias drawerBlurFullyOpen: settingsObj.drawerBlurFullyOpen
        property alias invertedDrawer: settingsObj.invertedDrawer
        property alias enableSideStage: settingsObj.enableSideStage
        property alias indicatorGesture: settingsObj.indicatorGesture
        property alias orientationPrompt: settingsObj.orientationPrompt
        property alias useLomiriLogo: settingsObj.useLomiriLogo
        property alias useCustomLogo: settingsObj.useCustomLogo
        property alias useCustomBFBColor: settingsObj.useCustomBFBColor
        property alias customLogoScale: settingsObj.customLogoScale
        property alias customLogoColor: settingsObj.customLogoColor
        property alias customBFBColor: settingsObj.customBFBColor
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
        property alias alwaysHideTopPanel: settingsObj.alwaysHideTopPanel
        property alias topPanelOpacity: settingsObj.topPanelOpacity

        // Pro1-X
        property alias pro1_OSKOrientation: settingsObj.pro1_OSKOrientation
        property alias pro1_OSKToggleKey: settingsObj.pro1_OSKToggleKey
        property alias pro1_orientationToggleKey: settingsObj.pro1_orientationToggleKey

        // Non-persistent settings
        property bool enableOW: false

        Settings {
            id: settingsObj

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
            property bool useCustomLogo: false
            property bool useCustomBFBColor: false
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
        }
    }
    
    function showSettings() {
        settingsLoader.active = true
    }

    Loader {
        id: settingsLoader
        active: false
        z: inputMethod.visible ? inputMethod.z - 1 : shellBorderLoader.z + 1
        anchors {
            bottom: parent.bottom
            bottomMargin: inputMethod.visibleRect.height
            horizontalCenter: parent.horizontalCenter
        }
        width: Math.min(parent.width, units.gu(40))
        height: inputMethod.visible ? parent.height - inputMethod.visibleRect.height - panel.minimizedPanelHeight
                                    : Math.min(parent.height, units.gu(60))

        sourceComponent: Component {
            Rectangle {
                property alias stack: stack
                color: Suru.backgroundColor
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
                                icon.name:  stack.depth > 1 ? "back" : "close"
                                icon.width: units.gu(2)
                                icon.height: units.gu(2)
                                onClicked: {
                                    if (stack.depth > 1) {
                                        stack.pop()
                                    } else {
                                        settingsLoader.active = false
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

            settingsItems: [
                LPSettingsNavItem {
                    Layout.fillWidth: true
                    text: "Outer Wilds"
                    onClicked: settingsLoader.item.stack.push(outerWildsPage, {"title": text})
                }
                ,LPSettingsNavItem {
                    Layout.fillWidth: true
                    text: "Customizations"
                    onClicked: settingsLoader.item.stack.push(customizationsPage, {"title": text})
                }
                ,LPSettingsNavItem {
                    Layout.fillWidth: true
                    text: "Features"
                    onClicked: settingsLoader.item.stack.push(featuresPage, {"title": text})
                }
                ,LPSettingsNavItem {
                    Layout.fillWidth: true
                    text: "Device Configuration"
                    onClicked: settingsLoader.item.stack.push(devicePage, {"title": text})
                }
                ,LPSettingsNavItem {
                    Layout.fillWidth: true
                    text: "Device Specific Hacks"
                    onClicked: settingsLoader.item.stack.push(deviceSpecificPage, {"title": text})
                }
            ]
        }
    }
    Component {
        id: outerWildsPage
        
        LPSettingsPage {
            settingsItems: [
                QQC2.CheckDelegate {
                    id: owTheme
                    Layout.fillWidth: true
                    text: "Outer Wilds Theme"
                    onCheckedChanged: shell.settings.enableOW = checked
                    Binding {
                        target: owTheme
                        property: "checked"
                        value: shell.settings.enableOW
                    }
                }
                , QQC2.CheckDelegate {
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
            ]
        }
    }
    Component {
        id: deviceSpecificPage
        
        LPSettingsPage {
            settingsItems: [
                LPSettingsNavItem {
                    Layout.fillWidth: true
                    text: "Fxtec Pro1-X"
                    onClicked: settingsLoader.item.stack.push(pro1Page, {"title": text})
                }
            ]

            Component {
                id: pro1Page
                
                LPSettingsPage {
                    settingsItems: [
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            text: "Disables OSK when in the same orientation as the physical keyboard and enables it when in any other orientation"
                            wrapMode: Text.WordWrap
                            Suru.textLevel: Suru.Caption
                        }
                        ,QQC2.CheckDelegate {
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
                        ,QQC2.CheckDelegate {
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
                        ,QQC2.CheckDelegate {
                            id: pro1_orientationToggleKey
                            Layout.fillWidth: true
                            text: "Use Camera Key to toggle orientation"
                            onCheckedChanged: shell.settings.pro1_orientationToggleKey = checked
                            Binding {
                                target: pro1_orientationToggleKey
                                property: "checked"
                                value: shell.settings.pro1_orientationToggleKey
                            }
                        }
                    ]
                }
            }
        }
    }
    Component {
        id: customizationsPage
        
        LPSettingsPage {
            settingsItems: [
                LPSettingsNavItem {
                    Layout.fillWidth: true
                    text: "Lockscreen"
                    onClicked: settingsLoader.item.stack.push(lockscreenPage, {"title": text})
                }
                ,LPSettingsNavItem {
                    Layout.fillWidth: true
                    text: "Launcher"
                    onClicked: settingsLoader.item.stack.push(launcherPage, {"title": text})
                }
                ,LPSettingsNavItem {
                    Layout.fillWidth: true
                    text: "Top Panel"
                    onClicked: settingsLoader.item.stack.push(topPanelpage, {"title": text})
                }
                ,LPSettingsNavItem {
                    Layout.fillWidth: true
                    text: "App Drawer"
                    onClicked: settingsLoader.item.stack.push(drawerpage, {"title": text})
                }
                ,LPSettingsNavItem {
                    Layout.fillWidth: true
                    text: "App Spread"
                    onClicked: settingsLoader.item.stack.push(spreadPage, {"title": text})
                }
            ]
            Component {
                id: lockscreenPage
                
                LPSettingsPage {
                    settingsItems: [
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            text: "Custom Wallpaper Filename: ~/Pictures/lomiriplus/lockscreen"
                            wrapMode: Text.WordWrap
                            Suru.textLevel: Suru.Caption
                        }
                        ,QQC2.CheckDelegate {
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
                    ]
                }
            }
            Component {
                id: topPanelpage
                
                LPSettingsPage {
                    settingsItems: [
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
                        ,QQC2.CheckDelegate {
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
                        ,QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            text: "Top panel will always be hidden unless in the greeter or app spread"
                            wrapMode: Text.WordWrap
                            Suru.textLevel: Suru.Caption
                        }
                        ,QQC2.CheckDelegate {
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
                    ]
                }
            }
            Component {
                id: drawerpage
                
                LPSettingsPage {
                    settingsItems: [
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
                        ,QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            visible: shell.settings.drawerBlur
                            text: "Better performance while opening the drawer"
                            wrapMode: Text.WordWrap
                            Suru.textLevel: Suru.Caption
                        }
                        ,QQC2.CheckDelegate {
                            id: drawerBlurFullyOpen
                            Layout.fillWidth: true
                            visible: shell.settings.drawerBlur
                            text: "Blur only when fully open"
                            onCheckedChanged: shell.settings.drawerBlurFullyOpen = checked
                            Binding {
                                target: drawerBlurFullyOpen
                                property: "checked"
                                value: shell.settings.drawerBlurFullyOpen
                            }
                        }
                        ,QQC2.CheckDelegate {
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
                    ]
                }
            }
            Component {
                id: spreadPage
                
                LPSettingsPage {
                    settingsItems: [
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            text: "Requires Notch/Punchhole configuration and Corner Radius"
                            wrapMode: Text.WordWrap
                            Suru.textLevel: Suru.Caption
                        }
                        ,QQC2.CheckDelegate {
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
                    ]
                }
            }
            Component {
                id: launcherPage
                
                LPSettingsPage {
                    settingsItems: [
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
                        ,QQC2.TextField {
                            id: customBFBColor
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            visible: shell.settings.useCustomBFBColor
                            onTextChanged: shell.settings.customBFBColor = text
                            Binding {
                                target: customBFBColor
                                property: "text"
                                value: shell.settings.customBFBColor
                            }
                        }
                        , QQC2.CheckDelegate {
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
                        ,QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            text: "Custom Logo Filename: ~/Pictures/lomiriplus/bfb.svg"
                            wrapMode: Text.WordWrap
                            Suru.textLevel: Suru.Caption
                        }
                        ,QQC2.CheckDelegate {
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
                        ,QQC2.ItemDelegate {
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
                        ,QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            visible: customLogoColorItem.visible
                            text: "Will replace all #ffffff surfaces in the SVG"
                            Suru.textLevel: Suru.Caption
                            wrapMode: Text.WordWrap
                        }
                        ,QQC2.ItemDelegate {
                            id: customLogoColorItem
                            Layout.fillWidth: true
                            text: "Logo Color"
                            visible: shell.settings.useCustomLogo
                            indicator: QQC2.TextField {
                                id: customLogoColor
                                anchors {
                                    right: parent.right
                                    rightMargin: units.gu(2)
                                    verticalCenter: parent.verticalCenter
                                }
                                onTextChanged: shell.settings.customLogoColor = text
                                Binding {
                                    target: customLogoColor
                                    property: "text"
                                    value: shell.settings.customLogoColor
                                }
                            }
                        }
                    ]
                }
            }
        }
    }
    Component {
        id: featuresPage
        
        LPSettingsPage {
            settingsItems: [
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
                ,QQC2.Label {
                    Layout.fillWidth: true
                    Layout.margins: units.gu(2)
                    text: "Swipe from the very bottom of left/right edge to open the application menu/indicator panel"
                    wrapMode: Text.WordWrap
                    Suru.textLevel: Suru.Caption
                }
                ,QQC2.CheckDelegate {
                    id: indicatorGesture
                    Layout.fillWidth: true
                    text: "Bottom Side Gestures"
                    onCheckedChanged: shell.settings.indicatorGesture = checked
                    Binding {
                        target: indicatorGesture
                        property: "checked"
                        value: shell.settings.indicatorGesture
                    }
                }
                ,QQC2.CheckDelegate {
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
                ,QQC2.Label {
                    Layout.fillWidth: true
                    Layout.margins: units.gu(2)
                    text: "Requires: Right punchholes, Notch Side Margin, Exact Punchhole Width, Punchhole Height From Top"
                    wrapMode: Text.WordWrap
                    Suru.textLevel: Suru.Caption
                }
                ,QQC2.CheckDelegate {
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
            ]
        }
    }
    Component {
        id: devicePage
        
        LPSettingsPage {
            settingsItems: [
                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.margins: units.gu(2)
                    text: "Most configuration only takes effect when your device doesn't have pre-configuration"
                    wrapMode: Text.WordWrap
                }
                , Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: units.dp(1)
                    color: Suru.neutralColor
                }
                ,LPSettingsNavItem {
                    Layout.fillWidth: true
                    text: "Notch / Punchhole"
                    onClicked: settingsLoader.item.stack.push(notchpage, {"title": text})
                }
                ,LPSettingsNavItem {
                    Layout.fillWidth: true
                    text: "Punchhole Battery (Experimental)"
                    onClicked: settingsLoader.item.stack.push(punchPage, {"title": text})
                }
                ,LPSettingsNavItem {
                    Layout.fillWidth: true
                    text: "Rounded Corners"
                    onClicked: settingsLoader.item.stack.push(cornerPage, {"title": text})
                }
            ]
            Component {
                id: notchpage
                
                LPSettingsPage {
                    settingsItems: [
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
                        ,QQC2.CheckDelegate {
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
                        ,QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            verticalAlignment: QQC2.Label.AlignVCenter
                            visible: notchPositionItem.notchEnabled
                            text: "Notch Top Margin"
                        }
                        ,QQC2.SpinBox {
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
                        , Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: units.dp(1)
                            color: Suru.neutralColor
                            visible: notchPositionItem.notchEnabled
                        }
                        ,QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            verticalAlignment: QQC2.Label.AlignVCenter
                            visible: notchPositionItem.notchEnabled
                            text: "Notch Side Margin"
                        }
                        ,QQC2.SpinBox {
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
                    ]
                }
            }
            Component {
                id: punchPage
                
                LPSettingsPage {
                    settingsItems: [
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            verticalAlignment: QQC2.Label.AlignVCenter
                            text: "Exact Punchhole Width"
                        }
                        ,QQC2.SpinBox {
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
                        , Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: units.dp(1)
                            color: Suru.neutralColor
                        }
                        ,QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            verticalAlignment: QQC2.Label.AlignVCenter
                            text: "Punchhole Height From Top"
                        }
                        ,QQC2.SpinBox {
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
                        , Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: units.dp(1)
                            color: Suru.neutralColor
                        }
                    ]
                }
            }
            Component {
                id: cornerPage
                
                LPSettingsPage {
                    settingsItems: [
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            text: "Only necessary or has effects when a notch/punchhole is configured"
                            wrapMode: Text.WordWrap
                            Suru.textLevel: Suru.Caption
                        }
                        ,QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            verticalAlignment: QQC2.Label.AlignVCenter
                            text: "Corner Radius"
                        }
                        ,QQC2.SpinBox {
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
                        , Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: units.dp(1)
                            color: Suru.neutralColor
                        }
                        ,QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: units.gu(2)
                            verticalAlignment: QQC2.Label.AlignVCenter
                            text: "Corner Margin"
                        }
                        ,QQC2.SpinBox {
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
                    ]
                }
            }
        }
    }
    // ENH046 - End
    
    // ENH002 - Notch/Punch hole fix
    DeviceConfiguration {
        id: deviceConfiguration
        name: applicationArguments.deviceName
    }

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
        anchors.topMargin: panel.fullscreenMode || shell.settings.alwaysHideTopPanel ? shell.shellTopMargin 
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
        active: shell.settings.indicatorGesture
        asynchronous: true
        height: (Screen.pixelDensity * 25.4) * 0.5 // 0.5 inch
        width: shell.edgeSize
        z: greeter.fullyShown ? greeter.z + 1 : overlay.z - 1
        anchors {
            right: parent.right
            bottom: parent.bottom
        }

        sourceComponent: SwipeArea {
            id: indicatorsBottomSwipe
            
            // draggingCustom is used for implementing trigger delay
            property bool draggingCustom: distance >= units.gu(4) 
            
            signal triggered
            enabled: !shell.immersiveMode
            direction: SwipeArea.Leftwards
            immediateRecognition: true
            
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
    }
    
    Loader {
        active: shell.settings.indicatorGesture
        asynchronous: true
        height: (Screen.pixelDensity * 25.4) * 0.5 // 0.5 inch
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
            // ENH030 - Blurred indicator panel
            blurSource: greeter.shown ? greeter : stages
            // ENH046 - Lomiri Plus Settings
            //interactiveBlur: shell.interactiveBlur
            interactiveBlur: shell.settings.indicatorBlur
            // ENH046 - End
            leftMarginBlur: !greeter.shown ? overlay.anchors.leftMargin : 0
            topMarginBlur: !greeter.shown ? overlay.anchors.topMargin : 0
            // ENH030 - End
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
            forceHidePanel: shell.settings.alwaysHideTopPanel && ((!LightDMService.greeter.active && !stage.spreadShown && stage.rightEdgeDragProgress == 0 && stage.rightEdgePushProgress == 0)
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
            // ENH043 - Button to toggle OSK
            GlobalShortcut { // toggle OSK
                enabled: shell.settings.pro1_OSKToggleKey
                shortcut: 0//Qt.Key_WebCam
                onTriggered: unity8Settings.alwaysShowOsk = !unity8Settings.alwaysShowOsk
            }
            // ENH043 - End

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
