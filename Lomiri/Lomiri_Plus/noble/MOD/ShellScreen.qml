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
import Lomiri.Components 1.3
import WindowManager 1.0
import Cursor 1.1
import "Components"
// ENH112 - Settings for external display
import Qt.labs.settings 1.0
// ENH112 - End

ScreenWindow {
    id: screenWindow

    color: "black"
    title: "Lomiri Shell"

    property int screenIndex: -1
    readonly property bool primary: {
        // If this is the only screen then it's the primary one
        if (Screens.count === 1)
            return true;

        // ENH112 - Settings for external display
        // if ((deviceConfiguration.category == "phone" || deviceConfiguration.category == "tablet")
        //      && Screens.count > 1 && screenIndex === 1)
        // if (deviceConfiguration.category == "phone" && Screens.count > 1 && screenIndex === 1)
        if ((deviceConfiguration.category == "phone" || deviceConfiguration.category == "tablet")
                && Screens.count > 1
                && ((isMirrored && screenIndex === 0) || (!isMirrored && screenIndex === 1))
            )
        // ENH112 - End
            return true;

        return (Screens.count > 1 && screenIndex === 0)
    }

    DeviceConfiguration {
        id: deviceConfiguration
    }

    // ENH112 - Settings for external display
    property bool isMultiDisplay: settingsObj ? settingsObj.value("externalDisplayBehavior", 0) == 1 : false
    property bool isMirrored: settingsObj ? settingsObj.value("externalDisplayBehavior", 0) == 2 : false
    readonly property var loadedContent: loader.item
    Settings {
        id: settingsObj

        category: "lomiriplus"
    }
    Component.onCompleted: {
        if (isMirrored) {
            console.log("BAKIT AYAW???????? " + screenIndex + " - " + screen.active + " - " + primary)
            screen.active = screenIndex == 0
        }
    }
    // Tries to make it take effect without rebooting
    Connections {
        target: Screens
        function onCountChanged() {
            screenWindow.isMultiDisplay = Qt.binding( function() { return settingsObj ? settingsObj.value("externalDisplayBehavior", 0) == 1 : false } )
            screenWindow.isMirrored = Qt.binding( function() { return settingsObj ? settingsObj.value("externalDisplayBehavior", 0) == 2 : false } )
        }
    }
    // ENH112 - End

    Loader {
        id: loader
        width: screenWindow.width
        // ENH157 - Bottom swipe workaround for some devices
        property bool useBottomSwipeFix: settingsObj ? settingsObj.value("enableBottomSwipeDeviceFix", 0) == "true"
                                                        || settingsObj.value("enableBottomSwipeDeviceFix", 0) == true
                                                    : false
        // height: screenWindow.height
        states: [
            State {
                name: "normal"
                when: !loader.useBottomSwipeFix
                PropertyChanges {
                    target: loader
                    height: screenWindow.height
                    anchors.topMargin: 0
                }
                AnchorChanges {
                    target: loader
                    anchors.top: undefined
                    anchors.bottom: undefined
                }
            }
            , State {
                name: "bottomSwipeFix"
                when: loader.useBottomSwipeFix
                PropertyChanges {
                    target: loader
                    height: screenWindow.height + units.dp(1)
                }
                AnchorChanges {
                    target: loader
                    //anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }
            }
        ]
        // ENH157 - End

        sourceComponent: {
            // ENH112 - Settings for external display
            // if ((deviceConfiguration.category == "phone" || deviceConfiguration.category == "tablet")
            //      && Screens.count > 1 && screenIndex === 0) {
            if (!screenWindow.isMultiDisplay && (deviceConfiguration.category == "phone" || deviceConfiguration.category == "tablet")
                    && Screens.count > 1
                    && ((screenWindow.isMirrored && screenIndex === 1) || (!screenWindow.isMirrored && screenIndex === 0))
                ) {

                if (screenWindow.isMirrored && screenIndex === 1) {
                    return mirroredScreenComponent;
                }
                // ENH112 - End
                return disabledScreenComponent;
            }

            return shellComponent;
        }
    }

    Component {
        id: shellComponent
        OrientedShell {
            implicitWidth: screenWindow.width
            implicitHeight: screenWindow.height
            screen: screenWindow.screen
            visible: true
            // ENH157 - Bottom swipe workaround for some devices
            onPhysicalOrientationChanged: {
                loader.useBottomSwipeFix = settingsObj ? settingsObj.value("enableBottomSwipeDeviceFix", 0) == "true"
                                                            || settingsObj.value("enableBottomSwipeDeviceFix", 0) == true
                                                        : false
            }
            // ENH157 - End

            deviceConfiguration {
                // ENH136 - Separate desktop mode per screen
                // overrideName: Screens.count > 1 ? "desktop" : false
                overrideName: Screens.count > 1 && !screenWindow.primary ? "desktop" : false
                // ENH136 - End
            }
        }
    }

    Component {
        id: disabledScreenComponent
        DisabledScreenNotice {
            screen: screenWindow.screen
            oskEnabled: Screens.count > 1
        }
    }
    // ENH112 - Settings for external display
    Component {
        id: mirroredScreenComponent
        
        ShaderEffectSource {
            id: previewShader

            property var screen: screenWindow.screen
            sourceItem: parent
            implicitWidth: screenWindow.width
            implicitHeight: screenWindow.height
            sourceRect: sourceItem ? Qt.rect(0, 0, sourceItem.width, sourceItem.height)
                                    : Qt.rect(0, 0, 0, 0)
            
            Label {
                text: "Mirror move!!!!!!!"
                anchors.centerIn: parent
            }
        }
    }
    // ENH112 - End
}
