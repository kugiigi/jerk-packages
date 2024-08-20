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
import QtQuick.Window 2.2
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.Controls 2.5 as QQC2
import QtWebEngine 1.10
import Morph.Web 0.1
import webbrowsercommon.private 0.1
import "TextUtils.js" as TextUtils
// import "webbrowser" as BrowserApp
import "../.." as Common

WebView {
    id: webview

    // Used for UI components like the context menu
    property bool wide: false

    // ToDo: does not yet take into account browser zoom and pinch (pinch is not connected to zoomFactor property of WebEngineView
    readonly property real scaleFactor: Screen.devicePixelRatio

    property var currentWebview: webview
    property ContextMenuRequest contextMenuRequest: null

    // Current context menu displayed
    property var contextMenuObj

    // Current selection menu
    property var selectionMenuObj

    property var contentHandlerLoaderObj

    // better way to detect that, or move context menu items only available for the browser to other files ?
    readonly property bool isWebApp: (typeof browserTab === 'undefined')

    // the property webapp is defined in "webcontainer/WebApp.qml", browser is defined in "webbrowser/Browser.qml"
    readonly property var browserOrWebAppSettings: isWebApp ? webapp.settings : browser.settings

    readonly property alias findController: findController
    readonly property alias zoomController: zoomMenu.controller
    readonly property alias resetZoomShortCutText: zoomMenu.resetZoomShortCutText

    signal shareLinkRequested(url linkUrl, string title)
    signal shareTextRequested(string text)

    enableSelectOverride: true //let Morph.Web handle the dropdowns overlay

    //property real contextMenux: contextMenuRequest.x + (webview.scrollPosition.x - contextMenuStartScroll.x)
    //property real contextMenuy: contextMenuRequest.y + (webview.scrollPosition.y - contextMenuStartScroll.y)

    //enable using plugins, such as widevine or flash, to be installed separate
    settings.pluginsEnabled: true

    settings.unknownUrlSchemePolicy: WebEngineSettings.AllowAllUnknownUrlSchemes

    // setting it to false, because "true" opens the PDF viewer extension but makes it difficult to download the pdf (only possible with context menu)
    // furthermore pages saved as PDF would not be downloaded but only displayed as PDF
    settings.pdfViewerEnabled: false

    // allow pasting to clipboard from javascript
    settings.javascriptCanAccessClipboard: true

    // automatically load images
    settings.autoLoadImages: browserOrWebAppSettings ? browserOrWebAppSettings.loadImages : true

    /*experimental.certificateVerificationDialog: CertificateVerificationDialog {}
    experimental.proxyAuthenticationDialog: ProxyAuthenticationDialog {}*/

    // Try to not flash white when in dark mode when loading a site
    backgroundColor: loadProgress < 50 ? theme.palette.normal.background : "white"

    QtObject {
        id: findController

        property bool foundMatch: false
        property int numberOfMatches
        property int activeMatch
        property string searchText: ""
        property bool isCaseSensitive: false

        function next() {
            if (isCaseSensitive) {
                webview.findText(searchText, WebEngineView.FindCaseSensitively, function(success) {foundMatch = success})
            } else {
                webview.findText(searchText, 0, function(success) {foundMatch = success})
            }
        }

        function previous() {
            if (isCaseSensitive) {
                webview.findText(searchText, WebEngineView.FindBackward | WebEngineView.FindCaseSensitively, function(success) {foundMatch = success})
            } else {
                webview.findText(searchText, WebEngineView.FindBackward, function(success) {foundMatch = success})
            }
        }

        onSearchTextChanged: {
            findController.next()
        }
        onIsCaseSensitiveChanged: findController.next()
    }

    MouseArea {
        z: 1
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton

        onClicked: {
            if (mouse.button == Qt.BackButton) {
                webview.goBack()
            } else if (mouse.button == Qt.ForwardButton) {
                webview.goForward()
            }
        }
    }

    Loader {
        id: contentPickerLoader
        source: "ContentPickerDialog.qml"
        asynchronous: true
    }

    onFindTextFinished: {
        findController.numberOfMatches = result.numberOfMatches
        findController.activeMatch = result.activeMatch
    }

    onJavaScriptDialogRequested: function(request) {

        if (isASelectRequest(request)) return; //this is a select box , Morph.Web handled it already

        switch (request.type)
        {
            case JavaScriptDialogRequest.DialogTypeAlert:
                request.accepted = true;
                var alertDialog = PopupUtils.open(Qt.resolvedUrl("../../AlertDialog.qml"), this);
                alertDialog.message = request.message;
                alertDialog.accept.connect(request.dialogAccept);
                break;

            case JavaScriptDialogRequest.DialogTypeConfirm:
                request.accepted = true;
                var confirmDialog = PopupUtils.open(Qt.resolvedUrl("../../ConfirmDialog.qml"), this);
                confirmDialog.message = request.message;
                confirmDialog.accept.connect(request.dialogAccept);
                confirmDialog.reject.connect(request.dialogReject);
                break;

            case JavaScriptDialogRequest.DialogTypePrompt:
                request.accepted = true;
                var promptDialog = PopupUtils.open(Qt.resolvedUrl("../../PromptDialog.qml"), this);
                promptDialog.message = request.message;
                promptDialog.defaultValue = request.defaultText;
                promptDialog.accept.connect(request.dialogAccept);
                promptDialog.reject.connect(request.dialogReject);
                break;

            // did not work with JavaScriptDialogRequest.DialogTypeUnload (the default dialog was shown)
            //case JavaScriptDialogRequest.DialogTypeUnload:
            case 3:
                request.accepted = true;
                var beforeUnloadDialog = PopupUtils.open(Qt.resolvedUrl("../../BeforeUnloadDialog.qml"), this);
                beforeUnloadDialog.message = request.message;
                beforeUnloadDialog.accept.connect(request.dialogAccept);
                beforeUnloadDialog.reject.connect(request.dialogReject);
                break;
        }

    }

    onFileDialogRequested: function(request) {

        switch (request.mode)
        {
            case FileDialogRequest.FileModeOpen:
                request.accepted = true;
                var fileDialogSingle = contentPickerLoader.item.openDialog(false, request)
                break;

            case FileDialogRequest.FileModeOpenMultiple:
                request.accepted = true;
                var fileDialogMultiple = contentPickerLoader.item.openDialog(true, request)
                break;

            case FilealogRequest.FileModeUploadFolder:
            case FileDialogRequest.FileModeSave:
                request.accepted = false;
                break;
        }

    }

    onColorDialogRequested: function(request) {
        request.accepted = true;
        var colorDialog = PopupUtils.open(Qt.resolvedUrl("../../ColorSelectDialog.qml"), this);
        colorDialog.defaultValue = request.color;
        colorDialog.accept.connect(request.dialogAccept);
        colorDialog.reject.connect(request.dialogReject);
        //myDialog.visible = true;
    }

    onAuthenticationDialogRequested: function(request) {

        switch (request.type)
        {
            //case WebEngineAuthenticationDialogRequest.AuthenticationTypeHTTP:
            case 0:
            request.accepted = true;
            var authDialog = PopupUtils.open(Qt.resolvedUrl("../../HttpAuthenticationDialog.qml"), this);
            authDialog.host = UrlUtils.extractHost(request.url);
            authDialog.realm = request.realm;
            authDialog.accept.connect(request.dialogAccept);
            authDialog.reject.connect(request.dialogReject);

            break;

            //case WebEngineAuthenticationDialogRequest.AuthenticationTypeProxy:
            case 1:
            request.accepted = false;
            break;
        }

    }

     onFeaturePermissionRequested: {

         switch(feature)
         {
             case WebEngineView.Geolocation:

             var domain = UrlUtils.extractHost(securityOrigin);
             var locationPreference = DomainSettingsModel.getLocationPreference(domain);

             if (locationPreference === DomainSettingsModel.AllowLocationAccess)
             {
                 grantFeaturePermission(securityOrigin, feature, true);
                 return;
             }

             if (locationPreference === DomainSettingsModel.DenyLocationAccess)
             {
                 grantFeaturePermission(securityOrigin, feature, false);
                 return;
             }

             var geoPermissionDialog = PopupUtils.open(Qt.resolvedUrl("../../GeolocationPermissionRequest.qml"), this);
             geoPermissionDialog.securityOrigin = securityOrigin;
             geoPermissionDialog.showRememberDecisionCheckBox = (domain !== "") && ! incognito
             geoPermissionDialog.allow.connect(function() { grantFeaturePermission(securityOrigin, feature, true); });
             geoPermissionDialog.allowPermanently.connect(function() { grantFeaturePermission(securityOrigin, feature, true);
                                                                       DomainSettingsModel.setLocationPreference(domain, DomainSettingsModel.AllowLocationAccess);
                                                                     })
             geoPermissionDialog.reject.connect(function() { grantFeaturePermission(securityOrigin, feature, false); });
             geoPermissionDialog.rejectPermanently.connect(function() { grantFeaturePermission(securityOrigin, feature, false);
                                                                       DomainSettingsModel.setLocationPreference(domain, DomainSettingsModel.DenyLocationAccess);
                                                                     })
             break;

             case WebEngineView.MediaAudioCapture:
             case WebEngineView.MediaVideoCapture:
             case WebEngineView.MediaAudioVideoCapture:

             var mediaAccessDialog = PopupUtils.open(Qt.resolvedUrl("../../MediaAccessDialog.qml"), this);
             mediaAccessDialog.origin = securityOrigin;
             mediaAccessDialog.feature = feature;
             break;
         }
    }

      onCertificateError: function(certificateError) {

          certificateError.defer()
          var certificateVerificationDialog = PopupUtils.open(Qt.resolvedUrl("../../CertificateVerificationDialog.qml"), this);
          certificateVerificationDialog.host = UrlUtils.extractHost(certificateError.url);
          webview.profile.certificateErrorsMap[certificateVerificationDialog.host] = certificateError;
          webview.profile.certificateErrorsMapChanged();
          certificateVerificationDialog.localizedErrorMessage = certificateError.description;
          certificateVerificationDialog.errorIsOverridable = certificateError.overridable;
          certificateVerificationDialog.accept.connect(certificateError.ignoreCertificateError);
          certificateVerificationDialog.reject.connect(certificateError.rejectCertificate);
      }

    function showMessage(text) {

         var alertDialog = PopupUtils.open(Qt.resolvedUrl("../../AlertDialog.qml"), webview);
         alertDialog.message = text;
     }

    QtObject {
        id: domElementOfContextMenu

        // true for input and textarea elements that support text selection
        property bool hasSelectMethod: false
        property bool isDocumentElement: false
    }

    onContextMenuRequested: function(request) {

        contextMenuRequest = request;
        //console.log("onContextMenuRequested, request: " + JSON.stringify(request))
        request.accepted = true;
        zoomMenu.close()

        if (request.linkUrl.toString() || request.mediaType)
        {
            contextMenuObj = contextMenuComponent.createObject(webview)

            // Not sure why binding doesn't work properly so we set it here
            contextMenuObj.showAsCenteredModal = !webview.wide
            if (webview.wide) {
                contextMenuObj.popup(request.x + units.gu(2), request.y)
            } else {
                contextMenuObj.show()
            }
        }
        else if (request.isContentEditable)
        {
            if (contextMenuObj) {
                contextMenuObj.close()
            }
            contextMenuObj = editableMenuComponent.createObject(webview)
            contextMenuObj.popup(request.x - (contextMenuObj.width / 2), request.y + units.gu(5))
        }
        else
        {
            contextMenuController.selectedTextLength = contextMenuRequest.selectedText.length
            contextMenuController.textSelectionLevels = []
            contextMenuController.textSelectionIsAtRootLevel = false

            if (request.editFlags & ContextMenuRequest.CanCopy) {
                showSelectionMenu()
            } else {
                contextMenuObj = generalContextMenuComponent.createObject(webview)

                // Not sure why binding doesn't work properly so we set it here
                contextMenuObj.showAsCenteredModal = !webview.wide
                if (webview.wide) {
                    contextMenuObj.popup(request.x + units.gu(2), request.y)
                } else {
                    contextMenuObj.show()
                }
            }
        }

        var commandGetContextMenuInfo = "
        var morphElemContextMenu = document.elementFromPoint(%1, %2);
        var morphContextMenuIsDocumentElement = false;
        if (morphElemContextMenu === null)
        {
            morphElemContextMenu = document.documentElement;
            morphContextMenuIsDocumentElement = true;
        }
        var morphContextMenuElementHasSelectMethod = (typeof morphElemContextMenu.select === 'function') ? true : false;
        // result array
        // [0]..[3] : bounds of the selected element
        // [4] : boolean variable morphContextMenuIsDocumentElement
        //    true: context menu for the whole HTML document
        //    false: context menu for a specific element (e.g. input, span, ...)
        // [5] : boolean variable morphContextMenuElementHasSelectMethod
        [morphElemContextMenu.offsetLeft, morphElemContextMenu.offsetTop, morphElemContextMenu.offsetWidth, morphElemContextMenu.offsetHeight, morphContextMenuIsDocumentElement, morphContextMenuElementHasSelectMethod];
        ".arg(request.x / webview.zoomFactor).arg(request.y / webview.zoomFactor)

        webview.runJavaScript(commandGetContextMenuInfo, function(result)
                                                    {
                                                       console.log("commandGetContextMenuInfo returned array " + JSON.stringify(result))
                                                       domElementOfContextMenu.isDocumentElement = result[4]
                                                       domElementOfContextMenu.hasSelectMethod = result[5]
                                                    }
                                 );
   }

    Component {
        id: contextMenuComponent

        AdvancedMenu {
            id: contextMenu

            readonly property string linkUrl: webview.contextMenuRequest.linkUrl.toString()
            readonly property string mediaUrl: webview.contextMenuRequest.mediaUrl.toString()
            readonly property bool isImage: webview.contextMenuRequest.mediaType === ContextMenuRequest.MediaTypeImage
            readonly property bool isCanvas: webview.contextMenuRequest.mediaType === ContextMenuRequest.MediaTypeCanvas
            readonly property bool isVideo: webview.contextMenuRequest.mediaType === ContextMenuRequest.MediaTypeVideo
            readonly property int foundTabIndex: !isWebApp ? browser.tabsModel.searchSameUrl(linkUrl) : -1
            readonly property bool existingTabIsFound: foundTabIndex > -1
            readonly property bool foundTabIsCurrent: !isWebApp && foundTabIndex === browser.tabsModel.selectedIndex

            headerTitle: {
                if (webview.contextMenuRequest) {
                    if (linkUrl) {
                        return linkUrl
                    } else if (mediaUrl) {
                        return mediaUrl
                    }
                }

                return ""
            }

            iconName: {
                if (linkUrl) {
                    return "stock_link"
                } else if (isVideo) {
                    return "stock_video"
                } else if (isImage) {
                    return "stock_image"
                }

                return ""
            }

            multilineTitle: true
            showShortcuts: !isWebApp && browser.hasKeyboard
            showAsCenteredModal: !webview.wide
            destroyOnClose: true

            CustomizedMenuItem {
                id: switchTabMenuItem
                objectName: "SwitchToTabContextualAction"
                text: i18n.tr("Switch to tab")
                enabled: !isWebApp && contextMenu.linkUrl && contextMenu.existingTabIsFound && !contextMenu.foundTabIsCurrent
                onTriggered: browser.switchToTabRequested(contextMenu.foundTabIndex)
            }
            CustomizedMenuItem {
                id: moveTabNextMenuItem
                objectName: "MoveToTabContextualAction"
                text: i18n.tr("Move found tab next to this tab")
                enabled: !isWebApp && contextMenu.linkUrl && contextMenu.existingTabIsFound && !contextMenu.foundTabIsCurrent
                onTriggered: browser.moveTabNextToCurrentTabRequested(contextMenu.foundTabIndex)
            }
            CustomizedMenuItem {
                id: newTabMenuItem
                objectName: "OpenLinkInNewTabContextualAction"
                text: i18n.tr("Open link in new tab")
                enabled: !isWebApp && contextMenu.linkUrl
                onTriggered: browser.openLinkInNewTabRequested(contextMenuRequest.linkUrl, false)
            }
            CustomizedMenuItem {
                id: newBGTabMenuItem
                objectName: "OpenLinkInNewBackgroundTabContextualAction"
                text: i18n.tr("Open link in new background tab")
                enabled: !isWebApp && contextMenu.linkUrl
                onTriggered: browser.openLinkInNewTabRequested(contextMenuRequest.linkUrl, true)
            }
            CustomizedMenuItem {
                id: newWindowMenuItem
                objectName: "OpenLinkInNewWindowContextualAction"
                text: isWebApp ? i18n.tr("Open link in overlay") : i18n.tr("Open link in new window")
                enabled: !incognito && contextMenu.linkUrl
                onTriggered: webview.triggerWebAction(WebEngineView.OpenLinkInNewWindow)
            }
            CustomizedMenuItem {
                id: openExternallyMenuItem
                objectName: "OpenLinkExternallyContextualAction"
                text: i18n.tr("Open link externally")
                enabled: isWebApp && contextMenu.linkUrl
                onTriggered: Qt.openUrlExternally(contextMenuRequest.linkUrl)
            }
            /*
            BrowserApp.OpenToWindowMenu {
                id: openToWindowMenu
                model: browser.appWindows
                linkUrl: contextMenuRequest.linkUrl
                thisWindow: browser.thisWindow
                showIcon: false
                enabled: !isWebApp && !browser.incognito && model.length > 1 && contextMenu.linkUrl
            }
            */
            CustomizedMenuItem {
                id: newPrivateWindowMenuItem
                objectName: "OpenLinkInNewPrivateWindowContextualAction"
                text: i18n.tr("Open link in new private window")
                enabled: !isWebApp && contextMenu.linkUrl
                onTriggered: browser.openLinkInNewWindowRequested(contextMenuRequest.linkUrl, true)
            }

            CustomizedMenuSeparator {
                visible: newTabMenuItem.enabled || newBGTabMenuItem.enabled || newWindowMenuItem.enabled || newPrivateWindowMenuItem.enabled
            }

            ActionRowMenu {
                menu: contextMenu

                model: [
                    RowMenuAction {
                        readonly property bool isBookmarked: !isWebApp && browser.bookmarksModel.contains(contextMenuRequest.linkUrl)

                        objectName: "BookmarkLinkContextualAction"
                        text: isBookmarked ? i18n.tr("Remove link from bookmarks") : i18n.tr("Bookmark link")
                        enabled: !isWebApp && contextMenu.linkUrl
                        icon.name: isBookmarked ? "starred" : "non-starred"
                        closeMenuOnTrigger: true
                        onTriggered: {
                            chrome.toggleBookmarkState(false, contextMenuRequest.linkUrl, contextMenuRequest.linkText)
                        }
                    }
                    , RowMenuAction {
                        readonly property bool isAlreadyAdded: isWebApp && webapp.findFromArray(webapp.settings.customURLActions, "url", contextMenu.linkUrl) ? true : false

                        objectName: "AddCustomActionContextualAction"
                        text: i18n.tr("Add Link as Custom Action")
                        enabled: isWebApp && contextMenu.linkUrl && !isAlreadyAdded
                        icon.name: "non-starred"
                        closeMenuOnTrigger: true
                        onTriggered: {
                            webapp.addNewCustomURLAction(contextMenu.linkUrl)
                        }
                    }
                    , RowMenuAction {
                        objectName: "CopyLinkContextualAction"
                        text: i18n.tr("Copy link")
                        icon.name: "stock_link"
                        enabled: contextMenu.linkUrl
                        closeMenuOnTrigger: true
                        onTriggered: {
                            Clipboard.push(["text/plain", contextMenuRequest.linkUrl.toString()])
                            if (isWebApp) {
                                webapp.showTooltip(i18n.tr("Link url copied"))
                            } else {
                                browser.showTooltip(i18n.tr("Link url copied"))
                            }
                        }
                    }
                    , RowMenuAction {
                        objectName: "CopyContextualAction"
                        text: i18n.tr("Copy text")
                        icon.name: "edit-copy"
                        enabled: contextMenuRequest.linkText !== ""
                        closeMenuOnTrigger: true
                        onTriggered: {
                            Clipboard.push(["text/plain", contextMenuRequest.linkText])
                            if (isWebApp) {
                                webapp.showTooltip(i18n.tr("Link text copied"))
                            } else {
                                browser.showTooltip(i18n.tr("Link text copied"))
                            }
                        }
                    }
                    , RowMenuAction {
                        objectName: "SaveLinkContextualAction"
                        text: i18n.tr("Save link")
                        icon.name: "save"
                        enabled: contextMenu.linkUrl
                        closeMenuOnTrigger: true
                        onTriggered: {
                            webview.triggerWebAction(WebEngineView.DownloadLinkToDisk)
                        }
                    }
                    , RowMenuAction {
                        objectName: "ShareContextualAction"
                        text: i18n.tr("Share link")
                        icon.name: "share"
                        enabled: ((!isWebApp && browserTab.contentHandlerLoader && browserTab.contentHandlerLoader.status === Loader.Ready)
                                    || (isWebApp && webview.contentHandlerLoaderObj && webview.contentHandlerLoaderObj.status === Loader.Ready))
                                && contextMenu.linkUrl
                        closeMenuOnTrigger: true
                        onTriggered: {
                            if (isWebApp) {
                                webview.shareLinkRequested(contextMenu.linkUrl, contextMenuRequest.linkText);
                            } else {
                                browser.shareLinkRequested(contextMenu.linkUrl, contextMenuRequest.linkText);
                            }
                        }
                    }
                ]
            }

            CustomizedMenuItem {
                id: imageNewTabMenuItem
                objectName: "OpenImageInNewTabContextualAction"
                text: i18n.tr("Open image in new tab")
                enabled: !isWebApp && contextMenu.isImage &&
                           contextMenu.mediaUrl
                onTriggered: browser.openLinkInNewTabRequested(contextMenuRequest.mediaUrl, false);
            }
            CustomizedMenuItem {
                id: copyImageLinkMenuItem
                objectName: "CopyImageLinkContextualAction"
                text: i18n.tr("Copy image link")
                enabled:  (contextMenu.isImage || contextMenu.isCanvas) // && contextModel.hasImageContents
                onTriggered: Clipboard.push(["text/plain", contextMenuRequest.mediaUrl.toString()])
            }
            CustomizedMenuItem {
                id: copyImageMenuItem
                objectName: "CopyImageContextualAction"
                text: i18n.tr("Copy image")
                enabled:  (contextMenu.isImage || contextMenu.isCanvas) // && contextModel.hasImageContents
                // TODO: Doesn't work in UT
                onTriggered: webview.triggerWebAction(WebEngineView.CopyImageToClipboard)
            }
            CustomizedMenuItem {
                id: saveImageMenuItem
                objectName: "SaveImageContextualAction"
                text: i18n.tr("Save image")
                enabled: (contextMenu.isImage || contextMenu.isCanvas) // && contextModel.hasImageContents

                onTriggered: webview.triggerWebAction(WebEngineView.DownloadImageToDisk)
            }
            CustomizedMenuItem {
                id: videoNewTabMenuItem
                objectName: "OpenVideoInNewTabContextualAction"
                text: i18n.tr("Open video in new tab")
                enabled: !isWebApp && contextMenu.isVideo && contextMenu.mediaUrl
                onTriggered: browser.openLinkInNewTabRequested(contextMenuRequest.mediaUrl, false);
            }
            CustomizedMenuItem {
                id: saveVideoMenuItem
                objectName: "SaveVideoContextualAction"
                text: i18n.tr("Save video")
                enabled: contextMenu.isVideo && contextMenu.mediaUrl
                onTriggered: webview.triggerWebAction(WebEngineView.DownloadMediaToDisk)
            }

            CustomizedMenuSeparator {
                visible: imageNewTabMenuItem.enabled || copyImageMenuItem.enabled || saveImageMenuItem.enabled
                                    || videoNewTabMenuItem.enabled || saveVideoMenuItem.enabled
            }

            CustomizedMenuItem {
                objectName: "CancelContextualAction"
                text: i18n.tr("Cancel")
                onTriggered: contextMenu.close()
            }
        }
    }
    
    function showSelectionMenu() {
        if (selectionMenuObj) selectionMenuObj.close()
        selectionMenuObj = selectElementMenuComponent.createObject(webview)
        selectionMenuObj.popup(contextMenuRequest.x - (selectionMenuObj.width / 2), contextMenuRequest.y + units.gu(5))
    }

    function showZoomMenu() {
        zoomMenu.open()
    }

    function hideZoomMenu() {
        zoomMenu.close()
    }

    function hideContextMenu() {
        if (contextMenuObj) contextMenuObj.close()
    }
    
    function scrollToTop(){
        runJavaScript("window.scrollTo(0, 0); ")
    }

    function scrollToBottom(){
        runJavaScript("window.scrollTo(0, " + webview.contentsSize.height +"); ")
    }

    function gotoUrl(urlText) {
        var query = urlText.trim()
        var requestedUrl = UrlUtils.fixUrl(query)
        console.log("requestedUrl: " + requestedUrl)
        browser.openLinkInNewTabRequested(requestedUrl, false)
    }
    
    function searchForText(searchText) {
        var query = searchText.trim()
        var requestedUrl = TextUtils.buildSearchUrl(query, webapp.searchUrl)
        console.log("requestedUrl: " + requestedUrl)
        if (isWebApp) {
            webapp.currentWebview.openUrlExternally(requestedUrl, false)
        } else {
            browser.openLinkInNewTabRequested(requestedUrl, false)
        }
    }

    Component {
        id: editableMenuComponent

        AdvancedMenu {
            id: editableMenu
            
            property bool tempCopyEnabled: false

            focus: false
            showShortcuts: !isWebApp && browser.hasKeyboard
            destroyOnClose: true
            modal: false
            closePolicy: QQC2.Popup.CloseOnEscape

            ActionRowMenu {
                menu: editableMenu
                hideSeparator: true

                model: [
                    RowMenuAction {
                        text: i18n.dtr('lomiri-ui-toolkit', "Undo")
                        icon.name: "edit-undo"
                        // with the editFlags we would have to close the context menu after one "Undo" step (desktop way)
                        // after one action we do no longer know if further Undo actions are possible
                        // if we keep the button enabled, the user can use Undo/Redo multiple times
                        enabled: true // && (contextMenuRequest.editFlags & ContextMenuRequest.CanUndo)
                        closeMenuOnTrigger: false
                        onTriggered: {
                            webview.triggerWebAction(WebEngineView.Undo)
                            // ToDo: might there be a way to refresh / recreate the context menu again (for the same element) without user interaction,
                            // so that the editFlags are updated, then we could use the editFlags for the enabled property
                            // with JavaScript it seems not possible: https://stackoverflow.com/a/1241569/4326472
                        }
                    }
                    , RowMenuAction {
                        text: i18n.dtr('lomiri-ui-toolkit', "Redo")
                        icon.name: "edit-redo"
                        // with the editFlags we would have to close the context menu after one "Redo" step (desktop way)
                        // see comment for "Undo"
                        enabled: true // && (contextMenuRequest.editFlags & ContextMenuRequest.CanRedo)
                        closeMenuOnTrigger: false
                        onTriggered: {
                            webview.triggerWebAction(WebEngineView.Redo)
                        }
                    }
                    , RowMenuAction {
                        text: i18n.dtr('lomiri-ui-toolkit', "Select All")
                        icon.name: "edit-select-all"
                        // can we make it so that it only appears for non-empty inputs ?
                        enabled: contextMenuRequest.editFlags & ContextMenuRequest.CanSelectAll
                        closeMenuOnTrigger: false
                        onTriggered: {
                            webview.triggerWebAction(WebEngineView.SelectAll)
                            editableMenu.tempCopyEnabled = true // WORKAROUND: To enable copy, cut, share when selecting all
                        }
                    }
                    , RowMenuAction {
                        text: i18n.dtr('lomiri-ui-toolkit', "Cut")
                        icon.name: "edit-cut"
                        enabled: (contextMenuRequest.editFlags & ContextMenuRequest.CanCut) || editableMenu.tempCopyEnabled
                        closeMenuOnTrigger: true
                        onTriggered: {
                            webview.triggerWebAction(WebEngineView.Cut);
                        }
                    }
                    , RowMenuAction {
                        text: i18n.dtr('lomiri-ui-toolkit', "Copy")
                        icon.name: "edit-copy"
                        enabled: (contextMenuRequest.editFlags & ContextMenuRequest.CanCopy) || editableMenu.tempCopyEnabled
                        closeMenuOnTrigger: true
                        onTriggered: {
                            webview.triggerWebAction(WebEngineView.Copy);
                        }
                    }
                    , RowMenuAction {
                        text: i18n.dtr('lomiri-ui-toolkit', "Paste")
                        icon.name: "edit-paste"
                        enabled: contextMenuRequest.editFlags & ContextMenuRequest.CanPaste
                        closeMenuOnTrigger: true
                        onTriggered: {
                            webview.triggerWebAction(WebEngineView.Paste);
                        }
                    }
                    , RowMenuAction {
                        text: i18n.dtr('lomiri-ui-toolkit', "Share")
                        icon.name: "share"
                        enabled: ((!isWebApp && browserTab.contentHandlerLoader && browserTab.contentHandlerLoader.status === Loader.Ready)
                                    || (isWebApp && webview.contentHandlerLoaderObj && webview.contentHandlerLoaderObj.status === Loader.Ready))
                                        && ((contextMenuRequest.editFlags & ContextMenuRequest.CanCopy) || editableMenu.tempCopyEnabled)
                        closeMenuOnTrigger: true
                        onTriggered: {
                            if (isWebApp) {
                                webview.runJavaScript("window.getSelection().toString()", function(result) { webview.shareTextRequested(result) })
                            } else {
                                webview.runJavaScript("window.getSelection().toString()", function(result) { browser.shareTextRequested(result) })
                            }
                        }
                    }
                    , RowMenuAction {
                        text: i18n.tr('Close menu')
                        icon.name: "close"
                        closeMenuOnTrigger: true
                    }
                ]
            }
        }
    }

    Component {
        id: generalContextMenuComponent

        AdvancedMenu {
            id: generalContextMenu

            showShortcuts: !isWebApp && browser.hasKeyboard
            showAsCenteredModal: !webview.wide
            destroyOnClose: true

            ActionRowMenu {
                menu: generalContextMenu

                model: [
                    RowMenuAction {
                        text: !isWebApp ? i18n.tr("%1 (%2)").arg(i18n.tr("Go back one page")).arg(browser.backHistoryShortcutText)
                                        : i18n.tr("Go back one page")
                        icon.name: "previous"
                        enabled: webview.canGoBack
                        displayWhenDisabled: true
                        closeMenuOnTrigger: true
                        onTriggered: {
                            if (webview.loading) {
                                webview.stop()
                            }
                            webview.goBack()
                        }
                    }
                    , RowMenuAction {
                        text: !isWebApp ? i18n.tr("%1 (%2)").arg(i18n.tr("Go forward one page")).arg(browser.forwardHistoryShortcutText)
                                        : i18n.tr("Go forward one page")
                        icon.name: "next"
                        enabled: webview.canGoForward
                        closeMenuOnTrigger: true
                        displayWhenDisabled: true
                        onTriggered: {
                            if (webview.loading) {
                                webview.stop()
                            }
                            webview.goForward()
                        }
                    }
                    , RowMenuAction {
                        text: !isWebApp ? i18n.tr("%1 (%2)").arg(i18n.tr("Reload current page")).arg(browser.reloadShortcutText)
                                        : i18n.tr("Reload current page")
                        icon.name: chrome.loading ? "stop" : "reload"
                        closeMenuOnTrigger: true
                        onTriggered: {
                            if (chrome.loading) {
                                webview.stop()
                            } else {
                                webview.forceActiveFocus()
                                webview.reload()
                            }
                        }
                    }
                    , RowMenuAction {
                        readonly property bool isBookmarked: !isWebApp && browser.bookmarksModel.contains(webview.url)

                        text: !isWebApp ? i18n.tr("%1 (%2)").arg(isBookmarked ? i18n.tr("Remove tab from bookmarks") : i18n.tr("Bookmark this tab"))
                                            .arg(browser.bookmarkTabShortcutText)
                                    : ""
                        enabled: !isWebApp && webview.url.toString() ? true : false
                        icon.name: isBookmarked ? "starred" : "non-starred"
                        closeMenuOnTrigger: true
                        onTriggered: {
                            chrome.toggleBookmarkState(false)
                        }
                    }
                    , RowMenuAction {
                        readonly property bool isAlreadyAdded: isWebApp && webapp.findFromArray(webapp.settings.customURLActions, "url", webview.url) !== undefined

                        text: i18n.tr("Add Current as Custom Action")
                        enabled: isWebApp && webview.url.toString() && !isAlreadyAdded ? true : false
                        icon.name: "non-starred"
                        closeMenuOnTrigger: true
                        onTriggered: {
                            webapp.addNewCustomURLAction(webview.url)
                        }
                    }
                    , RowMenuAction {
                        text: i18n.tr("Copy current link")
                        icon.name: "stock_link"
                        enabled: webview.url.toString() !== ""
                        closeMenuOnTrigger: true
                        onTriggered: {
                            Clipboard.push(["text/plain", webview.url.toString()])
                            if (isWebApp) {
                                webapp.showTooltip(i18n.tr("Link url copied"))
                            } else {
                                browser.showTooltip(i18n.tr("Link url copied"))
                            }
                        }
                    }
                    , RowMenuAction {
                        objectName: "CopyContextualAction"
                        text: i18n.tr("Copy current site title")
                        icon.name: "edit-copy"
                        enabled: webview.title !== ""
                        closeMenuOnTrigger: true
                        onTriggered: {
                            Clipboard.push(["text/plain", webview.title])
                            if (isWebApp) {
                                webapp.showTooltip(i18n.tr("Site title copied"))
                            } else {
                                browser.showTooltip(i18n.tr("Site title copied"))
                            }
                        }
                    }
                    , RowMenuAction {
                        text: i18n.tr("Share current tab's link")
                        icon.name: "share"
                        enabled: ((!isWebApp && browserTab.contentHandlerLoader && browserTab.contentHandlerLoader.status === Loader.Ready)
                                    || (isWebApp && webview.contentHandlerLoaderObj && webview.contentHandlerLoaderObj.status === Loader.Ready))
                                && webview.url.toString()
                        closeMenuOnTrigger: true
                        onTriggered: {
                            if (isWebApp) {
                                webview.shareLinkRequested(webview.url, webview.title);
                            } else {
                                browser.shareLinkRequested(webview.url, webview.title);
                            }
                        }
                    }
                    , RowMenuAction {
                        text: i18n.dtr('lomiri-ui-toolkit', "Settings")
                        icon.name: "settings"
                        enabled: isWebApp && ! domElementOfContextMenu.hasSelectMethod && ( contextMenuController.selectedTextLength === 0 || domElementOfContextMenu.isDocumentElement )
                        closeMenuOnTrigger: true
                        onTriggered: {
                            webapp.showWebappSettings()
                        }
                    }
                ]
            }
            CustomizedMenuItem {
                text: i18n.dtr('lomiri-ui-toolkit', "Select All")
                enabled: contextMenuRequest.editFlags & ContextMenuRequest.CanSelectAll
                onTriggered: {
                    // prevent creation of new context menu request
                    if (! domElementOfContextMenu.hasSelectMethod)
                    {
                        webview.runJavaScript("window.getSelection().removeAllRanges()", function(){webview.triggerWebAction(WebEngineView.SelectAll)})
                        domElementOfContextMenu.isDocumentElement = true
                        contextMenuController.selectedTextLength = Math.max(1, contextMenuController.selectedTextLength)
                    }
                    else
                    {
                        webview.triggerWebAction(WebEngineView.SelectAll)
                    }
                    webview.showSelectionMenu()
                }
            }
            CustomizedMenuItem {
                text: i18n.tr("Select element")
                enabled: !domElementOfContextMenu.isDocumentElement && !domElementOfContextMenu.hasSelectMethod
                                    && !contextMenuController.textSelectionIsAtRootLevel
                onTriggered: {
                    contextMenuController.extendSelectionUpTheDom("morphElemContextMenu")
                    webview.showSelectionMenu()
                }
            }
            CustomizedMenuSeparator{}

            CustomizedMenuItem {
                text: i18n.tr("Zoom settings")
                enabled: ! domElementOfContextMenu.hasSelectMethod && ( contextMenuController.selectedTextLength === 0 || domElementOfContextMenu.isDocumentElement )
                onTriggered: webview.showZoomMenu()
            }
            CustomizedMenuItem {
                text: i18n.tr("Save page as...")
                enabled: !isWebApp && webview.url.toString() !== ""
                rightDisplay: !isWebApp ? browser.saveAsShortcutText : "" //"Ctrl+S"
                onTriggered: browser.savePageRequested()
            }
            CustomizedMenuItem {
                text: i18n.tr("View source")
                rightDisplay: !isWebApp ? browser.viewSourceShortcutText : "" //"Ctrl+U"
                enabled: !isWebApp && webview.url.toString() !== "" && (webview.url.toString().substring(0,12) !== "view-source:")
                onTriggered: browser.viewSourceRequested()
            }
        }
    }

    Component {
        id: selectElementMenuComponent

        AdvancedMenu {
            id: selectElementMenu

            focus: false
            destroyOnClose: true
            modal: false
            closePolicy: QQC2.Popup.CloseOnEscape

            ActionRowMenu {
                menu: selectElementMenu
                hideSeparator: true

                model: [
                    RowMenuAction {
                        text: i18n.dtr('lomiri-ui-toolkit', "Select Less")
                        icon.name: "view-collapse"
                        enabled: !domElementOfContextMenu.isDocumentElement && !domElementOfContextMenu.hasSelectMethod
                                            && contextMenuController.textSelectionLevels.length > 1
                        closeMenuOnTrigger: false
                        displayWhenDisabled: true
                        onTriggered: {
                            contextMenuController.setTextSelection("morphElemContextMenu"
                                            , contextMenuController.textSelectionLevels[contextMenuController.textSelectionLevels.length - 2])
                        }
                    }
                    , RowMenuAction {
                        text: (contextMenuController.textSelectionLevels.length == 0)    ? i18n.dtr('lomiri-ui-toolkit', "Select Element")
                                                                         :  i18n.dtr('lomiri-ui-toolkit', "Select More")
                        icon.name: "view-expand"
                        enabled: !domElementOfContextMenu.isDocumentElement && !domElementOfContextMenu.hasSelectMethod
                                            && !contextMenuController.textSelectionIsAtRootLevel
                        closeMenuOnTrigger: false
                        displayWhenDisabled: true
                        onTriggered: {
                            contextMenuController.extendSelectionUpTheDom("morphElemContextMenu")
                        }
                    }
                    , RowMenuAction {
                        text: i18n.dtr('lomiri-ui-toolkit', "Select All")
                        icon.name: "edit-select-all"
                        // can we make it so that it only appears for non-empty inputs ?
                        enabled: contextMenuRequest.editFlags & ContextMenuRequest.CanSelectAll
                        closeMenuOnTrigger: false
                        onTriggered: {
                            webview.triggerWebAction(WebEngineView.SelectAll)
                        }
                    }
                    , RowMenuAction {
                        text: i18n.dtr('lomiri-ui-toolkit', "Copy")
                        icon.name: "edit-copy"
                        enabled: contextMenuController.selectedTextLength > 0
                        closeMenuOnTrigger: true
                        onTriggered: {
                            webview.triggerWebAction(WebEngineView.Copy);
                        }
                    }
                    , RowMenuAction {
                        text: i18n.dtr('lomiri-ui-toolkit', "Share")
                        icon.name: "share"
                        enabled: ((!isWebApp && browserTab.contentHandlerLoader && browserTab.contentHandlerLoader.status === Loader.Ready)
                                    || (isWebApp && webview.contentHandlerLoaderObj && webview.contentHandlerLoaderObj.status === Loader.Ready))
                                        && contextMenuController.selectedTextLength > 0
                        closeMenuOnTrigger: true
                        onTriggered: {
                            if (isWebApp) {
                                webview.runJavaScript("window.getSelection().toString()", function(result) { webview.shareTextRequested(result) })
                            } else {
                                webview.runJavaScript("window.getSelection().toString()", function(result) { browser.shareTextRequested(result) })
                            }
                        }
                    }
                    , RowMenuAction {
                        readonly property bool isUrl: UrlUtils.looksLikeAUrl(contextMenuRequest.selectedText)
                        readonly property string elidedText: TextUtils.elideText(contextMenuRequest.selectedText, 20)

                        text: isUrl ? i18n.tr('Go to "%1"').arg(elidedText)
                                            : i18n.tr('Search for "%1"').arg(elidedText)
                        icon.name: isUrl ? "stock_website" : "find"
                        enabled: contextMenuRequest.selectedText
                        closeMenuOnTrigger: true
                        onTriggered: {
                            webview.triggerWebAction(WebEngineView.Copy)
                            searchTextDelay.restart()
                        }
                    }
                    , RowMenuAction {
                        text: i18n.tr('Close menu')
                        icon.name: "close"
                        closeMenuOnTrigger: true
                    }
                ]
            }
        }
    }

    Timer {
        id: searchTextDelay
        running: false
        interval: 100
        onTriggered: {
            let selectedText = Clipboard.data.text
            let isUrl = UrlUtils.looksLikeAUrl(selectedText)
            let elidedText = TextUtils.elideText(selectedText, 20)

            if (isUrl) {
                webview.gotoUrl(selectedText)
            } else {
                webview.searchForText(selectedText)
            }
        }
    }

    QtObject {
        id: contextMenuController

        property int selectedTextLength: 0
        // remember previous text selection levels in an first in - first out array
        property var textSelectionLevels: []
        property bool textSelectionIsAtRootLevel: false
        
        // text selection with <leafElementName> as starting point
        function extendSelectionUpTheDom (leafElementName) {
            var commandExtendSelection = "
                var elementForTextSelection = %1;
                var selectedLengthStart = window.getSelection().toString().length;

                var levelCounter = 0;
                // go up the DOM until the selection is larger
                while (elementForTextSelection.parentNode)
                {
                    // select the current node
                    var range = document.createRange();
                    range.selectNode(elementForTextSelection);
                    window.getSelection().removeAllRanges();
                    window.getSelection().addRange(range);

                    if (window.getSelection().toString().length > selectedLengthStart)
                    {
                        break;
                    }
                    elementForTextSelection = elementForTextSelection.parentNode;
                    levelCounter++;
                }

                // return array
                // [0] length of selection
                // [1] parent level at end
                // [2] isRootNode
                [window.getSelection().toString().length, levelCounter, elementForTextSelection.parentNode ? false : true]
            ".arg(leafElementName);

            webview.runJavaScript(commandExtendSelection,
                function(result) {
                    console.log("[extendSelectionUpTheDom] java script function returned " + JSON.stringify(result))
                    var selectedLength = result[0]
                    var parentLevelAtEnd = result[1]
                    var isRootNode = result[2]
                    contextMenuController.selectedTextLength = selectedLength
                    while (contextMenuController.textSelectionLevels.length > 0
                                    && (parentLevelAtEnd <= contextMenuController.textSelectionLevels[contextMenuController.textSelectionLevels.length - 1] ))
                    {
                        contextMenuController.textSelectionLevels.pop()
                    }
                    contextMenuController.textSelectionLevels.push(parentLevelAtEnd)
                    contextMenuController.textSelectionLevelsChanged()
                    console.log("contextMenuController.textSelectionLevels is now " + JSON.stringify(contextMenuController.textSelectionLevels))
                    contextMenuController.textSelectionIsAtRootLevel = isRootNode
               });
        }

        // <parentLevel> how many levels (.parentNode calls) to go up to reach the node with the text selection in the DOM
        // <leafElementName> is the starting point (element the context menu was created for)
        function setTextSelection (leafElementName, parentLevel) {

            var commandSetTextSelection = "
                var elementForTextSelection = %1;
                var parentLevel = %2;

                var levelCounter = 0;
                while (elementForTextSelection.parentNode && (levelCounter < parentLevel))
                {
                    elementForTextSelection = elementForTextSelection.parentNode;
                    levelCounter++;
                }

                var range = document.createRange();
                range.selectNode(elementForTextSelection);
                window.getSelection().removeAllRanges();
                window.getSelection().addRange(range);

                // return length of selection
                window.getSelection().toString().length
            ".arg(leafElementName).arg(parentLevel);

            webview.runJavaScript(commandSetTextSelection,
                function(result) {
                    console.log("the length of selection is now " + result)
                    contextMenuController.selectedTextLength = result
                    contextMenuController.textSelectionLevels.pop()
                    contextMenuController.textSelectionLevelsChanged()
                    console.log("contextMenuController.textSelectionLevels is now " + JSON.stringify(contextMenuController.textSelectionLevels))
                    contextMenuController.textSelectionIsAtRootLevel = false
                });
        }
    }

    // Creates and handles zoom menu, control and autofit logic.
    ZoomControls {
      id: zoomMenu
    }

    onFullScreenRequested: function(request) {
        if (request.toggleOn) {
          // twice because of QTBUG-84313
          webview.zoomFactor = 1.0;
          webview.zoomFactor = 1.0;
        } else {
          webview.zoomController.refresh();
        }
        request.accept();
    }

    onLoadingChanged: {
        // not about current url (e.g. finished loading of page we have already navigated away from)
        if (loadRequest.url !== webview.url) {
            return;
        }

        if (loadRequest.status === WebEngineLoadRequest.LoadFailedStatus) {
            if (loadRequest.errorCode < 0) { // Positive errorCode means HTTP error
                /*
                 * This intends to remove Chromium's error page. Ideally, we could set
                 * webView.settings.errorPageEnabled = false and we wouldn't have to do
                 * this. However, we can't do that since we need Chromium's error page for
                 * HTTP error, where we can't detect ourselve if the server has served
                 * a custom error page or not. That means we have to leave errorPageEnabled
                 * as true (the default), and instead do this only when we need.
                 */
                webview.runJavaScript("if (document.documentElement) {document.removeChild(document.documentElement);}")
            }
        }

        if ((loadRequest.status === WebEngineLoadRequest.LoadSucceededStatus) && ! UrlUtils.isPdfViewerExtensionUrl(webview.url)) {
           webview.runJavaScript("document.contentType", function(docContentType) {
               if (docContentType === "application/pdf") {
                   // ToDo: decide how we handle PDFs:
                   // - ask the user if the file should be viewn / downloaded ?
                   // - both download the PDF and show the preview ?
                   // - create a user setting ?
                   webview.goBack();
                   if (!webview.isWebApp) {
                       browser.closeCurrentTab()
                   }
               }
           });
        }
    }

    // https://github.com/ubports/morph-browser/issues/92
    // this is not perfect, because if the user types very quickly after entering the field, the first typed letter can be missing
    // but without it removing any text (especially for textareas / multiple lines) would remove already typed text and replace it
    // by the last commited word ...
    Timer {
      id: inputMethodTimer
      interval: 500
      onTriggered: {
          Qt.inputMethod.reset()
      }
    }

   // the keyboard is already open, but its type changes
   // e.g. focus is in address bar, then the user clicks in a text field
   onActiveFocusChanged: {
       if (webview.activeFocus && ! inputMethodTimer.running && Qt.inputMethod.visible)
       {
           inputMethodTimer.restart()
       }
   }

   Connections {
       // user clicks in a browser text field, the keyboard is not yet open
       target: Qt.inputMethod
       onVisibleChanged: {
         if (visible && ! inputMethodTimer.running) {
           inputMethodTimer.restart()
         }
       }
    }
}
