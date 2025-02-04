/*
 * Copyright (C) 2013-2016 Canonical Ltd.
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
import QtGraphicalEffects 1.12
import Powerd 0.1
import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.3 as ListItem
import Lomiri.Notifications 1.0
import QMenuModel 1.0
import Utils 0.1
import "../Components"
// ENH062 - Slim volume notification
import QtQuick.Layouts 1.12
// ENH062 - End

StyledItem {
    id: notification

    property alias iconSource: icon.fileSource
    property alias secondaryIconSource: secondaryIcon.source
    property alias summary: summaryLabel.text
    property alias body: bodyLabel.text
    property alias value: valueIndicator.value
    property var actions
    property var notificationId
    property var type
    property var hints
    property var notification
    property color color: theme.palette.normal.background
    property bool fullscreen: notification.notification && typeof notification.notification.fullscreen != "undefined" ?
                                  notification.notification.fullscreen : false // fullscreen prop only exists in the mock
    property int maxHeight
    property int margins: units.gu(1)
    property bool privacyMode: false
    property bool hideContent: notification.privacyMode &&
                               notification.notification.urgency !== Notification.Critical &&
                               (notification.type === Notification.Ephemeral || notification.type === Notification.Interactive)


    readonly property real defaultOpacity: 1.0
    property bool hasMouse
    property url background: ""

    objectName: "background"
    implicitHeight: type !== Notification.PlaceHolder ? (fullscreen ? maxHeight : outterColumn.height + shapedBack.anchors.topMargin + margins * 2) : 0

    // FIXME: non-zero initially because of LP: #1354406 workaround, we want this to start at 0 upon creation eventually
    opacity: defaultOpacity - Math.abs(x / notification.width)

    theme: ThemeSettings {
        name: "Lomiri.Components.Themes.Ambiance"
    }

    readonly property bool expanded: type === Notification.SnapDecision &&                   // expand only snap decisions, if...
                                     (fullscreen ||                                          // - it's a fullscreen one
                                      ListView.view.currentIndex === index ||                // - it's the one the user clicked on
                                      (ListView.view.currentIndex === -1 && index == 0)      // - the first one after the user closed the previous one
                                      )

    NotificationAudio {
        id: sound
        objectName: "sound"
        // ENH202 - Caller Alarm
        // source: hints["suppress-sound"] !== "true" && hints["sound-file"] !== undefined ? hints["sound-file"] : ""
        source: isSnatchAlarmContact && silentMode ? "file:///usr/share/sounds/lomiri/ringtones/Alarm clock.ogg"
                    : hints["suppress-sound"] !== "true" && hints["sound-file"] !== undefined ? hints["sound-file"] : ""
        // ENH202 - End
    }

    Component.onCompleted: {
        if (type === Notification.PlaceHolder) {
            return;
        }

        // Turn on screen as needed (Powerd.Notification means the screen
        // stays on for a shorter amount of time)
        if (type === Notification.SnapDecision) {
            Powerd.setStatus(Powerd.On, Powerd.SnapDecision);
        } else if (type !== Notification.Confirmation) {
            Powerd.setStatus(Powerd.On, Powerd.Notification);
        }

        // FIXME: using onCompleted because of LP: #1354406 workaround, has to be onOpacityChanged really
        if (opacity == defaultOpacity && hints["suppress-sound"] !== "true" && sound.source !== "") {
            sound.play();
        }
    }

    // ENH202 - Caller Alarm
    readonly property bool isIncomingCall: secondaryIconSource == "image://theme/incoming-call"
    readonly property bool isSnatchAlarmContact: shell.settings.enableSnatchAlarm && isIncomingCall && summaryLabel.text === shell.settings.snatchAlarmContactName
    property bool silentMode: false
    property bool previousSilentMode: false
    property real previousVolume: 1

    onIsSnatchAlarmContactChanged: {
        if (isSnatchAlarmContact) {
            let _silentModeItem = shell.quickToggleItems[4].toggleObj
            let _volumeItem = shell.quickToggleItems[16].toggleObj
            let _silentMode = _silentModeItem.checked
            let _volume = _volumeItem.value

            previousSilentMode = _silentMode
            previousVolume = _volume

            // Doesn't actually do anything because ringtone still doesn't play
            if (_silentMode) {
                silentMode = true
                _silentModeItem.clicked()
            }
            _volumeItem.value = 1

            shell.temporaryDisableVolumeControl = true
        }
    }
    // ENH202 - End
    Component.onDestruction: {
        if (type === Notification.PlaceHolder) {
            return;
        }

        if (type === Notification.SnapDecision) {
            Powerd.setStatus(Powerd.Off, Powerd.SnapDecision);
        } else if (type !== Notification.Confirmation) {
            Powerd.setStatus(Powerd.Off, Powerd.Notification);
        }
        // ENH202 - Caller Alarm
        if (isSnatchAlarmContact) {
            let _silentModeItem = shell.quickToggleItems[4].toggleObj
            let _volumeItem = shell.quickToggleItems[16].toggleObj
            let _silentMode = _silentModeItem.checked

            if (previousSilentMode !== _silentMode) {
                _silentModeItem.clicked()
            }
            _volumeItem.value = previousVolume

            silentMode = false
            shell.temporaryDisableVolumeControl = false
        }
        // ENH202 - End
    }

    function closeNotification() {
        if (index === ListView.view.currentIndex) { // reset to get the 1st snap decision expanded
            ListView.view.currentIndex = -1;
        }

        // perform the "reject" action
        notification.notification.invokeAction(notification.actions.data(1, ActionModel.RoleActionId));

        notification.notification.close();
    }

    Behavior on x {
        LomiriNumberAnimation { easing.type: Easing.OutBounce }
    }

    onHintsChanged: {
        if (type === Notification.Confirmation && opacity == defaultOpacity && hints["suppress-sound"] !== "true" && sound.source !== "") {
            sound.play();
        }
    }

    onFullscreenChanged: {
        if (fullscreen) {
            notification.notification.urgency = Notification.Critical;
        }
        if (index == 0) {
            ListView.view.topmostIsFullscreen = fullscreen;
        }
    }

    Behavior on implicitHeight {
        enabled: !fullscreen
        LomiriNumberAnimation {
            duration: LomiriAnimation.SnapDuration
        }
    }

    visible: type !== Notification.PlaceHolder

    BorderImage {
        anchors {
            fill: contents
            margins: shapedBack.visible ? -units.gu(1) : -units.gu(1.5)
        }
        source: "../graphics/dropshadow2gu.sci"
        opacity: notification.opacity * 0.5
        enabled: !fullscreen
    }

    LomiriShape {
        id: shapedBack
        objectName: "shapedBack"

        visible: !fullscreen
        anchors {
            fill: parent
            leftMargin: notification.margins
            rightMargin: notification.margins
            topMargin: index == 0 ? notification.margins : 0
        }
        backgroundColor: parent.color
        radius: "small"
        aspect: LomiriShape.Flat
    }

    Rectangle {
        id: nonShapedBack

        visible: fullscreen
        anchors.fill: parent
        color: parent.color
    }

    onXChanged: {
        if (Math.abs(notification.x) > 0.75 * notification.width) {
            closeNotification();
        }
    }

    Item {
        id: contents
        anchors.fill: fullscreen ? nonShapedBack : shapedBack

        LomiriMenuModelPaths {
            id: paths

            source: hints["x-lomiri-private-menu-model"]

            busNameHint: "busName"
            actionsHint: "actions"
            menuObjectPathHint: "menuPath"
        }

        AyatanaMenuModel {
            id: lomiriMenuModel

            property string lastNameOwner: ""

            busName: paths.busName
            actions: paths.actions
            menuObjectPath: paths.menuObjectPath
            onNameOwnerChanged: {
                if (lastNameOwner !== "" && nameOwner === "" && notification.notification !== undefined) {
                    notification.notification.close()
                }
                lastNameOwner = nameOwner
            }
        }

        MouseArea {
            id: interactiveArea

            anchors.fill: parent
            objectName: "interactiveArea"

            drag.target: !fullscreen ? notification : undefined
            drag.axis: Drag.XAxis
            drag.minimumX: -notification.width
            drag.maximumX: notification.width
            hoverEnabled: true
            // ENH209 - Notifications at the bottom
            // Disable swipe to dismiss for calls
            enabled: !notifySwipeButtonLoader.active
            // ENH209 - End

            onClicked: {
                if (notification.type === Notification.Interactive) {
                    notification.notification.invokeAction(actionRepeater.itemAt(0).actionId)
                } else {
                    notification.ListView.view.currentIndex = index;
                }
            }
            onReleased: {
                if (Math.abs(notification.x) < notification.width / 2) {
                    notification.x = 0
                } else {
                    notification.x = notification.width
                }
            }
        }

        NotificationButton {
            objectName: "closeButton"
            width: units.gu(2)
            height: width
            radius: width / 2
            visible: hasMouse && (containsMouse || interactiveArea.containsMouse)
            iconName: "close"
            outline: false
            hoverEnabled: true
            color: theme.palette.normal.negative
            anchors.horizontalCenter: parent.left
            anchors.horizontalCenterOffset: notification.parent.state === "narrow" ? notification.margins / 2 : 0
            anchors.verticalCenter: parent.top
            anchors.verticalCenterOffset: notification.parent.state === "narrow" ? notification.margins / 2 : 0

            onClicked: closeNotification();
        }

        Column {
            id: outterColumn
            objectName: "outterColumn"

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: !fullscreen ? notification.margins : 0
            }

            spacing: notification.margins

            Row {
                id: topRow

                spacing: notification.margins
                anchors {
                    left: parent.left
                    right: parent.right
                }

                Item {
                    id: iconWrapper
                    width: units.gu(6)
                    height: width
                    visible: iconSource !== "" && type !== Notification.Confirmation
                    ShapedIcon {
                        id: icon

                        objectName: "icon"
                        anchors.fill: parent
                        shaped: notification.hints["x-lomiri-non-shaped-icon"] !== "true"
                        visible: iconSource !== "" && !blurEffect.visible
                    }

                    FastBlur {
                        id: blurEffect
                        objectName: "blurEffect"
                        visible: notification.hideContent
                        anchors.fill: icon
                        source: icon
                        transparentBorder: true
                        radius: 64
                    }
                }

                Label {
                    objectName: "privacySummaryLabel"
                    width: secondaryIcon.visible ? parent.width - x - units.gu(3) : parent.width - x
                    height: units.gu(6)
                    anchors.verticalCenter: iconWrapper.verticalCenter
                    verticalAlignment: Text.AlignVCenter
                    visible: notification.hideContent
                    fontSize: "medium"
                    font.weight: Font.Light
                    color: theme.palette.normal.backgroundSecondaryText
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: i18n.tr("New message")
                }

                Column {
                    id: labelColumn
                    width: secondaryIcon.visible ? parent.width - x - units.gu(3) : parent.width - x
                    anchors.verticalCenter: (icon.visible && !bodyLabel.visible) ? iconWrapper.verticalCenter : undefined
                    spacing: units.gu(.4)
                    visible: type !== Notification.Confirmation && !notification.hideContent

                    Label {
                        id: summaryLabel

                        objectName: "summaryLabel"
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        fontSize: "medium"
                        font.weight: Font.Light
                        color: theme.palette.normal.backgroundSecondaryText
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    Label {
                        id: bodyLabel

                        objectName: "bodyLabel"
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        visible: body != ""
                        fontSize: "small"
                        font.weight: Font.Light
                        color: theme.palette.normal.backgroundTertiaryText
                        wrapMode: Text.Wrap
                        maximumLineCount: {
                            if (type === Notification.SnapDecision) {
                                return 12;
                            } else if (notification.hints["x-lomiri-truncation"] === false) {
                                return 20;
                            } else {
                                return 2;
                            }
                        }
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        lineHeight: 1.1
                    }
                }

                Image {
                    id: secondaryIcon

                    objectName: "secondaryIcon"
                    width: units.gu(2)
                    height: width
                    visible: status === Image.Ready
                    fillMode: Image.PreserveAspectCrop
                }
            }

            ListItem.ThinDivider {
                visible: type === Notification.SnapDecision && notification.expanded
            }

            Icon {
                name: "toolkit_chevron-down_3gu"
                visible: type === Notification.SnapDecision && !notification.expanded
                width: units.gu(2)
                height: width
                anchors.horizontalCenter: parent.horizontalCenter
                color: theme.palette.normal.base
            }

            ShapedIcon {
                id: centeredIcon
                objectName: "centeredIcon"
                width: units.gu(4)
                height: width
                shaped: notification.hints["x-lomiri-non-shaped-icon"] !== "true"
                fileSource: icon.fileSource
                // ENH062 - Slim volume notification
                // visible: fileSource !== "" && type === Notification.Confirmation
                visible: fileSource !== "" && type === Notification.Confirmation && !shell.settings.enableSlimVolume
                // ENH062 - End
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                id: valueLabel
                objectName: "valueLabel"
                text: body
                anchors.horizontalCenter: parent.horizontalCenter
                visible: type === Notification.Confirmation && body !== ""
                fontSize: "medium"
                font.weight: Font.Light
                color: theme.palette.normal.backgroundSecondaryText
                wrapMode: Text.WordWrap
                maximumLineCount: 1
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            // ENH062 - Slim volume notification
            RowLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                }
                ShapedIcon {
                    Layout.preferredWidth: units.gu(2)
                    Layout.preferredHeight: units.gu(2)
                    shaped: notification.hints["x-canonical-non-shaped-icon"] !== "true"
                    fileSource: icon.fileSource
                    visible: fileSource !== "" && type === Notification.Confirmation && shell.settings.enableSlimVolume
                }
                ProgressBar {
                    id: valueIndicator
                    objectName: "valueIndicator"
                    visible: type === Notification.Confirmation
                    minimumValue: 0
                    maximumValue: 100
                    showProgressPercentage: false
                    // anchors {
                    //     left: parent.left
                    //     right: parent.right
                    // }
                    Layout.fillWidth: true
                    // height: units.gu(1)
                    Layout.preferredHeight: units.gu(1)
                }
            }
            // ENH062 - End

            Column {
                id: dialogColumn
                objectName: "dialogListView"
                spacing: notification.margins

                visible: count > 0 && (notification.expanded || notification.fullscreen)

                anchors {
                    left: parent.left
                    right: parent.right
                    top: fullscreen ? parent.top : undefined
                    bottom: fullscreen ? parent.bottom : undefined
                }

                Repeater {
                    model: lomiriMenuModel

                    NotificationMenuItemFactory {
                        id: menuItemFactory

                        anchors {
                            left: dialogColumn.left
                            right: dialogColumn.right
                        }

                        menuModel: lomiriMenuModel
                        menuData: model
                        menuIndex: index
                        maxHeight: notification.maxHeight
                        background: notification.background

                        onLoaded: {
                            notification.fullscreen = Qt.binding(function() { return fullscreen; });
                        }
                        onAccepted: {
                            notification.notification.invokeAction(actionRepeater.itemAt(0).actionId)
                        }
                    }
                }
            }

            Column {
                id: oneOverTwoCase

                anchors {
                    left: parent.left
                    right: parent.right
                }

                spacing: notification.margins

                visible: notification.type === Notification.SnapDecision && oneOverTwoRepeaterTop.count === 3 && notification.expanded

                Repeater {
                    id: oneOverTwoRepeaterTop

                    model: notification.actions
                    delegate: Loader {
                        id: oneOverTwoLoaderTop

                        property string actionId: id
                        property string actionLabel: label

                        Component {
                            id: oneOverTwoButtonTop

                            NotificationButton {
                                objectName: "notify_oot_button" + index
                                width: oneOverTwoCase.width
                                text: oneOverTwoLoaderTop.actionLabel
                                outline: notification.hints["x-lomiri-private-affirmative-tint"] !== "true"
                                color: notification.hints["x-lomiri-private-affirmative-tint"] === "true" ? theme.palette.normal.positive
                                                                                                             : theme.name == "Lomiri.Components.Themes.SuruDark" ? "#888"
                                                                                                                                                                 : "#666"
                                onClicked: notification.notification.invokeAction(oneOverTwoLoaderTop.actionId)
                            }
                        }
                        sourceComponent: index == 0 ? oneOverTwoButtonTop : undefined
                    }
                }

                Row {
                    spacing: notification.margins

                    Repeater {
                        id: oneOverTwoRepeaterBottom

                        model: notification.actions
                        delegate: Loader {
                            id: oneOverTwoLoaderBottom

                            property string actionId: id
                            property string actionLabel: label

                            Component {
                                id: oneOverTwoButtonBottom

                                NotificationButton {
                                    objectName: "notify_oot_button" + index
                                    width: oneOverTwoCase.width / 2 - spacing / 2
                                    text: oneOverTwoLoaderBottom.actionLabel
                                    outline: notification.hints["x-lomiri-private-rejection-tint"] !== "true"
                                    color: index == 1 && notification.hints["x-lomiri-private-rejection-tint"] === "true" ? theme.palette.normal.negative
                                                                                                                             : theme.name == "Lomiri.Components.Themes.SuruDark" ? "#888"
                                                                                                                                                                                 : "#666"
                                    onClicked: notification.notification.invokeAction(oneOverTwoLoaderBottom.actionId)
                                }
                            }
                            sourceComponent: (index == 1 || index == 2) ? oneOverTwoButtonBottom : undefined
                        }
                    }
                }
            }

            Row {
                id: buttonRow

                objectName: "buttonRow"
                anchors {
                    left: parent.left
                    right: parent.right
                }
                visible: notification.type === Notification.SnapDecision && actionRepeater.count > 0 && !oneOverTwoCase.visible && notification.expanded
                spacing: notification.margins
                layoutDirection: Qt.RightToLeft

                Loader {
                    id: notifySwipeButtonLoader
                    active: notification.hints["x-lomiri-snap-decisions-swipe"] === "true"

                    sourceComponent: SwipeToAct  {
                        objectName: "notify_swipe_button"
                        width: buttonRow.width
                        leftIconName: "call-end"
                        rightIconName: "call-start"
                        clickToAct: notification.hasMouse
                        onRightTriggered: {
                            notification.notification.invokeAction(notification.actions.data(0, ActionModel.RoleActionId))
                        }

                        onLeftTriggered: {
                            notification.notification.invokeAction(notification.actions.data(1, ActionModel.RoleActionId))
                        }
                    }
                }

                Repeater {
                    id: actionRepeater
                    model: notification.actions
                    delegate: Loader {
                        id: loader

                        property string actionId: id
                        property string actionLabel: label
                        active: !notifySwipeButtonLoader.active

                        Component {
                            id: actionButton

                            NotificationButton {
                                objectName: "notify_button" + index
                                width: buttonRow.width / 2 - spacing / 2
                                text: loader.actionLabel
                                outline: (index == 0 && notification.hints["x-lomiri-private-affirmative-tint"] !== "true") ||
                                         (index == 1 && notification.hints["x-lomiri-private-rejection-tint"] !== "true")
                                color: {
                                    var result = "#666";
                                    if (theme.name == "Lomiri.Components.Themes.SuruDark") {
                                        result = "#888"
                                    }
                                    if (index == 0 && notification.hints["x-lomiri-private-affirmative-tint"] === "true") {
                                        result = theme.palette.normal.positive;
                                    }
                                    if (index == 1 && notification.hints["x-lomiri-private-rejection-tint"] === "true") {
                                        result = theme.palette.normal.negative;
                                    }
                                    return result;
                                }
                                onClicked: notification.notification.invokeAction(loader.actionId)
                            }
                        }
                        sourceComponent: (index == 0 || index == 1) ? actionButton : undefined
                    }
                }
            }

            OptionToggle {
                id: optionToggle
                objectName: "notify_button2"
                width: parent.width
                anchors {
                    left: parent.left
                    right: parent.right
                }

                visible: notification.type === Notification.SnapDecision && actionRepeater.count > 3 && !oneOverTwoCase.visible && notification.expanded
                model: notification.actions
                expanded: false
                startIndex: 2
                onTriggered: {
                    notification.notification.invokeAction(id)
                }
            }
        }
    }
}
