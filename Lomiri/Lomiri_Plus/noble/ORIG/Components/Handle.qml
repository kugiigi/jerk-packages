/*
 * Copyright (C) 2014 Canonical Ltd.
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

Item {
    id: handle
    height: units.gu(2)
    property bool active: false

    Row {
        id: dots
        width: childrenRect.width
        height: childrenRect.height
        anchors.centerIn: parent
        spacing: units.gu(0.5)
        rotation: (parent.width >= parent.height) ? 0 : 90
        Repeater {
            model: 3
            delegate: Rectangle {
                id: dot
                width: units.dp(3)
                height: width
                color: handle.active ? theme.palette.focused.foreground : theme.palette.normal.backgroundText
                radius: units.dp(1)
            }
        }
    }
}
