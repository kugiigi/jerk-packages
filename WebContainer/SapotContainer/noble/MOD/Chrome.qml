/*
 * Copyright 2013-2016 Canonical Ltd.
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
import Lomiri.Components 1.3
import ".."
import "sapot" as Sapot

Sapot.ChromeBase {
    id: chrome

    property bool wide: false
    property bool navigationButtonsVisible: false
    property bool accountSwitcher: false
    property real availableHeight
    signal toggleDownloads()
    property bool showDownloadButton: false
    property bool downloadNotify: false
    readonly property alias downloadsButtonPlaceHolder: downloadsButton

    property bool navHistoryOpen: false
    property color iconColor: theme.palette.normal.baseText

    property bool isPopupOverlay: false
    property bool incognito: false
    property string searchUrl

    loading: webview && webview.loading && webview.loadProgress !== 100
    loadProgress: loading ? webview.loadProgress : 0

    function updateChromeElementsColor(color) {
        chromeTextLabel.color = color;

        backButton.iconColor = color;
        forwardButton.iconColor = color;

        reloadButton.iconColor = color;
        settingsButton.iconColor = color;
        accountsButton.iconColor = color;

        readerModeButton.iconColor = Qt.binding(function(){ return chrome.webview && chrome.webview.readerMode ? theme.palette.normal.focus : color})
        downloadsButton.iconColor = Qt.binding(function(){ return downloadNotify ? theme.palette.normal.focus : color})
    }

    function showNavHistory(model, fromBottom, caller) {
        navHistPopup.model = model
        navHistPopup.show(fromBottom, caller)
    }

    function showBackNavHistory(fromBottom, caller) {
        showNavHistory(webview.navigationHistory.backItems, fromBottom, caller)
    }

    function showForwardNavHistory(fromBottom, caller) {
        showNavHistory(webview.navigationHistory.forwardItems, fromBottom, caller)
    }

    signal closeOverlay
    signal openLinkExternally
    signal chooseAccount()

    Sapot.NavHistoryPopup {
        id: navHistPopup

        property int navOffset: 0

        availHeight: chrome.availableHeight
        availWidth: chrome.width
        onNavigate: {
            // Navigate only after the dialog has closed
            // so history list won't be seen updating
            navOffset = offset
        }
        onOpened: chrome.navHistoryOpen = true
        onClosed: {
            chrome.navHistoryOpen = false
            if (navOffset !== 0) {
                chrome.webview.goBackOrForward(navOffset)
            }
            navOffset = 0
        }
    }

    FocusScope {
        anchors {
            fill: parent
            margins: units.gu(1)
        }

        focus: true

        ChromeButton {
            id: closeButton
            objectName: "overlayCloseButton"
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            height: parent.height
            width: visible ? height : 0

            iconName: "dropdown-menu"
            iconSize: 0.6 * height

            enabled: true
            visible: chrome.isPopupOverlay

            MouseArea {
                anchors.fill: parent
                onClicked: chrome.closeOverlay()
            }
        }

        ChromeButton {
            id: backButton
            objectName: "backButton"

            iconName: "previous"
            iconSize: 0.6 * height
            iconColor: chrome.iconColor

            height: parent.height
            visible: chrome.isPopupOverlay ? enabled : chrome.navigationButtonsVisible
            width: visible ? height : 0

            enableContextMenu: true
            contextMenu: navHistPopup

            anchors {
                left: closeButton.right
                verticalCenter: parent.verticalCenter
            }

            enabled: chrome.webview ? chrome.webview.canGoBack : false
            onTriggered: {
                if (chrome.webview.loading) {
                    chrome.webview.stop()
                }
                chrome.webview.goBack()
            }

            onShowContextMenu: showNavHistory(chrome.webview.navigationHistory.backItems, false, backButton)
        }

        ChromeButton {
            id: forwardButton
            objectName: "forwardButton"

            iconName: "next"
            iconSize: 0.6 * height
            iconColor: chrome.iconColor

            height: parent.height
            visible: chrome.navigationButtonsVisible && enabled
            width: visible ? height : 0

            enableContextMenu: true
            contextMenu: navHistPopup

            anchors {
                left: backButton.right
                verticalCenter: parent.verticalCenter
            }

            enabled: chrome.webview ? chrome.webview.canGoForward : false
            onTriggered: {
                if (chrome.webview.loading) {
                    chrome.webview.stop()
                }
                chrome.webview.goForward()
            }

            onShowContextMenu: showNavHistory(chrome.webview.navigationHistory.forwardItems, false, forwardButton)
        }

        Item {
            id: faviconContainer

            height: parent.height
            width: height
            anchors.left: forwardButton.right

            Favicon {
                anchors.centerIn: parent
                source: chrome.webview ? chrome.webview.icon : null
                shouldCache: chrome.isPopupOverlay && chrome.incognito ? false : true
            }
        }

        Label {
            id: chromeTextLabel
            objectName: "chromeTextLabel"

            anchors {
                left: faviconContainer.right
                right: readerModeButton.left
                rightMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }

            text: chrome.webview.title ? chrome.webview.title : chrome.webview.url
            elide: Text.ElideRight
        }

        ChromeButton {
            id: readerModeButton
            objectName: "readerModeButton"

            iconName: "stock_ebook"
            iconSize: 0.6 * height
            iconColor: chrome.webview && chrome.webview.readerMode ? theme.palette.normal.focus : chrome.iconColor

            height: parent.height
            visible: chrome.webview && (chrome.webview.isReaderable || chrome.webview.readerMode)
            width: visible ? height : 0

            anchors {
                right: homeButton.left
                verticalCenter: parent.verticalCenter
            }

            onTriggered: chrome.webview.toggleReaderMode()
        }

        ChromeButton {
            id: homeButton
            objectName: "homeButton"

            iconName: "go-home"
            iconSize: 0.6 * height
            iconColor: chrome.iconColor

            height: parent.height
            visible: chrome.navigationButtonsVisible && !chrome.isPopupOverlay
            width: visible ? height : 0

            anchors {
                right: reloadButton.left
                verticalCenter: parent.verticalCenter
            }

            enabled: chrome.webview.url && chrome.webview.url !== ""
            onTriggered: webapp.goHome()
        }

        ChromeButton {
            id: reloadButton
            objectName: "reloadButton"

            iconName: "reload"
            iconSize: 0.6 * height
            iconColor: chrome.iconColor

            height: parent.height
            visible: chrome.navigationButtonsVisible
            width: visible ? height : 0

            anchors {
                right: downloadsButton.left
                verticalCenter: parent.verticalCenter
            }

            enabled: chrome.webview.url && chrome.webview.url !== ""
            onTriggered: chrome.webview.reload()
        }

        ChromeButton {
            id: downloadsButton
            objectName: "downloadsButton"

            visible: chrome.navigationButtonsVisible && showDownloadButton && !chrome.isPopupOverlay
            iconName: "save"
            iconSize: 0.6 * height
            iconColor: chrome.iconColor

            height: parent.height
            width: visible ? height : 0

            anchors {
                right: settingsButton.left
                verticalCenter: parent.verticalCenter
            }

            Connections {
                target: root
                ignoreUnknownSignals: true

                onDownloadNotifyChanged: {
                    if (downloadNotify) {
                        shakeAnimation.start()
                    }
                }
            }

            Behavior on iconColor {
                ColorAnimation { duration: LomiriAnimation.BriskDuration  }
            }

            SequentialAnimation {
                id: shakeAnimation

                loops: 4

                RotationAnimation {
                    target: downloadsButton
                    direction: RotationAnimation.Counterclockwise
                    to: 350
                    duration: 50
                }

                RotationAnimation {
                    target: downloadsButton
                    direction: RotationAnimation.Clockwise
                    to: 10
                    duration: 50
                }

                RotationAnimation {
                    target: downloadsButton
                    direction: RotationAnimation.Counterclockwise
                    to: 0
                    duration: 50
                }
            }

            onTriggered: {
                toggleDownloads()
            }
        }

        ChromeButton {
            id: settingsButton
            objectName: "settingsButton"

            iconName: "settings"
            iconSize: 0.6 * height
            iconColor: chrome.iconColor

            height: parent.height
            visible: chrome.navigationButtonsVisible && !chrome.isPopupOverlay
            width: visible ? height : 0

            anchors {
                right: accountsButton.left
                verticalCenter: parent.verticalCenter
            }

            onTriggered: webapp.showWebappSettings()
        }

        ChromeButton {
            id: accountsButton
            objectName: "accountsButton"

            iconName: "contact"
            iconSize: 0.6 * height
            iconColor: chrome.iconColor

            height: parent.height
            width: visible ? height : 0

            anchors {
                right: buttonOpenInBrowser.left
                verticalCenter: parent.verticalCenter
            }

            visible: accountSwitcher && !chrome.isPopupOverlay
            onTriggered: chrome.chooseAccount()
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
            width: visible ? height : 0

            iconName: "external-link"
            iconSize: 0.6 * height
            iconColor: chrome.iconColor

            enabled: true
            visible: chrome.isPopupOverlay

            MouseArea {
                anchors.fill: parent
                onClicked: chrome.openLinkExternally()
            }
        }
    }
}
