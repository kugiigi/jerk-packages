/*
 * Copyright (C) 2014-2016 Canonical Ltd.
 * Copyright (C) 2020 UBports Foundation
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
import Lomiri.Gestures 0.1
import "../Components"
import "Indicators"
// ENH056 - Quick toggles
import QtQuick.Layouts 1.12
import Lomiri.Components.ListItems 1.3 as ListItems
// ENH056 - End

Showable {
    id: root
    property alias model: bar.model
    property alias showDragHandle: __showDragHandle
    property alias hideDragHandle: __hideDragHandle
    property alias overFlowWidth: bar.overFlowWidth
    property alias verticalVelocityThreshold: yVelocityCalculator.velocityThreshold
    property int minimizedPanelHeight: units.gu(3)
    property int expandedPanelHeight: units.gu(7)
    property real openedHeight: units.gu(71)
    property bool enableHint: true
    property bool showOnClick: true
    // ENH111 - Blurred expanded top panel
    // property color panelColor: theme.palette.normal.background
    // ENH166 - Panel appearance settings
    readonly property color customPanelColor: shell.settings.useCustomIndicatorPanelColor ? shell.settings.customIndicatorPanelColor : "#000000"
    readonly property real colorOpacity: shell.settings.useCustomIndicatorPanelOpacity ? shell.settings.customIndicatorPanelOpacity : 0.85
    readonly property bool useCustomColorAndOpacity: shell.settings.useCustomIndicatorPanelColor || shell.settings.useCustomIndicatorPanelOpacity
    // property color panelColor: lightMode ? "#FFFFFF" : "#000000"
    property color panelColor: useCustomColorAndOpacity ? Qt.hsla(customPanelColor.hslHue, customPanelColor.hslSaturation, customPanelColor.hslLightness, colorOpacity)
                : lightMode ? "#FFFFFF" : "#000000"
    // ENH166 - End
    // ENH111 - End
    property real menuContentX: 0

    property alias alignment: bar.alignment
    property alias hideRow: bar.hideRow
    property alias rowItemDelegate: bar.rowItemDelegate
    property alias pageDelegate: content.pageDelegate
    // ENH002 - Notch/Punch hole fix
    property alias contentRightMargin: bar.contentRightMargin
    property alias contentLeftMargin: bar.contentLeftMargin
    property real leftMarginBlur
    property real topMarginBlur
    // ENH002 - End
    // ENH028 - Open indicators via gesture
    property bool inverted: false
    property string currentTitle
    property real panelOpacity: 1
    property int initialIndexOnInverted: -1
    // ENH028 - End
    // ENH056 - Quick toggles
    readonly property bool quickTogglesExpanded: quickToggles.expanded
    property string wifiIcon: "network-wifi-symbolic"
    property string bluetoothIcon: "bluetooth-active"
    property bool enableQuickToggles: false
    property var rotationToggle
    property var flashlightToggle
    property var autoDarkModeToggle
    property var darkModeToggle
    property var desktopModeToggle
    property var silentModeToggle
    property var flightModeToggle
    property var mobileDataToggle
    property var wifiToggle
    property var bluetoothToggle
    property var locationToggle
    property var immersiveToggle
    property var hotspotToggle
    property var autoBrightnessToggle
    property var brightnessSlider
    property var volumeSlider

    function expandCollapseQuickToggles(_expand) {
        quickToggles.expanded = _expand
    }
    // ENH056 - End
    // ENH028 - Open indicators via gesture
    property var dateItem
    property var lockItem
    // ENH028 - End
    // ENH139 - System Direct Actions
    readonly property alias quickToggleItems: quickToggles.toggleItems
    // ENH139 - End

    property var blurSource : null
    property rect blurRect : Qt.rect(0, 0, 0, 0)
    property bool lightMode : false

    readonly property real unitProgress: Math.max(0, (height - minimizedPanelHeight) / (openedHeight - minimizedPanelHeight))
    readonly property bool fullyOpened: unitProgress >= 1
    readonly property bool partiallyOpened: unitProgress > 0 && unitProgress < 1.0
    readonly property bool fullyClosed: unitProgress == 0
    readonly property alias expanded: bar.expanded
    readonly property int barWidth: bar.width
    readonly property alias currentMenuIndex: bar.currentItemIndex

    // Exposes the current contentX of the PanelBar's internal ListView. This
    // must be used to offset absolute x values against the ListView, since
    // we commonly add or remove elements and cause the contentX to change.
    readonly property int rowContentX: bar.rowContentX

    // The user tapped the panel and did not move.
    // Note that this does not fire on mouse events, only touch events.
    signal showTapped()

    // TODO: Perhaps we need a animation standard for showing/hiding? Each showable seems to
    // use its own values. Need to ask design about this.
    showAnimation: SequentialAnimation {
        StandardAnimation {
            target: root
            property: "height"
            to: openedHeight
            duration: LomiriAnimation.BriskDuration
            easing.type: Easing.OutCubic
        }
        // set binding in case units.gu changes while menu open, so height correctly adjusted to fit
        ScriptAction { script: root.height = Qt.binding( function(){ return root.openedHeight; } ) }
    }

    hideAnimation: SequentialAnimation {
        StandardAnimation {
            target: root
            property: "height"
            to: minimizedPanelHeight
            duration: LomiriAnimation.BriskDuration
            easing.type: Easing.OutCubic
        }
        // set binding in case units.gu changes while menu closed, so menu adjusts to fit
        ScriptAction { script: root.height = Qt.binding( function(){ return root.minimizedPanelHeight; } ) }
    }

    shown: false
    height: minimizedPanelHeight

    onUnitProgressChanged: d.updateState()

    BackgroundBlur {
        // ENH002 - Notch/Punch hole fix
        // x: 0
        // y: 0
        x: 0 - root.leftMarginBlur
        y: 0 - root.topMarginBlur
        // ENH002 - End
        width: root.blurRect.width
        height: root.blurRect.height
        visible: root.height > root.minimizedPanelHeight
        sourceItem: root.blurSource
        blurRect: root.blurRect
        occluding: false
    }

    // ENH028 - Open indicators via gesture
    onFullyClosedChanged: {
        if (fullyClosed) {
            inverted = false
            // ENH056 - Quick toggles
            quickToggles.editMode = false
            if (shell.settings.autoCollapseQuickToggles) {
                quickToggles.expanded = false
            }
            // ENH056 - End
        }
    }

    function openAsInverted(indicatorIndex, openInverted = true) {
        inverted = openInverted

        if (indicatorIndex == -1) {
            if (initialIndexOnInverted > -1) {
                bar.setCurrentItemIndex(initialIndexOnInverted)
            } else {
                if (currentMenuIndex >= root.model.count || currentMenuIndex < 0) {
                    bar.setCurrentItemIndex(0)
                } else {
                    bar.setCurrentItemIndex(currentMenuIndex)
                }
            }
        } else {
            bar.setCurrentItemIndex(indicatorIndex)
        }
        show()
    }
    // ENH028 - End

    Item {
        // ENH056 - Quick toggles
        id: menuContainer
        // ENH056 - End
        anchors {
            left: parent.left
            right: parent.right
            // ENH028 - Open indicators via gesture
            // top: bar.bottom
            // bottom: parent.bottom
            // ENH056 - Quick toggles
            //top: root.inverted ? parent.top : bar.bottom
            //bottom: root.inverted ? bar.top : parent.bottom
            // ENH056 - End
            // ENH028 - End
        }
        clip: root.partiallyOpened

        Rectangle {
            // ENH166 - Panel appearance settings
            // color: Qt.rgba(root.panelColor.r,
            //                root.panelColor.g,
            //                root.panelColor.b,
            //                1.0)
            color: root.useCustomColorAndOpacity ? root.panelColor
                   : Qt.rgba(root.panelColor.r,
                           root.panelColor.g,
                           root.panelColor.b,
                           1.0)
            // opacity: 0.85
            opacity: root.useCustomColorAndOpacity ? 1 : 0.85
            // ENH166 - End
            anchors.fill: parent
        }

        // eater
        MouseArea {
            anchors.fill: content
            // ENH056 - Quick toggles
            // hoverEnabled: true
            hoverEnabled: enabled
            // ENH056 - End
            acceptedButtons: Qt.AllButtons
            onWheel: wheel.accepted = true;
            enabled: root.state != "initial"
            visible: content.visible
        }

        // ENH056 - Quick toggles
        MouseArea {
            id: quickToggles

            readonly property real swipeThreshold: units.gu(5)
            readonly property real toggleHeight: units.gu(6)
            readonly property real rowHeight: quickToggles.toggleHeight + units.gu(3)
            readonly property real rowMargins: gridLayout.anchors.margins * 2
            readonly property bool multiRows: rowHeight + rowMargins !== gridLayout.height + rowMargins
            readonly property real expandedHeight: Math.min(gridLayout.height + rowMargins, root.height - bar.height - handle.height)
            readonly property real collapsedHeight: {
                if (shell.settings.quickTogglesCollapsedRowCount > 1 && root.height > units.gu(60)) {
                    let _availableRows = Math.floor(gridLayout.height / rowHeight)
                    let _multiplier = Math.min(_availableRows - 1, shell.settings.quickTogglesCollapsedRowCount) // Do not allow full rows as collapsed rows
                    return (rowHeight * _multiplier) + rowMargins
                } else {
                    return rowHeight + rowMargins
                }
            }

            property bool editMode: false
            property bool expanded: false

            readonly property var toggleItems: [
                /* Rotation */          {"identifier": "rotation", "text": "Screen Rotation", "type": 0, "controlType": "toggle", "slot": 1, "toggleObj": root.rotationToggle, "holdActionType": "indicator", "holdActionUrl": ""
                                        , "iconOn": "orientation-lock", "iconOff": "view-rotate"}                                 
                /* Flashlight */        , {"identifier": "flashlight", "text": "Flashlight", "type": 1, "controlType": "toggle", "slot": 1, "toggleObj": root.flashlightToggle, "holdActionType": "indicator", "holdActionUrl": ""
                                        , "iconOn": "torch-on", "iconOff": "torch-off"}                                     
                // ENH116 - Standalone Dark mode toggle
                // /* Dark mode */         , {"identifier": "test", "text": "test", "type": 2, "controlType": "toggle", "slot": 1, "toggleObj": root.darkModeToggle, "holdActionType": "indicator", "holdActionUrl": ""
                /* Dark mode */         , {"identifier": "darkmode", "text": "Dark Mode", "type": 2, "controlType": "toggle", "slot": 1, "toggleObj": root.darkModeToggle ? root.darkModeToggle : darkModeToggle
                                        , "holdActionType": "indicator", "holdActionUrl": ""
                // ENH116 - End
                                        , "iconOn": "weather-clear-night-symbolic", "iconOff": "night-mode"}
                                        // ENH136 - Separate desktop mode per screen             
                /* Desktop mode */      //, {"identifier": "test", "text": "test", "type": 3, "controlType": "toggle", "slot": 1, "toggleObj": root.desktopModeToggle, "holdActionType": "indicator", "holdActionUrl": ""
                /* Desktop mode */      , {"identifier": "desktopmode", "text": "Desktop Mode", "type": 3, "controlType": "toggle", "slot": 1, "toggleObj": shell.haveMultipleScreens ? shellDesktopModeToggle : root.desktopModeToggle, "holdActionType": "indicator", "holdActionUrl": ""
                                        // ENH136 - End
                                        , "iconOn": "computer-symbolic", "iconOff": "phone-smartphone-symbolic"}        
                /* Silent mode */       , {"identifier": "silentmode", "text": "Silent Mode", "type": 4, "controlType": "toggle", "slot": 1, "toggleObj": root.silentModeToggle, "holdActionType": "indicator", "holdActionUrl": ""
                                        , "iconOn": "audio-speakers-muted-symbolic", "iconOff": "audio-speakers-symbolic"} 
                /* Flight mode */       , {"identifier": "flightmode", "text": "Flight Mode", "type": 5, "controlType": "toggle", "slot": 1, "toggleObj": root.flightModeToggle, "holdActionType": "indicator", "holdActionUrl": ""
                                        , "iconOn": "airplane-mode", "iconOff": "airplane-mode-disabled"}                  
                /* Mobile data */       , {"identifier": "mobiledata", "text": "Mobile Data", "type": 6, "controlType": "toggle", "slot": 1, "toggleObj": root.mobileDataToggle, "holdActionType": "external"
                                        , "holdActionUrl": "settings:///system/cellular"
                                        , "iconOn": "transfer-progress", "iconOff": "transfer-none"}                       
                /* Wifi */              , {"identifier": "wifi", "text": "Wi-Fi", "type": 7, "controlType": "toggle", "slot": 1, "toggleObj": root.wifiToggle, "holdActionType": "indicator", "holdActionUrl": ""
                                        , "iconOn": root.wifiIcon, "iconOff": "wifi-none"}                                
                /* Bluetooth */         , {"identifier": "bluetooth", "text": "Bluetooth", "type": 8, "controlType": "toggle", "slot": 1, "toggleObj": root.bluetoothToggle, "holdActionType": "indicator"
                                        , "holdActionUrl": "settings:///system/bluetooth"
                                        , "iconOn": root.bluetoothIcon, "iconOff": "bluetooth-disabled"}
                /* Location */          , {"identifier": "location", "text": "Location", "type": 9, "controlType": "toggle", "slot": 1, "toggleObj": root.locationToggle, "holdActionType": "external"
                                        , "holdActionUrl": "settings:///system/location"
                                        , "iconOn": "location-idle", "iconOff": "location-disabled"}
                // ENH115 - Standalone Immersive mode
                // /* Immersive */         , {"identifier": "test", "text": "test", "type": 10, "controlType": "toggle", "slot": 1, "toggleObj": root.immersiveToggle, "holdActionType": "indicator", "holdActionUrl": ""
                /* Immersive */         , {"identifier": "immersive", "text": "Immersive Mode", "type": 10, "controlType": "toggle", "slot": 1, "toggleObj": root.immersiveToggle ? root.immersiveToggle : immersiveModeToggle
                // ENH115 - End
                                        , "holdActionType": "indicator", "holdActionUrl": ""
                                        , "iconOn": "media-record", "iconOff": "media-optical-symbolic"}
                /* Hotspot */           , {"identifier": "hotspot", "text": "Hotspot", "type": 11, "controlType": "toggle", "slot": 1, "toggleObj": root.hotspotToggle, "holdActionType": "external"
                                        , "holdActionUrl": "settings:///system/hotspot"
                                        , "iconOn": "hotspot-connected", "iconOff": "hotspot-disabled"}     
                /* Auto brightness */   , {"identifier": "auto-brightness", "text": "Auto-Brightness", "type": 12, "controlType": "toggle", "slot": 1, "toggleObj": root.autoBrightnessToggle, "holdActionType": "indicator", "holdActionUrl": ""
                                        , "iconOn": "display-brightness-symbolic", "iconOff": "display-brightness-min"}
                // ENH116 - Standalone Dark mode toggle
                // /* Auto Dark mode */    , {"identifier": "test", "text": "test", "type": 13, "controlType": "toggle", "slot": 1, "toggleObj": root.autoDarkModeToggle, "holdActionType": "indicator", "holdActionUrl": ""
                /* Auto Dark mode */    , {"identifier": "autodarkmode", "text": "Auto Dark Mode", "type": 13, "controlType": "toggle", "slot": 1, "toggleObj": root.autoDarkModeToggle ? root.autoDarkModeToggle : autoDarkModeToggle
                                        , "holdActionType": "indicator", "holdActionUrl": ""
                // ENH116 - End
                                        , "iconOn": "weather-few-clouds-night-symbolic", "iconOff": "weather-few-clouds-night-symbolic"}            
                /* Media Player */      , {"identifier": "mediaplayer", "text": "Media Player", "type": 14, "controlType": "media", "slot": 0, "toggleObj": { parentMenuIndex: root.silentModeToggle ? root.silentModeToggle.parentMenuIndex : -1 }, "holdActionType": "indicator", "holdActionUrl": ""
                                        , "iconOn": "", "iconOff": ""} 
                /* Brightness */        , {"identifier": "brightness", "text": "Brightness", "type": 15, "controlType": "slider", "slot": 0, "toggleObj": root.brightnessSlider, "holdActionType": "indicator", "holdActionUrl": ""
                                        , "iconOn": "", "iconOff": ""} 
                /* Volume */            , {"identifier": "volume", "text": "Volume", "type": 16, "controlType": "slider", "slot": 0, "toggleObj": root.volumeSlider, "holdActionType": "indicator", "holdActionUrl": ""
                                        , "iconOn": "", "iconOff": ""} 
                /* Active Screen */     , {"identifier": "activescreen", "text": "Active Screen", "type": 17, "controlType": "toggle", "slot": 1, "toggleObj": activeScreenToggle, "holdActionType": "indicator", "holdActionUrl": ""
                                        , "iconOn": "preferences-desktop-display-symbolic", "iconOff": "video-display-symbolic"}
                // ENH128 - OSK Quick toggle
                /* OSK */               , {"identifier": "osk", "text": "On-screen Keyboard", "type": 18, "controlType": "toggle", "slot": 1, "toggleObj": oskToggle, "holdActionType": "external", "holdActionUrl": "settings:///system/language"
                                        , "iconOn": "input-keyboard-symbolic", "iconOff": "input-keyboard-symbolic"} 
                // ENH128 - End
                // ENH129 - Color overlay
                /* Color Overlay */     , {"identifier": "coloroverlay", "text": "Color Overlay", "type": 19, "controlType": "toggle", "slot": 1, "toggleObj": colorOverlayToggle, "holdActionType": "indicator", "holdActionUrl": ""
                                        , "iconOn": "preferences-color-symbolic", "iconOff": "preferences-color-symbolic"} 
                // ENH129 - End
                // ENH190 - Keypad backlight settings
                /* Keypad Backlight */     , {"identifier": "keypadBacklight", "text": "Keypad Backlight", "type": 20, "controlType": "toggle", "slot": 1, "toggleObj": keypadBacklightToggle, "holdActionType": "indicator", "holdActionUrl": ""
                                        , "iconOn": "flash-on", "iconOff": "flash-off"}
                // ENH190 - End
            ]

            z: 2

            visible: {
                if (shell.settings.quickTogglesOnlyShowInNotifications) {
                    const _identifier = root.model.data(root.currentMenuIndex, 0)

                    return content.visible && root.enableQuickToggles && _identifier == "ayatana-indicator-messages"
                }

                return content.visible && root.enableQuickToggles
            }

            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onWheel: {
                let _deltaY = wheel.angleDelta.y
                if (_deltaY >= 120) {
                    quickToggles.expanded = true
                } else if (_deltaY <= -120 && quickTogglesFlickable.contentY === 0) {
                    quickToggles.expanded = false
                }
                wheel.accepted = true;
            }
            enabled: root.state != "initial"
            clip: true

            height: {
                if (visible) {
                    if (swipeArea.dragging) {
                        let _height = expanded ? expandedHeight - swipeArea.distance : collapsedHeight + swipeArea.distance
                        let _defaultHeight = expanded ? expandedHeight : collapsedHeight

                        if (_height <= expandedHeight && _height >= collapsedHeight) {
                            return _height
                        } else if (_height > expandedHeight) {
                            return expandedHeight
                        } else if (_height < collapsedHeight) {
                            return collapsedHeight
                        } else {
                            return _defaultHeight
                        }
                    }
                    if (quickTogglesFlickable.interactive && quickTogglesFlickable.verticalOvershoot < 0) {
                        let _height = expandedHeight + quickTogglesFlickable.verticalOvershoot
                        let _defaultHeight = expandedHeight

                        if (_height <= expandedHeight && _height >= collapsedHeight) {
                            return _height
                        } else if (_height > expandedHeight) {
                            return expandedHeight
                        } else if (_height < collapsedHeight) {
                            return collapsedHeight
                        } else {
                            return _defaultHeight
                        }
                    }
                    if (expanded || editMode) {
                        return expandedHeight
                    } else {
                        return collapsedHeight
                    }
                } else {
                    return 0
                }
            }
            anchors {
                left: parent.left
                right: parent.right
            }

            Behavior on height { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }

            onClicked: mouse.accepted = true

            onPressAndHold: {
                editMode = !editMode
                shell.haptics.playSubtle()
            }

            onExpandedChanged: if (!expanded) quickTogglesFlickable.reset()

            function arrMove(arr, oldIndex, newIndex) {
                if (newIndex >= arr.length) {
                    let i = newIndex - arr.length + 1;
                    while (i--) {
                        arr.push(undefined);
                    }
                }
                arr.splice(newIndex, 0, arr.splice(oldIndex, 1)[0]);
                return arr;
            }

            ListItems.ThinDivider {
                id: quickTogglesDivider
                anchors {
                    left: parent.left
                    right: parent.right
                }
            }

            Flickable {
                id: quickTogglesFlickable

                anchors.fill: parent
                bottomMargin: units.gu(1)
                boundsBehavior: Flickable.DragOverBounds
                boundsMovement: Flickable.StopAtBounds
                contentHeight: gridLayout.height
                interactive: quickToggles.expanded && gridLayout.height > menuContainer.height && !gridArea.isDragActive

                function reset() {
                    contentY = 0
                }

                onDraggingChanged: {
                    if (!dragging && verticalOvershoot <= -quickToggles.swipeThreshold) {
                        quickToggles.expanded = false
                    }
                }

                GridLayout {
                    id: gridLayout

                    columns: Math.floor((width - (anchors.margins * 2)) / (quickToggles.toggleHeight + units.gu(2)))
                    columnSpacing: 0
                    rowSpacing: 0
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: units.gu(1)
                    }

                    Repeater {
                        id: togglesRepeater

                        model: shell.settings.quickToggles

                        Item {
                            id: itemContainer

                            Layout.fillWidth: true
                            Layout.preferredHeight: quickToggles.rowHeight
                            Layout.columnSpan: itemData.slot == 0 && gridLayout.columns > 0 ? gridLayout.columns : itemData.slot

                            readonly property bool isMediaPlayer: itemControlType == "media"
                            property var itemData: quickToggles.toggleItems[modelData.type]
                            property int itemIndex: index
                            property int itemType: modelData.type
                            property string itemControlType: itemData.controlType
                            property var toggleObj: itemData ? itemData.toggleObj : null

                            visible: opacity > 0
                            opacity: isMediaPlayer ? shell.playbackItemIndicator && (shell.playbackItemIndicator.canPlay || quickToggles.editMode)
                                                                && (modelData.enabled || quickToggles.editMode) ? 1 : 0
                                                   : toggleObj && (modelData.enabled || quickToggles.editMode) ? 1 : 0

                            Behavior on opacity {
                                LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
                            }

                            // WORKAROUND: Click events on mouse area for dragging in edit mode
                            // doesn't propagate to TapHandler of each quick toggle
                            function clicked() {
                                const _item = itemLoader.item
                                if (_item) {
                                    const _actualItem = _item.children[0]
                                    if (_actualItem) {
                                        _actualItem.clicked()
                                    }
                                }
                            }
                            
                            Item {
                                id: toggleContainer

                                property int type: (index >= 0) ? togglesRepeater.model[index].type : -1

                                x: 0
                                y: 0
                                width: parent.width
                                height: parent.height

                                states: [
                                    State {
                                        name: "active"; when: gridArea.activeId == toggleContainer.type
                                        PropertyChanges {target: toggleContainer; x: gridArea.mouseX - parent.x - width / 2; y: gridArea.mouseY - parent.y - height - units.gu(3); z: 10}
                                    }
                                ]
                                
                                Behavior on x {
                                    LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
                                }
                                Behavior on y {
                                    LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
                                }

                                Loader {
                                    id: itemLoader

                                    property alias itemData: itemContainer.itemData
                                    property alias itemIndex: itemContainer.itemIndex
                                    property alias itemType: itemContainer.itemType
                                    property alias toggleObject: itemContainer.toggleObj
                                    property var modelItemData: modelData

                                    sourceComponent: {
                                        switch (itemContainer.itemControlType) {
                                            case "media":
                                                return mediaPlayerComponent
                                            case "slider":
                                                return sliderComponent
                                            default:
                                                return quickToggleComponent
                                        }
                                    }
                                    asynchronous: true
                                    visible: status == Loader.Ready
                                    anchors.fill: parent
                                }
                            }
                        }
                    }

                    LPToggleItem {
                        id: activeScreenToggle

                        checked: shell.isScreenActive
                        parentMenuIndex: "ayatana-indicator-session"

                        onClicked: shell.isScreenActive = !shell.isScreenActive
                    }

                    // ENH128 - OSK Quick toggle
                    LPToggleItem {
                        id: oskToggle

                        checked: lomiriSettings.alwaysShowOsk
                        parentMenuIndex: "ayatana-indicator-keyboard"

                        onClicked: lomiriSettings.alwaysShowOsk = !lomiriSettings.alwaysShowOsk
                    }
                    // ENH128 - End

                    // ENH129 - Color overlay
                    LPToggleItem {
                        id: colorOverlayToggle

                        checked: shell.settings.enableColorOverlaySensor
                        parentMenuIndex: "ayatana-indicator-session"

                        onClicked: shell.settings.enableColorOverlaySensor = !shell.settings.enableColorOverlaySensor
                    }
                    // ENH129 - End
                    // ENH190 - Keypad backlight settings
                    LPToggleItem {
                        id: keypadBacklightToggle

                        checked: shell.settings.enableKeyboardBacklight
                        parentMenuIndex: "ayatana-indicator-session"

                        onClicked: shell.settings.enableKeyboardBacklight = !shell.settings.enableKeyboardBacklight
                    }
                    // ENH190 - End

                    // ENH115 - Standalone Immersive mode
                    LPToggleItem {
                        id: immersiveModeToggle

                        checked: shell.settings.immersiveMode
                        parentMenuIndex: "ayatana-indicator-session"

                        onClicked: shell.settings.immersiveMode = !shell.settings.immersiveMode
                    }
                    // ENH115 - End

                    // ENH116 - Standalone Dark mode toggle
                    LPToggleItem {
                        id: darkModeToggle

                        checked: shell.themeSettings.isDarkMode
                        parentMenuIndex: "ayatana-indicator-session"

                        onClicked: shell.themeSettings.toggleTheme()
                    }
                    LPToggleItem {
                        id: autoDarkModeToggle

                        checked: shell.settings.enableAutoDarkMode
                        parentMenuIndex: "ayatana-indicator-session"

                        onClicked: shell.settings.enableAutoDarkMode = !shell.settings.enableAutoDarkMode
                    }
                    // ENH116 - End

                    // ENH136 - Separate desktop mode per screen
                    LPToggleItem {
                        id: shellDesktopModeToggle

                        checked: shell.isDesktopMode
                        parentMenuIndex: "ayatana-indicator-session"

                        onClicked: shell.isDesktopMode = !shell.isDesktopMode
                    }
                    // ENH136 - End

                    Component {
                        id: quickToggleComponent

                        Item {
                            LPQuickToggleButton {
                                id: toggleButton

                                anchors.centerIn: parent
                                editMode: quickToggles.editMode
                                toggleObj: toggleObject
                                checked: toggleObj ? quickToggles.editMode ? modelItemData.enabled : toggleObj.checked  
                                                   : false
                                enabled: toggleObj ? toggleObj.enabled || quickToggles.editMode : false
                                iconName: checked || quickToggles.editMode ? controlData.iconOn : controlData.iconOff
                                height: quickToggles.toggleHeight
                                width: height
                                controlData: itemData
                                controlIndex: itemIndex

                                onClicked: {
                                    if (!editMode) {
                                        toggleObj.clicked()
                                    }
                                }
                            }
                        }
                    }
                    
                    Component {
                        id: sliderComponent

                        Item {
                            LPSliderMenu {
                                id: sliderMenu

                                readonly property bool isBrightness: toggleObj == root.brightnessSlider

                                anchors {
                                    fill: parent
                                    topMargin: units.gu(0.5)
                                    bottomMargin: anchors.topMargin
                                    leftMargin: units.gu(1.5)
                                    rightMargin: anchors.leftMargin
                                }

                                sliderObj: toggleObject
                                toggleObj: toggleObject
                                editMode: quickToggles.editMode
                                checked: modelItemData.enabled
                                controlData: itemData
                                controlIndex: itemIndex

                                // Brightness Slider
                                readonly property bool autoBrightnessAvailable: root.autoBrightnessToggle ? true : false
                                readonly property bool autoBrightnessEnabled: autoBrightnessAvailable && root.autoBrightnessToggle.checked
                                readonly property bool customAutoBrightnessEnabled: shell.settings.enableCustomAutoBrightness
                                readonly property int currentState: {
                                    switch (true) {
                                        // System auto-brightness is enabled
                                        case (autoBrightnessAvailable && autoBrightnessEnabled):
                                            return 1
                                        // Custom auto-brightness is enabled
                                        case (!autoBrightnessEnabled && customAutoBrightnessEnabled):
                                            return 2
                                        // No auto-brightness enabled
                                        default:
                                            return 0
                                    }
                                } 

                                sliderEnabled: !(isBrightness && autoBrightnessEnabled)
                                enabledMinMaxButtons: !isBrightness
                                toggleIcon: {
                                    if (!isBrightness)
                                        return ""

                                    switch (currentState) {
                                        case 1:
                                            return "display-brightness-symbolic"
                                        case 2:
                                            return "display-brightness-max"
                                        case 0:
                                        default:
                                            return "display-brightness-min"
                                    }
                                }

                                onToggleButtonClicked: {
                                    switch (currentState) {
                                        case 0: // From No auto-brightness to System
                                            if (!autoBrightnessEnabled) {
                                                root.autoBrightnessToggle.clicked()
                                            }
                                            break
                                        case 1: // From System auto-brightness to Custom
                                            if (autoBrightnessEnabled) {
                                                root.autoBrightnessToggle.clicked()
                                            }
                                            shell.settings.enableCustomAutoBrightness = true
                                            break
                                        case 2: // From Custom auto-brightness to No auto-brightness
                                        default:
                                            if (autoBrightnessEnabled) {
                                                root.autoBrightnessToggle.clicked()
                                            }
                                            shell.settings.enableCustomAutoBrightness = false
                                            break
                                    }
                                }
                            }
                        }
                    }
                    Component {
                        id: mediaPlayerComponent

                        Item {
                            LPMediaControls {
                                anchors {
                                    fill: parent
                                    topMargin: units.gu(0.5)
                                    bottomMargin: anchors.topMargin
                                    leftMargin: units.gu(1.5)
                                    rightMargin: anchors.leftMargin
                                }
                                mediaPlayerObj: shell.mediaPlayerIndicator
                                playBackObj: shell.playbackItemIndicator
                                toggleObj: toggleObject
                                editMode: quickToggles.editMode
                                checked: modelItemData.enabled
                                controlData: itemData
                                controlIndex: itemIndex
                            }
                        }
                    }
                }

                MouseArea {
                    id: gridArea

                    property var currentItem: gridLayout.childAt(mouseX, mouseY) //item underneath cursor
                    // For offset to the top
                    //property var currentItem: isDragActive ? gridLayout.childAt(mouseX, mouseY - quickToggles.toggleHeight) : gridLayout.childAt(mouseX, mouseY) //item underneath cursor
                    property int index: currentItem ? currentItem.itemIndex : -1 //item underneath cursor
                    property int activeId: -1 //type of active item
                    property int activeIndex //current position of active item
                    readonly property bool isDragActive: activeId > -1

                    enabled: quickToggles.editMode
                    anchors.fill: gridLayout
                    hoverEnabled: enabled
                    propagateComposedEvents: true

                    onClicked: {
                        if (currentItem) {
                            currentItem.clicked()
                        }
                    }

                    onPressAndHold: {
                        if (currentItem) {
                            activeIndex = index
                            activeId = currentItem.itemType
                        } else {
                            quickToggles.editMode = !quickToggles.editMode
                        }
                        shell.haptics.play()
                    }
                    onReleased: {
                        activeId = -1
                        shell.settings.quickToggles = togglesRepeater.model.slice()
                        togglesRepeater.model = Qt.binding( function () { return shell.settings.quickToggles } )
                    }
                    onPositionChanged: {
                        if (activeId != -1 && index != -1 && index != activeIndex) {
                            togglesRepeater.model = quickToggles.arrMove(togglesRepeater.model, activeIndex, activeIndex = index)
                            shell.haptics.playSubtle()
                        }
                    }
                }
            }

            LPSwipeGestureHandler {
                id: swipeArea

                enabled: !quickToggles.editMode && !quickTogglesFlickable.interactive
                anchors.fill: parent
                immediateRecognition: false
                direction: quickToggles.expanded ? SwipeArea.Downwards : SwipeArea.Upwards

                onDraggingChanged: {
                    if (!dragging && towardsDirection && distance >= quickToggles.swipeThreshold) {
                        quickToggles.expanded = !quickToggles.expanded
                    }
                }
            }

            Icon {
                visible: quickToggles.multiRows && !quickToggles.editMode
                name: quickToggles.expanded ? "down" : "up"
                height: units.gu(1.5)
                width: height
                color: theme.palette.normal.backgroundText
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: quickToggles.expanded = !quickToggles.expanded
                }
            }
        }
        // ENH056 - End

        MenuContent {
            id: content
            objectName: "menuContent"

            anchors {
                left: parent.left
                right: parent.right
                // ENH056 - Quick toggles
                // top: parent.top
                // ENH056 - End
            }
            // ENH056 - Quick toggles
            // height: openedHeight - bar.height - handle.height
            height: openedHeight - bar.height - handle.height - quickToggles.height
            // ENH056 - End
            model: root.model
            visible: root.unitProgress > 0
            currentMenuIndex: bar.currentItemIndex
        }
    }

    // ENH054 - Transparent drag handle
    Rectangle {
        color: root.panelColor
        anchors.fill: handle
        visible: root.inverted
    }
    // ENH054 - End

    Handle {
        id: handle
        objectName: "handle"
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.gu(2)
        active: d.activeDragHandle ? true : false
        visible: !root.fullyClosed
        // ENH054 - Transparent drag handle
        transparentBackground: true
        // ENH054 - End
    }

    Rectangle {
        anchors.fill: bar
        color: panelColor
        visible: !root.fullyClosed
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Left) {
            bar.selectPreviousItem();
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            bar.selectNextItem();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            root.hide();
            event.accepted = true;
        }
    }

    // ENH028 - Open indicators via gesture
    // Dummy item to hold states of the panel bar's top/bottom anchor
    Item {
        states: [
            State {
                when: root.inverted
                // ENH056 - Quick toggles
                //AnchorChanges { target: bar; anchors.bottom: handle.top; }
                AnchorChanges {
                    target: bar
                    anchors.bottom: handle.top
                }

                AnchorChanges {
                    target: quickToggles
                    anchors.top: content.bottom
                }

                AnchorChanges {
                    target: quickTogglesDivider
                    anchors.top: parent.top
                }

                AnchorChanges {
                    target: menuContainer
                    anchors.top: parent.top
                    anchors.bottom: bar.top
                }

                AnchorChanges {
                    target: content
                    anchors.top: parent.top
                }
                // ENH056 - End
            }
            , State {
                when: !root.inverted
                // ENH056 - Quick toggles
                //AnchorChanges { target: bar; anchors.top: parent.top; }
                AnchorChanges {
                    target: bar
                    anchors.top: parent.top
                }

                AnchorChanges {
                    target: quickToggles
                    anchors.top: content.bottom
                }

                AnchorChanges {
                    target: menuContainer
                    anchors.top: bar.bottom
                    anchors.bottom: parent.bottom
                }

                AnchorChanges {
                    target: content
                    anchors.top: parent.top
                }
                // ENH056 - End
            }
        ]
    }
    // ENH028 - End

    PanelBar {
        id: bar
        objectName: "indicatorsBar"

        anchors {
            left: parent.left
            right: parent.right
        }
        expanded: false
        enableLateralChanges: false
        lateralPosition: -1
        lightMode: root.lightMode
        unitProgress: root.unitProgress
        // ENH028 - Open indicators via gesture
        inverted: root.inverted
        visible: !root.useIndicatorSelector
        // ENH028 - End

        // ENH095 - Middle notch support
        // height: expanded ? expandedPanelHeight : minimizedPanelHeight
        // ENH028 - Open indicators via gesture
        //height: (expanded ? expandedPanelHeight : minimizedPanelHeight) + contentTopMargin
        height: {
            if (root.useIndicatorSelector) {
                return units.gu(7)
            }

            return (expanded ? expandedPanelHeight : minimizedPanelHeight) + contentTopMargin
        }
        // ENH028 - End
        // ENH095 - End
        Behavior on height { NumberAnimation { duration: LomiriAnimation.SnapDuration; easing: LomiriAnimation.StandardEasing } }
    }

    // ENH028 - Open indicators via gesture
    readonly property bool useIndicatorSelector: shell.settings.useIndicatorSelectorForPanelBarWhenInverted && root.inverted
    // So that clicking on empty space won't close the indicator panel
    MouseArea {
        anchors.fill: bar
        acceptedButtons: Qt.AllButtons
        onWheel: wheel.accepted = true;
        enabled: indicatorSelectorLoader.active
        visible: enabled
        hoverEnabled: enabled
    }
    Loader {
        id: indicatorSelectorLoader
        
        readonly property bool swipeSelectMode: item && item.swipeSelectMode
        readonly property bool isHovered: item && item.isHovered
        readonly property real defaultBottomMargin: units.gu(4)
        //bottomMargin for views
        readonly property real viewBottomMargin: item ? (swipeSelectMode ? item.storedHeightBeforeSwipeSelectMode : height) + indicatorSelectorLoader.defaultBottomMargin
                                                      : 0

        active: root.useIndicatorSelector
        asynchronous: true
        height: item ? item.height : 0 // Since height doesn't reset when inactive
        focus: false
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: (swipeSelectMode && !isHovered ? shell.convertFromInch(0.3) : 0) + defaultBottomMargin
            leftMargin: units.gu(1)
            rightMargin: units.gu(1)
        }

        Behavior on anchors.bottomMargin { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }
        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.BriskDuration } }

        sourceComponent: LPIndicatorSelector {
            id: indicatorSelector
            swipeEnabled: true
            mouseHoverEnabled: true
            noExpandWithMouse: true
            swipeHandlerOutsideMargin: 0
            model: bar.model
            currentIndex: bar.currentItemIndex
            indicatorWidth: units.gu(2)
            indicatorExpandedWidth: units.gu(2.5)

            onNewIndexSelected: bar.setCurrentItemIndex(newIndex)
        }
    }
    // ENH028 - End

    ScrollCalculator {
        id: leftScroller
        width: units.gu(5)
        anchors.left: bar.left
        height: bar.height

        forceScrollingPercentage: 0.33
        stopScrollThreshold: units.gu(0.75)
        direction: Qt.RightToLeft
        lateralPosition: -1

        onScroll: bar.addScrollOffset(-scrollAmount);
    }

    ScrollCalculator {
        id: rightScroller
        width: units.gu(5)
        anchors.right: bar.right
        height: bar.height

        forceScrollingPercentage: 0.33
        stopScrollThreshold: units.gu(0.75)
        direction: Qt.LeftToRight
        lateralPosition: -1

        onScroll: bar.addScrollOffset(scrollAmount);
    }

    MouseArea {
        anchors.bottom: parent.bottom
        anchors.left: alignment == Qt.AlignLeft ? parent.left : __showDragHandle.left
        anchors.right: alignment == Qt.AlignRight ? parent.right : __showDragHandle.right
        height: minimizedPanelHeight
        enabled: __showDragHandle.enabled && showOnClick
        onClicked: {
            var barPosition = mapToItem(bar, mouseX, mouseY);
            bar.selectItemAt(barPosition.x)
            root.show()
        }
    }

    DragHandle {
        id: __showDragHandle
        objectName: "showDragHandle"
        anchors.bottom: parent.bottom
        anchors.left: alignment == Qt.AlignLeft ? parent.left : undefined
        anchors.leftMargin: -root.menuContentX
        anchors.right: alignment == Qt.AlignRight ? parent.right : undefined
        width: root.overFlowWidth + root.menuContentX
        height: minimizedPanelHeight
        direction: Direction.Downwards
        enabled: !root.shown && root.available && !hideAnimation.running && !showAnimation.running
        autoCompleteDragThreshold: maxTotalDragDistance / 2
        stretch: true

        onPressedChanged: {
            if (pressed) {
                touchPressTime = new Date().getTime();
            } else {
                var touchReleaseTime = new Date().getTime();
                if (touchReleaseTime - touchPressTime <= 300 && distance < units.gu(1)) {
                    root.showTapped();
                }
            }
        }
        property var touchPressTime

        // using hint regulates minimum to hint displacement, but in fullscreen mode, we need to do it manually.
        overrideStartValue: enableHint ? minimizedPanelHeight : expandedPanelHeight + handle.height
        maxTotalDragDistance: openedHeight - (enableHint ? minimizedPanelHeight : expandedPanelHeight + handle.height)
        // ENH095 - Middle notch support
        // hintDisplacement: enableHint ? expandedPanelHeight - minimizedPanelHeight + handle.height : 0
        hintDisplacement: enableHint ? shell.adjustForMiddleNotch ? expandedPanelHeight + handle.height
                                                                : expandedPanelHeight - minimizedPanelHeight + handle.height
                                     : 0
        // ENH095 - End
    }

    MouseArea {
        anchors.fill: __hideDragHandle
        enabled: __hideDragHandle.enabled
        onClicked: root.hide()
    }

    DragHandle {
        id: __hideDragHandle
        objectName: "hideDragHandle"
        anchors.fill: handle
        direction: Direction.Upwards
        enabled: root.shown && root.available && !hideAnimation.running && !showAnimation.running
        hintDisplacement: units.gu(3)
        autoCompleteDragThreshold: maxTotalDragDistance / 6
        stretch: true
        maxTotalDragDistance: openedHeight - expandedPanelHeight - handle.height

        onTouchPositionChanged: {
            if (root.state === "locked") {
                d.xDisplacementSinceLock += (touchPosition.x - d.lastHideTouchX)
                d.lastHideTouchX = touchPosition.x;
            }
        }
    }

    PanelVelocityCalculator {
        id: yVelocityCalculator
        velocityThreshold: d.hasCommitted ? 0.1 : 0.3
        trackedValue: d.activeDragHandle ?
                            (Direction.isPositive(d.activeDragHandle.direction) ?
                                    d.activeDragHandle.distance :
                                    -d.activeDragHandle.distance)
                            : 0

        onVelocityAboveThresholdChanged: d.updateState()
    }

    Connections {
        target: showAnimation
        function onRunningChanged() {
            if (showAnimation.running) {
                root.state = "commit";
            }
        }
    }

    Connections {
        target: hideAnimation
        function onRunningChanged() {
            if (hideAnimation.running) {
                root.state = "initial";
            }
        }
    }

    QtObject {
        id: d
        property var activeDragHandle: showDragHandle.dragging ? showDragHandle : hideDragHandle.dragging ? hideDragHandle : null
        property bool hasCommitted: false
        property real lastHideTouchX: 0
        property real xDisplacementSinceLock: 0
        onXDisplacementSinceLockChanged: d.updateState()

        property real rowMappedLateralPosition: {
            if (!d.activeDragHandle) return -1;
            return d.activeDragHandle.mapToItem(bar, d.activeDragHandle.touchPosition.x, 0).x;
        }

        function updateState() {
            if (!showAnimation.running && !hideAnimation.running && d.activeDragHandle) {
                if (unitProgress <= 0) {
                    root.state = "initial";
                // lock indicator if we've been committed and aren't moving too much laterally or too fast up.
                } else if (d.hasCommitted && (Math.abs(d.xDisplacementSinceLock) < units.gu(2) || yVelocityCalculator.velocityAboveThreshold)) {
                    root.state = "locked";
                } else {
                    root.state = "reveal";
                }
            }
        }
    }

    states: [
        State {
            name: "initial"
            PropertyChanges { target: d; hasCommitted: false; restoreEntryValues: false }
        },
        State {
            name: "reveal"
            StateChangeScript {
                script: {
                    yVelocityCalculator.reset();
                    // initial item selection
                    if (!d.hasCommitted) bar.selectItemAt(d.rowMappedLateralPosition);
                    d.hasCommitted = false;
                }
            }
            PropertyChanges {
                target: bar
                expanded: true
                // changes to lateral touch position effect which indicator is selected
                lateralPosition: d.rowMappedLateralPosition
                // vertical velocity determines if changes in lateral position has an effect
                enableLateralChanges: d.activeDragHandle &&
                                      !yVelocityCalculator.velocityAboveThreshold
            }
            // left scroll bar handling
            PropertyChanges {
                target: leftScroller
                lateralPosition: {
                    if (!d.activeDragHandle) return -1;
                    var mapped = d.activeDragHandle.mapToItem(leftScroller, d.activeDragHandle.touchPosition.x, 0);
                    return mapped.x;
                }
            }
            // right scroll bar handling
            PropertyChanges {
                target: rightScroller
                lateralPosition: {
                    if (!d.activeDragHandle) return -1;
                    var mapped = d.activeDragHandle.mapToItem(rightScroller, d.activeDragHandle.touchPosition.x, 0);
                    return mapped.x;
                }
            }
        },
        State {
            name: "locked"
            StateChangeScript {
                script: {
                    d.xDisplacementSinceLock = 0;
                    d.lastHideTouchX = hideDragHandle.touchPosition.x;
                }
            }
            PropertyChanges { target: bar; expanded: true }
        },
        State {
            name: "commit"
            extend: "locked"
            PropertyChanges { target: root; focus: true }
            PropertyChanges { target: bar; interactive: true }
            PropertyChanges {
                target: d;
                hasCommitted: true
                lastHideTouchX: 0
                xDisplacementSinceLock: 0
                restoreEntryValues: false
            }
        }
    ]
    state: "initial"
}
