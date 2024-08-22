/*
 * Copyright 2015 Canonical Ltd.
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

import QtQuick 2.4
import Ubuntu.Components 1.3

import "key_constants.js" as UI

/*!
  Item to show a "bubble" with a text in the center.
  The bottom center is where the bubble points to, and it animates to that position
  when hiding it.
 */
Item {
    id: root

    property var chars: ["", "", "", "", ""];
    property var icons: ["", "", "", "", ""];
    property var angles: ["", "", "", "", ""];
    property int popFontSize: units.gu(UI.fontSize);
    property int index: 0

    visible: false

    FlickPopKey {
        id: center
        labelChar: chars[0] ? chars[0] : ""
        labelIcon: icons[0] ? icons[0] : ""
        anchors.centerIn: parent
        labelOpacity: index == 0 ? 1.0 : 0.6
        labelAngle: angles[0] ? angles[0] : ""
        labelColor: index == 0 ? fullScreenItem.theme.selectionColor : fullScreenItem.theme.fontColor
        labelFontSize: popFontSize
    }

    FlickPopKey {
        labelChar: chars[1] ? chars[1] : ""
        labelIcon:icons[1] ? icons[1] : ""
        anchors.verticalCenter: center.verticalCenter
        anchors.right: center.left
        labelOpacity: index == 1 ? 1.0 : 0.6
        labelAngle: angles[1] ? angles[1] : ""
        labelColor: index == 1 ? fullScreenItem.theme.selectionColor : fullScreenItem.theme.fontColor
        labelFontSize: popFontSize
    }

    FlickPopKey {
        labelChar: chars[2] ? chars[2] : ""
        labelIcon:icons[2] ? icons[2] : ""
        anchors.horizontalCenter: center.horizontalCenter
        anchors.bottom: center.top
        labelOpacity: index == 2 ? 1.0 : 0.6
        labelAngle: angles[2] ? angles[2] : ""
        labelColor: index == 2 ? fullScreenItem.theme.selectionColor : fullScreenItem.theme.fontColor
        labelFontSize: popFontSize
    }

    FlickPopKey {
        labelChar: chars[3] ? chars[3] : ""
        labelIcon:icons[3] ? icons[3] : ""
        anchors.verticalCenter: center.verticalCenter
        anchors.left: center.right
        labelOpacity: index == 3 ? 1.0 : 0.6
        labelAngle: angles[3] ? angles[3] : ""
        labelColor: index == 3 ? fullScreenItem.theme.selectionColor : fullScreenItem.theme.fontColor
        labelFontSize: popFontSize
    }

    FlickPopKey {
        labelChar: chars[4] ? chars[4] : ""
        labelIcon:icons[4] ? icons[4] : ""
        anchors.horizontalCenter: center.horizontalCenter
        anchors.top: center.bottom
        labelOpacity: index == 4 ? 1.0 : 0.6
        labelAngle: angles[4] ? angles[4] : ""
        labelColor: index == 4 ? fullScreenItem.theme.selectionColor : fullScreenItem.theme.fontColor
        labelFontSize: popFontSize
    }
}