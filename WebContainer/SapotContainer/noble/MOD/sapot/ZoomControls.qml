import QtQuick 2.5
import Lomiri.Components 1.3                  // For LomiriShape.
import QtWebEngine 1.7
import webbrowsercommon.private 0.1           // For DomainSettingsModel singleton.
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Controls.Suru 2.2
import QtQuick.Layouts 1.12

// ZoomControls object to provide zoom menu, control and autofit logic for WebViewImpl.
// Scope requirements:
//     webview:             An WebViewImpl object for zoomFactor manipulation and signal bindings.
//     browser (or webapp): An Browser (or WebApp) object for settings operations.
QQC2.Dialog {
    id: zoomControls
    objectName: "zoomActions"

    property bool incognito: false
    readonly property alias controller: controller
    readonly property bool displayedBottom: y >= parent.height / 2
    readonly property string resetZoomShortCutText: shortcutResetZoom.nativeText

    title: i18n.tr("Current Zoom") + ": " + " %1".arg(controller.viewSpecificZoom ? i18n.tr("Domain") 
                                                                    : (controller.currentZoomFactor === controller.defaultZoomFactor ? i18n.tr("Default") 
                                                                                                                                : i18n.tr("Auto-fit")))
    width: units.gu(40)
    height: units.gu(13)

    x: browser.wide ? webview.width - width - units.gu(3) : (webview.width - width) / 2
    y: browser.wide ? units.gu(3) : webview.height - height - units.gu(3)

    function timedDisplay() {
        if (!zoomControls.opened) {
            open()
            delayHide.restart()
        }
    }

    Timer {
        id: delayHide

        interval: 3000
        running: false
        onTriggered: {
            zoomControls.close()
        }
    }

    RowLayout {
        id: zoomActionsRow

        anchors {
            left: parent ? parent.left : undefined
            top: parent ? parent.top : undefined
            right: parent ? parent.right : undefined
        }

        ZoomSpinBox {
            Layout.fillWidth: true
            Layout.preferredHeight: units.gu(5)

            controller: zoomControls.controller

            onValueModified: delayHide.stop()
        }

        QQC2.Button {
            Layout.preferredHeight: units.gu(5)
            Layout.preferredWidth: units.gu(5)

            enabled: controller.resetAvailable
            icon.name: "reset"
            icon.height: units.gu(2)
            icon.width: units.gu(2)
            rightPadding: 0
            leftPadding: 0
            flat: true

            onClicked: {
                controller.resetSaveFit()
                delayHide.stop()
            }
        }

        QQC2.Button {
            Layout.preferredHeight: units.gu(5)
            Layout.preferredWidth: units.gu(5)

            enabled: controller.saveAvailable
            icon.name: "save"
            icon.height: units.gu(2)
            icon.width: units.gu(2)
            rightPadding: 0
            leftPadding: 0
            flat: true

            onClicked: {
                controller.save(zoomControls.displayedBottom)
                delayHide.stop()
            }
        }
    }

    QtObject {
        id: controller

        // Contains domain, or scheme if webview.url has no domain.
        readonly property string currentDomain: UrlUtils.hostIs(webview.url, "") ? "scheme:" + UrlUtils.extractScheme(webview.url) : UrlUtils.extractHost(webview.url)

        readonly property real defaultZoomFactor: browser.settings ? browser.settings.zoomFactor : webapp.settings.zoomFactor
        readonly property real minZoomFactor: 0.25
        readonly property real maxZoomFactor: 5.0
        readonly property alias currentZoomFactor: internal.currentZoomFactor
        readonly property alias viewSpecificZoom: internal.viewSpecificZoom

        readonly property bool autoFitToWidthEnabled: browser.settings ? browser.settings.autoFitToWidthEnabled : webapp.settings.autoFitToWidthEnabled
        readonly property real fitToWidthZoomFactor: internal.currentDomainScrollWidth > 0 ? Math.max(minZoomFactor, Math.min(maxZoomFactor, Math.floor((webview.width / internal.currentDomainScrollWidth) * 100) / 100)) : NaN

        readonly property bool currentNotDefaultZoom: Math.abs(currentZoomFactor - defaultZoomFactor) >= 0.01

        readonly property bool domainSaveAvailable: webview.incognito === false 
                    && (isNaN(internal.currentDomainZoomFactor) || Math.abs(currentZoomFactor - internal.currentDomainZoomFactor) >= 0.01)
        readonly property bool defaultSaveAvailable: currentNotDefaultZoom
        readonly property bool saveAvailable: domainSaveAvailable || defaultSaveAvailable
        readonly property bool resetAvailable: viewSpecificZoom || currentNotDefaultZoom

        signal zoomModified

        function zoomIn(showMenu) {
            internal.viewSpecificZoom = true;
            internal.currentZoomFactor = Math.min(maxZoomFactor, currentZoomFactor + ((Math.round(currentZoomFactor * 100) % 10 === 0) ? 0.1 : 0.1 - (currentZoomFactor % 0.1)));
            saveZoomFactorForCurrentDomain();

            internal.updateFitToWidthTimer.stop();
            zoomModified();
            
            if (showMenu) {
                timedDisplay()
            }
        }

        function resetSaveFit() {
            internal.viewSpecificZoom = false;
            internal.currentZoomFactor = defaultZoomFactor;
            saveZoomFactorForCurrentDomain();

            internal.updateFitToWidthTimer.stop();
            internal.currentDomainScrollWidth = 0;
            internal.updateFitToWidth();
        }

        function zoomOut(showMenu) {
            internal.viewSpecificZoom = true
            internal.currentZoomFactor = Math.max(minZoomFactor, currentZoomFactor - ((Math.round(currentZoomFactor * 100) % 10 === 0) ? 0.1 : currentZoomFactor % 0.1));
            saveZoomFactorForCurrentDomain();

            internal.updateFitToWidthTimer.stop();
            zoomModified();

            if (showMenu) {
                timedDisplay()
            }
        }

        function save(displayAtBottom) {
            internal.saveDialog = saveDialogComponent.createObject(webview)
            if (displayAtBottom) {
                internal.saveDialog.openBottom();
            } else {
                internal.saveDialog.openNormal();
            }
        }

        function saveZoomFactorForCurrentDomain() {
            if (webview.incognito) {
                return;
            }

            if (viewSpecificZoom) {
                DomainSettingsModel.setZoomFactor(currentDomain, currentZoomFactor);
            }
            else {
                DomainSettingsModel.setZoomFactor(currentDomain, NaN);
            }
        }

        function refresh() {
            internal.setWebviewZoomFactor(controller.currentZoomFactor);
        }

        // If current domain has changed, we have to forget about previous zoom factors and update page zoom.
        // This also means, that loading is in progress, fit to widt updates will be done there.
        onCurrentDomainChanged: {
            //console.log("[ZC] controller.onCurrentDomainChanged triggered: %1".arg(controller.currentDomain));
            internal.updateFitToWidthTimer.stop();
            internal.currentDomainScrollWidth = 0;
            internal.updatePageZoom();
        }

        // To keep webview.zoomFactor in sync with currentZoomFactor.
        onCurrentZoomFactorChanged: {
            //console.log("[ZC] controller.onCurrentZoomFactorChanged: %1".arg(controller.currentZoomFactor));
            internal.setWebviewZoomFactor(controller.currentZoomFactor);
        }
    }

    // Popup dialog for saving in zoom menu.
    Component {
        id: saveDialogComponent

        BaseDialog {
            id: saveDialog
            objectName: "saveZoomFactorDialog"

            readonly property string saveDomainText: saveDomainButton.enabled ? 
                        i18n.tr("Domain zoom (currently %1 and can be removed with reset button or from domain specific settings in privacy settings)"
                                        .arg(isNaN(internal.currentDomainZoomFactor) 
                                                        ? i18n.tr("none") : Math.round(internal.currentDomainZoomFactor * 100) + "%"))
                                : ""
            readonly property string saveDefaultText: saveDefaultButton.enabled 
                        ? i18n.tr("Default zoom (currently %1%, can be changed from settings menu%2)"
                                        .arg(Math.round(controller.defaultZoomFactor * 100)).arg(controller.viewSpecificZoom ? i18n.tr(" and resets domain zoom") : ""))
                                : ""

            title: i18n.tr("Save Zoom Setting")
            standardButtons: QQC2.Dialog.NoButton
            height: contentColumn.height + units.gu(12)

            onClosed: destroy()

            ColumnLayout {
                id: contentColumn

                spacing: Suru.units.gu(3)
                anchors {
                    top: parent.top
                    topMargin: Suru.units.gu(2)
                    left: parent.left
                    right: parent.right
                }

                Label {
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    text: i18n.tr("Current zoom (%1%) can be saved as:").arg(Math.round(controller.currentZoomFactor * 100)) + "\n\n"
                        + saveDomainText
                        + (saveDomainButton.enabled && saveDefaultButton.enabled ? "\n\n" + i18n.tr("or") + "\n\n": "")
                        + saveDefaultText
                        + "."
                }

                ColumnLayout {
                    spacing: units.gu(2)
                    Layout.fillWidth: true
                    Layout.leftMargin: units.gu(2)
                    Layout.rightMargin: units.gu(2)

                    Button {
                        id: saveDomainButton
                        objectName: "saveDomainButton"

                        Layout.fillWidth: true

                        text: i18n.tr("Save as Domain Zoom")
                        color: theme.palette.normal.positive
                        enabled: controller.domainSaveAvailable
                        visible: enabled

                        onClicked: {
                            internal.viewSpecificZoom = true;
                            controller.saveZoomFactorForCurrentDomain();
                            saveDialog.close();
                        }
                    }

                    Button {
                        id: saveDefaultButton
                        objectName: "saveDefaultButton"

                        Layout.fillWidth: true

                        text: i18n.tr("Save as Default Zoom")
                        enabled: controller.defaultSaveAvailable
                        visible: enabled

                        onClicked: {
                            if (browser.settings) {
                                browser.settings.zoomFactor = controller.currentZoomFactor;
                            }
                            else {
                                webapp.settings.zoomFactor = controller.currentZoomFactor;
                            }
                            internal.viewSpecificZoom = false;
                            controller.saveZoomFactorForCurrentDomain();
                            saveDialog.close();
                        }
                    }

                    Button {
                        objectName: "cancelButton"

                        Layout.fillWidth: true

                        text: i18n.tr("Cancel")
                        onClicked: {
                            saveDialog.close();
                        }
                    }
                }
            }
        }
    }

    // Internal states, functions and bindings/connecions.
    QtObject {
        id: internal

        property bool viewSpecificZoom: false
        property real currentZoomFactor: controller.defaultZoomFactor

        property int currentDomainScrollWidth: 0
        property real currentDomainZoomFactor: NaN

        property bool refreshZoomOnWebViewVisible: false
        property bool anyPageLoaded: false

        property var saveDialog

        // Resets scroll width, reloads page zoom and updates fit to width.
        // Or flags for update after visible, if not visible.
        function resetAndUpdate() {
            //console.log("[ZC] internal.resetAndUpdate called");
            internal.updateFitToWidthTimer.stop();
            internal.currentDomainScrollWidth = 0;

            // We need to adjust zoom settings now, or in the future.
            if (webview.visible === false) {
                //console.log("[ZC]   webview not visible");
                // Webview is not visible, flag to update after visible and return.
                internal.refreshZoomOnWebViewVisible = true;
                return;
            }

            // Adjust zoom settings according to domainZoomFactor, compute fitToWidthZoomFactor and fit if conditions met.
            internal.updatePageZoom();
            internal.updateFitToWidth();
        }

        function updatePageZoom() {
            //console.log("[ZC] internal.updatePageZoom called: %1".arg(controller.currentDomain));
            internal.currentDomainZoomFactor = DomainSettingsModel.getZoomFactor(controller.currentDomain);
            if (isNaN(internal.currentDomainZoomFactor) ) {
                internal.viewSpecificZoom = false;
                if (controller.autoFitToWidthEnabled && internal.currentDomainScrollWidth !== 0) {
                    internal.currentZoomFactor = controller.fitToWidthZoomFactor;
                }
                else {
                    internal.currentZoomFactor = controller.defaultZoomFactor;
                }
            }
            else {
                internal.viewSpecificZoom = true;
                internal.currentZoomFactor = internal.currentDomainZoomFactor;
            }
            //console.log("[ZC]   viewSpecificZoom: %1".arg(controller.viewSpecificZoom));
            //console.log("[ZC]   currentZoomFactor: %1".arg(controller.currentZoomFactor));
        }

        function setWebviewZoomFactor(newZoomFactor) {
            if (Math.abs(webview.zoomFactor - newZoomFactor) > 0.01) {
               //https://bugreports.qt.io/browse/QTBUG-84313
               // zoom is not set reliably on the first change
               // set it twice so that changes are not ignored
               webview.zoomFactor = newZoomFactor;
               webview.zoomFactor = newZoomFactor;
            }
        }

        function updateFitToWidth() {
            //console.log("[ZC] internal.updateFitToWidth called");

            if (controller.autoFitToWidthEnabled === false || controller.viewSpecificZoom === true) {
                //console.log("[ZC]   autofit not enabled or specific zoom is set");
                // Not doing automatic fit to width.
                return;
            }

            if (internal.currentDomainScrollWidth !== 0) {
                //console.log("[ZC]   scroll width allready retrieved");
                // Fit to width was allready handled for this domain, so don't continue.
                return;
            }

            if (internal.anyPageLoaded === false) {
                //console.log("[ZC]   no page was loaded");
                // No page loaded, we are in "greeter", don't need to update fit to width.
                return;
            }

            if (webview.loading === true) {
                //console.log("[ZC]   webview is currently loading");
                // If webview is currently loading a page, no need to refresh fit, cause it will be refreshed after loading.
                return;
            }

            //console.log("[ZC]   zooming to default and autofitting");
            // Automatic fit to width is done from defaultZoomFactor
            internal.setWebviewZoomFactor(controller.defaultZoomFactor);
            // Wait, to be sure that any page layout change (css, js, ...) after previous zoom or width change takes effect.
            internal.updateFitToWidthTimer.restart();
        }

        // This timer is here because, if we want to fit to page's scrollWidth after some zoom factor change, we have to wait for css, js and other stuff on page to adjust an then fit.
        property Timer updateFitToWidthTimer: Timer {
            interval: 500
            running: false
            repeat: false

            // Determine page's scrollWidth, save it to currentDomainScrollWidth.
            // If automatic fit to width conditions are met, set zoomFactor to fit to width.
            // Keep in mind that webview.zoomFactor might be diffrent than controller.currentZoomFactor, so we have to sync them upon exit.
            onTriggered: {
                //console.log("[ZC] internal.updateFitToWidthTimer triggered");
                webview.runJavaScript("document && document.body ? document.body.scrollWidth : null", function(width) {
                    //console.log("[ZC]   body.scrollWidth: %1".arg(width));
                    if (width === null || width <= 0) {
                        //console.log("[ZC]   no scrollWidth");
                        // Sync zoom factors in case they are out of sync.
                        internal.setWebviewZoomFactor(controller.currentZoomFactor);
                        return;
                    }

                    internal.currentDomainScrollWidth = width;
                    //console.log("[ZC]   fitToWidthZoomFactor: %1".arg(controller.fitToWidthZoomFactor));

                    // If fitToWidthZoomFactor is to close to currentZoomFactor, don't bother to fit.
                    if (Math.abs(controller.currentZoomFactor - controller.fitToWidthZoomFactor) < 0.1) {
                        //console.log("[ZC]   not autofitting, close to currentZoomFactor");
                        // Sync zoom factors in case they are out of sync.
                        internal.setWebviewZoomFactor(controller.currentZoomFactor);
                        return;
                    }

                    // Adjust zoom factor to fit to page's scrollWidth.
                    internal.currentZoomFactor = controller.fitToWidthZoomFactor;
                });
            }
        }

        property Connections webviewConnections: Connections {
            target: webview

            // Width has changed. If currentDomainScrollWidth was retrieved up until now, it no loger is valid.
            onWidthChanged: {
                //console.log("[ZC] webview.onWidthChanged triggered: %1".arg(webview.width));

                if (internal.anyPageLoaded === false) {
                    //console.log("[ZC]   no page was loaded")
                    // No need for any retrieval, no page was loaded, we are in greeter screen.
                    return;
                }

                // Since page width changed, the scroll width is probably not valid anymore and needs to be reevaluated in future.
                internal.updateFitToWidthTimer.stop();
                internal.currentDomainScrollWidth = 0;

                if (webview.visible === false) {
                    //console.log("[ZC]   webview not visible, setting flag to refresh after visible and skipping fit to width");
                    internal.refreshZoomOnWebViewVisible = true;
                    return;
                }

                internal.updateFitToWidth();
            }

            // A page loading status has been changed. If it is our current page and the status is a LoadSucceededStatus, then now is our time to handle autofit or retrieve scroll width if oom menu is visible.
            onLoadingChanged: {
                //console.log("[ZC] webview.onLoadingChanged: %1".arg(webview.url));
                //console.log("[ZC]   webview.loading: %1".arg(webview.loading));

                // Not our current url (e.g. finished loading of page we have already navigated away from).
                if (loadRequest.url !== webview.url) {
                    return;
                }

                if (loadRequest.status !== WebEngineLoadRequest.LoadSucceededStatus) {
                    return;
                }

                // Our current page loading succeeded.
                //console.log("[ZC]   webview.onLoadingChanged: LoadSucceeded");
                internal.anyPageLoaded = true;

                // This is a workaround, because sometimes a page is not zoomed after loading (happens after manual url change),
                // although the webview.zoomFactor (and currentZoomFactor) is correctly set.
                internal.setWebviewZoomFactor(controller.currentZoomFactor);
                // End of workaround.

                if (webview.visible === false) {
                    //console.log("[ZC]   webview not visible, setting flag to refresh after visible and skipping fit to width");
                    internal.refreshZoomOnWebViewVisible = true;
                    return;
                }

                internal.updateFitToWidth();
            }

            // Page visibility changed. If page is currently visible, check if there is a need for fit to widh updates.
            onVisibleChanged: {
                //console.log("[ZC] webview.onVisibleChanged triggered: %1 (%2)".arg(webview.visible).arg(webview.url));
                if (internal.anyPageLoaded === false) {
                    //console.log("  no page was loaded")
                    return;
                }
                if (webview.visible === true && internal.refreshZoomOnWebViewVisible === true) {
                    //console.log("[ZC]   refreshing zoom and fit after visible");
                    internal.refreshZoomOnWebViewVisible = false;

                    // Reload zoom levels for current domain and update fit to width if needed.
                    internal.updatePageZoom();
                    internal.updateFitToWidth();
                }
            }

            onZoomFactorChanged: internal.currentZoomFactor = target.zoomFactor
        }

        property Connections domainSettingsModelConnections: Connections {
            target: DomainSettingsModel

            // If database changed, reload zoomFactor according to new db.
            // This is a workaround. Because if browser runs with previously opened pages (session), the DomainSettingsModel is not initialized yet when onCurrentDomainChanged is trigerred first time. I couldn't figure out, how to initialize DomainSettingsModel prior signaling.
            onDatabasePathChanged: {
                //console.log("[ZC] DomainSettingsModel.onDatabasePathChanged triggered: %1".arg(DomainSettingsModel.databasePath));
                internal.resetAndUpdate();
            }

            // This is mainly here, to handle domain ZoomFactor changes outside this zoom menu (eg. from domain specific settings in privacy settings).
            // Also this trigger on user zoom actions, so sometimes is everything up to date and zoom doesn't need any corrections.
            onDomainZoomFactorChanged: {
                //console.log("[ZC] DomainSettingsModel.onDomainZoomFactorChanged triggered: %1".arg(domain));
                if (domain != controller.currentDomain) {
                    //console.log("[ZC]   not my domain (%1) changed".arg(controller.currentDomain));
                    // Not my current domain changed, nothing to do here.
                    return;
                }

                // Zoom factor for current domain was changed, check if we are up to date with the change.
                internal.currentDomainZoomFactor = DomainSettingsModel.getZoomFactor(controller.currentDomain);
                if (
                    (isNaN(internal.currentDomainZoomFactor) && internal.viewSpecificZoom === false)
                    ||
                    (!isNaN(internal.currentDomainZoomFactor) && internal.viewSpecificZoom === true && internal.currentZoomFactor === internal.currentDomainZoomFactor)
                ) {
                    //console.log("[ZC]   up to date");
                    // Our zoom settings are up to date to domainZoomFactor, nothing to do here.
                    return;
                }

                internal.resetAndUpdate();
            }
        }

        // This is here and not in controller object, because if the binding are set here, they won't trigger on controller property initialization.
        property Connections controllerConnections: Connections {
            target: controller

            // If page uses defaultZoomFactor, refresh zoom and fit to width.
            onDefaultZoomFactorChanged: {
                //console.log("[ZC] controller.onDefaultZoomFactorChanged: %1 (%2)".arg(controller.defaultZoomFactor).arg(webview.url));
                updateAfterDefaultZoomFactorChangedOrAutoFitToWidthEnabledChanged();
            }

            // Changed in settings.
            onAutoFitToWidthEnabledChanged: {
                //console.log("[ZC] controller.onAutoFitToWidthEnabledChanged: %1".arg(controller.autoFitToWidthEnabled));
                updateAfterDefaultZoomFactorChangedOrAutoFitToWidthEnabledChanged();
            }

            function updateAfterDefaultZoomFactorChangedOrAutoFitToWidthEnabledChanged() {
                if (internal.anyPageLoaded === false) {
                    //console.log("[ZC]   no page was loaded")
                    return;
                }

                if (controller.viewSpecificZoom === true) {
                    //console.log("[ZC]   page has specific zoom.")
                    // Page has specific zoom, defaultZoomFactor change has no impact.
                    return;
                }

                // Page is currently in default zoom mode, call resetAndUpdate to change current zoom and handle fit to width.
                internal.resetAndUpdate();
            }
        }
    }

    // Ctrl+Plus: zoom in
    Shortcut {
        sequence: StandardKey.ZoomIn
        onActivated: controller.zoomIn(true)
    }
    // For improved compatibility with qwerty-based keyboard layouts, where "="
    // and "+" are on the same key (see https://launchpad.net/bugs/1624381):
    Shortcut {
        sequence: "Ctrl+="
        onActivated: controller.zoomIn(true)
    }

    // Ctrl+Minus: zoom out
    Shortcut {
        sequence: StandardKey.ZoomOut
        onActivated: controller.zoomOut(true)
    }
    // For improved compatibility with qwerty-based keyboard layouts, where "-"
    // and "_" are on the same key (see https://launchpad.net/bugs/1624381):
    Shortcut {
        sequence: "Ctrl+_"
        onActivated: controller.zoomOut(true)
    }

    // Ctrl+0: reset zoom factor to default
    Shortcut {
        id: shortcutResetZoom
        sequence: "Ctrl+0"
        onActivated: controller.resetSaveFit()
    }
}
