/*
 * Copyright (C) 2025 UBports Foundation
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

Rectangle {
    id: root

    function show() {
        opacity = 0.3
        timeoutTimer.restart()
    }

    enabled: false
    opacity: 0
    visible: opacity > 0
    color: theme.palette.normal.activity

    Behavior on opacity { LomiriNumberAnimation {} }

    Timer {
        id: timeoutTimer
        interval: 2000
        onTriggered: root.opacity = 0
    }

    Connections {
        target: root.parent
        enabled: root.enabled

        // Avoid showing up when Lomiri starts
        Component.onCompleted: root.enabled = true

        onWidthChanged: root.show()
    }
}
