/*
 * Copyright (C) 2015-2016 Canonical Ltd.
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
import Utils 0.1

QtObject {
    id: root

    // This allows to override device name, used for convergence
    // to set screens to desktop "mode"
    property var overrideName: false

    readonly property int useNativeOrientation: -1

    readonly property alias name: priv.name;

    readonly property alias primaryOrientation: priv.primaryOrientation
    readonly property alias supportedOrientations: priv.supportedOrientations
    readonly property alias landscapeOrientation: priv.landscapeOrientation
    readonly property alias invertedLandscapeOrientation: priv.invertedLandscapeOrientation
    readonly property alias portraitOrientation: priv.portraitOrientation
    readonly property alias invertedPortraitOrientation: priv.invertedPortraitOrientation

    readonly property alias category: priv.category
    // ENH046 - Lomiri Plus Settings
    property var shell
    // ENH046 - End

    // ENH002 - Notch/Punch hole fix
    readonly property alias withNotch: priv.withNotch
    readonly property alias notchPosition: priv.notchPosition
    readonly property alias notchHeightMargin: priv.notchHeightMargin
    readonly property alias fullyHideNotchInPortrait: priv.fullyHideNotchInPortrait
    readonly property alias notchWidthMargin: priv.notchWidthMargin
    readonly property alias punchHoleWidth: priv.punchHoleWidth
    readonly property alias punchHoleHeightFromTop: priv.punchHoleHeightFromTop
    readonly property alias batteryCircle: priv.batteryCircle
    readonly property alias withRoundedCorners: priv.withRoundedCorners
    readonly property alias roundedCornerRadius: priv.roundedCornerRadius
    readonly property alias roundedCornerMargin: priv.roundedCornerMargin
    // ENH002 - End

    readonly property var deviceConfig: DeviceConfig {}

    readonly property var binding: Binding {
        target: priv
        property: "state"
        value: root.overrideName ? overrideName : deviceConfig.name
    }

    readonly property var priv: StateGroup {
        id: priv

        property int primaryOrientation: deviceConfig.primaryOrientation == Qt.PrimaryOrientation ?
                                             root.useNativeOrientation : deviceConfig.primaryOrientation

        property int supportedOrientations: deviceConfig.supportedOrientations

        property int landscapeOrientation: deviceConfig.landscapeOrientation
        property int invertedLandscapeOrientation: deviceConfig.invertedLandscapeOrientation
        property int portraitOrientation: deviceConfig.portraitOrientation
        property int invertedPortraitOrientation: deviceConfig.invertedPortraitOrientation
        property string category: deviceConfig.category
        property string name: deviceConfig.name
        property bool supportsMultiColorLed: deviceConfig.supportsMultiColorLed
        // ENH002 - Notch/Punch hole fix
        // Notch/Punchhole/Rounded corner Configuration values
        readonly property bool withNotch: notchPosition !== "none" && notchHeightMargin > 0 && notchWidthMargin > 0
        // ENH046 - Lomiri Plus Settings
        //property string notchPosition: "none" // Values: "left", "middle", "right", "none"
        property string notchPosition: { // Values: "left", "middle", "right", "none"
            if (shell) {
                switch(shell.settings.notchPosition) {
                    case 0:
                        return "none"
                    case 1:
                        return "middle"
                    case 2:
                        return "left"
                    case 3:
                        return "right"
                }
            } else {
                return "none"
            }
        }
        //property real notchHeightMargin: 0 // (fullyHideNotchInPortrait = true) Height reserved for the notch/punchhole. (fullyHideNotchInPortrait = false) height of indicator panel
        property real notchHeightMargin: shell ? shell.settings.notchHeightMargin : 0 // (fullyHideNotchInPortrait = true) Height reserved for the notch/punchhole. (fullyHideNotchInPortrait = false) height of indicator panel
        //property bool fullyHideNotchInPortrait: false // (True) Full bar where the notch is will be blank space. (False) Indicator bar height is equal to notchHeightMargin
        property bool fullyHideNotchInPortrait: shell ? (withNotch && shell.settings.fullyHideNotchInNative)
                                                      : false// (True) Full bar where the notch is will be blank space. (False) Indicator bar height is equal to notchHeightMargin
        //property real notchWidthMargin: 0 // Width reserved for punchholes located on the right. Affects indicator bar
        property real notchWidthMargin: shell ? shell.settings.notchWidthMargin : 0 // Width reserved for punchholes located on the right. Affects indicator bar
        
        // ENH036 - Use punchole as battery indicator
        //property real punchHoleWidth: 0 // Width of the actual punch hole
        //property real punchHoleHeightFromTop: 0 // Exact distance from top of the screen to bottom of the punch hole
        property real punchHoleWidth: shell ? shell.settings.punchHoleWidth : 0 // Width of the actual punch hole
        property real punchHoleHeightFromTop: shell ? shell.settings.punchHoleHeightFromTop : 0 // Exact distance from top of the screen to bottom of the punch hole
        property bool batteryCircle: false // Enable battery circle
        // ENH036 - End
        readonly property bool withRoundedCorners: roundedCornerRadius > 0
        //property real roundedCornerRadius: 0 // Radius of the rounded corners
        //property real roundedCornerMargin: 0 // Margin when there are rounded corners. Affects the indicator panel's icons and labels
        property real roundedCornerRadius: shell ? shell.settings.roundedCornerRadius : 0 // Radius of the rounded corners
        property real roundedCornerMargin: shell ? shell.settings.roundedCornerMargin : 0 // Margin when there are rounded corners. Affects the indicator panel's icons and labels
        // ENH046 - End
        // ENH002 - End

        states: [
            // ENH002 - Notch/Punch hole fix
            State {
                name: "beyond12" // Samsung S10
                PropertyChanges {
                    target: priv
                    primaryOrientation: root.useNativeOrientation
                    supportedOrientations: Qt.PortraitOrientation
                                         | Qt.InvertedPortraitOrientation
                                         | Qt.LandscapeOrientation
                                         | Qt.InvertedLandscapeOrientation
                    landscapeOrientation: Qt.LandscapeOrientation
                    invertedLandscapeOrientation: Qt.InvertedLandscapeOrientation
                    portraitOrientation: Qt.PortraitOrientation
                    invertedPortraitOrientation: Qt.InvertedPortraitOrientation
                    category: "phone"
                    name: "beyond12"
                    
                    // Notch/Punchhole/Rounded Corner values
                    notchPosition: "right"
                    notchHeightMargin: 155
                    fullyHideNotchInPortrait: false
                    notchWidthMargin: 204
                    // ENH036 - Use punchole as battery indicator
                    punchHoleWidth: 117
                    punchHoleHeightFromTop: 150
                    batteryCircle: false
                    // ENH036 - End
                    roundedCornerRadius: 270
                    roundedCornerMargin: 50
                }
            },
            State {
                name: "yggdrasil" // Volla
                PropertyChanges {
                    target: priv
                    primaryOrientation: root.useNativeOrientation
                    supportedOrientations: Qt.PortraitOrientation
                                         | Qt.InvertedPortraitOrientation
                                         | Qt.LandscapeOrientation
                                         | Qt.InvertedLandscapeOrientation
                    landscapeOrientation: Qt.LandscapeOrientation
                    invertedLandscapeOrientation: Qt.InvertedLandscapeOrientation
                    portraitOrientation: Qt.PortraitOrientation
                    invertedPortraitOrientation: Qt.InvertedPortraitOrientation
                    category: "phone"
                    name: "yggdrasil"
                    
                    // Notch/Punchhole/Rounded Corner values
                    notchPosition: "middle"
                    notchHeightMargin: 80
                    fullyHideNotchInPortrait: true
                    //punchHoleWidth: 117
                    //punchHoleHeightFromTop: 150
                    batteryCircle: false
                    roundedCornerRadius: 160
                    roundedCornerMargin: 30
                }
            },
            State {
                name: "hammerhead" // Nexus 5
                PropertyChanges {
                    target: priv
                    primaryOrientation: root.useNativeOrientation
                    supportedOrientations: Qt.PortraitOrientation
                                         | Qt.InvertedPortraitOrientation
                                         | Qt.LandscapeOrientation
                                         | Qt.InvertedLandscapeOrientation
                    landscapeOrientation: Qt.LandscapeOrientation
                    invertedLandscapeOrientation: Qt.InvertedLandscapeOrientation
                    portraitOrientation: Qt.PortraitOrientation
                    invertedPortraitOrientation: Qt.InvertedPortraitOrientation
                    category: "phone"
                    name: "hammerhead"
                }
            },
            State {
                name: "angelica" // Redmi 9C
                PropertyChanges {
                    target: priv
                    primaryOrientation: root.useNativeOrientation
                    supportedOrientations: Qt.PortraitOrientation
                                         | Qt.InvertedPortraitOrientation
                                         | Qt.LandscapeOrientation
                                         | Qt.InvertedLandscapeOrientation
                    landscapeOrientation: Qt.LandscapeOrientation
                    invertedLandscapeOrientation: Qt.InvertedLandscapeOrientation
                    portraitOrientation: Qt.PortraitOrientation
                    invertedPortraitOrientation: Qt.InvertedPortraitOrientation
                    category: "phone"
                    name: "angelica"
                    
                    // Notch/Punchhole/Rounded Corner values
                    notchPosition: "middle"
                    notchHeightMargin: 80
                    fullyHideNotchInPortrait: true
                    roundedCornerRadius: 135
                    roundedCornerMargin: 25
                }
            },
            // ENH002 - End
            State {
                name: "mako"
                PropertyChanges {
                    target: priv
                    primaryOrientation: root.useNativeOrientation
                    supportedOrientations: Qt.PortraitOrientation
                                         | Qt.LandscapeOrientation
                                         | Qt.InvertedLandscapeOrientation
                    landscapeOrientation: Qt.LandscapeOrientation
                    invertedLandscapeOrientation: Qt.InvertedLandscapeOrientation
                    portraitOrientation: Qt.PortraitOrientation
                    invertedPortraitOrientation: Qt.InvertedPortraitOrientation
                    category: "phone"
                    name: "mako"
                }
            },
            State {
                name: "krillin"
                PropertyChanges {
                    target: priv
                    primaryOrientation: root.useNativeOrientation
                    supportedOrientations: Qt.PortraitOrientation
                                         | Qt.LandscapeOrientation
                                         | Qt.InvertedLandscapeOrientation
                    landscapeOrientation: Qt.LandscapeOrientation
                    invertedLandscapeOrientation: Qt.InvertedLandscapeOrientation
                    portraitOrientation: Qt.PortraitOrientation
                    invertedPortraitOrientation: Qt.InvertedPortraitOrientation
                    category: "phone"
                    name: "krillin"
                }
            },
            State {
                name: "arale"
                PropertyChanges {
                    target: priv
                    primaryOrientation: root.useNativeOrientation
                    supportedOrientations: Qt.PortraitOrientation
                                         | Qt.InvertedPortraitOrientation
                                         | Qt.LandscapeOrientation
                                         | Qt.InvertedLandscapeOrientation
                    landscapeOrientation: Qt.LandscapeOrientation
                    invertedLandscapeOrientation: Qt.InvertedLandscapeOrientation
                    portraitOrientation: Qt.PortraitOrientation
                    invertedPortraitOrientation: Qt.InvertedPortraitOrientation
                    supportsMultiColorLed: false
                    category: "phone"
                    name: "arale"
                }
            },
            State {
                name: "manta"
                PropertyChanges {
                    target: priv
                    primaryOrientation: root.useNativeOrientation
                    supportedOrientations: Qt.PortraitOrientation
                                         | Qt.InvertedPortraitOrientation
                                         | Qt.LandscapeOrientation
                                         | Qt.InvertedLandscapeOrientation
                    landscapeOrientation: Qt.LandscapeOrientation
                    invertedLandscapeOrientation: Qt.InvertedLandscapeOrientation
                    portraitOrientation: Qt.PortraitOrientation
                    invertedPortraitOrientation: Qt.InvertedPortraitOrientation
                    category: "tablet"
                    name: "manta"
                }
            },
            State {
                name: "flo"
                PropertyChanges {
                    target: priv
                    primaryOrientation: Qt.InvertedLandscapeOrientation
                    supportedOrientations: Qt.PortraitOrientation
                                         | Qt.InvertedPortraitOrientation
                                         | Qt.LandscapeOrientation
                                         | Qt.InvertedLandscapeOrientation
                    landscapeOrientation: Qt.InvertedLandscapeOrientation
                    invertedLandscapeOrientation: Qt.LandscapeOrientation
                    portraitOrientation: Qt.PortraitOrientation
                    invertedPortraitOrientation: Qt.InvertedPortraitOrientation
                    category: "tablet"
                    name: "flo"
                }
            },
            State {
                name: "desktop"
                PropertyChanges {
                    target: priv
                    primaryOrientation: root.useNativeOrientation
                    supportedOrientations: root.useNativeOrientation
                    landscapeOrientation: Qt.LandscapeOrientation
                    invertedLandscapeOrientation: Qt.InvertedLandscapeOrientation
                    portraitOrientation: Qt.PortraitOrientation
                    invertedPortraitOrientation: Qt.InvertedPortraitOrientation
                    category: "desktop"
                    name: "desktop"
                }
            },
            State {
                name: "turbo"
                PropertyChanges {
                    target: priv
                    supportsMultiColorLed: false
                }
            }
        ]
    }
}
