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
import Ubuntu.Components 1.3
import QtFeedback 5.0
import QtMultimedia 5.0
import QtQuick.Layouts 1.3
// ENH008 - Keyboard enhancements
// Temp workaround for disabling height
import GSettings 1.0
// ENH008 - End

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
    
    // ENH009 - Custom keyboard height
    readonly property real customPortraitHeight: 0 //0.31 //default: 0
    readonly property real customLandscapeHeight: 0 //0.49 //default: 0
    // ENH009 - End

    property bool cursorSwipe: false
    property int prevSwipePositionX
    property int prevSwipePositionY
    property int cursorSwipeDuration: 5000
    property var timerSwipe: swipeTimer
    property var theme: Theme.defaultTheme

    property variant input_method: maliit_input_method
    property variant event_handler: maliit_event_handler

    onXChanged: fullScreenItem.reportKeyboardVisibleRect();
    onYChanged: fullScreenItem.reportKeyboardVisibleRect();
    onWidthChanged: fullScreenItem.reportKeyboardVisibleRect();
    onHeightChanged: fullScreenItem.reportKeyboardVisibleRect();
    
    Component.onCompleted: Theme.load(maliit_input_method.theme)

    Item {
        id: canvas
        objectName: "ubuntuKeyboard" // Allow us to specify a specific keyboard within autopilot.

        // ENH009 - Custom keyboard height
        // property real keyboardHeight: (fullScreenItem.oneHanded ? keyboardSurface.oneHandedWidth * UI.oneHandedHeight
        //                     : fullScreenItem.height * (fullScreenItem.landscape ? fullScreenItem.tablet ? UI.tabletKeyboardHeightLandscape 
        //                                                                                                                   : UI.phoneKeyboardHeightLandscape
        //                                                                                     : fullScreenItem.tablet ? UI.tabletKeyboardHeightPortrait 
        //                                                                                                                   : UI.phoneKeyboardHeightPortrait))
        //                               + wordRibbon.height + borderTop.height + keyboardSurface.addBottomMargin
        property real keyboardHeight: {
            var multiplier
            var mainHeight
            var addedHeight = wordRibbon.height + borderTop.height + keyboardSurface.addBottomMargin

            if (fullScreenItem.landscape) {
                if (fullScreenItem.customLandscapeHeight > 0) {
                    multiplier = fullScreenItem.customLandscapeHeight
                } else {
                    if (fullScreenItem.tablet) {
                        multiplier = UI.tabletKeyboardHeightLandscape 
                    } else {
                        multiplier = UI.phoneKeyboardHeightLandscape
                    }
                }
            } else {
                if (fullScreenItem.customPortraitHeight > 0) {
                    multiplier = fullScreenItem.customPortraitHeight
                } else {
                    if (fullScreenItem.tablet) {
                        multiplier = UI.tabletKeyboardHeightPortrait 
                    } else {
                        multiplier = UI.phoneKeyboardHeightPortrait
                    }
                }
            }

//~             if (fullScreenItem.oneHanded) {
//~                 mainHeight = keyboardSurface.oneHandedWidth * UI.oneHandedHeight
//~                 mainHeight = fullScreenItem.height *  multiplier
//~             } else {
                mainHeight = fullScreenItem.height *  multiplier
//~             }

            return mainHeight + addedHeight
        }
        // ENH009 - End

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
            layer.enabled: dragButton.pressed || noActivity

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

            Behavior on x { UbuntuNumberAnimation {} }
            Behavior on width { UbuntuNumberAnimation {} }

            // Use Standlone animation instead of Behavior to avoid conflict with y changes from PressArea
            UbuntuNumberAnimation {
                id: yAnimation
                target: keyboardSurface
                duration: UbuntuAnimation.FastDuration
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

                    height: canvas.wordribbon_visible ? (fullScreenItem.tablet ? units.gu(UI.tabletWordribbonHeight)
                                                                               : units.gu(UI.phoneWordribbonHeight))
                                                      : 0
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
                height: fullScreenItem.tablet ? units.gu(UI.tabletWordribbonHeight) : units.gu(UI.phoneWordribbonHeight)
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
                    hideKeyLabels: fullScreenItem.cursorSwipe

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
                visible: !fullScreenItem.cursorSwipe
                width: units.gu(3)
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                }
            }
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
            UbuntuNumberAnimation { target: keyboardSurface; properties: "y"; }
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
            onThemeChanged: Theme.load(target.theme)
        }
    } // canvas

    Timer {
        id: swipeTimer
        interval: cursorSwipeDuration
        running: false
        onTriggered: {
            fullScreenItem.exitSwipeMode();
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
        duration: 10
        fadeTime: 50
        fadeIntensity: 0.0
    }
    
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
//~         event_handler.onKeyReleased("MoveToPreviousWord", "keysequence");
//~         event_handler.onKeyReleased("SelectNextWord", "keysequence");
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

    function processSwipe(positionX, positionY) {
        // TODO: Removed input_method.surrounding* from the criteria until they are fixed in QtWebEngine
        // ubports/ubuntu-touch#1157 <https://github.com/ubports/ubuntu-touch/issues/1157>
//~         if (positionX < prevSwipePositionX - units.gu(1) /*&& input_method.surroundingLeft != ""*/) {
        // Do not allow moving to previous/next line when moving horizontally

        // WORKAROUND: Always allow horizontal movement when surrounding texts are both blank as a workaround
        //             on apps where these properties are not working correctly (i.e. Terminal app)
        //             Also check if surrounding texts have a newline character on a specific position as a workaround
        //             on apps where surrounding texts contain the full text from the text field (i.e. QtWebEngine)
        if (positionX < prevSwipePositionX - units.gu(1)
                && ((input_method.surroundingLeft === "" && input_method.surroundingRight === "")
                        || (input_method.surroundingLeft !== "" && input_method.surroundingLeft.lastIndexOf("\n") !== input_method.surroundingLeft.length - 1 ))) {
            if(cursorSwipeArea.selectionMode){
                selectLeft();
            }else{
                sendLeftKey();
            }
            prevSwipePositionX = positionX
//~         } else if (positionX > prevSwipePositionX + units.gu(1) /*&& input_method.surroundingRight != ""*/) {
        } else if (positionX > prevSwipePositionX + units.gu(1)
                && ((input_method.surroundingLeft === "" && input_method.surroundingRight === "")
                        || (input_method.surroundingRight !== "" && input_method.surroundingRight.indexOf("\n") !== 0))) {
            if(cursorSwipeArea.selectionMode){
                selectRight();
            }else{
                sendRightKey();
            }
            prevSwipePositionX = positionX
        } 

        if (positionY < prevSwipePositionY - units.gu(4)) {
            if(cursorSwipeArea.selectionMode){
                selectUp();
            }else{
                sendUpKey();
            }
            prevSwipePositionY = positionY
        } else if (positionY > prevSwipePositionY + units.gu(4)) {
            if(cursorSwipeArea.selectionMode){
                selectDown();
            }else{
                sendDownKey();
            }
            prevSwipePositionY = positionY
        }
    }

} // fullScreenItem
