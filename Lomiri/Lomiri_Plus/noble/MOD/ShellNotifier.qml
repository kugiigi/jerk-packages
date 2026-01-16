/*
 * Copyright (C) 2016 Canonical Ltd.
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

/*
    Shared signals & properties on multi-window desktop
 */

pragma Singleton
import QtQuick 2.15

QtObject {
    property var greeter: QtObject {
        signal hide(bool now)

        property bool shown: true
    }
    // ENH224 - Brightness control in Virtual Touchpad mode
    property bool oskDisplayedInTouchpad: false
    // ENH224 - End
    // ENH141 - Air mouse in virtual touchpad

    //************** From Touchpad to Shell ************** 
    property bool inAirMouseMode: false
    signal switchToPrevApp
    signal showSpread
    signal showDrawer(bool search)
    signal toggleQuickActions(bool fromMouse)
    signal selectQuickAction
    signal normalHaptics
    signal subtleHaptics
    // ENH243 - Virtual Touchpad Enhancements
    signal switchWorkspaceRight
    signal switchWorkspaceRightMoveApp
    signal switchWorkspaceLeft
    signal switchWorkspaceLeftMoveApp
    signal commitWorkspaceSwitch
    signal getAppToDrag
    signal toggleSideStage
    signal toggleIndicators
    signal hintMoveAppToSideStage
    signal hintMoveAppToMainStage
    signal commitAppSwitchStage(bool toTheSideStage)
    signal cancelMoveToStage

    signal dragReleased(var appDelegate)

    // TODO: I think these are not actually used
    // Remove these and relevant codes
    // in the future once confirmed these are not used anymore
    signal fakeMaximizeAnimationRequested(var appDelegate, real amount)
    signal fakeMaximizeLeftAnimationRequested(var appDelegate, real amount)
    signal fakeMaximizeRightAnimationRequested(var appDelegate, real amount)
    signal fakeMaximizeTopLeftAnimationRequested(var appDelegate, real amount)
    signal fakeMaximizeTopRightAnimationRequested(var appDelegate, real amount)
    signal fakeMaximizeBottomLeftAnimationRequested(var appDelegate, real amount)
    signal fakeMaximizeBottomRightAnimationRequested(var appDelegate, real amount)
    signal stopFakeAnimation()
    // ENH243 - End

    //************** From Shell to Touchpad **************
    property bool enableAirMouse: false
    property bool enableCustomClickBehavior: false
    property bool enableCustomOneTwoGestureBehavior: false
    property bool enableVirtualTouchpadScrollWorkaround: false
    property bool airMouseAlwaysActive: false
    property bool enableSideGestures: false
    property int sideMouseScrollPosition: 0
    property bool enableSideMouseScrollHaptics: false
    property bool invertSideMouseScroll: false
    property bool invertMouseScroll: false
    property real sideMouseScrollSensitivity: 1
    property real airMouseSensitivity: 1
    property real sideGesturesWidth: 2
    property bool hideBottomButtons: false
    property bool hideBottomButtonsOnlyAirMouse: false

    property real quickActionsHeight: 1
    property real quickActionsSideMargins: 20
    property var quickActionsSwipeArea: null

    // ENH243 - Virtual Touchpad Enhancements
    property bool enableAdvancedGestures: false
    property bool enableVirtualTouchpadLowerClickThreshold: false
    property real virtualTouchpadScrollSensitivity: 1
    property bool inWindowedMode: false
    property bool workspaceEnabled: false
    property Item appForDragging: null
    property bool appDragGestureIsActive: false
    readonly property bool appIsBeingDragged: appForDragging !== null && appDragGestureIsActive
    property Item availableDesktopArea: null
    property real dragWindowSensitivity: 1
    property real cursorX: 0
    property real cursorY: 0
    readonly property point cursorPoint: Qt.point(cursorX, cursorY)
    // ENH243 - End

    signal leftClick
    signal rightClick
    signal leftPress
    signal rightPress
    signal leftRelease
    signal rightRelease
    // ENH141 - End
}
