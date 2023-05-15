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
import QtQuick.Window 2.0
import "languages/"
import "keys/"
import UbuntuKeyboard 1.0

Item {
    id: panel

    property int keyWidth: 0
    property int keyHeight: 0

    property bool autoCapsTriggered: false
    property bool delayedAutoCaps: false

    property string activeKeypadState: "NORMAL"
    property alias extendedKeysSelector: extendedKeysSelector
    property alias magnifier: magnifier
    property alias popoverEnabled: extendedKeysSelector.enabled
    property bool switchBack: false // Switch back to the previous layout when changing fields
    property bool hideKeyLabels: false // Hide key labels when in cursor movement mode

    property Item lastKeyPressed // Used for determining double click validity in PressArea

    state: "CHARACTERS"

    function closeExtendedKeys()
    {
        extendedKeysSelector.closePopover();
    }

    Loader {
        id: characterKeypadLoader
        objectName: "characterKeyPadLoader"
        // ENH081 - Number row
        // anchors.fill: parent
        anchors {
            fill: parent
            topMargin: numberRow.visible ? numberRow.height : 0
        }
        // ENH081 - End
        asynchronous: false
        source: panel.state === "CHARACTERS" ? internal.characterKeypadSource : internal.symbolKeypadSource
        onLoaded: {
            if (delayedAutoCaps) {
                activeKeypadState = "SHIFTED";
                delayedAutoCaps = false;
            } else {
                activeKeypadState = "NORMAL";
            }
        }
    }

    // ENH081 - Number row
    Row {
        id: numberRow

        visible: fullScreenItem.settings.showNumberRow && keypad.state == "CHARACTERS"
                    && maliit_input_method.activeLanguage !== "emoji"
                    && maliit_input_method.activeLanguage !== "ja"
                    && canvas.layoutId !== "number"
                    && canvas.layoutId !== "telephone"
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }

        spacing: 0

        CharKey { label: "1"; shifted: "1"; extended: ["!"]; extendedShifted: ["!"]; leftSide: true; }
        CharKey { label: "2"; shifted: "2"; extended: ["@"]; extendedShifted: ["@"]; }
        CharKey { label: "3"; shifted: "3"; extended: ["#"]; extendedShifted: ["#"]; }
        CharKey { label: "4"; shifted: "4"; extended: ["$"]; extendedShifted: ["$"]; }
        CharKey { label: "5"; shifted: "5"; extended: ["%"]; extendedShifted: ["%"]; }
        CharKey { label: "6"; shifted: "6"; extended: ["^"]; extendedShifted: ["^"]; }
        CharKey { label: "7"; shifted: "7"; extended: ["&"]; extendedShifted: ["&"]; }
        CharKey { label: "8"; shifted: "8"; extended: ["*"]; extendedShifted: ["*"]; }
        CharKey { label: "9"; shifted: "9"; extended: ["("]; extendedShifted: ["("]; }
        CharKey { label: "0"; shifted: "0"; extended: [")"]; extendedShifted: [")"]; rightSide: true; }
    }
    // ENH081 - End

    ExtendedKeysSelector {
        id: extendedKeysSelector
        objectName: "extendedKeysSelector"
        anchors.fill: parent
    }

    Magnifier {
        id: magnifier
        shown: false
    }

    states: [
        State {
            name: "CHARACTERS"
        },
        State {
            name: "SYMBOLS"
        }
    ]

    onStateChanged: {
        maliit_input_method.keyboardState = state
    }

    QtObject {
        id: internal

        property Item activeKeypad: characterKeypadLoader.item
        property string characterKeypadSource: loadLayout(maliit_input_method.contentType,
                                                          maliit_input_method.activeLanguage)
        property string symbolKeypadSource: activeKeypad ? activeKeypad.symbols : ""

        onCharacterKeypadSourceChanged: {
            panel.state = "CHARACTERS";
        }

        function loadLayout(contentType, activeLanguage)
        {
            var language = activeLanguage.toLowerCase();
            if (!maliit_input_method.languageIsSupported(language)) {
                // If we don't have a layout for this specific locale 
                // check more generic locale
                language = language.slice(0,2);
            }

            if (!maliit_input_method.languageIsSupported(language)) {
                console.log("Language '" + language + "' not supported - using 'en' instead");
                maliit_input_method.activeLanguage = "en";
                language = "en";
            }

            // NumberContentType
            if (contentType === 1) {
                canvas.layoutId = "number";
                return "languages/Keyboard_numbers.qml";
            }

            // PhoneNumberContentType
            if (contentType === 2) {
                canvas.layoutId = "telephone";
                return "languages/Keyboard_telephone.qml";
            }

            // EmailContentType
            if (contentType === 3) {
                canvas.layoutId = "email";
                return maliit_input_method.currentPluginPath + "/Keyboard_" + language + "_email.qml";
            }

            // UrlContentType
            if (contentType === 4) {
                canvas.layoutId = "url";
                return maliit_input_method.currentPluginPath + "/Keyboard_" + language + "_url_search.qml";
            }

            // FreeTextContentType used as fallback
            canvas.layoutId = "freetext";
            return maliit_input_method.currentPluginPath + "/Keyboard_" + language + ".qml";
        }
    }
}
