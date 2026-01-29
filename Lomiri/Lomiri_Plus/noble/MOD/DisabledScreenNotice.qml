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

import QtQuick 2.15
import QtQuick.Layouts 1.1
import Lomiri.Components 1.3
import Lomiri.Session 0.1
import QtQuick.Window 2.2
import WindowManager 1.0
import "Components"
// ENH241 - Rotate button in Virtual Touchpad
import QtSensors 5.15
// ENH241 - End

Item {
    id: root

    property var screen: null
    property var orientationLock: OrientationLock
    property alias overrideDeviceName: root.deviceConfiguration.overrideName

    property bool oskEnabled: false

    property alias deviceConfiguration: _deviceConfiguration
    DeviceConfiguration {
        id: _deviceConfiguration
    }

    Item {
        id: contentContainer
        objectName: "contentContainer"
        anchors.centerIn: parent
        height: rotation == 90 || rotation == 270 ? parent.width : parent.height
        width: rotation == 90 || rotation == 270 ? parent.height : parent.width

        property int savedOrientation: deviceConfiguration.primaryOrientation == deviceConfiguration.useNativeOrientation
                                       ? (root.width > root.height ? Qt.LandscapeOrientation : Qt.PortraitOrientation)
                                       : deviceConfiguration.primaryOrientation

        // ENH241 - Rotate button in Virtual Touchpad
        /*
        rotation: {
            var usedOrientation = root.screen.orientation;

            if (root.orientationLock.enabled) {
                usedOrientation = savedOrientation;
            }

            savedOrientation = usedOrientation;

            switch (usedOrientation) {
            case Qt.PortraitOrientation:
                return 0;
            case Qt.LandscapeOrientation:
                return 270;
            case Qt.InvertedPortraitOrientation:
                return 180;
            case Qt.InvertedLandscapeOrientation:
                return 90;
            }

            return 0;
        }
        */
        readonly property int angleFromPrimary: Screen.angleBetween(Screen.primaryOrientation, Screen.orientation)

        // Rotate based on the current physical orientation of the device
        function rotate() {
            // Rotate manually if the device is facing up
            // So we don't need to rotate the device physically
            // which might cause issue with the USB connection
            if (orientationSensor.reading.orientation === OrientationReading.FaceUp) {
                if (rotation === 270) {
                    rotation = 0
                } else {
                    rotation += 90
                }
            } else {
                rotation = angleFromPrimary
            }
        }
         OrientationSensor {
             id: orientationSensor
             active: true
         }
        // ENH241 - End
        transformOrigin: Item.Center

        Rectangle {
            anchors.fill: parent
            color: LomiriColors.jet
        }

        VirtualTouchPad {
            objectName: "virtualTouchPad"
            anchors.fill: parent
            oskEnabled: root.oskEnabled
            // ENH241 - Rotate button in Virtual Touchpad
            id: virtualTouchPad
            contentRotation: contentContainer.rotation
            onRotate: contentContainer.rotate()
            // ENH241 - End
        }
    }
}
