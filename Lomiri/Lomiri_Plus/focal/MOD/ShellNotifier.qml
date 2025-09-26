/*
 * Copyright (C) 2016 Canonical Ltd.
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

/*
    Shared signals & properties on multi-window desktop
 */

pragma Singleton
import QtQuick 2.12

QtObject {
    property var greeter: QtObject {
        signal hide(bool now)

        property bool shown: true
    }
    // ENH224 - Brightness control in Virtual Touchpad mode
    property bool oskDisplayedInTouchpad: false
    // ENH224 - End
    // ENH141 - Air mouse in virtual touchpad
    property bool inAirMouseMode: false
    // ENH141 - End
}
