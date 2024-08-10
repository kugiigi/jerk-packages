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

import QtQuick 2.12
import Lomiri.Components 1.3
import QtMir.Application 0.1
import WindowManager 1.0
import ".."
import "../../Components"
// ENH185 - Workspace spread UI fixes
import Utils 0.1
// ENH185 - End

Item {
    id: previewSpace
    clip: true

    property var workspace

    property QtObject screen
    property string background
    // ENH185 - Workspace spread UI fixes
    // property int screenHeight
    property real screenHeight
    // ENH185 - End

    property real previewScale: previewSpace.height / previewSpace.screenHeight

    property bool containsDragLeft: false
    property bool containsDragRight: false
    property bool isActive: false
    property bool isSelected: false
    // ENH154 - Workspace switcher gesture
    scale: isSelected ? 1.1 : 1
    Behavior on scale { LomiriNumberAnimation {} }
    // ENH154 - End

    Image {
        source: previewSpace.background
        anchors.fill: parent
        sourceSize.width: width
        sourceSize.height: height
        // ENH185 - Workspace spread UI fixes
        fillMode: Image.PreserveAspectCrop
        autoTransform: true
        // ENH185 - End

        Repeater {
            id: topLevelSurfaceRepeater
            model: visible ? workspace.windowModel : null
            delegate: Item {
                readonly property bool isMaximized : model.window.state === Mir.MaximizedState
                // ENH185 - Workspace spread UI fixes
                id: delegateItem
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
                readonly property int stage : WindowStateStorage.getStage(model.application.appId, ApplicationInfoInterface.MainStage)
                readonly property bool isMainStage : !shell.isWindowedMode && stage == ApplicationInfoInterface.MainStage
                readonly property bool isSideStage : !shell.isWindowedMode && stage == ApplicationInfoInterface.SideStage
                // width: surfaceItem.width * previewScale
                // height: surfaceItem.height + decorationHeight * previewScale
                // x: isMaximized ? 0 : (model.window.position.x - screen.position.x) * previewScale
                // y: isMaximized ? 0 : (model.window.position.y - screen.position.y - decorationHeight) * previewScale
                width: {
                    if (isMainStage) {
                        if (shell.sideStageShown) {
                            return previewSpace.width - (shell.sideStageWidth * previewScale)
                        } else {
                            return previewSpace.width
                        }
                    }

                    if (isSideStage) {
                        return shell.sideStageWidth * previewScale
                    }

                    // ENH156 - Advanced snapping keyboard shortcuts
                    //if (isFullscreen || isMaximized || isMaximizedHorizontally) {
                    if (isFullscreen || isMaximized || isMaximizedHorizontally
                            || (shell.settings.replaceHorizontalVerticalSnappingWithBottomTop && isMaximizedVertically)) {
                    // ENH156 - End
                        return previewSpace.width
                    }

                    if (isMaximizedLeft || isMaximizedRight || isMaximizedTopLeft || isMaximizedTopRight
                            || isMaximizedBottomLeft || isMaximizedBottomRight) {
                        return previewSpace.width / 2
                    }

                    return surfaceItem.width * previewScale
                }
                height: {
                    if (isFullscreen || isMaximized || isMainStage || isSideStage
                            // ENH156 - Advanced snapping keyboard shortcuts
                            //|| isMaximizedVertically || isMaximizedLeft || isMaximizedRight) {
                            || (isMaximizedVertically && !shell.settings.replaceHorizontalVerticalSnappingWithBottomTop) || isMaximizedLeft || isMaximizedRight) {
                            // ENH156 - End
                        return previewSpace.height
                    }

                    // ENH156 - Advanced snapping keyboard shortcuts
                    //if (isMaximizedTopLeft || isMaximizedTopRight || isMaximizedBottomLeft || isMaximizedBottomRight) {
                    if (isMaximizedTopLeft || isMaximizedTopRight || isMaximizedBottomLeft || isMaximizedBottomRight
                            || (shell.settings.replaceHorizontalVerticalSnappingWithBottomTop && (isMaximizedHorizontally || isMaximizedVertically))
                        ) {
                    // ENH156 - End
                        return previewSpace.height / 2
                    }

                    return (surfaceItem.height * previewScale) + decorationHeight
                }
                x: {
                    if (isSideStage) {
                        return previewSpace.width - (shell.sideStageWidth * previewScale)
                    }

                    if (isFullscreen || isMainStage || isMaximized || isMaximizedLeft || isMaximizedTopLeft
                            // ENH156 - Advanced snapping keyboard shortcuts
                            //|| isMaximizedBottomLeft || isMaximizedHorizontally) {
                            || isMaximizedBottomLeft || isMaximizedHorizontally
                            || (shell.settings.replaceHorizontalVerticalSnappingWithBottomTop && isMaximizedVertically)
                        ) {
                            // ENH156 - End
                        return 0
                    }

                    if (isMaximizedRight || isMaximizedTopRight || isMaximizedBottomRight) {
                        return previewSpace.width / 2
                    }

                    return (model.window.position.x - screen.position.x) * previewScale
                }
                y: {
                    if (isFullscreen || isMaximized || isMaximizedLeft || isMaximizedRight || isMaximizedTopLeft
                            // ENH156 - Advanced snapping keyboard shortcuts
                            //|| isMaximizedTopRight || isMaximizedVertically
                            || isMaximizedTopRight || (isMaximizedVertically && !shell.settings.replaceHorizontalVerticalSnappingWithBottomTop)
                            || (shell.settings.replaceHorizontalVerticalSnappingWithBottomTop && isMaximizedHorizontally)
                            // ENH156 - End
                            || isMainStage || isSideStage) {
                        return 0
                    }

                    // ENH156 - Advanced snapping keyboard shortcuts
                    //if (isMaximizedBottomLeft || isMaximizedBottomRight) {
                    if (isMaximizedBottomLeft || isMaximizedBottomRight
                            || (isMaximizedVertically && shell.settings.replaceHorizontalVerticalSnappingWithBottomTop)) {
                    // ENH156 - End
                        return previewSpace.height / 2
                    }

                    return (model.window.position.y - screen.position.y - decorationHeight) * previewScale
                }
                // ENH185 - End
                z: topLevelSurfaceRepeater.count - index
                visible: model.window.state !== Mir.MinimizedState && model.window.state !== Mir.HiddenState
                // ENH185 - Workspace spread UI fixes
                            && !(isSideStage && !shell.sideStageShown)
                onIsSideStageChanged: {
                    if (isSideStage && model.window.state !== Mir.MinimizedState && model.window.state !== Mir.HiddenState) {
                        sideStageDragHandle.thereIsSideStageApp = true
                    }
                }
                // ENH185 - End

                // ENH185 - Workspace spread UI fixes
                // property int decorationHeight: units.gu(3)
                property int decorationHeight: isFullscreen ? 0 : units.gu(3)
                // ENH185 - End

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
                    // ENH180 - Match window titlebar with app
                    visible: !delegateItem.isMainStage && !delegateItem.isSideStage && !delegateItem.isFullscreen
                    blurSource: surfaceItem
                    blurUpdates: false
                    // ENH180 - End
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
    
    // ENH185 - Workspace spread UI fixes
    Handle {
        id: sideStageDragHandle

        property bool thereIsSideStageApp: false

        x: previewSpace.width - (shell.sideStageWidth * previewScale) - (width / 2)
        visible: opacity > 0
        opacity: shell.sideStageShown && thereIsSideStageApp ? 1 : 0
        height: screenHeight
        width: units.gu(2)

        Image {
            z: -1
            anchors.centerIn: parent
            width: parent.width * 2
            height: parent.height
            source: "../graphics/sidestage_handle@20.png"
        }

        transform: Scale {
            origin.x: 0
            origin.y: 0
            xScale: previewScale
            yScale: previewScale
        }
    }
    // ENH185 - End

    Rectangle {
        anchors.fill: parent
        border.color: LomiriColors.ash
        // ENH154 - Workspace switcher gesture
        // border.width: units.gu(.5)
        border.width: units.gu(1)
        // ENH154 - End
        color: "transparent"
        visible: previewSpace.isActive
    }

    Rectangle {
        anchors.fill: parent
        border.color: LomiriColors.blue
        // ENH154 - Workspace switcher gesture
        // border.width: units.gu(.5)
        border.width: units.gu(1)
        // ENH154 - End
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
            }
        }
    }
}
