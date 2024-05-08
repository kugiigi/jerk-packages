/*
 * Copyright 2016 Canonical Ltd.
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

import QtQuick 2.4
import Morph.Web 0.1
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtWebEngine 1.5
import "../actions" as Actions
import ".."
import "sapot" as Sapot
import QtQuick.Window 2.2

Sapot.WebViewImpl {
    id: webappWebview

    property Sapot.ChromeBase chrome
    property alias scrollTracker: scrollTrackerItem
    property Item scrollPositionerParent: webappWebview
    property bool wide: false
    property bool webviewPulledDown: false
    readonly property real contentHeight: contentsSize.height / scaleFactor

    signal openUrlExternallyRequested(string url)

    function pullDownWebview() {
        webviewPulledDown = true
    }

    function pullUpWebview() {
        webviewPulledDown = false
    }

    function scrollToTop(){
        runJavaScript("window.scrollTo(0, 0); ")
    }

    function scrollToBottom(){
        runJavaScript("window.scrollTo(0, " + contentsSize.height +"); ")
    }

    Loader {
        id: contentHandlerLoader
        source: "../ContentHandler.qml"
        asynchronous: true
    }

    QtObject {
        id: internal

        function instantiateShareComponent() {
            var component = Qt.createComponent("../Share.qml")
            if (component.status === Component.Ready) {
                var share = component.createObject(webappWebview)
                share.onDone.connect(share.destroy)
                return share
            }
            return null
        }

        function shareLink(url, title) {
            var share = instantiateShareComponent()
            if (share) share.shareLink(url, title)
        }

        function shareText(text) {
            var share = instantiateShareComponent()
            if (share) share.shareText(text)
        }
    }

    Loader {
        id: filePickerLoader
        source: "ContentPickerDialog.qml"
        asynchronous: true
    }

    Sapot.WebviewSwipeHandler {
        id: leftSwipeGesture
        objectName: "leftSwipeGesture"

        z: 1
        webviewPullDownState: webappWebview.webviewPulledDown
        enabled: webapp.settings && webapp.settings.enableWebviewPullDownGestures
        usePhysicalUnit: webapp.settings && webapp.settings.physicalForGestures
        width: (Screen.pixelDensity * 25.4) * 0.2 // 0.2 inch
        anchors {
            left: parent ? parent.left : undefined
            top: parent ? parent.top : undefined
            bottom: parent ? parent.bottom : undefined
        }

        onTrigger: {
            if (webviewPullDownState) {
                webappWebview.pullUpWebview()
            } else {
                webappWebview.pullDownWebview()
            }
        }
    }

    Sapot.WebviewSwipeHandler {
        id: rightSwipeGesture
        objectName: "rightSwipeGesture"

        z: 1
        webviewPullDownState: webappWebview.webviewPulledDown
        enabled: webapp.settings && webapp.settings.enableWebviewPullDownGestures
        usePhysicalUnit: webapp.settings && webapp.settings.physicalForGestures
        width: (Screen.pixelDensity * 25.4) * 0.2 // 0.2 inch
        anchors {
            right: parent ? parent.right : undefined
            top: parent ? parent.top : undefined
            bottom: parent ? parent.bottom : undefined
        }

        onTrigger: {
            if (webviewPullDownState) {
                webappWebview.pullUpWebview()
            } else {
                webappWebview.pullDownWebview()
            }
        }
    }

    Sapot.ScrollTracker {
        id: scrollTrackerItem

        active: webappWebview && !webappWebview.isFullScreen
        webview: webappWebview
        header: webappWebview.chrome

        onScrolledUp: {
            if (header.autoHide) header.changeChromeState()
            if (header.timesOut && !header.holdTimeout) header.state = "hidden"
        }
        onScrolledDown: {
            if (header.autoHide) header.changeChromeState()
            if (header.timesOut && !header.holdTimeout) header.state = "hidden"
        }
    }

    Sapot.ScrollPositionerItem {
        id: scrollPositioner

        parent: webappWebview.scrollPositionerParent
        active: webapp.settings.appWideScrollPositioner
        target: webappWebview
        z: webappWebview.z + 1
        sideMargin: units.gu(2)
        bottomMargin: units.gu(5)
        position: webapp.settings.scrollPositionerPosition
        buttonWidthGU: webapp.settings.scrollPositionerSize
        mode: scrollTrackerItem.scrollingUp ? "Up" : "Down"
        forceHide: webappWebview.isFullScreen
    }
}
