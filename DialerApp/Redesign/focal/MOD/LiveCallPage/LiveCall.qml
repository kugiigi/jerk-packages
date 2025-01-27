/*
 * Copyright 2012-2016 Canonical Ltd.
 * Copyright 2024 UBports Foundation
 *
 * This file is part of dialer-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * dialer-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.3 as ListItems
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.12
import Lomiri.Telephony 0.1
import Lomiri.Contacts 0.1
import QtContacts 5.0
import "../DialerPage"
import "../"

Page {
    id: liveCall
    objectName: "pageLiveCall"

    readonly property bool compactView: liveCall.height <= units.gu(50)
    readonly property bool isWide: liveCall.width >= units.gu(80)

    property var call: callManager.foregroundCall
    property var calls: callManager.calls
    property string dtmfEntry: ""
    property alias number: contactWatcher.identifier
    property bool onHold: call ? call.held : false
    property bool isMuted: call ? call.muted : false
    property bool dtmfVisible: call ? call.voicemail : false
    property bool multiCall: callManager.calls.length > 1
    property bool isVoicemail: (call ? call.voicemail : false) && callManager.calls.length === 1
    property string activeAudioOutput: call ? call.activeAudioOutput : ""
    property variant audioOutputs: call ? call.audioOutputs : null
    property int defaultTimeout: 10000
    property string initialStatus: ""
    property string initialNumber: ""
    property string caller: {
        if (call && call.isConference) {
            return i18n.tr("Conference");
        } else if (contactWatcher.alias !== "") {
            return contactWatcher.alias;
        } else if (call && call.phoneNumber !== "") {
            return call.phoneNumber;
        } else if (!call && initialNumber != "") {
            return initialNumber
        } else {
            return " "
        }
    }

    property Action backAction: Action {
        id: backAction
        objectName: "backButton"
        iconName: "back"
        onTriggered: {
            if (mainView.greeterMode) {
               greeter.showGreeter();
            } else {
                pageStackNormalMode.pop();
            }
        }
    }

    title: caller
    header: PageHeader {
        id: pageHeader
        title: liveCall.title
        leadingActionBar {
            actions: [ backAction ]
        }
        Sections {
            id: headerSections
            model: call ? [call.account.displayName]: []
            selectedIndex: 0
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            visible: multiplePhoneAccounts
        }
        extension: multiplePhoneAccounts ? headerSections : null
    }

    Keys.onPressed: {
        if (!dtmfVisible) {
            dtmfVisible = true
        }

        keypad.keyPressed(event.key, event.text)
    }

    function reportStatus(callObject, text) {
        // if a previous status was already set, do not overwrite it
        if (statusLabel.text !== "" || callManager.hasCalls) {
            return;
        }
        statusLabel.text = text;
        callConnection.target = null;
        liveCall.call = callObject;
        liveCall.dtmfVisible = false;
        closeTimer.running = true;
    }

    function isDefaultAudioOutput(id) {
        return (id == "default" ||
                id == "wired_headset" ||
                id == "earpiece")
    }

    function changeCallHoldingStatus(call, held) {
        callHoldingConnection.target = call;
        call.held = held;
    }

    Connections {
        target: callManager
        onHasCallsChanged: {
            if(!callManager.hasCalls) {
                reportStatus({}, i18n.tr("No calls"));
            } else {
                closeTimer.running = false;
                statusLabel.text = "";
                liveCall.call = Qt.binding(function() { return callManager.foregroundCall; });

                if (mainView.delayedDialNumber != "") {
                    console.log("Arm delayed dial timer for text=" + mainView.delayedDialNumber);
                    delayedDial.interval = 1;
                    delayedDial.running = true;
                }
            }
        }

        onConferenceRequestFailed: {
            mainView.showNotification(i18n.tr("Conference call failure"),
                                      i18n.tr("Failed to create a conference call."));
        }
    }

    Connections {
        id: callConnection
        target: call
        onCallEnded: {
            mainView.delayedDialNumber = "";
            delayedDial.running = false;

            var callObject = {};
            callObject["elapsedTime"] = call.elapsedTime;
            callObject["active"] = true;
            callObject["voicemail"] = call.voicemail;
            callObject["account"] = call.account;
            callObject["phoneNumber"] = contactWatcher.identifier;
            callObject["held"] = call.held;
            callObject["muted"] = call.muted;
            callObject["activeAudioOutput"] = call.activeAudioOutput;
            callObject["audioOutputs"] = [];
            callObject["isConference"] = call.isConference;

            reportStatus(callObject, i18n.tr("Call ended"));
        }
    }

    Connections {
        id: callHoldingConnection
        // the target will be set on the actions
        target: null
        onCallHoldingFailed: {
            mainView.showNotification(i18n.tr("Call holding failure"),
                                      target.held ? i18n.tr("Failed to activate the call.")
                                                  : i18n.tr("Failed to place the active call on hold."));
        }
    }

    Component {
        id: audioOutputsPopover
        Popover {
            id: popover
            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                ListItems.Header { text: i18n.tr("Switch audio source:") }
                Repeater {
                    model: audioOutputs
                    ListItems.Standard {
                        text: nameForAudioId(modelData.id)
                        showDivider: index != model.count-1
                        onClicked: {
                            call.activeAudioOutput = modelData.id
                            PopupUtils.close(popover)
                        }
                    }
                }
            }
        }
    }

    states: [
        State {
            name: "keypadVisibleNarrow"
            when: dtmfVisible && !mainLayout.isWideLayout
            extend: "keypadVisible"

            PropertyChanges {
                target: durationLabel
                anchors.topMargin: units.gu(2)
            }

            PropertyChanges {
                target: callerLabel
                font.pixelSize: FontUtils.sizeToPixels("small")
            }

            PropertyChanges {
                target: divider
                opacity: 1
            }
        },

        State {
            name: "keypadVisible"
            when: dtmfVisible

            PropertyChanges {
                target: keypad
                opacity: 1.0
            }
            PropertyChanges {
                target: dtmfButton
                iconColor: theme.palette.normal.positive
            }
        },

        State {
            name: "multiCall"
            when: (multiCall || call && call.isConference) && !dtmfVisible

            PropertyChanges {
                target: durationLabel
                opacity: 0.0
            }

            PropertyChanges {
                target: callerLabel
                opacity: 0.0
            }

            PropertyChanges {
                target: multiCallArea
                opacity: 1.0
            }
        },

        State {
            name: "closing"
            when: closeTimer.running || greeterAnimationTimer.running

            PropertyChanges {
                target: buttonsArea
                opacity: 0.0
                enabled: false
            }

            PropertyChanges {
                target: hangupButton
                enabled: false
            }

            PropertyChanges {
                target: durationLabel
                anchors.topMargin: units.gu(9)
            }
        }
    ]

    transitions: [
        Transition {
            ParallelAnimation {
                LomiriNumberAnimation {
                    targets: [durationLabel,callerLabel]
                    properties: "font.pixelSize,anchors.topMargin,opacity"
                }
                LomiriNumberAnimation {
                    targets: [keypad,multiCallArea,buttonsArea]
                    properties: "opacity"
                }
            }
        }

    ]

    onCallChanged: {
        // reset the DTMF keypad visibility status
        dtmfVisible = (call && call.voicemail);
    }

    onActiveChanged: {
        callManager.callIndicatorVisible = !active && callManager.hasCalls;
    }

    Component.onCompleted: {
        callManager.callIndicatorVisible = !active && callManager.hasCalls;
        forceActiveFocus();
    }

    Timer {
        id: callWatcher
        interval: defaultTimeout
        repeat: false
        running: true
        onTriggered: {
            if (!callManager.hasCalls) {
                // TODO: notify about failed call
                reportStatus({}, i18n.tr("Call failed"))
            }
        }
    }

    Timer {
        id: greeterAnimationTimer
        interval: 1000
        repeat: false
        running: false
        onTriggered: mainView.switchToKeypadView()
    }

    Timer {
        id: closeTimer
        interval: mainView.greeterMode ? 2000 : 3000
        repeat: false
        running: false
        onTriggered: {
            if (!callManager.hasCalls) {
                if (!mainView.greeterMode) {
                    mainView.switchToKeypadView();
                }

                // TODO: we can't be sure that the currentPage is a DialerPage instance
                if (pageStackNormalMode.currentPage.dialNumber) {
                    pageStackNormalMode.currentPage.dialNumber = pendingNumberToDial;
                }
                if (mainView.greeterMode) {
                    greeter.showGreeter();
                    greeterAnimationTimer.running = true
                }
            }
        }
    }

    Timer {
        id: delayedDial
        interval: 1000
        repeat: false
        running: false

        onTriggered: {
            if (mainView.delayedDialNumber.length == 0) {
                // not re-arming the timer
                return;
            }

            if (mainView.delayedDialNumber[0] == ";") {
                interval = 1000;
                console.log("wait for 1 second");
            } else if (mainView.delayedDialNumber[0] == ",") {
                interval = 2000;
                console.log("wait for 2 second");
            } else {
                interval = 250;
                console.log("dial " + mainView.delayedDialNumber[0]);
                dtmfEntry += mainView.delayedDialNumber[0];
                call.sendDTMF(mainView.delayedDialNumber[0]);
            }

            mainView.delayedDialNumber = mainView.delayedDialNumber.substring(1);
            running = mainView.delayedDialNumber.length > 0;
        }
    }

    function endCall() {
        if (call) {
            call.endCall();
        }
    }

    function nameForAudioId(id) {
        if (id == "bluetooth") {
            return i18n.tr("Bluetooth device")
        } else if (id == "default") {
            return i18n.tr("Ubuntu Touch Phone")
        } else if (id == "speaker") {
            return i18n.tr("Phone Speaker")
        }
        return i18n.tr("Unknown device")
    }

    // background
    Rectangle {
        anchors.fill: parent
        color: Theme.palette.normal.background
    }

    // FIXME: this invisible label is only used for
    // calculating the size of the screen and resizing
    // the dtmf string accordingly so it can fit the page header
    Label {
        id: dtmfLabelHelper
        visible: false
        text: dtmfEntry
        anchors.left: parent.left
        anchors.leftMargin: units.gu(2)
        anchors.right: parent.right
        anchors.rightMargin: units.gu(4)
        fontSize: "x-large"
        onTextChanged: {
            if(paintedWidth > width) {
                // drop the first number
                dtmfEntry = dtmfEntry.substr(1)
            }
        }
    }

    ContactWatcher {
        id: contactWatcher
        // FIXME: handle conf calls
        identifier: {
            if (initialNumber != "") {
                return initialNumber
            } else if (call) {
                return call.phoneNumber
            }
            return ""
        }

        // FIXME: if we implement VOIP, get the addressable fields from the account itself
        addressableFields: ["tel"]
    }

    StopWatch {
        id: stopWatch
        objectName: "stopWatch"
        time: call ? call.elapsedTime : 0
    }

    GridLayout {
        id: mainLayout

        readonly property bool isWideLayout: state === "wide"

        anchors {
            fill: parent
            topMargin: pageHeader.height
        }

        columnSpacing: 0
        rowSpacing: 0

        state: "narrow"
        states: [
            State {
                name: "narrow"
                when: !liveCall.isWide

                PropertyChanges {
                    target: mainLayout
                    flow: GridLayout.TopToBottom
                }

                AnchorChanges {
                    target: durationLabel

                    anchors {
                        top: parent.top
                        verticalCenter: undefined
                    }
                }

                ParentChange {
                    target: keypad
                    parent: keypadNarrowParent
                }

                PropertyChanges {
                    target: keypadWideParent
                    visible: false
                }

                ParentChange {
                    target: multiCallActionArea
                    parent: multiCallActionAreaNarrowParent
                }

                PropertyChanges {
                    target: multiCallActionArea
                    anchors.topMargin: 0
                }

                PropertyChanges {
                    target: buttonsAreaParent

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                    Layout.bottomMargin: units.gu(1)
                    Layout.fillWidth: true
                }

                PropertyChanges {
                    target: buttonsArea
                    flow: GridLayout.LeftToRight
                }

                PropertyChanges {
                    target: hangupButtonParent

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                    Layout.rightMargin: 0
                    Layout.bottomMargin: liveCall.compactView ? units.gu(2) : units.gu(4)
                }

                PropertyChanges {
                    target: hangupButton

                    width: liveCall.compactView ? units.gu(18) : units.gu(21)
                    height: units.gu(4.5)
                }
            }
            , State {
                name: "wide"
                when: liveCall.isWide

                PropertyChanges {
                    target: mainLayout
                    flow: GridLayout.LeftToRight
                }

                AnchorChanges {
                    target: durationLabel

                    anchors {
                        top: undefined
                        verticalCenter: parent.verticalCenter
                    }
                }

                ParentChange {
                    target: keypad
                    parent: keypadWideParent
                }

                PropertyChanges {
                    target: keypadWideParent
                    visible: true
                }

                ParentChange {
                    target: multiCallActionArea
                    parent: multiCallActionAreaWideParent
                }

                PropertyChanges {
                    target: multiCallActionArea
                    anchors.topMargin: units.gu(2)
                }

                PropertyChanges {
                    target: buttonsAreaParent

                    Layout.alignment: Qt.AlignCenter
                    Layout.bottomMargin: 0
                    Layout.fillWidth: false
                    Layout.preferredWidth: units.gu(10)
                }

                PropertyChanges {
                    target: buttonsArea
                    flow: GridLayout.TopToBottom
                }

                PropertyChanges {
                    target: hangupButtonParent

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: units.gu(10)
                    Layout.fillWidth: false
                    Layout.bottomMargin: 0
                }

                PropertyChanges {
                    target: hangupButton

                    width: units.gu(4.5)
                    height: liveCall.compactView ? units.gu(15) : units.gu(21)
                }
            }
        ]

        Item {
            id: centralArea

            Layout.fillWidth: true
            Layout.fillHeight: true

            Label {
                id: statusLabel
                anchors {
                    bottom: durationLabel.top
                    bottomMargin: units.gu(1)
                    horizontalCenter: durationLabel.horizontalCenter
                }
                text: ""
                fontSize: "large"
                opacity: text !== "" ? 1 : 0

                Behavior on opacity {
                    LomiriNumberAnimation { }
                }
            }

            Label {
                id: durationLabel

                anchors {
                    top: parent.top
                    topMargin: units.gu(5)
                    left: parent.left
                    right: parent.right
                }
                clip: true
                horizontalAlignment: Qt.AlignHCenter

                text: {
                    var duration = ""
                    if (dtmfVisible && dtmfLabelHelper.text !== "") {
                        duration = dtmfLabelHelper.text;
                    } else if (call && call.active) {
                        // TRANSLATORS: %1 is the call duration here.
                        duration = call.held ? i18n.tr("%1 - on hold").arg(stopWatch.elapsed) : stopWatch.elapsed;
                    } else if (call && !call.incoming) {
                        duration = i18n.tr("Calling")
                    } else if (!call && initialStatus !== "") {
                        duration = initialStatus
                    } else {
                        duration = " "
                    }

                    if (liveCall.compactView)
                        return "%1 (%2)".arg(duration).arg(caller)
                    else
                        return duration
                }
                fontSize: liveCall.compactView ? "large" : "x-large"
            }

            Label {
                id: callerLabel

                anchors {
                    top: durationLabel.bottom
                    topMargin: units.gu(1)
                    horizontalCenter: parent.horizontalCenter
                }
                text: caller
                color: theme.palette.normal.backgroundSecondaryText

                fontSize:"large"
                visible: !liveCall.compactView
                height: visible ? implicitHeight : 0
            }

            MultiCallDisplay {
                id: multiCallArea
                objectName: "multiCallDisplay"
                calls: callManager.calls
                opacity: 0
                anchors {
                    fill: parent
                }
            }

            ListItems.ThinDivider {
                id: divider

                opacity: 0
                anchors {
                    left: parent.left
                    right: parent.right
                    top: callerLabel.bottom
                    topMargin: liveCall.compactView ? units.gu(0.5) : units.gu(2)
                }
            }

            Item {
                id: multiCallActionAreaWideParent

                height: units.gu(6)
                anchors {
                    top: callerLabel.bottom
                    left: parent.left
                    right: parent.right
                }
            }

            ColumnLayout {
                id: keypadNarrowParent

                spacing: 0

                anchors {
                    top: divider.bottom
                    topMargin: units.gu(2)
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                Keypad {
                    id: keypad

                    Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
                    Layout.maximumWidth: liveCall.isWide && liveCall.width <= units.gu(90) ? units.gu(40) : units.gu(50)
                    Layout.maximumHeight: units.gu(40)
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    onKeyPressed: {
                        if (call) {
                            dtmfEntry += keychar
                            call.sendDTMF(keychar)
                        }
                    }

                    visible: opacity > 0.0
                    opacity: 0.0
                    labelPixelSize: liveCall.compactView ? units.dp(20) : units.dp(30)
                    spacing: liveCall.compactView ? 0 : 5
                }
            }
        }

        ColumnLayout {
            id: keypadWideParent

            Layout.alignment: Qt.AlignCenter
            Layout.maximumWidth: units.gu(50)
            visible: false
            spacing: 0
        }

        Item {
            id: buttonsAreaParent

            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.bottomMargin: units.gu(1)
            Layout.fillWidth: true
            Layout.preferredHeight: buttonsArea.childrenRect.height

            Item {
                id: multiCallActionAreaNarrowParent

                height: childrenRect.height
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: buttonsArea.top
                    bottomMargin: units.gu(2)
                }

                Row {
                    id: multiCallActionArea

                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                    }

                    width: childrenRect.width
                    height: swapButton.height
                    opacity: multiCall && !dtmfVisible ? 1 : 0
                    enabled : opacity > 0
                    spacing: units.gu(3)

                    Behavior on opacity {
                        LomiriNumberAnimation { }
                    }

                    Button {
                        id: swapButton
                        visible: calls.length > 1
                        anchors {
                            verticalCenter: parent.verticalCenter
                        }

                        text: i18n.tr("Switch calls")
                        color: mainView.backgroundColor
                        strokeColor: theme.palette.normal.positive
                        onClicked: {
                            changeCallHoldingStatus(callManager.foregroundCall, true)
                        }
                    }

                    Button {
                        id: mergeButton
                        visible: calls.length > 1
                        anchors {
                            verticalCenter: parent.verticalCenter
                        }

                        text: i18n.tr("Merge calls")
                        color: mainView.backgroundColor
                        strokeColor: theme.palette.normal.positive
                        onClicked: {
                            callManager.mergeCalls(callManager.calls[0], callManager.calls[1])
                        }
                    }
                }
            }

            GridLayout {
                id: buttonsArea

                anchors.fill: parent

                Item {
                    Layout.fillWidth: true
                }

                LiveCallKeypadButton {
                    id: speakerButton
                    objectName: "speakerButton"
                    Layout.alignment: Qt.AlignCenter
                    iconSource: {
                        if (audioOutputs && audioOutputs.length <= 2) {
                            if (activeAudioOutput == "speaker") {
                                return "speaker"
                            }
                            return "speaker-mute"
                        } else {
                            if (activeAudioOutput == "bluetooth") {
                                return "audio-speakers-bluetooth-symbolic"
                            } else if (activeAudioOutput == "speaker") {
                                return "speaker"
                            } else {
                                return "speaker-mute"
                            }
                        }
                    }
                    selected: !isDefaultAudioOutput(activeAudioOutput)
                    iconWidth: units.gu(3)
                    iconHeight: units.gu(3)
                    onClicked: {
                        if (call) {
                            // all phones have at least two outputs: speaker and default,
                            // where default is either earpiece or wired headset
                            // if we have more than 2, we have to show a popup so users
                            // can select the active audio output
                            if (audioOutputs.length > 2) {
                                PopupUtils.open(audioOutputsPopover, speakerButton)
                                return
                            }
                            if (isDefaultAudioOutput(call.activeAudioOutput)) {
                                call.activeAudioOutput = "speaker"
                            } else {
                                call.activeAudioOutput = "default"
                            }
                        }
                    }
                    enabled: audioOutputs && audioOutputs.length > 1
                }

                LiveCallKeypadButton {
                    objectName: "muteButton"
                    Layout.alignment: Qt.AlignCenter
                    iconSource: selected ? "microphone-mute" : "microphone"
                    enabled: !isVoicemail
                    selected: liveCall.isMuted
                    iconWidth: units.gu(3)
                    iconHeight: units.gu(3)
                    onClicked: {
                        if (call) {
                            call.muted = !call.muted
                        }
                    }
                }

                LiveCallKeypadButton {
                    id: newCallButton
                    objectName: "newCallButton"
                    Layout.alignment: Qt.AlignCenter
                    iconSource: "add"
                    iconWidth: units.gu(3)
                    iconHeight: units.gu(3)
                    enabled: !mainView.greeterMode
                    onClicked: pageStackNormalMode.push(Qt.resolvedUrl("../ContactsPage/ContactsPage.qml"), { "initialTab":"0", "initialState":"searching"})
                }

                LiveCallKeypadButton {
                    objectName: "callHoldButton"
                    Layout.alignment: Qt.AlignCenter
                    iconSource: {
                        if (callManager.backgroundCall) {
                            return "swap"
                        } else if (selected) {
                            return "media-playback-start"
                        } else {
                            return "media-playback-pause"
                        }
                    }
                    selected: liveCall.onHold
                    iconWidth: units.gu(3)
                    iconHeight: units.gu(3)
                    onClicked: {
                        if (call) {
                            changeCallHoldingStatus(call, !call.held)
                        }
                    }
                }

                LiveCallKeypadButton {
                    id: dtmfButton
                    objectName: "dtmfButton"
                    Layout.alignment: Qt.AlignCenter
                    iconSource: "keypad"
                    iconWidth: units.gu(4)
                    iconHeight: units.gu(4)
                    enabled: !isVoicemail
                    onClicked: dtmfVisible = !dtmfVisible
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }

        Item {
            id: hangupButtonParent

            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.bottomMargin: liveCall.compactView ? units.gu(2) : units.gu(4)
            Layout.preferredHeight: liveCall.compactView ? units.gu(6): units.gu(10)

            HangupButton {
                id: hangupButton
                objectName: "hangupButton"

                anchors.centerIn: parent
                onClicked: endCall()
            }
        }
    }
}
