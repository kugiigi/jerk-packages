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
import QtQuick.Window 2.2
import Morph.Web 0.1
import QtWebEngine 1.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import ".."
import "sapot" as Sapot
import QtQuick.Layouts 1.12

FocusScope {
    id: popup

    property var popupWindowController
    property var webContext
    property alias currentWebview: popupWebview
    //property alias request: popupWebview.request
    property alias url: popupWebview.url
    property var mediaAccessDialogComponent
    property alias wide: popupWebview.wide

    property bool findInPageMode: false
    readonly property real findBarHeight: findLoader.height
    property real findInPageMargin: webapp.osk.height

    signal webviewUrlChanged(url webviewUrl)

    focus: true

    function focusFindField() {
        if (findLoader.item) {
            findLoader.item.focusField()
        }
    }

    onFindInPageModeChanged: {
        if (findInPageMode) {
            if (!findLoader.active) {
                findLoader.active = true
            } else {
                findLoader.show()
            }
        } else {
            findLoader.hide()
        }
    }

    Rectangle {
        color: theme.palette.normal.background
        anchors.fill: parent
    }

    Item {
        id: containerWebView
        anchors {
            bottom: findLoader.top
            left: parent.left
            right: parent.right
            top: menubar.bottom
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

            property QtObject rotateButtonObj
            readonly property bool rotateAvailable: popupWebview.isFullScreen
                                        && webapp.rotationAngle !== rotation

            chrome: menubar
            anchors.centerIn: parent
            anchors.verticalCenterOffset: popupWebview.webviewPulledDown ? popupWebview.height / 3 : 0
            width: rotation == 270 || rotation == 90 || rotation == -270 || rotation == -90 ? parent.height : parent.width
            height: rotation == 270 || rotation == 90 || rotation == -270 || rotation == -90 ? parent.width : parent.height
            
            Behavior on anchors.verticalCenterOffset {
                LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
            }

            Behavior on rotation {
                RotationAnimation { direction: RotationAnimation.Shortest }
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

    Chrome {
        id: menubar

        isPopupOverlay: true
        height: units.gu(6)
        width: parent.width
        scrollTracker: popupWebview.scrollTracker
        webview: popup.currentWebview
        navigationButtonsVisible: webapp.backForwardButtonsVisible
        accountSwitcher: webapp.accountSwitcher
        availableHeight: popup.height
        wide: webapp.wide

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }

        onCloseOverlay: {
            if (popupWindowController) {
                popupWindowController.handleViewRemoved(popup)
            }
        }

        onOpenLinkExternally: {
            if (popupWindowController) {
                popupWindowController.handleOpenInUrlBrowserForView(
                            popupWebview.url, popup)
            }
        }

        SwipeArea {
            anchors.fill: parent
            direction: SwipeArea.Downwards
            
            property int initMouseY: 0
            property int prevMouseY: 0

            onDistanceChanged: {
                if (dragging) {
                    if (popupWindowController) {
                        popup.y = distance
                    }
                }
            }

            onDraggingChanged: {
                 if (!dragging) {
                     popupWindowController.isDragging = false
                    if (distance > (popup.height / 8) ||
                            popup.y > popup.height/2) {
                        if (popupWindowController) {
                            popupWindowController.handleViewRemoved(popup)
                            return
                        }
                    }
                    popup.y = 0
                } else {
                    popupWindowController.isDragging = true
                }
            }
        }
    }

    Sapot.FindInPageBarItem {
        id: findLoader

        findInPageMargin: popup.findInPageMargin
        shortcutFindNextText: shortcutFindNext.nativeText
        shortcutFindPreviousText: shortcutFindPrevious.nativeText
        wide: popup.wide
        findController: popup.currentWebview ? popup.currentWebview.findController : null
        onHidden: popup.findInPageMode = false

        onVisibleChanged: if (!visible) containerWebView.forceActiveFocus()
    }

    Sapot.ActionsFactory {
        id: actionsFactory

        isOverlay: true
        webview: popup.currentWebview

        onFindInPage: shortcutFind.activated()
    }

    // Used for quick actions
    Item {
        id: dummyOverlay

        anchors.fill: parent
    }

    Sapot.GoIndicator {
        id: goForwardIcon

        iconName: "go-next"
        shadowColor: LomiriColors.ash
        swipeProgress: bottomBackForwardHandle.swipeProgress
        enabled: popup.currentWebview ? popup.currentWebview.canGoForward
                                        : false
        anchors {
            right: parent.right
            rightMargin: units.gu(3)
            verticalCenter: parent.verticalCenter
        }
    }

    Sapot.GoIndicator {
        id: goBackIcon

        iconName: "go-previous"
        shadowColor: LomiriColors.ash
        swipeProgress: bottomBackForwardHandle.swipeProgress
        rotation: shortcutWebviewBack.enabled ? 0 : -90
        anchors {
            left: parent.left
            leftMargin: units.gu(3)
            verticalCenter: parent.verticalCenter
        }
    }

    RowLayout {
        id: bottomGestures

        property real sideSwipeAreaWidth: popup.currentWebview && !popup.currentWebview.isFullScreen ?
                                                        popup.width * (popup.width > popup.height ? 0.15 : 0.30)
                                                        : 0

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            top: parent.top
        }

        Loader {
            id: leftSwipeAreaLoader

            Layout.alignment: Qt.AlignLeft | Qt.AlignBottom

            active: webapp.settings.webviewSideSwipe
            asynchronous: true
            visible: status == Loader.Ready
            sourceComponent: Sapot.BottomSwipeArea {
                actionsParent: dummyOverlay
                model: webapp.settings.webviewQuickActions[0] ? actionsFactory.getActionsModel(webapp.settings.webviewQuickActions[0])
                                : []
                implicitWidth: bottomGestures.sideSwipeAreaWidth
                triggerSignalOnQuickSwipe: true
                enableQuickActions: webapp.settings.webviewEnableQuickActions
                enableQuickActionsDelay: webapp.settings.webviewQuickActionEnableDelay
                edge: Sapot.BottomSwipeArea.Edge.Left
                bigUIMode: false
                maxQuickActionsHeightInInch: webapp.settings.webviewQuickActionsHeight
                availableHeight: popup.height
                availableWidth: popup.width
                implicitHeight: units.gu(webapp.settings.bottomGesturesAreaHeight)
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignBottom

            MouseArea {
                id: bottomEdgeHint

                readonly property alias color: recVisual.color
                readonly property real defaultHeight: units.gu(0.5)

                hoverEnabled: true
                height: defaultHeight
                visible: bottomBackForwardHandle.enabled && !webapp.settings.hideBottomHint
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: (((menubar.state == "shown" || menubar.timesOut))
                                                        && webapp.currentWebview && !webapp.currentWebview.isFullScreen) ? defaultHeight
                                                                                                               : -height

                    Behavior on bottomMargin { LomiriNumberAnimation {} }
                }

                Behavior on opacity { LomiriNumberAnimation {} }

                Rectangle {
                    id: recVisual
                    color: bottomEdgeHint.containsMouse ? LomiriColors.silk : LomiriColors.ash
                    radius: height / 2
                    height: bottomEdgeHint.containsMouse ? units.gu(1) : units.gu(0.5)
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: webapp.settings.webviewSideSwipe ? 0 : bottomGestures.sideSwipeAreaWidth
                        right: parent.right
                        rightMargin: webapp.settings.webviewSideSwipe ? 0 : bottomGestures.sideSwipeAreaWidth
                    }
                }
            }

            Sapot.HorizontalSwipeHandle {
                id: bottomBackForwardHandle
                objectName: "bottomBackForwardHandle"

                leftAction: goBackIcon
                rightAction: goForwardIcon
                immediateRecognition: true
                usePhysicalUnit: webapp.settings.physicalForGestures
                height: units.gu(webapp.settings.bottomGesturesAreaHeight)
                swipeHoldDuration: 700
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                enabled: webapp.settings.webviewHorizontalSwipe && popup.currentWebview && (Screen.orientation == Screen.primaryOrientation)
                rightSwipeHoldEnabled: popup.currentWebview ? popup.currentWebview.canGoBack
                                                          : false
                leftSwipeHoldEnabled: popup.currentWebview ? popup.currentWebview.canGoForward
                                                         : false
                leftSwipeActionEnabled: goForwardIcon.enabled
                rightSwipeActionEnabled: goBackIcon.enabled
                onRightSwipe:  {
                    if (shortcutWebviewBack.enabled) {
                        shortcutWebviewBack.activated()
                    } else {
                        menubar.closeOverlay()
                    }
                }
                onLeftSwipe:  shortcutWebviewForward.activated()
                onLeftSwipeHeld: menubar.showForwardNavHistory(true, navHistoryMargin)
                onRightSwipeHeld: menubar.showBackNavHistory(true, navHistoryMargin)
                onPressedChanged: if (pressed) Sapot.Haptics.playSubtle()

                Item {
                    id: navHistoryMargin
                    height: units.gu(10)
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.top
                    }
                }
            }

            Sapot.SwipeGestureHandler {
                id: bottomEdgeHandle
                objectName: "bottomEdgeHandle"

                usePhysicalUnit: webapp.settings.physicalForGestures
                immediateRecognition: !bottomBackForwardHandle.enabled
                height: units.gu(webapp.settings.bottomGesturesAreaHeight)
                swipeHoldDuration:  500
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                enabled: popup.currentWebview && (Screen.orientation == Screen.primaryOrientation)

                onDraggingChanged: {
                    if (!dragging && towardsDirection) {
                        if (popup.currentWebview && popup.currentWebview.isFullScreen) {
                            if (stage > 0) {
                                shortcutExitFullScreen.activated()
                            }
                        }
                    }
                }
            }
        }

        Loader {
            id: rightSwipeAreaLoader

            Layout.alignment: Qt.AlignRight | Qt.AlignBottom

            active: webapp.settings.webviewSideSwipe
            asynchronous: true
            visible: status == Loader.Ready
            sourceComponent: Sapot.BottomSwipeArea {
                actionsParent: dummyOverlay
                model: webapp.settings.webviewQuickActions[1] ? actionsFactory.getActionsModel(webapp.settings.webviewQuickActions[1])
                                : []
                implicitWidth: bottomGestures.sideSwipeAreaWidth
                triggerSignalOnQuickSwipe: true
                enableQuickActions: webapp.settings.webviewEnableQuickActions
                enableQuickActionsDelay: webapp.settings.webviewQuickActionEnableDelay
                edge: Sapot.BottomSwipeArea.Edge.Right
                bigUIMode: false
                maxQuickActionsHeightInInch: webapp.settings.webviewQuickActionsHeight
                availableHeight: popup.height
                availableWidth: popup.width
                implicitHeight: units.gu(webapp.settings.bottomGesturesAreaHeight)
            }
        }
    }

    // F5 or Ctrl+R: Reload current Tab
    Shortcut {
        sequence: "Ctrl+r"
        enabled: currentWebview && currentWebview.visible
        onActivated: currentWebview.reload()
    }
    Shortcut {
        id: shortcutWebviewReload
        sequence: "F5"
        enabled: currentWebview && currentWebview.visible
        onActivated: currentWebview.reload()
    }

    // Alt+← or Backspace: Goes to the previous page
    Shortcut {
        id: shortcutWebviewBack
        sequence: StandardKey.Back
        enabled: currentWebview && currentWebview.canGoBack
        onActivated: currentWebview.goBack()
    }

    // Alt+→ or Shift+Backspace: Goes to the next page
    Shortcut {
        id: shortcutWebviewForward
        sequence: StandardKey.Forward
        enabled: currentWebview && currentWebview.canGoForward
        onActivated: currentWebview.goForward()
    }

    Shortcut {
        id: shortcutFullscreen
        sequence: "F11"
        onActivated: webapp.window.toggleApplicationLevelFullscreen()
    }

    // Escape: Exit webview fullscreen
    Shortcut {
        id: shortcutExitFullScreen
        sequence: "Esc"
        enabled: currentWebview && currentWebview.isFullScreen
        onActivated: {
            if (currentWebview.isFullScreen) {
                currentWebview.fullScreenCancelled()
            }
        }
    }

    // Ctrl+F: Find in Page
    Shortcut {
        id: shortcutFind
        sequence: StandardKey.Find
        enabled: popup.currentWebview
        onActivated: {
            if (popup.currentWebview) {
                if (popup.findInPageMode) {
                    popup.focusFindField()
                } else {
                    popup.findInPageMode = true
                }
            }
        }
    }

    // Ctrl+G: Find next
    Shortcut {
        id: shortcutFindNext

        sequence: "Ctrl+G"
        enabled: popup.currentWebview && popup.findInPageMode
        onActivated: currentWebview.findController.next()
    }

    // Ctrl+Shift+G: Find previous
    Shortcut {
        id: shortcutFindPrevious

        sequence: "Ctrl+Shift+G"
        enabled: popup.currentWebview && popup.findInPageMode
        onActivated: currentWebview.findController.previous()
    }

    // F3: Find next
    Shortcut {
        sequence: StandardKey.FindNext
        enabled: popup.currentWebview && popup.findInPageMode
        onActivated: shortcutFindNext.activated()
    }

    // Shift+F3: Find previous
    Shortcut {
        sequence: StandardKey.FindPrevious
        enabled: popup.currentWebview && popup.findInPageMode
        onActivated: shortcutFindPrevious.activated()
    }
}
