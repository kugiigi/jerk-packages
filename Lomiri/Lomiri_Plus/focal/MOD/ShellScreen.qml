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

import QtQuick 2.12
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

        if (deviceConfiguration.category == "phone" && Screens.count > 1 && screenIndex === 1)
            return true;

        return (Screens.count > 1 && screenIndex === 0)
    }

    DeviceConfiguration {
        id: deviceConfiguration
    }

    // ENH112 - Settings for external display
    property bool isMultiDisplay: settingsObj ? settingsObj.value("externalDisplayBehavior", 0) > 0 : false
    Settings {
        id: settingsObj

        category: "lomiriplus"
    }
    // Tries to make it take effect without rebooting
    Connections {
        target: Screens
        onCountChanged: {
            screenWindow.isMultiDisplay = Qt.binding( function() { return settingsObj ? settingsObj.value("externalDisplayBehavior", 0) > 0 : false } )
        }
    }
    // ENH112 - End

    Loader {
        id: loader
        width: screenWindow.width
        height: screenWindow.height

        sourceComponent: {
            // ENH112 - Settings for external display
            // if (deviceConfiguration.category == "phone" && Screens.count > 1 && screenIndex === 0) {
            if (!screenWindow.isMultiDisplay && deviceConfiguration.category == "phone" && Screens.count > 1 && screenIndex === 0) {
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
}
