import QtQuick 2.12
import Lomiri.Components 1.3
import "." as Sapot

Item {
    id: actionsFactory

    property var webview
    property bool isOverlay: false

    readonly property var allActions: [
        { "id": "webviewBack", "title": i18n.tr("Web View Back"), "component": actionWebviewBack }
        , { "id": "webviewForward", "title": i18n.tr("Web View Forward"), "component": actionWebviewForward }
        , { "id": "webviewReload", "title": i18n.tr("Web View Reload"), "component": actionWebviewReload }
        , { "id": "webviewPullDown", "title": i18n.tr("Pull Down/Up Web View"), "component": actionWebviewPullDown }
        , { "id": "openDownloads", "title": i18n.tr("Downloads"), "component": actionOpenDownloads }
        , { "id": "openSettings", "title": i18n.tr("Settings"), "component": actionOpenSettings }
        , { "id": "findInPage", "title": i18n.tr("Find In Page"), "component": actionFindInPage }
        , { "id": "toggleFullscreen", "title": i18n.tr("Toggle Full Screen"), "component": actionFullscreen }
        , { "id": "goHome", "title": i18n.tr("Go Home"), "component": actionGoHome }
        , { "id": "shareLink", "title": i18n.tr("Share link"), "component": actionShareLink }
        , { "id": "copyLink", "title": i18n.tr("Copy link"), "component": actionCopyLink }
        , { "id": "openSearchInOverlay", "title": i18n.tr("Open search page"), "component": actionSearchInOverlay }
        , { "id": "toggleSiteVersion", "title": i18n.tr("Toggle site version"), "component": actionToggleSiteVersion }
        , { "id": "toggleReaderMode", "title": i18n.tr("Toggle Reader mode"), "component": actionToggleReaderMode }
        , { "id": "customUrl", "title": i18n.tr("Custom Url Action"), "component": actionCustomUrlAction }
    ]

    signal findInPage

    function getActionsModel(actionIDsList) {
        let newList = []

        actionIDsList.forEach( action => {
            if (action.id.startsWith("customUrl_")) {
                let _splitValues = action.id.split("_")
                let _customUrlName = _splitValues[1]
                let _customUrlActionItem = webapp.customURLActions.findItemByName(_customUrlName)
                let _newCustomUrlAction = customUrlActionComponent.createObject(actionsFactory, { "actionUrl": _customUrlActionItem.url, "iconName": _customUrlActionItem.icon, "text": _customUrlName })
                newList.push(_newCustomUrlAction)
            } else {
                newList.push(allActions.find(item => item.id == action.id).component)
            }
        });

        return newList
    }

    function navigateToUrl(targetUrl) {
        webview.forceActiveFocus()
        webview.url = targetUrl
    }

    QtObject {
        id: internal
        
        readonly property bool smallDevice: webapp.currentWebview && webapp.currentWebview.context.__ua.calcScreenSize() == "small"
        readonly property bool appForceDesktop: webapp.settings ? webapp.settings.setDesktopMode :  false
        readonly property bool appForceMobile: webapp.settings ? webapp.settings.forceMobileSite : false
        readonly property bool desktopSwitchMode: (smallDevice && !appForceDesktop) || (!smallDevice && appForceMobile)
                                            // Always treat as mobile when auto version is enabled and window is NOT wide
                                            // on a large screen
                                            || (!smallDevice && webapp.settings.autoDeskMobSwitch && !webapp.wide)
    }

    Component {
        id: customUrlActionComponent

        Sapot.BaseAction {
            property url actionUrl

            iconName: "other-actions"
            text: i18n.tr("Custom URL")
            enabled: actionsFactory.webview ? true : false
            onTrigger: actionsFactory.navigateToUrl(actionUrl)
        }
    }

    Sapot.BaseAction {
        id: actionCustomUrlAction

        property url actionUrl

        iconName: "other-actions"
        text: i18n.tr("Custom URL")
        enabled: webview ? true : false
        onTrigger: actionsFactory.navigateToUrl(actionUrl)
    }

    Sapot.BaseAction {
        id: actionGoHome

        iconName: "home"
        text: i18n.tr("Home")
        enabled: webview && webapp.homeURL && !actionsFactory.isOverlay
        onTrigger: actionsFactory.navigateToUrl(webapp.homeURL)
    }

    Sapot.BaseAction {
        id: actionWebviewBack

        iconName: "go-previous"
        text: i18n.tr("Go back")
        enabled: webview && webview.canGoBack
        onTrigger: webview.goBack()
    }

    Sapot.BaseAction {
        id: actionWebviewForward

        iconName: "go-next"
        text: i18n.tr("Go forward")
        enabled: webview && webview.canGoForward
        onTrigger: webview.goForward()
    }

    Sapot.BaseAction {
        id: actionWebviewReload

        iconName: "reload"
        text: i18n.tr("Reload")
        enabled: webview
        onTrigger: {
            if (webview.loading) {
                if (webview) webview.stop()
            }

            webview.reload()
        }
    }

    Sapot.BaseAction {
        id: actionWebviewPullDown

        iconName: webview && webview.webviewPulledDown ? "go-up" : "go-down"
        text: webview && webview.webviewPulledDown ? i18n.tr("Reset web view") : i18n.tr("Pull down web view")
        onTrigger: {
            if (webview.webviewPulledDown) {
                webview.pullUpWebview()
            } else {
                webview.pullDownWebview()
            }
        }
    }

    Sapot.BaseAction {
        id: actionFindInPage

        iconName: "find"
        text: i18n.tr("Find in page")
        enabled: webview
        onTrigger: actionsFactory.findInPage()
    }

    Sapot.BaseAction {
        id: actionFullscreen

        iconName: webapp.isFullScreen ? "view-restore" : "view-fullscreen"
        text: webapp.isFullScreen ? i18n.tr("Exit full screen") : i18n.tr("Go full screen")
        onTrigger: webapp.window.toggleApplicationLevelFullscreen()
    }

    Sapot.BaseAction {
        id: actionOpenDownloads

        iconName: "save-to"
        text: i18n.tr("Downloads")
        onTrigger: webapp.showDownloadsPage()
    }

    Sapot.BaseAction {
        id: actionOpenSettings

        iconName: "settings"
        text: i18n.tr("Settings")
        onTrigger: webapp.showWebappSettings()
    }

    Sapot.BaseAction {
        id: actionShareLink

        iconName: "share"
        text: i18n.tr("Share Link")
        onTrigger: webview.shareCurrentLink()
    }

    Sapot.BaseAction {
        id: actionCopyLink

        iconName: "stock_link"
        text: i18n.tr("Copy Link")
        onTrigger: webview.copyCurrentLink()
    }

    Sapot.BaseAction {
        id: actionSearchInOverlay

        iconName: "search"
        text: i18n.tr("Open Search page")
        onTrigger: webapp.openSearchInOverlay()
    }

    Sapot.BaseAction {
        id: actionToggleSiteVersion

        iconName: internal.desktopSwitchMode && !checked ? "computer-symbolic" : "phone-smartphone-symbolic"
        text: internal.desktopSwitchMode && !checked ? i18n.tr("Desktop site") : i18n.tr("Mobile site")

        onTrigger: {
            if (webview) {
                checked = !checked
                if (internal.desktopSwitchMode) {
                    webview.forceDesktopSite = checked
                } else {
                    webview.forceMobileSite = checked
                }
            }
        }
    }

    Binding {
        target: actionToggleSiteVersion
        property: "checked"
        value: internal.desktopSwitchMode ? webview && webview.forceDesktopSite
                                : webview && webview.forceMobileSite
    }

    Sapot.BaseAction {
        id: actionToggleReaderMode

        enabled: webview && (webview.isReaderable || webview.readerMode)
        iconName: "stock_ebook"
        text: checked ? i18n.tr("Disable Reader mode") : i18n.tr("Reader mode")

        onTrigger: {
            if (webview) {
                webview.toggleReaderMode()
            }
        }
    }

    Binding {
        target: actionToggleReaderMode
        property: "checked"
        value: webview && webview.readerMode
    }
}
