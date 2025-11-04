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

import QtQuick 2.15
import Lomiri.Components 1.3
import Utils 0.1 // For EdgeBarrierSettings
import "../Components/PanelState"

Rectangle {
    id: fakeRectangle
    // ENH156 - Advanced snapping keyboard shortcuts
    readonly property bool useForKeyboardShortcut: shell.settings.onlyCommitOnReleaseWhenKeyboardSnapping
    readonly property bool maximized: edge == Item.Top
    readonly property bool maximizedTop: edge == maximizeTopEdge
    readonly property bool maximizedBottom: edge == maximizeBottomEdge
    readonly property bool minimized: edge == Item.Bottom
    readonly property bool maximizedLeft: edge == Item.Left
    readonly property bool maximizedRight: edge == Item.Right
    readonly property bool maximizedTopLeft: edge == Item.TopLeft
    readonly property bool maximizedTopRight: edge == Item.TopRight
    readonly property bool maximizedBottomLeft: edge == Item.BottomLeft
    readonly property bool maximizedBottomRight: edge == Item.BottomRight
    readonly property bool anyMaximized: maximized || maximizedLeft || maximizedRight || maximizedTopLeft
                                            || maximizedTopRight || maximizedBottomLeft || maximizedBottomRight
                                            || maximizedTop || maximizedBottom

    readonly property int maximizeTopEdge: 20
    readonly property int maximizeBottomEdge: 21
    property bool delayedSnappingIsHappening: false
    property bool delayedSnappingIsInitialShow: true
    property real launcherWidth
    // visible: opacity > 0 && target && !target.anyMaximized // we go from 0.2 to 0.5
    visible: opacity > 0 && target && (!target.anyMaximized || delayedSnappingIsHappening) // we go from 0.2 to 0.5
    // ENH156 - End
    enabled: visible
    // ENH156 - Advanced snapping keyboard shortcuts
    // color: "#ffffff"
    color: shell.settings.useCustomWindowSnappingRectangleColor ? shell.settings.customWindowSnappingRectangleColor
                : "#ffffff"
    // ENH156 - End
    border.width: units.dp(2)
    // ENH156 - Advanced snapping keyboard shortcuts
    // border.color: "#99ffffff"
    border.color: shell.settings.useCustomWindowSnappingRectangleBorderColor ? shell.settings.customWindowSnappingRectangleBorderColor
                    : "#99ffffff"
    // ENH156 - End

    scale: progress > 0 && progress <= hintThreshold ? MathUtils.projectValue(progress, 0.0, 1.0, 1, 2) : 1
    opacity: progress > 0 ? MathUtils.projectValue(progress, 0.0, 1.0, 0.2, 0.5) : 0

    property int edge: -1 // Item.TransformOrigin
    property var target   // appDelegate
    property int leftMargin
    property real appContainerWidth
    property real appContainerHeight
    property PanelState panelState

    readonly property real hintThreshold: 0.1

    // Edge push progress
    // Value range is [0.0, 1.0]
    readonly property real progress: priv.directProgress != -1 ? priv.directProgress : priv.accumulatedProgress

    signal passed(int origin)

    QtObject {
        id: priv

        readonly property real accumulatedProgress: MathUtils.clamp(accumulatedPush / EdgeBarrierSettings.pushThreshold, 0.0, 1.0)
        property real directProgress: -1
        property real accumulatedPush: 0

        function push(amount) {
            if (accumulatedPush === EdgeBarrierSettings.pushThreshold) {
                // NO-OP
                return;
            }

            if (accumulatedPush + amount > EdgeBarrierSettings.pushThreshold) {
                accumulatedPush = EdgeBarrierSettings.pushThreshold;
            } else {
                accumulatedPush += amount;
            }

            if (accumulatedPush === EdgeBarrierSettings.pushThreshold) {
                passed(edge);
                // commit(); // NB: uncomment to have automatic maximization on 100% progress
            }
        }

        function setup(edge) {
            if (edge !== fakeRectangle.edge) {
                stop(); // a different edge, start anew
            }
            // ENH156 - Advanced snapping keyboard shortcuts
            // fakeRectangle.x = target.x;
            // fakeRectangle.y = target.y;
            // fakeRectangle.width = target.width;
            // fakeRectangle.height = target.height;
            if (fakeRectangle.delayedSnappingIsInitialShow) {
                fakeRectangle.x = target.x;
                fakeRectangle.y = target.y;
                fakeRectangle.width = target.width;
                fakeRectangle.height = target.height;
            }
            // ENH156 - End
            fakeRectangle.edge = edge;
            // ENH156 - Advanced snapping keyboard shortcuts
            // fakeRectangle.transformOrigin = edge;
            if (edge == fakeRectangle.maximizeTopEdge) {
                fakeRectangle.transformOrigin = Item.Top;
            } else if (edge == fakeRectangle.maximizeBottomEdge) {
                fakeRectangle.transformOrigin = Item.Bottom;
            } else {
                fakeRectangle.transformOrigin = edge;
            }
            // ENH156 - End
        }

        function processAnimation(amount, animation, isProgress) {
            if (isProgress) {
                priv.directProgress = amount;
            } else {
                priv.directProgress = -1;
                priv.push(amount);
            }

            if (progress > hintThreshold) { // above 10% we start the full preview animation
                animation.start();
            }
        }
    }

    function commit() {
        if (progress > hintThreshold && edge != -1) {
            // ENH156 - Advanced snapping keyboard shortcuts
            // Stop and hide when snapping is cancelled
            if ((maximized && target.maximized)
                || (maximizedTop && target.maximizedHorizontally)
                || (maximizedBottom && target.maximizedVertically)
                || (minimized && target.minimized)
                || (maximizedLeft && target.maximizedLeft)
                || (maximizedRight && target.maximizedRight)
                || (maximizedTopLeft && target.maximizedTopLeft)
                || (maximizedTopRight && target.maximizedTopRight)
                || (maximizedBottomLeft && target.maximizedBottomLeft)
                || (maximizedBottomRight && target.maximizedBottomRight)
                || (!anyMaximized && !minimized && !target.anyMaximized && !target.minimized)
                ) {
                stop()
                return
            }
            // ENH156 - End
            if (edge == Item.Top) {
                target.requestMaximize();
            } else if (edge == Item.Left) {
                target.requestMaximizeLeft();
            } else if (edge == Item.Right) {
                target.requestMaximizeRight();
            } else if (edge == Item.TopLeft) {
                target.requestMaximizeTopLeft();
            } else if (edge == Item.TopRight) {
                target.requestMaximizeTopRight();
            } else if (edge == Item.BottomLeft) {
                target.requestMaximizeBottomLeft();
            } else if (edge == Item.BottomRight) {
                target.requestMaximizeBottomRight();
            // ENH156 - Advanced snapping keyboard shortcuts
            } else if (edge == fakeRectangle.maximizeTopEdge) {
                target.requestMaximizeHorizontally()
            } else if (edge == fakeRectangle.maximizeBottomEdge) {
                target.requestMaximizeVertically()
            } else if (edge == Item.Bottom) {
                if (!target.minimized) {
                    target.requestMinimize();
                }
            } else if (edge == Item.Center) {
                if (target.minimized || target.anyMaximized) {
                    target.requestRestore();
                }
            // ENH156 - End
            }
        } else {
            stop();
        }
    }

    function stop() {
        priv.accumulatedPush = 0;
        priv.directProgress = -1;
        edge = -1;
    }

    // ENH156 - Advanced snapping keyboard shortcuts
    function restore(amount, isProgress) {
        if (fakeRectangle.edge != Item.Center) {
            priv.setup(Item.Center);
        }
        priv.processAnimation(amount, fakeRestoreAnimation, isProgress);
    }

    function minimize(amount, isProgress) {
        if (fakeRectangle.edge != Item.Bottom) {
            priv.setup(Item.Bottom);
        }
        priv.processAnimation(amount, fakeMinimizeAnimation, isProgress);
    }

    function maximizeTop(amount, isProgress) {
        if (fakeRectangle.edge != fakeRectangle.maximizeTopEdge) {
            priv.setup(fakeRectangle.maximizeTopEdge);
        }
        priv.processAnimation(amount, fakeMaximizeTopAnimation, isProgress);
    }

    function maximizeBottom(amount, isProgress) {
        if (fakeRectangle.edge != fakeRectangle.maximizeBottomEdge) {
            priv.setup(fakeRectangle.maximizeBottomEdge);
        }
        priv.processAnimation(amount, fakeMaximizeBottomAnimation, isProgress);
    }
    // ENH156 - End

    function maximize(amount, isProgress) {
        if (fakeRectangle.edge != Item.Top) {
            priv.setup(Item.Top);
        }
        priv.processAnimation(amount, fakeMaximizeAnimation, isProgress);
    }

    function maximizeLeft(amount, isProgress) {
        if (fakeRectangle.edge != Item.Left) {
            priv.setup(Item.Left);
        }
        priv.processAnimation(amount, fakeMaximizeLeftAnimation, isProgress);
    }

    function maximizeRight(amount, isProgress) {
        if (fakeRectangle.edge != Item.Right) {
            priv.setup(Item.Right);
        }
        priv.processAnimation(amount, fakeMaximizeRightAnimation, isProgress);
    }

    function maximizeTopLeft(amount, isProgress) {
        if (fakeRectangle.edge != Item.TopLeft) {
            priv.setup(Item.TopLeft);
        }
        priv.processAnimation(amount, fakeMaximizeTopLeftAnimation, isProgress);
    }

    function maximizeTopRight(amount, isProgress) {
        if (fakeRectangle.edge != Item.TopRight) {
            priv.setup(Item.TopRight);
        }
        priv.processAnimation(amount, fakeMaximizeTopRightAnimation, isProgress);
    }

    function maximizeBottomLeft(amount, isProgress) {
        if (fakeRectangle.edge != Item.BottomLeft) {
            priv.setup(Item.BottomLeft);
        }
        priv.processAnimation(amount, fakeMaximizeBottomLeftAnimation, isProgress);
    }

    function maximizeBottomRight(amount, isProgress) {
        if (fakeRectangle.edge != Item.BottomRight) {
            priv.setup(Item.BottomRight);
        }
        priv.processAnimation(amount, fakeMaximizeBottomRightAnimation, isProgress);
    }

    Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.BriskDuration } }
    Behavior on scale { LomiriNumberAnimation { duration: LomiriAnimation.BriskDuration } }

    ParallelAnimation {
        id: fakeMaximizeAnimation
        LomiriNumberAnimation { target: fakeRectangle; properties: "x"; duration: LomiriAnimation.BriskDuration; to: leftMargin }
        LomiriNumberAnimation { target: fakeRectangle; properties: "y"; duration: LomiriAnimation.BriskDuration; to: panelState.panelHeight }
        LomiriNumberAnimation { target: fakeRectangle; properties: "width"; duration: LomiriAnimation.BriskDuration; to: appContainerWidth - leftMargin }
        LomiriNumberAnimation { target: fakeRectangle; properties: "height"; duration: LomiriAnimation.BriskDuration; to: appContainerHeight }
    }

    ParallelAnimation {
        id: fakeMaximizeLeftAnimation
        LomiriNumberAnimation { target: fakeRectangle; properties: "x"; duration: LomiriAnimation.BriskDuration; to: leftMargin }
        LomiriNumberAnimation { target: fakeRectangle; properties: "y"; duration: LomiriAnimation.BriskDuration; to: panelState.panelHeight }
        LomiriNumberAnimation { target: fakeRectangle; properties: "width"; duration: LomiriAnimation.BriskDuration; to: (appContainerWidth - leftMargin)/2 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "height"; duration: LomiriAnimation.BriskDuration; to: appContainerHeight - panelState.panelHeight }
    }

    ParallelAnimation {
        id: fakeMaximizeRightAnimation
        LomiriNumberAnimation { target: fakeRectangle; properties: "x"; duration: LomiriAnimation.BriskDuration; to: (appContainerWidth + leftMargin)/2 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "y"; duration: LomiriAnimation.BriskDuration; to: panelState.panelHeight }
        LomiriNumberAnimation { target: fakeRectangle; properties: "width"; duration: LomiriAnimation.BriskDuration; to: (appContainerWidth - leftMargin)/2 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "height"; duration: LomiriAnimation.BriskDuration; to: appContainerHeight - panelState.panelHeight }
    }

    ParallelAnimation {
        id: fakeMaximizeTopLeftAnimation
        LomiriNumberAnimation { target: fakeRectangle; properties: "x"; duration: LomiriAnimation.BriskDuration; to: leftMargin }
        LomiriNumberAnimation { target: fakeRectangle; properties: "y"; duration: LomiriAnimation.BriskDuration; to: panelState.panelHeight }
        LomiriNumberAnimation { target: fakeRectangle; properties: "width"; duration: LomiriAnimation.BriskDuration; to: (appContainerWidth - leftMargin)/2 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "height"; duration: LomiriAnimation.BriskDuration; to: (appContainerHeight - panelState.panelHeight)/2 }
    }

    ParallelAnimation {
        id: fakeMaximizeTopRightAnimation
        LomiriNumberAnimation { target: fakeRectangle; properties: "x"; duration: LomiriAnimation.BriskDuration; to: (appContainerWidth + leftMargin)/2 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "y"; duration: LomiriAnimation.BriskDuration; to: panelState.panelHeight }
        LomiriNumberAnimation { target: fakeRectangle; properties: "width"; duration: LomiriAnimation.BriskDuration; to: (appContainerWidth - leftMargin)/2 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "height"; duration: LomiriAnimation.BriskDuration; to: (appContainerHeight - panelState.panelHeight)/2 }
    }

    ParallelAnimation {
        id: fakeMaximizeBottomLeftAnimation
        LomiriNumberAnimation { target: fakeRectangle; properties: "x"; duration: LomiriAnimation.BriskDuration; to: leftMargin }
        LomiriNumberAnimation { target: fakeRectangle; properties: "y"; duration: LomiriAnimation.BriskDuration; to: (appContainerHeight + panelState.panelHeight)/2 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "width"; duration: LomiriAnimation.BriskDuration; to: (appContainerWidth - leftMargin)/2 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "height"; duration: LomiriAnimation.BriskDuration; to: appContainerHeight/2 }
    }

    ParallelAnimation {
        id: fakeMaximizeBottomRightAnimation
        LomiriNumberAnimation { target: fakeRectangle; properties: "x"; duration: LomiriAnimation.BriskDuration; to: (appContainerWidth + leftMargin)/2 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "y"; duration: LomiriAnimation.BriskDuration; to: (appContainerHeight + panelState.panelHeight)/2 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "width"; duration: LomiriAnimation.BriskDuration; to: (appContainerWidth - leftMargin)/2 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "height"; duration: LomiriAnimation.BriskDuration; to: appContainerHeight/2 }
    }

    // ENH156 - Advanced snapping keyboard shortcuts
    ParallelAnimation {
        id: fakeMinimizeAnimation
        LomiriNumberAnimation { target: fakeRectangle; properties: "x"; duration: LomiriAnimation.BriskDuration; to: launcherWidth }
        LomiriNumberAnimation { target: fakeRectangle; properties: "y"; duration: LomiriAnimation.BriskDuration; to: (appContainerHeight) * 0.75 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "width"; duration: LomiriAnimation.BriskDuration; to: units.gu(6) }
        LomiriNumberAnimation { target: fakeRectangle; properties: "height"; duration: LomiriAnimation.BriskDuration; to: units.gu(6) }
    }
    ParallelAnimation {
        id: fakeRestoreAnimation
        LomiriNumberAnimation { target: fakeRectangle; properties: "x"; duration: LomiriAnimation.BriskDuration; to: fakeRectangle.target ? fakeRectangle.target.normalX : 0 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "y"; duration: LomiriAnimation.BriskDuration; to: fakeRectangle.target ? fakeRectangle.target.normalY : 0 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "width"; duration: LomiriAnimation.BriskDuration; to: fakeRectangle.target ? fakeRectangle.target.normalWidth : 0 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "height"; duration: LomiriAnimation.BriskDuration; to: fakeRectangle.target ? fakeRectangle.target.normalHeight : 0 }
    }
    ParallelAnimation {
        id: fakeMaximizeTopAnimation
        LomiriNumberAnimation { target: fakeRectangle; properties: "x"; duration: LomiriAnimation.BriskDuration; to: leftMargin }
        LomiriNumberAnimation { target: fakeRectangle; properties: "y"; duration: LomiriAnimation.BriskDuration; to: panelState.panelHeight }
        LomiriNumberAnimation { target: fakeRectangle; properties: "width"; duration: LomiriAnimation.BriskDuration; to: appContainerWidth - leftMargin }
        LomiriNumberAnimation { target: fakeRectangle; properties: "height"; duration: LomiriAnimation.BriskDuration; to: (appContainerHeight - panelState.panelHeight)/2 }
    }
    ParallelAnimation {
        id: fakeMaximizeBottomAnimation
        LomiriNumberAnimation { target: fakeRectangle; properties: "x"; duration: LomiriAnimation.BriskDuration; to: leftMargin }
        LomiriNumberAnimation { target: fakeRectangle; properties: "y"; duration: LomiriAnimation.BriskDuration; to: (appContainerHeight + panelState.panelHeight)/2 }
        LomiriNumberAnimation { target: fakeRectangle; properties: "width"; duration: LomiriAnimation.BriskDuration; to: appContainerWidth - leftMargin }
        LomiriNumberAnimation { target: fakeRectangle; properties: "height"; duration: LomiriAnimation.BriskDuration; to: (appContainerHeight - panelState.panelHeight)/2 }
    }
    // ENH156 - End
}
