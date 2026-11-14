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

ActionKey {
    // ENH077 - Show emoji in language key
    // iconNormal: "language-chooser";
    // iconShifted: "language-chooser";
    // iconCapsLock: "language-chooser";
    iconNormal: maliit_input_method.previousLanguage == "emoji" || maliit_input_method.activeLanguage == "emoji"
                            ? "" : "language-chooser";
    iconShifted: maliit_input_method.previousLanguage == "emoji" || maliit_input_method.activeLanguage == "emoji"
                            ? "" : "language-chooser";
    iconCapsLock: maliit_input_method.previousLanguage == "emoji" || maliit_input_method.activeLanguage == "emoji"
                            ? "" : "language-chooser";
    label: maliit_input_method.previousLanguage == "emoji" ? "☻" : "";
    shifted: maliit_input_method.previousLanguage == "emoji" ? "☻" : "";
    // ENH077 - End

    property bool held: false;

    padding: 0

    // ENH228 - Option to hide Language key
    property bool doNotHide: false
    // width: panel.keyWidth
    width: fullScreenItem.settings.hideLanguageKey && !doNotHide ? 0 : panel.keyWidth
    visible: !fullScreenItem.settings.hideLanguageKey || doNotHide
    // ENH228 - End
    // ENH119 - Extended selector language key
    id: languageKey

    Component.onCompleted: setExtendedKeys()

    function setExtendedKeys() {
        let tempArr = maliit_input_method.enabledLanguages.slice()
        tempArr.splice(tempArr.indexOf(maliit_input_method.activeLanguage), 1)
        extended = [...tempArr, fullScreenItem.settings.settingsIcon, fullScreenItem.settings.mkSettingsIconText]
    }

    Connections {
        target: maliit_input_method
        onEnabledLanguagesChanged: {
            if (fullScreenItem.settings.redesignedLanguageKey) {
                languageKey.setExtendedKeys()
            }
        }
    }
    // overridePressArea: true
    overridePressArea: !fullScreenItem.settings.redesignedLanguageKey

    overrideExtendedKeySelection: fullScreenItem.settings.redesignedLanguageKey
    onExtendedKeySelected: {
        if (sig_selectedKey == fullScreenItem.settings.settingsIcon) {
            Qt.openUrlExternally("settings:///system/language")
        } else if (sig_selectedKey == fullScreenItem.settings.mkSettingsIconText) {
            fullScreenItem.showSettings()
        } else {
            maliit_input_method.activeLanguage = sig_selectedKey
        }
    }
    // ENH119 - End

    action: "language"

    onPressed: {
        if (maliit_input_method.useAudioFeedback)
            audioFeedback.play();

        if (maliit_input_method.useHapticFeedback)
            pressEffect.start();
        
        held = false;
    }

    onReleased: {
        // ENH119 - Extended selector language key
        if (!extendedKeysShown) {
            panel.switchBack = false;
            if (held) {
                return;
            }

            if (maliit_input_method.previousLanguage && maliit_input_method.previousLanguage != maliit_input_method.activeLanguage) {
                maliit_input_method.activeLanguage = maliit_input_method.previousLanguage
            } else {
                canvas.languageMenuShown = true
            }
        }
        // ENH119 - End
    }

    onPressAndHold: {
        if (maliit_input_method.useAudioFeedback)
            audioFeedback.play();

        if (maliit_input_method.useHapticFeedback)
            pressEffect.start();

        canvas.languageMenuShown = true
        held = true;
    }
}
