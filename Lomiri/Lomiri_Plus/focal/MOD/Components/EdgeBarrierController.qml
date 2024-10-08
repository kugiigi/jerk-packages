/*
 * Copyright (C) 2015 Canonical Ltd.
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
import Utils 0.1 // For EdgeBarrierSettings

MouseArea {
    id: root

    hoverEnabled: true

    // Edge push progress
    // Value range is [0.0, 1.0]
    readonly property real progress: Math.min(Math.max(0.0, _accumulatedPush / EdgeBarrierSettings.pushThreshold), 1.0)
    // ENH163 - Less sensitive edge barrier
    readonly property real realProgressWhenLessSensitive: Math.min(Math.max(0.0, _realAccumulatedPushWhenLessSensitive / EdgeBarrierSettings.pushThreshold), 1.0)
    property real _realAccumulatedPushWhenLessSensitive: 0
    // ENH163 - End

    // Emitted when progress reaches 1.0
    // Should trigger the action associated with this edge
    signal passed()

    onPressed: mouse.accepted = false;

    function push(amount) {
        if (!root._containsMouse) {
            // ENH104 - Mouse edge push settings
            // Removed to avoid spamming log when mouse push is disabled
            // console.warn("pushing right edge without mouse actually being at right edge!")
            // ENH104 - End
            return;
        }

        if (_accumulatedPush === EdgeBarrierSettings.pushThreshold) {
            // NO-OP
            return;
        }
        // ENH163 - Less sensitive edge barrier
        if (shell.settings.lessSensitiveEdgeBarriers) {
            if (_realAccumulatedPushWhenLessSensitive === EdgeBarrierSettings.pushThreshold) {
                // NO-OP
                return;
            }

            if (_realAccumulatedPushWhenLessSensitive + amount > EdgeBarrierSettings.pushThreshold) {
                _realAccumulatedPushWhenLessSensitive = EdgeBarrierSettings.pushThreshold;
            } else {
                _realAccumulatedPushWhenLessSensitive += amount;
            }

            if (amount <= 100 && _accumulatedPush == 0) {
                return;
            }
        }
        // ENH163 - End

        if (_accumulatedPush + amount > EdgeBarrierSettings.pushThreshold) {
            _accumulatedPush = EdgeBarrierSettings.pushThreshold;
        } else {
            _accumulatedPush += amount;
        }

        if (_accumulatedPush === EdgeBarrierSettings.pushThreshold) {
            passed();
        }
    }

    onEnabledChanged: {
        if (!enabled) {
            // reset
            _accumulatedPush = 0;
            // ENH163 - Less sensitive edge barrier
            _realAccumulatedPushWhenLessSensitive = 0;
            // ENH163 - End
        }
    }

    // to be overwritten by tests
    property bool _containsMouse: root.containsMouse
    on_ContainsMouseChanged: {
        if (!_containsMouse) {
            // reset
            _accumulatedPush = 0;
            // ENH163 - Less sensitive edge barrier
            _realAccumulatedPushWhenLessSensitive = 0;
            // ENH163 - End
        }
    }

    property real _accumulatedPush: 0
}
