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
import Morph.Web 0.1
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import ".."

FocusScope {
    id: popup

    property var popupWindowController
    property var webContext
    property alias currentWebview: popupWebview
    //property alias request: popupWebview.request
    property alias url: popupWebview.url
    property var mediaAccessDialogComponent
    property alias wide: popupWebview.wide

    signal webviewUrlChanged(url webviewUrl)

    focus: true

    Rectangle {
        color: theme.palette.normal.background
        anchors.fill: parent
    }

    Item {
        id: menubar

        height: units.gu(6)
        width: parent.width

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }

        ChromeButton {
            id: closeButton
            objectName: "overlayCloseButton"
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            height: parent.height
            width: height

            iconName: "dropdown-menu"
            iconSize: 0.6 * height

            enabled: true
            visible: true

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (popupWindowController) {
                        popupWindowController.handleViewRemoved(popup)
                    }
                }
            }
        }

        Item {
            anchors  {
                top: parent.top
                bottom: parent.bottom
                left: closeButton.right
                right: buttonOpenInBrowser.left
            }

            Label {
                anchors {
                    rightMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                }

                text: popupWebview.title ? popupWebview.title : popupWebview.url
                elide: Text.ElideRight
            }

            MouseArea {
                anchors.fill: parent

                property int initMouseY: 0
                property int prevMouseY: 0

                onPressed: {
                    initMouseY = mouse.y
                    prevMouseY = initMouseY
                }
                onReleased: {
                    if ((prevMouseY - initMouseY) > (popup.height / 8) ||
                            popup.y > popup.height/2) {
                        if (popupWindowController) {
                            popupWindowController.handleViewRemoved(popup)
                            return
                        }
                    }
                    popup.y = 0
                }
                onMouseYChanged: {
                    if (popupWindowController) {
                        var diff = mouseY - initMouseY
                        prevMouseY = mouseY
                        popupWindowController.onOverlayMoved(popup, diff)
                    }
                }
            }
        }

        ChromeButton {
            id: buttonOpenInBrowser
            objectName: "overlayButtonOpenInBrowser"
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: units.gu(1)
            }

            height: parent.height
            width: height

            iconName: "external-link"
            iconSize: 0.6 * height

            enabled: true
            visible: true

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (popupWindowController) {
                        popupWindowController.handleOpenInUrlBrowserForView(
                                    popupWebview.url, popup)
                    }
                }
            }
        }
    }

    WebappWebview {
        id: popupWebview

        objectName: "overlayWebview"

        context: webContext

        onUrlChanged: webviewUrlChanged(popupWebview.url)

        focus: true

        Connections {
            target: popupWebview.visible ? popupWebview : null

            /**
             * We are only connecting to the mediaAccessPermission signal if we are the currently
             * visible overlay. If other overlays slide over this one, oxide will deny (by default)
             * all media access requests for this overlay.
             *
             * See the browser's webbrowser/Browser.qml source for additional comments.
             */
            //onMediaAccessPermissionRequested: PopupUtils.open(mediaAccessDialogComponent, null, { request: request })
        }


        onOpenUrlExternallyRequested: {
            if (popupWindowController) {
               popupWindowController.openUrlExternally(url)
            }
        }

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            top: menubar.bottom
        }

        onNewViewRequested: {

            if (!request.userInitiated) {
                return
            }
      
            if (popupWindowController) {
                popupWindowController.createPopupViewForUrl(popup.parent, request.requestedUrl.toString(), false, context)
            }
        }

        function isNewForegroundWebViewDisposition(disposition) {
            return disposition === WebEngineView.NewViewInDialog ||
                    disposition === WebEngineView.NewViewInTab;
        }

        onNavigationRequested: {
            var url = request.url.toString()
            request.action = WebEngineNavigationRequest.AcceptRequest
            if (isNewForegroundWebViewDisposition(request.disposition)) {
                var shouldAcceptRequest =
                        popupWindowController.handleNewForegroundNavigationRequest(url, request, false);
                if (!shouldAcceptRequest) {
                    request.action = WebEngineNavigationRequest.IgnoreRequest
                }
            }
        }
/*
        onCloseRequested: {
            if (popupWindowController) {
                popupWindowController.handleViewRemoved(popup)
            }
        }
*/
        Loader {
            anchors {
                fill: popupWebview
            }
            active: webProcessMonitor.crashed || (webProcessMonitor.killed && !popupWebview.currentWebview.loading)
            sourceComponent: SadPage {
                webview: popupWebview
                objectName: "overlaySadPage"
            }
            WebProcessMonitor {
                id: webProcessMonitor
                webview: popupWebview
            }
            asynchronous: true
        }
    }
}
