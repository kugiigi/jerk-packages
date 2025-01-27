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

import QtContacts 5.0
import QtQuick 2.9
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Telephony 0.1
import Lomiri.Contacts 0.1
import Lomiri.Components.ListItems 1.3 as ListItems
import QtQuick.Layouts 1.12

import "../"

Page {
    id: page

    property bool bottomEdgeCommitted: bottomEdge.status === BottomEdge.Committed
    property alias bottomEdgeItem: bottomEdge
    property alias dialNumber: keypadEntry.value
    property alias input: keypadEntry.input
    property alias callAnimationRunning: callAnimation.running
    property bool greeterMode: false
    property var mmiPlugins: []
    readonly property bool isGreeterMode: mainView.state === "greeterMode"
    readonly property bool compactView: page.height <= units.gu(50)
    readonly property bool isWide: page.width >= units.gu(80)
    readonly property bool isTall: page.height >= units.gu(95)
    property bool isInEmergencyMode: (greeter.greeterActive && mainView.applicationActive) | (mainView.account && mainView.account.simLocked)

    function selectAccount(accountId) {
        for (var i in accountsModel.activeAccounts) {
            var account = accountsModel.activeAccounts[i]
            if (account.accountId === accountId) {
                headerSections.selectedIndex = i
                return
            }
        }
    }

    header: PageHeader {
        id: pageHeader

        property list<Action> actionsGreeter
        property list<Action> actionsNormal: [
            Action {
                objectName: "favorite-selected"
                iconName: "favorite-selected"
                text: i18n.tr("Favorite Contacts")
                visible: !contactListLoader.visible
                onTriggered: pageStackNormalMode.push(Qt.resolvedUrl("../ContactsPage/ContactsPage.qml"), {"initialTab":"1", "initialState":"default"})
            },
            Action {
                objectName: "contacts"
                iconName: "contact"
                text: i18n.tr("Contacts")
                onTriggered: pageStackNormalMode.push(Qt.resolvedUrl("../ContactsPage/ContactsPage.qml"), { "initialTab":"0", "initialState":"searching"})
            },
            Action {
                iconName: "settings"
                text: i18n.tr("Settings")
                onTriggered: pageStackNormalMode.push(Qt.resolvedUrl("../SettingsPage/SettingsPage.qml"))
            }

        ]
        title: page.title
        focus: false
        trailingActionBar {
            actions: mainView.greeterMode ? actionsGreeter : actionsNormal
        }

        // make sure the SIM selector never gets focus
        onFocusChanged: {
            if (focus) {
                focus = false
            }
        }

        leadingActionBar {
            property list<QtObject> backActionList: [
                Action {
                    iconName: "back"
                    text: i18n.tr("Close")
                    visible: mainView.greeterMode
                    onTriggered: {
                        greeter.showGreeter()
                        dialNumber = "";
                    }
                }
            ]
            property list<QtObject> simLockedActionList: [
                Action {
                    id: simLockedAction
                    objectName: "simLockedAction"
                    iconName: "simcard-locked"
                    onTriggered: {
                        mainView.showSimLockedDialog()
                    }
                }
            ]
            actions: {
                if (mainView.simLocked && !mainView.greeterMode) {
                    return simLockedActionList
                } else {
                    return backActionList
                }
            }
        }

        Sections {
            id: headerSections
            model: mainView.multiplePhoneAccounts ? accountsModel.activeAccountNames : []
            selectedIndex: accountsModel.defaultCallAccountIndex
            focus: false
            onSelectedIndexChanged: {
                if (selectedIndex >= 0) {
                    mainView.account = accountsModel.activeAccounts[selectedIndex]
                } else {
                    mainView.account = null
                }
            }
            onModelChanged: {
                selectedIndex = accountsModel.defaultCallAccountIndex
            }
        }

        extension: headerSections.model.length > 1 ? headerSections : null
    }

    objectName: "dialerPage"
    title: {
        // avoid clearing the title when app is inactive
        // under some states
        if (!mainView.telepathyReady) {
            return i18n.tr("Initializing...")
        } else if (greeter.greeterActive) {
            if (mainView.applicationActive) {
                return i18n.tr("Emergency Calls")
            } else {
                return " "
            }
        } else if (telepathyHelper.flightMode) {
            return i18n.tr("Flight Mode")
        } else if (mainView.account && mainView.account.simLocked) {
            // just in case we need it back in the future somewhere, keep the original string
            var oldTitle = i18n.tr("SIM Locked")
            // show Emergency Calls for sim locked too. There is going to be an icon indicating it is locked
            return i18n.tr("Emergency Calls")
        } else if (mainView.account && mainView.account.networkName && mainView.account.networkName != "") {
            return mainView.account.networkName
        } else if (mainView.account && mainView.account.type != AccountEntry.PhoneAccount) {
            return mainView.account.protocolInfo.serviceDisplayName != "" ? mainView.account.protocolInfo.serviceDisplayName :
                                                                            mainView.account.protocolInfo.name
        } else if (multiplePhoneAccounts && !mainView.account) {
            return i18n.tr("Phone")
        }
        return i18n.tr("No network")
    }

    state: "narrow"
    states: [
        State {
            name: "narrow"
            when: !page.isWide

            AnchorChanges {
                target: keypadContainer

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: footer.top
                }
            }

            PropertyChanges {
                target: topSpacerItem
                visible: !contactListLoader.visible
            }

            PropertyChanges {
                target: keypadLayout

                Layout.leftMargin: units.gu(3)
                Layout.rightMargin: units.gu(3)
                flow: GridLayout.TopToBottom
            }

            PropertyChanges {
                target: keypad

                Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
                Layout.leftMargin: units.gu(2)
                Layout.rightMargin: units.gu(2)
            }

            PropertyChanges {
                target: favoritesListWideParent
                visible: false
            }

            PropertyChanges {
                target: entryWithButtons

                Layout.topMargin: 0
                Layout.bottomMargin: 0
                Layout.alignment: Qt.AlignBottom
            }

            PropertyChanges {
                target: keypadEntryDivider
                visible: true
            }

            ParentChange {
                target: contactListLoader
                parent: favoritesListNarrowParent
            }

            PropertyChanges {
                target: contactListLoader
                active: page.isTall
            }

            AnchorChanges {
                target: footer

                anchors {
                    top: undefined
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
            }

            PropertyChanges {
                target: footer

                height: page.compactView ? units.gu(6) : units.gu(10)
                anchors.topMargin: 0
                anchors.bottomMargin: page.compactView ? units.gu(2) : units.gu(4)
            }

            PropertyChanges {
                target: footerLayout

                Layout.leftMargin: units.gu(2)
                Layout.rightMargin: units.gu(2)
                flow: GridLayout.LeftToRight
            }

            PropertyChanges {
                target: callButton

                Layout.preferredWidth: page.compactView ? units.gu(18) : units.gu(21)
                Layout.preferredHeight: units.gu(4.5)
            }

            PropertyChanges {
                target: addContact

                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.bottomMargin: 0
            }

            PropertyChanges {
                target: backspace

                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.topMargin: 0
            }
        }
        , State {
            name: "wide"
            when: page.isWide

            AnchorChanges {
                target: keypadContainer

                anchors {
                    left: parent.left
                    right: footer.left
                    bottom: parent.bottom
                }
            }

            PropertyChanges {
                target: topSpacerItem
                visible: false
            }

            PropertyChanges {
                target: keypadLayout

                Layout.leftMargin: units.gu(3)
                Layout.rightMargin: units.gu(3)
                flow: GridLayout.LeftToRight
            }

            PropertyChanges {
                target: keypad

                Layout.alignment: Qt.AlignCenter
                Layout.leftMargin: 0
                Layout.rightMargin: 0
            }

            PropertyChanges {
                target: contactListLoader
                active: true
            }

            PropertyChanges {
                target: favoritesListWideParent
                visible: contactListLoader.item && contactListLoader.item.count > 0 && !page.isGreeterMode
            }

            PropertyChanges {
                target: entryWithButtons

                Layout.topMargin: units.gu(2)
                Layout.bottomMargin: units.gu(1)
                Layout.alignment: Qt.AlignCenter
            }

            PropertyChanges {
                target: keypadEntryDivider
                visible: contactListLoader.visible
            }

            ParentChange {
                target: contactListLoader
                parent: favoritesListWideParent
            }

            AnchorChanges {
                target: footer

                anchors {
                    top: parent.top
                    left: undefined
                    right: parent.right
                    bottom: parent.bottom
                }
            }

            PropertyChanges {
                target: footer

                width: units.gu(10)
                anchors.topMargin: pageHeader.height
                anchors.bottomMargin: 0
            }

            PropertyChanges {
                target: footerLayout

                Layout.leftMargin: 0
                Layout.rightMargin: 0
                flow: GridLayout.TopToBottom
            }

            PropertyChanges {
                target: callButton

                Layout.preferredWidth: units.gu(4.5)
                Layout.preferredHeight: page.compactView ? units.gu(15) : units.gu(21)
            }

            PropertyChanges {
                target: addContact

                Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
                Layout.bottomMargin: units.gu(2)
            }

            PropertyChanges {
                target: backspace

                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                Layout.topMargin: units.gu(2)
            }
        }
    ]

    // Forward key presses
    Keys.onPressed: {
        if (!active) {
            return
        }

        // in case Enter is pressed, remove focus from the view to prevent multiple calls to get placed
        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
            page.focus = false;
        }
        keypad.keyPressed(event.key, event.text, keypad.keyTextfromKeyCode(event.key))
    }

    function triggerCallAnimation() {
        callAnimation.start();
    }

    Connections {
        target: mainView
        onPendingNumberToDialChanged: {
            keypadEntry.value = mainView.pendingNumberToDial;
            if (mainView.pendingNumberToDial !== "") {
                mainView.switchToKeypadView();
            }
        }
    }

    function createObjectAsynchronously(componentFile, callback) {
        var component = Qt.createComponent(componentFile, Component.Asynchronous);

        function componentCreated() {
            if (component.status == Component.Ready) {
                var incubator = component.incubateObject(page, {}, Qt.Asynchronous);

                function objectCreated(status) {
                    if (status == Component.Ready) {
                        callback(incubator.object);
                    }
                }
                incubator.onStatusChanged = objectCreated;

            } else if (component.status == Component.Error) {
                console.log("Error loading component:", component.errorString());
            }
        }

        component.statusChanged.connect(componentCreated);
    }

    function pushMmiPlugin(plugin) {
        mmiPlugins.push(plugin);
    }

    Component.onCompleted: {
        // load MMI plugins
        var plugins = application.mmiPluginList()
        for (var i in plugins) {
            createObjectAsynchronously(plugins[i], pushMmiPlugin);
        }
    }

    AccountsModel {
        id: accountsModel

        onDefaultCallAccountIndexChanged: {
            headerSections.selectedIndex = defaultCallAccountIndex
        }
    }

    // background
    Rectangle {
        anchors.fill: parent
        color: Theme.palette.normal.background
    }

    FocusScope {
        id: keypadContainer

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: pageHeader.height
        }
        focus: true

        GridLayout {
            id: keypadLayout

            anchors.fill: parent
            columnSpacing: 0
            rowSpacing: 0

            Item {
                id: topSpacerItem

                Layout.fillHeight: true
                visible: !contactListLoader.visible
            }

            Item {
                id: favoritesListNarrowParent

                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: contactListLoader.item && contactListLoader.item.count > 0 && !page.isGreeterMode

                Loader {
                    id: contactListLoader

                    anchors.fill: parent
                    asynchronous: true

                    sourceComponent: FavoritesGridView {
                        onContactSelected: {
                            // no phone number case:
                            if (contact.phoneNumbers.length === 0) {
                                mainView.viewContact(contact,
                                                     page,
                                                     contactList.listModel)
                            } else {
                                // we have several phone numbers, open a popup to select to desired one
                                if (contact.phoneNumbers.length > 1) {
                                    var dialog = PopupUtils.open(Qt.resolvedUrl("../Dialogs/ChooseNumberDialog.qml"), page, {
                                            'contact': contact
                                        });
                                    dialog.selectedPhoneNumber.connect(
                                                function(number) {
                                                    mainView.populateDialpad(number)
                                                    PopupUtils.close(dialog);
                                                })
                                } else {
                                    mainView.populateDialpad(contact.phoneNumber.number)
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                visible: contactListLoader.visible

                ListItems.ThinDivider {
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        right: parent.right
                        rightMargin: units.gu(2)
                    }
                }
            }

            ColumnLayout {
                spacing: 0

                Item {
                    id: entryWithButtons

                    Layout.fillWidth: true
                    Layout.leftMargin: units.gu(2)
                    Layout.rightMargin: units.gu(2)
                    Layout.preferredHeight: page.compactView ? units.gu(7) : units.gu(10)
                    Layout.alignment: Qt.AlignBottom

                    KeypadEntry {
                        id: keypadEntry
                        objectName: "keypadEntry"

                        anchors {
                            top: parent.top
                            topMargin: units.gu(3)
                            left: parent.left
                            right: parent.right
                        }
                        focus: true
                        placeHolder: i18n.tr("Enter a number")
                        Keys.forwardTo: [callButton]
                        value: mainView.pendingNumberToDial
                        height: page.compactView ? units.gu(2) : units.gu(4)
                        maximumFontSize: page.compactView ? units.dp(20) : units.dp(30)
                        onCommitRequested: {
                            callButton.clicked()
                        }
                    }
                }

                Item {
                    id: keypadEntryDivider

                    Layout.fillWidth: true

                    ListItems.ThinDivider {
                        id: divider

                        anchors {
                            left: parent.left
                            leftMargin: units.gu(2)
                            right: parent.right
                            rightMargin: units.gu(2)
                        }
                    }
                }

                Item {
                    id: favoritesListWideParent

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
            }

            ContactWatcher {
                id: contactWatcher
                identifier: keypadEntry.value
                // for this contact watcher we are only interested in matching phone numbers
                addressableFields: ["tel"]
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignCenter
                Layout.maximumWidth: page.isWide && page.width <= units.gu(90) ? units.gu(40) : units.gu(50)
                Layout.maximumHeight: units.gu(45)

                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.leftMargin: units.gu(2)
                    Layout.rightMargin: units.gu(2)
                    Layout.topMargin: units.gu(1)
                    Layout.bottomMargin: units.gu(1)
                    Layout.preferredHeight: page.compactView ? units.gu(3): units.gu(4)

                    Label {
                        id: contactLabel

                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: contactWatcher.isUnknown ? "" : contactWatcher.alias
                        color: theme.palette.normal.backgroundSecondaryText
                        opacity: text != "" ? 1 : 0
                        visible: opacity > 0 && !page.isGreeterMode
                        fontSize: "medium"
                        Behavior on opacity {
                            LomiriNumberAnimation { }
                        }
                    }

                    ContactDialPadSearch {
                        id: contactSearch

                        anchors.fill: parent
                        visible: contactWatcher.isUnknown
                        clip: true

                        phoneNumberField: input.text

                        onContactSelected: {
                            input.text = phoneNumber
                        }

                        Behavior on opacity {
                            LomiriNumberAnimation { }
                        }

                        Connections {
                            target: keypad
                            enabled: mainView.settings.contactSearchWithDialPad && !isInEmergencyMode
                            onKeyPressed : {
                                if (keycode == Qt.Key_Backspace) {
                                    contactSearch.pop()
                                } else {
                                    contactSearch.push(keyText)
                                }
                            }
                            onKeyPressAndHold : {
                                if (keycode == Qt.Key_1) {
                                    contactSearch.clearAll()

                                }
                            }
                        }
                        Connections {
                            target: backspace
                            enabled: mainView.settings.contactSearchWithDialPad && !isInEmergencyMode
                            onClicked : contactSearch.pop()
                            onPressAndHold : contactSearch.clearAll()
                        }
                    }
                }

                Keypad {
                    id: keypad
                    showVoicemail: true

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: units.gu(2)
                    Layout.rightMargin: units.gu(2)
                    Layout.bottomMargin: units.gu(2)
                    Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter

                    labelPixelSize: page.compactView ? units.dp(20) : units.dp(30)
                    spacing: page.compactView ? 0 : 5
                    onKeyPressed: {
                        // handle special keys (backspace, arrows, etc)
                        keypadEntry.handleKeyEvent(keycode, keychar)

                        if (keycode == Qt.Key_Space) {
                            return
                        }

                        callManager.playTone(keychar);
                        input.insert(input.cursorPosition, keychar)
                        if(checkMMI(dialNumber)) {
                            // check for custom strings
                            for (var i in mmiPlugins) {
                                if (mmiPlugins[i].code == dialNumber) {
                                    dialNumber = ""
                                    mmiPlugins[i].trigger()
                                }
                            }
                        }
                    }
                    onKeyPressAndHold: {
                        // we should only call voicemail if the keypad entry was empty,
                        // but as we add numbers when onKeyPressed is triggered, the keypad entry will be "1"
                        if (keycode == Qt.Key_1 && dialNumber == "1") {
                            dialNumber = ""
                            mainView.callVoicemail()
                        } else if (keycode == Qt.Key_0) {
                            // replace 0 by +
                            input.remove(input.cursorPosition - 1, input.cursorPosition)
                            input.insert(input.cursorPosition, "+")
                        } else if (dialNumber.length > 1 && keycode == Qt.Key_ssharp) {
                            // replace '#' by ';'. don't do this if this itself is the first character
                            input.remove(input.cursorPosition - 1, input.cursorPosition)
                            input.insert(input.cursorPosition, ";")
                        } else if (dialNumber.length > 1 && keycode == Qt.Key_Asterisk) {
                            // replace '*' by ','. don't do this if this itself is the first character
                            input.remove(input.cursorPosition - 1, input.cursorPosition)
                            input.insert(input.cursorPosition, ",")
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        id: footer

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        GridLayout {
            id: footerLayout

            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            Layout.maximumWidth: keypad.Layout.maximumWidth
            columnSpacing: 0
            rowSpacing: 0

            CustomButton {
                id: addContact

                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.preferredWidth: units.gu(6)
                Layout.preferredHeight: units.gu(6)

                icon: "contact-new"
                iconWidth: units.gu(3)
                iconHeight: units.gu(3)
                opacity: !page.isGreeterMode && (keypadEntry.value !== "" && contactWatcher.isUnknown) ? 1.0 : 0.0

                Behavior on opacity {
                    LomiriNumberAnimation { }
                }

                Behavior on width {
                    LomiriNumberAnimation { }
                }

                onClicked: mainView.addNewPhone(keypadEntry.value)
            }

            CallButton {
                id: callButton
                objectName: "callButton"
                enabled: mainView.telepathyReady

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: units.gu(21)

                onClicked: {
                    if (dialNumber == "") {
                        if (mainView.greeterMode) {
                            return;
                        }
                        keypadEntry.value = generalSettings.lastCalledPhoneNumber
                        return;
                    }

                    if (mainView.greeterMode && !mainView.isEmergencyNumber(dialNumber)) {
                        // we only allow users to call any number in greeter mode if there are
                        // no sim cards present. The operator will block the number if it thinks
                        // it's necessary.
                        // for phone accounts, active means the the status is not offline:
                        // "nomodem", "nosim" or "flightmode"

                        var denyEmergencyCall = false
                        // while in flight mode we can't detect if sims are present in some devices
                        if (telepathyHelper.flightMode) {
                            denyEmergencyCall = true
                        } else {
                            for (var i in accountsModel.activeAccounts) {
                                var account = accountsModel.activeAccounts[i]
                                if (account.type == AccountEntry.PhoneAccount) {
                                    denyEmergencyCall = true;
                                }
                            }
                        }
                        if (denyEmergencyCall) {
                            // if there is at least one sim card present, just ignore the call
                            showNotification(i18n.tr("Emergency call"), i18n.tr("This is not an emergency number."))
                            keypadEntry.value = "";
                            return;
                        }

                        // this is a special case, we need to call using callEmergency() directly to avoid
                        // all network and dual sim checks we have in mainView.call()
                        mainView.callEmergency(keypadEntry.value)
                        return;
                    }

                    console.log("Starting a call to " + keypadEntry.value);
                    mainView.call(keypadEntry.value);
                }
            }

            CustomButton {
                id: backspace
                objectName: "eraseButton"

                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.preferredWidth: units.gu(6)
                Layout.preferredHeight: units.gu(6)

                icon: "erase"
                iconWidth: units.gu(3)
                iconHeight: units.gu(3)
                opacity: input.text !== "" ? 1 : 0

                Behavior on opacity {
                    LomiriNumberAnimation { }
                }

                Behavior on width {
                    LomiriNumberAnimation { }
                }

                onPressAndHold: input.text = ""

                onClicked:  {
                    if (input.cursorPosition > 0)  {
                        input.remove(input.cursorPosition, input.cursorPosition - 1)
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: callAnimation

        PropertyAction {
            target: callButton
            property: "color"
            value: theme.palette.normal.negative
        }

        ParallelAnimation {
            LomiriNumberAnimation {
                target: keypadContainer
                property: "opacity"
                to: 0.0
                duration: LomiriAnimation.SlowDuration
            }
            LomiriNumberAnimation {
                target: callButton
                property: "iconRotation"
                to: -90.0
                duration: LomiriAnimation.SlowDuration
            }
        }
        ScriptAction {
            script: {
                mainView.switchToLiveCall(i18n.tr("Calling"), keypadEntry.value)
                keypadEntry.value = ""
                callButton.iconRotation = 0.0
                keypadContainer.opacity = 1.0
                callButton.color = callButton.defaultColor
            }
        }
    }

    DialerBottomEdge {
        id: bottomEdge
        enabled: !mainView.greeterMode
        height: page.height
        hint.text: i18n.tr("Recent")
        hint.visible: enabled
    }

    ContactDetailPhoneNumberTypeModel {
       id: phoneTypeModel
    }
}
