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

import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Gestures 0.1
import QtMir.Application 0.1

Item {
    id: root

    // to be set from outside
    property Item target // appDelegate
    property WindowResizeArea resizeArea
    property Item boundsItem

    // to be read from outside
    readonly property alias overlayShown: overlay.visible
    readonly property alias dragging: priv.dragging

    signal fakeMaximizeAnimationRequested(real amount)
    signal fakeMaximizeLeftAnimationRequested(real amount)
    signal fakeMaximizeRightAnimationRequested(real amount)
    signal fakeMaximizeTopLeftAnimationRequested(real amount)
    signal fakeMaximizeTopRightAnimationRequested(real amount)
    signal fakeMaximizeBottomLeftAnimationRequested(real amount)
    signal fakeMaximizeBottomRightAnimationRequested(real amount)
    signal stopFakeAnimation()
    signal dragReleased()

    TouchGestureArea {
        id: gestureArea
        anchors.fill: parent

        // NB: for testing set to 2, not to clash with lomiri7 touch overlay controls
        minimumTouchPoints: 3
        maximumTouchPoints: minimumTouchPoints

        readonly property bool recognizedPress: status == TouchGestureArea.Recognized &&
                                                touchPoints.length >= minimumTouchPoints &&
                                                touchPoints.length <= maximumTouchPoints
        onRecognizedPressChanged: {
            if (recognizedPress) {
                target.activate();
                overlayTimer.start();
            }
        }

        readonly property bool recognizedDrag: recognizedPress && dragging
        onRecognizedDragChanged: {
            if (recognizedDrag) {
                moveHandler.handlePressedChanged(true, Qt.LeftButton, tp.x, tp.y);
            } else if (!mouseArea.containsPress) { // prevent interfering with the central piece drag/move
                moveHandler.handlePressedChanged(false, Qt.LeftButton);
                root.dragReleased();
                moveHandler.handleReleased(true);
            }
        }

        readonly property point tp: recognizedPress ? Qt.point(touchPoints[0].x, touchPoints[0].y) : Qt.point(-1, -1)
        onUpdated: {
            if (recognizedDrag) {
                moveHandler.handlePositionChanged(tp, priv.getSensingPoints());
            }
        }
    }

    // dismiss timer
    Timer {
        id: overlayTimer
        interval: 2000
        repeat: priv.dragging
    }

    QtObject {
        id: priv
        readonly property bool dragging: moveHandler.dragging || (root.resizeArea && root.resizeArea.dragging)

        function getSensingPoints() {
            var xPoints = [];
            var yPoints = [];
            for (var i = 0; i < gestureArea.touchPoints.length; i++) {
                var pt = gestureArea.touchPoints[i];
                xPoints.push(pt.x);
                yPoints.push(pt.y);
            }

            var leftmost = Math.min.apply(Math, xPoints);
            var rightmost = Math.max.apply(Math, xPoints);
            var topmost = Math.min.apply(Math, yPoints);
            var bottommost = Math.max.apply(Math, yPoints);

            return {
                left: mapToItem(target.parent, leftmost, (topmost+bottommost)/2),
                top: mapToItem(target.parent, (leftmost+rightmost)/2, topmost),
                right: mapToItem(target.parent, rightmost, (topmost+bottommost)/2),
                topLeft: mapToItem(target.parent, leftmost, topmost),
                topRight: mapToItem(target.parent, rightmost, topmost),
                bottomLeft: mapToItem(target.parent, leftmost, bottommost),
                bottomRight: mapToItem(target.parent, rightmost, bottommost)
            }
        }
    }

    // the visual overlay
    Item {
        id: overlay
        objectName: "windowControlsOverlay"
        anchors.fill: parent
        enabled: overlayTimer.running
        visible: opacity > 0
        opacity: enabled ? 0.95 : 0

        Behavior on opacity {
            LomiriNumberAnimation {}
        }

        Image {
            source: "graphics/arrows-centre.png"
            width: units.gu(10)
            height: width
            sourceSize: Qt.size(width, height)
            anchors.centerIn: parent
            visible: target && target.width > units.gu(12) && target.height > units.gu(12)

            // move handler
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                visible: overlay.visible
                enabled: visible
                hoverEnabled: true

                onPressedChanged: moveHandler.handlePressedChanged(pressed, pressedButtons, mouseX, mouseY)
                onPositionChanged: moveHandler.handlePositionChanged(mouse)
                onReleased: {
                    root.dragReleased();
                    moveHandler.handleReleased();
                }
            }

            MoveHandler {
                id: moveHandler
                objectName: "moveHandler"
                target: root.target

                boundsItem: root.boundsItem

                onFakeMaximizeAnimationRequested: root.fakeMaximizeAnimationRequested(amount)
                onFakeMaximizeLeftAnimationRequested: root.fakeMaximizeLeftAnimationRequested(amount)
                onFakeMaximizeRightAnimationRequested: root.fakeMaximizeRightAnimationRequested(amount)
                onFakeMaximizeTopLeftAnimationRequested: root.fakeMaximizeTopLeftAnimationRequested(amount)
                onFakeMaximizeTopRightAnimationRequested: root.fakeMaximizeTopRightAnimationRequested(amount)
                onFakeMaximizeBottomLeftAnimationRequested: root.fakeMaximizeBottomLeftAnimationRequested(amount)
                onFakeMaximizeBottomRightAnimationRequested: root.fakeMaximizeBottomRightAnimationRequested(amount)
                onStopFakeAnimation: root.stopFakeAnimation()
            }

            // dismiss area
            InverseMouseArea {
                anchors.fill: parent
                visible: overlay.visible
                enabled: visible
                onPressed: {
                    if (gestureArea.recognizedPress || gestureArea.recognizedDrag) {
                        mouse.accepted = false;
                        return;
                    }

                    overlayTimer.stop();
                    mouse.accepted = root.contains(mapToItem(root.target.clientAreaItem, mouse.x, mouse.y));
                }
                propagateComposedEvents: true
            }
        }

        ResizeGrip { // top left
            anchors.horizontalCenter: parent.left
            anchors.verticalCenter: parent.top
            visible: root.enabled || target.maximizedBottomRight
            resizeTarget: root.resizeArea
        }

        ResizeGrip { // top center
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.top
            rotation: 45
            visible: root.enabled || target.maximizedHorizontally || target.maximizedBottomLeft || target.maximizedBottomRight
            resizeTarget: root.resizeArea
        }

        ResizeGrip { // top right
            anchors.horizontalCenter: parent.right
            anchors.verticalCenter: parent.top
            rotation: 90
            visible: root.enabled || target.maximizedBottomLeft
            resizeTarget: root.resizeArea
        }

        ResizeGrip { // right
            anchors.horizontalCenter: parent.right
            anchors.verticalCenter: parent.verticalCenter
            rotation: 135
            visible: root.enabled || target.maximizedVertically || target.maximizedLeft ||
                     target.maximizedTopLeft || target.maximizedBottomLeft
            resizeTarget: root.resizeArea
        }

        ResizeGrip { // bottom right
            anchors.horizontalCenter: parent.right
            anchors.verticalCenter: parent.bottom
            visible: root.enabled || target.maximizedTopLeft
            resizeTarget: root.resizeArea
        }

        ResizeGrip { // bottom center
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.bottom
            rotation: 45
            visible: root.enabled || target.maximizedHorizontally || target.maximizedTopLeft || target.maximizedTopRight
            resizeTarget: root.resizeArea
        }

        ResizeGrip { // bottom left
            anchors.horizontalCenter: parent.left
            anchors.verticalCenter: parent.bottom
            rotation: 90
            visible: root.enabled || target.maximizedTopRight
            resizeTarget: root.resizeArea
        }

        ResizeGrip { // left
            anchors.horizontalCenter: parent.left
            anchors.verticalCenter: parent.verticalCenter
            rotation: 135
            visible: root.enabled || target.maximizedVertically || target.maximizedRight ||
                     target.maximizedTopRight || target.maximizedBottomRight
            resizeTarget: root.resizeArea
        }
    }
}
