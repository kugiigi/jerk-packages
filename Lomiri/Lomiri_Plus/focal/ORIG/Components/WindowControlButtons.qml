/*
 * Copyright (C) 2014-2016 Canonical Ltd.
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

Row {
    id: root
    spacing: overlayShown ? units.gu(2) : windowIsMaximized ? 0 : units.gu(1)
    Behavior on spacing {
        LomiriNumberAnimation {}
    }

    // to be set from outside
    property bool active: false
    property bool windowIsMaximized: false
    property bool closeButtonShown: true
    property bool maximizeButtonShown: true
    property bool minimizeButtonVisible: true
    property bool overlayShown

    signal closeClicked()
    signal minimizeClicked()
    signal maximizeClicked()
    signal maximizeVerticallyClicked()
    signal maximizeHorizontallyClicked()

    MouseArea {
        id: closeWindowButton
        objectName: "closeWindowButton"
        hoverEnabled: true
        height: parent.height
        width: height
        onClicked: root.closeClicked()
        visible: root.closeButtonShown

        Rectangle {
            anchors.fill: parent
            anchors.margins: windowIsMaximized ? units.dp(3) : 0
            radius: height / 2
            color: theme.palette.normal.negative
            visible: parent.containsMouse && !overlayShown
        }
        Icon {
            anchors.fill: parent
            anchors.margins: windowIsMaximized ? units.dp(6) : units.dp(3)
            source: "graphics/window-close.svg"
            color: root.active ? "white" : LomiriColors.slate
        }
    }

    MouseArea {
        id: minimizeWindowButton
        objectName: "minimizeWindowButton"
        hoverEnabled: true
        height: parent.height
        width: height
        onClicked: root.minimizeClicked()
        visible: root.minimizeButtonVisible

        Rectangle {
            anchors.fill: parent
            anchors.margins: windowIsMaximized ? units.dp(3) : 0
            radius: height / 2
            color: root.active ? LomiriColors.graphite : LomiriColors.ash
            visible: parent.containsMouse && !overlayShown
        }
        Icon {
            anchors.fill: parent
            anchors.margins: windowIsMaximized ? units.dp(6) : units.dp(3)
            source: "graphics/window-minimize.svg"
            color: root.active ? "white" : LomiriColors.slate
        }
    }

    MouseArea {
        id: maximizeWindowButton
        objectName: "maximizeWindowButton"
        hoverEnabled: true
        height: parent.height
        width: height
        visible: root.maximizeButtonShown
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: {
            if (mouse.button == Qt.LeftButton) {
                root.maximizeClicked();
            } else if (mouse.button == Qt.RightButton) {
                root.maximizeHorizontallyClicked();
            } else if (mouse.button == Qt.MiddleButton) {
                root.maximizeVerticallyClicked();
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: windowIsMaximized ? units.dp(3) : 0
            radius: height / 2
            color: root.active ? LomiriColors.graphite : LomiriColors.ash
            visible: parent.containsMouse && !overlayShown
        }
        Icon {
            anchors.fill: parent
            anchors.margins: windowIsMaximized ? units.dp(6) : units.dp(3)
            source: root.windowIsMaximized ? "graphics/window-window.svg" : "graphics/window-maximize.svg"
            color: root.active ? "white" : LomiriColors.slate
        }
    }
}
