/*
 * Copyright 2013-2017 Canonical Ltd.
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
import QtWebEngine 1.10
import Qt.labs.settings 1.0
import webbrowsercommon.private 0.1
import Morph.Web 0.1
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Action 1.1 as LomiriActions
import "../actions" as Actions
import ".." as Common
import "ColorUtils.js" as ColorUtils
import QtQuick.Window 2.2
import QtSensors 5.2
import "sapot" as Sapot
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12 as QQC2

Common.BrowserView {
    id: webapp

    property Settings settings

    objectName: "webappBrowserView"

    currentWebview: containerWebView.currentWebview

    readonly property bool wide: Window.width >= units.gu(90)
    readonly property bool isFullScreen: Window.visibility == Window.FullScreen

    property alias window: containerWebView.window

    property alias url: containerWebView.url

    property bool accountSwitcher

    property string webappModelSearchPath: ""

    property var webappUrlPatterns
    property alias popupRedirectionUrlPrefixPattern: containerWebView.popupRedirectionUrlPrefixPattern
    property alias webviewOverrideFile: containerWebView.webviewOverrideFile
    property alias blockOpenExternalUrls: containerWebView.blockOpenExternalUrls
    property alias localUserAgentOverride: containerWebView.localUserAgentOverride
    property alias dataPath: containerWebView.dataPath
    property alias runningLocalApplication: containerWebView.runningLocalApplication
    property alias openExternalUrlInOverlay: containerWebView.openExternalUrlInOverlay
    property alias popupBlockerEnabled: containerWebView.popupBlockerEnabled

    property string webappName: ""

    property bool backForwardButtonsVisible: false
    property bool chromeVisible: false
    readonly property bool chromeless: !chromeVisible && !backForwardButtonsVisible && !accountSwitcher
    readonly property real themeColorTextContrastFactor: 3.0
    
    property var recentDownloads: []
    property var currentDownloadsDialog: null

    readonly property bool sensorExists: orientationSensor.connectedToBackend
    readonly property int sensorOrientation: orientationSensor.reading ? orientationSensor.reading.orientation : 0
    readonly property int rotationAngle: {
        if (orientationSensor.reading && Screen.angleBetween(Screen.orientation, orientationSensor.orientation) !== 0) {
            switch (orientationSensor.reading.orientation) {
                case 1: /* OrientationReading.TopUp */
                case 3: /* OrientationReading.LeftUp */
                    return 270
                    break
                case 4: /* OrientationReading.RightUp */
                case 2: /* OrientationReading.TopDown */
                    return 90
                    break
                
                case 5: /* OrientationReading.FaceUp */
                case 6: /* OrientationReading.FaceDown */
                default:
                    return 0
            }
        }

        return 0
    }
    property alias allQuickActions: actionsFactory.allActions
    property alias actionsFactory: actionsFactory
    property alias customURLActions: customURLActionsItem
    property url homeURL: ""
    property bool findInPageMode: false
    readonly property real findBarHeight: findLoader.height
    property real findInPageMargin: keyboardRec.height
    property alias osk: keyboardRec
    property string searchUrl: {
        let _searchEngine = searchEngines[webapp.settings.defaultSearchEngine]
        if (_searchEngine) {
            return _searchEngine.url
        }

        return searchEngines[0].url
    }
    property string searchPageUrl: {
        let _searchEngine = searchEngines[webapp.settings.defaultSearchEngine]
        if (_searchEngine) {
            return _searchEngine.home
        }

        return searchEngines[0].home
    }
    readonly property var searchEngines: [
        { "name" : "DuckDuckGo", "url": "https://duckduckgo.com/?q={searchTerms}", "home": "https://duckduckgo.com" } 
        , { "name" : "Baidu", "url": "https://www.baidu.com/s?ie=utf-8&f=8&rsv_bp=0&wd={searchTerms}", "home": "https://www.baidu.com" }
        , { "name" : "Bing", "url": "https://www.bing.com/search?q={searchTerms}", "home": "https://www.bing.com" }
        , { "name" : "Brave", "url": "https://search.brave.com/search?q={searchTerms}", "home": "https://search.brave.com" }
        , { "name" : "Google", "url": "https://google.com/search?client=ubuntu&q={searchTerms}&ie=utf-8&oe=utf-8", "home": "https://google.com" }
        , { "name" : "StartPage", "url": "https://www.startpage.com/do/dsearch?query={searchTerms}&amp;language=auto", "home": "https://www.startpage.com" }
        , { "name" : "Yahoo", "url": "https://search.yahoo.com/yhs/search?ei=UTF-8&amp;p={searchTerms}", "home": "https://search.yahoo.com" }
    ]

    signal chooseAccount()

    // Used for testing. There is a bug that currently prevents non visual Qt objects
    // to be introspectable from AP which makes directly accessing the settings object
    // not possible https://bugs.launchpad.net/autopilot-qt/+bug/1273956
    property alias generatedUrlPatterns: urlPatternSettings.generatedUrlPatterns

    currentWebcontext: currentWebview ? currentWebview.context : null

    actions: [
        Actions.Back {
            enabled: webapp.backForwardButtonsVisible &&
                     containerWebView.currentWebview &&
                     containerWebView.currentWebview.canGoBack
            onTriggered: {
                if (containerWebView.currentWebview.loading) {
                    containerWebView.currentWebview.stop()
                }
                containerWebView.currentWebview.goBack()
            }
        },
        Actions.Forward {
            enabled: webapp.backForwardButtonsVisible &&
                     containerWebView.currentWebview &&
                     containerWebView.currentWebview.canGoForward
            onTriggered: {
                if (containerWebView.currentWebview.loading) {
                    containerWebView.currentWebview.stop()
                }
                containerWebView.currentWebview.goForward()
            }
        },
        Actions.Reload {
            onTriggered: containerWebView.currentWebview.reload()
        }
    ]

    focus: true

    OrientationSensor {
        id: orientationSensor

        readonly property int orientation: {
            if (reading) {
                switch (reading.orientation) {
                    case 1:
                    case 2:
                        if (Screen.nativeOrientation == Qt.LandscapeOrientation
                            || Screen.nativeOrientation == Qt.InvertedLandscapeOrientation) {
                            return Qt.LandscapeOrientation
                        } else {
                            return Qt.PortraitOrientation
                        }
                        break
                    case 3:
                    case 4:
                        if (Screen.nativeOrientation == Qt.LandscapeOrientation
                            || Screen.nativeOrientation == Qt.InvertedLandscapeOrientation) {
                            return Qt.PortraitOrientation
                        } else {
                            return Qt.LandscapeOrientation
                        }
                        break
                    default:
                        return orientation
                }
            } else {
                return Qt.PortraitOrientation
            }
        }

        active: window.visibility == Window.FullScreen
    }

    Settings {
        id: urlPatternSettings
        property string generatedUrlPatterns
    }

    function addGeneratedUrlPattern(urlPattern) {
        if (urlPattern.trim().length === 0) {
            return;
        }

        var patterns = []
        if (urlPatternSettings.generatedUrlPatterns
                && urlPatternSettings.generatedUrlPatterns.trim().length !== 0) {
            try {
                patterns = JSON.parse(urlPatternSettings.generatedUrlPatterns)
            } catch(e) {
                console.error("Invalid JSON content found in url patterns file")
            }
            if (! (patterns instanceof Array)) {
                console.error("Invalid JSON content type found in url patterns file (not an array)")
                patterns = []
            }
        }
        if (patterns.indexOf(urlPattern) < 0) {
            patterns.push(urlPattern)

            urlPatternSettings.generatedUrlPatterns = JSON.stringify(patterns)
        }
    }

    function mergeUrlPatternSets(p1, p2) {
        if ( ! (p1 instanceof Array)) {
            return (p2 instanceof Array) ? p2 : []
        }
        if ( ! (p2 instanceof Array)) {
            return (p1 instanceof Array) ? p1 : []
        }
        var p1hash = {}
        var result = []
        for (var i1 in p1) {
            p1hash[p1[i1]] = 1
            result.push(p1[i1])
        }
        for (var i2 in p2) {
            if (! (p2[i2] in p1hash)) {
                result.push(p2[i2])
            }
        }
        return result
    }

    function showWebappSettings()
    {
       webappSettingsViewLoader.active = true;
    }

    function showDownloadsPage() {
        downloadsViewLoader.active = true
        return downloadsViewLoader.item
    }

    function startDownload(download) {

        var downloadIdDataBase = Common.ActiveDownloadsSingleton.downloadIdPrefixOfCurrentSession.concat(download.id)

        // check if the ID has already been added
        if ( Common.ActiveDownloadsSingleton.currentDownloads[downloadIdDataBase] === download )
        {
           console.log("the download id " + downloadIdDataBase + " has already been added.")
           return
        }

        console.log("adding download with id " + downloadIdDataBase)
        Common.ActiveDownloadsSingleton.currentDownloads[downloadIdDataBase] = download
        DownloadsModel.add(downloadIdDataBase, download.url, download.path, download.mimeType, false)

        addNewDownload(download)

        if (webapp.chromeless) {
            showDownloadsDialog(anchorItem)
        } else {
            showDownloadsDialog()
        }
    }

    function setDownloadComplete(download) {

        var downloadIdDataBase = Common.ActiveDownloadsSingleton.downloadIdPrefixOfCurrentSession.concat(download.id)

        if ( Common.ActiveDownloadsSingleton.currentDownloads[downloadIdDataBase] !== download )
        {
            console.log("the download id " + downloadIdDataBase + " is not in the current downloads.")
            return
        }

        console.log("download with id " + downloadIdDataBase + " is complete.")

        DownloadsModel.setComplete(downloadIdDataBase, true)

        if ((download.state === WebEngineDownloadItem.DownloadCancelled) || (download.state === WebEngineDownloadItem.DownloadInterrupted))
        {
          DownloadsModel.setError(downloadIdDataBase, download.interruptReasonString)
        }

        if (!currentDownloadsDialog) {
            if (!webapp.chromeless) {
                chrome.downloadNotify = true

                if (!chrome.navigationButtonsVisible) {
                    showDownloadsDialog()
                }
            } else {
                showDownloadsDialog(anchorItem)
            }
        }
    }

    function showDownloadsDialog(caller) {
        if (!currentDownloadsDialog) {
            if (!webapp.chromeless) {
                chrome.downloadNotify = false
                if (caller === undefined) caller = chrome.downloadsButtonPlaceHolder
            } else {
                if (caller === undefined) caller = webapp
            }
            var properties = {"downloadsList": recentDownloads}  
            currentDownloadsDialog = PopupUtils.open(Qt.resolvedUrl("../DownloadsDialog.qml"),
                                                               caller, properties)
        }
    }

    function addNewDownload(download) {
        recentDownloads.unshift(download)
        if (!webapp.chromeless) {
            chrome.showDownloadButton = true
        }
        if (currentDownloadsDialog) {
            currentDownloadsDialog.downloadsList = recentDownloads
        }
    }

    function findFromArray(_arr, _itemProp, _itemValue) {
        if (_itemProp) {
            return _arr.find(item => item[_itemProp] == _itemValue)
        } else {
            return _arr.find(item => item == _itemValue)
        }
    }

    function countFromArray(_arr, _itemProp, _itemValue) {
        let _counter = 0;
        for (let i = 0; i < _arr.length; i++) {
            if (_itemProp) {
                if (_arr[i][_itemProp] == _itemValue) {
                    _counter++;
                }
            } else {
                if (_arr[i] == _itemValue) {
                    _counter++;
                }
            }
        }
        return _counter
    }

    function showTooltip(customText, position, customTimeout) {
        globalTooltip.display(customText, position, customTimeout)
    }

    function focusFindField() {
        if (findLoader.item) {
            findLoader.item.focusField()
        }
    }

    function addNewCustomURLAction(_url) {
        let _addDialog = addEditCustomURLActionComponent.createObject(QQC2.Overlay.overlay, { "customUrl": _url })
        _addDialog.add.connect(function(customUrl, customURLName, customURLIcon) {
                customURLActionsItem.addToCustomURLActions(customUrl, customURLName, customURLIcon)
            }
        )
        _addDialog.edit.connect(function(customURLIndex, customUrl, customURLName, customURLIcon) {
                customURLActionsItem.editCustomURLAction(customURLIndex, customUrl, customURLName, customURLIcon)
            }
        )
        if (webapp.wide) {
            _addDialog.openNormal();
        } else {
            _addDialog.openBottom();
        }
    }

    function openSearchInOverlay() {
        containerWebView.openOverlayForUrl(webapp.searchPageUrl, true)
    }

    function goHome() {
        actionsFactory.navigateToUrl(homeURL)
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

    Connections {
        target: currentDownloadsDialog
        onShowDownloadsPage: showDownloadsPage()
    }

    /* Only used for anchoring the downloads dialog to the top when chromeless */
    Item {
        id: anchorItem
        anchors {
            top: parent.top
            right: parent.right
        }
        height: units.gu(2)
        width: height
    }

    Item {
        id: hoverShowHeader

        z: 1000
        visible: chrome.floating && chrome.state == "hidden"
        height: units.gu(2)
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        HoverHandler {
            id: hoverHander

            onHoveredChanged: {
                if (hovered) {
                    showHeaderOnHoverTimer.restart()
                } else {
                    showHeaderOnHoverTimer.stop()
                }
            }
        }

        Timer {
            id: showHeaderOnHoverTimer
            running: false
            interval: 200
            onTriggered: chrome.state = "shown"
        }
    }

    Item {
        id: webviewContainer

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: findLoader.top
        }

        WebappContainerWebview {
            id: containerWebView
            objectName: "webview"

            readonly property real contentHeightThreshold: chrome.height

            states: [
                State {
                    name: "chromeAutoHide"
                    PropertyChanges {
                        target: containerWebView
                        height: parent.height
                    }
                }
                , State {
                    name: "chromeFixed"
                    AnchorChanges {
                        target: containerWebView
                        anchors.bottom: parent.bottom
                    }
                }
                , State {
                    name: "chromeFloating"
                    AnchorChanges {
                        target: containerWebView
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                    }
                }
            ]

            wide: webapp.wide
            chromeItem: chrome
            overlayViewsParent: overlayParent
            anchors {
                left: parent.left
                right: parent.right
                top: chrome.bottom
            }
            developerExtrasEnabled: webapp.developerExtrasEnabled

            focus: true

            function changeState() {
                if (chrome.floating && webapp.currentWebview && webapp.currentWebview.url != "") {
                    state = "chromeFloating"
                } else if (chrome.autoHide && webapp.currentWebview && webapp.currentWebview.contentHeight > webapp.currentWebview.height + contentHeightThreshold) {
                    state = "chromeAutoHide"
                } else if (!chrome.autoHide || (webapp.currentWebview && webapp.currentWebview.url == "")
                                || (chrome.autoHide && webapp.currentWebview && webapp.currentWebview.contentHeight <= webapp.currentWebview.height + contentHeightThreshold)) {
                    state = "chromeFixed"
                }
            }

            Connections {
                target: chrome

                onAutoHideChanged: containerWebView.changeState()
                onStateChanged: containerWebView.changeState()
                onFloatingChanged: containerWebView.changeState()
            }

            Connections {
                target: webapp.currentWebview
                onLoadingChanged: containerWebView.changeState()
            }

            onThemeColorMetaInformationDetected: {
                var color = webappContainerHelper.rgbColorFromCSSColor(theme_color)
                if (!webapp.chromeless && color.length) {
                    chrome.backgroundColor = theme_color
                    chrome.updateChromeElementsColor(
                            ColorUtils.getMostConstrastedColor(
                                color,
                                Qt.darker(theme_color, themeColorTextContrastFactor),
                                Qt.lighter(theme_color, themeColorTextContrastFactor))
                            )
                }
            }
            onSamlRequestUrlPatternReceived: {
                addGeneratedUrlPattern(urlPattern)
            }
            webappUrlPatterns: mergeUrlPatternSets(urlPatternSettings.generatedUrlPatterns,
                                   webapp.webappUrlPatterns)

            /**
             * Use the --webapp parameter value w/ precedence, but also take into account
             * the fact that a webapp 'name' can come from a webapp-properties.json file w/o
             * being explictly defined here.
             */
            webappName: webapp.webappName

            Loader {
                anchors {
                    fill: containerWebView
                    topMargin: (!webapp.chromeless && chrome.state == "shown")
                               ? chrome.height
                               : 0
                }
                active: containerWebView.currentWebview &&
                        (webProcessMonitor.crashed || (webProcessMonitor.killed && !containerWebView.currentWebview.loading))
                sourceComponent: SadPage {
                    webview: containerWebView.currentWebview
                    objectName: "mainWebviewSadPage"
                }
                Common.WebProcessMonitor {
                    id: webProcessMonitor
                    webview: containerWebView.currentWebview
                }
                asynchronous: true
            }
        }

        Loader {
            anchors {
                fill: containerWebView
            }
            sourceComponent: Common.ErrorSheet {
                visible: containerWebView.currentWebview && ! containerWebView.currentWebview.loading && containerWebView.currentWebview.lastLoadFailed
                url: containerWebView.currentWebview ? containerWebView.currentWebview.url : ""
                errorString: containerWebView.currentWebview ? containerWebView.currentWebview.lastLoadRequestErrorString : ""
                errorDomain: containerWebView.currentWebview ? containerWebView.currentWebview.lastLoadRequestErrorDomain : -1
                canGoBack: containerWebView.currentWebview && containerWebView.currentWebview.canGoBack
                onBackToSafetyClicked: containerWebView.currentWebview.goBack()
                onRefreshClicked: containerWebView.currentWebview.reload()
            }
            asynchronous: true
        }

        Chrome {
            id: chrome

            // If the chrome is actually hidden since there are cases when it's not
            // i.e. Web content spans the full viewport
            readonly property bool actualAutoHide: containerWebView.state == "chromeAutoHide"

            webview: webapp.currentWebview
            navigationButtonsVisible: webapp.backForwardButtonsVisible
            accountSwitcher: webapp.accountSwitcher

            anchors {
                left: parent.left
                right: parent.right
            }
            scrollTracker: containerWebView.scrollTracker
            height: units.gu(6)
            availableHeight: containerWebView.height

            wide: webapp.wide
            autoHide: settings.headerHide == 1 && !floating
            floating: webapp.isFullScreen || settings.headerHide >= 2
            alwaysHidden: settings.headerHide == 3
            timesOut: floating

            // Don't hide chrome in certain situations
            holdTimeout: chrome.navHistoryOpen || webapp.currentDownloadsDialog

            onChooseAccount: webapp.chooseAccount()
            onToggleDownloads: {
                webapp.showDownloadsDialog()
            }
        }

/*
        Binding {
            when: webapp.currentWebview && !webapp.chromeless
            target: webapp.currentWebview ? webapp.currentWebview.locationBarController : null
            property: 'height'
            value: webapp.currentWebview.visible ? chromeLoader.item.height : 0
        }
*/

        Loader {
            id: contentExportLoader
            source: "../ContentExportDialog.qml"
            asynchronous: true
        }

        Connections {
            target: contentExportLoader.item

            onPreview: {
                downloadsViewLoader.active = false
                webapp.currentWebview.url = url;
            }
        }

       Connections {
            target: webapp.currentWebview
            enabled: !webapp.chromeless

            onIsFullScreenChanged: {
                if (webapp.currentWebview.isFullScreen) {
                    chrome.state = "hidden";
                } else {
                    chrome.state = "shown";
                }
                if (!webapp.window.manualFullscreen) {
                    webapp.window.setFullscreen(target.isFullScreen)
                }

                webapp.findInPageMode = false
            }
       }

       Connections {

           target: webapp.currentWebview ? webapp.currentWebview.context : null

           onDownloadRequested: {

               console.log("a download was requested with path %1".arg(download.path))

               download.accept();
               webapp.startDownload(download);
           }

           onDownloadFinished: {

               console.log("a download was finished with path %1.".arg(download.path))
               webapp.setDownloadComplete(download)
           }
       }

       Connections {
           target: settings
           onZoomFactorChanged: DomainSettingsModel.defaultZoomFactor = settings.zoomFactor
           onDomainWhiteListModeChanged: DomainPermissionsModel.whiteListMode = settings.domainWhiteListMode
       }

        Common.ChromeController {
            webview: webapp.currentWebview
            forceHide: webapp.chromeless
        //    defaultMode: webapp.hasTouchScreen
        //                     ? Oxide.LocationBarController.ModeAuto
        //                     : Oxide.LocationBarController.ModeShown
        }
    }

    Sapot.FindInPageBarItem {
        id: findLoader

        findInPageMargin: webapp.findInPageMargin
        shortcutFindNextText: shortcutFindNext.nativeText
        shortcutFindPreviousText: shortcutFindPrevious.nativeText
        wide: webapp.wide
        findController: webapp.currentWebview ? webapp.currentWebview.findController : null
        onHidden: webapp.findInPageMode = false

        onVisibleChanged: if (!visible) containerWebView.forceActiveFocus()
    }

    // Pages background
    Rectangle {
        z: webappSettingsViewLoader.z - 1
        anchors.fill: parent
        color: "black"
        visible: opacity > 0
        opacity: webappSettingsViewLoader.active || downloadsViewLoader.active ? 0.7 : 0
        Behavior on opacity { LomiriNumberAnimation {} }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (downloadsViewLoader.active) {
                    downloadsViewLoader.active = false
                }
                if (webappSettingsViewLoader.active) {
                    webappSettingsViewLoader.active = false
                }
            }
        }
    }


    Loader {
        id: webappSettingsViewLoader

        z: 1000
        readonly property real maxWidth: units.gu(60)
        readonly property real maxHeight: units.gu(90)
        readonly property real sideMargin: webapp.width > maxWidth + units.gu(20) ? (webapp.width - maxWidth) / 2 : 0
        readonly property real topMargin: webapp.height > maxHeight && sideMargin > 0 ? units.gu(5) : 0

        anchors {
            fill: parent
            leftMargin: sideMargin
            rightMargin: sideMargin
            topMargin: topMargin
        }
        active: false
        asynchronous: false
        Component.onCompleted: {
            setSource("WebappSettingsPage.qml", {
                          "focus": true,
                          "settingsObject": settings
                      })
        }

        Connections {
            target: webappSettingsViewLoader.item
            onClearCache: {

                // clear http cache
                webapp.currentWebview.profile.clearHttpCache();
                SharedWebContext.sharedIncognitoContext.clearHttpCache();

                var cacheLocationUrl = Qt.resolvedUrl(cacheLocation);
                var dataLocationUrl = Qt.resolvedUrl(webapp.dataPath);

                // clear favicons
                FileOperations.removeDirRecursively(cacheLocationUrl + "/favicons");

                // remove captures
                FileOperations.removeDirRecursively(cacheLocationUrl + "/captures");

                // application cache
                FileOperations.removeDirRecursively(dataLocationUrl + "/Application Cache");

                // File System
                FileOperations.removeDirRecursively(dataLocationUrl + "/File System");

                // Local Storage
                FileOperations.removeDirRecursively(dataLocationUrl + "/Local Storage");

                // Service WorkerScript
                FileOperations.removeDirRecursively(dataLocationUrl + "/Service Worker")

                // visited Links
                FileOperations.remove(dataLocationUrl + "/Visited Links");
            }
            onClearAllCookies: {
                BrowserUtils.deleteAllCookiesOfProfile(webapp.currentWebview.profile);
                BrowserUtils.deleteAllCookiesOfProfile(SharedWebContext.sharedIncognitoContext);
            }
            onDone: webappSettingsViewLoader.active = false
            onShowDownloadsPage: webapp.showDownloadsPage()
        }
    }

    Loader {
        id: downloadsViewLoader

        z: 1000
        anchors {
            fill: parent
            leftMargin: webappSettingsViewLoader.sideMargin
            rightMargin: webappSettingsViewLoader.sideMargin
            topMargin: webappSettingsViewLoader.topMargin
        }

        active: false
        asynchronous: true
        Component.onCompleted: {
            setSource("../DownloadsPage.qml", {
                          "incognito": false,
                          "focus": true,
                          "subtitle": webapp.dataPath.replace('/home/phablet', '~')
            })
        }

        Connections {
            target: downloadsViewLoader.item
            onDone: downloadsViewLoader.active = false
        }
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
        enabled: webapp.currentWebview ? webapp.currentWebview.canGoForward
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
        enabled: webapp.currentWebview ? webapp.currentWebview.canGoBack
                                        : false
        anchors {
            left: parent.left
            leftMargin: units.gu(3)
            verticalCenter: parent.verticalCenter
        }
    }

    RowLayout {
        id: bottomGestures

        property real sideSwipeAreaWidth: webapp.currentWebview && !webapp.currentWebview.isFullScreen ?
                                                        webapp.width * (webapp.width > webapp.height ? 0.15 : 0.30)
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
                availableHeight: containerWebView.height
                availableWidth: containerWebView.width
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
                    bottomMargin: (((chrome.state == "shown" || chrome.timesOut))
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

                enabled: webapp.settings.webviewHorizontalSwipe && webapp.currentWebview && (Screen.orientation == Screen.primaryOrientation)
                rightSwipeHoldEnabled: webapp.currentWebview ? webapp.currentWebview.canGoBack
                                                          : false
                leftSwipeHoldEnabled: webapp.currentWebview ? webapp.currentWebview.canGoForward
                                                         : false
                leftSwipeActionEnabled: goForwardIcon.enabled
                rightSwipeActionEnabled: goBackIcon.enabled
                onRightSwipe:  shortcutWebviewBack.activated()
                onLeftSwipe:  shortcutWebviewForward.activated()
                onLeftSwipeHeld: chrome.showForwardNavHistory(true, navHistoryMargin)
                onRightSwipeHeld: chrome.showBackNavHistory(true, navHistoryMargin)
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

                enabled: webapp.currentWebview && (Screen.orientation == Screen.primaryOrientation)

                onDraggingChanged: {
                    if (!dragging && towardsDirection) {
                        if (webapp.currentWebview && webapp.currentWebview.isFullScreen) {
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
                availableHeight: containerWebView.height
                availableWidth: containerWebView.width
                implicitHeight: units.gu(webapp.settings.bottomGesturesAreaHeight)
            }
        }
    }

    Item {
        id: overlayParent
        z: 5
        anchors.fill: parent
    }

    Sapot.ActionsFactory {
        id: actionsFactory

        webview: webapp.currentWebview

        onFindInPage: shortcutFind.activated()
    }

    Item {
        id: customURLActionsItem

        function addToCustomURLActions(_url, _name, _icon) {
            let _arrNewValues = webapp.settings.customURLActions.slice()
            _arrNewValues.push({ "url": _url, "name": _name, "icon": _icon })
            webapp.settings.customURLActions = _arrNewValues
        }

        function editCustomURLAction(_index, _newUrl, _newName, _newIcon) {
            let _tempArr = webapp.settings.customURLActions.slice()
            let _itemData = _tempArr[_index]
            let _oldName = ""
            if (_itemData) {
                _oldName = _itemData.name
                _itemData.url = _newUrl
                _itemData.name = _newName
                _itemData.icon = _newIcon
                _tempArr[_index] = _itemData
                webapp.settings.customURLActions = _tempArr.slice()
                editCustomUrlActionInQuickActions(_oldName, _newName)
            }
        }

        function deleteFromCustomURLActions(_itemName) {
            let _arrNewValues = webapp.settings.customURLActions.slice()
            _arrNewValues.splice(_arrNewValues.indexOf(findItemByName(_itemName)), 1)
            webapp.settings.customURLActions = _arrNewValues
            deleteCustomUrlActionFromQuickActions(_itemName)
        }

        function findItemByName(_itemName) {
            return webapp.settings.customURLActions.find(item => item.name == _itemName)
        }

        function editCustomUrlActionInQuickActions(_itemName, _itemNewName) {
            let _arrValues = webapp.settings.webviewQuickActions.slice()
            let _leftAction = webapp.findFromArray(_arrValues[0], "id", "customUrl_" + _itemName)
            if (_leftAction) {
                let _index = _arrValues[0].indexOf(_leftAction)
                _leftAction.id = "customUrl_" + _itemNewName
                _arrValues[0][_index] = _leftAction
            }
            let _rightAction = webapp.findFromArray(_arrValues[1], "id", "customUrl_" + _itemName)
            if (_rightAction) {
                let _index = _arrValues[1].indexOf(_rightAction)
                _rightAction.id = "customUrl_" + _itemNewName
                _arrValues[1][_index] = _rightAction
            }
            webapp.settings.webviewQuickActions = _arrValues
        }

        function deleteCustomUrlActionFromQuickActions(_itemName) {
            let _arrValues = webapp.settings.webviewQuickActions.slice()
            let _leftAction = webapp.findFromArray(_arrValues[0], "id", "customUrl_" + _itemName)
            if (_leftAction) {
                let _index = _arrValues[0].indexOf(_leftAction)
                _arrValues[0].splice(_index, 1)
            }
            let _rightAction = webapp.findFromArray(_arrValues[1], "id", "customUrl_" + _itemName)
            if (_rightAction) {
                let _index = _arrValues[1].indexOf(_rightAction)
                _arrValues[1].splice(_index, 1)
            }
            webapp.settings.webviewQuickActions = _arrValues
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
        enabled: webapp.currentWebview
        onActivated: {
            if (webapp.currentWebview) {
                if (webapp.findInPageMode) {
                    webapp.focusFindField()
                } else {
                    webapp.findInPageMode = true
                }
            }
        }
    }

    // Ctrl+G: Find next
    Shortcut {
        id: shortcutFindNext

        sequence: "Ctrl+G"
        enabled: webapp.currentWebview && webapp.findInPageMode
        onActivated: currentWebview.findController.next()
    }

    // Ctrl+Shift+G: Find previous
    Shortcut {
        id: shortcutFindPrevious

        sequence: "Ctrl+Shift+G"
        enabled: webapp.currentWebview && webapp.findInPageMode
        onActivated: currentWebview.findController.previous()
    }

    // F3: Find next
    Shortcut {
        sequence: StandardKey.FindNext
        enabled: webapp.currentWebview && webapp.findInPageMode
        onActivated: shortcutFindNext.activated()
    }

    // Shift+F3: Find previous
    Shortcut {
        sequence: StandardKey.FindPrevious
        enabled: webapp.currentWebview && webapp.findInPageMode
        onActivated: shortcutFindPrevious.activated()
    }

    Sapot.GlobalTooltip {
        id: globalTooltip
    }

    Sapot.KeyboardRectangle {
        id: keyboardRec
    }

    Component {
        id: addEditCustomURLActionComponent

        Sapot.AddEditCustomURLAction {}
    }
}
