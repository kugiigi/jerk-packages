/*
 * Copyright (C) 2013 Canonical Ltd.
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
// ENH142 - Custom infographics dots color
import Lomiri.Components 1.3
// ENH142 - End

// ENH142 - Custom infographics dots color
// Image {
Icon {
    color: "white"
    keyColor: "#ffffff"
// ENH142 - End
    states: [
        State {
            name: "unfilled"
            // ENH142 - Custom infographics dots color
            // PropertyChanges { target: dot; source: "graphics/dot_empty.png" }
            PropertyChanges { target: dot; source: "graphics/dot_empty.svg" }
            // ENH142 - End
        },

        State {
            name: "filled"
            // ENH142 - Custom infographics dots color
            // PropertyChanges { target: dot; source: "graphics/dot_filled.png" }
            PropertyChanges { target: dot; source: "graphics/dot_filled.svg" }
            // ENH142 - End
        },

        State {
            name: "pointer"
            // ENH142 - Custom infographics dots color
            // PropertyChanges { target: dot; source: "graphics/dot_pointer.png"; scale: 2.0 }
            PropertyChanges { target: dot; source: "graphics/dot_pointer.svg"; scale: 2.0 }
            // ENH142 - End
        }
    ]
}
