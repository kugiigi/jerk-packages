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
import Lomiri.Components.Popups 1.3
import QtWebEngine 1.7
import Morph.Web 0.1
import webbrowsercommon.private 0.1
import ".."

WebappWebview {
    id: webview

    // XXX: Ideally, we would use the Window.window
    // attached property, but it is new in Qt 5.7.
    property Window window

    property bool developerExtrasEnabled: false
    property string webappName: ""
    property string localUserAgentOverride: ""
    property var webappUrlPatterns: null
    property string popupRedirectionUrlPrefixPattern: ""
    property var dataPath
    property var popupController
    property var overlayViewsParent: webview.parent
    property var mediaAccessDialogComponent
    property bool openExternalUrlInOverlay: false
    property bool popupBlockerEnabled: true

    // Mostly used for testing & avoid external urls to
    //  "leak" in the default browser. External URLs corresponds
    //  to URLs that are not included in the set defined by the url patterns
    //  (if any) or navigations resulting in new windows being created.
    property bool blockOpenExternalUrls: false

    signal samlRequestUrlPatternReceived(string urlPattern)
    signal themeColorMetaInformationDetected(string theme_color)

    // Those signals are used for testing purposes to externally
    //  track down the various internal logic & steps of a popup lifecycle.
    signal openExternalUrlTriggered(string url)
    signal gotRedirectionUrl(string url)
    property bool runningLocalApplication: false

/*    onLoadEvent: {
        var url = event.url.toString()
        if (event.type === Oxide.LoadEvent.TypeRedirected
                && url.indexOf("SAMLRequest") > 0) {
            handleSamlRequestNavigation(url)
        }
    }
*/
    function openOverlayForUrl(overlayUrl) {
        if (popupController) {
            popupController.createPopupViewForUrl(
                        overlayViewsParent,
                        overlayUrl,
                        true,
                        context)
        }
    }

    focus: true

    currentWebview: webview

    context: WebContext {
        dataPath: webview.dataPath
        userAgent: localUserAgentOverride ? localUserAgentOverride : defaultUserAgent

        //popupBlockerEnabled: webview.popupBlockerEnabled

        userScripts: [
            WebEngineScript {
                name: "oxide://webapp-specific-page-metadata-collector/"
                sourceUrl: Qt.resolvedUrl("webapp-specific-page-metadata-collector.js")
                runOnSubframes: true
            }
        ]
    }

/*    Component.onCompleted: webappSpecificMessageHandler.createObject(
                               webview,
                               {
                                   msgId: "webapp-specific-page-metadata-detected",
                                   contexts: ["oxide://webapp-specific-page-metadata-collector/"],
                                   callback: function(msg, frame) {
                                       handlePageMetadata(msg.payload)
                                   }
                               });
*/
//    Component {
//        id: webappSpecificMessageHandler
//        Oxide.ScriptMessageHandler { }
//    }

    onOpenUrlExternallyRequested: openUrlExternally(url, false)

    //preferences.allowFileAccessFromFileUrls: runningLocalApplication
    //preferences.allowUniversalAccessFromFileUrls: runningLocalApplication
    //preferences.localStorageEnabled: true
    //preferences.appCacheEnabled: true

    onNewViewRequested: {
      
      if(request.userInitiated && shouldAllowNavigationTo(request.requestedUrl.toString()))
      {
        popupController.createPopupViewForUrl(overlayViewsParent,request.requestedUrl,true,context)
      }
      else
      {
        openUrlExternally(request.requestedUrl, request.userInitiated)
      }
    }
/*
    Connections {
        target: webview.visible ? webview : null

        /**
         * We are only connecting to the mediaAccessPermission signal if we are
         * the only webview currently visible (no overlay present). In the case of an overlay
         * and the absence of a signal handler in this main view, oxide's default behavior
         * is triggered and the request is denied.
         *
         * See the browser's webbrowser/Browser.qml source for additional comments.
         */
  //      onMediaAccessPermissionRequested: PopupUtils.open(mediaAccessDialogComponent, null, { request: request })
//    }

    StateSaver.properties: "url"
    StateSaver.enabled: !runningLocalApplication

    function handleSAMLRequestPattern(urlPattern) {
        webappUrlPatterns.push(urlPattern)

        samlRequestUrlPatternReceived(urlPattern)
    }

    function isRunningAsANamedWebapp() {
        return webview.webappName && typeof(webview.webappName) === 'string' && webview.webappName.length != 0
    }

    function haveValidUrlPatterns() {
        return webappUrlPatterns && webappUrlPatterns.length !== 0
    }

    function isNewForegroundWebViewDisposition(disposition) {
      //  return disposition === Oxide.NavigationRequest.DispositionNewPopup ||
      //         disposition === Oxide.NavigationRequest.DispositionNewForegroundTab;
    }

    function openUrlExternally(url, isTriggeredByUserNavigation) {
        if (openExternalUrlInOverlay && isTriggeredByUserNavigation) {
            popupController.createPopupViewForUrl(overlayViewsParent, url, true, context)
            return
        } else {
            webview.openExternalUrlTriggered(url)
            if (! webview.blockOpenExternalUrls) {
                Qt.openUrlExternally(url)
            }
        }
    }

    function shouldAllowNavigationTo(url) {
        // Check if URL requested matches against provided patterns
        if (runningLocalApplication && url.startsWith('file://')) {
            return true;
        }

        if (haveValidUrlPatterns()) {
            for (var i = 0; i < webappUrlPatterns.length; ++i) {
                var pattern = webappUrlPatterns[i]
                if (url.match(pattern)) {
                    return true;
                }
            }
        }

        return false;
    }

    function handleSamlRequestNavigation(url) {
        var urlRegExp = new RegExp("https?://([^?/]+)")
        var match = urlRegExp.exec(url)
        var host = match[1]
        var escapeDotsRegExp = new RegExp("\\.", "g")
        var hostPattern = "https?://" + host.replace(escapeDotsRegExp, "\\.") + "/*"

        console.log("SAML request detected. Adding host pattern: " + hostPattern)

        handleSAMLRequestPattern(hostPattern)
    }

    function navigateToUrl(targetUrl) {
        webview.forceActiveFocus()
        webview.url = targetUrl
    }

    function navigateToUrlAsync(targetUrl)
    {
        currentWebview.runJavaScript("window.location.href = '%1';".arg(targetUrl));
    }

    // domains the user has allowed custom protocols for this (incognito) session
    property var domainsWithCustomUrlSchemesAllowed: []

    function allowCustomUrlSchemes(domain, allowPermanently) {
       domainsWithCustomUrlSchemesAllowed.push(domain);

       if (allowPermanently)
       {
            DomainSettingsModel.allowCustomUrlSchemes(domain, true);
       }
    }

    function areCustomUrlSchemesAllowed(domain) {

        for (var i in domainsWithCustomUrlSchemesAllowed) {
            if (domain === domainsWithCustomUrlSchemesAllowed[i]) {
                return true;
            }
        }

        if (DomainSettingsModel.areCustomUrlSchemesAllowed(domain))
        {
            domainsWithCustomUrlSchemesAllowed.push(domain);
            return true;
        }

        return false;
    }

    function navigationRequestedDelegate(request) {

        var url = request.url.toString();
        var isMainFrame = request.isMainFrame;

        // for file urls we set currentDomain to "scheme:file", because there is no host
        var currentDomain = UrlUtils.schemeIs(webview.url, "file") ? "scheme:file" : UrlUtils.extractHost(webview.url);

        // handle custom schemes
        if (UrlUtils.hasCustomScheme(url))
        {
            if (! areCustomUrlSchemesAllowed(currentDomain))
            {
              request.action = WebEngineNavigationRequest.IgnoreRequest;

              var allowCustomSchemesDialog = PopupUtils.open(Qt.resolvedUrl("../AllowCustomSchemesDialog.qml"), webview);
              allowCustomSchemesDialog.url = url;
              allowCustomSchemesDialog.domain = currentDomain;
              allowCustomSchemesDialog.showAllowPermanentlyCheckBox = true;
              allowCustomSchemesDialog.allow.connect(function() {allowCustomUrlSchemes(currentDomain, false);
                                                                 navigateToUrlAsync(url);
                                                                }
                                                    );
              allowCustomSchemesDialog.allowPermanently.connect(function() {allowCustomUrlSchemes(currentDomain, true);
                                                                            navigateToUrlAsync(url);
                                                                           }
                                                               );
            }
            return;
        }

        // handle domain permissions
        var requestDomain = UrlUtils.schemeIs(url, "file") ? "scheme:file" : UrlUtils.extractHost(url);
        var requestDomainWithoutSubdomain = DomainPermissionsModel.getDomainWithoutSubdomain(requestDomain);
        var currentDomainWithoutSubdomain = DomainPermissionsModel.getDomainWithoutSubdomain(UrlUtils.extractHost(webview.url));
        var domainPermission = DomainPermissionsModel.getPermission(requestDomainWithoutSubdomain);

        if (domainPermission !== DomainPermissionsModel.NotSet)
        {
            if (isMainFrame) {
              DomainPermissionsModel.setRequestedByDomain(requestDomainWithoutSubdomain, "", false);
            }
            else if (requestDomainWithoutSubdomain !== currentDomainWithoutSubdomain) {
              DomainPermissionsModel.setRequestedByDomain(requestDomainWithoutSubdomain, currentDomainWithoutSubdomain, false);
            }
        }

        if (domainPermission === DomainPermissionsModel.Blocked)
        {
            if (isMainFrame)
            {
                var alertDialog = PopupUtils.open(Qt.resolvedUrl("../AlertDialog.qml"), browser.currentWebview);
                alertDialog.title = i18n.tr("Blocked domain");
                alertDialog.message = i18n.tr("Blocked navigation request to domain %1.").arg(requestDomainWithoutSubdomain);
            }
            request.action = WebEngineNavigationRequest.IgnoreRequest;
            return;
        }

        if ((domainPermission === DomainPermissionsModel.NotSet) && DomainPermissionsModel.whiteListMode)
        {
            var allowOrBlockDialog = PopupUtils.open(Qt.resolvedUrl("../AllowOrBlockDomainDialog.qml"), currentWebview);
            allowOrBlockDialog.domain = requestDomainWithoutSubdomain;
            if (isMainFrame)
            {
                allowOrBlockDialog.parentDomain = "";
                allowOrBlockDialog.allow.connect(function() {
                    DomainPermissionsModel.setRequestedByDomain(requestDomainWithoutSubdomain, "", false);
                    DomainPermissionsModel.setPermission(requestDomainWithoutSubdomain, DomainPermissionsModel.Whitelisted, false);
                    currentWebview.url = url;
                });
            }
            else
            {
                allowOrBlockDialog.parentDomain = currentDomainWithoutSubdomain;
                allowOrBlockDialog.allow.connect(function() {
                    DomainPermissionsModel.setRequestedByDomain(requestDomainWithoutSubdomain, currentDomainWithoutSubdomain, false);
                    DomainPermissionsModel.setPermission(requestDomainWithoutSubdomain, DomainPermissionsModel.Whitelisted, false);
                    var alertDialog = PopupUtils.open(Qt.resolvedUrl("../AlertDialog.qml"), browser.currentWebview);
                    alertDialog.title = i18n.tr("Whitelisted domain");
                    alertDialog.message = i18n.tr("domain %1 is now whitelisted, please reload the page.").arg(requestDomainWithoutSubdomain);
                });
            }
            allowOrBlockDialog.block.connect(function() {
                DomainPermissionsModel.setRequestedByDomain(requestDomainWithoutSubdomain, isMainFrame ? "" : currentDomainWithoutSubdomain, false);
                DomainPermissionsModel.setPermission(requestDomainWithoutSubdomain, DomainPermissionsModel.Blocked, false);
              });
            request.action = WebEngineNavigationRequest.IgnoreRequest;
            return;
        }

        // handle user agents
        if (isMainFrame)
        {
          var newUserAgentId = (UserAgentsModel.count > 0) ? DomainSettingsModel.getUserAgentId(requestDomain) : 0;

          // change of the custom user agent
          if (newUserAgentId !== webview.context.userAgentId)
          {
            webview.context.userAgentId = newUserAgentId;
            webview.context.userAgent = (newUserAgentId > 0) ? UserAgentsModel.getUserAgentString(newUserAgentId)
                                                             : localUserAgentOverride ? localUserAgentOverride : webview.context.defaultUserAgent;

            // for some reason when letting through the request, another navigation request will take us back to the
            // to the previous page. Therefore we block it first and navigate to the new url with the correct user agent.
            request.action = WebEngineNavigationRequest.IgnoreRequest;
            webview.url = url;
            return;
          }
          else
          {
              console.log("user agent: " + webview.context.httpUserAgent);
          }
        }

        if (runningLocalApplication && !url.startsWith("file://") && !webview.haveValidUrlPatterns) {
            request.action = WebEngineNavigationRequest.IgnoreRequest;
            openUrlExternally(url, true);
            return;
        }

        request.action = WebEngineNavigationRequest.IgnoreRequest
        if (isNewForegroundWebViewDisposition(request.disposition)) {
            var shouldAcceptRequest = popupController.handleNewForegroundNavigationRequest(url, request, true);
            if (shouldAcceptRequest) {
                request.action = WebEngineNavigationRequest.AcceptRequest;
            }
            return;
        }

        // Pass-through if we are not running as a named webapp (--webapp='Gmail')
        // or if we dont have a list of url patterns specified to filter the
        // browsing actions
        if (!webview.haveValidUrlPatterns() && !webview.isRunningAsANamedWebapp()) {
            request.action = WebEngineNavigationRequest.AcceptRequest;
            return;
        }

        // for now (as the old behavior) allow resources to be loaded
        // ToDo: maybe we should only allow resources defined in the URL patterns here
        if (! isMainFrame)
        {
            console.debug('accepted resource request to %1.'.arg(url));
            request.action = WebEngineNavigationRequest.AcceptRequest;
        }

        else if (webview.shouldAllowNavigationTo(url))
        {
            request.action = WebEngineNavigationRequest.AcceptRequest;
        }

        // SAML requests are used for instance by Google Apps for your domain;
        // they are implemented as a HTTP redirect to a URL containing the
        // query parameter called "SAMLRequest".
        // Besides letting the request through, we must also add the SAML
        // domain to the list of the allowed hosts.
      //  if (request.disposition === Oxide.NavigationRequest.DispositionCurrentTab
      //          && url.indexOf("SAMLRequest") > 0) {
      //      handleSamlRequestNavigation(url)
            //request.action = WebEngineNavigationRequest.AcceptRequest

      //  }

      if (request.action === WebEngineNavigationRequest.IgnoreRequest) {

            if (isMainFrame && request.navigationType === WebEngineNavigationRequest.LinkClickedNavigation)
            {
                console.debug('Opening: %1 in the browser window.'.arg(url));
                openUrlExternally(url, true);
            }
            else
            {
                console.debug('ignored request of type %1 of current page to %2.'.arg(request.navigationType).arg(url));
            }
      }
    }

    function handlePageMetadata(metadata) {
        if (metadata.type === 'manifest') {
            var request = new XMLHttpRequest();
            request.onreadystatechange = function() {
                if (request.readyState === XMLHttpRequest.DONE) {
                    try {
                        var manifest = JSON.parse(request.responseText);
                        if (manifest['theme_color']
                                && manifest['theme_color'].length !== 0) {
                            themeColorMetaInformationDetected(manifest['theme_color'])
                        }
                    } catch(e) {}
                }
            }
            request.open("GET", metadata.manifest);
            request.send();
        } else if (metadata.type === 'theme-color') {
            if (metadata['theme_color']
                    && metadata['theme_color'].length !== 0) {
                themeColorMetaInformationDetected(metadata['theme_color'])
            }
        }
    }
}
