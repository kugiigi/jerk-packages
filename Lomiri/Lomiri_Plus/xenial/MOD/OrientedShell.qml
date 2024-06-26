/*
 * Copyright (C) 2015 Canonical, Ltd.
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
import Unity.InputInfo 0.1
import Unity.Session 0.1
import Unity.Screens 0.1
// ENH044 - Manual rotate screen with button
import Powerd 0.1
import GlobalShortcut 1.0 // has to be before Utils, because of WindowInputFilter
// ENH044 - End
import Utils 0.1
import GSettings 1.0
import "Components"
import "Rotation"
// Workaround https://bugs.launchpad.net/ubuntu/+source/unity8/+bug/1473471
import Ubuntu.Components 1.3

Item {
    id: root

    implicitWidth: units.gu(40)
    implicitHeight: units.gu(71)

    onWidthChanged: calculateUsageMode();

    DeviceConfiguration {
        id: deviceConfiguration
        name: applicationArguments.deviceName
    }

    property alias orientations: d.orientations
    property bool lightIndicators: false

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
        id: unity8Settings
        schema.id: "com.canonical.Unity8"
    }

    GSettings {
        id: oskSettings
        objectName: "oskSettings"
        schema.id: "com.canonical.keyboard.maliit"
    }

    property int physicalOrientation: Screen.orientation
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
        if (unity8Settings.usageMode === undefined)
            return; // gsettings isn't loaded yet, we'll try again in Component.onCompleted

        console.log("Calculating new usage mode. Pointer devices:", pointerInputDevices, "current mode:", unity8Settings.usageMode, "old device count", miceModel.oldCount + touchPadModel.oldCount, "root width:", root.width / units.gu(1), "height:", root.height / units.gu(1))
        if (unity8Settings.usageMode === "Windowed") {
            if (Math.min(root.width, root.height) > units.gu(60)) {
                if (pointerInputDevices === 0) {
                    // All pointer devices have been unplugged. Move to staged.
                    unity8Settings.usageMode = "Staged";
                }
            } else {
                // The display is not large enough, use staged.
                unity8Settings.usageMode = "Staged";
            }
        } else {
            if (Math.min(root.width, root.height) > units.gu(60)) {
                if (pointerInputDevices > 0 && pointerInputDevices > miceModel.oldCount + touchPadModel.oldCount) {
                    unity8Settings.usageMode = "Windowed";
                }
            } else {
                // Make sure we initialize to something sane
                unity8Settings.usageMode = "Staged";
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
    UnitySortFilterProxyModel {
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

    Screens {
        id: screens
    }

    property int orientation
    // ENH042 - Enable/disable keyboard based on orientation
    onOrientationChanged: {
        if (shell.settings.pro1_OSKOrientation) {
            if (orientation == Qt.InvertedLandscapeOrientation) {
                unity8Settings.alwaysShowOsk = false
            } else {
                unity8Settings.alwaysShowOsk = true
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
        // ENH029 - Manual orientation via rotation lock
        if (orientationLocked) {
            orientationLock.savedOrientation = physicalOrientation;
            //orientation = orientations.portrait
        } else {
            orientation = physicalOrientation;
            //orientation = orientations.landscape
        }
        // ENH029 - End
    }
    Component.onCompleted: {
        // ENH029 - Manual orientation via rotation lock
        //if (orientationLocked) {
        orientation = orientationLock.savedOrientation;
        //    orientation = orientations.portrait
        //} else {
        //    orientation = orientations.landscape
        //}
        // ENH029 - End

        calculateUsageMode();

        // We need to manually update this on startup as the binding
        // below doesn't seem to have any effect at that stage
        oskSettings.disableHeight = !shell.oskEnabled || shell.usageScenario == "desktop"
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
        target: unity8Settings
        property: "oskSwitchVisible"
        value: shell.hasKeyboard
    }

    readonly property int supportedOrientations: shell.supportedOrientations
        & (deviceConfiguration.supportedOrientations == deviceConfiguration.useNativeOrientation
                ? orientations.native_
                : deviceConfiguration.supportedOrientations)

    property int acceptedOrientationAngle: {
        if (orientation & supportedOrientations) {
            return Screen.angleBetween(orientations.native_, orientation);
        } else if (shell.orientation & supportedOrientations) {
            // stay where we are
            return shell.orientationAngle;
        } else if (angleToOrientation(shell.mainAppWindowOrientationAngle) & supportedOrientations) {
            return shell.mainAppWindowOrientationAngle;
        } else {
            // rotate to some supported orientation as we can't stay where we currently are
            // TODO: Choose the closest to the current one
            if (supportedOrientations & Qt.PortraitOrientation) {
                return Screen.angleBetween(orientations.native_, Qt.PortraitOrientation);
            } else if (supportedOrientations & Qt.LandscapeOrientation) {
                return Screen.angleBetween(orientations.native_, Qt.LandscapeOrientation);
            } else if (supportedOrientations & Qt.InvertedPortraitOrientation) {
                return Screen.angleBetween(orientations.native_, Qt.InvertedPortraitOrientation);
            } else if (supportedOrientations & Qt.InvertedLandscapeOrientation) {
                return Screen.angleBetween(orientations.native_, Qt.InvertedLandscapeOrientation);
            } else {
                // if all fails, fallback to primary orientation
                return Screen.angleBetween(orientations.native_, orientations.primary);
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
        
        UbuntuNumberAnimation {
            id: showAnimation

            running: false
            property: "opacity"
            target: rotateButton
            alwaysRunToEnd: true
            to: rotateButton.visibleOpacity
            duration: UbuntuAnimation.SlowDuration
        }

        UbuntuNumberAnimation {
            id: hideAnimation

            running: false
            property: "opacity"
            target: rotateButton
            alwaysRunToEnd: true
            to: 0
            duration: UbuntuAnimation.FastDuration
        }
        
        SequentialAnimation {
            running: rotateButton.visible
            loops: 3
            RotationAnimation {
                target: rotateButton
                duration: UbuntuAnimation.SnapDuration
                to: 0
                direction: RotationAnimation.Shortest
            }
            NumberAnimation { target: icon; duration: UbuntuAnimation.SnapDuration; property: "opacity"; to: 1 }
            PauseAnimation { duration: UbuntuAnimation.SlowDuration }
            RotationAnimation {
                target: rotateButton
                duration: UbuntuAnimation.SlowDuration
                to: root.orientationLocked ? Screen.angleBetween(root.orientation, root.physicalOrientation) : 0
                direction: RotationAnimation.Shortest
            }
            PauseAnimation { duration: UbuntuAnimation.SlowDuration }
            NumberAnimation { target: icon; duration: UbuntuAnimation.SnapDuration; property: "opacity"; to: 0 }

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
        // ENH031 - Blur behavior in Drawer
        // ENH003 - Enable dynamic blur
        // interactiveBlur: applicationArguments.interactiveBlur
        //interactiveBlur: true
        // ENH046 - Lomiri Plus Settings
        //interactiveBlur: deviceConfiguration.interactiveBlur
        interactiveBlur: settings.drawerBlur
        // ENH046 - End
        // ENH003 - End
        // ENH031 - End
        hasMouse: pointerInputDevices > 0
        hasKeyboard: keyboardsModel.count > 0
        hasTouchscreen: touchScreensModel.count > 0
        supportsMultiColorLed: deviceConfiguration.supportsMultiColorLed
        lightIndicators: root.lightIndicators

        // Since we dont have proper multiscreen support yet
        // hardcode screen count to only show osk on this screen
        // when it's the only one connected.
        // FIXME once multiscreen has landed
        oskEnabled: (!hasKeyboard && screens.count === 1) ||
                    unity8Settings.alwaysShowOsk || forceOSKEnabled

        usageScenario: {
            if (unity8Settings.usageMode === "Windowed") {
                return "desktop";
            } else {
                if (deviceConfiguration.category === "phone") {
                    return "phone";
                } else {
                    return "tablet";
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
        property bool pulledDown: false

        onPulledDownChanged: {
            if (pulledDown) {
                switch(Math.abs(transformRotationAngle)) {
                    case 0:
                        y += nativeHeight / 3
                    break
                    case 90:
                        x -= (nativeWidth / 3)
                    break
                    case 180:
                        y -= (nativeHeight / 3)
                    break
                    case 270:
                        x += (nativeWidth / 3)
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
