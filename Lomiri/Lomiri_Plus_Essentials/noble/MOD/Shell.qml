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


StyledItem {
    id: shell

    readonly property bool lightMode: settings.lightMode
    theme.name: lightMode ? "Lomiri.Components.Themes.Ambiance" :
                            "Lomiri.Components.Themes.SuruDark"

    // ENH002 - Notch/Punch hole fix
    property alias deviceConfiguration: deviceConfiguration
    property real shellMargin: shell.isBuiltInScreen && shell.deviceConfiguration.withNotch
                            ? deviceConfiguration.notchHeightMargin : 0
    property real shellLeftMargin: orientation == 8 ? shellMargin : 0
    property real shellRightMargin: orientation == 2 ? shellMargin : 0
    property real shellBottomMargin: orientation == 4 ? shellMargin : 0
    property real shellTopMargin: orientation == 1 ? shellMargin : 0
    
    readonly property bool isBuiltInScreen: Screen.name == Qt.application.screens[0].name
    // ENH002 - End
    // ENH046 - Lomiri Plus Settings
    property alias settings: lp_settings
    property alias lpsettingsLoader: settingsLoader
    Suru.theme: Suru.Dark
    // ENH046 - End
    // ENH095 - Middle notch support
    readonly property bool adjustForMiddleNotch: shell.isBuiltInScreen && shell.orientation == 1
                                                    && shell.deviceConfiguration.notchPosition == "middle" && !shell.deviceConfiguration.fullyHideNotchInPortrait
                                                        && shell.deviceConfiguration.notchHeightMargin > 0 && shell.deviceConfiguration.notchWidthMargin > 0
    // ENH095 - End
    // ENH037 - Manual screen rotation button
    readonly property bool isFullScreen: panel.focusedSurfaceIsFullscreen
    // ENH037 - End

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
    // ENH046 - Lomiri Plus Settings
    onShowingGreeterChanged: {
        if (!showingGreeter && !shell.settings.welcomeDialogShown) {
            welcomeDelayTimer.restart()
        }
    }
    Timer {
        id: welcomeDelayTimer
        interval: 1000
        onTriggered: {
            const _dialog = welcomeDialogComponent.createObject(shell);
            _dialog.show()
        }
    }
    Component {
        id: welcomeDialogComponent

        Dialog {
            id: dialog

            property bool reparentToRootItem: false

            title: "Welcome to Lomiri Plus Essentials!"
            
            signal close
            onClose: {
                shell.settings.welcomeDialogShown = true;
                PopupUtils.close(dialog)
            }

            Label {
                text: "To access the Settings page, go to the System indicator.\n\n\n\
Lomiri Plus Essentials is a collection of Kugi's personal tweaks and hacks in Lomiri.\
This is a very minimal version of Lomiri Plus. Its main goal is to provide temporary solutions for crucial issues such as notch/punchhole support, \
at least until we get official and proper support for these things.\n\
\n\n\n Enjoy!"
                wrapMode: Text.WordWrap
                color: theme.palette.normal.foregroundText
            }

            Button {
                text: "Open settings"
                color: theme.palette.normal.positive
                onClicked: {
                    shell.showSettings()
                    dialog.close()
                }
            }
            Button {
                text: "Donate"
                color: theme.palette.normal.negative
                onClicked: {
                    Qt.openUrlExternally("https://youtu.be/dQw4w9WgXcQ?si=flAd1M0i9Rvj-TFL")
                    dialog.close()
                }
            }
            Button {
                text: "Leave me alone!"
                color: theme.palette.normal.foreground
                onClicked: dialog.close()
            }
        }
    }
    // ENH046 - End

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
        property alias enableSideStage: settingsObj.enableSideStage
        property alias orientationPrompt: settingsObj.orientationPrompt
        property alias alwaysHiddenIndicatorIcons: settingsObj.alwaysHiddenIndicatorIcons
        property alias alwaysShownIndicatorIcons: settingsObj.alwaysShownIndicatorIcons
        property alias onlyShowNotificationsIndicatorWhenGreen: settingsObj.onlyShowNotificationsIndicatorWhenGreen
        property alias onlyShowSoundIndicatorWhenSilent: settingsObj.onlyShowSoundIndicatorWhenSilent
        property alias welcomeDialogShown: settingsObj.welcomeDialogShown

        // Device Config
        property alias fullyHideNotchInNative: settingsObj.fullyHideNotchInNative
        property alias notchHeightMargin: settingsObj.notchHeightMargin
        property alias notchPosition: settingsObj.notchPosition
        property alias notchWidthMargin: settingsObj.notchWidthMargin
        property alias roundedCornerRadius: settingsObj.roundedCornerRadius
        property alias roundedCornerMargin: settingsObj.roundedCornerMargin
        property alias roundedAppPreview: settingsObj.roundedAppPreview
        property alias punchHoleWidth: settingsObj.punchHoleWidth
        property alias punchHoleHeightFromTop: settingsObj.punchHoleHeightFromTop
        property alias showMiddleNotchHint: settingsObj.showMiddleNotchHint
        property alias hideTimeIndicatorAlarmIcon: settingsObj.hideTimeIndicatorAlarmIcon
        property alias hideBatteryIndicatorBracket: settingsObj.hideBatteryIndicatorBracket
        property alias hideBatteryIndicatorPercentage: settingsObj.hideBatteryIndicatorPercentage
        property alias hideBatteryIndicatorIcon: settingsObj.hideBatteryIndicatorIcon

        Settings {
            id: settingsObj

            category: "lomiriplus"
            property bool enableSideStage: false
            property bool orientationPrompt: false
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
            property real punchHoleWidth: 0
            property real punchHoleHeightFromTop: 0
            property bool showMiddleNotchHint: false
            property var alwaysHiddenIndicatorIcons: []
            property var alwaysShownIndicatorIcons: []
            property bool onlyShowNotificationsIndicatorWhenGreen: false
            property bool onlyShowSoundIndicatorWhenSilent: false
            property bool hideTimeIndicatorAlarmIcon: false
            property bool hideBatteryIndicatorBracket: false
            property bool hideBatteryIndicatorPercentage: false
            property bool hideBatteryIndicatorIcon: false
            property bool welcomeDialogShown: false
        }
    }

    function showSettings() {
        settingsLoader.active = true
    }

    Loader {
        id: settingsLoader
        active: false
        z: inputMethod.visible ? inputMethod.z - 1 : cursor.z - 2
        width: Math.min(parent.width, units.gu(40))
        height: inputMethod.visible ? parent.height - inputMethod.visibleRect.height - panel.minimizedPanelHeight
                                    : Math.min(parent.height, units.gu(60))

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

            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Accessibility"
                onClicked: settingsLoader.item.stack.push(accessibilityPage, {"title": text})
            }
            LPSettingsNavItem {
                Layout.fillWidth: true
                text: "Device Configuration"
                onClicked: settingsLoader.item.stack.push(devicePage, {"title": text})
            }
        }
    }

    Component {
        id: accessibilityPage
        
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
                text: "Top Bar"
                onClicked: settingsLoader.item.stack.push(topBarPage, {"title": text})
            }

            Component {
                id: topBarPage
                
                LPSettingsPage {
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Always Hidden Top Bar Icons"
                        onClicked: settingsLoader.item.stack.push(alwaysHiddenIconsPage, {"title": text})
                    }
                    LPSettingsNavItem {
                        Layout.fillWidth: true
                        text: "Always Shown Top Bar Icons"
                        onClicked: settingsLoader.item.stack.push(alwaysShownIconsPage, {"title": text})
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
                        text: "Date and Time"
                        wrapMode: Text.WordWrap
                        textSize: Label.Large
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
    // ENH002 - Notch/Punch hole fix
    DeviceConfiguration {
        id: deviceConfiguration
        //name: applicationArguments.deviceName // Removed in focal since it causes an error
        // ENH046 - Lomiri Plus Settings
        shell: shell
        // ENH046 - End
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
    // ENH095 - Middle notch support
    Loader {
        active: shell.settings.notchPosition == 1 && shell.settings.showMiddleNotchHint
        asynchronous: true
        z: shellBorderLoader.z + 1
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
        // anchors.leftMargin: (launcher.lockedByUser && launcher.lockAllowed) ? launcher.panelWidth : 0
        anchors.topMargin: panel.fullscreenMode ? shell.shellTopMargin 
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
                        ((shell.height > shell.width && shell.height / 2 >= units.gu(40)) || (shell.height <= shell.width && shell.width / 2 >= units.gu(40)))
                                && shell.settings.enableSideStage ?
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

    InputMethod {
        id: inputMethod
        objectName: "inputMethod"
        anchors {
            fill: parent
            topMargin: panel.panelHeight
            // ENH002 - Notch/Punch hole fix
            // leftMargin: (launcher.lockedByUser && launcher.lockAllowed) ? launcher.panelWidth : 0
            leftMargin: ((launcher.lockedByUser && launcher.lockAllowed) ? launcher.panelWidth : 0) + shell.shellLeftMargin
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
            function onActiveChanged() {
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
            blurSource: settings.enableBlur ? (greeter.shown ? greeter : stages) : null
            lightMode: shell.lightMode

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
            // ENH002 - Notch/Punch hole fix
            topPanelMargin: shell.isBuiltInScreen && deviceConfiguration.withNotch && shell.orientation == 1 && ! deviceConfiguration.fullyHideNotchInPortrait
                                        ? shell.shellMargin : 0
            // ENH002 - End

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
            greeterShown: greeter && greeter.shown
            hasKeyboard: shell.hasKeyboard
            panelState: panelState
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
                    && shell.mode !== "greeter"
            visible: shell.mode !== "greeter"
            inverted: shell.usageScenario !== "desktop"
            superPressed: physicalKeysMapper.superPressed
            superTabPressed: physicalKeysMapper.superTabPressed
            panelWidth: units.gu(settings.launcherWidth)
            lockedVisible: (lockedByUser || shell.atDesktop) && lockAllowed
            // ENH002 - Notch/Punch hole fix
            leftMarginBlur: overlay.anchors.leftMargin
            topMarginBlur: overlay.anchors.topMargin
            // ENH002 - End
            blurSource: settings.enableBlur ? (greeter.shown ? greeter : stages) : null
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
        function onShowHome() { if (shell.mode !== "greeter") showHome() }
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
            function onItemSnapshotRequested(item) { itemGrabber.capture(item) }
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
