/*
 * Copyright (C) 2013-2017 Canonical, Ltd.
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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Layouts 1.0
import Unity.Application 0.1
import Unity.Indicators 0.1
import Utils 0.1
import Unity.ApplicationMenu 0.1

import QtQuick.Window 2.2

import "../ApplicationMenus"
import "../Components"
import "../Components/PanelState"
import ".."
import "Indicators"
// ENH030 - Blurred indicator panel
import "../Launcher"
// ENH030 - End

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
    // ENH028 - Open indicators via gesture
    property string dateTimeString
    // ENH028 - End
    // ENH030 - Blurred indicator panel
    property Item blurSource: null
    property bool interactiveBlur: false
    property real leftMarginBlur
    property real topMarginBlur
    // ENH030 - End
    // ENH036 - Use punchole as battery indicator
    property bool batteryCircleEnabled
    property real batteryCircleBorder
    property bool batteryCharging: false
    property int batteryLevel: 0
    // ENH036 - End
    // ENH048 - Always hide panel mode
    property bool forceHidePanel: true
    // ENH048 - End
            

    // Whether our expanded menus should take up the full width of the panel
    property bool partialWidth: width >= units.gu(60)

    property string mode: "staged"

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
        target: PanelState
        property: "panelHeight"
        value: minimizedPanelHeight
    }

    RegisteredApplicationMenuModel {
        id: registeredMenuModel
        persistentSurfaceId: PanelState.focusedPersistentSurfaceId
    }

    QtObject {
        id: d

        property bool revealControls: !greeterShown &&
                                      !applicationMenus.shown &&
                                      !indicators.shown &&
                                      (decorationMouseArea.containsMouse || menuBarLoader.menusRequested)

        property bool showWindowDecorationControls: (revealControls && PanelState.decorationsVisible) ||
                                                    PanelState.decorationsAlwaysVisible

        property bool showPointerMenu: revealControls && enablePointerMenu &&
                                       (PanelState.decorationsVisible || mode == "windowed")

        property bool enablePointerMenu: applicationMenus.available &&
                                         applicationMenus.model

        property bool showTouchMenu: !greeterShown &&
                                     !showPointerMenu &&
                                     !showWindowDecorationControls

        property bool enableTouchMenus: showTouchMenu &&
                                        applicationMenus.available &&
                                        applicationMenus.model
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
    
    // ENH030 - Blurred indicator panel
    Loader {
        active: root.interactiveBlur
        asynchronous: true
        sourceComponent: BackgroundBlur {
            id: backgroundBlur
            property real fullBlurAmount: units.gu(6)//units.gu(6)

            anchors.fill: parent
            anchors.leftMargin: -root.leftMarginBlur
            anchors.topMargin: -root.topMarginBlur
            visible: root.interactiveBlur && root.blurSource && (__applicationMenus.unitProgress > 0 || __indicators.unitProgress > 0)
            blurAmount: __applicationMenus.unitProgress ? (__applicationMenus.unitProgress / 1) * fullBlurAmount
                                        : __indicators.unitProgress ? (__indicators.unitProgress / 1) * fullBlurAmount
                                                        : fullBlurAmount
            sourceItem: root.blurSource
            blurRect: Qt.rect(0, 0, sourceItem.width, sourceItem.height)
            cached: __applicationMenus.partiallyOpened || __indicators.partiallyOpened
        }
    }
    // ENH030 - End

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
            visible: PanelState.dropShadow
            source: "graphics/rectangular_dropshadow.sci"
        }

        Rectangle {
            id: panelAreaBackground
            color: callHint.visible ? theme.palette.normal.activity : theme.palette.normal.background
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: minimizedPanelHeight
            // ENH030 - Blurred indicator panel
            // ENH046 - Lomiri Plus Settings
            opacity: shell.settings.topPanelOpacity / 100
            // ENH046 - End
            // ENH030 - End

            Behavior on color { ColorAnimation { duration: UbuntuAnimation.FastDuration } }
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
                    Behavior on opacity { UbuntuNumberAnimation { duration: UbuntuAnimation.SnapDuration } }

                    active: PanelState.decorationsVisible || PanelState.decorationsAlwaysVisible
                    windowIsMaximized: true
                    onCloseClicked: PanelState.closeClicked()
                    onMinimizeClicked: PanelState.minimizeClicked()
                    onMaximizeClicked: PanelState.restoreClicked()
                    closeButtonShown: PanelState.closeButtonShown
                }

                Loader {
                    id: menuBarLoader
                    objectName: "menuBarLoader"
                    height: parent.height
                    enabled: d.enablePointerMenu
                    opacity: d.showPointerMenu ? 1 : 0
                    visible: opacity != 0
                    Behavior on opacity { UbuntuNumberAnimation { duration: UbuntuAnimation.SnapDuration } }
                    active: d.showPointerMenu && !callHint.visible

                    width: parent.width - windowControlButtons.width - units.gu(2) - __indicators.barWidth

                    readonly property bool menusRequested: menuBarLoader.item ? menuBarLoader.item.showRequested : false

                    sourceComponent: MenuBar {
                        id: bar
                        objectName: "menuBar"
                        anchors.left: parent ? parent.left : undefined
                        anchors.margins: units.gu(1)
                        height: menuBarLoader.height
                        enableKeyFilter: valid && PanelState.decorationsVisible
                        unityMenuModel: __applicationMenus.model

                        Connections {
                            target: __applicationMenus
                            onShownChanged: bar.dismiss();
                        }

                        Connections {
                            target: __indicators
                            onShownChanged: bar.dismiss();
                        }

                        onDoubleClicked: PanelState.restoreClicked()
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
            // ENH028 - Open indicators via gesture
            panelOpacity: root.interactiveBlur ? 0.9 : 1
            // ENH028 - End
            // ENH002 - Notch/Punch hole fix
            contentLeftMargin: shell.isBuiltInScreen 
                                    ? shell.orientation == 1 && shell.deviceConfiguration.notchPosition == "left" && !shell.deviceConfiguration.fullyHideNotchInPortrait 
                                                ? shell.deviceConfiguration.notchWidthMargin : shell.deviceConfiguration.roundedCornerMargin
                                    : 0
            // ENH002 - End

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

                menuModel: __applicationMenus.model
                submenuIndex: modelIndex

                factory: ApplicationMenuItemFactory {
                    rootModel: __applicationMenus.model
                }
            }

            enabled: d.enableTouchMenus
            opacity: d.showTouchMenu ? 1 : 0
            visible: opacity != 0
            Behavior on opacity { UbuntuNumberAnimation { duration: UbuntuAnimation.SnapDuration } }

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
                    // ENH027 - Logic for showing app title
                    // right: root.partialWidth ? parent.right : parent.left
                    right: root.partialWidth && root.width - __indicators.width - __applicationMenus.contentLeftMargin >= units.gu(20)
                                                ? parent.right : parent.left
                    // End - ENH027
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
                text: (root.partialWidth && !callHint.visible) ? PanelState.title : ""
                opacity: __applicationMenus.visible && !__applicationMenus.expanded
                Behavior on opacity { NumberAnimation { duration: UbuntuAnimation.SnapDuration } }
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
                Behavior on opacity { NumberAnimation { duration: UbuntuAnimation.SnapDuration } }
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
            // ENH028 - Open indicators via gesture
            panelOpacity: root.interactiveBlur ? 0.9 : 1
            // ENH028 - End
            // ENH002 - Notch/Punch hole fix
            // ENH036 - Use punchole as battery indicator
            /*contentRightMargin: shell.isBuiltInScreen && !inverted
                                    ? shell.orientation == 1 && shell.deviceConfiguration.notchPosition == "right" && !shell.deviceConfiguration.fullyHideNotchInPortrait
                                                ? shell.deviceConfiguration.notchWidthMargin : shell.deviceConfiguration.roundedCornerMargin
                                    : 0*/
            contentRightMargin: shell.isBuiltInScreen && !inverted
                                    ? shell.orientation == 1 && shell.deviceConfiguration.notchPosition == "right" && !shell.deviceConfiguration.fullyHideNotchInPortrait
                                                ? shell.deviceConfiguration.notchWidthMargin + (panel.batteryCircleEnabled ? panel.batteryCircleBorder : 0) : shell.deviceConfiguration.roundedCornerMargin
                                    : 0
            // ENH036 - End
            // ENH002 - End

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
                readonly property bool hidden: !expanded && (overflow || !indicatorVisible || hideSessionIndicator || hideKeyboardIndicator || hideBatteryIndicator)
                // ENH036 - End
                // HACK for indicator-session
                readonly property bool hideSessionIndicator: identifier == "indicator-session" && Math.min(Screen.width, Screen.height) <= units.gu(60)
                // HACK for indicator-keyboard
                readonly property bool hideKeyboardIndicator: identifier == "indicator-keyboard" && !hasKeyboard
                // ENH036 - Use punchole as battery indicator
                readonly property bool hideBatteryIndicator: identifier == "indicator-power" && panel.batteryCircleEnabled
                // ENH036 - End

                height: parent.height
                expanded: indicators.expanded
                selected: ListView.isCurrentItem

                identifier: model.identifier
                busName: indicatorProperties.busName
                actionsObjectPath: indicatorProperties.actionsObjectPath
                menuObjectPath: indicatorProperties.menuObjectPath

                opacity: hidden ? 0.0 : 1.0
                Behavior on opacity { UbuntuNumberAnimation { duration: UbuntuAnimation.SnapDuration } }
                // ENH036 - Use punchole as battery indicator
                // width: ((expanded || indicatorVisible) && !hideSessionIndicator && !hideKeyboardIndicator) ? implicitWidth : 0
                width: ((expanded || indicatorVisible) && !hideSessionIndicator && !hideKeyboardIndicator && !hideBatteryIndicator) ? implicitWidth : 0
                // ENH036 - End

                Behavior on width { UbuntuNumberAnimation { duration: UbuntuAnimation.SnapDuration } }
                // ENH028 - Open indicators via gesture
                onSelectedChanged: {
                    if (selected && __indicators.model) {
                        __indicators.currentTitle = Qt.binding(function() { return title })
                    }
                }
                // ENH028 - End
                // ENH036 - Use punchole as battery indicator
                onRightLabelChanged: {
                    if (identifier == "indicator-power") {
                        panel.batteryLevel = rightLabel.match(/\d+/)[0]
                    }
                }
                onIconsChanged: {
                    if (identifier == "indicator-power") {
                        if (icons) {
                            if (icons[0].search("charging") > -1) {
                                panel.batteryCharging = true
                            } else {
                                panel.batteryCharging = false
                            }
                        }
                    }
                }
                // ENH036 - End
            }

            pageDelegate: PanelMenuPage {
                objectName: modelData.identifier + "-page"
                submenuIndex: 0

                menuModel: delegate.menuModel
                // ENH028 - Open indicators via gesture
                inverted: __indicators.inverted
                titleText: __indicators.currentTitle //root.dateTimeString
                onModelCountChanged: {
                    // Open notifications when there are ny
                    if (modelData.identifier == "indicator-messages") {
                        if (count > 0) {
                            __indicators.initialIndexOnInverted = 0
                        } else {
                            __indicators.initialIndexOnInverted = -1
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
            Behavior on opacity { UbuntuNumberAnimation { duration: UbuntuAnimation.SnapDuration } }

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
            // when: !fullscreenMode
            when: !fullscreenMode && !forceHidePanel
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
            // UbuntuNumberAnimation { target: panelArea; properties: "anchors.topMargin,opacity" }
            UbuntuNumberAnimation { target: panelArea; properties: "opacity" }
        },
        Transition {
            to: "offscreen"
            // UbuntuNumberAnimation { target: panelArea; properties: "anchors.topMargin,opacity" }
            UbuntuNumberAnimation { target: panelArea; properties: "opacity" }
        }
    ]
    // ENH049 - End
}
