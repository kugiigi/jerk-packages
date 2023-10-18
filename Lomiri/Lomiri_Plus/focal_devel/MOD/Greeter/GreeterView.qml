/*
 * Copyright (C) 2015-2016 Canonical, Ltd.
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
import QtGraphicalEffects 1.12
import Lomiri.Components 1.3
import Lomiri.Telephony 0.1 as Telephony
import "../Components"

FocusScope {
    id: root
    objectName: "GreeterView"

    focus: true

    property url background
    property real backgroundSourceSize
    property real panelHeight
    property bool hasCustomBackground
    property alias dragHandleLeftMargin: coverPage.dragHandleLeftMargin
    property var infographicModel
    property alias launcherOffset: coverPage.launcherOffset
    property alias currentIndex: loginList.currentIndex
    property alias delayMinutes: delayedLockscreen.delayMinutes // TODO
    property alias alphanumeric: loginList.alphanumeric
    property alias hasKeyboard: loginList.hasKeyboard
    property bool locked
    property bool waiting
    property var userModel // Set from outside
    property bool multiUser: false
    property int orientation
    property bool isLandscape: root.orientation == Qt.LandscapeOrientation ||
                               root.orientation == Qt.InvertedLandscapeOrientation ||
                               usageMode == "desktop"
    property bool isPortrait: (root.orientation == Qt.PortraitOrientation ||
                              root.orientation == Qt.InvertedPortraitOrientation) &&
                              usageMode != "desktop"

    property string usageMode

    readonly property bool animating: coverPage.showAnimation.running || coverPage.hideAnimation.running
    readonly property bool fullyShown: coverPage.showProgress === 1 || lockscreen.shown
    readonly property bool required: coverPage.required || lockscreen.required
    readonly property alias sessionToStart: loginList.currentSession

    property rect inputMethodRect

    signal selected(int index)
    signal responded(string response)
    signal tease()
    signal emergencyCall() // unused
    
    // ENH032 - Infographics Outer Wilds
    property bool enableOW: false
    property bool alternateOW: false
    property bool solarOW: false
    property bool dlcOW: false
    property bool fastModeOW: false
    signal fastModeToggle
    signal owToggle
    // ENH032 - End

    function notifyAuthenticationFailed() {
        loginList.showError();
    }

    function forceShow() {
        coverPage.show();
    }

    function tryToUnlock(toTheRight) {
        var coverChanged = coverPage.shown;
        if (toTheRight) {
            coverPage.hideRight();
        } else {
            coverPage.hide();
        }
        if (root.locked) {
            lockscreen.show();
            loginList.tryToUnlock();
            return false;
        } else {
            root.responded("");
            return coverChanged;
        }
    }

    function hide() {
        lockscreen.hide();
        coverPage.hide();
    }

    function showFakePassword() {
        loginList.showFakePassword();
    }

    function showErrorMessage(msg) {
        coverPage.showErrorMessage(msg);
    }

    onLockedChanged: changeLockscreenState()
    onMultiUserChanged: changeLockscreenState()

    function changeLockscreenState() {
        if (locked || multiUser) {
            lockscreen.maybeShow();
        } else {
            lockscreen.hide();
        }
    }

    // ENH038 - Directly type password/passcode in lockscreen
    // Keys.onSpacePressed: coverPage.hide();
    // Keys.onReturnPressed: coverPage.hide();
    // Keys.onEnterPressed: coverPage.hide();

    Keys.onPressed: {
        // ENH032 - Infographics Outer Wilds
        if ((event.key == Qt.Key_Enter || event.key == Qt.Key_Return
                    || event.key == Qt.Key_Space) && owMenuLoader.item && !owMenuLoader.item.listIsFocused && coverPage.shown) {
            owMenuLoader.item.selectCurrentItem()
        } else if ((event.key == Qt.Key_Up || event.key == Qt.Key_Down) && owMenuLoader.item
                                                                && !owMenuLoader.item.listIsFocused) {
            owMenuLoader.item.setFocus()
            if (event.key == Qt.Key_Down) {
                owMenuLoader.item.incrementCurrentIndex()
            } else {
                owMenuLoader.item.decrementCurrentIndex()
            }
        } else if ((event.key == Qt.Key_Escape
                    || event.key == Qt.Key_Return || event.key == Qt.Key_Enter
                    || event.key == Qt.Key_Space) && !owMenuLoader.item) {
                coverPage.hide();
        } else if (event.text.trim() !== "") {
            if (loginList.setInitText(event.text)) { // Check if initial text is accepted based on prompt type
                coverPage.hide();
            }
        }
        event.accepted = true;
        // ENH032 - End
    }

    // ENH038 - End

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: lockscreen.showProgress * 0.8
    }

    CoverPage {
        id: lockscreen
        objectName: "lockscreen"
        height: parent.height
        width: parent.width
        draggable: false
        state: "LoginList"

        // ENH034 - Separate wallpaper lockscreen and desktop
        // background: root.background
        backgroundSourceSize: root.backgroundSourceSize
        //background: "file:///home/phablet/Pictures/lomiri_wallpapers/lockscreen"
        //backgroundSourceSize: 1440
        fallbackBackground: root.background
        // ENH034 - End
        panelHeight: root.panelHeight
        hasCustomBackground: root.hasCustomBackground
        backgroundShadeOpacity: 0.6

        showInfographic: isLandscape && root.usageMode != "phone" && (root.usageMode != "tablet" || root.multiUser) && !delayedLockscreen.visible
        infographicModel: root.infographicModel

        shown: false
        opacity: 0

        showAnimation: StandardAnimation { property: "opacity"; to: 1 }
        hideAnimation: StandardAnimation { property: "opacity"; to: 0 }

        infographicsTopMargin: parent.height * 0.125
        infographicsBottomMargin: parent.height * 0.125
        infographicsLeftMargin: loginList.x + loginList.width
        // ENH032 - Infographics Outer Wilds
        owWallpaper: root.enableOW
        owAlternateWallpaper: root.alternateOW
        owDLCWallpaper: root.dlcOW
        Loader {
            active: lockscreen.owWallpaper && lockscreen.owAlternateWallpaper && lockscreen.shown && !coverPage.shown
            asynchronous: true
            anchors {
                right: parent.right
                bottom: parent.bottom
                rightMargin: units.gu(5)
                bottomMargin: inputMethodRect.height + units.gu(5)
            }
            height: units.gu(10)
            width: height
            sourceComponent: Component {
                Item {
                    Icon {
                        source: "../OuterWilds/graphics/loading_circle.svg"
                        width: units.gu(5)
                        height: width
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        id: rotatingCircle
                        color: "transparent"
                        anchors.fill: parent
                        Rectangle {
                            color: "#fe7c25"
                            radius: width / 2
                            height: units.gu(1)
                            width: height
                            anchors {
                                top: parent.top
                                horizontalCenter: parent.horizontalCenter
                            }
                        }
                        RotationAnimation {
                            target: rotatingCircle
                            running: true
                            loops: Animation.Infinite
                            duration: 5000
                            from: 0
                            to: 360
                            direction: RotationAnimation.Clockwise
                        }
                    }
                }
            }
        }
        // ENH032 - End

        onTease: root.tease()

        onShowProgressChanged: {
            if (showProgress === 0 && !root.locked) {
                root.responded("");
            }
        }

        LoginList {
            id: loginList
            objectName: "loginList"

            width: units.gu(40)
            anchors {
                top: parent.top
                bottom: parent.bottom
            }

            boxVerticalOffset: (height - highlightedHeight -
                               inputMethodRect.height) / 2
            Behavior on boxVerticalOffset { LomiriNumberAnimation {} }

            enabled: !coverPage.shown && visible
            visible: !delayedLockscreen.visible

            model: root.userModel
            onResponded: root.responded(response)
            onSelected: root.selected(index)
            onSessionChooserButtonClicked: parent.state = "SessionsList"
            onCurrentIndexChanged: setCurrentSession()

            locked: root.locked
            waiting: root.waiting

            Keys.forwardTo: [sessionChooserLoader.item]

            Component.onCompleted: setCurrentSession()

            function setCurrentSession() {
                currentSession = LightDMService.users.data(currentIndex, LightDMService.userRoles.SessionRole);
            }
        }

        DelayedLockscreen {
            id: delayedLockscreen
            objectName: "delayedLockscreen"
            anchors.fill: parent
            visible: delayMinutes > 0
            alphaNumeric: loginList.alphanumeric
        }

        function maybeShow() {
            if ((root.locked || root.multiUser) && !shown) {
                showNow();
            }
        }

        Loader {
            id: sessionChooserLoader

            height: loginList.height
            width: loginList.width

            anchors {
                left: parent.left
                leftMargin: Math.min(parent.width * 0.16, units.gu(20))
                top: parent.top
            }

            active: false

            onLoaded: sessionChooserLoader.item.forceActiveFocus();
            onActiveChanged: {
                if (!active) return;
                item.updateHighlight(loginList.currentSession);
            }

            Connections {
                target: sessionChooserLoader.item
                onSessionSelected: loginList.currentSession = sessionKey
                onShowLoginList: {
                    lockscreen.state = "LoginList"
                    loginList.tryToUnlock();
                }
                ignoreUnknownSignals: true
            }
        }

        // Use an AbstractButton due to icon limitations with Button
        AbstractButton {
            id: sessionChooser
            objectName: "sessionChooserButton"

            readonly property url icon: LightDMService.sessions.iconUrl(loginList.currentSession)

            visible: LightDMService.sessions.count > 1 &&
                !LightDMService.users.data(loginList.currentUserIndex, LightDMService.userRoles.LoggedInRole)

            height: units.gu(3.5)
            width: units.gu(3.5)

            activeFocusOnTab: true
            anchors {
                right: parent.right
                rightMargin: units.gu(2)

                bottom: parent.bottom
                bottomMargin: units.gu(1.5)
            }

            Rectangle {
                id: badgeHighlight

                anchors.fill: parent
                visible: parent.activeFocus
                color: "transparent"
                border.color: theme.palette.normal.focus
                border.width: units.dp(1)
                radius: 3
            }

            Icon {
                id: badge
                anchors.fill: parent
                anchors.margins: units.dp(3)
                keyColor: "#ffffff" // icon providers give us white icons
                color: theme.palette.normal.raisedSecondaryText
                source: sessionChooser.icon
            }

            Keys.onReturnPressed: {
                parent.state = "SessionsList";
            }

            onClicked: {
                parent.state = "SessionsList";
            }

            // Refresh the icon path if looking at different places at runtime
            // this is mainly for testing
            Connections {
                target: LightDMService.sessions
                onIconSearchDirectoriesChanged: {
                    badge.source = LightDMService.sessions.iconUrl(root.currentSession)
                }
            }
        }

        states: [
            State {
                name: "SessionsList"
                PropertyChanges { target: loginList; opacity: 0 }
                PropertyChanges { target: sessionChooserLoader;
                                  active: true;
                                  opacity: 1
                                  source: "SessionsList.qml"
                                }
            },

            State {
                name: "LoginList"
                PropertyChanges { target: loginList; opacity: 1 }
                PropertyChanges { target: sessionChooserLoader;
                                  active: false;
                                  opacity: 0
                                  source: "";
                                }
            }
        ]

        transitions: [
            Transition {
                from: "*"
                to: "*"
                LomiriNumberAnimation {
                    property: "opacity";
                }
            }
        ]

        Component.onCompleted: if (root.multiUser) showNow()
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: coverPage.showProgress * 0.8
    }

    CoverPage {
        id: coverPage
        objectName: "coverPage"
        height: parent.height
        width: parent.width
        // ENH034 - Separate wallpaper lockscreen and desktop
        // background: root.background
        //background: "file:///home/phablet/Pictures/lomiri_wallpapers/lockscreen"
        fallbackBackground: root.background
        useCoverPageWallpaper: shell.settings.useCustomCoverPage
        // ENH034 - End
        hasCustomBackground: root.hasCustomBackground
        backgroundShadeOpacity: 0.4
        panelHeight: root.panelHeight
        draggable: !root.waiting
        onTease: root.tease()
        onClicked: hide()
        // ENH034 - Separate wallpaper lockscreen and desktop
        backgroundSourceSize: root.backgroundSourceSize
        //backgroundSourceSize: 1440
        // ENH034 - End
        infographicModel: root.infographicModel

        showInfographic: !root.multiUser && root.usageMode != "desktop"

        onShowProgressChanged: {
            if (showProgress === 0) {
                if (lockscreen.shown) {
                    loginList.tryToUnlock();
                } else {
                    root.responded("");
                }
            }
        }
        
        // ENH032 - Infographics Outer Wilds
        enableOW: root.enableOW
        alternateOW: root.alternateOW
        solarOW: root.solarOW
        dlcOW: root.dlcOW
        fastModeOW: root.fastModeOW
        onOwToggle: root.owToggle()
        onFastModeToggle: root.fastModeToggle()
        readonly property bool isLargeScreen: isLandscape ? root.height >= units.gu(70)
                                                          : root.width >= units.gu(70)
        // ENH032 - End

        Clock {
            id: clock
            anchors.centerIn: parent
            // ENH032 - Infographics Outer Wilds
            owThemed: root.enableOW || shell.settings.ow_ColoredClock
            owDLCThemed: root.enableOW && root.dlcOW
            largeMode: coverPage.isLargeScreen
            gradientTimeText: shell.settings.ow_GradientColoredTime && !owDLCThemed
            // ENH032 - End
            // ENH064 - Dynamic Cove
            // ENH065 - Option to hide lockscreen clock
            //visible: !shell.settings.hideLockscreenClock
            visible: !shell.settings.hideLockscreenClock && !(shell.settings.dcDigitalClockMode && coverPage.dynamicCoveClock)
            // ENH065 - End
            dateOnly: !shell.settings.dcDigitalClockMode && coverPage.dynamicCoveClock
            // ENH064 - End
        }

        // ENH032 - Infographics Outer Wilds
        Loader {
            id: owMenuLoader
            active: shell.settings.ow_mainMenu
            asynchronous: true
            anchors {
                top: clock.bottom
                left: clock.left
                right: clock.right
            }
            states: [
                State {
                    name: "landscape"
                    when: isLandscape
                    PropertyChanges {
                        target: owMenuLoader;
                        anchors.topMargin: coverPage.isLargeScreen ? units.gu(10) : units.gu(4)
                    }
                }
                , State {
                    name: "portrait"
                    when: !isLandscape
                    PropertyChanges {
                        target: owMenuLoader
                        anchors.topMargin: coverPage.isLargeScreen ? units.gu(15) : units.gu(10)
                    }
                }
            ]
            sourceComponent: Component {
                Item {
                    id: owMainMenu
                    
                    readonly property bool listIsFocused: owMainMenuList.activeFocus

                    function setFocus() {
                        owMainMenuList.forceActiveFocus()
                    }

                    function selectCurrentItem() {
                        owMainMenuList.currentItem.trigger()
                    }

                    function incrementCurrentIndex() {
                        owMainMenuList.incrementCurrentIndex()
                    }

                    function decrementCurrentIndex() {
                        owMainMenuList.decrementCurrentIndex()
                    }

                    Column {
                        spacing: coverPage.isLargeScreen ? units.gu(5) : units.gu(3)
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        Rectangle {
                            color: "#3b3a3b"
                            opacity: 0.6
                            height: units.dp(1)
                            anchors {
                                left: parent.left
                                right: parent.right
                            }    
                        }

                        ListView {
                            id: owMainMenuList
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            model: owMenuModel
                            height: contentHeight
                            keyNavigationWraps: true
                            delegate: MouseArea {
                                readonly property alias contentWidth: menuLabel.contentWidth
                                readonly property alias contentHeight: menuLabel.contentHeight
                                readonly property bool isCurrentItem: ListView.isCurrentItem
                                height: coverPage.isLargeScreen ? units.gu(8) : units.gu(4)
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                }

                                function trigger() {
                                    switch (index) {
                                        case 0: // Unlock
                                            coverPage.hide()
                                            break
                                        case 1: // Emergency
                                            root.emergencyCall()
                                            break
                                        case 2: // Options
                                            shell.showSettings()
                                            break
                                    }
                                }

                                Label {
                                    id: menuLabel
                                    text: model.title
                                    color: isCurrentItem ? "#f9e0ce" : "#ec813f"
                                    font.family: "DejaVu Sans"
                                    fontSize: coverPage.isLargeScreen ? "x-large" : "medium"
                                    font.weight: Font.DemiBold
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Keys.onEnterPressed: trigger()
                                Keys.onReturnPressed: trigger()
                                Keys.onSpacePressed: trigger()

                                onClicked: {
                                    owMainMenuList.currentIndex = index
                                    trigger()
                                }
                            }
                            highlightFollowsCurrentItem: false
                            highlight: Component {
                                Item {
                                    height: owMainMenuList.currentItem.height
                                    width: owMainMenuList.currentItem.contentWidth
                                    x: (owMainMenuList.currentItem.width / 2) - (width / 2)
                                    y: owMainMenuList.currentItem.y
                                    Behavior on y {
                                        SpringAnimation {
                                            spring: 3
                                            damping: 0.2
                                        }
                                    }
                                    Behavior on width {
                                        SpringAnimation {
                                            spring: 3
                                            damping: 0.2
                                        }
                                    }
                                    Icon {
                                        id: left
                                        asynchronous: true
                                        anchors {
                                            right: parent.left
                                            rightMargin: units.gu(1)
                                            verticalCenter: parent.verticalCenter
                                        }
                                        source: "../OuterWilds/graphics/menu_arrow.svg"
                                        color: "#f9e0ce"
                                        width: owMainMenuList.currentItem.contentHeight
                                        height: width
                                        keyColor: "#ffffff"
                                        transform: Rotation { origin.x: left.width / 2; origin.y: 0; axis { x: 0; y: 1; z: 0 } angle: 180 }
                                    }
                                    Icon {
                                        id: right
                                        asynchronous: true
                                        anchors {
                                            left: parent.right
                                            leftMargin: units.gu(1)
                                            verticalCenter: parent.verticalCenter
                                        }
                                        source: "../OuterWilds/graphics/menu_arrow.svg"
                                        color: "#f9e0ce"
                                        width: left.width
                                        height: width
                                        keyColor: "#ffffff"
                                    }
                                }
                            }
                            Connections {
                                target: shell.lpsettingsLoader
                                onActiveChanged: {
                                    if (!target.active) {
                                        owMainMenuList.forceActiveFocus()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            color: "#3b3a3b"
                            opacity: 0.6
                            height: units.dp(1)
                            anchors {
                                left: parent.left
                                right: parent.right
                            }    
                        }
                    }

                    ListModel {
                        id: owMenuModel

                        Component.onCompleted: {
                            append({
                                "title": "UNLOCK"
                            })
                            append({
                                "title": "EMERGENCY"
                            })
                            append({
                                "title": "OPTIONS"
                            })
                        }
                    }
                }
            }
        }
        // ENH032 - End

        states: [
            // ENH032 - Infographics Outer Wilds
            State {
                name: "landscape-with-infographics-ow"
                when: isLandscape && clock.owThemed
                AnchorChanges {
                    target: clock
                    anchors.top: coverPage.top
                    anchors.left: coverPage.left
                    anchors.horizontalCenter: undefined
                    anchors.verticalCenter: undefined
                }
                PropertyChanges {
                    target: clock;
                    anchors.topMargin: coverPage.isLargeScreen ? units.gu(10) + panelHeight : units.gu(4) + panelHeight
                    anchors.leftMargin: coverPage.isLargeScreen ? units.gu(15): units.gu(5)
                    anchors.centerIn: undefined
                    anchors.horizontalCenterOffset: 0 //- coverPage.width / 2 + clock.width / 2 + units.gu(8)
                }
                PropertyChanges {
                    target: coverPage
                    infographicsLeftMargin: clock.width + units.gu(8)
                }
            },
            // ENH032 - End
            State {
                name: "landscape-with-infographics"
                when: isLandscape && coverPage.showInfographic
                AnchorChanges {
                    target: clock
                    anchors.top: undefined
                    // ENH032 - Infographics Outer Wilds
                    anchors.left: undefined
                    // ENH032 - End
                    anchors.horizontalCenter: undefined
                    anchors.verticalCenter: undefined
                }
                PropertyChanges {
                    target: clock;
                    anchors.topMargin: undefined
                    // ENH032 - Infographics Outer Wilds
                    anchors.leftMargin: undefined
                    // ENH032 - End
                    anchors.centerIn: coverPage
                    anchors.horizontalCenterOffset: - coverPage.width / 2 + clock.width / 2 + units.gu(8)
                }
                PropertyChanges {
                    target: coverPage
                    infographicsLeftMargin: clock.width + units.gu(8)
                }
            },
            State {
                name: "portrait"
                when: isPortrait && coverPage.showInfographic
                AnchorChanges {
                    target: clock;
                    anchors.top: coverPage.top
                    anchors.horizontalCenter: coverPage.horizontalCenter
                    anchors.verticalCenter: undefined
                }
                PropertyChanges {
                    target: clock;
                    anchors.topMargin: units.gu(2) + panelHeight
                    anchors.centerIn: undefined
                    anchors.horizontalCenterOffset: 0
                }
                PropertyChanges {
                    target: coverPage
                    infographicsLeftMargin: 0
                }
            },
            State {
                name: "without-infographics"
                when: !coverPage.showInfographic
                AnchorChanges {
                    target: clock
                    anchors.top: undefined
                    anchors.horizontalCenter: coverPage.horizontalCenter
                    anchors.verticalCenter: coverPage.verticalCenter
                }
                PropertyChanges {
                    target: clock;
                    anchors.topMargin: 0
                    anchors.centerIn: undefined
                    anchors.horizontalCenterOffset: 0
                }
                PropertyChanges {
                    target: coverPage
                    infographicsLeftMargin: 0
                }
            }
        ]
    }

    StyledItem {
        id: bottomBar
        // ENH010 - Greeter bar enable
        // visible: usageMode == "phone" && lockscreen.shown
        // height: units.gu(4)
        visible: lockscreen.shown
        height: units.gu(6)
        // ENH010 - End

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.bottom
        anchors.topMargin: - height * (1 - coverPage.showProgress)
                           - ( inputMethodRect.height )

        Label {
            text: i18n.tr("Cancel")
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            verticalAlignment: Text.AlignVCenter
            font.weight: Font.Light
            // ENH010 - Greeter bar enable
            // fontSize: "small"
            fontSize: "medium"
            // ENH010 - End
            color: theme.palette.normal.raisedSecondaryText

            AbstractButton {
                anchors.fill: parent
                anchors.leftMargin: -units.gu(2)
                anchors.rightMargin: -units.gu(2)
                onClicked: coverPage.show()
            }
        }

        Label {
            objectName: "emergencyCallLabel"
            text: callManager.hasCalls ? i18n.tr("Return to Call") : i18n.tr("Emergency")
            anchors.right: parent.right
            anchors.rightMargin: units.gu(2)
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            verticalAlignment: Text.AlignVCenter
            font.weight: Font.Light
            // ENH010 - Greeter bar enable
            fontSize: "medium"
            // ENH010 - End
            color: theme.palette.normal.raisedSecondaryText
            // TODO: uncomment once bug 1616538 is fixed
            // visible: telepathyHelper.ready && telepathyHelper.emergencyCallsAvailable
            enabled: visible

            AbstractButton {
                anchors.fill: parent
                anchors.leftMargin: -units.gu(2)
                anchors.rightMargin: -units.gu(2)
                onClicked: root.emergencyCall()
            }
        }
    }

    states: [
        State {
            name: "phone"
            when: root.usageMode == "phone" || (root.usageMode == "tablet" && isPortrait)
            AnchorChanges {
                target: loginList;
                anchors.horizontalCenter: lockscreen.horizontalCenter;
                anchors.left: undefined;
            }
            PropertyChanges {
                target: loginList;
                anchors.leftMargin: 0;
            }
        },
        State {
            name: "tablet"
            when: root.usageMode == "tablet" && isLandscape
            AnchorChanges {
                target: loginList;
                anchors.horizontalCenter: undefined;
                anchors.left: lockscreen.left;
            }
            PropertyChanges {
                target: loginList;
                anchors.leftMargin: Math.min(lockscreen.width * 0.16, units.gu(8));
            }
        },
        State {
            name: "desktop"
            when: root.usageMode == "desktop"
            AnchorChanges {
                target: loginList;
                anchors.horizontalCenter: undefined;
                anchors.left: lockscreen.left;
            }
            PropertyChanges {
                target: loginList;
                anchors.leftMargin: Math.min(lockscreen.width * 0.16, units.gu(20));
            }
        }
    ]
}
