/*
 * This file is part of system-settings
 *
 * Copyright (C) 2013-2016 Canonical Ltd.
 *
 * Contact: Didier Roche <didier.roches@canonical.com>
 *          Diego Sarmentero <diego.sarmentero@canonical.com>
 *          Jonas G. Drange <jonas.drange@canonical.com>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtQuick.Layouts 1.1
import SystemSettings 1.0
import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.3 as ListItem
import Lomiri.Components.Popups 1.3
import Lomiri.SystemSettings.Update 1.0
import Lomiri.Connectivity 1.0
import "i18nd.js" as I18nd

ItemPage {
    id: root
    objectName: "systemUpdatesPage"

    header: PageHeader {
        title: I18nd.tr("Updates")
        flickable: scrollWidget

        trailingActionBar.actions: [
            Action {
                iconName: "settings"
                text: I18nd.tr("Update settings")
                onTriggered: {
                    onClicked: pageStack.addPageToNextColumn(
                        root, Qt.resolvedUrl("UpdateSettings.qml"))
                }
            },
            Action {
                iconName: "delete"
                text: i18n.tr("Clear updates")
                onTriggered: {
                    var dialog = PopupUtils.open(clearDialog, root, {})
                    dialog.canceled.connect(function() {
                        PopupUtils.close(dialog)
                    });
                    dialog.accepted.connect(function() {
                        PopupUtils.close(dialog)
                        UpdateManager.reset()
                        releaseUpgradeManager.check(/* force */ true)
                    });
                }
            },
            Action {
                iconName: "reload"
                text: i18n.tr("Check for updates")
                onTriggered: {
                    check(true)
                }
            }
        ]
    }


    property bool batchMode: false
    property bool havePower: (Battery.state === Battery.Charging) ||
                             (Battery.batteryLevel > 25)
    property bool online: NetworkingStatus.online
    property bool forceCheck: false

    property int updatesCount: {
        var count = 0;
        count += clickRepeater.count;
        count += imageRepeater.count;
        return count;
    }

    function check(force) {
        if (force === true) {
            UpdateManager.check(UpdateManager.CheckAll);
        } else {
            if (imageRepeater.count === 0 && clickRepeater.count === 0) {
                UpdateManager.check(UpdateManager.CheckAll);
            } else {
                // Only check 30 minutes after last successful check.
                UpdateManager.check(UpdateManager.CheckIfNecessary);
            }
        }

        releaseUpgradeManager.check(force);
    }

    ReleaseUpgradeManager {
        id: releaseUpgradeManager
    }

    Component {
         id: clearDialog

        Dialog {
            id: dialog

            title: i18n.tr("Clear updates")
            text: i18n.tr("Clear the update list?")

            signal accepted()
            signal canceled()

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: units.gu(2)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: units.gu(4)
                    Button {
                        text: i18n.tr("Cancel")
                        onClicked: dialog.canceled()
                    }
                    Button {
                        text: i18n.tr("Clear")
                        color: theme.palette.normal.negative
                        onClicked: dialog.accepted()
                    }
                }
            }
        }
    }

    DownloadHandler {
        id: downloadHandler
        updateModel: UpdateManager.model
    }

    Flickable {
        id: scrollWidget
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: configuration.top
        }
        clip: true
        contentHeight: content.height
        boundsBehavior: (contentHeight > parent.height) ?
                        Flickable.DragAndOvershootBounds :
                        Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: content
            anchors { left: parent.left; right: parent.right }

            GlobalUpdateControls {
                id: glob
                objectName: "global"
                anchors { left: parent.left; right: parent.right }

                height: hidden ? 0 : units.gu(8)
                clip: true
                status: UpdateManager.status
                batchMode: root.batchMode
                requireRestart: imageRepeater.count > 0
                updatesCount: root.updatesCount
                online: root.online
                onStop: UpdateManager.cancel()

                onRequestInstall: {
                    if (requireRestart) {
                        var popup = PopupUtils.open(
                            Qt.resolvedUrl("ImageUpdatePrompt.qml"), null, {
                                havePowerForUpdate: root.havePower
                            }
                        );
                        popup.requestSystemUpdate.connect(function () {
                            install();
                        });
                    } else {
                        install();
                    }
                }
                onInstall: {
                    root.batchMode = true
                    if (requireRestart) {
                        postAllBatchHandler.target = root;
                    } else {
                        postClickBatchHandler.target = root;
                    }
                }
            }

            Rectangle {
                id: overlay
                objectName: "overlay"
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    right: parent.right
                    rightMargin: units.gu(2)
                }
                // Block OTA
                // visible: placeholder.text
                visible: false
                // End
                color: theme.palette.normal.background
                height: units.gu(10)

                Label {
                    id: placeholder
                    objectName: "overlayText"
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: {
                        var s = UpdateManager.status;
                        if (!root.online) {
                            return I18nd.tr("Connect to the Internet to check for updates.");
                        } else if (s === UpdateManager.StatusIdle &&
                                   !updatesAvailableHeader.visible)
                        {
                            return I18nd.tr("Software is up to date");
                        } else if (s === UpdateManager.StatusServerError ||
                                   s === UpdateManager.StatusNetworkError) {
                            return I18nd.tr("The update server is not responding. Try again later.");
                        }
                        return "";
                    }
                }
            }

            SettingsItemTitle {
                id: updatesAvailableHeader
                text: I18nd.tr("Updates Available")
                visible: imageUpdateCol.visible ||
                         clickUpdatesCol.visible ||
                         releaseUpgradeItem.visible
            }

            // Block OTA
            Label {
                anchors { left: parent.left; right: parent.right; margins: units.gu(2) }
                font.bold: true
                color: theme.palette.normal.negative
                text: "OTA updates are being blocked by Ambot/Jerk Installer to avoid possible conflicts between the new OTA update and your installed packages. \
                        \n\nReset all components or uninstall all packages to unblock OTA updates. You can reinstall them again after the update. \
                        \n\nvia Ambot Installer app:\
                        \n - Actions > Reset Components > All Components \
                        \nvia Jerk Installer script: \
                        \n - Run 'jerk reset all' \
                        \n\nOr simply unblock OTA at the risk of encountering conflicts and rendering your device unusable until you reflash a clean system\
                        \n\nvia Ambot Installer app:\
                        \n - Actions > OTA Updates > Unblock \
                        \nvia Jerk Installer script: \
                        \n -Run 'jerk unblock-ota'"
                wrapMode: Text.WordWrap
            }
            // End

            ColumnLayout {
                id: releaseUpgradeItem
                anchors {
                    left: parent.left
                    right: parent.right
                }
                spacing: units.gu(2)

                // Block OTA
                visible: false
                /*
                visible: releaseUpgradeManager.availableUpgrade &&
                         updatesCount == 0 &&
                         online
                */
                // End

                Icon {
                    name: "distributor-logo"
                    width: units.gu(10)
                    height: width
                    Layout.alignment: Qt.AlignHCenter

                    LomiriShape {
                        anchors {
                            bottom: parent.bottom
                            bottomMargin: units.gu(-1.5)
                            right: parent.right
                            rightMargin: units.gu(-1.5)
                        }
                        width: units.gu(4)
                        height: width
                        backgroundColor: theme.palette.normal.positive
 
                        Icon {
                            width: units.gu(3)
                            height: width
                            anchors {
                                bottom: parent.bottom
                                bottomMargin: units.gu(0.5)
                                right: parent.right
                                rightMargin: units.gu(0.5)
                            }

                            name: "save"
                            color: theme.palette.normal.positiveText
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: units.gu(2)
                    Layout.rightMargin: units.gu(2)

                    Label {
                        Layout.fillWidth: true
                        text: releaseUpgradeManager.availableUpgrade
                            // TRANSLATORS: %1 is OS name e.g. "Ubuntu Touch",
                            // %2 is OS version e.g. "24.04-1.0 RC 3".
                            ? I18nd.tr("%1 %2")
                                .arg("Ubuntu Touch") // TODO: don't hardcode this.
                                .arg(releaseUpgradeManager.availableUpgradeVersion)
                            : ''
                        wrapMode: Text.Wrap
                        textSize: Label.Large
                    }

                    Button {
                        id: releaseUpgradeBtn
                        Layout.alignment: Qt.AlignHCenter
                        text: I18nd.tr("Upgrade");
                        color: theme.palette.normal.positive
                        onClicked: {
                            releaseUpgradeBtn.enabled = false;
                            releaseUpgradeManager.startUpgrade().then(
                            function () {
                                // Normally this won't be visible, as the entry
                                // should be replaced by normal update by then.
                                // But if s-i-dbus stops in between, we want to
                                // be able to re-trigger this.
                                releaseUpgradeBtn.enabled = true;
                            }).catch(function(error) {
                                // TODO: there's not really an error handling...
                                console.error(error);
                                releaseUpgradeBtn.enabled = true;
                            });
                        }
                    }
                }

                ActivityIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    visible: releaseUpgradeManager.releaseHighlight === null
                    running: visible
                }

                Label {
                    id: releaseUpgradeHighlight

                    Layout.fillWidth: true
                    Layout.leftMargin: units.gu(2)
                    Layout.rightMargin: units.gu(2)

                    visible: releaseUpgradeManager.releaseHighlight &&
                             releaseUpgradeManager.releaseHighlight.length > 0
                    textSize: Label.Medium
                    wrapMode: Text.WordWrap
                    text: releaseUpgradeManager.releaseHighlight
                    textFormat: Text.StyledText
                    // A blue-ish color that adapts to theme. The same color as
                    // an activity indicator/progress indicator.
                    linkColor: theme.palette.normal.activity

                    onLinkActivated: function (link) {
                        Qt.openUrlExternally(link);
                    }
                }

                // A wrapper item to put ThinDivider into a Layout, as it sets
                // anchors implicitly.
                Item {
                    Layout.fillWidth: true
                    
                    ListItem.ThinDivider {}
                }
            }

            Column {
                id: imageUpdateCol
                objectName: "imageUpdates"
                anchors { left: parent.left; right: parent.right }
                // Block OTA
                visible: false
                /*
                visible: {
                    var s = UpdateManager.status;
                    var haveUpdates = imageRepeater.count > 0;
                    switch (s) {
                    case UpdateManager.StatusCheckingClickUpdates:
                    case UpdateManager.StatusIdle:
                        return haveUpdates && online;
                    }
                    return false;
                }
                */
                // End

                Repeater {
                    id: imageRepeater
                    model: UpdateManager.imageUpdates

                    delegate: UpdateDelegate {
                        objectName: "imageUpdatesDelegate-" + index
                        width: imageUpdateCol.width
                        updateState: model.updateState
                        progress: model.progress
                        version: remoteVersion
                        size: model.size
                        changelog: model.changelog
                        error: model.error
                        kind: model.kind
                        iconUrl: model.iconUrl
                        name: title

                        onResume: download()
                        onRetry: download()
                        onDownload: {
                            if (SystemImage.downloadMode < 2) {
                                SystemImage.downloadUpdate();
                                SystemImage.forceAllowGSMDownload();
                            } else {
                                SystemImage.downloadUpdate();
                            }
                        }
                        onPause: SystemImage.pauseDownload();
                        onInstall: {
                            var popup = PopupUtils.open(
                                Qt.resolvedUrl("ImageUpdatePrompt.qml"), null, {
                                    havePowerForUpdate: root.havePower
                                }
                            );
                            popup.requestSystemUpdate.connect(SystemImage.applyUpdate);
                        }
                    }
                }
            }

            Column {
                id: clickUpdatesCol
                objectName: "clickUpdates"
                anchors { left: parent.left; right: parent.right }
                visible: {
                    var s = UpdateManager.status;
                    var haveUpdates = clickRepeater.count > 0;
                    switch (s) {
                    case UpdateManager.StatusCheckingImageUpdates:
                    case UpdateManager.StatusIdle:
                        return haveUpdates && online;
                    }
                    return false;
                }

                Repeater {
                    id: clickRepeater
                    model: UpdateManager.clickUpdates

                    delegate: ClickUpdateDelegate {
                        objectName: "clickUpdatesDelegate" + index
                        width: clickUpdatesCol.width
                        updateState: model.updateState
                        progress: model.progress
                        version: remoteVersion
                        size: model.size
                        name: title
                        iconUrl: model.iconUrl
                        kind: model.kind
                        changelog: model.changelog
                        error: model.error
                        signedUrl: signedDownloadUrl

                        onInstall: downloadHandler.createDownload(model);
                        onPause: downloadHandler.pauseDownload(model)
                        onResume: downloadHandler.resumeDownload(model)
                        onRetry: {
                            /* This creates a new signed URL with which we can
                            retry the download. See onSignedUrlChanged. */
                            UpdateManager.retry(model.identifier,
                                               model.revision);
                        }

                        onSignedUrlChanged: {
                            // If we have a signedUrl, user intend to retry.
                            if (signedUrl) {
                                downloadHandler.retryDownload(model);
                            }
                        }

                        Connections {
                            target: glob
                            onInstall: install()
                        }

                        /* If we a downloadId, we expect LDM to restore it
                        after some time. Workaround for lp:1603770. */
                        Timer {
                            id: downloadTimeout
                            interval: 30000
                            running: true
                            onTriggered: {
                                var s = updateState;
                                if (model.downloadId
                                    || s === Update.StateQueuedForDownload
                                    || s === Update.StateDownloading) {
                                    downloadHandler.assertDownloadExist(model);
                                }
                            }
                        }
                    }
                }
            }

            SettingsItemTitle {
                text: I18nd.tr("Recent updates")
                visible: installedCol.visible
            }

            Column {
                id: installedCol
                objectName: "installedUpdates"
                anchors { left: parent.left; right: parent.right }
                visible: installedRepeater.count > 0

                Repeater {
                    id: installedRepeater
                    model: UpdateManager.installedUpdates

                    delegate: UpdateDelegate {
                        objectName: "installedUpdateDelegate-" + index
                        width: installedCol.width
                        version: remoteVersion
                        size: model.size
                        name: title
                        kind: model.kind
                        iconUrl: model.iconUrl
                        changelog: model.changelog
                        updateState: Update.StateInstalled
                        updatedAt: model.updatedAt

                        leadingActions: ListItemActions {
                           actions: [
                               Action {
                                    iconName: "delete"
                                    onTriggered: UpdateManager.remove(
                                        model.identifier, model.revision
                                    )
                               }
                           ]
                        }

                        // Launchable if there's a package name on a click.
                        launchable: (!!packageName &&
                                     model.kind === Update.KindClick)

                        onLaunch: UpdateManager.launch(identifier, revision);
                    }
                }
            }
        } // Column inside flickable.
    } // Flickable

    Column {
        id: configuration

        height: childrenRect.height

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
    }

    Connections {
        id: postClickBatchHandler
        ignoreUnknownSignals: true
        target: null
        onUpdatesCountChanged: {
            if (target.updatesCount === 0) {
                root.batchMode = false;
                target = null;
            }
        }
    }

    Connections {
        id: postAllBatchHandler
        ignoreUnknownSignals: true
        target: null
        onUpdatesCountChanged: {
            if (target.updatesCount === 1) {
                SystemImage.updateDownloaded.connect(function () {
                    SystemImage.applyUpdate();
                });
                SystemImage.downloadUpdate();
            }
        }
    }

    Connections {
        target: NetworkingStatus
        onOnlineChanged: {
            if (!online) {
                UpdateManager.cancel();
            } else {
                UpdateManager.check(UpdateManager.CheckAll);
            }
        }
    }

    Connections {
        target: SystemImage
        onUpdateFailed: {
            if (consecutiveFailureCount > SystemImage.failuresBeforeWarning) {
                var popup = PopupUtils.open(
                    Qt.resolvedUrl("InstallationFailed.qml"), null, {
                        text: lastReason
                    }
                );
            }
        }
    }

    Component.onCompleted: check()
}
