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

import QtQuick 2.4
import Lomiri.Components 1.3
import Qt.labs.settings 1.0
import QtWebEngine 1.10
import Morph.Web 0.1
import webcontainer.private 0.1
import webbrowsercommon.private 0.1
import ".."
import "sapot" as Sapot
import QtQuick.Window 2.2
import QtQuick.Controls.Suru 2.2

Sapot.BrowserWindow {
    id: root
    objectName: "webappContainer"

    property bool backForwardButtonsVisible: true
    property bool chromeVisible: true

    property string localCookieStoreDbPath: ""

    property string url: ""
    property url webappIcon: ""
    property string webappName: ""
    property string webappModelSearchPath: ""
    property var webappUrlPatterns
    property var userScripts
    property string accountProvider: ""
    property bool accountSwitcher: false
    property string popupRedirectionUrlPrefixPattern: ""
    property url webviewOverrideFile: ""
    property var __webappCookieStore: null
    property alias webContextSessionCookieMode: webappViewLoader.webContextSessionCookieMode
    property string localUserAgentOverride: ""
    property bool blockOpenExternalUrls: false
    property bool openExternalUrlInOverlay: false
    property string defaultVideoCaptureCameraPosition: ""
    property bool popupBlockerEnabled: true
    property bool localContentCanAccessRemoteUrls: false

    currentWebview: webappViewLoader.item ? webappViewLoader.item.currentWebview : null

    property bool runningLocalApplication: false

    property bool startMaximized: false

    property bool manualFullscreen: false // When user entered fullscreen manually via shortcut or button

    title: getWindowTitle()

    // Used for testing
    signal schemeUriHandleFilterResult(string uri)

    function getWindowTitle() {
        var webappViewTitle =
                webappViewLoader.item
                ? webappViewLoader.item.title : ""
        var name = getWebappName()
        if (typeof(name) === 'string' && name.length !== 0) {
            return name
        } else if (webappViewTitle) {
            // TRANSLATORS: %1 refers to the current page’s title
            return i18n.tr("%1 - Morph Web Browser").arg(webappViewTitle)
        } else {
            return i18n.tr("Morph Web Browser")
        }
    }
    
    function toggleApplicationLevelFullscreen() {
        let notFullscreen = visibility !== Window.FullScreen
        setFullscreen(notFullscreen)
        root.manualFullscreen = notFullscreen
    }

    Component {
        id: webappViewComponent

        WebApp {
            id: browser

            settings: root.settings

            window: root

            url: accountProvider.length !== 0 ? "" : root.url
            homeURL: root.url

            accountSwitcher: root.accountSwitcher

            dataPath: webappDataLocation
            chromeVisible: root.chromeVisible
            backForwardButtonsVisible: root.backForwardButtonsVisible
            developerExtrasEnabled: root.developerExtrasEnabled
            webappModelSearchPath: root.webappModelSearchPath
            webappUrlPatterns: root.webappUrlPatterns
            blockOpenExternalUrls: root.blockOpenExternalUrls
            openExternalUrlInOverlay: root.openExternalUrlInOverlay
            defaultVideoCaptureDevicePosition: root.defaultVideoCaptureCameraPosition ?
                                                   root.defaultVideoCaptureCameraPosition
                                                 : browser.defaultVideoCaptureDevicePosition
            popupBlockerEnabled: root.popupBlockerEnabled
            hasTouchScreen: root.hasTouchScreen

            focus: true

            popupRedirectionUrlPrefixPattern: root.popupRedirectionUrlPrefixPattern

            localUserAgentOverride: getLocalUserAgentOverrideIfAny()

            runningLocalApplication: root.runningLocalApplication
            webviewOverrideFile: root.webviewOverrideFile

            anchors.fill: parent

            onWebappNameChanged: {
                if (root.webappName !== browser.webappName) {
                    root.webappName = browser.webappName;
                    root.title = getWindowTitle();
                }
            }

            onChooseAccount: {
                showAccountsPage()
                onlineAccountsController.showAccountSwitcher()
            }
        }
    }

    function getWebappName() {
        /**
          Any webapp name coming from the command line takes over.
          A webapp can also be defined by a specific drop-in webapp-properties.json
          file that can bundle a few specific 'properties' (as the name implies)
          instead of having them listed in the command line.
          */
        if (webappName)
            return webappName
        return webappModelSearchPath && webappModel.providesSingleInlineWebapp()
            ? webappModel.getSingleInlineWebappName()
            : ""
    }

    function getLocalUserAgentOverrideIfAny() {
        if (localUserAgentOverride.length !== 0)
            return localUserAgentOverride

        var name = getWebappName()
        if (name && webappModel.exists(name))
            return webappModel.userAgentOverrideFor(name)

        return ""
    }

    Sapot.UserAgent02 {
        id: customUserAgent02
    }

    // Because of https://launchpad.net/bugs/1398046, it's important that this
    // is the first child
    Loader {
        id: webappViewLoader
        anchors.fill: parent

        property string webContextSessionCookieMode: ""
        property var webappDataLocation

        focus: true

        onLoaded: {
            // Use our custom UserAgent02
            SharedWebContext.sharedContext.__ua = customUserAgent02
            SharedWebContext.sharedIncognitoContext.__ua = customUserAgent02

            var context = item.currentWebview.context;
            context.offTheRecord = false;
            context.storageName = "Default";
            onlineAccountsController.setupWebcontextForAccount(context);
            item.currentWebview.settings.localContentCanAccessRemoteUrls = localContentCanAccessRemoteUrls;

            loadCustomUserScripts();
            DomainPermissionsModel.databasePath = webappDataLocation + '/domainpermissions.sqlite';
            DomainPermissionsModel.whiteListMode = settings.domainWhiteListMode;
            DomainSettingsModel.databasePath = webappDataLocation + '/domainsettings.sqlite';
            DomainSettingsModel.defaultZoomFactor = settings.zoomFactor;
            DownloadsModel.databasePath = webappDataLocation + "/downloads.sqlite";
            UserAgentsModel.databasePath = DomainSettingsModel.databasePath;

            // create downloads path
            item.currentWebview.profile.downloadPath = webappDataLocation + "/Downloads";
            SharedWebContext.sharedIncognitoContext.downloadPath = webappDataLocation + "/Downloads";
            FileOperations.mkpath(webappDataLocation + "/Downloads");

            // create path for pages printed to PDF
            FileOperations.mkpath(Qt.resolvedUrl(cacheLocation) + "/pdf_tmp");
        }

        function loadCustomUserScripts() {

            var scripts = [];

            var customScripts = root.userScripts;

            if ((typeof customScripts === "undefined") || (customScripts.length === 0))
            {
                return;
            }

            var i;
            for (i = 0; i < customScripts.length; i++)
            {
              var script = Qt.createQmlObject('import QtWebEngine 1.10; WebEngineScript {}', webappViewLoader);
              script.sourceUrl = customScripts[i];
              script.injectionPoint = WebEngineScript.DocumentCreation;
              script.worldId = WebEngineScript.MainWorld;
              script.runOnSubframes = true;
              scripts.push(script);
            }

            // global user scripts
            for (i = 0; i < item.currentWebview.profile.userScripts.length; i++) {
              scripts.push(item.currentWebview.profile.userScripts[i]);
            }

            item.currentWebview.profile.userScripts = scripts;
        }
    }

    property var settings: Settings {
        property bool domainWhiteListMode: false
        property bool autoFitToWidthEnabled: false
        property real zoomFactor: 1.0
        property bool loadImages: true
        property int headerHide: !root.chromeVisible && !root.backForwardButtonsVisible && !root.accountSwitcher ? 3 : 0
        /*
         0 - Disabled
         1 - On scroll down
         2 - Time out (Header shows when using bottom gestures)
         3 - Always hidden
        */
        property bool enableHaptics: true
        property bool appWideScrollPositioner: false
        property int scrollPositionerPosition: Sapot.ScrollPositionerItem.Position.Right
        /*
         * ScrollPositionerItem.Position.Right
         * ScrollPositionerItem.Position.Left
         * ScrollPositionerItem.Position.Middle
        */
        property int scrollPositionerSize: 8 // In Grid Units
        property bool enableWebviewPullDownGestures: false
        property bool physicalForGestures: false // Use physical unit for swipe gestures (in inches)

        property bool hideBottomHint: false
        property var webviewQuickActions: [
            [
                { "id": "openSettings" }
                , { "id": "goHome" }
                , { "id": "webviewReload" }
                , { "id": "webviewForward" }
                , { "id": "webviewBack" }
            ]
            , [
                { "id": "openSettings" }
                , { "id": "goHome" }
                , { "id": "webviewReload" }
                , { "id": "webviewForward" }
                , { "id": "webviewBack" }
            ]
        ]
        property bool webviewHorizontalSwipe: true
        property bool webviewSideSwipe: true
        property bool webviewQuickSideSwipe: false
        property bool webviewEnableQuickActions: true
        property bool webviewQuickActionEnableDelay: false
        property real webviewQuickActionsHeight: 3 // In Inch
        property real bottomGesturesAreaHeight: 2 // In Grid Unit
        property bool restorePreviousURL: false
        property string previousURL: ""
        property int externalUrlHandling: 0
        /*
         0 - Block all
         1 - Open in overlay
         2 - Open externally
         3 - Always ask
        */
        property bool askWhenOpeningLinkOutside: true
        property string searchEngine: "duckduckgo"
        property var customURLActions: []
        property bool incognitoOverlay: true
        property bool setDesktopMode: false
        property bool forceMobileSite: false
        property bool autoDeskMobSwitch: true
        property bool autoDeskMobSwitchReload: true
        property int defaultSearchEngine: 0
        property bool enableFloatingScrollButton: false
        property int floatingScrollButtonSideMargin: 2 // In Grid Units
        property int floatingScrollButtonSize: 6 // In Grid Units
        property bool enableFloatingScrollButtonAsPositioner: false
        property int floatingScrollButtonVerticalMargin: 2 // In Grid Units


        Component.onCompleted: Sapot.Haptics.enabled = Qt.binding( function() { return enableHaptics } )

        function restoreDefaults() {
            domainWhiteListMode = false;
            autoFitToWidthEnabled = false;
            zoomFactor = 1.0;
            loadImages = true;
            headerHide = !root.chromeVisible && !root.backForwardButtonsVisible && !root.accountSwitcher ? 3 : 0;
            enableHaptics = true;
            appWideScrollPositioner = false;
            scrollPositionerPosition = Sapot.ScrollPositionerItem.Position.Right;
            scrollPositionerSize = 8;
            enableWebviewPullDownGestures = false;
            physicalForGestures = false;
            hideBottomHint = false;
            webviewQuickActions = [
                [
                    { "id": "openSettings" }
                    , { "id": "goHome" }
                    , { "id": "webviewReload" }
                    , { "id": "webviewForward" }
                    , { "id": "webviewBack" }
                ]
                , [
                    { "id": "openSettings" }
                    , { "id": "goHome" }
                    , { "id": "webviewReload" }
                    , { "id": "webviewForward" }
                    , { "id": "webviewBack" }
                ]
            ];
            webviewHorizontalSwipe = true;
            webviewSideSwipe = true;
            webviewQuickSideSwipe = false;
            webviewEnableQuickActions = true;
            webviewQuickActionEnableDelay = false;
            webviewQuickActionsHeight = 3; // In Inch
            bottomGesturesAreaHeight = 2; // In Grid Unit
            restorePreviousURL = false;
            externalUrlHandling = 0;
            askWhenOpeningLinkOutside = true;
            restoreDefault_searchEngine();
            customURLActions = [];
            incognitoOverlay = true;
            setDesktopMode = false;
            forceMobileSite = false;
            autoDeskMobSwitch = true;
            autoDeskMobSwitchReload = true;
            defaultSearchEngine = 0;
            enableFloatingScrollButton = false;
            floatingScrollButtonSideMargin = 2;
            floatingScrollButtonSize = 6;
            enableFloatingScrollButtonAsPositioner = false;
            floatingScrollButtonVerticalMargin = 2;
        }

        function restoreDefault_searchEngine() {
            searchEngine = "duckduckgo";
        }

        function resetDomainPermissions() {
            DomainPermissionsModel.deleteAndResetDataBase();
        }

        function resetDomainSettings() {
            DomainSettingsModel.deleteAndResetDataBase();
            // it is a common database with DomainSettingsModel, so it is only for reset here
            UserAgentsModel.deleteAndResetDataBase();
        }

        onSetDesktopModeChanged: if (root.currentWebview && autoDeskMobSwitchReload) root.currentWebview.reload();
        onForceMobileSiteChanged: if (root.currentWebview && autoDeskMobSwitchReload) root.currentWebview.reload();
        onAutoDeskMobSwitchChanged: {
            if (autoDeskMobSwitchReload && root.currentWebview && root.currentWebview.context.__ua.calcScreenSize() == "large") {
                root.currentWebview.reload();
            }
        }
    }

    OnlineAccountsController {
        id: onlineAccountsController
        anchors.fill: parent
        z: -1 // This is needed to have the dialogs shown; see above comment about bug 1398046
        providerId: accountProvider
        applicationId: unversionedAppId
        accountSwitcher: root.accountSwitcher
        webappName: getWebappName()
        webappIcon: root.webappIcon

        onAccountSelected: {
            var newWebappDataLocation = dataLocation + accountDataLocation
            console.log("Loading webview on " + newWebappDataLocation)
            if (newWebappDataLocation === webappViewLoader.webappDataLocation) {
                showWebView()
                return
            }
            webappViewLoader.sourceComponent = null
            webappViewLoader.webappDataLocation = newWebappDataLocation
            // If we need to preserve session cookies, make sure that the
            // mode is "restored" and not "persistent", or the cookies
            // transferred from OA would be lost.
            // We check if the webContextSessionCookieMode is defined and, if so,
            // we override it in the webapp loader.
            if (willMoveCookies && typeof webContextSessionCookieMode === "string") {
                webappViewLoader.webContextSessionCookieMode = "restored"
            }
            webappViewLoader.sourceComponent = webappViewComponent
        }
        onContextReady: startBrowsing()
        onQuitRequested: Qt.quit()
    }

    Component.onCompleted: {
      //  console.info("webapp-container using QtWebEngine %1 (chromium %2)".arg(Oxide.version).arg(Oxide.chromiumVersion))
        i18n.domain = "morph-browser"
        if (forceFullscreen) {
            showFullScreen()
        } else if (startMaximized) {
            showMaximized()
        } else {
            show()
        }
    }

    function showWebView() {
        onlineAccountsController.visible = false
        webappViewLoader.visible = true
    }

    function showAccountsPage() {
        webappViewLoader.visible = false
        onlineAccountsController.visible = true
    }

    function startBrowsing() {
        console.log("Start browsing")
        webappViewLoader.item.webappName = root.webappName

        // As we use StateSaver to restore the URL, we need to check first if
        // it has not been set previously before setting the URL to the default property
        // homepage.
        var webView = webappViewLoader.item.currentWebview

        if (settings.restorePreviousURL && settings.previousURL.trim() !== "") {
            webView.url = settings.previousURL
        } else {
            var current_url = webView.url.toString();
            if (!current_url || current_url.length === 0) {
                webView.url = root.url
            }
        }
        showWebView()
    }

    function makeUrlFromResult(result) {
        var scheme = null
        var hostname = null
        var url = root.currentWebview.url || root.url
        if (result.host
                && result.host.length !== 0) {
            hostname = result.host
        }
        else {
            var matchHostname = url.toString().match(/.*:\/\/([^/]*)\/.*/)
            if (matchHostname.length > 1) {
                hostname = matchHostname[1]
            }
        }

        if (result.scheme
                && result.scheme.length !== 0) {
            scheme = result.scheme
        }
        else {
            var matchScheme = url.toString().match(/(.*):\/\/[^/]*\/.*/)
            if (matchScheme.length > 1) {
                scheme = matchScheme[1]
            }
        }
        return scheme
                + '://'
                + hostname
                + "/"
                + (result.path
                    ? result.path : "")
    }

    /**
     *
     */
    function translateHandlerUri(uri) {
        //
        var scheme = uri.substr(0, uri.indexOf(":"))
        if (scheme.indexOf("http") === 0) {
            schemeUriHandleFilterResult(uri)
            return uri
        }

        var result = webappSchemeFilter.applyFilter(uri)
        var mapped_uri = makeUrlFromResult(result)

        uri = mapped_uri

        // Report the result of the intent uri filtering (if any)
        // Done for testing purposed. It is not possible at this point
        // to have AP call a slot and retrieve its result synchronously.
        schemeUriHandleFilterResult(uri)

        return uri
    }

    function openUrls(urls) {
        // only consider the first one (if multiple)
        if (urls.length === 0 || !root.currentWebview) {
            return;
        }
        var requestedUrl = urls[0].toString();

        if (popupRedirectionUrlPrefixPattern.length !== 0
                && requestedUrl.match(popupRedirectionUrlPrefixPattern)) {
            return;
        }

        requestedUrl = translateHandlerUri(requestedUrl);

        // Add a small guard to prevent browsing to invalid urls
        if (currentWebview
                && currentWebview.shouldAllowNavigationTo
                && !currentWebview.shouldAllowNavigationTo(requestedUrl)) {
            return;
        }

        root.url = requestedUrl
        root.currentWebview.url = requestedUrl
    }

    property var openUrlsHandler: Connections {
        target: UriHandler
        onOpened: root.openUrls(uris)
    }

    // Change theme in real time when set to follow system theme
    // Only works when the app gets unfocused then focused
    // Possibly ideal so the change won't happen while the user is using the app
    property string previousTheme: Theme.name
    Connections {
        target: Qt.application
        onStateChanged: {
            if (previousTheme !== theme.name) {
                root.Suru.theme = Theme.name == "Lomiri.Components.Themes.SuruDark" ? Suru.Dark : Suru.Light
                theme.name = Theme.name
                theme.name = ""
            }
            previousTheme = Theme.name
        }
    }
}
