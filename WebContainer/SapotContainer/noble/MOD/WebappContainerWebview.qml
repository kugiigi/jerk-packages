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

import QtQuick 2.4
import QtQuick.Window 2.2
import Lomiri.Components 1.3
import Lomiri.Action 1.1 as LomiriActions
import webbrowsercommon.private 0.1
import QtQuick.Controls 2.2 as QQC2
import "../actions" as Actions
import ".."
import "sapot" as Sapot

FocusScope {
    id: containerWebview

    property Window window
    property bool initialUrlLoaded: false
    property string url: ""
    property bool developerExtrasEnabled: false
    property string webappName: ""
    property var dataPath
    property var currentWebview: webappContainerWebViewLoader.item ?
                                     webappContainerWebViewLoader.item.currentWebview
                                   : null
    property var webappUrlPatterns
    property string localUserAgentOverride: ""
    property string popupRedirectionUrlPrefixPattern: ""
    property url webviewOverrideFile: ""
    property bool blockOpenExternalUrls: false
    property bool runningLocalApplication: false
    property bool wide: false
    property bool openExternalUrlInOverlay: false
    property bool popupBlockerEnabled: true

    property Sapot.ChromeBase chromeItem
    property Sapot.ScrollTracker scrollTracker: webappContainerWebViewLoader.item ? webappContainerWebViewLoader.item.scrollTracker : null
    property var overlayViewsParent: parent

    signal samlRequestUrlPatternReceived(string urlPattern)
    signal themeColorMetaInformationDetected(string theme_color)

    onWideChanged: {
        if (webappContainerWebViewLoader.item
                && webappContainerWebViewLoader.item.wide !== undefined) {
            webappContainerWebViewLoader.item.wide = wide
        }
    }

    function openOverlayForUrl(_url, _incognito) {
        if (webappContainerWebViewLoader.item) {
            webappContainerWebViewLoader.item.openOverlayForUrl(_url, _incognito)
        }
    }

    Component {
        id: mediaAccessDialogComponent
        MediaAccessDialog {
            objectName: "mediaAccessDialog"
        }
    }

    PopupWindowController {
        id: popupController
        objectName: "popupController"
        webappUrlPatterns: containerWebview.webappUrlPatterns
        mainWebappView: containerWebview.currentWebview
        blockOpenExternalUrls: containerWebview.blockOpenExternalUrls
        mediaAccessDialogComponent: mediaAccessDialogComponent
        wide: containerWebview.wide
        onInitializeOverlayViewsWithUrls: {
            if (webappContainerWebViewLoader.item) {
                for (var i in urls) {
                    webappContainerWebViewLoader
                        .item
                        .openOverlayForUrl(urls[i])
                }
            }
        }

    }

    Connections {
        target: webappContainerWebViewLoader.item
        onSamlRequestUrlPatternReceived: {
            samlRequestUrlPatternReceived(urlPattern)
        }

        onThemeColorMetaInformationDetected: {
            themeColorMetaInformationDetected(theme_color)
        }

        onLastLoadSucceededChanged: {
          if (! initialUrlLoaded && webappContainerWebViewLoader.item.lastLoadSucceeded) {
             if (!webapp.settings.restorePreviousURL && UrlUtils.extractScheme(containerWebView.url) !== 'file') {
                webappContainerWebViewLoader.item.runJavaScript("window.location.replace('%1')".arg(containerWebView.url))
             }
             initialUrlLoaded = true
          }
        }
        
        onIsFullScreenChanged: {
            target.pullUpWebview()
            if (target.isFullScreen) {
                fullscreenExitHintComponent.createObject(webappContainerWebViewLoader)
            } else {
                webappContainerWebViewLoader.rotation = 0
            }
        }

        onUrlChanged: {
            if (webapp.settings.restorePreviousURL) {
                webapp.settings.previousURL = target.url
            }
        }
    }

    Loader {
        id: webappContainerWebViewLoader
        objectName: "containerWebviewLoader"

        focus: true
        property QtObject rotateButtonObj
        readonly property bool rotateAvailable: item && item.isFullScreen
                                    && webapp.rotationAngle !== rotation

        anchors.centerIn: parent
        anchors.verticalCenterOffset: item && item.webviewPulledDown ? item.height / 3 : 0
        width: rotation == 270 || rotation == 90 || rotation == -270 || rotation == -90 ? parent.height : parent.width
        height: rotation == 270 || rotation == 90 || rotation == -270 || rotation == -90 ? parent.width : parent.height
        
        Behavior on anchors.verticalCenterOffset {
            LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
        }

        Behavior on rotation {
            RotationAnimation { direction: RotationAnimation.Shortest }
        }

        function showRotateButton() {
            if (rotateButtonObj) {
                rotateButtonObj.delayHide()
            } else {
                rotateButtonObj = rotateButtonComponent.createObject(containerWebview)
            }
        }

        // FIXME: Workaround on some devices where rotation detection doesn't work the first time
        // the browser go into full screen
        onRotateAvailableChanged: {
            if (webappContainerWebViewLoader.rotateAvailable) {
                webappContainerWebViewLoader.showRotateButton()
            }
        }
        
        onRotationChanged: {
            if (rotation !== 0 && webappContainerWebViewLoader.item.isFullScreen) {
                fullscreenExitHintComponent.createObject(webappContainerWebViewLoader)
            }
        }

        Connections {
            target: webapp
            onSensorOrientationChanged: {
                if (webappContainerWebViewLoader.rotateAvailable) {
                    webappContainerWebViewLoader.showRotateButton()
                }
            }
        }
    }

    // Vibe coded XD
    // Custom implementation of zooming with Ctrl + Mouse scroll
    // zoomFactor property doesn't change when you zoom with this
    // so we just do it ourselves as advised by Grok LOL
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true

        onWheel: (wheel) => {
            if (wheel.modifiers & Qt.ControlModifier) {
                wheel.accepted = true;

                var delta = wheel.angleDelta.y > 0 ? 0.1 : -0.1;
                // or use angleDelta / 120 to match browser steps

                currentWebview.zoomFactor = Math.max(0.25, Math.min(5.0,currentWebview.zoomFactor + delta));
            } else {
                wheel.accepted = false;   // let normal scrolling happen
            }
        }
    }

    onUrlChanged: if (webappContainerWebViewLoader.item) webappContainerWebViewLoader.item.url = url

    Component.onCompleted: {
        var webappEngineSource = Qt.resolvedUrl("WebViewImplOxide.qml");

        // This is an experimental, UNSUPPORTED, API
        // It loads an alternative webview, adjusted for a specific webapp
        if (webviewOverrideFile.toString()) {
            console.log("Loading custom webview from " + webviewOverrideFile);
            webappEngineSource = webviewOverrideFile;
        }

        webappContainerWebViewLoader.setSource(
                    webappEngineSource,
                    { window: containerWebView.window
                    , localUserAgentOverride: containerWebview.localUserAgentOverride
                    , url: (UrlUtils.extractScheme(containerWebview.url) === 'file') ? containerWebview.url : 'about:blank'
                    , webappName: containerWebview.webappName
                    , dataPath: dataPath
                    , webappUrlPatterns: containerWebview.webappUrlPatterns
                    , developerExtrasEnabled: containerWebview.developerExtrasEnabled
                    , popupRedirectionUrlPrefixPattern: containerWebview.popupRedirectionUrlPrefixPattern
                    , blockOpenExternalUrls: containerWebview.blockOpenExternalUrls
                    , runningLocalApplication: containerWebview.runningLocalApplication
                    , popupController: popupController
                    , overlayViewsParent: containerWebview.overlayViewsParent
                    , wide: containerWebview.wide
                    , mediaAccessDialogComponent: mediaAccessDialogComponent
                    , openExternalUrlInOverlay: containerWebview.openExternalUrlInOverlay
                    , chrome: containerWebview.chromeItem
                    , scrollPositionerParent: containerWebview.parent
                    , popupBlockerEnabled: containerWebview.popupBlockerEnabled})
    }

    Component {
        id: rotateButtonComponent

        Sapot.CustomizedButton {
            id: rotateButton

            display: QQC2.AbstractButton.IconOnly

            anchors {
                bottom: parent.bottom
                bottomMargin: units.gu(4)
                horizontalCenter: parent.horizontalCenter
            }

            leftPadding: units.gu(2)
            rightPadding: leftPadding
            topPadding: leftPadding
            bottomPadding: leftPadding
            opacity: 0.5
            radius: width / 2

            icon {
                name: "view-rotate"
                width: units.gu(4)
                height: units.gu(4)
            }

            onClicked: {
                delayHide()

                webappContainerWebViewLoader.rotation = webapp.rotationAngle
            }

            function delayHide() {
                hideDelay.restart()
            }

            Behavior on opacity {
                LomiriNumberAnimation {
                    duration: LomiriAnimation.SlowDuration
                }
            }
            onOpacityChanged: {
                if (opacity == 0.0) {
                    rotateButton.destroy()
                }
            }

            // Delay showing to prevent it from jumping up while the
            // webview is being resized
            visible: false
            Timer {
                running: true
                interval: 250
                onTriggered: {
                    if (webappContainerWebViewLoader.rotateAvailable || webappContainerWebViewLoader.orientationMismatch) {
                        rotateButton.visible = true
                    }
                }
            }

            Timer {
                id: hideDelay

                running: rotateButton.visible
                interval: 2000
                onTriggered: rotateButton.opacity = 0
            }

            Connections {
                target: webappContainerWebViewLoader.item
                onIsFullScreenChanged: {
                    if (!target.isFullScreen) {
                        rotateButton.destroy()
                    }
                }
            }
        }
    }

    Component {
        id: fullscreenExitHintComponent

        Rectangle {
            id: fullscreenExitHint
            objectName: "fullscreenExitHint"

            anchors {
                horizontalCenter: webappContainerWebViewLoader.rotation !== 0 ? undefined : parent.horizontalCenter
                left: webappContainerWebViewLoader.rotation == -90 ? parent.left : undefined
                right: webappContainerWebViewLoader.rotation == 90 ? parent.right : undefined
                margins: webappContainerWebViewLoader.rotation !== 0 ? units.gu(2) : 0
                bottom: parent.bottom
                bottomMargin : units.gu(5)
            }
            height: units.gu(6)
            width: Math.min(units.gu(50), parent.width - units.gu(12))
            radius: units.gu(1)
            color: theme.palette.normal.backgroundSecondaryText
            opacity: 0.85

            Behavior on opacity {
                LomiriNumberAnimation {
                    duration: LomiriAnimation.SlowDuration
                }
            }
            onOpacityChanged: {
                if (opacity == 0.0) {
                    fullscreenExitHint.destroy()
                }
            }

            // Delay showing the hint to prevent it from jumping up while the
            // webview is being resized (https://launchpad.net/bugs/1454097).
            visible: false
            Timer {
                running: true
                interval: 250
                onTriggered: fullscreenExitHint.visible = true
            }

            Label {
                color: theme.palette.normal.background
                font.weight: Font.Light
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: Label.XSmall
                textSize: Label.Large
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors {
                    fill: parent
                    leftMargin: units.gu(2) + (webappContainerWebViewLoader.rotation == 0 || edgePointer.rightEdgeHint ? 0 : edgePointer.width)
                    rightMargin: units.gu(2) + (webappContainerWebViewLoader.rotation == 0 || !edgePointer.rightEdgeHint ? 0 : edgePointer.width)
                }

                text: webappContainerWebViewLoader.rotation == 0 ? i18n.tr("Swipe from the bottom edge to exit")
                            : i18n.tr("Swipe from this edge to exit")
            }

            Icon {
                id: edgePointer

                readonly property bool rightEdgeHint: webappContainerWebViewLoader.rotation == 90

                visible: webappContainerWebViewLoader.rotation !== 0
                height: units.gu(4)
                width: height
                name: rightEdgeHint ? "next" : "previous"
                anchors {
                    right: rightEdgeHint ? parent.right : undefined
                    left: rightEdgeHint ? undefined : parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            Timer {
                running: fullscreenExitHint.visible
                interval: 3000
                onTriggered: fullscreenExitHint.opacity = 0
            }

            Connections {
                target: webappContainerWebViewLoader.item
                onIsFullScreenChanged: {
                    if (!target.isFullScreen) {
                        fullscreenExitHint.destroy()
                    }
                }

                onRotationChanged: {
                    fullscreenExitHint.destroy()
                }
            }
        }
    }
}

