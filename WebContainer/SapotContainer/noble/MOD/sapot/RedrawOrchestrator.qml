/*
 * Copyright 2026 UBports Foundation
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

// Workaround for QtWebEngine 6.10 with libhybris ANGLE & Ozone buffer sharing
// The current web page would turn black if the
// app gets resumed from suspend. Enqueueing a
// redraw through visibility changes restores the page.
// Ensure we fill a snapshot image in for flicker-free visuals.

import QtQml
import QtQuick
import QtWebEngine

Item {
    // required property BrowserWindow browserWindow
    required property WebEngineView webview

    property bool prevVisible : true;
    property bool grabbing : false;
    property bool grabInterrupted : false;

    // Show a snapshot of the window, created when suspending
    Image {
        id: windowSnapshot
        anchors.fill: parent
        visible: false
    }

    Timer {
        id: hideSnapshotTimer
        repeat: false
        running: false
        // interval: 750
        interval: 100
        onTriggered: {
            windowSnapshot.visible = false;
        }
    }


    // Force redraw once process is active again
    Connections {
        target: Application
        function onStateChanged() {
            if (Application.state === Qt.ApplicatonHidden ||
                Application.state === Qt.ApplicationSuspended)
            {
                orchestrateRedraw(false);
            }
            else if (Application.state === Qt.ApplicationActive)
            {
                orchestrateRedraw(true);
            }
            else if (Application.state === Qt.ApplicationInactive && windowSnapshot.visible)
            {
                orchestrateRedraw(true);
            }
        }
    }

    /*
    Connections {
        target: browserWindow
        target: webview

        function onActiveChanged() {
            orchestrateRedraw(browserWindow.active);
        }

        function onWidthChanged() {
            orchestrateRedraw(true);
        }
        function onHeightChanged() {
            orchestrateRedraw(true);
        }
    }
    */

    function orchestrateRedraw(finalize) {
        if (!finalize)
        {
            hideSnapshotTimer.stop();

            if (!grabbing && !windowSnapshot.visible
                    // && currentWebview.visible) {
                    && webview.visible) {
                // prevVisible = currentWebview.visible;
                prevVisible = webview.visible;
                grabInterrupted = false;

                webview.visible = false
                webview.visible = true

                // grabbing = browserWindow.contentItem.grabToImage(function(result) {
                grabbing = webview.grabToImage(function(result) {
                    if (grabInterrupted) {
                        grabbing = false;
                        return;
                    }
                    windowSnapshot.source = result.url;
                    windowSnapshot.visible = true;
                    grabbing = false;
                    // currentWebview.visible = false;
                    // webview.visible = false;
                }, Qt.size(
                    // browserWindow.contentItem.width,
                    // browserWindow.contentItem.height
                    webview.width,
                    webview.height
                ));
            }
        } else {
            hideSnapshotTimer.restart();
            // currentWebview.visible = prevVisible;
            // webview.visible = prevVisible;
            webview.visible = false;
            webview.visible = true;
            grabInterrupted = true;
        }
    }
}
