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
import webbrowsercommon.private 0.1
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

    property bool forceDesktopSite: false
    property bool forceMobileSite: false

    signal openUrlExternallyRequested(string url)


    onForceDesktopSiteChanged: if (webapp.settings.autoDeskMobSwitchReload) reload()
    onForceMobileSiteChanged: if (webapp.settings.autoDeskMobSwitchReload) reload()
    onWideChanged: {
        if (webapp.settings.autoDeskMobSwitch && webapp.settings.autoDeskMobSwitchReload) {
            if (context.__ua.calcScreenSize() == "large") {
                reload()
            }
        }
    }

    onShareLinkRequested: internal.shareLink(linkUrl, title)
    onShareTextRequested: internal.shareText(text)

    contentHandlerLoaderObj: contentHandlerLoader

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

    function shareCurrentLink() {
        internal.shareLink(url, title)
    }

    function copyCurrentLink() {
        Clipboard.push(["text/plain", url.toString()])
        webapp.showTooltip(i18n.tr("Link url copied"))
    }

    function navigationRequestedDelegate(request) {

        var url = request.url.toString();
        var isMainFrame = request.isMainFrame;
        var requestDomain = UrlUtils.schemeIs(url, "file") ? "scheme:file" : UrlUtils.extractHost(url);

        // handle user agents
        if (isMainFrame)
        {
            let _appForceDesktop = webapp.settings ? webapp.settings.setDesktopMode :  false
            let _appForceMobile = webapp.settings ? webapp.settings.forceMobileSite : false
            let _tabForceDesktop = webappWebview.forceDesktopSite
            let _tabForceMobile = webappWebview.forceMobileSite
            let _forceDesktopUA = false
            let _forceMobileUA = false
            let _screenSize = webappWebview.context.__ua.calcScreenSize()
            let _newUserAgentId = 0
            let _newCustomUserAgent = ""

            if ( _screenSize == "small") {
                // Small screeens use mobile UA by default so only check when desktop UA is forced
                _forceDesktopUA = ((_appForceDesktop && !_tabForceMobile) || (!_appForceDesktop && _tabForceDesktop))
            } else {
                // Large screeens use desktop UA by default so only check when mobile UA is forced
                if (webapp.settings.autoDeskMobSwitch) {
                    _forceMobileUA = ((webapp.wide && _appForceMobile && !_tabForceDesktop)
                                            || (webapp.wide && !_appForceMobile && _tabForceMobile)
                                            || (!webapp.wide && !_tabForceDesktop))
                } else {
                    _forceMobileUA = ((_appForceMobile && !_tabForceDesktop) || (!_appForceMobile && _tabForceMobile))
                }
            }

            _newUserAgentId = (UserAgentsModel.count > 0) ? DomainSettingsModel.getUserAgentId(requestDomain) : 0;

            // change of the custom user agent
            if (_newUserAgentId !== webappWebview.context.userAgentId) {
                webappWebview.context.userAgentId = _newUserAgentId;
                webappWebview.context.userAgent = (_newUserAgentId > 0) ? UserAgentsModel.getUserAgentString(_newUserAgentId)
                                                                 : localUserAgentOverride ? localUserAgentOverride : webappWebview.context.defaultUserAgent;

                // for some reason when letting through the request, another navigation request will take us back to the
                // to the previous page. Therefore we block it first and navigate to the new url with the correct user agent.
                request.action = WebEngineNavigationRequest.IgnoreRequest;
                webappWebview.url = url;
                return;
            } else {
                if ( _screenSize == "small") {
                    webappWebview.context.__ua.setDesktopMode(_forceDesktopUA);
                } else {
                    webappWebview.context.__ua.forceMobileSite(_forceMobileUA);
                }
                console.log("user agent: " + webappWebview.context.httpUserAgent);
            }
        }
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
