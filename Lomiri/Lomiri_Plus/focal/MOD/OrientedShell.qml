/*
 * Copyright (C) 2015 Canonical Ltd.
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
import QtQuick.Window 2.2 as QtQuickWindow
import Lomiri.InputInfo 0.1
import Lomiri.Session 0.1
import WindowManager 1.0
// ENH044 - Manual rotate screen with button
import Powerd 0.1
import GlobalShortcut 1.0 // has to be before Utils, because of WindowInputFilter
// ENH044 - End
import Utils 0.1
import GSettings 1.0
import "Components"
import "Rotation"
// Workaround https://bugs.launchpad.net/lomiri/+source/lomiri/+bug/1473471
import Lomiri.Components 1.3

Item {
    id: root

    implicitWidth: units.gu(40)
    implicitHeight: units.gu(71)

    property alias deviceConfiguration: _deviceConfiguration
    property alias orientations: d.orientations
    property bool lightIndicators: false

    property var screen: null
    Connections {
        target: screen
        onFormFactorChanged: calculateUsageMode();
    }

    onWidthChanged: calculateUsageMode();
    property var overrideDeviceName: Screens.count > 1 ? "desktop" : false

    DeviceConfiguration {
        id: _deviceConfiguration

        // Override for convergence to set scale etc for second monitor
        overrideName: root.overrideDeviceName
        // ENH046 - Lomiri Plus Settings
        shell: shell
        // ENH046 - End
    }

    Item {
        id: d

        property Orientations orientations: Orientations {
            id: orientations
            // NB: native and primary orientations here don't map exactly to their QScreen counterparts
            native_: root.width > root.height ? Qt.LandscapeOrientation : Qt.PortraitOrientation

            primary: deviceConfiguration.primaryOrientation == deviceConfiguration.useNativeOrientation
                ? native_ : deviceConfiguration.primaryOrientation

            landscape: deviceConfiguration.landscapeOrientation
            invertedLandscape: deviceConfiguration.invertedLandscapeOrientation
            portrait: deviceConfiguration.portraitOrientation
            invertedPortrait: deviceConfiguration.invertedPortraitOrientation
        }
    }

    GSettings {
        id: lomiriSettings
        schema.id: "com.lomiri.Shell"
    }

    GSettings {
        id: oskSettings
        objectName: "oskSettings"
        schema.id: "com.lomiri.keyboard.maliit"
    }

    property int physicalOrientation: QtQuickWindow.Screen.orientation
    property bool orientationLocked: OrientationLock.enabled
    property var orientationLock: OrientationLock

    InputDeviceModel {
        id: miceModel
        deviceFilter: InputInfo.Mouse
        property int oldCount: 0
    }

    InputDeviceModel {
        id: touchPadModel
        deviceFilter: InputInfo.TouchPad
        property int oldCount: 0
    }

    InputDeviceModel {
        id: keyboardsModel
        deviceFilter: InputInfo.Keyboard
        onDeviceAdded: forceOSKEnabled = autopilotDevicePresent();
        onDeviceRemoved: forceOSKEnabled = autopilotDevicePresent();
    }

    InputDeviceModel {
        id: touchScreensModel
        deviceFilter: InputInfo.TouchScreen
    }

    Binding {
        target: QuickUtils
        property: "keyboardAttached"
        value: keyboardsModel.count > 0
    }
    // ENH025 - Auto switch to staged workaround
    // readonly property int pointerInputDevices: miceModel.count + touchPadModel.count
    readonly property int pointerInputDevices: miceModel.count
    // ENH025 - End
    onPointerInputDevicesChanged: calculateUsageMode()

    function calculateUsageMode() {
        if (lomiriSettings.usageMode === undefined)
            return; // gsettings isn't loaded yet, we'll try again in Component.onCompleted

        console.log("Calculating new usage mode. Pointer devices:", pointerInputDevices, "current mode:", lomiriSettings.usageMode, "old device count", miceModel.oldCount + touchPadModel.oldCount, "root width:", root.width, "height:", root.height)
        if (lomiriSettings.usageMode === "Windowed") {
            if (Math.min(root.width, root.height) > units.gu(60)) {
                if (pointerInputDevices === 0) {
                    // All pointer devices have been unplugged. Move to staged.
                    lomiriSettings.usageMode = "Staged";
                }
            } else {
                // The display is not large enough, use staged.
                lomiriSettings.usageMode = "Staged";
            }
        } else {
            if (Math.min(root.width, root.height) > units.gu(60)) {
                if (pointerInputDevices > 0 && pointerInputDevices > miceModel.oldCount + touchPadModel.oldCount) {
                    lomiriSettings.usageMode = "Windowed";
                }
            } else {
                // Make sure we initialize to something sane
                lomiriSettings.usageMode = "Staged";
            }
        }
        miceModel.oldCount = miceModel.count;
        touchPadModel.oldCount = touchPadModel.count;
    }

    /* FIXME: This exposes the NameRole as a work arround for lp:1542224.
     * When QInputInfo exposes NameRole to QML, this should be removed.
     */
    property bool forceOSKEnabled: false
    property var autopilotEmulatedDeviceNames: ["py-evdev-uinput"]
    LomiriSortFilterProxyModel {
        id: autopilotDevices
        model: keyboardsModel
    }

    function autopilotDevicePresent() {
        for(var i = 0; i < autopilotDevices.count; i++) {
            var device = autopilotDevices.get(i);
            if (autopilotEmulatedDeviceNames.indexOf(device.name) != -1) {
                console.warn("Forcing the OSK to be enabled as there is an autopilot eumlated device present.")
                return true;
            }
        }
        return false;
    }

    property int orientation
    // ENH042 - Enable/disable keyboard based on orientation
    onOrientationChanged: {
        if (shell.settings.pro1_OSKOrientation) {
            if (orientation == Qt.InvertedLandscapeOrientation) {
                lomiriSettings.alwaysShowOsk = false
            } else {
                lomiriSettings.alwaysShowOsk = true
            }
        }
    }
    // ENH042 - End
    // ENH044 - Manual rotate screen with button
    GlobalShortcut { // rotate screen
        shortcut: Qt.Key_WebCam
        enabled: shell.settings.pro1_orientationToggleKey && !shell.settings.enableCameraKeyDoublePress
        onTriggered: {
            if (shell.settings.pro1_orientationToggleKey && !shell.settings.enableCameraKeyDoublePress) {
                toggleRotation()
            }
        }
    }
    function toggleRotation() {
        if (orientationLocked && Powerd.status === Powerd.On) {
            if (orientation == Qt.InvertedLandscapeOrientation) {
                orientation = Qt.PortraitOrientation
            } else {
                orientation = Qt.InvertedLandscapeOrientation
            }
        }
    }
    // ENH044 - End
    onPhysicalOrientationChanged: {
        if (!orientationLocked) {
            orientation = physicalOrientation;
            // ENH037 - Manual screen rotation button
        } else {
            // ENH046 - Lomiri Plus Settings
            if (shell.settings.orientationPrompt) {
                if (orientation !== physicalOrientation && !shell.showingGreeter) {
                    rotateButton.show()
                } else {
                    rotateButton.hide()
                }
            }
            // ENH046 - End
        // ENH037 - End
        }
    }
    onOrientationLockedChanged: {
        if (orientationLocked) {
            orientationLock.savedOrientation = physicalOrientation;
        } else {
            orientation = physicalOrientation;
        }
    }
    Component.onCompleted: {
        if (orientationLocked) {
            orientation = orientationLock.savedOrientation;
        }

        calculateUsageMode();

        // We need to manually update this on startup as the binding
        // below doesn't seem to have any effect at that stage
        oskSettings.disableHeight = !shell.oskEnabled || shell.usageScenario == "desktop"
    }

    Component.onDestruction: {
        const from_workspaces = root.screen.workspaces;
        const from_workspaces_size = from_workspaces.count;
        for (var i = 0; i < from_workspaces_size; i++) {
            const from = from_workspaces.get(i);
            WorkspaceManager.destroyWorkspace(from);
        }
    }

    // we must rotate to a supported orientation regardless of shell's preference
    property bool orientationChangesEnabled:
        (shell.orientation & supportedOrientations) === 0 ? true
                                                          : shell.orientationChangesEnabled

    Binding {
        target: oskSettings
        property: "disableHeight"
        value: !shell.oskEnabled || shell.usageScenario == "desktop"
    }

    Binding {
        target: lomiriSettings
        property: "oskSwitchVisible"
        value: shell.hasKeyboard
    }

    readonly property int supportedOrientations: shell.supportedOrientations
        & (deviceConfiguration.supportedOrientations == deviceConfiguration.useNativeOrientation
                ? orientations.native_
                : deviceConfiguration.supportedOrientations)

    // During desktop mode switches back to phone mode Qt seems to swallow
    // supported orientations by itself, not emitting them. Cause them to be emitted
    // using the attached property here.
    QtQuickWindow.Screen.orientationUpdateMask: supportedOrientations

    property int acceptedOrientationAngle: {
        if (orientation & supportedOrientations) {
            return QtQuickWindow.Screen.angleBetween(orientations.native_, orientation);
        } else if (shell.orientation & supportedOrientations) {
            // stay where we are
            return shell.orientationAngle;
        } else if (angleToOrientation(shell.mainAppWindowOrientationAngle) & supportedOrientations) {
            return shell.mainAppWindowOrientationAngle;
        } else {
            // rotate to some supported orientation as we can't stay where we currently are
            // TODO: Choose the closest to the current one
            if (supportedOrientations & Qt.PortraitOrientation) {
                return QtQuickWindow.Screen.angleBetween(orientations.native_, Qt.PortraitOrientation);
            } else if (supportedOrientations & Qt.LandscapeOrientation) {
                return QtQuickWindow.Screen.angleBetween(orientations.native_, Qt.LandscapeOrientation);
            } else if (supportedOrientations & Qt.InvertedPortraitOrientation) {
                return QtQuickWindow.Screen.angleBetween(orientations.native_, Qt.InvertedPortraitOrientation);
            } else if (supportedOrientations & Qt.InvertedLandscapeOrientation) {
                return QtQuickWindow.Screen.angleBetween(orientations.native_, Qt.InvertedLandscapeOrientation);
            } else {
                // if all fails, fallback to primary orientation
                return QtQuickWindow.Screen.angleBetween(orientations.native_, orientations.primary);
            }
        }
    }

    function angleToOrientation(angle) {
        switch (angle) {
        case 0:
            return orientations.native_;
        case 90:
            return orientations.native_ === Qt.PortraitOrientation ? Qt.InvertedLandscapeOrientation
                                                                : Qt.PortraitOrientation;
        case 180:
            return orientations.native_ === Qt.PortraitOrientation ? Qt.InvertedPortraitOrientation
                                                                : Qt.InvertedLandscapeOrientation;
        case 270:
            return orientations.native_ === Qt.PortraitOrientation ? Qt.LandscapeOrientation
                                                                : Qt.InvertedPortraitOrientation;
        default:
            console.warn("angleToOrientation: Invalid orientation angle: " + angle);
            return orientations.primary;
        }
    }

    RotationStates {
        id: rotationStates
        objectName: "rotationStates"
        orientedShell: root
        shell: shell
        shellCover: shellCover
        shellSnapshot: shellSnapshot
    }

    // ENH037 - Manual screen rotation button
    Rectangle {
        id: rotateButton

        readonly property real visibleOpacity: 0.8
        readonly property bool rotateAvailable: root.orientationLocked && root.physicalOrientation !== root.orientation
        
        z: shell.z + 1
        anchors.margins: units.gu(3)
        states: [
            State {
                when: !rotateButton.rotateAvailable
                AnchorChanges {
                    target: rotateButton
                    anchors.right: parent.left
                    anchors.top: parent.bottom
                }
            }
            , State {
                when: rotateButton.rotateAvailable && root.physicalOrientation == Qt.InvertedLandscapeOrientation
                AnchorChanges {
                    target: rotateButton
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                }
            }
            , State {
                when: rotateButton.rotateAvailable && root.physicalOrientation == Qt.LandscapeOrientation
                AnchorChanges {
                    target: rotateButton
                    anchors.right: parent.right
                    anchors.top: parent.top
                }
                PropertyChanges {
                    target: rotateButton
                    anchors.topMargin: shell.shellMargin
                }
            }
            , State {
                when: rotateButton.rotateAvailable && root.physicalOrientation == Qt.PortraitOrientation
                AnchorChanges {
                    target: rotateButton
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                }
            }
            , State {
                when: rotateButton.rotateAvailable && root.physicalOrientation == Qt.InvertedPortraitOrientation
                AnchorChanges {
                    target: rotateButton
                    anchors.left: parent.left
                    anchors.top: parent.top
                }
                PropertyChanges {
                    target: rotateButton
                    anchors.topMargin: shell.shellMargin
                }
            }
        ]
        height: units.gu(4)
        width: height
        radius: width / 2
        visible: opacity > 0
        opacity: 0 //visibleOpacity
        color: theme.palette.normal.background
        
        function show() {
            if (!visible) {
                showDelay.restart()
            }
        }
        
        function hide() {
            hideAnimation.restart()
            showDelay.stop()
        }

        Icon {
            id: icon

            implicitWidth: units.gu(3)
            implicitHeight: implicitWidth
            anchors.centerIn: parent
            name: "view-rotate"
            color: theme.palette.normal.backgroundText
         }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                rotateButton.hide()
                orientationLock.savedOrientation = root.orientation
                root.orientation = root.physicalOrientation
            }
        }
        
        LomiriNumberAnimation {
            id: showAnimation

            running: false
            property: "opacity"
            target: rotateButton
            alwaysRunToEnd: true
            to: rotateButton.visibleOpacity
            duration: LomiriAnimation.SlowDuration
        }

        LomiriNumberAnimation {
            id: hideAnimation

            running: false
            property: "opacity"
            target: rotateButton
            alwaysRunToEnd: true
            to: 0
            duration: LomiriAnimation.FastDuration
        }
        
        SequentialAnimation {
            running: rotateButton.visible
            loops: 3
            RotationAnimation {
                target: rotateButton
                duration: LomiriAnimation.SnapDuration
                to: 0
                direction: RotationAnimation.Shortest
            }
            NumberAnimation { target: icon; duration: LomiriAnimation.SnapDuration; property: "opacity"; to: 1 }
            PauseAnimation { duration: LomiriAnimation.SlowDuration }
            RotationAnimation {
                target: rotateButton
                duration: LomiriAnimation.SlowDuration
                to: root.orientationLocked ? QtQuickWindow.Screen.angleBetween(root.orientation, root.physicalOrientation) : 0
                direction: RotationAnimation.Shortest
            }
            PauseAnimation { duration: LomiriAnimation.SlowDuration }
            NumberAnimation { target: icon; duration: LomiriAnimation.SnapDuration; property: "opacity"; to: 0 }

            onFinished: rotateButton.hide()
        }

        Timer {
            id: showDelay

            running: false
            interval: 500
            onTriggered: {
                showAnimation.restart()
            }
        }

        Timer {
            id: hideDelay

            running: false
            interval: 3000
            onTriggered: rotateButton.hide()
        }
    }
    
    // ENH037 - End

    // ENH129 - Color overlay
    Loader {
        active: shell.settings.enableColorOverlay
        asynchronous: true
        z: shell.z + 1
        anchors.fill: parent
        sourceComponent: Rectangle {
            color: shell.settings.overlayColor
            opacity: shell.settings.colorOverlayOpacity
        }
    }
    // ENH129 - End

    Shell {
        id: shell
        objectName: "shell"
        width: root.width
        height: root.height
        orientation: root.angleToOrientation(orientationAngle)
        orientations: root.orientations
        nativeWidth: root.width
        nativeHeight: root.height
        mode: applicationArguments.mode
        hasMouse: pointerInputDevices > 0
        hasKeyboard: keyboardsModel.count > 0
        hasTouchscreen: touchScreensModel.count > 0
        supportsMultiColorLed: deviceConfiguration.supportsMultiColorLed
        lightIndicators: root.lightIndicators
        // ENH137 - Enable OSK based on form factor
        // Disabled for now
        oskEnabled: (!hasKeyboard && Screens.count === 1) ||
        //oskEnabled: (!hasKeyboard && (Screens.count === 1 || screen.formFactor === Screen.Phone || screen.formFactor === Screen.Tablet)) ||
        // ENH137 - End
                    lomiriSettings.alwaysShowOsk || forceOSKEnabled

        // Multiscreen support: in addition to judging by the device type, go by the screen type.
        // This allows very flexible usecases beyond the typical "connect a phone to a monitor".
        // Status quo setups:
        // - phone + external monitor: virtual touchpad on the device
        // - tablet + external monitor: dual-screen desktop
        // - desktop: Has all the bells and whistles of a fully fledged PC/laptop shell
        usageScenario: {
            // ENH136 - Separate desktop mode per screen
            // if (lomiriSettings.usageMode === "Windowed") {
            if ((haveMultipleScreens && isDesktopMode) || (!haveMultipleScreens && lomiriSettings.usageMode === "Windowed")) {
            // ENH136 - End
                return "desktop";
            } else if (deviceConfiguration.category === "phone") {
                return "phone";
            } else if (deviceConfiguration.category === "tablet") {
                return "tablet";
            } else {
                if (screen.formFactor === Screen.Tablet) {
                    return "tablet";
                } else if (screen.formFactor === Screen.Phone) {
                    return "phone";
                } else {
                    return "desktop";
                }
            }
        }

        property real transformRotationAngle
        property real transformOriginX
        property real transformOriginY

        transform: Rotation {
            origin.x: shell.transformOriginX; origin.y: shell.transformOriginY; axis { x: 0; y: 0; z: 1 }
            angle: shell.transformRotationAngle
        }
        // ENH037 - Manual screen rotation button
        onIsFullScreenChanged: {
            if (!isFullScreen && root.orientationLocked) {
                //root.orientation = orientationLock.savedOrientation
            }
        }
        // ENH037 - End
        // ENH100 - Camera button to toggle rotation and OSK
        onToggleRotation: root.toggleRotation()
        // ENH100 - End
        // ENH117 - Shell reachability
        readonly property real pullDownHeight: shell.convertFromInch(shell.settings.pullDownHeight)
        readonly property bool pullDownEnabled: shell.height >= pullDownHeight * 1.2
        property bool pulledDown: false

        onPulledDownChanged: {
            if (pulledDown) {
                let _newPos = nativeHeight - pullDownHeight
                switch(Math.abs(transformRotationAngle)) {
                    case 0:
                        y += _newPos
                    break
                    case 90:
                        x -= _newPos
                    break
                    case 180:
                        y -= _newPos
                    break
                    case 270:
                        x += _newPos
                    break
                }
            } else {
                if (transformRotationAngle == 90 || transformRotationAngle == 270) {
                    let _heightWidth = nativeHeight - nativeWidth
                    if (_heightWidth) {
                        x = -(_heightWidth / 2)
                        y = _heightWidth / 2
                    } else {
                        x = _heightWidth / 2
                        y = -(_heightWidth / 2)
                    }
                } else {
                    x = 0
                    y = 0
                }
            }
        }

        onTransformRotationAngleChanged: pulledDown = false

        Loader {
            active: shell.settings.enablePullDownGesture
            asynchronous: true
            sourceComponent: swipeHandlersComponent
            anchors.fill: parent
            anchors.bottomMargin: parent.height / 2
            z: 1000
        }

        Component {
            id: swipeHandlersComponent

            Item {
                Connections {
                    target: Powerd
                    onStatusChanged: {
                        if (target.status == Powerd.Off) {
                            shell.pulledDown = false
                        }
                    }
                }
                LPPullDownSwipeHandler {
                    id: leftPullDownSwipeArea

                    pullDownState: shell.pulledDown
                    usePhysicalUnit: true
                    width: shell.edgeSize
                    enabled: shell.pullDownEnabled
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        leftMargin: shell.shellLeftMargin
                    }

                    onTrigger: {
                        if (pullDownState) {
                            shell.pulledDown = false
                        } else {
                            shell.pulledDown = true
                        }
                    }

                    /*
                    Rectangle {
                        color: "red"
                        opacity: 0.6
                        anchors.fill: parent
                    }
                    */
                }

                LPPullDownSwipeHandler {
                    id: rightPullDownSwipeArea

                    pullDownState: shell.pulledDown
                    usePhysicalUnit: true
                    width: shell.edgeSize
                    enabled: shell.pullDownEnabled
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.right
                        rightMargin: shell.shellRightMargin
                    }

                    onTrigger: {
                        if (pullDownState) {
                            shell.pulledDown = false
                        } else {
                            shell.pulledDown = true
                        }
                    }

                    /*
                    Rectangle {
                        color: "blue"
                        opacity: 0.6
                        anchors.fill: parent
                    }
                    */
                }
            }
        }
        // ENH117 - End
    }

    Rectangle {
        id: shellCover
        color: "black"
        anchors.fill: parent
        visible: false
    }

    ItemSnapshot {
        id: shellSnapshot
        target: shell
        visible: false
        width: root.width
        height: root.height

        property real transformRotationAngle
        property real transformOriginX
        property real transformOriginY

        transform: Rotation {
            origin.x: shellSnapshot.transformOriginX; origin.y: shellSnapshot.transformOriginY;
            axis { x: 0; y: 0; z: 1 }
            angle: shellSnapshot.transformRotationAngle
        }
    }
}
