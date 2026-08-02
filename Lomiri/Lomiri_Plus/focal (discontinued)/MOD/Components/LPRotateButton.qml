/*
 * Copyright (C) 2016 Canonical, Ltd.
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
import QtQuick.Window 2.2 as QtQuickWindow

Rectangle {
    id: root

    readonly property int screenPhysicalOrientation: QtQuickWindow.Screen.orientation
    readonly property bool rotateAvailable: screenOrientationLocked && screenPhysicalOrientation !== screenOrientation

    property real visibleOpacity: 0.8
    property int screenOrientation: Qt.PortraitOrientation
    property bool screenOrientationLocked: false

    signal clicked

    anchors.margins: units.gu(3)
    states: [
        State {
            when: !root.rotateAvailable
            AnchorChanges {
                target: root
                anchors.right: parent.left
                anchors.top: parent.bottom
            }
        }
        , State {
            when: root.rotateAvailable && root.screenPhysicalOrientation == Qt.InvertedLandscapeOrientation
            AnchorChanges {
                target: root
                anchors.left: parent.left
                anchors.bottom: parent.bottom
            }
        }
        , State {
            when: root.rotateAvailable && root.screenPhysicalOrientation == Qt.LandscapeOrientation
            AnchorChanges {
                target: root
                anchors.right: parent.right
                anchors.top: parent.top
            }
        }
        , State {
            when: root.rotateAvailable && root.screenPhysicalOrientation == Qt.PortraitOrientation
            AnchorChanges {
                target: root
                anchors.right: parent.right
                anchors.bottom: parent.bottom
            }
        }
        , State {
            when: root.rotateAvailable && root.screenPhysicalOrientation == Qt.InvertedPortraitOrientation
            AnchorChanges {
                target: root
                anchors.left: parent.left
                anchors.top: parent.top
            }
        }
    ]

    height: units.gu(4)
    width: height
    radius: width / 2
    visible: opacity > 0
    opacity: 0
    color: theme.palette.normal.background
    border {
        width: units.dp(1)
        color: theme.palette.normal.backgroundText
    }

    function show() {
        if (!visible) {
            showDelay.restart()
        }
    }

    function hide() {
        hideAnimation.restart()
        showDelay.stop()
    }

    Icon {
        id: icon

        implicitWidth: units.gu(3)
        implicitHeight: implicitWidth
        anchors.centerIn: parent
        asynchronous: true
        name: "view-rotate"
        color: theme.palette.normal.backgroundText
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.hide()
            root.clicked()
        }
    }

    LomiriNumberAnimation {
        id: showAnimation

        running: false
        property: "opacity"
        target: root
        alwaysRunToEnd: true
        to: root.visibleOpacity
        duration: LomiriAnimation.SlowDuration
    }

    LomiriNumberAnimation {
        id: hideAnimation

        running: false
        property: "opacity"
        target: root
        alwaysRunToEnd: true
        to: 0
        duration: LomiriAnimation.FastDuration
    }

    SequentialAnimation {
        running: root.visible
        loops: 3
        RotationAnimation {
            target: root
            duration: LomiriAnimation.SnapDuration
            to: 0
            direction: RotationAnimation.Shortest
        }
        NumberAnimation { target: icon; duration: LomiriAnimation.SnapDuration; property: "opacity"; to: 1 }
        PauseAnimation { duration: LomiriAnimation.SlowDuration }
        RotationAnimation {
            target: root
            duration: LomiriAnimation.SlowDuration
            to: root.screenOrientationLocked ? QtQuickWindow.Screen.angleBetween(root.screenOrientation, root.screenPhysicalOrientation) : 0
            direction: RotationAnimation.Shortest
        }
        PauseAnimation { duration: LomiriAnimation.SlowDuration }
        NumberAnimation { target: icon; duration: LomiriAnimation.SnapDuration; property: "opacity"; to: 0 }

        onFinished: root.hide()
    }

    Timer {
        id: showDelay

        running: false
        interval: 1000
        onTriggered: {
            showAnimation.restart()
        }
    }

    Timer {
        id: hideDelay

        running: false
        interval: 3000
        onTriggered: root.hide()
    }
}
