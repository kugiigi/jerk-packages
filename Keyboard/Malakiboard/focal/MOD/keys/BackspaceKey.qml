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
// ENH194 - Swipe delete
import Lomiri.Components 1.3
// ENH194 - End

ActionKey {
    iconNormal: "erase";
    iconShifted: "erase";
    iconCapsLock: "erase";
    action: "backspace";
    // ENH194 - Swipe delete
    id: backspaceKey

    property bool wasSwiped: false

    overridePressArea: swipeAreaItem.enabled

    onPressAndHold: {
        if (swipeAreaItem.enabled && !swipeAreaItem.dragging) {
            event_handler.onKeyPressed(backspaceKey.valueToSubmit, backspaceKey.action);
        }
    }

    onReleased: {
        if (swipeAreaItem.enabled) {
            if (!backspaceKey.wasSwiped || (backspaceKey.wasSwiped && input_method.hasSelection)) {
                event_handler.onKeyPressed(backspaceKey.valueToSubmit, backspaceKey.action);
                event_handler.onKeyReleased(valueToSubmit, action);
                keySent(valueToSubmit);
            }

            backspaceKey.wasSwiped = false
        }
    }

    onPressed: {
        if (swipeAreaItem.enabled) {
            keypad.magnifier.currentlyAssignedKey = backspaceKey
            keypad.magnifier.shown = !noMagnifier && maliit_input_method.enableMagnifier

            if (maliit_input_method.useAudioFeedback)
                audioFeedback.play();

            if (maliit_input_method.useHapticFeedback)
                 pressEffect.start();
        }
    }

    SwipeArea {
        id: swipeAreaItem

        enabled: fullScreenItem.settings.enableSwipeToDelete
        anchors.fill: parent
        direction: SwipeArea.Horizontal
        immediateRecognition: false
        grabGesture: false
        onDraggingChanged: {
            if (dragging) {
                backspaceKey.wasSwiped = true
                fullScreenItem.enterSelectMode(false, touchPosition.x, 0)
            } else {
                backspaceKey.currentlyPressed = false
                fullScreenItem.exitSelectMode(false)
            }
        }
        onTouchPositionChanged: {
            if (swipeAreaItem.dragging) {
                fullScreenItem.processSwipe(touchPosition.x, touchPosition.y);
            }
        }
    }
    // ENH194 - End
}
