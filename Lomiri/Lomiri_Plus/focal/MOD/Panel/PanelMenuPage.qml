/*
 * Copyright 2013-2016 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.3 as ListItems
import Lomiri.Indicators 0.1 as Indicators
import "../Components"
import "Indicators"
// ENH046 - Lomiri Plus Settings
import Lomiri.Settings.Menus 0.1 as Menus
// ENH046 - End
// ENH102 - App suspension indicator
import QtQuick.Layouts 1.12
// ENH102 - End
// ENH196 - Battery stats tracking
import Powerd 0.1
import QtQuick.Controls 2.12 as QQC2
// ENH196 - End

PageStack {
    id: root

    property var submenuIndex: undefined
    property QtObject menuModel: null
    property Component factory
    // ENH028 - Open indicators via gesture
    property bool inverted: false
    property string titleText

    signal modelCountChanged(int count)
    // ENH028 - End
    // ENH056 - Quick toggles
    property string identifier
    property int menuIndex: -1
    property var rotationToggle
    property var flashlightToggle
    property var autoDarkModeToggle
    property var darkModeToggle
    property var desktopModeToggle
    property var silentModeToggle
    property var flightModeToggle
    property var mobileDataToggle
    property var wifiToggle
    property var bluetoothToggle
    property var locationToggle
    property var immersiveToggle
    property var hotspotToggle
    property var autoBrightnessToggle
    property var brightnessSlider
    property var volumeSlider
    property var dateItem
    property var lockItem
    // ENH056 - End
    // ENH064 - Dynamic Cove
    property var mediaPlayer
    property var playbackItem
    // ENH064 - End
    // ENH046 - Lomiri Plus Settings
    property real topPanelMargin: 0
    // ENH046 - End

    Connections {
        id: dynamicChanges
        target: root.menuModel
        property bool ready: false

        // fix async creation with signal from model before it's finished.
        onRowsInserted: {
            if (submenuIndex !== undefined && first <= submenuIndex) {
                reset(true);
            }
        }
        onRowsRemoved: {
            if (submenuIndex !== undefined && first <= submenuIndex) {
                reset(true);
            }
        }
        onModelReset: {
            if (root.submenuIndex !== undefined) {
                reset(true);
            }
        }
    }

    Component.onCompleted: {
        reset(true);
        dynamicChanges.ready = true;
    }

    function reset(clearModel) {
        if (clearModel) {
            clear();
            var model = root.submenuIndex == undefined ? menuModel : menuModel.submenu(root.submenuIndex)
            if (model) {
                push(pageComponent, { "menuModel": model });
            }
        } else if (root.currentPage) {
            root.currentPage.reset();
        }
    }

    Component {
        id: pageComponent
        Page {
            id: page

            property alias menuModel: listView.model
            property alias title: backLabel.title
            property bool isSubmenu: false

            function reset() {
                // ENH046 - Lomiri Plus Settings
                // listView.positionViewAtBeginning();
                panelFlickable.contentY = 0
                // ENH046 - End
            }

            property QtObject factory: root.factory.createObject(page, { menuModel: page.menuModel } )

            header: PageHeader {
                id: backLabel
                visible: page.isSubmenu
                // ENH028 - Open indicators via gesture
                anchors.top: parent.top
                anchors.topMargin: labelHeader.height
                StyleHints {
                    backgroundColor: "transparent"
                }
                ListItems.ThinDivider {
                    visible: root.inverted
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                }
                // ENH028 - End
                leadingActionBar.actions: [
                    Action {
                        iconName: "back"
                        text: i18n.tr("Back")
                        onTriggered: {
                            root.pop();
                        }
                    }
                ]
            }
            // ENH207 - Disable bottom gesture in indicator panels
            Component.onCompleted: {
                if (page.hasOwnProperty("forceDisableBottmGesture")) {
                    page.forceDisableBottmGesture = true
                }
            }
            // ENH207 - End
            
            // ENH028 - Open indicators via gesture
            // Fix height binding loop
            height: parent.height

            LPHeader {
                id: labelHeader
                    
                readonly property real maximumHeightWhenInverted: units.gu(50)
                readonly property real idealRechableHeight: shell.convertFromInch(shell.settings.pullDownHeight)
                readonly property real idealMaxHeight: shell.height - idealRechableHeight
                readonly property real idealExpandableHeight: idealRechableHeight + units.gu(10)

                z: page.header.z + 1
                expandable: shell.height >= idealExpandableHeight && (shell.settings.enablePanelHeaderExpand || root.inverted)
                defaultHeight: root.topPanelMargin
                maxHeight: idealMaxHeight

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                Connections {
                    target: root
                    onInvertedChanged: {
                        labelHeader.collapse()

                        if (target.inverted && labelHeader.expandable) {
                            if (shell.settings.expandPanelHeaderWhenBottom) {
                                labelHeader.expand()
                            }
                        } else {
                            labelHeader.collapse()
                        }
                    }
                }

                Rectangle {
                    color: "transparent"
                    anchors.fill: parent

                    Label {
                        id: timeDateLabel

                        textSize: Label.XLarge
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: root.titleText
                        opacity: labelHeader.height - labelHeader.defaultHeight < labelHeader.maxHeight * 0.2 ? 0
                                            : 1 - ((labelHeader.maxHeight - labelHeader.height) / ((labelHeader.maxHeight * 0.8) - labelHeader.defaultHeight))
                        visible: opacity > 0
                    }
                }
            }
            ListItems.ThinDivider {
                anchors {
                    bottom: panelFlickable.top
                    left: parent.left
                    right: parent.right
                }
            }
            // ENH028 - End

            // ENH046 - Lomiri Plus Settings
            LPCollapseHeaderSwipeArea {
                enabled: pageHeader.expandable && pageHeader.expanded
                pageHeader: labelHeader
                z: panelFlickable.z + 1
                anchors.fill: parent
            }

            LPFlickable {
                id: panelFlickable

                pageHeader: labelHeader
                clip: true
                anchors {
                    top: page.isSubmenu ? backLabel.bottom : parent.top
                    topMargin: root.inverted ? labelHeader.height : labelHeader.height - root.topPanelMargin
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: Qt.inputMethod.visible ? (Qt.inputMethod.keyboardRectangle.height - root.anchors.bottomMargin) : 0
                }
                
                Behavior on bottomMargin {
                    NumberAnimation {
                        duration: 175
                        easing.type: Easing.OutQuad
                    }
                }
                // TODO - does ever frame.
                onBottomMarginChanged: {
                    listView.positionViewAtIndex(listView.currentIndex, ListView.End)
                }

                interactive: labelHeader.expandable ? !labelHeader.expanded : contentHeight > height
                contentHeight: customMenuItems.height + listView.height + (customBottomMenuItems.active ? customBottomMenuItems.height : 0)
                contentWidth: parent.width

                Loader {
                    id: customMenuItems

                    asynchronous: true
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    sourceComponent: {
                        switch (root.identifier) {
                            case "ayatana-indicator-session":
                                return lomiriSettingsComponent
                            break
                            case "ayatana-indicator-keyboard":
                                if (shell.settings.enableOSKToggleInIndicator) {
                                    return toggleOSKComponent
                                }
                            break
                        }
                        return null
                    }

                    Component {
                        id: lomiriSettingsComponent;
                        
                        ColumnLayout {
                            spacing: 0
                            // ENH102 - App suspension indicator
                            Menus.SwitchMenu {
                                id: appSuspensionSwitch

                                Layout.fillWidth: true

                                visible: shell.focusedAppName !== ""  && shell.settings.enableAppSuspensionToggleIndicator
                                                && !shell.isWindowedMode
                                text: "Do not suspend"
                                iconSource: shell.focusedAppIcon
                                highlightWhenPressed: false

                                onCheckedChanged: {
                                    if (checked) {
                                        shell.exemptFromLifecycle(shell.focusedAppId)
                                    } else {
                                        shell.removeExemptFromLifecycle(shell.focusedAppId)
                                    }
                                }

                                Binding {
                                    target: appSuspensionSwitch
                                    property: "checked"
                                    value: shell.focusedAppIsExemptFromLifecycle
                                }
                            }
                            // ENH102 - End
                            // ENH103 - Active screen indicator
                            Menus.SwitchMenu {
                                id: activeScreenSwitch

                                Layout.fillWidth: true

                                visible: shell.settings.enableActiveScreenToggleIndicator
                                text: "Disable screen timeout"
                                iconSource: "image://theme/preferences-desktop-display-symbolic"
                                highlightWhenPressed: false

                                onCheckedChanged: shell.isScreenActive = checked

                                Binding {
                                    target: activeScreenSwitch
                                    property: "checked"
                                    value: shell.isScreenActive
                                }
                            }
                            // ENH103 - End
                            // ENH115 - Standalone Immersive mode
                            Menus.SwitchMenu {
                                id: immersiveModeSwitch

                                Layout.fillWidth: true

                                visible: shell.settings.enableImmersiveModeToggleIndicator
                                text: "Immersive Mode"
                                iconSource: "image://theme/media-record"
                                highlightWhenPressed: false

                                onCheckedChanged: shell.settings.immersiveMode = checked

                                Binding {
                                    target: immersiveModeSwitch
                                    property: "checked"
                                    value: shell.settings.immersiveMode
                                }
                            }
                            // ENH115 - End
                            // ENH152 - Touch visuals
                            Menus.SwitchMenu {
                                id: showTouchVisualsSwitch

                                Layout.fillWidth: true

                                visible: shell.settings.enableShowTouchVisualsToggleIndicator
                                text: "Show touch visuals"
                                iconSource: "image://theme/gestures"
                                highlightWhenPressed: false

                                onCheckedChanged: shell.settings.showTouchVisuals = checked

                                Binding {
                                    target: showTouchVisualsSwitch
                                    property: "checked"
                                    value: shell.settings.showTouchVisuals
                                }
                            }
                            // ENH152 - End
                            // ENH116 - Standalone Dark mode toggle
                            Menus.SwitchMenu {
                                id: autoDarkModeSwitch

                                Layout.fillWidth: true

                                visible: shell.settings.enableAutoDarkModeToggleIndicator
                                text: "Scheduled Dark Mode"
                                iconSource: "image://theme/timer"
                                highlightWhenPressed: false

                                onCheckedChanged: shell.settings.enableAutoDarkMode = checked

                                Binding {
                                    target: autoDarkModeSwitch
                                    property: "checked"
                                    value: shell.settings.enableAutoDarkMode
                                }
                            }
                            Menus.SwitchMenu {
                                id: darkModeSwitch

                                Layout.fillWidth: true

                                visible: shell.settings.enableDarkModeToggleIndicator && !shell.settings.enableAutoDarkMode
                                text: "Dark Mode"
                                iconSource: "image://theme/night-mode"
                                highlightWhenPressed: false

                                onCheckedChanged: {
                                    if (checked) {
                                        shell.themeSettings.setToDark()
                                    } else {
                                        shell.themeSettings.setToAmbiance()
                                    }
                                }

                                Binding {
                                    target: darkModeSwitch
                                    property: "checked"
                                    value: shell.themeSettings.isDarkMode
                                }
                            }
                            // ENH136 - Separate desktop mode per screen
                            Menus.SwitchMenu {
                                id: desktopModeSwitch

                                Layout.fillWidth: true

                                visible: shell.haveMultipleScreens
                                text: "Desktop mode"
                                iconSource: "image://theme/computer-symbolic"
                                highlightWhenPressed: false

                                onCheckedChanged: shell.isDesktopMode = checked

                                Binding {
                                    target: desktopModeSwitch
                                    property: "checked"
                                    value: shell.isDesktopMode
                                }
                            }
                            // ENH136 - End
                            // ENH116 - End
                            Menus.BaseLayoutMenu {
                                property QtObject menuData: null
                                property int menuIndex: -1

                                Layout.fillWidth: true

                                visible: !shell.settings.onlyShowLomiriSettingsWhenUnlocked || !shell.showingGreeter
                                text: "Lomiri Plus Settings..."
                                enabled: true
                                backColor: Qt.rgba(1,1,1,0.07)
                                highlightWhenPressed: false

                                onTriggered: shell.showSettings()

                                slots: Icon {
                                    name: "settings"
                                    height: units.gu(3)
                                    width: height
                                    color: theme.palette.normal.backgroundText
                                    SlotsLayout.position: SlotsLayout.Trailing
                                }
                            }
                        }
                    }

                    Component {
                        id: toggleOSKComponent

                        Menus.SwitchMenu {
                            id: switchItem

                            text: "On-screen keyboard"
                            iconSource: "image://theme/input-keyboard-symbolic"
                            highlightWhenPressed: false

                            onCheckedChanged: lomiriSettings.alwaysShowOsk = checked
                            
                            Binding {
                                target: switchItem
                                property: "checked"
                                value: lomiriSettings.alwaysShowOsk
                            }
                        }
                    }

                    // ENH195 - Battery graph in indicator
                    Component {
                        id: batteryComponent

                        ColumnLayout {
                            id: batteryLayout

                            property bool expandScreenTime: false

                            spacing: 0

                            onVisibleChanged: {
                                if (!visible) {
                                    expandScreenTime = false
                                }
                            }

                            LPBatteryGraph {
                                Layout.fillWidth: true
                                visible: shell.settings.enableBatteryGraphIndicator
                            }

                            // ENH196 - Battery stats tracking
                            LiveTimer {
                                frequency: shell.batteryTracking && Powerd.status === Powerd.On && batteryLayout.visible ? LiveTimer.Minute : LiveTimer.Disabled
                                onTrigger: shell.batteryTracking.updateScreenTimeValues()
                            }

                            Menus.StandardMenu {
                                Layout.fillWidth: true
                                visible: shell.settings.enableBatteryTracking && shell.settings.enableBatteryStatsIndicator && shell.settings.collapsibleScreenTimeIndicators
                                text: i18n.tr("Screen Time")
                                iconSource: batteryLayout.expandScreenTime ? "image://theme/go-up" : "image://theme/go-down"
                                onTriggered: batteryLayout.expandScreenTime = !batteryLayout.expandScreenTime
                            }

                            ColumnLayout {
                                Layout.fillHeight: true
                                visible: shell.settings.enableBatteryTracking && shell.settings.enableBatteryStatsIndicator //&& shell.settings.showScreenTimeSinceLastFullCharged
                                            && (!shell.settings.collapsibleScreenTimeIndicators || (shell.settings.collapsibleScreenTimeIndicators && batteryLayout.expandScreenTime))
                                spacing: 0

                                onVisibleChanged: {
                                    if (visible && shell.batteryTracking) {
                                        shell.batteryTracking.updateScreenTimeValues()
                                    }
                                }

                                Menus.StandardMenu {
                                    Layout.fillWidth: true
                                    visible: shell.settings.enableBatteryStatsIndicator && shell.settings.showScreenTimeSinceLastFullCharged
                                    text: i18n.tr("Since Last Full Charge")
                                    iconSource: ""
                                    highlightWhenPressed: false
                                }

                                Menus.EventMenu {
                                    Layout.fillWidth: true
                                    visible: shell.settings.enableBatteryStatsIndicator && shell.settings.showScreenTimeSinceLastFullCharged

                                    highlightWhenPressed: false
                                    text: i18n.tr("Screen On Time")
                                    time: shell.batteryTracking ? shell.batteryTracking.screenOnTimeSinceLastFull : ""
                                    iconSource: "image://theme/view-on"
                                }

                                Menus.EventMenu {
                                    Layout.fillWidth: true
                                    visible: shell.settings.enableBatteryStatsIndicator && shell.settings.showScreenTimeSinceLastFullCharged

                                    highlightWhenPressed: false
                                    text: i18n.tr("Screen Off Time")
                                    time: shell.batteryTracking ? shell.batteryTracking.screenOffTimeSinceLastFull : ""
                                    iconSource: "image://theme/view-off"
                                }

                                Menus.StandardMenu {
                                    Layout.fillWidth: true
                                    visible: shell.settings.enableBatteryStatsIndicator && shell.settings.showScreenTimeSinceLastCharge
                                    text: shell.batteryTracking ? i18n.tr("Since Last Charge", "Since Last Charge: %1%", shell.batteryTracking.lastChargeBatteryLevel).arg(shell.batteryTracking.lastChargeBatteryLevel)
                                                : i18n.tr("Since Last Charge")
                                    iconSource: ""
                                    highlightWhenPressed: false
                                }

                                Menus.EventMenu {
                                    Layout.fillWidth: true
                                    visible: shell.settings.enableBatteryStatsIndicator && shell.settings.showScreenTimeSinceLastCharge

                                    highlightWhenPressed: false
                                    text: i18n.tr("Screen On Time")
                                    time: shell.batteryTracking ? shell.batteryTracking.screenOnTimeSinceLastCharge : ""
                                    iconSource: "image://theme/view-on"
                                }

                                Menus.EventMenu {
                                    Layout.fillWidth: true
                                    visible: shell.settings.enableBatteryStatsIndicator && shell.settings.showScreenTimeSinceLastCharge

                                    highlightWhenPressed: false
                                    text: i18n.tr("Screen Off Time")
                                    time: shell.batteryTracking ? shell.batteryTracking.screenOffTimeSinceLastCharge : ""
                                    iconSource: "image://theme/view-off"
                                }

                                Menus.StandardMenu {
                                    Layout.fillWidth: true
                                    visible: shell.settings.enableBatteryStatsIndicator && shell.settings.showScreenTimeToday
                                    text: i18n.tr("Today")
                                    iconSource: ""
                                    highlightWhenPressed: false
                                }

                                Menus.EventMenu {
                                    Layout.fillWidth: true
                                    visible: shell.settings.enableBatteryStatsIndicator && shell.settings.showScreenTimeToday

                                    highlightWhenPressed: false
                                    text: i18n.tr("Screen On Time")
                                    time: shell.batteryTracking ? shell.batteryTracking.screenOnTimeToday : ""
                                    iconSource: "image://theme/view-on"
                                }

                                Menus.EventMenu {
                                    Layout.fillWidth: true
                                    visible: shell.settings.enableBatteryStatsIndicator && shell.settings.showScreenTimeToday

                                    highlightWhenPressed: false
                                    text: i18n.tr("Screen Off Time")
                                    time: shell.batteryTracking ? shell.batteryTracking.screenOffTimeToday : ""
                                    iconSource: "image://theme/view-off"
                                }

                                Menus.StandardMenu {
                                    Layout.fillWidth: true
                                    visible: shell.settings.enableBatteryStatsIndicator && shell.settings.showScreenTimeYesterday
                                    text: i18n.tr("Yesterday")
                                    iconSource: ""
                                    highlightWhenPressed: false
                                }

                                Menus.EventMenu {
                                    Layout.fillWidth: true
                                    visible: shell.settings.enableBatteryStatsIndicator && shell.settings.showScreenTimeYesterday

                                    highlightWhenPressed: false
                                    text: i18n.tr("Screen On Time")
                                    time: shell.batteryTracking ? shell.batteryTracking.screenOnTimeYesterday : ""
                                    iconSource: "image://theme/view-on"
                                }

                                Menus.EventMenu {
                                    Layout.fillWidth: true
                                    visible: shell.settings.enableBatteryStatsIndicator && shell.settings.showScreenTimeYesterday

                                    highlightWhenPressed: false
                                    text: i18n.tr("Screen Off Time")
                                    time: shell.batteryTracking ? shell.batteryTracking.screenOffTimeYesterday : ""
                                    iconSource: "image://theme/view-off"
                                }

                                ColumnLayout {
                                    id: historyChartsLayout

                                    Layout.fillWidth: true
                                    visible: shell.settings.showHistoryCharts
                                    spacing: 0

                                    property int dataToDisplay: LPBatteryChart.DataToDisplay.Both

                                    function navigateDisplay() {
                                        if (dataToDisplay < 2) {
                                            dataToDisplay += 1
                                        } else {
                                            dataToDisplay = 0
                                        }
                                    }

                                    Menus.EventMenu {
                                        id: titleMenu

                                        Layout.fillWidth: true

                                        text: {
                                            switch (swipeView.currentItem.type) {
                                                case LPBatteryChart.Type.Day:
                                                    return shell.batteryTracking ? i18n.tr("Last %1 days").arg(shell.batteryTracking.daysData.length)
                                                                : i18n.tr("Previous days")
                                                case LPBatteryChart.Type.FullyCharged:
                                                    return i18n.tr("Last Fully Charged")
                                                case LPBatteryChart.Type.LastCharge:
                                                    return i18n.tr("Last Charge")
                                            }
                                        }
                                        time: {
                                            switch (swipeView.currentItem.dataToDisplay) {
                                                case LPBatteryChart.DataToDisplay.Both:
                                                    return i18n.tr("Screen Time")
                                                case LPBatteryChart.DataToDisplay.ScreenOn:
                                                    return i18n.tr("Screen On")
                                                case LPBatteryChart.DataToDisplay.ScreenOff:
                                                    return i18n.tr("Screen Off")
                                            }
                                        }
                                        highlightWhenPressed: false
                                        iconSource: "image://theme/history"
                                    }

                                    QQC2.SwipeView {
                                        id: swipeView

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: units.gu(40)

                                        currentIndex: 0

                                        LPBatteryChart {
                                            screenOnAverage: shell.batteryTracking ? shell.batteryTracking.screenOnTimeDaysAverage : 0
                                            screenOffAverage: shell.batteryTracking ? shell.batteryTracking.screenOffTimeDaysAverage : 0
                                            dataToDisplay: historyChartsLayout.dataToDisplay
                                            type: LPBatteryChart.Type.Day
                                            modelData: shell.batteryTracking ? shell.batteryTracking.daysData : []
                                            onClicked: historyChartsLayout.navigateDisplay()
                                        }
                                        LPBatteryChart {
                                            screenOnAverage: shell.batteryTracking ? shell.batteryTracking.screenOnTimeFullyChargedAverage : 0
                                            screenOffAverage: shell.batteryTracking ? shell.batteryTracking.screenOffTimeFullyChargedAverage : 0
                                            dataToDisplay: historyChartsLayout.dataToDisplay
                                            type: LPBatteryChart.Type.FullyCharged
                                            modelData: shell.batteryTracking ? shell.batteryTracking.fullyChargedData : []
                                            onClicked: historyChartsLayout.navigateDisplay()
                                        }
                                        LPBatteryChart {
                                            screenOnAverage: shell.batteryTracking ? shell.batteryTracking.screenOnTimeLastChargeAverage : 0
                                            screenOffAverage: shell.batteryTracking ? shell.batteryTracking.screenOffTimeLastChargeAverage : 0
                                            dataToDisplay: historyChartsLayout.dataToDisplay
                                            type: LPBatteryChart.Type.LastCharge
                                            modelData: shell.batteryTracking ? shell.batteryTracking.lastChargeData : []
                                            onClicked: historyChartsLayout.navigateDisplay()
                                        }
                                    }

                                    Menus.EventMenu {
                                        Layout.fillWidth: true

                                        highlightWhenPressed: false
                                        text: {
                                            if (swipeView.currentItem.dataToDisplay !== LPBatteryChart.DataToDisplay.ScreenOff) {
                                                return i18n.tr("On: %1").arg(swipeView.currentItem.screenOnAverage)
                                            } else {
                                                return i18n.tr("Off: %1").arg(swipeView.currentItem.screenOffAverage)
                                            }
                                        }
                                        time: {
                                            if (swipeView.currentItem.dataToDisplay === LPBatteryChart.DataToDisplay.Both) {
                                                return i18n.tr("Off: %1").arg(swipeView.currentItem.screenOffAverage)
                                            } else {
                                                return  ""
                                            }
                                        }
                                        iconSource: ""
                                    }

                                    QQC2.PageIndicator {
                                        id: pageIndicator

                                        Layout.alignment: Qt.AlignHCenter
                                        visible: count > 1
                                        count: swipeView.count
                                        currentIndex: swipeView.currentIndex
                                        delegate: Rectangle {
                                            color: index === pageIndicator.currentIndex ? theme.palette.normal.backgroundText : theme.palette.normal.foreground
                                            width: units.gu(1)
                                            height: width
                                            radius: width / 2
                                        }
                                    }
                                }
                            }
                            // ENH196 - End
                        }
                    }
                    // ENH195 - End
                }
                Loader {
                    id: customBottomMenuItems

                    asynchronous: true
                    anchors {
                        top: listView.bottom
                        left: parent.left
                        right: parent.right
                    }
                    sourceComponent: {
                        switch (root.identifier) {
                            // ENH195 - Battery graph in indicator
                            case "ayatana-indicator-power":
                                return batteryComponent
                            // ENH195 - End
                            // ENH204 - Bluetooth device list
                            case "ayatana-indicator-bluetooth":
                                if (shell.settings.enableBluetoothDevicesList
                                        && root.bluetoothToggle && root.bluetoothToggle.checked) {
                                    return bluetoothComponent
                                }
                            // ENH204 - End
                            break
                        }
                        return null
                    }

                    Component {
                        id: bluetoothComponent

                        LPBluetoothDevices {}
                    }
                }
                // ENH046 - End

                ListView {
                    id: listView
                    objectName: "listView"
                    // ENH028 - Open indicators via gesture
                    clip: true
                    // ENH028 - End

                    anchors {
                        // ENH028 - Open indicators via gesture
                        // top: page.isSubmenu ? backLabel.bottom : parent.top
                        // ENH046 - Lomiri Plus Settings
                        //top: page.isSubmenu ? backLabel.bottom : labelHeader.bottom
                        top: customMenuItems.bottom
                        // ENH046 - End
                        // ENH028 - End
                        left: parent.left
                        right: parent.right
                        // ENH046 - Lomiri Plus Settings
                        /*
                        bottom: parent.bottom
                        bottomMargin: Qt.inputMethod.visible ? (Qt.inputMethod.keyboardRectangle.height - root.anchors.bottomMargin) : 0

                        Behavior on bottomMargin {
                            NumberAnimation {
                                duration: 175
                                easing.type: Easing.OutQuad
                            }
                        }
                        // TODO - does ever frame.
                        onBottomMarginChanged: {
                            listView.positionViewAtIndex(listView.currentIndex, ListView.End)
                        }
                        */
                        // ENH046 - End
                    }

                    // Don't load all the delegates (only max of 3 pages worth -1/0/+1)
                    cacheBuffer: Math.max(height * 3, units.gu(70))

                    // ENH046 - Lomiri Plus Settings
                    // Only allow flicking if the content doesn't fit on the page
                    // interactive: contentHeight > height
                    interactive: false
                    height: contentHeight
                    // ENH046 - End

                    property int selectedIndex: -1
                    property bool blockCurrentIndexChange: false
                    // for count = 0
                    onCountChanged: {
                        if (count == 0 && selectedIndex != -1) {
                            selectedIndex = -1;
                        }
                        // ENH028 - Open indicators via gesture
                        modelCountChanged(count)
                        // ENH028 - End
                    }
                    // for highlight following
                    onSelectedIndexChanged: {
                        if (currentIndex != selectedIndex) {
                            var blocked = blockCurrentIndexChange;
                            blockCurrentIndexChange = true;

                            currentIndex = selectedIndex;

                            blockCurrentIndexChange = blocked;
                        }
                    }
                    // for item addition/removal
                    onCurrentIndexChanged: {
                        if (!blockCurrentIndexChange) {
                            if (selectedIndex != -1 && selectedIndex != currentIndex) {
                                selectedIndex = currentIndex;
                            }
                        }
                    }

                    Connections {
                        target: listView.model ? listView.model : null
                        onRowsAboutToBeRemoved: {
                            // track current item deletion.
                            if (listView.selectedIndex >= first && listView.selectedIndex <= last) {
                                listView.selectedIndex = -1;
                            }
                        }
                    }

                    delegate: Loader {
                        id: loader
                        objectName: "menuItem" + index
                        width: ListView.view.width
                        visible: status == Loader.Ready

                        property int modelIndex: index
                        sourceComponent: page.factory.load(model)

                        onLoaded: {
                            // ENH028 - Open indicators via gesture
                            if (root.identifier == "indicator-datetime"
                                    || root.identifier == "ayatana-indicator-datetime") {
                                if (model.action == "indicator.phone.open-calendar-app") {
                                    root.dateItem = item
                                }
                            }
                            if (root.identifier == "indicator-session"
                                    || root.identifier == "ayatana-indicator-session") {
                                if (model.action == "indicator.switch-to-screensaver") {
                                    root.lockItem = item
                                }
                            }
                            // ENH028 - End
                            // ENH064 - Dynamic Cove
                            if (root.identifier == "indicator-sound"
                                    || root.identifier == "ayatana-indicator-sound") {
                                if (model.type == "com.canonical.unity.media-player"
                                        || model.type == "com.canonical.lomiri.media-player"
                                        || model.type == "org.ayatana.indicator.media-player") {
                                    root.mediaPlayer = item
                                }
                                if (model.type == "com.canonical.unity.playback-item"
                                        || model.type == "com.canonical.lomiri.playback-item"
                                        || model.type == "org.ayatana.indicator.playback-item") {
                                    root.playbackItem = item
                                }
                            }
                            // ENH064 - End
                            // ENH056 - Quick toggles
                            if (model.type == "com.canonical.unity.slider"
                                    || model.type == "org.ayatana.indicator.slider") {
                                if ((root.identifier == "indicator-power" || root.identifier == "ayatana-indicator-power")
                                            && model.action == "indicator.brightness") {
                                    root.brightnessSlider = item
                                }
                                if ((root.identifier == "indicator-sound" || root.identifier == "ayatana-indicator-sound")
                                            && model.action == "indicator.volume") {
                                    root.volumeSlider = item
                                }
                            }
                            if (model.type == "com.canonical.indicator.switch"
                                    || model.type == "org.ayatana.indicator.switch") {
                                if ((root.identifier == "indicator-rotation-lock" || root.identifier == "ayatana-indicator-rotation-lock")
                                        && model.action == "indicator.rotation-lock") {
                                    root.rotationToggle = item
                                }
                                if ((root.identifier == "indicator-power" || root.identifier == "ayatana-indicator-power")
                                        && model.action == "indicator.flashlight") {
                                    root.flashlightToggle = item
                                }
                                if (root.identifier == "kugiigi-indicator-darkmode" && model.action == "indicator.auto") {
                                    root.autoDarkModeToggle = item
                                }
                                if (root.identifier == "kugiigi-indicator-darkmode" && model.action == "indicator.toggle") {
                                    root.darkModeToggle = item
                                }
                                if ((root.identifier == "indicator-session" || root.identifier == "ayatana-indicator-session")
                                        && model.action == "indicator.usage-mode") {
                                    root.desktopModeToggle = item
                                }
                                if ((root.identifier == "indicator-sound" || root.identifier == "ayatana-indicator-sound")
                                        && model.action == "indicator.silent-mode") {
                                    root.silentModeToggle = item
                                }
                                if (root.identifier == "indicator-network" && model.action == "indicator.airplane.enabled") {
                                    root.flightModeToggle = item
                                }
                                if (root.identifier == "indicator-network" && model.action == "indicator.mobiledata.enabled") {
                                    root.mobileDataToggle = item
                                }
                                if (root.identifier == "indicator-network" && model.action == "indicator.wifi.enable") {
                                    root.wifiToggle = item
                                }
                                if ((root.identifier == "indicator-bluetooth" || root.identifier == "ayatana-indicator-bluetooth")
                                        && model.action == "indicator.bluetooth-enabled") {
                                    root.bluetoothToggle = item
                                }
                                if (root.identifier == "indicator-location" && model.action == "indicator.location-detection-enabled") {
                                    root.locationToggle = item
                                }
                                if (root.identifier == "kugiigi-indicator-immersive" && model.action == "indicator.toggle") {
                                    root.immersiveToggle = item
                                }
                                if (root.identifier == "indicator-network" && model.action == "indicator.hotspot.enable") {
                                    root.hotspotToggle = item
                                }
                                if ((root.identifier == "indicator-power" || root.identifier == "ayatana-indicator-power")
                                        && model.action == "indicator.auto-brightness") {
                                    root.autoBrightnessToggle = item
                                }
                            }

                            if (item.hasOwnProperty("parentMenuIndex")) {
                                item.parentMenuIndex = root.menuIndex;
                            }
                            // ENH056 - End
                            if (item.hasOwnProperty("selected")) {
                                item.selected = listView.selectedIndex == index;
                            }
                            if (item.hasOwnProperty("menuSelected")) {
                                item.menuSelected.connect(function() { listView.selectedIndex = index; });
                            }
                            if (item.hasOwnProperty("menuDeselected")) {
                                item.menuDeselected.connect(function() { listView.selectedIndex = -1; });
                            }
                            if (item.hasOwnProperty("menuData")) {
                                item.menuData = Qt.binding(function() { return model; });
                            }
                            if (item.hasOwnProperty("menuIndex")) {
                                item.menuIndex = Qt.binding(function() { return modelIndex; });
                            }
                            if (item.hasOwnProperty("clicked")) {
                                item.clicked.connect(function() {
                                    if (model.hasSubmenu) {
                                        page.menuModel.aboutToShow(modelIndex);
                                        root.push(pageComponent, {
                                                 "isSubmenu": true,
                                                 "title": model.label.replace(/_|&/, ""),
                                                 "menuModel": page.menuModel.submenu(modelIndex)
                                        });
                                    }
                                });
                            }
                        }

                        Binding {
                            target: item ? item : null
                            property: "objectName"
                            value: model.action
                        }

                        // TODO: Fixes lp#1243146
                        // This is a workaround for a Qt bug. https://bugreports.qt-project.org/browse/QTBUG-34351
                        Connections {
                            target: listView
                            onSelectedIndexChanged: {
                                if (loader.item && loader.item.hasOwnProperty("selected")) {
                                    loader.item.selected = listView.selectedIndex == index;
                                }
                            }
                        }
                    }
                }
            // ENH046 - Lomiri Plus Settings
            } // Flickable
            // ENH046 - End
        }
    }
}
