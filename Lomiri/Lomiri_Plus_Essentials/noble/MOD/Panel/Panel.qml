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
    property real menuWidth: partialWidth ? units.gu(40) : width
    property alias applicationMenuContentX: __applicationMenus.menuContentX

    property alias applicationMenus: __applicationMenus
    property alias indicators: __indicators
    property bool fullscreenMode: false
    property real panelAreaShowProgress: 1.0
    property bool greeterShown: false
    property bool hasKeyboard: false
    property bool supportsMultiColorLed: true
    // ENH002 - Notch/Punch hole fix
    property real leftMarginBlur
    property real topMarginBlur
    // ENH002 - End
    // ENH046 - Lomiri Plus Settings
    property real topPanelMargin: 0
    // ENH046 - End

    property var blurSource : null
    property bool lightMode : false

    // Whether our expanded menus should take up the full width of the panel
    property bool partialWidth: width >= units.gu(60)

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
    }

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
                bottomMargin: -units.gu(1)
            }
            visible: panelState.dropShadow
            source: "graphics/rectangular_dropshadow.sci"
        }

        Rectangle {
            id: panelAreaBackground
            color: callHint.visible ? theme.palette.normal.activity :
                       (root.lightMode ? "#FFFFFF" : "#000000")
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: minimizedPanelHeight

            Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
        }

        MouseArea {
            id: decorationMouseArea
            objectName: "windowControlArea"
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
            panelColor: panelAreaBackground.color
            // ENH002 - Notch/Punch hole fix
            contentLeftMargin: shell.isBuiltInScreen 
                                    ? shell.orientation == 1 && shell.deviceConfiguration.notchPosition == "left" && !shell.deviceConfiguration.fullyHideNotchInPortrait 
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

                    return returnValue
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
                    right: root.partialWidth ? parent.right : parent.left
                    rightMargin: touchMenuIcon.width
                }
                objectName: "panelTitle"
                height: root.minimizedPanelHeight
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                maximumLineCount: 1
                fontSize: "medium"
                font.weight: Font.Medium
                color: theme.palette.selected.backgroundText
                text: (root.partialWidth && !callHint.visible) ? panelState.title : ""
                opacity: __applicationMenus.visible && !__applicationMenus.expanded
                Behavior on opacity { NumberAnimation { duration: LomiriAnimation.SnapDuration } }
                visible: opacity !== 0
            }

            Icon {
                id: touchMenuIcon
                objectName: "touchMenuIcon"
                anchors {
                    left: parent.left
                    leftMargin: rowLabel.contentWidth + units.dp(2)
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
            panelColor: panelAreaBackground.color
            // ENH002 - Notch/Punch hole fix
            contentRightMargin: shell.isBuiltInScreen
                                    ? shell.orientation == 1 && shell.deviceConfiguration.notchPosition == "right" && !shell.deviceConfiguration.fullyHideNotchInPortrait
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
                // ENH060 - Show/Hide Indicators Settings
                readonly property bool alwaysHidden: shell.settings.alwaysHiddenIndicatorIcons.includes(identifier)
                readonly property bool alwaysShown: shell.settings.alwaysShownIndicatorIcons.includes(identifier)
                // readonly property bool hidden: !expanded && (overflow || !indicatorVisible || hideSessionIndicator || hideKeyboardIndicator)
                readonly property bool hidden: !expanded && (alwaysHidden || overflow || !indicatorVisible || hideSessionIndicator
                                                                        || hideKeyboardIndicator || hideMessagesIndicator || hideSoundIndicator)
                                                    && !alwaysShown
                // ENH060 - End
                // HACK for indicator-session
                readonly property bool hideSessionIndicator: identifier == "ayatana-indicator-session" && Math.min(Screen.width, Screen.height) <= units.gu(60)
                // HACK for indicator-keyboard
                readonly property bool hideKeyboardIndicator: identifier == "ayatana-indicator-keyboard" && !hasKeyboard
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

                // ENH060 - Show/Hide Indicators Settings
                // width: ((expanded || indicatorVisible) && !hideSessionIndicator && !hideKeyboardIndicator) ? implicitWidth : 0
                width: !alwaysHidden && ((expanded || indicatorVisible)
                                                                && !hideSessionIndicator && !hideKeyboardIndicator
                                                                && !hideMessagesIndicator && !hideSoundIndicator)
                                    || alwaysShown ? implicitWidth : 0
                // ENH060 - End

                Behavior on width { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }
                // ENH060 - Show/Hide Indicators Settings
                onIconsChanged: {
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

                // ENH046 - Lomiri Plus Settings
                topPanelMargin: root.topPanelMargin
                identifier: modelData.identifier
                // ENH046 - End
                menuModel: delegate.menuModel

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
            when: !fullscreenMode || temporarilyShown
            PropertyChanges {
                target: panelArea;
                anchors.topMargin: 0
                opacity: 1;
            }
        },
        State {
            name: "offscreen" //pushed off screen
            when: fullscreenMode
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

    transitions: [
        Transition {
            to: "onscreen"
            LomiriNumberAnimation { target: panelArea; properties: "anchors.topMargin,opacity" }
        },
        Transition {
            to: "offscreen"
            LomiriNumberAnimation { target: panelArea; properties: "anchors.topMargin,opacity" }
        }
    ]
}
