/*
 * Copyright (C) 2013-2016 Canonical Ltd.
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
import AccountsService 0.1
import Biometryd 0.0
import GSettings 1.0
import Powerd 0.1
import Lomiri.Components 1.3
import Lomiri.Launcher 0.1
import Lomiri.Session 0.1

import "." 0.1
import ".." 0.1
import "../Components"

Showable {
    id: root
    created: loader.status == Loader.Ready

    property real dragHandleLeftMargin: 0

    property url background
    property bool hasCustomBackground
    property real backgroundSourceSize

    // How far to offset the top greeter layer during a launcher left-drag
    property real launcherOffset

    // How far down to position the greeter's interface to avoid the Panel
    property real panelHeight

    readonly property bool active: required || hasLockedApp
    readonly property bool fullyShown: loader.item ? loader.item.fullyShown : false

    property bool allowFingerprint: true

    // True when the greeter is waiting for PAM or other setup process
    readonly property alias waiting: d.waiting

    property string lockedApp: ""
    readonly property bool hasLockedApp: lockedApp !== ""

    property bool forcedUnlock
    readonly property bool locked: LightDMService.greeter.active && !LightDMService.greeter.authenticated && !forcedUnlock

    property bool tabletMode
    property string usageMode
    property url viewSource // only used for testing

    property int failedLoginsDelayAttempts: 7 // number of failed logins
    property real failedLoginsDelayMinutes: 5 // minutes of forced waiting
    property int failedFingerprintLoginsDisableAttempts: 5 // number of failed fingerprint logins
    property int failedFingerprintReaderRetryDelay: 250 // time to wait before retrying a failed fingerprint read [ms]

    readonly property bool animating: loader.item ? loader.item.animating : false

    property rect inputMethodRect

    property bool hasKeyboard: false
    property int orientation

    signal tease()
    signal sessionStarted()
    signal emergencyCall()

    // ENH032 - Infographics Outer Wilds
    property bool enableOW: shell.settings.enableOW
    property bool alternateOW: shell.settings.ow_theme == 0
    property bool solarOW: shell.settings.ow_theme == 1
    property bool dlcOW: shell.settings.ow_theme == 2
    property bool fastModeOW: false
    // ENH032 - End

    function forceShow() {
        if (!active) {
            d.isLockscreen = true;
        }
        forcedUnlock = false;
        if (required) {
            if (loader.item) {
                loader.item.forceShow();
            }
            // Normally loader.onLoaded will select a user, but if we're
            // already shown, do it manually.
            d.selectUser(d.currentIndex);
        }

        // Even though we may already be shown, we want to call show() for its
        // possible side effects, like hiding indicators and such.
        //
        // We re-check forcedUnlock here, because selectUser above might
        // process events during authentication, and a request to unlock could
        // have come in in the meantime.
        if (!forcedUnlock) {
            showNow();
        }
    }

    function notifyAppFocusRequested(appId) {
        if (!active) {
            return;
        }

        if (hasLockedApp) {
            if (appId === lockedApp) {
                hide(); // show locked app
            } else {
                show();
                d.startUnlock(false /* toTheRight */);
            }
        } else {
            d.startUnlock(false /* toTheRight */);
        }
    }

    // Notify that the user has explicitly requested an app
    function notifyUserRequestedApp() {
        if (!active) {
            return;
        }

        // A hint that we're about to focus an app.  This way we can look
        // a little more responsive, rather than waiting for the above
        // notifyAppFocusRequested call.  We also need this in case we have a locked
        // app, in order to show lockscreen instead of new app.
        d.startUnlock(false /* toTheRight */);
    }

    // This is a just a glorified notifyUserRequestedApp(), but it does one
    // other thing: it hides any cover pages to the RIGHT, because the user
    // just came from a launcher drag starting on the left.
    // It also returns a boolean value, indicating whether there was a visual
    // change or not (the shell only wants to hide the launcher if there was
    // a change).
    function notifyShowingDashFromDrag() {
        if (!active) {
            return false;
        }

        return d.startUnlock(true /* toTheRight */);
    }

    function sessionToStart() {
        for (var i = 0; i < LightDMService.sessions.count; i++) {
            var session = LightDMService.sessions.data(i,
                LightDMService.sessionRoles.KeyRole);
            if (loader.item.sessionToStart === session) {
                return session;
            }
        }

        return LightDMService.greeter.defaultSession;
    }

    QtObject {
        id: d

        readonly property bool multiUser: LightDMService.users.count > 1
        readonly property int selectUserIndex: d.getUserIndex(LightDMService.greeter.selectUser)
        property int currentIndex: Math.max(selectUserIndex, 0)
        readonly property bool waiting: LightDMService.prompts.count == 0 && !root.forcedUnlock
        property bool isLockscreen // true when we are locking an active session, rather than first user login
        readonly property bool secureFingerprint: isLockscreen &&
                                                  AccountsService.failedFingerprintLogins <
                                                  root.failedFingerprintLoginsDisableAttempts
        readonly property bool alphanumeric: AccountsService.passwordDisplayHint === AccountsService.Keyboard

        // We want 'launcherOffset' to animate down to zero.  But not to animate
        // while being dragged.  So ideally we change this only when the user
        // lets go and launcherOffset drops to zero.  But we need to wait for
        // the behavior to be enabled first.  So we cache the last known good
        // launcherOffset value to cover us during that brief gap between
        // release and the behavior turning on.
        property real lastKnownPositiveOffset // set in a launcherOffsetChanged below
        property real launcherOffsetProxy: (shown && !launcherOffsetProxyBehavior.enabled) ? lastKnownPositiveOffset : 0
        Behavior on launcherOffsetProxy {
            id: launcherOffsetProxyBehavior
            enabled: launcherOffset === 0
            LomiriNumberAnimation {}
        }

        function getUserIndex(username) {
            if (username === "")
                return -1;

            // Find index for requested user, if it exists
            for (var i = 0; i < LightDMService.users.count; i++) {
                if (username === LightDMService.users.data(i, LightDMService.userRoles.NameRole)) {
                    return i;
                }
            }

            return -1;
        }

        function selectUser(index) {
            if (index < 0 || index >= LightDMService.users.count)
                return;
            currentIndex = index;
            var user = LightDMService.users.data(index, LightDMService.userRoles.NameRole);
            AccountsService.user = user;
            LauncherModel.setUser(user);
            LightDMService.greeter.authenticate(user); // always resets auth state
        }

        function hideView() {
            if (loader.item) {
                loader.item.enabled = false; // drop OSK and prevent interaction
                loader.item.hide();
            }
        }

        function login() {
            if (LightDMService.greeter.startSessionSync(root.sessionToStart())) {
                sessionStarted();
                hideView();
            } else if (loader.item) {
                loader.item.notifyAuthenticationFailed();
            }
        }

        function startUnlock(toTheRight) {
            if (loader.item) {
                return loader.item.tryToUnlock(toTheRight);
            } else {
                return false;
            }
        }

        function checkForcedUnlock(hideNow) {
            if (forcedUnlock && shown) {
                hideView();
                if (hideNow) {
                    ShellNotifier.greeter.hide(true); // skip hide animation
                }
            }
        }

        function showFingerprintMessage(msg) {
            d.selectUser(d.currentIndex);
            LightDMService.prompts.prepend(msg, LightDMService.prompts.Error);
            if (loader.item) {
                loader.item.showErrorMessage(msg);
                loader.item.notifyAuthenticationFailed();
            }
        }
    }

    onLauncherOffsetChanged: {
        if (launcherOffset > 0) {
            d.lastKnownPositiveOffset = launcherOffset;
        }
    }

    onForcedUnlockChanged: d.checkForcedUnlock(false /* hideNow */)
    Component.onCompleted: d.checkForcedUnlock(true /* hideNow */)

    onLockedChanged: {
        if (!locked) {
            AccountsService.failedLogins = 0;
            AccountsService.failedFingerprintLogins = 0;

            // Stop delay timer if they logged in with fingerprint
            forcedDelayTimer.stop();
            forcedDelayTimer.delayMinutes = 0;
        }
    }

    onRequiredChanged: {
        if (required) {
            lockedApp = "";
        }
    }

    GSettings {
        id: greeterSettings
        schema.id: "com.lomiri.Shell.Greeter"
    }

    Timer {
        id: forcedDelayTimer

        // We use a short interval and check against the system wall clock
        // because we have to consider the case that the system is suspended
        // for a few minutes.  When we wake up, we want to quickly be correct.
        interval: 500

        property var delayTarget
        property int delayMinutes

        function forceDelay() {
            // Store the beginning time for a lockout in GSettings, so that
            // we still lock the user out if they reboot.  And we store
            // starting time rather than end-time or how-long because:
            // - If storing end-time and on boot we have a problem with NTP,
            //   we might get locked out for a lot longer than we thought.
            // - If storing how-long, and user turns their phone off for an
            //   hour rather than wait, they wouldn't expect to still be locked
            //   out.
            // - A malicious actor could manipulate either of the above
            //   settings to keep the user out longer.  But by storing
            //   start-time, we never make the user wait longer than the full
            //   lock out time.
            greeterSettings.lockedOutTime = new Date().getTime();
            checkForForcedDelay();
        }

        onTriggered: {
            var diff = delayTarget - new Date();
            if (diff > 0) {
                delayMinutes = Math.ceil(diff / 60000);
                start(); // go again
            } else {
                delayMinutes = 0;
            }
        }

        function checkForForcedDelay() {
            if (greeterSettings.lockedOutTime === 0) {
                return;
            }

            var now = new Date();
            delayTarget = new Date(greeterSettings.lockedOutTime + failedLoginsDelayMinutes * 60000);

            // If tooEarly is true, something went very wrong.  Bug or NTP
            // misconfiguration maybe?
            var tooEarly = now.getTime() < greeterSettings.lockedOutTime;
            var tooLate = now >= delayTarget;

            // Compare stored time to system time. If a malicious actor is
            // able to manipulate time to avoid our lockout, they already have
            // enough access to cause damage. So we choose to trust this check.
            if (tooEarly || tooLate) {
                stop();
                delayMinutes = 0;
            } else {
                triggered();
            }
        }

        Component.onCompleted: checkForForcedDelay()
    }

    // event eater
    // Nothing should leak to items behind the greeter
    MouseArea { anchors.fill: parent; hoverEnabled: true }

    Loader {
        id: loader
        objectName: "loader"

        anchors.fill: parent

        active: root.required
        source: root.viewSource.toString() ? root.viewSource : "GreeterView.qml"

        onLoaded: {
            root.lockedApp = "";
            item.forceActiveFocus();
            d.selectUser(d.currentIndex);
            LightDMService.infographic.readyForDataChange();
        }

        Connections {
            target: loader.item
            onSelected: {
                d.selectUser(index);
            }
            onResponded: {
                if (root.locked) {
                    LightDMService.greeter.respond(response);
                } else {
                    d.login();
                }
            }
            onTease: root.tease()
            onEmergencyCall: root.emergencyCall()
            onRequiredChanged: {
                if (!loader.item.required) {
                    ShellNotifier.greeter.hide(false);
                }
            }

            // ENH032 - Infographics Outer Wilds
            onOwToggle: root.enableOW = !root.enableOW
            onFastModeToggle: root.fastModeOW = !root.fastModeOW
            // ENH032 - End
        }
        // ENH045 - Return focus when rotating in greeter
        Connections {
            target: root
            onOrientationChanged: {
                if (loader.item && loader.item.fullyShown) {
                    timerBeta.restart()
                }
            }
        }
        
        // Solves a timing issue when rotating to portrait
        Timer {
            id: timerBeta
            interval: 1
            onTriggered: loader.item.forceActiveFocus()
        }
        // ENH045 - End
        // ENH032 - Infographics Outer Wilds
        Binding {
            target: loader.item
            property: "enableOW"
            value: root.enableOW
        }
        Binding {
            target: loader.item
            property: "alternateOW"
            value: root.alternateOW
        }
        Binding {
            target: loader.item
            property: "solarOW"
            value: root.solarOW
        }
        Binding {
            target: loader.item
            property: "dlcOW"
            value: root.dlcOW
        }
        Binding {
            target: loader.item
            property: "fastModeOW"
            value: root.fastModeOW
        }
        // ENH032 - End

        Binding {
            target: loader.item
            property: "panelHeight"
            value: root.panelHeight
        }

        Binding {
            target: loader.item
            property: "launcherOffset"
            value: d.launcherOffsetProxy
        }

        Binding {
            target: loader.item
            property: "dragHandleLeftMargin"
            value: root.dragHandleLeftMargin
        }

        Binding {
            target: loader.item
            property: "delayMinutes"
            value: forcedDelayTimer.delayMinutes
        }

        Binding {
            target: loader.item
            property: "background"
            value: root.background
        }

        Binding {
            target: loader.item
            property: "backgroundSourceSize"
            value: root.backgroundSourceSize
        }

        Binding {
            target: loader.item
            property: "hasCustomBackground"
            // ENH032 - Infographics Outer Wilds
            // value: root.hasCustomBackground
            value: root.enableOW ? false : root.hasCustomBackground
            // ENH032 - End
        }

        Binding {
            target: loader.item
            property: "locked"
            value: root.locked
        }

        Binding {
            target: loader.item
            property: "waiting"
            value: d.waiting
        }

        Binding {
            target: loader.item
            property: "alphanumeric"
            value: d.alphanumeric
        }

        Binding {
            target: loader.item
            property: "currentIndex"
            value: d.currentIndex
        }

        Binding {
            target: loader.item
            property: "userModel"
            value: LightDMService.users
        }

        Binding {
            target: loader.item
            property: "infographicModel"
            value: LightDMService.infographic
        }

        Binding {
            target: loader.item
            property: "inputMethodRect"
            value: root.inputMethodRect
        }

        Binding {
            target: loader.item
            property: "hasKeyboard"
            value: root.hasKeyboard
        }

        Binding {
            target: loader.item
            property: "usageMode"
            value: root.usageMode
        }

        Binding {
            target: loader.item
            property: "multiUser"
            value: d.multiUser
        }

        Binding {
            target: loader.item
            property: "orientation"
            value: root.orientation
        }
    }

    // ENH032 - Infographics Outer Wilds
    Icon {
        id: eyeMarker

        readonly property color normalColor: "#c2cffc"
        readonly property color successColor: "#3d60e3"
        readonly property color errorColor: "#3d60e3"
        
        readonly property real normalSize: units.gu(5)
        readonly property real successSize: units.gu(60)

        // ENH046 - Lomiri Plus Settings
        //property bool enableMarker: true
        property bool enableMarker: shell.settings.enableEyeFP
        // ENH046 - End
        property bool show: false

        visible: biometryd.idEnabled && enableMarker && root.fullyShown && shell.isBuiltInScreen
        source: "../OuterWilds/graphics/eye.svg"
        color: successColor
        keyColor: "#000000"
        width: !show ? normalSize : successSize
        height: width
        anchors.centerIn: fpMarker
        
        Behavior on width {
            LomiriNumberAnimation {
                duration: LomiriAnimation.SnapDuration
            }
        }
        
        Behavior on opacity {
            LomiriNumberAnimation {
                duration: LomiriAnimation.SnapDuration
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: LomiriAnimation.SnapDuration
            }
        }

        MouseArea {
            anchors.centerIn: parent
            width: fpMarker.width
            height: fpMarker.height
            onPressed: {
                eyeMarker.show = true
                resetDelay.restart()
            }
        }
        
        Timer {
            id: resetDelay
            interval: 500
            onTriggered: {
                eyeMarker.show = false
            }
        }
    }
    // ENH032 - End
    
    // ENH001 - Fingerprint marker
    Rectangle {
		id: fpMarker

		readonly property real sideMargin: 250 //units.gu(10)

        property bool enableMarker: false

		visible: biometryd.idEnabled && enableMarker && root.fullyShown && shell.isBuiltInScreen
		height: 210//180 // units.gu(7)
		width: 180//150 // units.gu(6)
		color: theme.palette.normal.activity
		opacity: 0.2
		radius: width / 2

		states: [
			State {
				name: "portrait"
				when: root.orientation == 1

				AnchorChanges {
					target: fpMarker
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.bottom: parent.bottom
				}
				PropertyChanges {
					target: fpMarker
					anchors.bottomMargin: fpMarker.sideMargin
				}
			}
			,State {
				name: "invertedportrait"
				when: root.orientation == 4

				AnchorChanges {
					target: fpMarker
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.top: parent.top
				}
				PropertyChanges {
					target: fpMarker
					anchors.topMargin: fpMarker.sideMargin
				}
			}
			,State {
				name: "landscape"
				when: root.orientation == 2

				AnchorChanges {
					target: fpMarker
					anchors.verticalCenter: parent.verticalCenter
					anchors.left: parent.left
				}
				PropertyChanges {
					target: fpMarker
					anchors.leftMargin: fpMarker.sideMargin
				}
			}
			,State {
				name: "invertedlandscape"
				when: root.orientation == 8

				AnchorChanges {
					target: fpMarker
					anchors.verticalCenter: parent.verticalCenter
					anchors.right: parent.right
				}
				PropertyChanges {
					target: fpMarker
					anchors.rightMargin: fpMarker.sideMargin
				}
			}
		]

		Connections {
			target: biometryd
			onFailed: fpMarker.color = theme.palette.normal.negative
			onSucceeded: fpMarker.color = theme.palette.normal.positive
			onStarted: fpMarker.color = theme.palette.normal.activity
		}
    }
    // ENH001 - End

    Connections {
        target: LightDMService.greeter

        onShowGreeter: root.forceShow()
        onHideGreeter: root.forcedUnlock = true

        onLoginError: {
            if (!loader.item) {
                return;
            }

            loader.item.notifyAuthenticationFailed();

            if (!automatic) {
                AccountsService.failedLogins++;

                // Check if we should initiate a forced login delay
                if (failedLoginsDelayAttempts > 0
                        && AccountsService.failedLogins > 0
                        && AccountsService.failedLogins % failedLoginsDelayAttempts == 0) {
                    forcedDelayTimer.forceDelay();
                }

                d.selectUser(d.currentIndex);
            }
        }

        onLoginSuccess: {
            if (!automatic) {
                d.login();
            }
        }

        onRequestAuthenticationUser: d.selectUser(d.getUserIndex(user))
    }

    Connections {
        target: ShellNotifier.greeter
        onHide: {
            if (now) {
                root.hideNow(); // skip hide animation
            } else {
                root.hide();
            }
        }
    }

    Binding {
        target: ShellNotifier.greeter
        property: "shown"
        value: root.shown
    }

    Connections {
        target: DBusLomiriSessionService
        onLockRequested: root.forceShow()
        onUnlocked: {
            root.forcedUnlock = true;
            ShellNotifier.greeter.hide(true);
        }
    }

    Binding {
        target: LightDMService.greeter
        property: "active"
        value: root.active
    }

    Binding {
        target: LightDMService.infographic
        property: "username"
        value: AccountsService.statsWelcomeScreen ? LightDMService.users.data(d.currentIndex, LightDMService.userRoles.NameRole) : ""
    }

    Connections {
        target: i18n
        onLanguageChanged: LightDMService.infographic.readyForDataChange()
    }

    Timer {
        id: fpRetryTimer
        running: false
        repeat: false
        onTriggered: biometryd.startOperation()
        interval: failedFingerprintReaderRetryDelay
    }

    Observer {
        id: biometryd
        objectName: "biometryd"

        property var operation: null
        readonly property bool idEnabled: root.active &&
                                          root.allowFingerprint &&
                                          // ENH219 - Fingerprint Improvements
                                          // Powerd.status === Powerd.On &&
                                          (shell.settings.enableFingerprintWhileDisplayOff
                                            || !shell.settings.enableFingerprintWhileDisplayOff && Powerd.status === Powerd.On) &&
                                          // ENH219 - End
                                          Biometryd.available &&
                                          AccountsService.enableFingerprintIdentification

        function startOperation() {
            if (idEnabled) {
                var identifier = Biometryd.defaultDevice.identifier;
                operation = identifier.identifyUser();
                operation.start(biometryd);
            }
        }

        function cancelOperation() {
            if (operation) {
                operation.cancel();
                operation = null;
            }
        }

        function restartOperation() {
            cancelOperation();
            if (failedFingerprintReaderRetryDelay > 0) {
                fpRetryTimer.running = true;
            } else {
                startOperation();
            }
        }

        function failOperation(reason) {
            console.log("Failed to identify user by fingerprint:", reason);
            restartOperation();
            var msg = d.secureFingerprint ? i18n.tr("Try again") :
                      d.alphanumeric ? i18n.tr("Enter passphrase to unlock") :
                                       i18n.tr("Enter passcode to unlock");
            d.showFingerprintMessage(msg);
        }

        Component.onCompleted: startOperation()
        Component.onDestruction: cancelOperation()
        onIdEnabledChanged: restartOperation()

        onSucceeded: {
            if (!d.secureFingerprint) {
                failOperation("fingerprint reader is locked");
                // ENH219 - Fingerprint Improvements
                // Turn on display when locked out
                if (shell.settings.enableFingerprintWhileDisplayOff && Powerd.status === Powerd.Off) {
                    Powerd.setStatus(Powerd.On, Powerd.SnapDecision)
                }
                // ENH219 - End
                return;
            }
            if (result !== LightDMService.users.data(d.currentIndex, LightDMService.userRoles.UidRole)) {
                AccountsService.failedFingerprintLogins++;
                failOperation("not the selected user");
                return;
            }
            console.log("Identified user by fingerprint:", result);
            if (loader.item) {
                // ENH219 - Fingerprint Improvements
                // loader.item.showFakePassword();
                if (!shell.settings.enableFingerprintWhileDisplayOff
                        || (shell.settings.enableFingerprintWhileDisplayOff
                                && !shell.settings.onlyTurnOnDisplayWhenFingerprintDisplayOff)
                   ) {
                    loader.item.showFakePassword();
                }
                // ENH219 - End
            }
            if (root.active)
                // ENH219 - Fingerprint Improvements
                if (shell.settings.enableFingerprintWhileDisplayOff && Powerd.status === Powerd.Off) {
                    Powerd.setStatus(Powerd.On, Powerd.SnapDecision)

                    // Display on only and do not unlock
                    if (shell.settings.onlyTurnOnDisplayWhenFingerprintDisplayOff) {
                        restartOperation();
                        return;
                    }
                }
                // ENH219 - End
                // ENH032 - Infographics Outer Wilds
                // root.forcedUnlock = true;
                delayUnlock.restart()           
                // ENH032 - End
        }
        onFailed: {
            if (!d.secureFingerprint) {
                failOperation("fingerprint reader is locked");
            } else if (reason !== "ERROR_CANCELED") {
                // ENH219 - Fingerprint Improvements
                // AccountsService.failedFingerprintLogins++;
                if (!shell.settings.enableFingerprintWhileDisplayOff
                        || (shell.settings.enableFingerprintWhileDisplayOff && !shell.settings.failedFingerprintAttemptsWhileDisplayOffWontCount)
                    ) {
                    AccountsService.failedFingerprintLogins++;
                }
                if (shell.settings.enableFingerprintHapticWhenFailed) {
                    shell.haptics.playLong()
                }
                // ENH219 - End
                failOperation(reason);
            }
        }
    }
    // ENH032 - Infographics Outer Wilds
    Timer {
        id: delayUnlock
        interval: 1
        onTriggered: root.forcedUnlock = true;
    }
    // ENH032 - End
}
