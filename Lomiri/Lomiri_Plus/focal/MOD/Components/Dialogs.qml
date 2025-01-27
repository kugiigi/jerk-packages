/*
 * Copyright (C) 2014-2017 Canonical Ltd.
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
import QtMir.Application 0.1
import Lomiri.Session 0.1
import GlobalShortcut 1.0
import Lomiri.Components 1.3
import Lomiri.Platform 1.0
import Utils 0.1

MouseArea {
    id: root
    acceptedButtons: Qt.AllButtons
    hoverEnabled: true
    onWheel: wheel.accepted = true

    readonly property bool hasActiveDialog: dialogLoader.active || d.modeSwitchWarningPopup

    // to be set from outside, useful mostly for testing purposes
    property var lomiriSessionService: DBusLomiriSessionService
    property string usageScenario
    property size screenSize: Qt.size(Screen.width, Screen.height)
    property bool hasKeyboard: false

    signal powerOffClicked();

    function showPowerDialog() {
        d.showPowerDialog();
    }

    property var doOnClosedAllWindows: function() {}
    Connections {
        target: topLevelSurfaceList

        onClosedAllWindows: {
            doOnClosedAllWindows();
        }
    }

    // ENH096 - Disable close desktop apps dialog
    /*
    onUsageScenarioChanged: {
        // if we let the user switch manually to desktop mode, don't display the warning dialog
        // see MenuItemFactory.qml, for the Desktop Mode switch logic
        var isTabletSize = Math.min(screenSize.width, screenSize.height) > units.gu(60);

        if (usageScenario != "desktop" && legacyAppsModel.count > 0 && !d.modeSwitchWarningPopup && !isTabletSize) {
            var comp = Qt.createComponent(Qt.resolvedUrl("ModeSwitchWarningDialog.qml"))
            d.modeSwitchWarningPopup = comp.createObject(root, {model: legacyAppsModel});
            d.modeSwitchWarningPopup.forceClose.connect(function() {
                for (var i = legacyAppsModel.count - 1; i >= 0; i--) {
                    ApplicationManager.stopApplication(legacyAppsModel.get(i).appId);
                }
                d.modeSwitchWarningPopup.hide();
                d.modeSwitchWarningPopup.destroy();
                d.modeSwitchWarningPopup = null;
            })
        } else if (usageScenario == "desktop" && d.modeSwitchWarningPopup) {
            d.modeSwitchWarningPopup.hide();
            d.modeSwitchWarningPopup.destroy();
            d.modeSwitchWarningPopup = null;
        }
    }
    */
    // ENH096 - End

    ApplicationsFilterModel {
        id: legacyAppsModel
        applicationsModel: ApplicationManager
        filterTouchApps: true
    }

    GlobalShortcut { // reboot/shutdown dialog
        shortcut: Qt.Key_PowerDown
        active: Platform.isPC
        onTriggered: root.lomiriSessionService.RequestShutdown()
    }

    GlobalShortcut { // reboot/shutdown dialog
        shortcut: Qt.Key_PowerOff
        active: Platform.isPC
        onTriggered: root.lomiriSessionService.RequestShutdown()
    }

    GlobalShortcut { // sleep
        shortcut: Qt.Key_Sleep
        onTriggered: root.lomiriSessionService.Suspend()
    }

    GlobalShortcut { // hibernate
        shortcut: Qt.Key_Hibernate
        onTriggered: root.lomiriSessionService.Hibernate()
    }

    GlobalShortcut { // logout/lock dialog
        shortcut: Qt.Key_LogOff
        onTriggered: root.lomiriSessionService.RequestLogout()
    }

    GlobalShortcut { // logout/lock dialog
        shortcut: Qt.ControlModifier|Qt.AltModifier|Qt.Key_Delete
        onTriggered: root.lomiriSessionService.RequestLogout()
    }

    GlobalShortcut { // lock screen
        shortcut: Qt.Key_ScreenSaver
        onTriggered: root.lomiriSessionService.PromptLock()
    }

    GlobalShortcut { // lock screen
        shortcut: Qt.ControlModifier|Qt.AltModifier|Qt.Key_L
        onTriggered: root.lomiriSessionService.PromptLock()
    }

    GlobalShortcut { // lock screen
        shortcut: Qt.MetaModifier|Qt.Key_L
        onTriggered: root.lomiriSessionService.PromptLock()
    }

    QtObject {
        id: d // private stuff
        objectName: "dialogsPrivate"

        property var modeSwitchWarningPopup: null

        function showPowerDialog() {
            if (!dialogLoader.active) {
                dialogLoader.sourceComponent = powerDialogComponent;
                dialogLoader.focus = true;
                dialogLoader.active = true;
            }
        }
    }

    Loader {
        id: dialogLoader
        objectName: "dialogLoader"
        anchors.fill: parent
        active: false
        onActiveChanged: {
            if (!active) {
                if (previousFocusedItem) {
                    previousFocusedItem.forceActiveFocus(Qt.OtherFocusReason);
                    previousFocusedItem = undefined;
                }
                previousSourceComponent = undefined;
                sourceComponent = undefined;
            }
        }
        onSourceComponentChanged: {
            if (previousSourceComponent !== sourceComponent) {
                previousSourceComponent = sourceComponent;
                previousFocusedItem = window.activeFocusItem;
            }
        }

        property var previousSourceComponent: undefined
        property var previousFocusedItem: undefined
    }
    // ENH218 - Disable power off/restart in Lockscreen
    Loader {
        id: disablePowerRebootLoader

        active: shell.settings.disablePowerRebootInLockscreen && shell.showingGreeter
        asynchronous: true
        anchors.fill: parent
        sourceComponent: disablePowerRebootInLockscreenComponent
    }

    Component {
        id: disablePowerRebootInLockscreenComponent

        Item {
            readonly property bool bothAreDragging: leftSwipeArea.dragging && rightSwipeArea.dragging

            SwipeArea {
                id: leftSwipeArea

                direction: SwipeArea.Rightwards
                width: units.gu(2)
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
            }

            SwipeArea {
                id: rightSwipeArea

                direction: SwipeArea.Leftwards
                width: units.gu(2)
                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                }
            }
        }
    }
    // ENH218 - End

    Component {
        id: logoutDialogComponent
        ShellDialog {
            id: logoutDialog
            title: i18n.ctr("Title: Lock/Log out dialog", "Log out")
            text: i18n.tr("Are you sure you want to log out?")
            Button {
                width: parent.width
                text: i18n.ctr("Button: Lock the system", "Lock")
                visible: root.lomiriSessionService.CanLock()
                onClicked: {
                    root.lomiriSessionService.PromptLock();
                    logoutDialog.hide();
                }
                Component.onCompleted: if (root.hasKeyboard) forceActiveFocus(Qt.TabFocusReason)
            }
            Button {
                width: parent.width
                focus: true
                text: i18n.ctr("Button: Log out from the system", "Log Out")
                onClicked: {
                    lomiriSessionService.logout();
                    logoutDialog.hide();
                }
            }
            Button {
                width: parent.width
                text: i18n.tr("Cancel")
                onClicked: {
                    logoutDialog.hide();
                }
            }
        }
    }

    Component {
        id: rebootDialogComponent
        ShellDialog {
            id: rebootDialog
            title: i18n.ctr("Title: Reboot dialog", "Reboot")
            text: i18n.tr("Are you sure you want to reboot?")
            Button {
                width: parent.width
                text: i18n.tr("No")
                onClicked: {
                    rebootDialog.hide();
                }
            }
            Button {
                width: parent.width
                focus: true
                text: i18n.tr("Yes")
                onClicked: {
                    doOnClosedAllWindows = function(lomiriSessionService, rebootDialog) {
                        return function() {
                            lomiriSessionService.reboot();
                            rebootDialog.hide();
                        }
                    }(lomiriSessionService, rebootDialog);
                    topLevelSurfaceList.closeAllWindows();
                }
                color: theme.palette.normal.negative
                Component.onCompleted: if (root.hasKeyboard) forceActiveFocus(Qt.TabFocusReason)
            }
        }
    }

    Component {
        id: powerDialogComponent
        ShellDialog {
            id: powerDialog
            title: i18n.ctr("Title: Power off/Restart dialog", "Power")
            text: i18n.tr("Are you sure you would like\nto power off?")
            Button {
                width: parent.width
                focus: true
                text: i18n.ctr("Button: Power off the system", "Power off")
                onClicked: {
                    // ENH218 - Disable power off/restart in Lockscreen
                    /*
                    doOnClosedAllWindows = function(root, powerDialog) {
                        return function() {
                            powerDialog.hide();
                            root.powerOffClicked();
                        }
                    }(root, powerDialog);
                    topLevelSurfaceList.closeAllWindows();
                    */ 
                    if (shell.settings.disablePowerRebootInLockscreen && shell.showingGreeter
                            && (!disablePowerRebootLoader.item || (disablePowerRebootLoader.item && !disablePowerRebootLoader.item.bothAreDragging))) {
                        console.log("You shall not shutdown")
                    } else {
                        doOnClosedAllWindows = function(root, powerDialog) {
                            return function() {
                                powerDialog.hide();
                                root.powerOffClicked();
                            }
                        }(root, powerDialog);
                        topLevelSurfaceList.closeAllWindows();
                    }
                    // ENH218 - End
                }
                color: theme.palette.normal.negative
                Component.onCompleted: if (root.hasKeyboard) forceActiveFocus(Qt.TabFocusReason)
            }
            Button {
                width: parent.width
                text: i18n.ctr("Button: Restart the system", "Restart")
                onClicked: {
                    // ENH218 - Disable power off/restart in Lockscreen
                    /*
                    doOnClosedAllWindows = function(lomiriSessionService, powerDialog) {
                        return function() {
                            lomiriSessionService.reboot();
                            powerDialog.hide();
                        }
                    }(lomiriSessionService, powerDialog);
                    topLevelSurfaceList.closeAllWindows();
                    */
                    if (shell.settings.disablePowerRebootInLockscreen && shell.showingGreeter
                            && (!disablePowerRebootLoader.item || (disablePowerRebootLoader.item && !disablePowerRebootLoader.item.bothAreDragging))) {
                        console.log("You shall not reboot")
                    } else {
                        doOnClosedAllWindows = function(lomiriSessionService, powerDialog) {
                            return function() {
                                lomiriSessionService.reboot();
                                powerDialog.hide();
                            }
                        }(lomiriSessionService, powerDialog);
                        topLevelSurfaceList.closeAllWindows();
                    }
                    // ENH218 - End
                }
            }
            Button {
                width: parent.width
                text: i18n.tr("Screenshot")
                onClicked: {
                    powerDialog.hide();
                    itemGrabber.capture(shell);
                }
            }
            Button {
                width: parent.width
                text: i18n.tr("Cancel")
                onClicked: {
                    powerDialog.hide();
                }
            }
        }
    }

    Connections {
        target: root.lomiriSessionService

        onLogoutRequested: {
            // Display a dialog to ask the user to confirm.
            if (!dialogLoader.active) {
                dialogLoader.sourceComponent = logoutDialogComponent;
                dialogLoader.focus = true;
                dialogLoader.active = true;
            }
        }

        onShutdownRequested: {
            // Display a dialog to ask the user to confirm.
            showPowerDialog();
        }

        onRebootRequested: {
            // Display a dialog to ask the user to confirm.

            // display a combined reboot/shutdown dialog, sadly the session indicator calls rather the "Reboot()" method
            // than shutdown when clicking on the "Shutdown..." menu item
            // FIXME: when/if session indicator is fixed, put the rebootDialogComponent here
            showPowerDialog();
        }

        onLogoutReady: {
            doOnClosedAllWindows = function(lomiriSessionService) {
                return function() {
                    Qt.quit();
                    lomiriSessionService.endSession();
                }
            }(lomiriSessionService);
            topLevelSurfaceList.closeAllWindows();
        }
    }
}
