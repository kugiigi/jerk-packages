/*
 * Copyright (C) 2013-2017 Canonical Ltd.
 * Copyright (C) 2020 UBports Foundation
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

import QtQuick 2.15
import QtQml 2.15
import Lomiri.Components 1.3
import Lomiri.Layouts 1.0
import QtMir.Application 0.1
import Lomiri.Indicators 0.1
import Utils 0.1
import Lomiri.ApplicationMenu 0.1

import QtQuick.Window 2.2

// ENH056 - Quick toggles
import QtQuick.Layouts 1.12
// ENH056 - End

import "../ApplicationMenus"
import "../Components"
import "../Components/PanelState"
import ".."
import "Indicators"

Item {
    id: root

    readonly property real panelHeight: panelArea.y + minimizedPanelHeight
    readonly property bool fullyClosed: indicators.fullyClosed && applicationMenus.fullyClosed

    property real minimizedPanelHeight: units.gu(3)
    property real expandedPanelHeight: units.gu(7)
    // ENH069 - Wider landscape top panel pages
    // property real menuWidth: partialWidth ? units.gu(40) : width
    property real menuWidth: partialWidth ? shell.settings.widerLandscapeTopPanel ? units.gu(50) : units.gu(40)
                                          // ENH239 - Force show Launcher
                                          //: width
                                          : shell.settings.forceLockLauncher ? width - applicationMenuContentX : width
                                          // ENH239 - End
    // ENH069 - End
    property alias applicationMenuContentX: __applicationMenus.menuContentX

    property alias applicationMenus: __applicationMenus
    property alias indicators: __indicators
    property bool fullscreenMode: false
    property real panelAreaShowProgress: 1.0
    property bool greeterShown: false
    property bool hasKeyboard: false
    property bool supportsMultiColorLed: true
    // ENH028 - Open indicators via gesture
    property string dateTimeString
    property bool hasNotifications: false
    // ENH028 - End
    // ENH036 - Use punchole as battery indicator
    property bool batteryCircleEnabled
    property real batteryCircleBorder
    property bool batteryCharging: false
    property int batteryLevel: 0
    // ENH036 - End
    // ENH048 - Always hide panel mode
    property bool forceHidePanel: true
    // ENH048 - End
    // ENH064 - Dynamic Cove
    property var mediaPlayer
    property var playbackItem
    // ENH064 - End
    // ENH002 - Notch/Punch hole fix
    property real leftMarginBlur
    property real topMarginBlur
    // ENH002 - End
    // ENH122 - Option to transparent top bar when in spread
    property bool transparentTopBar: false
    property real topBarOpacityOverride: 0
    // ENH122 - End
    // ENH139 - System Direct Actions
    readonly property alias quickToggleItems: __indicators.quickToggleItems
    // ENH139 - End
    // ENH170 - Adjust top panel based on Drawer and Indicator panels
    property real spreadDragProgress: 0
    property bool spreadShown: false
    property real drawerProgress: 0
    property real drawerOpacity: 0
    property color drawerColor: "black"
    // ENH170 - End
    property var blurSource : null
    property bool lightMode : false

    // Whether our expanded menus should take up the full width of the panel
    // ENH066 - Option to always full width the top panel menu
    // property bool partialWidth: width >= units.gu(60)
    property bool partialWidth: !(shell.settings.alwaysFullWidthTopPanel && (shell.orientation == Qt.PortraitOrientation
                                                                                    || shell.orientation == Qt.InvertedPortraitOrientation)
                                 )
                                 && width >= units.gu(60)
    // ENH066 - End
    // ENH046 - Lomiri Plus Settings
    property real topPanelMargin: 0
    // ENH046 - End
    // ENH171 - Add blur to Top Panel and Drawer
    property var topPanelBlurSource: null
    // ENH171 - End

    property string mode: "staged"
    property PanelState panelState

    property bool temporarilyShown: false

    function temporarilyShow() {
        temporarilyShown = true
        temporaryShowTimeout.restart()
    }

    Timer {
        id: temporaryShowTimeout
        running: false
        interval: 2000
        onTriggered: {
            temporarilyShown = false
        }
    }

    MouseArea {
        id: backMouseEater
        anchors.fill: parent
        anchors.topMargin: panelHeight
        visible: !indicators.fullyClosed || !applicationMenus.fullyClosed
        enabled: visible
        hoverEnabled: true // should also eat hover events, otherwise they will pass through

        onClicked: {
            __applicationMenus.hide();
            __indicators.hide();
        }
    }

    Binding {
        target: panelState
        restoreMode: Binding.RestoreBinding
        property: "panelHeight"
        value: minimizedPanelHeight
    }

    RegisteredApplicationMenuModel {
        id: registeredMenuModel
        persistentSurfaceId: panelState.focusedPersistentSurfaceId
    }

    QtObject {
        id: d

        property bool revealControls: !greeterShown &&
                                      !applicationMenus.shown &&
                                      !indicators.shown &&
                                      (decorationMouseArea.containsMouse || menuBarLoader.menusRequested)

        property bool showWindowDecorationControls: (revealControls && panelState.decorationsVisible) ||
                                                    panelState.decorationsAlwaysVisible

        property bool showPointerMenu: revealControls &&
                                       (panelState.decorationsVisible || mode == "windowed")

        property bool enablePointerMenu: applicationMenus.available &&
                                         applicationMenus.model

        property bool showTouchMenu: !greeterShown &&
                                     !showPointerMenu &&
                                     !showWindowDecorationControls

        property bool enableTouchMenus: showTouchMenu &&
                                        applicationMenus.available &&
                                        applicationMenus.model
        // ENH056 - Quick toggles
        function extractIconName(_iconSource) {
            const _prefix = "image://theme/"
            const _suffix = ","
            const _start = _iconSource.search(_prefix) + _prefix.length
            const _end = _iconSource.search(_suffix)

            return _iconSource.substring(_start, _end)
        }
        // ENH056 - End
    }

    // ENH028 - Open indicators via gesture
    /*
    Component.onCompleted: {
        updateText()
        timeDateTimer.restart()
    }

    function updateText() {
        var locale = Qt.locale()
        var currentTime = new Date()
        var timeString = currentTime.toLocaleTimeString(locale, Locale.ShortFormat);
        var dateString = currentTime.toLocaleDateString(locale, Locale.LongFormat);
        dateTimeString = timeString + "\n" + dateString
    }
    
    Timer {
        id: timeDateTimer
        interval: 1000
        repeat: true
        onTriggered: root.updateText()
    }
    */
    // ENH028 - End

    Item {
        id: panelArea
        objectName: "panelArea"

        anchors.fill: parent

        transform: Translate {
            y: indicators.state === "initial"
                ? (1.0 - panelAreaShowProgress) * - minimizedPanelHeight
                : 0
        }

        BorderImage {
            id: indicatorsDropShadow
            anchors {
                fill: __indicators
                margins: -units.gu(1)
            }
            visible: !__indicators.fullyClosed
            source: "graphics/rectangular_dropshadow.sci"
        }

        BorderImage {
            id: appmenuDropShadow
            anchors {
                fill: __applicationMenus
                margins: -units.gu(1)
            }
            visible: !__applicationMenus.fullyClosed
            source: "graphics/rectangular_dropshadow.sci"
        }

        BorderImage {
            id: panelDropShadow
            anchors {
                fill: panelAreaBackground
                // ENH171 - Add blur to Top Panel and Drawer
                // bottomMargin: -units.gu(1)
                // Hides shadow edges when top panel has transparency
                margins: -units.gu(1)
                // ENH171 - End
            }
            visible: panelState.dropShadow
            source: "graphics/rectangular_dropshadow.sci"
        }

        // ENH171 - Add blur to Top Panel and Drawer
        // Only used when in the Greeter
        BackgroundBlur {
            x: 0 - root.leftMarginBlur
            y: 0 - root.topMarginBlur
            width: panelAreaBackground.width
            height: panelAreaBackground.height
            // ENH176 - Option for fully transparent top bar in greeter
            //visible: sourceItem !== null
            visible: sourceItem !== null && !((shell.settings.enableTransparentTopBarInGreeter && shell.showingGreeter)
                                                || (shell.settings.enableTransparentTopBarOnDesktop && shell.desktopShown))
            // ENH176 - End
            sourceItem: root.topPanelBlurSource
            blurRect: Qt.rect(x,
                              0,
                              panelAreaBackground.width,
                              panelAreaBackground.height)
            occluding: false
        }
        // ENH171 - End

        Rectangle {
            id: panelAreaBackground
            // ENH046 - Lomiri Plus Settings
            // color: callHint.visible ? theme.palette.normal.activity :
            //            (root.lightMode ? "#FFFFFF" : "#000000")
            // ENH170 - Adjust top panel based on Drawer and Indicator panels
            //color: callHint.visible ? theme.palette.normal.activity
            //                : shell.settings.useCustomPanelColor ? shell.settings.customPanelColor : (root.lightMode ? "#FFFFFF" : "#000000")
            color: {
                if (callHint.visible) {
                    return theme.palette.normal.activity
                }

                if (shell.settings.matchTopPanelToDrawerIndicatorPanels) {
                    if (root.drawerProgress > 0) {
                        return root.drawerColor
                    }

                    if (!__applicationMenus.fullyClosed || !__indicators.fullyClosed) {
                        return __indicators.customPanelColor
                    }
                }

                return shell.settings.useCustomPanelColor ? shell.settings.customPanelColor : (root.lightMode ? "#FFFFFF" : "#000000")
            }
            // ENH170 - End
            // ENH046 - End
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: minimizedPanelHeight
            // ENH046 - Lomiri Plus Settings
            // ENH122 - Option to transparent top bar when in spread
            readonly property real panelOpacity: shell.settings.topPanelOpacity / 100
            //opacity: panelOpacity
            // ENH170 - Adjust top panel based on Drawer and Indicator panels
            //opacity: transparentTopBar ? topBarOpacityOverride : panelOpacity
            // ENH176 - Option for fully transparent top bar in greeter
            //readonly property real intendedOpacity: root.transparentTopBar ? root.spreadShown ? 0 : panelOpacity - (root.spreadDragProgress * 2)
            //                                                               : panelOpacity
            readonly property real intendedOpacity: {
                if ((shell.settings.enableTransparentTopBarInGreeter && shell.showingGreeter)
                        || (shell.settings.enableTransparentTopBarOnDesktop && shell.desktopShown)) {
                    return 0
                }

                if (root.transparentTopBar) {
                    if (root.spreadShown) {
                        return 0
                    }

                    return panelOpacity - (root.spreadDragProgress * 2)
                }

                return panelOpacity
            }
           // ENH176 - End
            readonly property real finalOpacityBasedOnDrawer: root.drawerOpacity - intendedOpacity
            opacity: {
                if (shell.settings.matchTopPanelToDrawerIndicatorPanels) {
                    if (root.drawerProgress > 0) {
                        return intendedOpacity + (finalOpacityBasedOnDrawer * (drawerProgress / 1))
                    }

                    if (!__applicationMenus.fullyClosed || !__indicators.fullyClosed) {
                        return __indicators.colorOpacity
                    }
                }

                return intendedOpacity
            }
            // ENH170 - End
            // ENH122 - End
            // ENH046 - End

            Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
        }

        MouseArea {
            id: decorationMouseArea
            objectName: "windowControlArea"
            // ENH145 - Fix windows control in fullscreen
            z: __applicationMenus.z + 1
            // ENH145 - End
            anchors {
                left: parent.left
                right: parent.right
            }
            height: minimizedPanelHeight
            hoverEnabled: !__indicators.shown
            onClicked: {
                if (callHint.visible) {
                    callHint.showLiveCall();
                }
            }

            onPressed: {
                if (!callHint.visible) {
                    // let it fall through to the window decoration of the maximized window behind, if any
                    mouse.accepted = false;
                }
                var menubar = menuBarLoader.item;
                if (menubar) {
                    menubar.invokeMenu(mouse);
                }
            }

            Row {
                anchors.fill: parent
                spacing: units.gu(2)

                // WindowControlButtons inside the mouse area, otherwise QML doesn't grok nested hover events :/
                // cf. https://bugreports.qt.io/browse/QTBUG-32909
                WindowControlButtons {
                    id: windowControlButtons
                    objectName: "panelWindowControlButtons"
                    height: indicators.minimizedPanelHeight
                    opacity: d.showWindowDecorationControls ? 1 : 0
                    visible: opacity != 0
                    Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }

                    active: panelState.decorationsVisible || panelState.decorationsAlwaysVisible
                    windowIsMaximized: true
                    onCloseClicked: panelState.closeClicked()
                    onMinimizeClicked: panelState.minimizeClicked()
                    onMaximizeClicked: panelState.restoreClicked()
                    closeButtonShown: panelState.closeButtonShown
                }

                Loader {
                    id: menuBarLoader
                    objectName: "menuBarLoader"
                    height: parent.height
                    enabled: d.enablePointerMenu
                    opacity: d.showPointerMenu ? 1 : 0
                    visible: opacity != 0
                    Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }
                    active: d.showPointerMenu && !callHint.visible

                    width: parent.width - windowControlButtons.width - units.gu(2) - __indicators.barWidth

                    readonly property bool menusRequested: menuBarLoader.item ? menuBarLoader.item.showRequested : false

                    sourceComponent: MenuBar {
                        id: bar
                        objectName: "menuBar"
                        anchors.left: menuBarLoader ? menuBarLoader.left : undefined
                        anchors.margins: units.gu(1)
                        height: menuBarLoader.height
                        enableKeyFilter: valid && panelState.decorationsVisible
                        lomiriMenuModel: __applicationMenus.model
                        panelState: root.panelState

                        Connections {
                            target: __applicationMenus
                            function onShownChanged() { bar.dismiss(); }
                        }

                        Connections {
                            target: __indicators
                            function onShownChanged() { bar.dismiss(); }
                        }

                        onDoubleClicked: panelState.restoreClicked()
                        onPressed: mouse.accepted = false // let the parent mouse area handle this, so it can both unsnap window and show menu
                    }
                }
            }

            ActiveCallHint {
                id: callHint
                objectName: "callHint"

                anchors.centerIn: parent
                height: minimizedPanelHeight

                visible: active && indicators.state == "initial" && __applicationMenus.state == "initial"
                greeterShown: root.greeterShown
            }
        }

        PanelMenu {
            id: __applicationMenus

            x: menuContentX
            model: registeredMenuModel.model
            width: root.menuWidth
            overFlowWidth: width
            minimizedPanelHeight: root.minimizedPanelHeight
            expandedPanelHeight: root.expandedPanelHeight
            openedHeight: root.height
            alignment: Qt.AlignLeft
            enableHint: !callHint.active && !fullscreenMode
            showOnClick: false
            // ENH111 - Blurred expanded top panel
            // panelColor: panelAreaBackground.color
            // ENH111 - Blurred expanded top panel
            // ENH056 - Quick toggles
            enableQuickToggles: false
            // ENH056 - End
            // ENH002 - Notch/Punch hole fix
            contentLeftMargin: shell.isBuiltInScreen 
                                    ? shell.orientation == 1 && shell.isLeftNotch && !shell.deviceConfiguration.fullyHideNotchInPortrait 
                                                ? shell.deviceConfiguration.notchWidthMargin : shell.deviceConfiguration.roundedCornerMargin
                                    : 0
            leftMarginBlur: root.leftMarginBlur
            topMarginBlur: root.topMarginBlur
            // ENH002 - End
            blurSource: root.blurSource
            blurRect: Qt.rect(x,
                              0,
                              root.width,
                              root.height)
            lightMode: root.lightMode

            onShowTapped: {
                if (callHint.active) {
                    callHint.showLiveCall();
                }
            }

            hideRow: !expanded
            rowItemDelegate: ActionItem {
                id: actionItem
                property int ownIndex: index
                objectName: "appMenuItem"+index
                enabled: model.sensitive

                width: _title.width + units.gu(2)
                height: parent.height

                action: Action {
                    text: model.label.replace("_", "&")
                }
                // ENH028 - Open indicators via gesture
                readonly property bool isCurrent: ownIndex == __applicationMenus.currentMenuIndex
                onIsCurrentChanged: {
                    if (isCurrent && __applicationMenus.model) {
                        __applicationMenus.currentTitle = _title.text
                    }
                }
                // ENH028 - End

                Label {
                    id: _title
                    anchors.centerIn: parent
                    text: actionItem.text
                    horizontalAlignment: Text.AlignLeft
                    color: enabled ? theme.palette.normal.backgroundText : theme.palette.disabled.backgroundText
                }
            }

            pageDelegate: PanelMenuPage {
                readonly property bool isCurrent: modelIndex == __applicationMenus.currentMenuIndex
                onIsCurrentChanged: {
                    if (isCurrent && menuModel) {
                        menuModel.aboutToShow(modelIndex);
                    }
                }
                // ENH028 - Open indicators via gesture
                inverted: __applicationMenus.inverted
                titleText: __applicationMenus.currentTitle//root.dateTimeString
                // ENH028 - End
                // ENH046 - Lomiri Plus Settings
                topPanelMargin: root.topPanelMargin
                // ENH046 - End

                menuModel: __applicationMenus.model
                submenuIndex: modelIndex

                factory: ApplicationMenuItemFactory {
                    rootModel: __applicationMenus.model
                }
            }

            enabled: d.enableTouchMenus
            opacity: d.showTouchMenu ? 1 : 0
            visible: opacity != 0
            clip: true
            Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }

            onEnabledChanged: {
                if (!enabled) hide();
            }
        }

        Item {
            id: panelTitleHolder
            anchors {
                left: parent.left
                // ENH002 - Notch/Punch hole fix
                // leftMargin: units.gu(1)

                leftMargin: {
                    var returnValue = units.gu(1)

                    if (shell.isBuiltInScreen) {
                        if (shell.orientation == 1 && shell.deviceConfiguration.notchPosition == "left"
                                && !shell.deviceConfiguration.fullyHideNotchInPortrait) {
                            returnValue = shell.deviceConfiguration.notchWidthMargin
                        } else if (shell.deviceConfiguration.withRoundedCorners) {
                            returnValue = shell.deviceConfiguration.roundedCornerMargin
                        }
                    }

                    // ENH239 - Force show Launcher
                    //return returnValue
                    return shell.settings.forceLockLauncher ? returnValue + root.applicationMenuContentX : returnValue
                }
                // ENH002 - End
                right: __indicators.left
                rightMargin: units.gu(1)
            }
            height: root.minimizedPanelHeight

            Label {
                id: rowLabel
                anchors {
                    left: parent.left
                    // ENH027 - Logic for showing app title
                    // right: root.partialWidth ? parent.right : parent.left
                    right: root.partialWidth && root.width - __indicators.width - __applicationMenus.contentLeftMargin >= units.gu(20)
                                                ? parent.right : parent.left
                    // End - ENH027
                    // ENH056 - Quick toggles
                    // rightMargin: touchMenuIcon.width
                    rightMargin: touchMenuIcon.width + (customIndicators.width > 0 ? customIndicators.width + units.gu(2) : 0)
                    // ENH056 - End
                }
                objectName: "panelTitle"
                height: root.minimizedPanelHeight
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                maximumLineCount: 1
                fontSize: "medium"
                font.weight: Font.Medium
                color: theme.palette.selected.backgroundText
                // ENH135 - Show Desktop
                // text: (root.partialWidth && !callHint.visible) ? panelState.title : ""
                text: (root.partialWidth && !callHint.visible && !shell.desktopShown) ? panelState.title : ""
                // ENH135 - End
                opacity: __applicationMenus.visible && !__applicationMenus.expanded
                Behavior on opacity { NumberAnimation { duration: LomiriAnimation.SnapDuration } }
                visible: opacity !== 0
            }

            Icon {
                id: touchMenuIcon
                objectName: "touchMenuIcon"
                anchors {
                    left: parent.left
                    // ENH056 - Quick toggles
                    // leftMargin: rowLabel.contentWidth + units.dp(2)
                    leftMargin: rowLabel.visible ? rowLabel.contentWidth + units.dp(2) : 0
                    // ENH056 - End
                    verticalCenter: parent.verticalCenter
                }
                width: units.gu(2)
                height: units.gu(2)
                name: "down"
                color: theme.palette.normal.backgroundText
                opacity: !__applicationMenus.expanded && d.enableTouchMenus && !callHint.visible
                Behavior on opacity { NumberAnimation { duration: LomiriAnimation.SnapDuration } }
                visible: opacity !== 0
            }

            // ENH056 - Quick toggles
            RowLayout {
                id: customIndicators

                opacity: !__applicationMenus.expanded && !callHint.visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: LomiriAnimation.SnapDuration } }
                visible: opacity !== 0
                anchors {
                    left: touchMenuIcon.right
                    leftMargin: touchMenuIcon.visible ? units.gu(1) : -touchMenuIcon.width + units.gu(1)
                    top: parent.top
                    bottom: parent.bottom
                }

                // ENH115 - Standalone Immersive mode
                Icon {
                    name: "media-record"
                    Layout.preferredWidth: units.gu(2)
                    Layout.preferredHeight: implicitHeight
                    Layout.alignment: Qt.AlignVCenter
                    color: theme.palette.normal.foregroundText
                    visible: shell.immersiveMode && shell.settings.showImmersiveModeIconIndicator
                }
                // ENH115 - End

                // Indicate when display timeout is disabled
                Icon {
                    name: "preferences-desktop-display-symbolic"
                    Layout.preferredWidth: units.gu(2)
                    Layout.preferredHeight: implicitHeight
                    Layout.alignment: Qt.AlignVCenter
                    color: theme.palette.normal.foregroundText
                    visible: shell.isScreenActive && shell.settings.showActiveScreenIconIndicator
                }

                // ENH102 - App suspension indicator
                // Indicate when the current app is exempted from app suspension
                Icon {
                    name: "preferences-desktop-login-items-symbolic"
                    Layout.preferredWidth: units.gu(2)
                    Layout.preferredHeight: implicitHeight
                    Layout.alignment: Qt.AlignVCenter
                    color: theme.palette.normal.foregroundText
                    visible: shell.focusedAppIsExemptFromLifecycle && !shell.isWindowedMode && shell.settings.showAppSuspensionIconIndicator
                                && !root.greeterShown
                }
                // ENH102 - End
            }
            // ENH056 - End
        }

        PanelMenu {
            id: __indicators
            objectName: "indicators"

            anchors {
                top: parent.top
                right: parent.right
            }
            width: root.menuWidth
            minimizedPanelHeight: root.minimizedPanelHeight
            expandedPanelHeight: root.expandedPanelHeight
            openedHeight: root.height

            overFlowWidth: width - appMenuClear
            enableHint: !callHint.active && !fullscreenMode
            showOnClick: !callHint.visible
            // ENH240 - Light mode fix in Indicator Panel
            // For some reason, it works in vanilla Lomiri without this WTF?
            lightMode: root.lightMode
            // ENH240 - End
            // ENH111 - Blurred expanded top panel
            // panelColor: panelAreaBackground.color
            // ENH111 - End
            // ENH056 - Quick toggles
            enableQuickToggles: shell.settings.enableQuickToggles
            // ENH056 - End
            // ENH002 - Notch/Punch hole fix
            // ENH036 - Use punchole as battery indicator
            /*contentRightMargin: shell.isBuiltInScreen && !inverted
                                    ? shell.orientation == 1 && shell.deviceConfiguration.notchPosition == "right" && !shell.deviceConfiguration.fullyHideNotchInPortrait
                                                ? shell.deviceConfiguration.notchWidthMargin : shell.deviceConfiguration.roundedCornerMargin
                                    : 0*/
            contentRightMargin: shell.isBuiltInScreen && !inverted
                                    ? shell.orientation == 1 && shell.isRightNotch && !shell.deviceConfiguration.fullyHideNotchInPortrait
                                                ? shell.deviceConfiguration.notchWidthMargin + (panel.batteryCircleEnabled ? panel.batteryCircleBorder : 0) : shell.deviceConfiguration.roundedCornerMargin
                                    : 0
            contentLeftMargin: shell.isBuiltInScreen && !inverted
                                    ? shell.orientation == 1 && shell.isLeftNotch && !shell.deviceConfiguration.fullyHideNotchInPortrait 
                                                ? shell.deviceConfiguration.notchWidthMargin + (panel.batteryCircleEnabled ? panel.batteryCircleBorder : 0) : shell.deviceConfiguration.roundedCornerMargin
                                    : 0
            // ENH036 - End
            leftMarginBlur: root.leftMarginBlur
            topMarginBlur: root.topMarginBlur
            // ENH002 - End
            blurSource: root.blurSource
            // ENH002 - Notch/Punch hole fix
            // blurRect: Qt.rect(x,
            blurRect: Qt.rect(x - leftMarginBlur,
            // ENH002 - End
                              0,
                              root.width,
                              root.height)

            // On small screens, the Indicators' handle area is the entire top
            // bar unless there is an application menu. In that case, our handle
            // needs to allow for some room to clear the application menu.
            property var appMenuClear: (d.enableTouchMenus && !partialWidth) ? units.gu(7) : 0

            onShowTapped: {
                if (callHint.active) {
                    callHint.showLiveCall();
                }
            }

            rowItemDelegate: IndicatorItem {
                id: indicatorItem
                objectName: identifier+"-panelItem"

                property int ownIndex: index
                readonly property bool overflow: parent.width - (x - __indicators.rowContentX) > __indicators.overFlowWidth
                // ENH036 - Use punchole as battery indicator
                // readonly property bool hidden: !expanded && (overflow || !indicatorVisible || hideSessionIndicator || hideKeyboardIndicator)
                // ENH060 - Show/Hide Indicators Settings
                readonly property bool alwaysHidden: shell.settings.alwaysHiddenIndicatorIcons.includes(identifier)
                readonly property bool alwaysShown: shell.settings.alwaysShownIndicatorIcons.includes(identifier)
                // readonly property bool hidden: !expanded && (overflow || !indicatorVisible || hideSessionIndicator || hideKeyboardIndicator || hideBatteryIndicator)
                readonly property bool hidden: !expanded && (alwaysHidden || overflow || !indicatorVisible || hideSessionIndicator
                                                                        || hideKeyboardIndicator || hideBatteryIndicator
                                                                        || hideMessagesIndicator || hideSoundIndicator)
                                                    && !alwaysShown
                // ENH060 - End
                // ENH036 - End
                // HACK for indicator-session
                readonly property bool hideSessionIndicator: identifier == "ayatana-indicator-session" && Math.min(Screen.width, Screen.height) <= units.gu(60)
                // HACK for indicator-keyboard
                readonly property bool hideKeyboardIndicator: identifier == "ayatana-indicator-keyboard" && !hasKeyboard
                // ENH036 - Use punchole as battery indicator
                readonly property bool hideBatteryIndicator: identifier == "ayatana-indicator-power" && panel.batteryCircleEnabled
                // ENH036 - End
                // ENH060 - Show/Hide Indicators Settings
                readonly property bool hideMessagesIndicator: identifier == "ayatana-indicator-messages" && shell.settings.onlyShowNotificationsIndicatorWhenGreen
                                                                    && messagesEmpty
                readonly property bool hideSoundIndicator: identifier == "ayatana-indicator-sound" && shell.settings.onlyShowSoundIndicatorWhenSilent
                                                                    && !soundIsSilent
                property bool messagesEmpty: true
                property bool soundIsSilent: false
                // ENH060 - End

                height: parent.height
                expanded: indicators.expanded
                selected: ListView.isCurrentItem

                identifier: model.identifier
                busName: indicatorProperties.busName
                actionsObjectPath: indicatorProperties.actionsObjectPath
                menuObjectPath: indicatorProperties.menuObjectPath

                opacity: hidden ? 0.0 : 1.0
                Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }
                // ENH036 - Use punchole as battery indicator
                // width: ((expanded || indicatorVisible) && !hideSessionIndicator && !hideKeyboardIndicator) ? implicitWidth : 0
                // ENH060 - Show/Hide Indicators Settings
                // width: ((expanded || indicatorVisible) && !hideSessionIndicator && !hideKeyboardIndicator && !hideBatteryIndicator) ? implicitWidth : 0
                width: !alwaysHidden && ((expanded || indicatorVisible)
                                                                && !hideSessionIndicator && !hideKeyboardIndicator && !hideBatteryIndicator
                                                                && !hideMessagesIndicator && !hideSoundIndicator)
                                    || alwaysShown ? implicitWidth : 0
                // ENH060 - End
                // ENH036 - End

                Behavior on width { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }
                // ENH028 - Open indicators via gesture
                onSelectedChanged: {
                    if (selected && __indicators.model) {
                        __indicators.currentTitle = Qt.binding(function() { return title })
                    }
                }
                // ENH028 - End
                // ENH036 - Use punchole as battery indicator
                onRightLabelChanged: {
                    if (identifier == "ayatana-indicator-power") {
                        let _batteryLevelText = rightLabel.match(/\d+/)
                        if (_batteryLevelText) {
                            panel.batteryLevel = _batteryLevelText[0]
                        }
                    }
                }
                onIconsChanged: {
                    if (identifier == "ayatana-indicator-power") {
                        if (icons) {
                            if (icons[0].search("charging") > -1) {
                                panel.batteryCharging = true
                            } else {
                                panel.batteryCharging = false
                            }
                        }
                    }
                    // ENH056 - Quick toggles
                    if (identifier == "indicator-network") {
                        if (icons) {
                            const _iconFound = icons.find((element) => element.search("nm-") > -1);
                            if (_iconFound) {
                                __indicators.wifiIcon = d.extractIconName(_iconFound)
                            }
                        }
                    }
                    if (identifier == "indicator-bluetooth" || identifier == "ayatana-indicator-bluetooth") {
                        if (icons) {
                            const _iconFound = icons.find((element) => element.search("bluetooth-") > -1);
                            if (_iconFound) {
                                __indicators.bluetoothIcon = d.extractIconName(_iconFound)
                            }
                        }
                    }
                    // ENH056 - End
                    // ENH060 - Show/Hide Indicators Settings
                    if (identifier == "ayatana-indicator-messages") {
                        if (icons) {
                            if (icons[0].search("messages-new") > -1) {
                                messagesEmpty = false
                            } else {
                                messagesEmpty = true
                            }
                        }
                    }
                    if (identifier == "ayatana-indicator-sound") {
                        if (icons) {
                            if (icons[0].search("muted") > -1) {
                                soundIsSilent = true
                            } else {
                                soundIsSilent = false
                            }
                        }
                    }
                    // ENH060 - End
                }
                // ENH036 - End

                // ENH095 - Middle notch support
                readonly property bool actuallyHidden: width == 0

                expandForNotch: !expanded && shell.adjustForMiddleNotch

                function setNotchMargin() {
                    let newMargin = 0

                    if (!actuallyHidden) {
                        let mappedPos = ListView.view.mapToItem(shell, 0, 0)
                        let notchWidth = shell.deviceConfiguration.notchWidthMargin

                        if (mappedPos.x < ListView.view.notchGlobalEndX) {
                            let notchEndX = ListView.view.notchGlobalEndX - mappedPos.x
                            let itemToExpandForNotch = ListView.view.itemAt(notchEndX, ListView.view.height / 2)

                            if (this == itemToExpandForNotch) {
                                ListView.view.resetExpandForNotch()
                                let itemWidthUnderNotch = notchEndX - itemToExpandForNotch.x // Item width under the notch

                                newMargin = notchWidth
                                                // + itemWidthUnderNotch
                                                // + (width - itemWidthUnderNotch) // Item width not under the notch
                                                + ((width - itemWidthUnderNotch) * 2 ) // Item width not under the notch
                            } else {
                                ListView.view.delayedNotchAdjustment()
                            }
                        }
                    }

                    notchMargin = newMargin
                }

                /* Disabled for now since it sometimes causes continuous binding loop error
                onImplicitWidthChanged: {
                    if (!actuallyHidden && !expanded) {
                        ListView.view.delayedNotchAdjustment()
                    }
                }
                */

                onActuallyHiddenChanged: {
                    if (!actuallyHidden && !expanded) {
                        notchExpandDelay.restart()
                    } else {
                        notchMargin = 0
                        if (!expanded) {
                            ListView.view.delayedNotchAdjustment()
                        }
                    }
                }

                Timer {
                    id: notchExpandDelay

                    running: false
                    interval: 200
                    onTriggered: setNotchMargin()
                }
                // ENH095 - End
            }

            pageDelegate: PanelMenuPage {
                objectName: modelData.identifier + "-page"
                submenuIndex: 0
                // ENH056 - Quick toggles
                id: indicatorsPanelMenuPage

                menuIndex: modelData.index
                identifier: modelData.identifier
                onRotationToggleChanged: __indicators.rotationToggle = rotationToggle
                onFlashlightToggleChanged: __indicators.flashlightToggle = flashlightToggle
                onAutoDarkModeToggleChanged: __indicators.autoDarkModeToggle = autoDarkModeToggle
                onDarkModeToggleChanged: __indicators.darkModeToggle = darkModeToggle
                onDesktopModeToggleChanged: __indicators.desktopModeToggle = desktopModeToggle
                onSilentModeToggleChanged: __indicators.silentModeToggle = silentModeToggle
                onFlightModeToggleChanged: __indicators.flightModeToggle = flightModeToggle
                onMobileDataToggleChanged: __indicators.mobileDataToggle = mobileDataToggle
                onWifiToggleChanged: __indicators.wifiToggle = wifiToggle
                onBluetoothToggleChanged: __indicators.bluetoothToggle = bluetoothToggle
                onLocationToggleChanged: __indicators.locationToggle = locationToggle
                onImmersiveToggleChanged: __indicators.immersiveToggle = immersiveToggle
                onHotspotToggleChanged: __indicators.hotspotToggle = hotspotToggle
                onAutoBrightnessToggleChanged: __indicators.autoBrightnessToggle = autoBrightnessToggle
                onBrightnessSliderChanged: __indicators.brightnessSlider = brightnessSlider
                onVolumeSliderChanged: __indicators.volumeSlider = volumeSlider
                readonly property bool isCurrent: modelIndex == __indicators.currentMenuIndex
                quickTogglesExpanded: __indicators.quickTogglesExpanded
                // Collapse quick toggles when header is expanded
                onHeaderExpandedChanged: {
                    if (expanded) {
                        __indicators.expandCollapseQuickToggles(false)
                    }
                }
                // ENH056 - End
                // ENH064 - Dynamic Cove
                onMediaPlayerChanged: root.mediaPlayer = mediaPlayer
                onPlaybackItemChanged: root.playbackItem = playbackItem
                // ENH064 - End
                // ENH028 - Open indicators via gesture
                onDateItemChanged: __indicators.dateItem = dateItem
                onLockItemChanged: __indicators.lockItem = lockItem
                // ENH028 - End
                // ENH046 - Lomiri Plus Settings
                topPanelMargin: root.topPanelMargin
                // ENH046 - End

                menuModel: delegate.menuModel
                // ENH028 - Open indicators via gesture
                inverted: __indicators.inverted
                titleText: __indicators.currentTitle //root.dateTimeString
                onModelCountChanged: {
                    // Open notifications when there are any
                    if (modelData.identifier == "ayatana-indicator-messages") {
                        if (count > 0) {
                            __indicators.initialIndexOnInverted = 0
                            root.hasNotifications = true
                        } else {
                            __indicators.initialIndexOnInverted = -1
                            root.hasNotifications = false
                        }
                    }
                }
                // ENH028 - End

                factory: IndicatorMenuItemFactory {
                    indicator: {
                        var context = modelData.identifier;
                        if (context && context.indexOf("fake-") === 0) {
                            context = context.substring("fake-".length)
                        }
                        return context;
                    }
                    rootModel: delegate.menuModel
                }

                IndicatorDelegate {
                    id: delegate
                    busName: modelData.indicatorProperties.busName
                    actionsObjectPath: modelData.indicatorProperties.actionsObjectPath
                    menuObjectPath: modelData.indicatorProperties.menuObjectPath
                }
            }

            enabled: !applicationMenus.expanded
            opacity: !callHint.visible && !applicationMenus.expanded ? 1 : 0
            clip: true
            Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }

            onEnabledChanged: {
                if (!enabled) hide();
            }
        }
    }

    IndicatorsLight {
        id: indicatorLights
        supportsMultiColorLed: root.supportsMultiColorLed
    }

    states: [
        State {
            name: "onscreen" //fully opaque and visible at top edge of screen
            // ENH048 - Always hide panel mode
            // when: !fullscreenMode || temporarilyShown
            when: (!fullscreenMode && !forceHidePanel) || temporarilyShown
            // ENH048 - End
            PropertyChanges {
                target: panelArea;
                anchors.topMargin: 0
                opacity: 1;
            }
        },
        State {
            name: "offscreen" //pushed off screen
            // ENH048 - Always hide panel mode
            // when: fullscreenMode
            when: fullscreenMode || forceHidePanel
            // ENH048 - End
            PropertyChanges {
                target: panelArea;
                anchors.topMargin: {
                    if (indicators.state !== "initial") return 0;
                    if (applicationMenus.state !== "initial") return 0;
                    return -minimizedPanelHeight;
                }
                opacity: indicators.fullyClosed && applicationMenus.fullyClosed ? 0.0 : 1.0
            }
            PropertyChanges {
                target: indicators.showDragHandle;
                anchors.bottomMargin: -units.gu(1)
            }
            PropertyChanges {
                target: applicationMenus.showDragHandle;
                anchors.bottomMargin: -units.gu(1)
            }
        }
    ]
    // ENH049 - Disable topmargin transition of top panel
    transitions: [
        Transition {
            to: "onscreen"
            // LomiriNumberAnimation { target: panelArea; properties: "anchors.topMargin,opacity" }
            LomiriNumberAnimation { target: panelArea; properties: "opacity" }
        },
        Transition {
            to: "offscreen"
            // LomiriNumberAnimation { target: panelArea; properties: "anchors.topMargin,opacity" }
            LomiriNumberAnimation { target: panelArea; properties: "opacity" }
        }
    ]
    // ENH049 - End
}
