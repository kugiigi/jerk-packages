/*
 * Copyright 2014-2016 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import Lomiri.Components 1.3
import QtWebEngine 1.10
import "../.."
import "." as Sapot

// use styled item otherwise Drawer button will steal focus from the AddressBar
StyledItem {
    id: chrome

    property WebEngineView webview
    property Sapot.ScrollTracker scrollTracker
    readonly property real visibleHeight: y + height
    readonly property bool moving: (y < 0) && (y > yWhenHidden)
    property real yWhenHidden: -height

    objectName: "chromeBase"

    property alias backgroundColor: backgroundRect.color

    property bool loading: false
    property real loadProgress: 0.0

    property bool floating: false
    property bool autoHide: false
    property bool alwaysHidden: false

    property bool timesOut: false
    property alias timeOutTimer: timeOutTimer
    property int timeout: 1500
    property bool holdTimeout: false

    states: [
        State {
            name: "shown"
        },
        State {
            name: "hidden"
        }
    ]

    state: alwaysHidden ? "hidden" : "shown"

    y: (state == "shown") ? 0 : yWhenHidden
    Behavior on y {
        SmoothedAnimation {
            duration: LomiriAnimation.BriskDuration
        }
    }

    function changeChromeState(newState) {
        delayStateChange.newState = newState ? newState : ""
        delayStateChange.restart()
    }

    onStateChanged: {
        if (state == "shown" && timesOut) {
            timeOutTimer.restart()
        }
    }

    onAutoHideChanged: {
        if (!autoHide) {
            if (!webview.isFullScreen) {
                state = "shown"
            }
        } else {
            changeChromeState()
        }
    }

    onTimesOutChanged: {
        if (state == "shown" && timesOut) {
            timeOutTimer.restart()
        } else {
            if (!webview.isFullScreen) {
                changeChromeState("shown")
            }
        }
    }

    onHoldTimeoutChanged: {
        if (timesOut && !alwaysHidden) {
            if (holdTimeout) {
                timeOutTimer.stop()
            } else {
                timeOutTimer.restart()
            }
        }
    }
    
    // Delay state change to allow for the webview change to take effect in the calculations
    Timer {
        id: delayStateChange

        property string newState

        interval: 1
        running: false
        onTriggered: {
            if (chrome.autoHide) {
                if ((scrollTracker.nearTop || (scrollTracker.nearTop && scrollTracker.nearBottom)
                        || scrollTracker.webview.scrollPosition.y == 0)
                         && !chrome.webview.isFullScreen) {
                    chrome.state = "shown"
                } else if (scrollTracker.nearBottom) {
                    chrome.state = "hidden"
                } else {
                    if (!chrome.moving) {
                        if (scrollTracker.scrollingUp) {
                            chrome.state = "shown"
                        } else {
                            chrome.state = "hidden"
                        }
                    }
                }
            } else {
                chrome.state = newState
            }
        }
    }

    Timer {
        id: timeOutTimer

        running: true
        interval: chrome.timeout
        onTriggered: {
            if (chrome.timesOut && !hoverHandler.hovered && !chrome.holdTimeout) {
                chrome.state = "hidden"
            }
        }
    }

    HoverHandler {
        id: hoverHandler
        onHoveredChanged: {
            if (!hovered) {
                timeOutTimer.restart()
            }
        }
    }

    Rectangle {
        id: backgroundRect

        anchors.fill: parent
        color: theme.palette.normal.background

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: units.dp(1)
            color: theme.palette.normal.base
        }
    }

    ThinProgressBar {
        id: progressBar

        visible: chrome.loading
        value: chrome.loadProgress

        anchors {
            left: parent.left
            right: parent.right
            top: parent.bottom
        }
        objectName: "chromeProgressBar"
    }
}
