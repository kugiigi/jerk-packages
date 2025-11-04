/*
 * Copyright (C) 2017 Canonical Ltd.
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
import QtMir.Application 0.1
import WindowManager 1.0
import Utils 0.1
import ".."
import "../../Components"

Item {
    id: previewSpace
    clip: true

    property var workspace

    property QtObject screen
    property string background
    property real screenHeight
    property real launcherWidth

    property real previewScale: previewSpace.height / previewSpace.screenHeight

    property bool containsDragLeft: false
    property bool containsDragRight: false
    property bool isActive: false
    property bool isSelected: false

    Image {
        source: previewSpace.background
        anchors.fill: parent
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectCrop
        autoTransform: true
        asynchronous: true

        Repeater {
            id: topLevelSurfaceRepeater
            model: visible ? workspace.windowModel : null
            delegate: Item {
                id: delegateItem

                readonly property bool isMaximized : model.window.state === Mir.MaximizedState
                readonly property bool isFullscreen : model.window.state === Mir.FullscreenState
                readonly property bool isAnyMaximized : isMaximized || isMaximizedVertically || isMaximizedHorizontally
                                                        || isMaximizedLeft || isMaximizedRight || isMaximizedTopLeft
                                                        || isMaximizedTopRight || isMaximizedBottomLeft || isMaximizedBottomRight
                readonly property bool isMaximizedVertically : model.window.state === Mir.VertMaximizedState
                readonly property bool isMaximizedHorizontally : model.window.state === Mir.HorizMaximizedState
                readonly property bool isMaximizedLeft : model.window.state === Mir.MaximizedLeftState
                readonly property bool isMaximizedRight : model.window.state === Mir.MaximizedRightState
                readonly property bool isMaximizedTopLeft : model.window.state === Mir.MaximizedTopLeftState
                readonly property bool isMaximizedTopRight : model.window.state === Mir.MaximizedTopRightState
                readonly property bool isMaximizedBottomLeft : model.window.state === Mir.MaximizedBottomLeftState
                readonly property bool isMaximizedBottomRight : model.window.state === Mir.MaximizedBottomRightState

                width: {
                    if (isFullscreen || isMaximized || isMaximizedHorizontally) {
                        return previewSpace.width
                    }

                    if (isMaximizedLeft || isMaximizedRight || isMaximizedTopLeft || isMaximizedTopRight
                            || isMaximizedBottomLeft || isMaximizedBottomRight) {
                        return previewSpace.width / 2
                    }

                    return surfaceItem.width * previewScale
                }
                height: {
                    if (isFullscreen || isMaximized || isMaximizedVertically || isMaximizedLeft || isMaximizedRight) {
                        return previewSpace.height
                    }

                    if (isMaximizedTopLeft || isMaximizedTopRight || isMaximizedBottomLeft || isMaximizedBottomRight) {
                        return previewSpace.height / 2
                    }

                    return (surfaceItem.height * previewScale) + decorationHeight
                }
                x: {
                    if (isFullscreen || isMaximized || isMaximizedLeft || isMaximizedTopLeft
                            || isMaximizedBottomLeft || isMaximizedHorizontally) {
                        return 0
                    }

                    if (isMaximizedRight || isMaximizedTopRight || isMaximizedBottomRight) {
                        return previewSpace.width / 2
                    }

                    return (model.window.position.x - screen.position.x - previewSpace.launcherWidth) * previewScale
                }
                y: {
                    if (isFullscreen || isMaximized || isMaximizedLeft || isMaximizedRight || isMaximizedTopLeft
                            || isMaximizedTopRight || isMaximizedVertically) {
                        return 0
                    }

                    if (isMaximizedBottomLeft || isMaximizedBottomRight) {
                        return previewSpace.height / 2
                    }

                    return (model.window.position.y - screen.position.y - decorationHeight) * previewScale
                }
                z: topLevelSurfaceRepeater.count - index
                visible: model.window.state !== Mir.MinimizedState && model.window.state !== Mir.HiddenState

                property int decorationHeight: isFullscreen || isMaximized ? 0 : units.gu(3)

                WindowDecoration {
                    width: surfaceItem.implicitWidth
                    height: parent.decorationHeight
                    transform: Scale {
                        origin.x: 0
                        origin.y: 0
                        xScale: previewScale
                        yScale: previewScale
                    }
                    title: model.window && model.window.surface ? model.window.surface.name : ""
                    z: 3
                }

                MirSurfaceItem {
                    id: surfaceItem
                    y: parent.decorationHeight * previewScale
                    width: implicitWidth
                    height: implicitHeight
                    surface: model.window.surface
                    transform: Scale {
                        origin.x: 0
                        origin.y: 0
                        xScale: previewScale
                        yScale: previewScale
                    }
                }
            }
        }

    }

    Rectangle {
        anchors.fill: parent
        border.color: LomiriColors.ash
        border.width: units.gu(.5)
        color: "transparent"
        visible: previewSpace.isActive
    }

    Rectangle {
        anchors.fill: parent
        border.color: LomiriColors.blue
        border.width: units.gu(.5)
        color: "transparent"
        visible: previewSpace.isSelected
    }

    Rectangle {
        anchors.fill: parent
        anchors.rightMargin: parent.width / 2
        color: "#55000000"
        visible: previewSpace.containsDragLeft

        Column {
            anchors.centerIn: parent
            spacing: units.gu(1)
            Icon {
                source: "../graphics/multi-monitor_drop-here.png"
                height: units.gu(4)
                width: height
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Label {
                text: qsTr("Drop here")
                color: "white"
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: parent.width / 2
        color: "#55000000"
        visible: previewSpace.containsDragRight

        Column {
            anchors.centerIn: parent
            spacing: units.gu(1)
            Icon {
                source: "../graphics/multi-monitor_leave.png"
                height: units.gu(4)
                width: height
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Label {
                text: qsTr("Drop and go")
                color: "white"
            }
        }
    }
}
