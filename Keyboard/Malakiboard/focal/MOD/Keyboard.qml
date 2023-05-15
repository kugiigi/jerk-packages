/*
 * This file is part of Maliit plugins
 *
 * Copyright (C) 2012 Openismus GmbH
 *
 * Contact: maliit-discuss@lists.maliit.org
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list
 * of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list
 * of conditions and the following disclaimer in the documentation and/or other materials
 * provided with the distribution.
 * Neither the name of Nokia Corporation nor the names of its contributors may be
 * used to endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

import QtQuick 2.4
import "constants.js" as Const
import "theme_loader.js" as Theme
import "keys/"
import "keys/key_constants.js" as UI
import Lomiri.Components 1.3
import QtFeedback 5.0
import QtMultimedia 5.0
import QtQuick.Layouts 1.3
// ENH008 - Keyboard enhancements
// Temp workaround for disabling height
import GSettings 1.0
// ENH008 - End
// ENH070 - Keyboard settings
import Qt.labs.settings 1.0
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Suru 2.2
// ENH070 - End
// ENH082 - Custom theme
import "MKColorpicker"
// ENH082 - End

Item {
    id: fullScreenItem
    objectName: "fullScreenItem"

    property bool landscape: width > height
    // ENH005 - Fix keyboard on landscape
    // readonly property bool tablet: landscape ? width >= units.gu(90) : height >= units.gu(90)
    readonly property bool tablet: landscape ? width / height <= 1.8 && width >= units.gu(90)
										: height / width <= 1.8 && height >= units.gu(90)
    // ENH005 - End
    readonly property bool keyboardFloating: keyboardSurface.state == "FLOATING"
    readonly property bool oneHanded: keyboardSurface.state == "ONE-HANDED-LEFT" || keyboardSurface.state == "ONE-HANDED-RIGHT" || keyboardSurface.state == "FLOATING"
    readonly property bool keyboardLandscape: landscape && !oneHanded
    // ENH008 - Keyboard enhancements
    // Replacement for proper usageMode settings
    property string usageMode: "Full"
    onUsageModeChanged: {
        keyboardSurface.state = keyboardSurface.settingsToState(usageMode)
        if (usageMode == "Floating") {
            oskSettings.disableHeight = true
        } else {
            oskSettings.disableHeight = false
        }
    }
    GSettings {
        id: oskSettings
        objectName: "oskSettings"
        schema.id: "com.canonical.keyboard.maliit"
    }
    Connections {
        target: oskSettings
        onDisableHeightChanged: {
            if (usageMode == "Floating" && !oskSettings.disableHeight) {
                oskSettings.disableHeight = true
            }
        }
    }
    // ENH008 - End

    property bool cursorSwipe: false
    property int prevSwipePositionX
    property int prevSwipePositionY
    // ENH088 - Cursor mover timeout
    // property int cursorSwipeDuration: 5000
    property int cursorSwipeDuration: fullScreenItem.settings.cursorMoverTimeout
    // ENH088 - End
    // ENH089 - Quick actions
    property alias swipeHaptic : swipeEffect
    property alias allQuickActions: actionsFactory.allActions
    // ENH089 - End
    // ENH082 - Custom theme
    property bool useCustomTheme: fullScreenItem.settings.useCustomTheme && !fullScreenItem.settings.followSystemTheme
    onUseCustomThemeChanged: {
        if (fullScreenItem.settings.followSystemTheme) {
            fullScreenItem.systemThemeUpdate()
        } else {
            fullScreenItem.loadTheme()
        }
    }
    // ENH082 - End
    // ENH071 - Custom height
    property bool resizeMode: false
    // ENH071 - End
    property var timerSwipe: swipeTimer
    property var theme: Theme.defaultTheme

    property variant input_method: maliit_input_method
    property variant event_handler: maliit_event_handler

    onXChanged: fullScreenItem.reportKeyboardVisibleRect();
    onYChanged: fullScreenItem.reportKeyboardVisibleRect();
    onWidthChanged: fullScreenItem.reportKeyboardVisibleRect();
    onHeightChanged: fullScreenItem.reportKeyboardVisibleRect();

    // ENH082 - Custom theme
    // Component.onCompleted: Theme.load(maliit_input_method.theme)
    Component.onCompleted: fullScreenItem.loadTheme()
    // ENH082 - End
    // ENH070 - Keyboard settings
    property alias settings: mal_settings
    Item {
        id: mal_settings

        // Appearance & Layout
        property alias useCustomHeight: settingsObj.useCustomHeight
        property alias customPortraitHeight: settingsObj.customPortraitHeight
        property alias customLandscapeHeight: settingsObj.customLandscapeHeight
        property alias useCustomRibbonHeight: settingsObj.useCustomRibbonHeight
        property alias customRibbonHeight: settingsObj.customRibbonHeight
        property alias customRibbonFontSize: settingsObj.customRibbonFontSize
        property alias hideUrlKey: settingsObj.hideUrlKey
        property alias hideCursorModeText: settingsObj.hideCursorModeText
        property alias followSystemTheme: settingsObj.followSystemTheme
        property alias lightTheme: settingsObj.lightTheme
        property alias darkTheme: settingsObj.darkTheme
        property alias showNumberRow: settingsObj.showNumberRow
        property alias customLightTheme: settingsObj.customLightTheme
        property alias customDarkTheme: settingsObj.customDarkTheme
        property alias useCustomTheme: settingsObj.useCustomTheme
        property alias customTheme: settingsObj.customTheme
        property alias bottomGesturehint: settingsObj.bottomGesturehint
        property alias useCustomFont: settingsObj.useCustomFont
        property alias customFont: settingsObj.customFont
        
        // Advanced Text Manipulation Mode
        property alias showBackSpaceEnter: settingsObj.showBackSpaceEnter
        property alias enableSelectWord: settingsObj.enableSelectWord
        property alias hapticsDuration: settingsObj.hapticsDuration
        property alias longPressDelay: settingsObj.longPressDelay
        property alias hapticsCursorMove: settingsObj.hapticsCursorMove
        property alias swipeHapticsDuration: settingsObj.swipeHapticsDuration
        property alias horizontalSwipeCursorSensitivity: settingsObj.horizontalSwipeCursorSensitivity
        property alias verticalSwipeCursorSensitivity: settingsObj.verticalSwipeCursorSensitivity
        property alias cursorMoverWorkaround: settingsObj.cursorMoverWorkaround
        property alias cursorMoverTimeout: settingsObj.cursorMoverTimeout

        // Quick actions
        property alias enableQuickActions: settingsObj.enableQuickActions
        property alias quickActions: settingsObj.quickActions

        // Saved data
        property alias savedPalettes: settingsObj.savedPalettes

        // Session data
        property string textClipboard: ""

        // ENH079 - Live theme change
        onFollowSystemThemeChanged: {
            if (fullScreenItem.settings.followSystemTheme) {
                fullScreenItem.systemThemeUpdate()
            } else {
                fullScreenItem.loadTheme()
            }
        }

        onLightThemeChanged: {
            if (fullScreenItem.settings.followSystemTheme) {
                fullScreenItem.systemThemeUpdate()
            }
        }

        onDarkThemeChanged: {
            if (fullScreenItem.settings.followSystemTheme) {
                fullScreenItem.systemThemeUpdate()
            }
        }
        // ENH079 - End
        // ENH082 - Custom theme
        onCustomThemeChanged: fullScreenItem.loadTheme()
        onCustomLightThemeChanged: {
            if (fullScreenItem.settings.followSystemTheme) {
                fullScreenItem.systemThemeUpdate()
            } else {
                fullScreenItem.loadTheme()
            }
        }
        onCustomDarkThemeChanged: {
            if (fullScreenItem.settings.followSystemTheme) {
                fullScreenItem.systemThemeUpdate()
            } else {
                fullScreenItem.loadTheme()
            }
        }
        // ENH082 - End

        Settings {
            id: settingsObj

            category: "malaki"
            fileName: "/home/phablet/.config/maliit-server/maliit-server.conf"

            property bool useCustomHeight: false
            property real customPortraitHeight: 0.31
            property real customLandscapeHeight: 0.49
            property bool useCustomRibbonHeight: false
            property real customRibbonHeight: 6 // in gu
            property real customRibbonFontSize: 17 // in dp
            property bool showBackSpaceEnter: true
            property bool hideUrlKey: false
            property bool enableSelectWord: true
            property bool hideCursorModeText: false
            property int hapticsDuration: 10 // in ms
            property bool followSystemTheme: false
            property string lightTheme: "Ambiance"
            property string darkTheme: "SuruDark"
            property int longPressDelay: 300 // in ms
            property bool showNumberRow: false
            property bool hapticsCursorMove: false
            property int swipeHapticsDuration: 3 // in ms
            property real horizontalSwipeCursorSensitivity: 1 // in gu
            property real verticalSwipeCursorSensitivity: 4 // in gu
            property bool cursorMoverWorkaround: false
            property int cursorMoverTimeout: 5000 // in ms
            property var customLightTheme: {
                "fontColor": "#333333",
                "selectionColor": "#19B6EE",
                "backgroundColor": "#f7f7f7",
                "dividerColor": "#cdcdcd",
                "annotationFontColor": "#333333",
                "charKeyColor": "white",
                "charKeyPressedColor": "#d9d9d9",
                "actionKeyColor": "#cdcdcd",
                "actionKeyPressedColor": "#aeaeae",
                "toolkitTheme": "Lomiri.Components.Themes.Ambiance",
                "popupBorderColor": "#888888",
                "keyBorderEnabled": false,
                "charKeyBorderColor": "white",
                "actionKeyBorderColor": "white"
            }
            property var customDarkTheme: {
                "fontColor": "#CDCDCD",
                "selectionColor": "#19B6EE",
                "backgroundColor": "#111111",
                "dividerColor": "#666666",
                "annotationFontColor": "#F7F7F7",
                "charKeyColor": "#3B3B3B",
                "charKeyPressedColor": "#5D5D5D",
                "actionKeyColor": "#666666",
                "actionKeyPressedColor": "#888888",
                "toolkitTheme": "Lomiri.Components.Themes.SuruDark",
                "popupBorderColor": "#888888",
                "keyBorderEnabled": false,
                "charKeyBorderColor": "#3B3B3B",
                "actionKeyBorderColor": "#3B3B3B"
            }
            property var savedPalettes: []
            property bool useCustomTheme: false
            property string customTheme: "CustomLight"
            property bool enableQuickActions: false
            property var quickActions: [
                [
                    { "id": "undo" }
                    , { "id": "redo" }
                    , { "id": "selectAll" }
                ]
                , [
                    { "id": "cut" }
                    , { "id": "copy" }
                    , { "id": "paste" }
                ]
            ]
            property bool bottomGesturehint: true
            property bool useCustomFont: false
            property string customFont: "Ubuntu"

        }
    }

    // ENH079 - Live theme change
    Settings {
        id: toolkitThemeSettings

        fileName: "/home/phablet/.config/lomiri-ui-toolkit/theme.ini"
    }

    Connections {
        target: canvas

        onStateChanged: {
            if (fullScreenItem.settings.followSystemTheme && target.state == "SHOWN") {
                fullScreenItem.systemThemeUpdate()
            }
        }
    }

    function systemThemeUpdate() {
        // Refresh theme data
        toolkitThemeSettings.fileName = ""
        toolkitThemeSettings.fileName = "/home/phablet/.config/lomiri-ui-toolkit/theme.ini"

        let currentTheme = toolkitThemeSettings.value("theme", "")

        if (currentTheme == "Lomiri.Components.Themes.SuruDark") {
            Theme.load(fullScreenItem.settings.darkTheme)
        } else {
            Theme.load(fullScreenItem.settings.lightTheme)
        }
    }
    // ENH079 - End

    // ENH082 - Custom theme
    function loadTheme() {
        if (fullScreenItem.useCustomTheme) {
            Theme.load(fullScreenItem.settings.customTheme)
        } else {
            Theme.load(maliit_input_method.theme)
        }
    }
    // ENH082 - End

    function showSettings() {
        settingsLoader.active = true
    }

    function hideSettings() {
        settingsLoader.active = false
    }

    function removeItemFromList(arr, value, isColor) {
        var i = 0;
        while (i < arr.length) {
            if ((isColor && Qt.colorEqual(arr[i], value))
                    || (!isColor && arr[i] === value)) {
                arr.splice(i, 1);
            } else {
                ++i;
            }
        }
        return arr;
    }

    // ENH070 - Keyboard settings
    Loader {
        id: settingsLoader
        
        property bool keyboardPreview: false

        active: false
        z: fullScreenItem.keyboardFloating ? canvas.z - 1 : canvas.z + 1

        anchors {
            fill: parent
            bottomMargin: keyboardPreview && !fullScreenItem.keyboardFloating ? canvas.height + units.dp(1) : 0
        }

        onActiveChanged: {
            if (active) {
                maliit_geometry.visibleRect = Qt.rect(0, 0, fullScreenItem.width, fullScreenItem.height);
            } else {
                fullScreenItem.reportKeyboardVisibleRect()
            }
        }

        sourceComponent: Component {
            Rectangle {
                id: malSettingsRec

                property alias stack: stack
                Suru.theme: dummy.theme.name == "Lomiri.Components.Themes.SuruDark" ? Suru.Dark : Suru.Light
                focus: false
                color: fullScreenItem.keyboardFloating ? "transparent" : Suru.neutralColor

                Rectangle {
                    id: pageRec

                    readonly property real defaultX: (parent.width / 2) - (width / 2)
                    readonly property real defaultY: 0

                    color: Suru.backgroundColor
                    x: defaultX
                    y: defaultY
                    width: Math.min(units.gu(60), parent.width)
                    height: fullScreenItem.keyboardFloating ? Math.min(units.gu(80), parent.height) : parent.height

                    Connections {
                        target: fullScreenItem
                        onKeyboardFloatingChanged: {
                            if (!target.keyboardFloating) {
                                pageRec.x = pageRec.defaultX
                                pageRec.y = pageRec.defaultY
                            }
                        }
                    }
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        QQC2.ToolBar {
                            Layout.fillWidth: true
                            Layout.bottomMargin: units.dp(1)
                            RowLayout {
                                anchors.fill: parent
                                MKHeaderToolButton {
                                    Layout.fillHeight: true
                                    icon.width: units.gu(2)
                                    icon.height: units.gu(2)
                                    visible: stack.currentItem.showBackButton
                                    action: MKBaseAction {
                                        icon.name:  stack.depth > 1 ? "back" : "close"
                                        shortcut: StandardKey.Cancel
                                         onTriggered: {
                                            if (stack.depth > 1) {
                                                stack.pop()
                                            } else {
                                                settingsLoader.active = false
                                            }
                                        }
                                    }
                                }

                                Repeater {
                                    id: leftRepeater

                                    model: stack.currentItem.headerLeftActions
                                    visible: false // So it won't be included in visible count

                                    MKHeaderToolButton {
                                        Layout.fillHeight: true
                                        icon.width: units.gu(2)
                                        icon.height: units.gu(2)
                                        action: modelData
                                        tooltipText: modelData ? modelData.tooltipText : ""
                                    }
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: stack.currentItem.title
                                    verticalAlignment: Text.AlignVCenter
                                    Suru.textLevel: Suru.HeadingThree
                                    elide: Text.ElideRight
                                }

                                Repeater {
                                    id: rightRepeater

                                    model: stack.currentItem.headerRightActions
                                    visible: false // So it won't be included in visible count

                                    MKHeaderToolButton {
                                        Layout.fillHeight: true
                                        icon.width: units.gu(2)
                                        icon.height: units.gu(2)
                                        action: modelData
                                        tooltipText: modelData ? modelData.tooltipText : ""
                                    }
                                }

                                MKHeaderToolButton {
                                    Layout.fillHeight: true
                                    visible: !fullScreenItem.keyboardFloating
                                    icon.width: units.gu(2)
                                    icon.height: units.gu(2)
                                    action: MKBaseAction {
                                        icon.name:  settingsLoader.keyboardPreview ? "view-off" : "view-on"
                                        onTriggered: settingsLoader.keyboardPreview = !settingsLoader.keyboardPreview
                                    }
                                }
                                MouseArea {
                                    id: settingsDragButton

                                    readonly property bool dragActive: drag.active

                                    Layout.fillHeight: true
                                    Layout.preferredWidth: units.gu(6)
                                    Layout.preferredHeight: width
                                    Layout.alignment: Qt.AlignRight

                                    drag.target: pageRec
                                    drag.axis: Drag.XAndYAxis
                                    drag.minimumX: 0
                                    drag.maximumX: fullScreenItem.width - pageRec.width
                                    drag.minimumY: 0
                                    drag.maximumY: fullScreenItem.height - pageRec.height
                                    
                                    visible: fullScreenItem.keyboardFloating

                                    Rectangle {
                                        anchors.fill: parent
                                        color: settingsDragButton.pressed ? Suru.highlightColor : Suru.backgroundColor

                                        Behavior on color {
                                            ColorAnimation { duration: LomiriAnimation.FastDuration }
                                        }

                                        Icon {
                                            id: icon

                                            implicitWidth: settingsDragButton.width * 0.60
                                            implicitHeight: implicitWidth
                                            name: "grip-large"
                                            anchors.centerIn: parent
                                            color: Suru.foregroundColor
                                        }
                                    }
                                }
                            }
                        }

                        QQC2.StackView {
                            id: stack

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            initialItem: settingsPage
                        }
                        
                        QQC2.Button {
                            id: closeButton

                            visible: !fullScreenItem.landscape
                            text: "Close"
                            Layout.fillWidth: true
                            onClicked: settingsLoader.active = false
                        }
                    }
                }
            }
        }
    }
    // ENH082 - Custom theme
    Loader {
        id: colorPickerLoader

        property var itemToColor
        property color oldColor

        anchors.fill: parent
        z: settingsLoader.z + 1
        active: false
        
        function open(caller) {
            itemToColor = caller
            oldColor = caller.text
            active = true
        }
        
        function close() {
            active = false
        }
        
        function applyColor() {
            itemToColor.text = item.colorValue
        }

        function revertColor() {
            itemToColor.text = oldColor
            item.setColor(itemToColor.text)
        }
        
        function savePalette(palette) {
            let strPalette = palette.toString()
            let tempArr = fullScreenItem.settings.savedPalettes.slice()
            tempArr = fullScreenItem.removeItemFromList(tempArr, strPalette, true)
            tempArr.push(strPalette)
            fullScreenItem.settings.savedPalettes = tempArr.slice()
        }

        function deletePalette(palette) {
            let paletteDelete = palette
            let tempArr = fullScreenItem.settings.savedPalettes.slice()
            tempArr = fullScreenItem.removeItemFromList(tempArr, paletteDelete, true)
            fullScreenItem.settings.savedPalettes = tempArr.slice()
        }

        onLoaded: item.setColor(itemToColor.text)
        
        sourceComponent: Component {
            Item {
                id: colorPickerContainer

                property alias colorValue: colorPicker.colorValue

                function setColor(colorToSet) {
                    colorPicker.setColorValue(colorToSet)
                }

                Suru.theme: dummy.theme.name == "Lomiri.Components.Themes.SuruDark" ? Suru.Dark : Suru.Light

                Item {
                    id: colorPickerFloat

                    x: fullScreenItem.width / 2 - width / 2
                    y: 0
                    width: Math.min(units.gu(60), parent.width - units.gu(4))
                    height: units.gu(50)
                    clip: true

                    // Eater mouse events
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.AllButtons
                        onWheel: wheel.accepted = true;
                    }

                    ColumnLayout {
                        spacing: 0
                        anchors {
                            fill: parent
                            margins: units.gu(1)
                        }

                        Rectangle {
                            Layout.preferredHeight: units.gu(6)
                            Layout.fillWidth: true
                            color: Suru.secondaryBackgroundColor

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: units.gu(2)
                                    rightMargin: units.gu(2)
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: colorPicker.colorValue
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Rectangle {
                                    Layout.preferredWidth: units.gu(10)
                                    Layout.preferredHeight: units.gu(4)
                                    Layout.alignment: Qt.AlignRight
                                    radius: units.gu(1)
                                    color: colorPicker.colorValue
                                    border {
                                        width: units.dp(1)
                                        color: Suru.foregroundColor
                                    }
                                }
                                QQC2.CheckBox {
                                    id: paletteMode
                                    Layout.alignment: Qt.AlignRight
                                    text: "Palette Mode"
                                    onCheckedChanged: colorPicker.paletteMode = !colorPicker.paletteMode
                                    Binding {
                                        target: paletteMode
                                        property: "checked"
                                        value: colorPicker.paletteMode
                                    }
                                }
                                MouseArea {
                                    id: dragButton

                                    readonly property bool dragActive: drag.active

                                    Layout.fillHeight: true
                                    Layout.preferredWidth: units.gu(6)
                                    Layout.preferredHeight: width
                                    Layout.alignment: Qt.AlignRight

                                    drag.target: colorPickerFloat
                                    drag.axis: Drag.XAndYAxis
                                    drag.minimumX: 0
                                    drag.maximumX: fullScreenItem.width - colorPickerFloat.width
                                    drag.minimumY: 0
                                    drag.maximumY: fullScreenItem.height - colorPickerFloat.height

                                    Rectangle {
                                        anchors.fill: parent
                                        color: dragButton.pressed ? Suru.activeFocusColor : Suru.secondaryBackgroundColor

                                        Behavior on color {
                                            ColorAnimation { duration: LomiriAnimation.FastDuration }
                                        }

                                        Icon {
                                            id: icon

                                            implicitWidth: dragButton.width * 0.60
                                            implicitHeight: implicitWidth
                                            name: "grip-large"
                                            anchors.centerIn: parent
                                            color: Suru.foregroundColor
                                        }
                                    }
                                }
                            }
                        }
                        Rectangle {
                            color: Suru.foregroundColor
                            Layout.preferredHeight: units.dp(1)
                            Layout.fillWidth: true
                        }
                        Colorpicker {
                            id: colorPicker

                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            enableDetails: false
                        }
                        Rectangle {
                            color: Suru.foregroundColor
                            Layout.preferredHeight: units.dp(1)
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: units.gu(6)
                            color: Suru.secondaryBackgroundColor

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: units.gu(2)
                                    rightMargin: units.gu(2)
                                }
                                QQC2.Button {
                                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                    text: "Close"
                                    onClicked: colorPickerLoader.close()
                                }
                                QQC2.Button {
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    text: colorPicker.savedPaletteIsSelected ? "Delete Palette" : "Save Palette"
                                    onClicked: {
                                        if (colorPicker.savedPaletteIsSelected) {
                                            colorPickerLoader.deletePalette(colorPicker.savedPaletteColor)
                                        } else {
                                            colorPickerLoader.savePalette(colorPicker.colorValue)
                                        }
                                    }
                                }
                                QQC2.Button {
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    text: "Revert"
                                    onClicked: colorPickerLoader.revertColor()
                                }
                                QQC2.Button {
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    text: "Apply"
                                    onClicked: colorPickerLoader.applyColor()
                                }
                            }
                        }
                    } // ColumnLayout

                    Rectangle {
                        anchors.fill: parent
                        radius: units.gu(2)
                        color: "transparent"
                        border {
                            color: Suru.tertiaryForegroundColor
                            width: units.gu(1)
                        }
                    }
                }
            }
        }
    }
    // ENH082 - End
    Component {
        id: settingsPage
        
        MKSettingsPage {
            title: "Malakiboard Settings"

            MKSettingsNavItem {
                Layout.fillWidth: true
                text: "Appearance and Layouts"
                onClicked: settingsLoader.item.stack.push(appearancePage, {"title": text})
            }
            MKSettingsNavItem {
                Layout.fillWidth: true
                text: "Advanced"
                onClicked: settingsLoader.item.stack.push(advancedPage, {"title": text})
            }
        }
    }
    Component {
        id: advancedPage

        MKSettingsPage {
            MKSettingsNavItem {
                Layout.fillWidth: true
                text: "Quick Actions"
                onClicked: settingsLoader.item.stack.push(quickActionsPage, {"title": text})
            }
            MKSettingsNavItem {
                Layout.fillWidth: true
                text: "Cursor Mode"
                onClicked: settingsLoader.item.stack.push(cursorModePage, {"title": text})
            }
            MKSliderItem {
                id: hapticsDuration

                Layout.fillWidth: true
                Layout.margins: units.gu(2)

                title: "Key press vibration duration (ms)"
                minimumValue: 1
                maximumValue: 30
                resetValue: 10
                onValueChanged: fullScreenItem.settings.hapticsDuration = value
                Binding {
                    target: hapticsDuration
                    property: "value"
                    value: fullScreenItem.settings.hapticsDuration
                }
            }
            MKSliderItem {
                id: longPressDelay

                Layout.fillWidth: true
                Layout.margins: units.gu(2)

                title: "Long press delay (ms)"
                minimumValue: 100
                maximumValue: 1000
                resetValue: 300
                onValueChanged: fullScreenItem.settings.longPressDelay = value
                Binding {
                    target: longPressDelay
                    property: "value"
                    value: fullScreenItem.settings.longPressDelay
                }
            }
        }
    }
    Component {
        id: quickActionsPage
        
        MKSettingsPage {
            QQC2.CheckDelegate {
                id: enableQuickActions

                Layout.fillWidth: true
                text: "Enable quick actions"
                onCheckedChanged: fullScreenItem.settings.enableQuickActions = checked
                Binding {
                    target: enableQuickActions
                    property: "checked"
                    value: fullScreenItem.settings.enableQuickActions
                }
            }
            MKSettingsNavItem {
                Layout.fillWidth: true
                visible: fullScreenItem.settings.enableQuickActions
                text: "Left Quick Actions"
                onClicked: settingsLoader.item.stack.push(leftQuickActionsPage, {"title": text})
            }
            MKSettingsNavItem {
                Layout.fillWidth: true
                visible: fullScreenItem.settings.enableQuickActions
                text: "Right Quick Actions"
                onClicked: settingsLoader.item.stack.push(rightQuickActionsPage, {"title": text})
            }
        }
    }
    Component {
        id: leftQuickActionsPage
        
        MKQuickActionsPage {
            model: fullScreenItem.settings.quickActions[0]
            onModelDataChanged: {
                fullScreenItem.settings.quickActions = [ newModelData, fullScreenItem.settings.quickActions[1] ]
            }
        }
    }
    Component {
        id: rightQuickActionsPage
        
        MKQuickActionsPage {
            model: fullScreenItem.settings.quickActions[1]
            onModelDataChanged: {
                fullScreenItem.settings.quickActions = [ fullScreenItem.settings.quickActions[0], newModelData ]
            }
        }
    }
    Component {
        id: cursorModePage
        
        MKSettingsPage {
            QQC2.CheckDelegate {
                id: showBackSpaceEnter

                Layout.fillWidth: true
                text: "Show backspace and enter keys"
                onCheckedChanged: fullScreenItem.settings.showBackSpaceEnter = checked
                Binding {
                    target: showBackSpaceEnter
                    property: "checked"
                    value: fullScreenItem.settings.showBackSpaceEnter
                }
            }
            QQC2.CheckDelegate {
                id: enableSelectWord

                Layout.fillWidth: true
                text: 'Enable "Select Word" function'
                onCheckedChanged: fullScreenItem.settings.enableSelectWord = checked
                Binding {
                    target: enableSelectWord
                    property: "checked"
                    value: fullScreenItem.settings.enableSelectWord
                }
            }
            QQC2.CheckDelegate {
                id: hapticsCursorMove

                Layout.fillWidth: true
                text: "Vibrate when moving cursor"
                onCheckedChanged: fullScreenItem.settings.hapticsCursorMove = checked
                Binding {
                    target: hapticsCursorMove
                    property: "checked"
                    value: fullScreenItem.settings.hapticsCursorMove
                }
            }
            MKSliderItem {
                id: swipeHapticsDuration

                Layout.fillWidth: true
                Layout.margins: units.gu(2)

                visible: fullScreenItem.settings.hapticsCursorMove
                title: "Swipe vibration duration (ms)"
                minimumValue: 1
                maximumValue: 30
                resetValue: 3
                onValueChanged: fullScreenItem.settings.swipeHapticsDuration = value
                Binding {
                    target: swipeHapticsDuration
                    property: "value"
                    value: fullScreenItem.settings.swipeHapticsDuration
                }
            }
            QQC2.CheckDelegate {
                id: cursorMoverWorkaround

                Layout.fillWidth: true
                text: "Prevent moving to previous/next line with horizontal movement"
                onCheckedChanged: fullScreenItem.settings.cursorMoverWorkaround = checked
                Binding {
                    target: cursorMoverWorkaround
                    property: "checked"
                    value: fullScreenItem.settings.cursorMoverWorkaround
                }
            }
            MKSliderItem {
                id: horizontalSwipeCursorSensitivity

                Layout.fillWidth: true
                Layout.margins: units.gu(2)

                title: "Horizontal sensitivity (high to low)"
                stepSize: 0.2
                minimumValue: 0.2
                maximumValue: 7
                resetValue: 1
                showCurrentValue: false
                onValueChanged: fullScreenItem.settings.horizontalSwipeCursorSensitivity = value
                Binding {
                    target: horizontalSwipeCursorSensitivity
                    property: "value"
                    value: fullScreenItem.settings.horizontalSwipeCursorSensitivity
                }
            }
            MKSliderItem {
                id: verticalSwipeCursorSensitivity

                Layout.fillWidth: true
                Layout.margins: units.gu(2)

                title: "Vertical sensitivity (high to low)"
                stepSize: 0.2
                minimumValue: 0.2
                maximumValue: 10
                resetValue: 4
                showCurrentValue: false
                onValueChanged: fullScreenItem.settings.verticalSwipeCursorSensitivity = value
                Binding {
                    target: verticalSwipeCursorSensitivity
                    property: "value"
                    value: fullScreenItem.settings.verticalSwipeCursorSensitivity
                }
            }
            MKSliderItem {
                id: cursorMoverTimeout

                Layout.fillWidth: true
                Layout.margins: units.gu(2)

                title: "Automatic exit timeout [0 = No Timeout] (ms)"
                minimumValue: 0
                maximumValue: 10000
                resetValue: 5000
                stepSize: 500
                onValueChanged: fullScreenItem.settings.cursorMoverTimeout = value
                Binding {
                    target: cursorMoverTimeout
                    property: "value"
                    value: fullScreenItem.settings.cursorMoverTimeout
                }
            }
        }
    }
    Component {
        id: appearancePage
        
        MKSettingsPage {
            MKSettingsNavItem {
                Layout.fillWidth: true
                text: "Dimensions"
                onClicked: settingsLoader.item.stack.push(dimensionsPage, {"title": text})
            }
            MKSettingsNavItem {
                Layout.fillWidth: true
                text: "Theming"
                onClicked: settingsLoader.item.stack.push(themePage, {"title": text})
            }
            QQC2.CheckDelegate {
                id: showNumberRow
                Layout.fillWidth: true
                text: "Always show a number row"
                onCheckedChanged: fullScreenItem.settings.showNumberRow = checked
                Binding {
                    target: showNumberRow
                    property: "checked"
                    value: fullScreenItem.settings.showNumberRow
                }
            }
            QQC2.CheckDelegate {
                id: hideCursorModeText
                Layout.fillWidth: true
                text: "Hide text in cursor mode"
                onCheckedChanged: fullScreenItem.settings.hideCursorModeText = checked
                Binding {
                    target: hideCursorModeText
                    property: "checked"
                    value: fullScreenItem.settings.hideCursorModeText
                }
            }
            QQC2.CheckDelegate {
                id: hideUrlKey
                Layout.fillWidth: true
                text: "Disable domain key (key with .com, .org, .co.uk, etc)"
                onCheckedChanged: fullScreenItem.settings.hideUrlKey = checked
                Binding {
                    target: hideUrlKey
                    property: "checked"
                    value: fullScreenItem.settings.hideUrlKey
                }
            }
            QQC2.CheckDelegate {
                id: bottomGesturehint
                Layout.fillWidth: true
                text: "Show bottom gesture hint"
                onCheckedChanged: fullScreenItem.settings.bottomGesturehint = checked
                Binding {
                    target: bottomGesturehint
                    property: "checked"
                    value: fullScreenItem.settings.bottomGesturehint
                }
            }
        }
    }
    Component {
        id: dimensionsPage
        
        MKSettingsPage {
            MKSettingsNavItem {
                Layout.fillWidth: true
                text: "Custom Height"
                onClicked: settingsLoader.item.stack.push(customHeightPage, {"title": text})
            }
            MKSettingsNavItem {
                Layout.fillWidth: true
                text: "Custom Ribbon Height"
                onClicked: settingsLoader.item.stack.push(customRibbonHeightPage, {"title": text})
            }
        }
    }
    Component {
        id: themePage
        
        MKSettingsPage {
            QQC2.CheckDelegate {
                id: followSystemTheme
                Layout.fillWidth: true
                text: "Follow system theme"
                onCheckedChanged: fullScreenItem.settings.followSystemTheme = checked
                Binding {
                    target: followSystemTheme
                    property: "checked"
                    value: fullScreenItem.settings.followSystemTheme
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: fullScreenItem.settings.followSystemTheme
                text: i18n.tr("Light theme")
                model: [
                    "Ambiance"
                    , "JustWhite"
                    , "BorderedWhite"
                    , "CustomLight"
                ]
                containerHeight: itemHeight * 6
                selectedIndex: model.indexOf(fullScreenItem.settings.lightTheme)
                onSelectedIndexChanged: fullScreenItem.settings.lightTheme = model[selectedIndex]
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: fullScreenItem.settings.followSystemTheme
                text: i18n.tr("Dark theme")
                model: [
                    "SuruDark"
                    , "SuruBlack"
                    , "JustBlack"
                    , "JustGrey"
                    , "BorderedBlack"
                    , "BorderedGrey"
                    , "CustomDark"
                ]
                containerHeight: itemHeight * 6
                selectedIndex: model.indexOf(fullScreenItem.settings.darkTheme)
                onSelectedIndexChanged: fullScreenItem.settings.darkTheme = model[selectedIndex]
            }
            QQC2.CheckDelegate {
                id: useCustomTheme
                Layout.fillWidth: true
                text: "Use custom theme"
                visible: !fullScreenItem.settings.followSystemTheme
                onCheckedChanged: fullScreenItem.settings.useCustomTheme = checked
                Binding {
                    target: useCustomTheme
                    property: "checked"
                    value: fullScreenItem.settings.useCustomTheme
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: fullScreenItem.useCustomTheme
                text: i18n.tr("Custom theme")
                model: [
                    "CustomLight"
                    , "CustomDark"
                ]
                containerHeight: itemHeight * 6
                selectedIndex: model.indexOf(fullScreenItem.settings.customTheme)
                onSelectedIndexChanged: fullScreenItem.settings.customTheme = model[selectedIndex]
            }
            MKSettingsNavItem {
                Layout.fillWidth: true
                text: "Custom Light Theme"
                onClicked: settingsLoader.item.stack.push(customLightPage, {"title": text})
            }
            MKSettingsNavItem {
                Layout.fillWidth: true
                text: "Custom Dark Theme"
                onClicked: settingsLoader.item.stack.push(customDarkPage, {"title": text})
            }
            QQC2.CheckDelegate {
                id: useCustomFont
                Layout.fillWidth: true
                text: "Use custom font"
                onCheckedChanged: fullScreenItem.settings.useCustomFont = checked
                Binding {
                    target: useCustomFont
                    property: "checked"
                    value: fullScreenItem.settings.useCustomFont
                }
            }
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: fullScreenItem.settings.useCustomFont
                text: i18n.tr("Custom font")
                model: Qt.fontFamilies()
                containerHeight: itemHeight * 6
                selectedIndex: model.indexOf(fullScreenItem.settings.customFont)
                onSelectedIndexChanged: fullScreenItem.settings.customFont = model[selectedIndex]
            }
        }
    }
    Component {
        id: customLightPage
        
        MKSettingsPage {
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)

                text: i18n.tr("Base Theme")
                model: [
                    "Lomiri.Components.Themes.Ambiance"
                    , "Lomiri.Components.Themes.SuruDark"
                ]
                containerHeight: itemHeight * 6
                selectedIndex: model.indexOf(fullScreenItem.settings.customLightTheme.toolkitTheme)
                onSelectedIndexChanged: {
                    let temp = fullScreenItem.settings.customLightTheme
                    temp.toolkitTheme = model[selectedIndex]
                    fullScreenItem.settings.customLightTheme = temp
                }
            }
            MKColorField {
                id: fontColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Font color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customLightTheme
                    temp.fontColor = text
                    fullScreenItem.settings.customLightTheme = temp
                }
                onColorPicker: colorPickerLoader.open(fontColor)
                Binding {
                    target: fontColor
                    property: "text"
                    value: fullScreenItem.settings.customLightTheme.fontColor
                }
            }
            MKColorField {
                id: selectionColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Selection color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customLightTheme
                    temp.selectionColor = text
                    fullScreenItem.settings.customLightTheme = temp
                }
                onColorPicker: colorPickerLoader.open(selectionColor)
                Binding {
                    target: selectionColor
                    property: "text"
                    value: fullScreenItem.settings.customLightTheme.selectionColor
                }
            }
            MKColorField {
                id: backgroundColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Background color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customLightTheme
                    temp.backgroundColor = text
                    fullScreenItem.settings.customLightTheme = temp
                }
                onColorPicker: colorPickerLoader.open(backgroundColor)
                Binding {
                    target: backgroundColor
                    property: "text"
                    value: fullScreenItem.settings.customLightTheme.backgroundColor
                }
            }
            MKColorField {
                id: dividerColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Divider color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customLightTheme
                    temp.dividerColor = text
                    fullScreenItem.settings.customLightTheme = temp
                }
                onColorPicker: colorPickerLoader.open(dividerColor)
                Binding {
                    target: dividerColor
                    property: "text"
                    value: fullScreenItem.settings.customLightTheme.dividerColor
                }
            }
            MKColorField {
                id: annotationFontColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Annotation font color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customLightTheme
                    temp.annotationFontColor = text
                    fullScreenItem.settings.customLightTheme = temp
                }
                onColorPicker: colorPickerLoader.open(annotationFontColor)
                Binding {
                    target: annotationFontColor
                    property: "text"
                    value: fullScreenItem.settings.customLightTheme.annotationFontColor
                }
            }
            MKColorField {
                id: charKeyColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Character keys color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customLightTheme
                    temp.charKeyColor = text
                    fullScreenItem.settings.customLightTheme = temp
                }
                onColorPicker: colorPickerLoader.open(charKeyColor)
                Binding {
                    target: charKeyColor
                    property: "text"
                    value: fullScreenItem.settings.customLightTheme.charKeyColor
                }
            }
            MKColorField {
                id: charKeyPressedColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Character keys pressed color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customLightTheme
                    temp.charKeyPressedColor = text
                    fullScreenItem.settings.customLightTheme = temp
                }
                onColorPicker: colorPickerLoader.open(charKeyPressedColor)
                Binding {
                    target: charKeyPressedColor
                    property: "text"
                    value: fullScreenItem.settings.customLightTheme.charKeyPressedColor
                }
            }
            MKColorField {
                id: actionKeyColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Action keys color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customLightTheme
                    temp.actionKeyColor = text
                    fullScreenItem.settings.customLightTheme = temp
                }
                onColorPicker: colorPickerLoader.open(actionKeyColor)
                Binding {
                    target: actionKeyColor
                    property: "text"
                    value: fullScreenItem.settings.customLightTheme.actionKeyColor
                }
            }
            MKColorField {
                id: actionKeyPressedColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Action keys pressed color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customLightTheme
                    temp.actionKeyPressedColor = text
                    fullScreenItem.settings.customLightTheme = temp
                }
                onColorPicker: colorPickerLoader.open(actionKeyPressedColor)
                Binding {
                    target: actionKeyPressedColor
                    property: "text"
                    value: fullScreenItem.settings.customLightTheme.actionKeyPressedColor
                }
            }
            MKColorField {
                id: popupBorderColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Key popup border color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customLightTheme
                    temp.popupBorderColor = text
                    fullScreenItem.settings.customLightTheme = temp
                }
                onColorPicker: colorPickerLoader.open(popupBorderColor)
                Binding {
                    target: popupBorderColor
                    property: "text"
                    value: fullScreenItem.settings.customLightTheme.popupBorderColor
                }
            }
            QQC2.CheckDelegate {
                id: keyBorderEnabled
                Layout.fillWidth: true
                text: "Enable key borders"
                onCheckedChanged: {
                    let temp = fullScreenItem.settings.customLightTheme
                    temp.keyBorderEnabled = checked
                    fullScreenItem.settings.customLightTheme = temp
                }
                Binding {
                    target: keyBorderEnabled
                    property: "checked"
                    value: fullScreenItem.settings.customLightTheme.keyBorderEnabled
                }
            }
            MKColorField {
                id: charKeyBorderColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Character keys border color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customLightTheme
                    temp.charKeyBorderColor = text
                    fullScreenItem.settings.customLightTheme = temp
                }
                onColorPicker: colorPickerLoader.open(charKeyBorderColor)
                Binding {
                    target: charKeyBorderColor
                    property: "text"
                    value: fullScreenItem.settings.customLightTheme.charKeyBorderColor
                }
            }
            MKColorField {
                id: actionKeyBorderColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Action keys border color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customLightTheme
                    temp.actionKeyBorderColor = text
                    fullScreenItem.settings.customLightTheme = temp
                }
                onColorPicker: colorPickerLoader.open(actionKeyBorderColor)
                Binding {
                    target: actionKeyBorderColor
                    property: "text"
                    value: fullScreenItem.settings.customLightTheme.actionKeyBorderColor
                }
            }
        }
    }
    Component {
        id: customDarkPage
        
        MKSettingsPage {
            OptionSelector {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)

                text: i18n.tr("Base Theme")
                model: [
                    "Lomiri.Components.Themes.Ambiance"
                    , "Lomiri.Components.Themes.SuruDark"
                ]
                containerHeight: itemHeight * 6
                selectedIndex: model.indexOf(fullScreenItem.settings.customDarkTheme.toolkitTheme)
                onSelectedIndexChanged: {
                    let temp = fullScreenItem.settings.customDarkTheme
                    temp.toolkitTheme = model[selectedIndex]
                    fullScreenItem.settings.customDarkTheme = temp
                }
            }
            MKColorField {
                id: fontColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Font color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customDarkTheme
                    temp.fontColor = text
                    fullScreenItem.settings.customDarkTheme = temp
                }
                onColorPicker: colorPickerLoader.open(fontColor)
                Binding {
                    target: fontColor
                    property: "text"
                    value: fullScreenItem.settings.customDarkTheme.fontColor
                }
            }
            MKColorField {
                id: selectionColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Selection color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customDarkTheme
                    temp.selectionColor = text
                    fullScreenItem.settings.customDarkTheme = temp
                }
                onColorPicker: colorPickerLoader.open(selectionColor)
                Binding {
                    target: selectionColor
                    property: "text"
                    value: fullScreenItem.settings.customDarkTheme.selectionColor
                }
            }
            MKColorField {
                id: backgroundColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Background color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customDarkTheme
                    temp.backgroundColor = text
                    fullScreenItem.settings.customDarkTheme = temp
                }
                onColorPicker: colorPickerLoader.open(backgroundColor)
                Binding {
                    target: backgroundColor
                    property: "text"
                    value: fullScreenItem.settings.customDarkTheme.backgroundColor
                }
            }
            MKColorField {
                id: dividerColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Divider color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customDarkTheme
                    temp.dividerColor = text
                    fullScreenItem.settings.customDarkTheme = temp
                }
                onColorPicker: colorPickerLoader.open(dividerColor)
                Binding {
                    target: dividerColor
                    property: "text"
                    value: fullScreenItem.settings.customDarkTheme.dividerColor
                }
            }
            MKColorField {
                id: annotationFontColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Annotation font color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customDarkTheme
                    temp.annotationFontColor = text
                    fullScreenItem.settings.customDarkTheme = temp
                }
                onColorPicker: colorPickerLoader.open(annotationFontColor)
                Binding {
                    target: annotationFontColor
                    property: "text"
                    value: fullScreenItem.settings.customDarkTheme.annotationFontColor
                }
            }
            MKColorField {
                id: charKeyColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Character keys color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customDarkTheme
                    temp.charKeyColor = text
                    fullScreenItem.settings.customDarkTheme = temp
                }
                onColorPicker: colorPickerLoader.open(charKeyColor)
                Binding {
                    target: charKeyColor
                    property: "text"
                    value: fullScreenItem.settings.customDarkTheme.charKeyColor
                }
            }
            MKColorField {
                id: charKeyPressedColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Character keys pressed color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customDarkTheme
                    temp.charKeyPressedColor = text
                    fullScreenItem.settings.customDarkTheme = temp
                }
                onColorPicker: colorPickerLoader.open(charKeyPressedColor)
                Binding {
                    target: charKeyPressedColor
                    property: "text"
                    value: fullScreenItem.settings.customDarkTheme.charKeyPressedColor
                }
            }
            MKColorField {
                id: actionKeyColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Action keys color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customDarkTheme
                    temp.actionKeyColor = text
                    fullScreenItem.settings.customDarkTheme = temp
                }
                onColorPicker: colorPickerLoader.open(actionKeyColor)
                Binding {
                    target: actionKeyColor
                    property: "text"
                    value: fullScreenItem.settings.customDarkTheme.actionKeyColor
                }
            }
            MKColorField {
                id: actionKeyPressedColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Action keys pressed color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customDarkTheme
                    temp.actionKeyPressedColor = text
                    fullScreenItem.settings.customDarkTheme = temp
                }
                onColorPicker: colorPickerLoader.open(actionKeyPressedColor)
                Binding {
                    target: actionKeyPressedColor
                    property: "text"
                    value: fullScreenItem.settings.customDarkTheme.actionKeyPressedColor
                }
            }
            MKColorField {
                id: popupBorderColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Key popup border color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customDarkTheme
                    temp.popupBorderColor = text
                    fullScreenItem.settings.customDarkTheme = temp
                }
                onColorPicker: colorPickerLoader.open(popupBorderColor)
                Binding {
                    target: popupBorderColor
                    property: "text"
                    value: fullScreenItem.settings.customDarkTheme.popupBorderColor
                }
            }
            QQC2.CheckDelegate {
                id: keyBorderEnabled
                Layout.fillWidth: true
                text: "Enable key borders"
                onCheckedChanged: {
                    let temp = fullScreenItem.settings.customDarkTheme
                    temp.keyBorderEnabled = checked
                    fullScreenItem.settings.customDarkTheme = temp
                }
                Binding {
                    target: keyBorderEnabled
                    property: "checked"
                    value: fullScreenItem.settings.customDarkTheme.keyBorderEnabled
                }
            }
            MKColorField {
                id: charKeyBorderColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Character keys border color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customDarkTheme
                    temp.charKeyBorderColor = text
                    fullScreenItem.settings.customDarkTheme = temp
                }
                onColorPicker: colorPickerLoader.open(charKeyBorderColor)
                Binding {
                    target: charKeyBorderColor
                    property: "text"
                    value: fullScreenItem.settings.customDarkTheme.charKeyBorderColor
                }
            }
            MKColorField {
                id: actionKeyBorderColor
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                title: "Action keys border color"
                onTextChanged: {
                    let temp = fullScreenItem.settings.customDarkTheme
                    temp.actionKeyBorderColor = text
                    fullScreenItem.settings.customDarkTheme = temp
                }
                onColorPicker: colorPickerLoader.open(actionKeyBorderColor)
                Binding {
                    target: actionKeyBorderColor
                    property: "text"
                    value: fullScreenItem.settings.customDarkTheme.actionKeyBorderColor
                }
            }
        }
    }
    Component {
        id: customHeightPage
        
        MKSettingsPage {
            id: customHeightPageItem

            function setResizeMode(mode) {
                fullScreenItem.resizeMode = mode
                if (mode) {
                    settingsLoader.keyboardPreview = true
                }
            }
            Component.onCompleted: setResizeMode(true)
            Component.onDestruction: setResizeMode(false)
            QQC2.CheckDelegate {
                id: useCustomHeight
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: {
                    fullScreenItem.settings.useCustomHeight = checked
                    customHeightPageItem.setResizeMode(checked)
                }
                Binding {
                    target: useCustomHeight
                    property: "checked"
                    value: fullScreenItem.settings.useCustomHeight
                }
            }
            MKSliderItem {
                id: customPortraitHeight
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: fullScreenItem.settings.useCustomHeight
                title: "Portrait Height (in %)"
                minimumValue: 0.2
                maximumValue: 0.7
                resetValue: 0.31
                percentageValue: true
                onValueChanged: fullScreenItem.settings.customPortraitHeight = value
                Binding {
                    target: customPortraitHeight
                    property: "value"
                    value: fullScreenItem.settings.customPortraitHeight
                }
            }
            MKSliderItem {
                id: customLandscapeHeight
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: fullScreenItem.settings.useCustomHeight
                title: "Landscape Height (in %)"
                minimumValue: 0.3
                maximumValue: 0.7
                resetValue: 0.49
                percentageValue: true
                onValueChanged: fullScreenItem.settings.customLandscapeHeight = value
                Binding {
                    target: customLandscapeHeight
                    property: "value"
                    value: fullScreenItem.settings.customLandscapeHeight
                }
            }
        }
    }
    Component {
        id: customRibbonHeightPage
        
        MKSettingsPage {
            QQC2.CheckDelegate {
                id: useCustomRibbonHeight
                Layout.fillWidth: true
                text: "Enable"
                onCheckedChanged: fullScreenItem.settings.useCustomRibbonHeight = checked
                Binding {
                    target: useCustomRibbonHeight
                    property: "checked"
                    value: fullScreenItem.settings.useCustomRibbonHeight
                }
            }
            MKSliderItem {
                id: customRibbonHeight
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: fullScreenItem.settings.customRibbonHeight
                title: "Height (in Grid Unit)"
                minimumValue: 2
                maximumValue: 10
                resetValue: 6
                onValueChanged: fullScreenItem.settings.customRibbonHeight = value
                Binding {
                    target: customRibbonHeight
                    property: "value"
                    value: fullScreenItem.settings.customRibbonHeight
                }
            }
            MKSliderItem {
                id: customRibbonFontSize
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                visible: fullScreenItem.settings.customRibbonFontSize
                title: "Font Size (in density pixel)"
                minimumValue: 10
                maximumValue: 30
                resetValue: 17
                onValueChanged: fullScreenItem.settings.customRibbonFontSize = value
                Binding {
                    target: customRibbonFontSize
                    property: "value"
                    value: fullScreenItem.settings.customRibbonFontSize
                }
            }
        }
    }
    // ENH070 - End
    

    Item {
        id: canvas
        objectName: "lomiriKeyboard" // Allow us to specify a specific keyboard within autopilot.

        // ENH071 - Custom height
        property real addedHeight: wordRibbon.height + borderTop.height + keyboardSurface.addBottomMargin
        // property real keyboardHeight: (fullScreenItem.oneHanded ? keyboardSurface.oneHandedWidth * UI.oneHandedHeight
        //                     : fullScreenItem.height * (fullScreenItem.landscape ? fullScreenItem.tablet ? UI.tabletKeyboardHeightLandscape 
        //                                                                                                                   : UI.phoneKeyboardHeightLandscape
        //                                                                                     : fullScreenItem.tablet ? UI.tabletKeyboardHeightPortrait 
        //                                                                                                                   : UI.phoneKeyboardHeightPortrait))
        //                               + wordRibbon.height + borderTop.height + keyboardSurface.addBottomMargin
        property real keyboardHeight: {
            var multiplier
            var mainHeight

            if (fullScreenItem.landscape) {
                if (fullScreenItem.settings.useCustomHeight) {
                    multiplier = fullScreenItem.settings.customLandscapeHeight
                } else {
                    if (fullScreenItem.tablet) {
                        multiplier = UI.tabletKeyboardHeightLandscape 
                    } else {
                        multiplier = UI.phoneKeyboardHeightLandscape
                    }
                }
            } else {
                if (fullScreenItem.settings.useCustomHeight > 0) {
                    multiplier = fullScreenItem.settings.customPortraitHeight
                } else {
                    if (fullScreenItem.tablet) {
                        multiplier = UI.tabletKeyboardHeightPortrait 
                    } else {
                        multiplier = UI.phoneKeyboardHeightPortrait
                    }
                }
            }

            mainHeight = fullScreenItem.height *  multiplier

            return mainHeight + addedHeight
        }
        // ENH071 - End

        anchors.bottom: parent.bottom
        anchors.left: parent.left

        width: parent.width
        height: keyboardHeight

        visible: true

        property bool wordribbon_visible: maliit_word_engine.enabled
        onWordribbon_visibleChanged: fullScreenItem.reportKeyboardVisibleRect();

        property bool languageMenuShown: false
        property bool extendedKeysShown: false

        property bool firstShow: true
        property bool hidingComplete: false

        property string layoutId: "freetext"

        onXChanged: fullScreenItem.reportKeyboardVisibleRect();
        onYChanged: fullScreenItem.reportKeyboardVisibleRect();
        onWidthChanged: {
            fullScreenItem.reportKeyboardVisibleRect();
            if (fullScreenItem.keyboardFloating) {
                keyboardSurface.returnToBoundsX(keyboardSurface.x)
            }
        }
        onHeightChanged: {
            fullScreenItem.reportKeyboardVisibleRect();
            if (fullScreenItem.keyboardFloating) {
                keyboardSurface.returnToBoundsY(keyboardSurface.floatY)
            }
        }
        // ENH070 - Keyboard settings
        onHidingCompleteChanged: if (hidingComplete) fullScreenItem.hideSettings()
        // ENH070 - End

        // These rectangles are outside canvas so that they can still be drawn even if layer.enabled is true
        Rectangle {
            id: keyboardBorder

            visible: keyboardSurface.visible
            border.color: fullScreenItem.theme.popupBorderColor
            border.width: units.gu(UI.keyboardBorderWidth)
            color: "transparent"
            opacity: keyboardSurface.opacity
            anchors {
                fill: keyboardSurface
                margins: units.gu(-UI.keyboardBorderWidth)
            }
        }

        Rectangle {
            id: dividerRect

            width: units.dp(1)
            color: fullScreenItem.theme.dividerColor
            opacity: keyboardSurface.opacity
            visible: keyboardSurface.visible
            anchors {
                left: keyboardSurface.left
                top: keyboardSurface.top
                bottom: keyboardSurface.bottom
            }
        }

        Item {
            id: keyboardSurface
            objectName: "keyboardSurface"

            readonly property real oneHandedWidth: Math.min(canvas.width
                                    * (fullScreenItem.tablet ? fullScreenItem.landscape ? UI.tabletOneHandedPreferredWidthLandscape : UI.tabletOneHandedPreferredWidthPortrait
                                                    : fullScreenItem.landscape ? UI.phoneOneHandedPreferredWidthLandscape : UI.phoneOneHandedPreferredWidthPortrait)
                                    , fullScreenItem.tablet ? units.gu(UI.tabletOneHandedMaxWidth) : units.gu(UI.phoneOneHandedMaxWidth))

            // Additional bottom margin when in floating mode to make it easier to use bottom swipe
            readonly property real addBottomMargin: fullScreenItem.keyboardFloating ? units.gu(2) : 0
            readonly property real defaultBottomMargin: units.gu(UI.bottom_margin)

            readonly property real fixedY: 0
            readonly property real floatBottomY: canvas.height - height
            property real floatY: canvas.height - height
            property real floatInitialX: (canvas.width / 2) - (width / 2)
            property bool positionedToLeft: true
            property bool noActivity: false

            x:0
            y:0
            width: parent.width
            height: canvas.keyboardHeight
            
            opacity: fullScreenItem.keyboardFloating && maliit_input_method.opacity == 1 
                        && (dragButton.pressed || noActivity) ? maliit_input_method.opacity / 2 : maliit_input_method.opacity
            // ENH093 - Fix layer of keybaord surface
            // layer.enabled: dragButton.pressed || noActivity
            layer.enabled: fullScreenItem.keyboardFloating && (dragButton.pressed || noActivity)
            // ENH093 - End

            onXChanged: fullScreenItem.reportKeyboardVisibleRect();
            onYChanged: fullScreenItem.reportKeyboardVisibleRect();
            onWidthChanged: fullScreenItem.reportKeyboardVisibleRect();
            onHeightChanged: fullScreenItem.reportKeyboardVisibleRect();

            onStateChanged: {
                fullScreenItem.reportKeyboardVisibleRect()
                fullScreenItem.usageMode = stateToSettings(state)
                if (state == "FLOATING") {
                    inactivityTimer.restart()
                }
            }

            // Do not initialize state when in floating mode to position the keyboard correctly on first show
            state: fullScreenItem.usageMode == "Floating" ? "" : keyboardSurface.settingsToState(fullScreenItem.usageMode)

            states: [
                State {
                    name: "FULL"

                    PropertyChanges { target: swipeArea; drag.minimumY: keyboardSurface.fixedY }
                    PropertyChanges { target: canvas; height: canvas.keyboardHeight }
                    PropertyChanges { target: keyboardSurface; width: canvas.width; y: keyboardSurface.fixedY; x: 0 }

                    // Action bar
                    PropertyChanges { target: actionBar; visible: false }
                    PropertyChanges { target: keyboardComp; anchors.rightMargin: 0; anchors.leftMargin: 0 }
                    PropertyChanges { target: cursorSwipeArea; anchors.rightMargin: 0; anchors.leftMargin: 0 }

                    // Borders
                    PropertyChanges { target: keyboardBorder; visible: false }
                    PropertyChanges { target: dividerRect; visible: false }
                }
                ,State {
                    name: "ONE-HANDED-LEFT"

                    PropertyChanges { target: swipeArea; drag.minimumY: keyboardSurface.fixedY }
                    PropertyChanges { target: canvas; height: canvas.keyboardHeight }
                    PropertyChanges { target: keyboardSurface; width: keyboardSurface.oneHandedWidth; y: keyboardSurface.fixedY; x: 0 }

                    // Action bar
                    PropertyChanges { target: actionBar; visible: true; x: keyboardSurface.width - width; alignment: Qt.AlignRight; }
                    PropertyChanges { target: keyboardComp; anchors.rightMargin: actionBar.width; anchors.leftMargin: 0 }
                    PropertyChanges { target: cursorSwipeArea; anchors.rightMargin: actionBar.width; anchors.leftMargin: 0 }

                    // Borders
                    PropertyChanges { target: keyboardBorder; visible: false }
                    PropertyChanges { target: dividerRect; visible: true }
                    AnchorChanges { target: dividerRect; anchors.left: keyboardSurface.right ; anchors.right: undefined }
                }
                ,State {
                    name: "ONE-HANDED-RIGHT"

                    PropertyChanges { target: swipeArea; drag.minimumY: keyboardSurface.fixedY }
                    PropertyChanges { target: canvas; height: canvas.keyboardHeight }
                    PropertyChanges { target: keyboardSurface; width: keyboardSurface.oneHandedWidth; y: keyboardSurface.fixedY; x: canvas.width - width }

                    // Action bar
                    PropertyChanges { target: actionBar; visible: true; x: 0; alignment: Qt.AlignLeft; }
                    PropertyChanges { target: keyboardComp; anchors.rightMargin: 0; anchors.leftMargin: actionBar.width }
                    PropertyChanges { target: cursorSwipeArea; anchors.rightMargin: 0; anchors.leftMargin: actionBar.width }

                    // Borders
                    PropertyChanges { target: keyboardBorder; visible: false }
                    PropertyChanges { target: dividerRect; visible: true }
                    AnchorChanges { target: dividerRect; anchors.left: undefined ; anchors.right: keyboardSurface.left }
                }
                ,State {
                    name: "FLOATING"

                    PropertyChanges { target: swipeArea; drag.minimumY: keyboardSurface.floatY }
                    PropertyChanges { target: canvas; height: fullScreenItem.height }
                    PropertyChanges { target: keyboardSurface; width: keyboardSurface.oneHandedWidth; y: keyboardSurface.floatBottomY; x: keyboardSurface.floatInitialX; noActivity: false }

                    // Action bar
                    PropertyChanges { target: actionBar; visible: true; x: keyboardSurface.positionedToLeft ? keyboardSurface.width - width : 0; alignment: keyboardSurface.positionedToLeft ? Qt.AlignRight : Qt.AlignLeft; }
                    PropertyChanges {
                        target: keyboardComp;
                        anchors.rightMargin: keyboardSurface.positionedToLeft ? actionBar.width : 0;
                        anchors.leftMargin: keyboardSurface.positionedToLeft ? 0 : actionBar.width
                    }
                    PropertyChanges {
                        target: cursorSwipeArea;
                        anchors.rightMargin: keyboardSurface.positionedToLeft ? actionBar.width : 0;
                        anchors.leftMargin: keyboardSurface.positionedToLeft ? 0 : actionBar.width
                    }

                    // Borders
                    PropertyChanges { target: keyboardBorder; visible: true }
                    PropertyChanges { target: dividerRect; visible: false }
                }
            ]

            function returnToBoundsX() {
                x = Qt.binding( function() { return getReturnToBoundsX(x); } )
            }

            function returnToBoundsY() {
                y = Qt.binding( function() { return getReturnToBoundsY(floatY); } )
                floatY = y
            }

            function getReturnToBoundsX(baseX) {
                var correctedX = baseX
                if (baseX < 0) {
                    correctedX = 0
                } else if (baseX + keyboardSurface.width > fullScreenItem.width) {
                    correctedX = fullScreenItem.width - keyboardSurface.width
                    if (correctedX < 0) {
                        correctedX = 0
                    }
                }
                return correctedX
            }

            function getReturnToBoundsY(baseY) {
                var correctedY = baseY
                if (baseY + keyboardSurface.height > fullScreenItem.height) {
                    correctedY = fullScreenItem.height - keyboardSurface.height
                }
                return correctedY
            }

            function stateToSettings(_state) {
                var _usageMode

                switch (_state) {
                    case "FULL":
                        _usageMode = "Full"
                        break
                    case "ONE-HANDED-LEFT":
                        _usageMode = "One-handed-left"
                        break
                    case "ONE-HANDED-RIGHT":
                        _usageMode = "One-handed-right"
                        break
                    case "FLOATING":
                        _usageMode = "Floating"
                        break
                    default:
                        _usageMode = "Full"
                        break
                }

                return _usageMode
            }

            function settingsToState(_usageMode) {
                var _state

                switch (_usageMode) {
                    case "Full":
                        _state = "FULL"
                        break
                    case "One-handed-left":
                        _state = "ONE-HANDED-LEFT"
                        break
                    case "One-handed-right":
                        _state = "ONE-HANDED-RIGHT"
                        break
                    case "Floating":
                        _state = "FLOATING"
                        break
                    default:
                        _state = "FULL"
                        break
                }

                return _state
            }

            transitions: [
                Transition {
                    from: "ONE-HANDED-LEFT"; to: "FLOATING";
                    PropertyAction { target: keyboardSurface; property: "positionedToLeft"; value: true }
                }
                ,Transition {
                    from: "ONE-HANDED-RIGHT"; to: "FLOATING";
                    PropertyAction { target: keyboardSurface; property: "positionedToLeft"; value: false }
                }
            ]

            Behavior on x { LomiriNumberAnimation {} }
            Behavior on width { LomiriNumberAnimation {} }

            // Use Standlone animation instead of Behavior to avoid conflict with y changes from PressArea
            LomiriNumberAnimation {
                id: yAnimation
                target: keyboardSurface
                duration: LomiriAnimation.FastDuration
                from: keyboardSurface.y
                property: "y"

                function startAnimation(toY) {
                    to = toY
                    start()
                }

                onStopped: keyboardSurface.floatY = yAnimation.to
            }

            PropertyAnimation {
                id: bounceBackAnimation
                target: keyboardSurface
                properties: "y"
                easing.type: Easing.OutBounce;
                easing.overshoot: 2.0
                to: fullScreenItem.keyboardFloating ? keyboardSurface.floatY : keyboardSurface.fixedY
            }

            Timer {
                id: inactivityTimer

                interval: 6000
                onTriggered: {
                    if (!fullScreenItem.cursorSwipe) {
                        keyboardSurface.noActivity = true
                    } else {
                        restart()
                    }
                }
            }

            MouseArea {
                id: activityMouseArea

                z: 100
                enabled: fullScreenItem.keyboardFloating
                anchors.fill: parent
                propagateComposedEvents: true

                onClicked: mouse.accepted = false;
                onReleased: mouse.accepted = false;
                onDoubleClicked: mouse.accepted = false;
                onPositionChanged: mouse.accepted = false;
                onPressAndHold: mouse.accepted = false;
                onPressed: {
                    keyboardSurface.noActivity = false
                    inactivityTimer.restart()
                    mouse.accepted = false;
                }
            }

            Rectangle {
                id: actionBar

                property int alignment

                color: fullScreenItem.theme.backgroundColor
                width: units.gu(UI.actionBarWidth)
                z: 2

                // Anchor is not used due to issues with dynamic anchor changes
                x: 0
                visible: false
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }

                ColumnLayout {
                    anchors.fill: parent

                    BarActionButton {
                        id: dragButton

                        readonly property bool dragActive: drag.active

                        Layout.fillWidth: true
                        Layout.preferredHeight: width
                        Layout.alignment: Qt.AlignTop | actionBar.alignment
                        iconName: "grip-large"

                        drag.target: keyboardSurface
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: 0
                        drag.maximumX: canvas.width - keyboardSurface.width
                        drag.minimumY: 0
                        drag.maximumY: canvas.height - keyboardSurface.height

                        onDragActiveChanged: {
                            if (!dragActive) {
                                keyboardSurface.floatY = keyboardSurface.y
                            }
                        }

                        onPressed: {
                            if (!dragActive && !fullScreenItem.keyboardFloating) {
                                keyboardSurface.floatInitialX = keyboardSurface.x
                                keyboardSurface.state = "FLOATING"
                            }
                        }
                    }

                    BarActionButton {
                        Layout.preferredWidth: parent.width * 0.80
                        Layout.fillHeight: true
                        Layout.preferredHeight: width
                        Layout.alignment: actionBar.alignment
                        iconName: "go-last"
                        visible: keyboardSurface.state == "ONE-HANDED-LEFT" 
                                    || (fullScreenItem.keyboardFloating 
                                            && (keyboardSurface.x + keyboardSurface.width !== canvas.width || keyboardSurface.positionedToLeft))

                        onClicked: {
                            if (fullScreenItem.keyboardFloating) {
                                keyboardSurface.x = canvas.width - keyboardSurface.width
                                keyboardSurface.positionedToLeft = false
                            } else {
                                keyboardSurface.state = "ONE-HANDED-RIGHT"
                            }
                        }
                    }

                    BarActionButton {
                        Layout.preferredWidth: parent.width * 0.80
                        Layout.fillHeight: true
                        Layout.preferredHeight: width
                        Layout.alignment: actionBar.alignment
                        iconName: "go-first"
                        visible: keyboardSurface.state == "ONE-HANDED-RIGHT"
                                    || (fullScreenItem.keyboardFloating
                                            && (keyboardSurface.x !== 0 || !keyboardSurface.positionedToLeft))

                        onClicked: {
                            if (fullScreenItem.keyboardFloating) {
                                keyboardSurface.x = 0
                                keyboardSurface.positionedToLeft = true
                            } else {
                                keyboardSurface.state = "ONE-HANDED-LEFT"
                            }
                        }
                    }

                    BarActionButton {
                        Layout.preferredWidth: parent.width * 0.80
                        Layout.fillHeight: true
                        Layout.preferredHeight: width
                        Layout.alignment: actionBar.alignment
                        iconName: "go-last"
                        iconRotation: 90
                        visible: fullScreenItem.keyboardFloating && keyboardSurface.y + keyboardSurface.height < canvas.height

                        onClicked: {
                            yAnimation.startAnimation(keyboardSurface.floatBottomY)
                        }
                    }

                    BarActionButton {
                        Layout.preferredWidth: parent.width * 0.80
                        Layout.alignment: Qt.AlignBottom | actionBar.alignment
                        Layout.preferredHeight: width
                        iconName: "view-fullscreen"
                        visible: keyboardSurface.state !== "FULL"

                        onClicked: {
                            keyboardSurface.state = "FULL"
                        }
                    }
                }
            }

            Rectangle {
                height: units.dp(1)
                color: fullScreenItem.theme.dividerColor
                anchors {
                    bottom: wordRibbon.visible ? swipeArea.top : keyboardComp.top
                    left: parent.left
                    right: parent.right
                }
            }

            MouseArea {
                id: swipeArea

                property int jumpBackThreshold: units.gu(10)

                anchors {
                    bottom: keyboardComp.top
                    left: keyboardComp.left
                    right: keyboardComp.right
                }

                height: wordRibbon.height + borderTop.height

                drag.target: keyboardSurface
                drag.axis: Drag.YAxis;
                drag.minimumY: 0
                drag.maximumY: canvas.height
                //fix for lp:1277186
                //only filter children when wordRibbon visible
                drag.filterChildren: wordRibbon.visible
                // Avoid conflict with extended key swipe selection and cursor swipe mode
                enabled: !canvas.extendedKeysShown && !fullScreenItem.cursorSwipe

                onReleased: {
                    var baseY = fullScreenItem.keyboardFloating ? keyboardSurface.floatY : keyboardSurface.fixedY
                    if (keyboardSurface.y > baseY + jumpBackThreshold) {
                        maliit_geometry.shown = false;
                    } else {
                        bounceBackAnimation.from = keyboardSurface.y
                        bounceBackAnimation.start();
                    }
                }

                WordRibbon {
                    id: wordRibbon
                    objectName: "wordRibbon"

                    visible: canvas.wordribbon_visible

                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                    }
                    // ENH072 - Custom ribbon height
                    // height: canvas.wordribbon_visible ? (fullScreenItem.tablet ? units.gu(UI.tabletWordribbonHeight)
                    //                                                            : units.gu(UI.phoneWordribbonHeight))
                    //                                   : 0
                    height: {
                        if (canvas.wordribbon_visible) {
                            if (fullScreenItem.settings.useCustomRibbonHeight) {
                                return units.gu(fullScreenItem.settings.customRibbonHeight)
                            } else {
                                if (fullScreenItem.tablet) {
                                    return units.gu(UI.tabletWordribbonHeight)
                                } else {
                                    return units.gu(UI.phoneWordribbonHeight)
                                }
                            }
                        }

                        return 0
                    }
                    // ENH072 - End
                    onHeightChanged: fullScreenItem.reportKeyboardVisibleRect();
                }
            }

            //TODO: Sets the theme for all UITK components used in the OSK. Replace those components to remove the need for this.
            ActionItem {
                id: dummy
                
                visible: false
                theme.name: fullScreenItem.theme.toolkitTheme
            }

            ActionsToolbar {
                id: toolbar
                objectName: "actionsToolbar"
                
                z: 1
                visible: fullScreenItem.cursorSwipe
                // ENH072 - Custom ribbon height
                // height: fullScreenItem.tablet ? units.gu(UI.tabletWordribbonHeight) : units.gu(UI.phoneWordribbonHeight)
                height: {
                    if (fullScreenItem.settings.useCustomRibbonHeight) {
                        return units.gu(fullScreenItem.settings.customRibbonHeight)
                    } else {
                        if (fullScreenItem.tablet) {
                            return units.gu(UI.tabletWordribbonHeight)
                        } else {
                            return units.gu(UI.phoneWordribbonHeight)
                        }
                    }
                }
                // ENH072 - End
                state: wordRibbon.visible ? "wordribbon" : "top"
                anchors {
                    left: keyboardComp.left
                    right: keyboardComp.right
                }
            }
                

            Item {
                id: keyboardComp
                objectName: "keyboardComp"

                height: canvas.keyboardHeight - wordRibbon.height + keypad.anchors.topMargin
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }

                onHeightChanged: fullScreenItem.reportKeyboardVisibleRect();

                Rectangle {
                    id: background

                    anchors.fill: parent

                    color: fullScreenItem.theme.backgroundColor
                }
            
                Item {
                    id: borderTop
                    width: parent.width
                    anchors.top: parent.top.bottom
                    height: wordRibbon.visible ? 0 : units.gu(UI.top_margin)
                }

                KeyboardContainer {
                    id: keypad

                    anchors.top: borderTop.bottom
                    anchors.bottom: background.bottom
                    anchors.bottomMargin: keyboardSurface.defaultBottomMargin + keyboardSurface.addBottomMargin
                    width: parent.width
                    // ENH086 - Do not hide key labels
                    // hideKeyLabels: fullScreenItem.cursorSwipe
                    // ENH086 - End

                    onPopoverEnabledChanged: fullScreenItem.reportKeyboardVisibleRect();
                }

                LanguageMenu {
                    id: languageMenu
                    objectName: "languageMenu"
                    anchors.centerIn: parent
                    height: contentHeight > keypad.height ? keypad.height : contentHeight
                    width: units.gu(30);
                    enabled: canvas.languageMenuShown
                    visible: canvas.languageMenuShown
                }
            } // keyboardComp

            FloatingActions {
                id: floatingActions
                objectName: "floatingActions"

                z: 1
                visible: fullScreenItem.cursorSwipe && !cursorSwipeArea.pressed && !bottomSwipe.pressed

                anchors {
                    top: parent.top
                    left: cursorSwipeArea.left
                    right: cursorSwipeArea.right
                    margins: units.gu(1)
                    topMargin: toolbar.height + units.gu(1)
                    bottom: cursorSwipeArea.bottom
                }
            }

            MouseArea {
                id: cursorSwipeArea

                property point lastRelease
                property bool selectionMode: false

                height: keyboardSurface.height - toolbar.height
                anchors {
                    fill: keyboardSurface
                    topMargin: toolbar.height
                }

                enabled: cursorSwipe

                Rectangle {
                    anchors.fill: parent
                    visible: parent.enabled
                    color: cursorSwipeArea.selectionMode ? fullScreenItem.theme.selectionColor : fullScreenItem.theme.charKeyPressedColor
                }

                function exitSelectionMode() {
                    selectionMode = false
                    fullScreenItem.timerSwipe.restart()
                }

                onSelectionModeChanged: {
                    if (fullScreenItem.cursorSwipe) {
                        fullScreenItem.keyFeedback();
                    }
                }

                onMouseXChanged: {
                    processSwipe(mouseX, mouseY)
                }

                onPressed: {
                    prevSwipePositionX = mouseX
                    prevSwipePositionY = mouseY
                    fullScreenItem.timerSwipe.stop()
                }

                onReleased: {
                    if (!cursorSwipeArea.selectionMode) {
                        fullScreenItem.timerSwipe.restart()
                    } else {
                        fullScreenItem.timerSwipe.stop()

                        // ENH075 - Select word settings
                        if (fullScreenItem.settings.enableSelectWord) {
                            // Select word when double tapped without selecting any text and cursor is in the middle of a word
                            if (!input_method.hasSelection && lastRelease === Qt.point(0,0)
                                        && input_method.surroundingLeft !== ""
                                        && input_method.surroundingRight !== ""
                                        && input_method.surroundingLeft.lastIndexOf("\n") !== input_method.surroundingLeft.length - 1
                                        && input_method.surroundingRight.indexOf("\n") !== 0
                                        && input_method.surroundingLeft.lastIndexOf(" ") !== input_method.surroundingLeft.length - 1
                                        && input_method.surroundingRight.indexOf(" ") !== 0) {
                                fullScreenItem.selectWord()
                            }
                        }
                        // ENH075 - End
                    }

                    lastRelease = Qt.point(mouse.x, mouse.y)
                }

                onDoubleClicked: {
                    // We avoid triggering double click accidentally by using a threshold
                    var xReleaseDiff = Math.abs(lastRelease.x - mouse.x)
                    var yReleaseDiff = Math.abs(lastRelease.y - mouse.y)

                    var threshold = units.gu(2)

                    if (xReleaseDiff < threshold && yReleaseDiff < threshold) {
                        if (!cursorSwipeArea.selectionMode) {
                            cursorSwipeArea.selectionMode = true
                            fullScreenItem.timerSwipe.stop()
                        } else {
                            exitSelectionMode();
                        }
                    }
                    // Reset lastRelease
                    lastRelease = Qt.point(0, 0)
                }
            }

            // ENH089 - Quick actions
            RowLayout {
                id: bottomGestures

                property real sideSwipeAreaWidth: keyboardSurface.width * (fullScreenItem.width > fullScreenItem.height && !fullScreenItem.oneHanded ? 0.15 : 0.30)

                z: floatingActions.z + 1
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    leftMargin: oneHanded && (keyboardSurface.state == "ONE-HANDED-RIGHT" || (fullScreenItem.keyboardFloating && !keyboardSurface.positionedToLeft))
                                            ? actionBar.width : 0
                    right: parent.right
                    rightMargin: oneHanded && (keyboardSurface.state == "ONE-HANDED-LEFT" || (fullScreenItem.keyboardFloating && keyboardSurface.positionedToLeft))
                                            ? actionBar.width : 0
                    top: parent.top
                }

                Loader {
                    id: leftSwipeAreaLoader

                    Layout.alignment: Qt.AlignLeft | Qt.AlignBottom

                    active: fullScreenItem.settings.enableQuickActions
                    asynchronous: true
                    visible: status == Loader.Ready
                    sourceComponent: MKBottomSwipeArea {
                        model: fullScreenItem.settings.quickActions[0] ? actionsFactory.getActionsModel(fullScreenItem.settings.quickActions[0])
                                        : []
                        implicitWidth: bottomGestures.sideSwipeAreaWidth
                        implicitHeight: bottomSwipe.height
                        triggerSignalOnQuickSwipe: true
                        enableQuickActions: fullScreenItem.settings.enableQuickActions
                        edge: MKBottomSwipeArea.Edge.Left
                        availableHeight: fullScreenItem.keyboardFloating ? keyboardSurface.y + keyboardSurface.height : fullScreenItem.height
                        availableWidth: fullScreenItem.width
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignBottom
                    
                    SwipeArea {
                        id: leftSwipe

                        property bool draggingCustom: distance >= units.gu(4)
                        height: bottomSwipe.height
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        direction: SwipeArea.Leftwards
                        immediateRecognition: false
                        grabGesture: false
                        visible: (keyboardSurface.state !== "ONE-HANDED-LEFT" || fullScreenItem.keyboardFloating) && !fullScreenItem.cursorSwipe

                        onDraggingCustomChanged: {
                            if (draggingCustom && touchPosition.y >= 0) {
                                switch (keyboardSurface.state) {
                                    case "ONE-HANDED-RIGHT":
                                        keyboardSurface.state = "FULL"
                                        break
                                    case "FULL":
                                        keyboardSurface.state = "ONE-HANDED-LEFT"
                                        break
                                    case "FLOATING":
                                        keyboardSurface.x = 0
                                        keyboardSurface.positionedToLeft = true
                                        break
                                }
                            }
                        }
                    }

                    SwipeArea {
                        id: rightSwipe

                        property bool draggingCustom: distance >= units.gu(4)
                        height: bottomSwipe.height
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        direction: SwipeArea.Rightwards
                        immediateRecognition: false
                        grabGesture: false
                        visible: (keyboardSurface.state !== "ONE-HANDED-RIGHT" || fullScreenItem.keyboardFloating) && !fullScreenItem.cursorSwipe

                        onDraggingCustomChanged: {
                            if (draggingCustom && touchPosition.y >= 0) {
                                switch (keyboardSurface.state) {
                                    case "ONE-HANDED-LEFT":
                                        keyboardSurface.state = "FULL"
                                        break
                                    case "FULL":
                                        keyboardSurface.state = "ONE-HANDED-RIGHT"
                                        break
                                    case "FLOATING":
                                        keyboardSurface.x = canvas.width - keyboardSurface.width
                                        keyboardSurface.positionedToLeft = false
                                        break
                                }
                            }
                        }
                    }

                    SwipeArea{
                        id: bottomSwipe
                        
                        property bool draggingCustom: distance >= units.gu(4)
                        property bool readyToSwipe: false

                        height: keypad.anchors.bottomMargin + units.gu(0.5)
                        anchors{
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        direction: SwipeArea.Upwards
                        immediateRecognition: true
                        grabGesture: false

                        onDraggingCustomChanged:{
                            if (dragging && !fullScreenItem.cursorSwipe) {
                                readyToSwipe = false
                                swipeDelay.restart()
                                fullScreenItem.cursorSwipe = true
                            }
                        }

                        onTouchPositionChanged: {
                            if (fullScreenItem.cursorSwipe && readyToSwipe) {
                                fullScreenItem.processSwipe(touchPosition.x, touchPosition.y)
                            }
                        }

                        onPressedChanged: {
                            if (!pressed) {
                                fullScreenItem.timerSwipe.restart()
                            }else{
                                fullScreenItem.timerSwipe.stop()
                            }
                        }

                        Timer {
                            id: swipeDelay
                            interval: 100
                            running: false
                            onTriggered: {
                                fullScreenItem.prevSwipePositionX = bottomSwipe.touchPosition.x
                                fullScreenItem.prevSwipePositionY = bottomSwipe.touchPosition.y
                                bottomSwipe.readyToSwipe = true
                            }
                        }
                    }

                    Icon {
                        id: bottomHint
                        name: "toolkit_bottom-edge-hint"
                        // ENH089 - Quick actions
                        // visible: !fullScreenItem.cursorSwipe
                        visible: !fullScreenItem.cursorSwipe && !fullScreenItem.settings.enableQuickActions
                                    // ENH090 - Bottom hint settings
                                    && fullScreenItem.settings.bottomGesturehint
                                    // ENH090 - End
                        // ENH089 - End
                        width: units.gu(3)
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                        }
                    }

                    MouseArea {
                        id: bottomEdgeHint

                        readonly property alias color: recVisual.color

                        hoverEnabled: true
                        enabled: false
                        height: units.gu(0.5)
                        visible: fullScreenItem.settings.enableQuickActions && !fullScreenItem.cursorSwipe
                                    // ENH090 - Bottom hint settings
                                    && fullScreenItem.settings.bottomGesturehint
                                    // ENH090 - End
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            bottomMargin: keypad.anchors.bottomMargin / 2
                        }

                        Rectangle {
                            id: recVisual
                            color: fullScreenItem.theme.actionKeyColor
                            radius: height / 2
                            height: units.gu(0.5)
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                right: parent.right
                            }
                        }
                    }
                }

                Loader {
                    id: rightSwipeAreaLoader

                    Layout.alignment: Qt.AlignRight | Qt.AlignBottom

                    active: fullScreenItem.settings.enableQuickActions
                    asynchronous: true
                    visible: status == Loader.Ready
                    sourceComponent: MKBottomSwipeArea {
                        model: fullScreenItem.settings.quickActions[1] ? actionsFactory.getActionsModel(fullScreenItem.settings.quickActions[1])
                                        : []
                        implicitWidth: bottomGestures.sideSwipeAreaWidth
                        implicitHeight: bottomSwipe.height
                        triggerSignalOnQuickSwipe: true
                        enableQuickActions: fullScreenItem.settings.enableQuickActions
                        edge: MKBottomSwipeArea.Edge.Right
                        availableHeight: fullScreenItem.keyboardFloating ? keyboardSurface.y + keyboardSurface.height : fullScreenItem.height
                        availableWidth: fullScreenItem.width
                    }
                }
            } // bottomGestures

        } //keyboardSurface

        state: "HIDDEN"

        states: [
            State {
                name: "SHOWN"
                PropertyChanges {
                    target: keyboardSurface;
                    y: fullScreenItem.keyboardFloating ? keyboardSurface.getReturnToBoundsY(keyboardSurface.floatY) : keyboardSurface.fixedY;
                    noActivity: false
                }
                onCompleted: {
                    if (canvas.firstShow) {
                        keyboardSurface.state = keyboardSurface.settingsToState(fullScreenItem.usageMode)
                    }
                    if (fullScreenItem.keyboardFloating) {
                        keyboardSurface.floatY = keyboardSurface.y
                        inactivityTimer.restart()
                    }
                    canvas.firstShow = false;
                    canvas.hidingComplete = false;
                }
                when: maliit_geometry.shown === true
            },

            State {
                name: "HIDDEN"
                PropertyChanges { target: keyboardSurface; y: canvas.height }
                onCompleted: {
                    canvas.languageMenuShown = false;
                    keypad.closeExtendedKeys();
                    keypad.activeKeypadState = "NORMAL";
                    keypad.state = "CHARACTERS";
                    maliit_input_method.close();
                    canvas.hidingComplete = true;
                    reportKeyboardVisibleRect();
                    // Switch back to the previous layout if we're in
                    // in a layout like emoji that requests switchBack
                    if (keypad.switchBack && maliit_input_method.previousLanguage) {
                        keypad.switchBack = false;
                        maliit_input_method.activeLanguage = maliit_input_method.previousLanguage;
                    }
                    
                    // Exit cursor swipe mode when the keyboard hides
                    fullScreenItem.exitSwipeMode();
                }
                // Wait for the first show operation to complete before
                // allowing hiding, as the conditions when the keyboard
                // has never been visible can trigger a hide operation
                when: maliit_geometry.shown === false && canvas.firstShow === false
            }
        ]
        transitions: Transition {
            LomiriNumberAnimation { target: keyboardSurface; properties: "y"; }
        }

        Connections {
            target: input_method
            onActivateAutocaps: {
                if (keypad.state == "CHARACTERS" && keypad.activeKeypadState != "CAPSLOCK" && !cursorSwipe) {
                    keypad.activeKeypadState = "SHIFTED";
                    keypad.autoCapsTriggered = true;
                } else {
                    keypad.delayedAutoCaps = true;
                }
            }

            onKeyboardReset: {
                keypad.state = "CHARACTERS"
            }
            onDeactivateAutocaps: {
                if(keypad.autoCapsTriggered) {
                    keypad.activeKeypadState = "NORMAL";
                    keypad.autoCapsTriggered = false;
                }
                keypad.delayedAutoCaps = false;
            }
            // ENH082 - Custom theme
            // onThemeChanged: Theme.load(target.theme)
            onThemeChanged: fullScreenItem.loadTheme()
            // ENH082 - End
        }
    } // canvas

    // ENH089 - Quick actions
    Item {
        id: actionsFactory

        readonly property var allActions: [
            { "id": "undo", "title": i18n.tr("Undo"), "component": actionUndo }
            , { "id": "redo", "title": i18n.tr("Redo"), "component": actionRedo }
            , { "id": "selectAll", "title": i18n.tr("Select all"), "component": actionSelectAll }
            , { "id": "cut", "title": i18n.tr("Cut"), "component": actionCut }
            , { "id": "copy", "title": i18n.tr("Copy"), "component": actionCopy }
            , { "id": "paste", "title": i18n.tr("Paste"), "component": actionPaste }
            , { "id": "goToStartLine", "title": i18n.tr("Go to start of line"), "component": actionGoToStartLine }
            , { "id": "goToEndLine", "title": i18n.tr("Go to end of line"), "component": actionGoToEndLine }
            , { "id": "goToStartDoc", "title": i18n.tr("Go to start of document"), "component": actionGoToStartDoc }
            , { "id": "goToEndDoc", "title": i18n.tr("Go to end of document"), "component": actionGoToEndDoc }
            , { "id": "selectCurrentWord", "title": i18n.tr("Select current word"), "component": actionSelectCurrentWord }
            , { "id": "selectPrevWord", "title": i18n.tr("Select previous word"), "component": actionSelectPrevWord }
            , { "id": "selectNextWord", "title": i18n.tr("Select next word"), "component": actionSelectNextWord }
            , { "id": "tab", "title": i18n.tr("Tab"), "component": actionTab }
            , { "id": "settings", "title": i18n.tr("Keyboard settings"), "component": actionSettings }
            , { "id": "mkSettings", "title": i18n.tr("Malakiboard settings"), "component": actionMKSettings }
        ]

        function getActionsModel(actionIDsList) {
            let newList = []
            actionIDsList.forEach( action => {
                newList.push(allActions.find(item => item.id == action.id).component)
            });

            return newList
        }

        MKBaseAction {
            id: actionUndo

            iconName: "edit-undo"
            text: i18n.tr("Undo")
            onTrigger: fullScreenItem.undo()
        }

        MKBaseAction {
            id: actionRedo

            iconName: "edit-redo"
            text: i18n.tr("Redo")
            onTrigger: fullScreenItem.redo()
        }

        MKBaseAction {
            id: actionSelectAll

            iconName: "edit-select-all"
            text: i18n.tr("Select all")
            onTrigger: fullScreenItem.selectAll()
        }

        MKBaseAction {
            id: actionCut

            iconName: "edit-cut"
            text: i18n.tr("Cut")
            onTrigger: fullScreenItem.cut()
        }

        MKBaseAction {
            id: actionCopy

            iconName: "edit-copy"
            text: i18n.tr("Copy")
            onTrigger: fullScreenItem.copy()
        }

        MKBaseAction {
            id: actionPaste

            iconName: "edit-paste"
            text: i18n.tr("Paste")
            onTrigger: fullScreenItem.paste()
        }

        MKBaseAction {
            id: actionGoToStartLine

            iconName: "go-first"
            text: i18n.tr("Go to start of line")
            onTrigger: fullScreenItem.moveToStartOfLine()
        }

        MKBaseAction {
            id: actionGoToEndLine

            iconName: "go-last"
            text: i18n.tr("Go to end of line")
            onTrigger: fullScreenItem.moveToEndOfLine()
        }

        MKBaseAction {
            id: actionGoToStartDoc

            iconName: "go-first"
            iconRotation: 90
            text: i18n.tr("Go to start of document")
            onTrigger: fullScreenItem.moveToStartOfDocument()
        }

        MKBaseAction {
            id: actionGoToEndDoc

            iconName: "go-last"
            iconRotation: 90
            text: i18n.tr("Go to end of document")
            onTrigger: fullScreenItem.moveToEndOfDocument()
        }

        MKBaseAction {
            id: actionSelectCurrentWord

            iconName: "edit-select-all"
            text: i18n.tr("Select current word")
            onTrigger: fullScreenItem.selectWord()
        }

        MKBaseAction {
            id: actionSelectPrevWord

            iconName: "previous"
            text: i18n.tr("Select previous word")
            onTrigger: fullScreenItem.selectPrevWord()
        }

        MKBaseAction {
            id: actionSelectNextWord

            iconName: "next"
            text: i18n.tr("Select next word")
            onTrigger: fullScreenItem.selectNextWord()
        }

        MKBaseAction {
            id: actionTab

            iconName: "keyboard-tab"
            text: i18n.tr("Tab")
            onTrigger: fullScreenItem.tab()
        }

        MKBaseAction {
            id: actionSettings

            iconName: "settings"
            text: i18n.tr("Keyboard settings")
            onTrigger: Qt.openUrlExternally("settings:///system/language")
        }

        MKBaseAction {
            id: actionMKSettings

            iconName: "settings"
            text: i18n.tr("Malakiboard settings")
            onTrigger: fullScreenItem.showSettings()
        }
    }
    // ENH089 - End
    
    // ENH071 - Custom height
    Rectangle {
        z: resizeItem.z
        color: fullScreenItem.theme.selectionColor
        opacity: resizeButton.drag.active ? 0.4 : 0.2
        visible: resizeItem.visible
        anchors {
            left: parent.left
            right: parent.right
            top: resizeItem.top
            topMargin: resizeButton.height / 2
            bottom: parent.bottom
        }
    }

    Item {
        id: resizeItem
        
        z: settingsLoader.z + 1
        height: (resizeButton.height / 2) + canvas.addedHeight
        width: resizeButton.width
        visible: fullScreenItem.settings.useCustomHeight && fullScreenItem.resizeMode && settingsLoader.keyboardPreview
                    && !fullScreenItem.keyboardFloating

        x: (keyboardSurface.width / 2) - (width / 2)
        y: {
            let multiplier = 1

            if (fullScreenItem.landscape) {
                multiplier = fullScreenItem.settings.customLandscapeHeight
            } else {
                multiplier = fullScreenItem.settings.customPortraitHeight
            }

            return (fullScreenItem.height - (fullScreenItem.height * multiplier)) - height
        }
        
        MouseArea {
            id: resizeButton

            readonly property bool dragActive: drag.active
            width: units.gu(6)
            height: width
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }

            drag.target: resizeItem
            drag.axis: Drag.YAxis
            drag.minimumY: fullScreenItem.height * 0.3
            drag.maximumY: fullScreenItem.height * 0.8

            onDragActiveChanged: {
                if (!dragActive) {
                    if (fullScreenItem.landscape) {
                        fullScreenItem.settings.customLandscapeHeight = Math.round((1 - ((resizeItem.y + resizeItem.height) / fullScreenItem.height)) * 100) / 100
                    } else {
                        fullScreenItem.settings.customPortraitHeight = Math.round((1 - ((resizeItem.y + resizeItem.height) / fullScreenItem.height)) * 100) / 100
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: resizeButton.pressed ? Suru.activeFocusColor : Suru.secondaryBackgroundColor
                border {
                    width: units.dp(1)
                    color: Suru.overlayColor
                }

                Behavior on color {
                    ColorAnimation { duration: LomiriAnimation.FastDuration }
                }

                Icon {
                    id: icon

                    implicitWidth: resizeButton.width * 0.60
                    implicitHeight: implicitWidth
                    name: "sort-listitem"
                    anchors.centerIn: parent
                    color: Suru.foregroundColor
                }
            }
        }
    }
    // ENH071 - End

    Timer {
        id: swipeTimer

        interval: cursorSwipeDuration
        running: false
        onTriggered: {
            // ENH088 - Cursor mover timeout
            if (interval > 0) {
                fullScreenItem.exitSwipeMode();
            }
            // ENH088 - End
        }
    }
    
    onCursorSwipeChanged:{
        if (cursorSwipe && input_method.hasSelection) {
            cursorSwipeArea.selectionMode = true
        }

        fullScreenItem.keyFeedback();
    }
    
    SoundEffect {
        id: audioFeedback
        source: maliit_input_method.audioFeedbackSound
    }
    
    HapticsEffect {
        id: pressEffect
        attackIntensity: 0.0
        attackTime: 50
        intensity: 1.0
        // ENH078 - Haptics settings
        // duration: 10
        duration: fullScreenItem.settings.hapticsDuration
        // ENH078 - End
        fadeTime: 50
        fadeIntensity: 0.0
    }

    // ENH083 - Cursor mover haptics
    HapticsEffect {
        id: swipeEffect
        attackIntensity: 0.0
        attackTime: 50
        intensity: 1.0
        duration: fullScreenItem.settings.swipeHapticsDuration
        fadeTime: 50
        fadeIntensity: 0.0
    }

    function swipeFeedback() {
        if (maliit_input_method.useHapticFeedback && fullScreenItem.settings.hapticsCursorMove) {
            swipeEffect.start()
        }
    }
    // ENH083 - End
    
    Connections {
        target: maliit_input_method
        onAudioFeedbackSoundChanged: audioFeedback.source = sound;
    }

    function keyFeedback() {
        if (maliit_input_method.useHapticFeedback) {
            pressEffect.start()
        }
        
        if (maliit_input_method.useAudioFeedback) {
            audioFeedback.play()
        }
    }
    
    function exitSwipeMode() {
        fullScreenItem.cursorSwipe = false
        fullScreenItem.timerSwipe.stop()
        cursorSwipeArea.selectionMode = false
        
        // We only enable autocaps after cursor movement has stopped
        if (keypad.delayedAutoCaps) {
            keypad.activeKeypadState = "SHIFTED"
            keypad.delayedAutoCaps = false
        } else {
            keypad.activeKeypadState = "NORMAL"
        }
    }

    function reportKeyboardVisibleRect() {
    // ENH070 - Keyboard settings
        if (!settingsLoader.active) {
            var vx = 0;
            var vy = 0;
            var vwidth = keyboardSurface.width;
            var vheight = keyboardComp.height + wordRibbon.height;

            var obj = mapFromItem(keyboardSurface, vx, vy, vwidth, vheight);
            // Report visible height of the keyboard to support anchorToKeyboard
            if (!fullScreenItem.keyboardFloating) {
                obj.height = fullScreenItem.height - obj.y;
            }

            // Work around QT bug: https://bugreports.qt-project.org/browse/QTBUG-20435
            // which results in a 0 height being reported incorrectly immediately prior
            // to the keyboard closing animation starting, which causes us to report
            // an extra visibility change for the keyboard.
            if (obj.height <= 0 && !canvas.hidingComplete) {
                return;
            }

            maliit_geometry.visibleRect = Qt.rect(obj.x, obj.y, obj.width, obj.height);
        }
    // ENH070 - End
    }

    // Autopilot needs to be able to move the cursor even when the layout
    // doesn't provide arrow keys (e.g. in phone mode)
    function commitPreedit() {
        event_handler.onKeyReleased("", "commit");
    }
    function sendLeftKey() {
        event_handler.onKeyReleased("", "left");
    }
    function sendRightKey() {
        event_handler.onKeyReleased("", "right");
    }
    function sendUpKey() {
        event_handler.onKeyReleased("", "up");
    }
    function sendDownKey() {
        event_handler.onKeyReleased("", "down");
    }
    function sendHomeKey() {
        event_handler.onKeyReleased("", "home");
    }
    function sendEndKey() {
        event_handler.onKeyReleased("", "end");
    }
    function selectLeft() {
        commitPreedit();
        event_handler.onKeyReleased("SelectPreviousChar", "keysequence");
    }
    function selectRight() {
        commitPreedit();
        event_handler.onKeyReleased("SelectNextChar", "keysequence");
    }
    function selectUp() {
        commitPreedit();
        event_handler.onKeyReleased("SelectPreviousLine", "keysequence");
    }
    function selectDown() {
        commitPreedit();
        event_handler.onKeyReleased("SelectNextLine", "keysequence");
    }
    function selectWord() {
        event_handler.onKeyReleased("MoveToNextWord", "keysequence");
        event_handler.onKeyReleased("SelectPreviousWord", "keysequence");
    }
    function selectStartOfLine() {
        commitPreedit();
        event_handler.onKeyReleased("SelectStartOfLine", "keysequence");
    }
    function selectEndOfLine() {
        commitPreedit();
        event_handler.onKeyReleased("SelectEndOfLine", "keysequence");
    }
    function selectStartOfDocument() {
        commitPreedit();
        event_handler.onKeyReleased("SelectStartOfDocument", "keysequence");
    }
    function selectEndOfDocument() {
        commitPreedit();
        event_handler.onKeyReleased("SelectEndOfDocument", "keysequence");
    }
    function selectAll() {
        commitPreedit();
        event_handler.onKeyReleased("SelectAll", "keysequence");
        cursorSwipeArea.selectionMode = true
    }
    function moveToStartOfLine() {
        commitPreedit();
        event_handler.onKeyReleased("MoveToStartOfLine", "keysequence");
    }
    function moveToEndOfLine() {
        commitPreedit();
        event_handler.onKeyReleased("MoveToEndOfLine", "keysequence");
    }
    function moveToStartOfDocument() {
        commitPreedit();
        event_handler.onKeyReleased("MoveToStartOfDocument", "keysequence");
    }
    function moveToEndOfDocument() {
        commitPreedit();
        event_handler.onKeyReleased("MoveToEndOfDocument", "keysequence");
    }
    function redo() {
        event_handler.onKeyReleased("Redo", "keysequence");
    }
    function undo() {
        event_handler.onKeyReleased("Undo", "keysequence");
    }
    function paste() {
        commitPreedit();
        event_handler.onKeyReleased("Paste", "keysequence");
    }
    function copy() {
        event_handler.onKeyReleased("Copy", "keysequence");
    }
    function cut() {
        event_handler.onKeyReleased("Cut", "keysequence");
    }
    // ENH089 - Quick actions
    function tab() {
        event_handler.onKeyReleased("	", "");
    }
    function selectPrevWord() {
        commitPreedit();
        event_handler.onKeyReleased("SelectPreviousWord", "keysequence");
    }
    function selectNextWord() {
        commitPreedit();
        event_handler.onKeyReleased("SelectNextWord", "keysequence");
    }
    // ENH089 - End

    function processSwipe(positionX, positionY) {
        // TODO: Removed input_method.surrounding* from the criteria until they are fixed in QtWebEngine
        // ubports/ubuntu-touch#1157 <https://github.com/ubports/ubuntu-touch/issues/1157>
//~         if (positionX < prevSwipePositionX - units.gu(1) /*&& input_method.surroundingLeft != ""*/) {
        // Do not allow moving to previous/next line when moving horizontally

        // WORKAROUND: Always allow horizontal movement when surrounding texts are both blank as a workaround
        //             on apps where these properties are not working correctly (i.e. Terminal app)
        //             Also check if surrounding texts have a newline character on a specific position as a workaround
        //             on apps where surrounding texts contain the full text from the text field (i.e. QtWebEngine)
        // ENH084 - Cursor mover sensitivity settings
        // if (positionX < prevSwipePositionX - units.gu(1)
        if (positionX < prevSwipePositionX - units.gu(fullScreenItem.settings.horizontalSwipeCursorSensitivity)
        // ENH084 - End
            // ENH085 - Cursor mover workaround settings
                // && ((input_method.surroundingLeft === "" && input_method.surroundingRight === "")
                        // || (input_method.surroundingLeft !== "" && input_method.surroundingLeft.lastIndexOf("\n") !== input_method.surroundingLeft.length - 1 ))) {
                && (
                        (
                            fullScreenItem.settings.cursorMoverWorkaround
                            && (
                                    (input_method.surroundingLeft === "" && input_method.surroundingRight === "")
                                    || (
                                        input_method.surroundingLeft !== "" && input_method.surroundingLeft.lastIndexOf("\n") !== input_method.surroundingLeft.length - 1
                                        )
                                )
                        )
                        || !fullScreenItem.settings.cursorMoverWorkaround
                    )
            ) {
            // ENH085 - End
            if(cursorSwipeArea.selectionMode){
                selectLeft();
            }else{
                sendLeftKey();
            }
            // ENH083 - Cursor mover haptics
            fullScreenItem.swipeFeedback()
            // ENH083 - End
            prevSwipePositionX = positionX
//~         } else if (positionX > prevSwipePositionX + units.gu(1) /*&& input_method.surroundingRight != ""*/) {
        // ENH084 - Cursor mover sensitivity settings
        // } else if (positionX > prevSwipePositionX + units.gu(1)
        } else if (positionX > prevSwipePositionX + units.gu(fullScreenItem.settings.horizontalSwipeCursorSensitivity)
        // ENH084 - End
            // ENH085 - Cursor mover workaround settings
                // && ((input_method.surroundingLeft === "" && input_method.surroundingRight === "")
                        // || (input_method.surroundingRight !== "" && input_method.surroundingRight.indexOf("\n") !== 0))) {
                && (
                        (
                            fullScreenItem.settings.cursorMoverWorkaround
                            && (
                                    (input_method.surroundingLeft === "" && input_method.surroundingRight === "")
                                    || (input_method.surroundingRight !== "" && input_method.surroundingRight.indexOf("\n") !== 0)
                                )
                        )
                        || !fullScreenItem.settings.cursorMoverWorkaround
                    )
            ) {
            // ENH085 - End
            if(cursorSwipeArea.selectionMode){
                selectRight();
            }else{
                sendRightKey();
            }
            // ENH083 - Cursor mover haptics
            fullScreenItem.swipeFeedback()
            // ENH083 - End
            prevSwipePositionX = positionX
        } 

        // ENH084 - Cursor mover sensitivity settings
        // if (positionY < prevSwipePositionY - units.gu(4)) {
        if (positionY < prevSwipePositionY - units.gu(fullScreenItem.settings.verticalSwipeCursorSensitivity)) {
        // ENH084 - End
            if(cursorSwipeArea.selectionMode){
                selectUp();
            }else{
                sendUpKey();
            }
            // ENH083 - Cursor mover haptics
            fullScreenItem.swipeFeedback()
            // ENH083 - End
            prevSwipePositionY = positionY
        // ENH084 - Cursor mover sensitivity settings
        // } else if (positionY > prevSwipePositionY + units.gu(4)) {
        } else if (positionY > prevSwipePositionY + units.gu(fullScreenItem.settings.verticalSwipeCursorSensitivity)) {
        // ENH084 - End
            if(cursorSwipeArea.selectionMode){
                selectDown();
            }else{
                sendDownKey();
            }
            // ENH083 - Cursor mover haptics
            fullScreenItem.swipeFeedback()
            // ENH083 - End
            prevSwipePositionY = positionY
        }
    }

} // fullScreenItem
