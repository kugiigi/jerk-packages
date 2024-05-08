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
}
