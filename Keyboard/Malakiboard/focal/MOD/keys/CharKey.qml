/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtMultimedia 5.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3

import "key_constants.js" as UI

Item {
    id: key

    property int padding: 0

    width: leftSide || rightSide ? keypad.keyWidth * 2 : keypad.keyWidth
    height: keypad.keyHeight

    /* to be set in keyboard layouts */
    property string label: ""
    property string shifted: ""
    property var extended; // list of extended keys
    property var extendedShifted; // list of extended keys in shifted state
    property var currentExtendedKey; // The currently highlighted extended key
    property bool highlight: false;
    property double textCenterOffset: units.gu(-0.15)

    property string valueToSubmit: keyLabel.text

    property alias acceptDoubleClick: keyMouseArea.acceptDoubleClick
    property alias horizontalSwipe: keyMouseArea.horizontalSwipe

    property string action
    property bool noMagnifier: false
    property bool skipAutoCaps: false
    property bool switchBackFromSymbols: false

    property bool leftSide: false
    property bool rightSide: false

    property double rowMargin: fullScreenItem.tablet ? units.gu(UI.tabletRowMargin)
                                                     : (fullScreenItem.keyboardLandscape ? units.dp(UI.phoneRowMarginLandscape)
                                                                                 : units.dp(UI.phoneRowMarginPortrait))
    property double keyMargin: fullScreenItem.tablet && !fullScreenItem.oneHanded ? units.gu(UI.tabletKeyMargins)
                                                     : units.gu(UI.phoneKeyMargins)

    // These properties are used by autopilot to determine the visible
    // portion of the key to press
    readonly property double leftOffset: buttonRect.anchors.leftMargin
    readonly property double rightOffset: buttonRect.anchors.rightMargin

    /* design */
    property string normalColor: fullScreenItem.theme.charKeyColor
    property string pressedColor: fullScreenItem.theme.charKeyPressedColor
    property bool borderEnabled: fullScreenItem.theme.keyBorderEnabled
    property string borderColor: borderEnabled ? fullScreenItem.theme.charKeyBorderColor : "transparent"

    // Scale the font so the label fits if a long word is set
    property int fontSize: (fullScreenItem.keyboardLandscape ? (height / 2) : (height / 2.8))
                           * (4 / (label.length >= 2 ? (label.length <= 6 ? label.length + 2.5 : 8) : 4));

    /// annotation shows a small label in the upper right corner
    // if the annotiation property is set, it will be used. If not, the first position in extended[] list or extendedShifted[] list will
    // be used, depending on the state. If no extended/extendedShifted arrays exist, no annotation is shown
    property string annotation: ""

    /*! indicates if the key is currently pressed/down*/
    property alias currentlyPressed: keyMouseArea.pressed

    /* internal */
    property string __annotationLabelNormal
    property string __annotationLabelShifted

    /**
     * this property specifies if the key can submit its value or not (e.g. when the popover is shown, it does not commit its value)
     */

    property bool extendedKeysShown: keypad.extendedKeysSelector.enabled

    /*
     * label changes when keyboard is in shifted mode
     * extended keys change as well when shifting keyboard, typically lower-uppercase: ê vs Ê
     */

    property string oskState: keypad.activeKeypadState
    property var activeExtendedModel: (keypad.activeKeypadState === "NORMAL") ? extended : extendedShifted

    // Allow action keys to override the standard key behaviour
    property bool overridePressArea: false

    // Allow to manipulate preedit if it need.
    // if allowPreeditHandler is enabled should be assigned preeditHandler.
    property bool allowPreeditHandler: false
    property var preeditHandler: null

    // Don't detect swipe changes until the swipeTimer has expired to prevent
    // accidentally selecting something other than the default extended key
    property bool swipeReady: false

    signal pressed()
    signal released()
    signal pressAndHold()
    signal doubleClicked()
    signal keySent(string key)

    Component.onCompleted: {
        if (annotation) {
            __annotationLabelNormal = annotation
            __annotationLabelShifted = annotation
        } else {
            if (extended)
                __annotationLabelNormal = extended[0]
            if (extendedShifted)
                __annotationLabelShifted = extendedShifted[0]
        }
    }

    // Make it possible for the visible area of the key to differ from the
    // actual key size. This allows us to extend the touch area of the bottom
    // row of keys all the way to the bottom of the keyboard, whilst
    // maintaining the same visual appearance.
    Item {
        anchors.top: parent.top
        height: keypad.keyHeight
        width: parent.width

        Rectangle {
            id: buttonRect
            color: key.currentlyPressed || key.highlight ? pressedColor : normalColor
            anchors.fill: parent
            anchors.leftMargin: key.leftSide ? (parent.width - keypad.keyWidth) + key.keyMargin : key.keyMargin
            anchors.rightMargin: key.rightSide ? (parent.width - keypad.keyWidth) + key.keyMargin : key.keyMargin
            anchors.bottomMargin: key.rowMargin
            border{
                width: borderEnabled ? units.gu(0.1) : 0
                color: borderColor
            }
            radius: units.dp(4)

            // label of the key
            //  the label is also the value subitted to the app

            Text {
                id: keyLabel
                text: (keypad.activeKeypadState === "NORMAL") ? label : shifted;
                // ENH091 - Font settings
                // font.family: UI.fontFamily
                font.family: fullScreenItem.settings.useCustomFont
                        && fullScreenItem.settings.customFont 
                        && maliit_input_method.activeLanguage !== "emoji" ? fullScreenItem.settings.customFont
                                                              : UI.fontFamily
                // ENH091 - End
                font.pixelSize: fontSize
                font.weight: Font.Light
                color: fullScreenItem.theme.fontColor
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.leftMargin: units.gu(0.2)
                anchors.rightMargin: units.gu(0.2)
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: key.textCenterOffset
                horizontalAlignment: Text.AlignHCenter
                // Avoid eliding characters that are slightly too wide (e.g. some emoji and chinese characters)
                elide: text.length <= 4 ? Text.ElideNone : Text.ElideRight
                visible: !keypad.hideKeyLabels
            }

            // shows an annotation
            // used e.g. for indicating the existence of extended keys

            Text {
                id: annotationLabel
                text: (keypad.activeKeypadState != "NORMAL") ? __annotationLabelShifted : __annotationLabelNormal

                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: units.gu(UI.annotationTopMargin)
                anchors.rightMargin: units.gu(UI.annotationRightMargin)
                // ENH091 - Font settings
                // font.family: UI.annotationFont
                font.family: fullScreenItem.settings.useCustomFont
                        && fullScreenItem.settings.customFont
                        && maliit_input_method.activeLanguage !== "emoji" ? fullScreenItem.settings.customFont
                                                              : UI.annotationFont
                // ENH091 - End
                font.pixelSize: fontSize / 3
                font.weight: Font.Light
                color: fullScreenItem.theme.annotationFontColor
                visible: !keypad.hideKeyLabels
            }

        }
    }

    PressArea {
        id: keyMouseArea
        anchors.fill: parent

        onPressAndHold: {
            if (overridePressArea) {
                key.pressAndHold();
                return;
            }
            if (activeExtendedModel != undefined) {
                if (maliit_input_method.useHapticFeedback)
                    pressEffect.start();

                swipeReady = false;
                swipeTimer.restart();
                keypad.magnifier.shown = false
                keypad.extendedKeysSelector.enabled = true
                keypad.extendedKeysSelector.extendedKeysModel = activeExtendedModel
                keypad.extendedKeysSelector.currentlyAssignedKey = key
                var extendedKeys = keypad.extendedKeysSelector.keys;
                var middleKey = extendedKeys.length > 1 ? Math.floor(extendedKeys.length / 2) - 1 : 0;
                extendedKeys[middleKey].highlight = true;
                currentExtendedKey = extendedKeys[middleKey];
            }
        }

        onMouseXChanged: {
            evaluateSelectorSwipe();
        }

        onMouseYChanged: {
            evaluateSelectorSwipe();
        }

        onReleased: {
            key.released();
            if (overridePressArea) {
                return;
            }
            if (extendedKeysShown) {
                if (currentExtendedKey) {
                    currentExtendedKey.commit();
                    currentExtendedKey = null;
                } else {
                    keypad.extendedKeysSelector.closePopover();
                }
            } else if(!swipedOut) {
                // Read this prior to altering autocaps
                var keyToSend = valueToSubmit;
                if (keypad.magnifier.currentlyAssignedKey == key) {
                    keypad.magnifier.shown = false;
                }

                if (keypad.autoCapsTriggered && action != "backspace") {
                    keypad.autoCapsTriggered = false;
                }
                else if (!skipAutoCaps) {
                    if (keypad.activeKeypadState === "SHIFTED" && keypad.state === "CHARACTERS")
                        keypad.activeKeypadState = "NORMAL";
                }
                if (switchBackFromSymbols && keypad.state === "SYMBOLS") {
                    keypad.state = "CHARACTERS";
                }

                if (allowPreeditHandler && preeditHandler) {
                    preeditHandler.onKeyReleased(keyToSend, action);
                    return;
                }

                event_handler.onKeyReleased(keyToSend, action);
                keySent(keyToSend);
            } else if (action == "backspace") {
                // Send release from backspace if we're swiped out since
                // backspace activates on press and deactivates on release
                // to allow for repeated backspaces, unlike normal keys
                // which activate on release.
                event_handler.onKeyReleased(valueToSubmit, action);
                keySent(valueToSubmit);
            }
        }

        onSwipedOutChanged: {
            if(swipedOut && keypad.magnifier.currentlyAssignedKey == key) {
                keypad.magnifier.shown = false;
            }
        }

        onPressed: {
            key.pressed();
            if (overridePressArea) {
                return;
            }
            keypad.magnifier.currentlyAssignedKey = key
            keypad.magnifier.shown = !noMagnifier && maliit_input_method.enableMagnifier

            if (maliit_input_method.useAudioFeedback)
                audioFeedback.play();

            if (maliit_input_method.useHapticFeedback)
                 pressEffect.start();

            // Quick workaround to fix initial autocaps - not beautiful, but works
            if(action != "backspace") {
                keypad.autoCapsTriggered = false;
            }
            event_handler.onKeyPressed(valueToSubmit, action);
        }

        onDoubleClicked: {
            key.doubleClicked();
            if (overridePressArea) {
                return;
            }
        }

        // Determine which extended key we're underneath when swiping,
        // highlight it and set it as the currentExtendedKey (to be committed
        // when press is released)
        function evaluateSelectorSwipe() {
            if (keypad.extendedKeysSelector.enabled && swipeReady) {
                var extendedKeys = keypad.extendedKeysSelector.keys;
                currentExtendedKey = null;
                var keyMapping = keypad.extendedKeysSelector.mapToItem(key, keypad.extendedKeysSelector.rowX, keypad.extendedKeysSelector.rowY);
                var mx = mouseX - keyMapping.x;
                var my = mouseY - keyMapping.y;
                for(var i = 0; i < extendedKeys.length; i++) {
                    var posX = extendedKeys[i].x;
                    var posY = extendedKeys[i].y;
                    if(mx > posX && mx < (posX + extendedKeys[i].width)
                       && my > posY && my < (posY + extendedKeys[i].height * 2.5)) {
                        if(!extendedKeys[i].highlight && maliit_input_method.useHapticFeedback) {
                            pressEffect.start();
                        }
                        extendedKeys[i].highlight = true;
                        currentExtendedKey = extendedKeys[i];
                    } else if('highlight' in extendedKeys[i]) {
                        extendedKeys[i].highlight = false;
                    }
                }
            }
        }
    }

    Timer {
        id: swipeTimer
        interval: 750
        onTriggered: {
            swipeReady = true;
            keyMouseArea.evaluateSelectorSwipe();
        }
    }

    Connections {
        target: swipeArea.drag
        onActiveChanged: {
            if (swipeArea.drag.active)
                keyMouseArea.cancelPress();
        }
    }
}
