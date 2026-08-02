// ENH210 - Advanced screenshot

// Copy of Components/ItemGrabber.qml

/*
 * Copyright (C) 2014-2016 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12 as QQC2
import Lomiri.Components.Extras 0.2 as Extras
import Lomiri.Content 1.3
import ScreenshotDirectory 0.1
import "Components"

/*
    Captures an image of the given item and saves it in a screenshots directory.
    It also displays a flash visual effect and camera shutter sound, as feedback
    to the user to hint that a screenshot was taken.
 */
Item {
    id: root
    visible: false

    readonly property alias toolbar: toolbarLoader.item
    property bool advancedMode: false
    property real topPanelHeight: 0
    property bool silentMode: false

    ScreenshotDirectory {
        id: screenshotDirectory
        objectName: "screenGrabber"
    }

    NotificationAudio {
        id: shutterSound
        source: "/usr/share/sounds/lomiri/camera/click/camera_click.ogg"
    }

    onVisibleChanged: {
        if (!visible) {
            reset()
        }
    }

    function show() {
        if (advancedMode) {
            toolbarLoader.open()
        }
        visible = true
    }

    function close() {
        visible = false
    }

    function reset() {
        editorLoader.close(false)
        shareLoader.close()
        toolbarLoader.close()
    }

    function capture(item) {
        d.target = item;
        show();
        if (!root.silentMode) {
            shutterSound.stop();
            shutterSound.play();
        }
        fadeIn.start();
    }

    // Eater mouse events
    MouseArea {
        anchors.fill: parent
        enabled: editorLoader.active || shareLoader.active
        hoverEnabled: enabled
        acceptedButtons: Qt.AllButtons
        onWheel: wheel.accepted = true;
    }

    Rectangle {
        id: flashRec

        anchors.fill: parent
        color: "white"
        opacity: 0

        NumberAnimation on opacity {
            id: fadeIn

            from: 0.0
            to: 1.0
            onStopped: {
                if (root.visible) {
                    fadeOut.start();
                }
            }
        }

        NumberAnimation on opacity {
            id: fadeOut
            from: 1.0
            to: 0.0
            onStopped: {
                if (root.visible) {
                    d.target.grabToImage(d.saveScreenshot);

                    if (!root.advancedMode) {
                        root.close();
                    }
                }
            }
        }
    }

    Loader {
        id: editorLoader

        property string fileName: ""

        active: false
        asynchronous: true
        anchors.fill: parent

        function open(_fileName) {
            fileName = _fileName
            active = true
        }

        function close(_showToolbar = true) {
            active = false
            fileName = ""
            toolbar.show(d.fileName, false)
        }

        onLoaded: {
            if (fileName !== "") {
                item.editor.open(fileName)
            }
        }

        sourceComponent: Item {
            property alias editor: photoEditor

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: 0.8
            }

            Page {
                id: editorPage

                readonly property real horizontalMargins: parent.width >= units.gu(180) ? units.gu(4) : 0
                readonly property real verticalMargins: parent.width >= units.gu(180) ? units.gu(4) : 0

                anchors {
                    fill: parent
                    topMargin: verticalMargins + root.topPanelHeight
                    leftMargin: horizontalMargins
                    rightMargin: horizontalMargins
                }

                header: PageHeader {
                    title: i18n.tr("Edit Screenshot")
                    leadingActionBar.actions: [
                        Action {
                            text: i18n.tr("Cancel")
                            iconName: "cancel"
                            onTriggered: photoEditor.close(false)
                        }
                    ]
                    trailingActionBar.actions: [
                        saveAction, ...editorPage.contextActions
                    ]
                }

                // Convert list to JS Array
                property var contextActions: {
                    let _len = photoEditor.actions.length
                    let _arr = []
                    for (let i = 0; i < _len; i++) {
                        _arr.push(photoEditor.actions[i])
                    }

                    return _arr
                }

                Action {
                    id: saveAction

                    text: i18n.tr("Save")
                    iconName: "save"
                    onTriggered: photoEditor.close(true)
                }

                Extras.PhotoEditor {
                    id: photoEditor
                    anchors {
                        fill: parent
                        topMargin: units.gu(2)
                    }
                    onClosed: editorLoader.close()
                }
            }
        }

    }

    

    Loader {
        id: shareLoader

        asynchronous: true
        active: false
        anchors.fill: parent

        function open() {
            active = true
        }

        function close() {
            active = false
            toolbar.close()
        }

        function cancel() {
            active = false
            toolbar.show(d.fileName, false)
        }

        sourceComponent: Item {
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: 0.8
            }

            Page {
                id: sharePage

                property int maxSize: Math.min(parent.width, parent.height)
                property int size: Math.min(maxSize, units.gu(50))

                anchors {
                    fill: parent
                    leftMargin: (parent.width - size) / 2
                    rightMargin: anchors.leftMargin
                    topMargin: parent.width >= units.gu(90) ? (parent.height - size) / 2 : (parent.height - size)
                    bottomMargin: parent.width >= units.gu(90) ? (parent.height - size) / 2 : 0
                }

                header: PageHeader {
                    title: i18n.tr("Share to")
                    leadingActionBar.actions: [
                        Action {
                            text: i18n.tr("Cancel")
                            iconName: "cancel"
                            onTriggered: shareLoader.cancel()
                        }
                    ]
                }

                Component {
                    id: contentItemComp
                    ContentItem {}
                }

                ContentPeerPicker {
                    objectName: "sharePicker"
                    showTitle: false
                    anchors {
                        fill: parent
                        topMargin: units.gu(2)
                    }
                    contentType: ContentType.Pictures
                    handler: ContentHandler.Share

                    onPeerSelected: {
                        var curTransfer = peer.request();
                        if (curTransfer.state === ContentTransfer.InProgress)
                        {
                            curTransfer.items = [ contentItemComp.createObject(parent, {"url": d.fileName}) ];
                            curTransfer.state = ContentTransfer.Charged;
                        }
                        shareLoader.close()
                    }
                    onCancelPressed: {
                        shareLoader.cancel()
                    }
                }
            }
        }
    }

    Loader {
        id: toolbarLoader

        asynchronous: true
        active: false
        visible: opacity > 0
        opacity: 0
        height: units.gu(10)
        width: Math.min(parent.width * 0.8, units.gu(40))
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: units.gu(10)
        }

        function open() {
            active = true
        }

        function close() {
            active = false
        }

        sourceComponent: Item {
            id: toolbarItem

            property bool closeRoot: false

            function show(imageUrl, timeouts = true) {
                snapshot.imageSource = ""
                snapshot.imageSource = imageUrl
                toolbarLoader.opacity = 1

                if (timeouts) {
                    timeoutTimer.restart()
                }
            }

            function hide() {
                closeRoot = false
                toolbarLoader.opacity = 0
                timeoutTimer.stop()
            }

            function close() {
                hide()
                closeRoot =true
            }

            onVisibleChanged: {
                if (!visible && closeRoot) {
                    root.close()
                }
            }

            Behavior on opacity { LomiriNumberAnimation {} }

            Timer {
                id: timeoutTimer
                interval: 5000
                onTriggered: toolbarItem.close()
            }

            InverseMouseArea {
               anchors.fill: parent
               acceptedButtons: Qt.LeftButton
               onPressed: {
                   toolbarItem.close()
               }
            }

            Rectangle {
                id: toolbarRec

                color: theme.palette.normal.foreground
                opacity: 0.9
                radius: units.gu(3)
                anchors.fill: parent
            }
            
            // Border
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: toolbarRec.radius
                border {
                    color: theme.palette.normal.activity
                    width: units.dp(1)
                }
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: toolbarRec.radius
                    rightMargin: toolbarRec.radius
                }

                LomiriShape {
                    id: snapshot

                    property url imageSource

                    Layout.fillHeight: true
                    Layout.topMargin: units.gu(2)
                    Layout.bottomMargin: units.gu(2)
                    Layout.preferredWidth: height
                    source: Image {
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        source: snapshot.imageSource
                    }

                    sourceFillMode: LomiriShape.PreserveAspectCrop
                    sourceHorizontalAlignment: LomiriShape.AlignHCenter
                    sourceVerticalAlignment: LomiriShape.AlignVCenter
                }

                QQC2.ToolButton {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                    icon.width: height * 0.3
                    icon.height: height * 0.3
                    action: QQC2.Action {
                        icon.name:  "edit"
                        onTriggered: {
                            toolbarItem.hide()
                            editorLoader.open(d.fileName)
                        }
                    }
                }
                QQC2.ToolButton {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                    icon.width: height * 0.3
                    icon.height: height * 0.3
                    action: QQC2.Action {
                        icon.name:  "share"
                        onTriggered: {
                            toolbarItem.hide()
                            shareLoader.open()
                        }
                    }
                }
                QQC2.ToolButton {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                    icon.width: height * 0.3
                    icon.height: height * 0.3
                    action: QQC2.Action {
                        icon.name:  "close"
                        onTriggered: toolbarItem.close()
                    }
                }
            }
        }
    }

    QtObject {
        id: d
        property Item target
        property string fileName: ""

        function saveScreenshot(result) {
            let _fileName = screenshotDirectory.makeFileName();
            if (_fileName.length === 0) {
                console.warn("ItemGrabber: No fileName to save image to");
            } else {
                console.log("ItemGrabber: Saving image to " + _fileName);
                if (result) {
                    fileName = _fileName
                    result.saveToFile(_fileName);
                    if (advancedMode) {
                        toolbar.show(fileName, true)
                    }
                }
            }
        }
    }
}
