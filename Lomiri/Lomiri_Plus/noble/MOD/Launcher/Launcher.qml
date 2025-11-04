/*
 * Copyright (C) 2013-2015 Canonical Ltd.
 * Copyright (C) 2021 UBports Foundation
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
import "../Components"
import Lomiri.Components 1.3
import Lomiri.Gestures 0.1
import Lomiri.Launcher 0.1
import Utils 0.1 as Utils
// ENH167 - Behavior changes for custom opacity/color of components
import Lomiri.Components.ListItems 1.3 as ListItems
// ENH167 - End

FocusScope {
    id: root

    readonly property int ignoreHideIfMouseOverLauncher: 1

    property bool autohideEnabled: false
    property bool lockedVisible: false
    property bool available: true // can be used to disable all interactions
    property alias inverted: panel.inverted
    property Item blurSource: null
    property int topPanelHeight: 0
    property bool drawerEnabled: true
    property alias privateMode: panel.privateMode
    property url background
    property bool lightMode : false

    property int panelWidth: units.gu(10)
    property int dragAreaWidth: units.gu(1)
    property real progress: dragArea.dragging && dragArea.touchPosition.x > panelWidth ?
                                (width * (dragArea.touchPosition.x-panelWidth) / (width - panelWidth)) : 0
    // ENH167 - Behavior changes for custom opacity/color of components
    property real drawerProgress: (drawer.width - Math.abs(drawer.x)) / drawer.width
    property bool drawerFullyClosed: drawer.fullyClosed
    // ENH167 - End

    property bool superPressed: false
    property bool superTabPressed: false
    property bool takesFocus: false;

    readonly property bool dragging: dragArea.dragging
    readonly property real dragDistance: dragArea.dragging ? dragArea.touchPosition.x : 0
    readonly property real visibleWidth: panel.width + panel.x
    readonly property alias shortcutHintsShown: panel.shortcutHintsShown

    readonly property bool shown: panel.x > -panel.width
    readonly property bool drawerShown: drawer.x == 0
    // ENH002 - Notch/Punch hole fix
    property real leftMarginBlur
    property real topMarginBlur
    // ENH002 - End
    // ENH130 - Launcher dim
    readonly property bool fullyShown: panel.x == 0
    // ENH130 - End
    // ENH139 - System Direct Actions
    property alias appModel: drawer.appModel
    // ENH139 - End
    // ENH170 - Adjust top panel based on Drawer and Indicator panels
    property real drawerOpacity: drawer.drawerOpacity
    property color drawerColor: drawer.drawerColor
    // ENH170 - End

    // emitted when an application is selected
    signal launcherApplicationSelected(string appId)

    // emitted when the dash icon in the launcher has been tapped
    signal showDashHome()

    onStateChanged: {
        if (state == "") {
            panel.dismissTimer.stop()
        } else {
            panel.dismissTimer.restart()
        }
    }

    onFocusChanged: {if (!focus) { root.takesFocus = false; }}

    onSuperPressedChanged: {
        if (state == "drawer")
            return;

        if (superPressed) {
            superPressTimer.start();
            superLongPressTimer.start();
        } else {
            superPressTimer.stop();
            superLongPressTimer.stop();
            switchToNextState(root.lockedVisible ? "visible" : "");
            panel.shortcutHintsShown = false;
        }
    }

    onSuperTabPressedChanged: {
        if (superTabPressed) {
            switchToNextState("visible")
            panel.highlightIndex = -1;
            root.takesFocus = true;
            root.focus = true;
            superPressTimer.stop();
            superLongPressTimer.stop();
        } else {
            switchToNextState(root.lockedVisible ? "visible" : "");
            root.focus = false;
            if (panel.highlightIndex == -1) {
                root.showDashHome();
            } else if (panel.highlightIndex >= 0){
                launcherApplicationSelected(LauncherModel.get(panel.highlightIndex).appId);
            }
            panel.highlightIndex = -2;
        }
    }

    onLockedVisibleChanged: {
        // We are in the progress of moving to the drawer
        // this is caused by the user pressing the bfb on unlock
        // in this case we want to show the drawer and not
        // just visible
        if (animateTimer.nextState == "drawer")
            return;

        if (lockedVisible && state == "") {
            panel.dismissTimer.stop();
            fadeOutAnimation.stop();
            switchToNextState("visible")
        } else if (!lockedVisible && (state == "visible" || state == "drawer")) {
            hide();
        }
    }

    onPanelWidthChanged: {
        hint();
    }

    // Switches the Launcher to the visible state, but only if it's not already
    // opened.
    // Prevents closing the Drawer when trying to show the Launcher.
    function show() {
        if (state === "" || state === "visibleTemporary") {
            switchToNextState("visible");
        }
    }

    function hide(flags) {
        if ((flags & ignoreHideIfMouseOverLauncher) && Utils.Functions.itemUnderMouse(panel)) {
            if (state == "drawer") {
                switchToNextState("visibleTemporary");
            }
            return;
        }
        if (root.lockedVisible) {
            // Due to binding updates when switching between modes
            // it could happen that our request to show will be overwritten
            // with a hide request. Rewrite it when we know hiding is not allowed.
            switchToNextState("visible")
        } else {
            switchToNextState("")
        }
        root.focus = false;
    }

    function fadeOut() {
        if (!root.lockedVisible) {
            fadeOutAnimation.start();
        }
    }

    function switchToNextState(state) {
        animateTimer.nextState = state
        animateTimer.start();
    }

    function tease() {
        if (available && !dragArea.dragging) {
            teaseTimer.mode = "teasing"
            teaseTimer.start();
        }
    }

    function hint() {
        if (available && root.state == "") {
            teaseTimer.mode = "hinting"
            teaseTimer.start();
        }
    }

    function pushEdge(amount) {
        if (root.state === "" || root.state == "visible" || root.state == "visibleTemporary") {
            edgeBarrier.push(amount);
        }
    }

    function openForKeyboardNavigation() {
        panel.highlightIndex = -1; // The BFB
        drawer.focus = false;
        root.takesFocus = true;
        root.focus = true;
        switchToNextState("visible")
    }

    function toggleDrawer(focusInputField, onlyOpen, alsoToggleLauncher) {
        if (!drawerEnabled) {
            return;
        }

        panel.shortcutHintsShown = false;
        superPressTimer.stop();
        superLongPressTimer.stop();
        root.takesFocus = true;
        root.focus = true;
        if (focusInputField) {
            drawer.focusInput();
        }
        if (state === "drawer" && !onlyOpen)
            if (alsoToggleLauncher && !root.lockedVisible)
                switchToNextState("");
            else
                switchToNextState("visible");
        else
            switchToNextState("drawer");
    }
    // ENH139 - System Direct Actions
    function searchInDrawer() {
        if (root.drawerShown) {
            drawer.focusInput();
        } else {
            toggleDrawer(true)
        }
    }
    // ENH139 - End

    Keys.onPressed: {
        switch (event.key) {
        case Qt.Key_Backtab:
            panel.highlightPrevious();
            event.accepted = true;
            break;
        case Qt.Key_Up:
            if (root.inverted) {
                panel.highlightNext()
            } else {
                panel.highlightPrevious();
            }
            event.accepted = true;
            break;
        case Qt.Key_Tab:
            panel.highlightNext();
            event.accepted = true;
            break;
        case Qt.Key_Down:
            if (root.inverted) {
                panel.highlightPrevious();
            } else {
                panel.highlightNext();
            }
            event.accepted = true;
            break;
        case Qt.Key_Right:
        case Qt.Key_Menu:
            panel.openQuicklist(panel.highlightIndex)
            event.accepted = true;
            break;
        case Qt.Key_Escape:
            panel.highlightIndex = -2;
            // Falling through intentionally
        case Qt.Key_Enter:
        case Qt.Key_Return:
        case Qt.Key_Space:
            if (panel.highlightIndex == -1) {
                root.showDashHome();
            } else if (panel.highlightIndex >= 0) {
                launcherApplicationSelected(LauncherModel.get(panel.highlightIndex).appId);
            }
            root.hide();
            panel.highlightIndex = -2
            event.accepted = true;
        }
    }

    Timer {
        id: superPressTimer
        interval: 200
        onTriggered: {
            switchToNextState("visible")
        }
    }

    Timer {
        id: superLongPressTimer
        interval: 1000
        onTriggered: {
            switchToNextState("visible")
            panel.shortcutHintsShown = true;
        }
    }

    Timer {
        id: teaseTimer
        interval: mode == "teasing" ? 200 : 300
        property string mode: "teasing"
    }

    // Because the animation on x is disabled while dragging
    // switching state directly in the drag handlers would not animate
    // the completion of the hide/reveal gesture. Lets update the state
    // machine and switch to the final state in the next event loop run
    Timer {
        id: animateTimer
        objectName: "animateTimer"
        interval: 1
        property string nextState: ""
        onTriggered: {
            // switching to an intermediate state here to make sure all the
            // values are restored, even if we were already in the target state
            root.state = "tmp"
            root.state = nextState
        }
    }

    Connections {
        target: LauncherModel
        function onHint() { hint(); }
    }

    Connections {
        target: i18n
        function onLanguageChanged() { LauncherModel.refresh() }
    }

    SequentialAnimation {
        id: fadeOutAnimation
        ScriptAction {
            script: {
                animateTimer.stop(); // Don't change the state behind our back
                panel.layer.enabled = true
            }
        }
        LomiriNumberAnimation {
            target: panel
            property: "opacity"
            easing.type: Easing.InQuad
            to: 0
        }
        ScriptAction {
            script: {
                panel.layer.enabled = false
                panel.animate = false;
                root.state = "";
                panel.x = -panel.width
                panel.opacity = 1;
                panel.animate = true;
            }
        }
    }

    InverseMouseArea {
        id: closeMouseArea
        anchors.fill: panel
        enabled: (root.state == "visible" && !root.lockedVisible) || root.state == "drawer" || hoverEnabled
        hoverEnabled: panel.quickListOpen
        visible: enabled
        onPressed: {
            mouse.accepted = false;
            panel.highlightIndex = -2;
            root.hide();
        }
    }

    MouseArea {
        id: launcherDragArea
        enabled: root.available && (root.state == "visible" || root.state == "visibleTemporary") && !root.lockedVisible
        anchors.fill: panel
        anchors.rightMargin: -units.gu(2)
        drag {
            axis: Drag.XAxis
            maximumX: 0
            target: panel
        }

        onReleased: {
            if (panel.x < -panel.width/3) {
                root.switchToNextState("")
            } else {
                root.switchToNextState("visible")
            }
        }
    }

    Item {
        clip: true
        x: 0
        y: drawer.y
        width: drawer.width + drawer.x
        height: drawer.height
        BackgroundBlur {
            id: backgroundBlur
            x: 0
            y: 0
            width: drawer.width
            height: drawer.height
            visible: drawer.x > -drawer.width
            sourceItem: root.blurSource
            // ENH002 - Notch/Punch hole fix
            // blurRect: Qt.rect(0,
            //                   root.topPanelHeight,
            blurRect: Qt.rect(0,
                              shell.settings.extendDrawerOverTopBar ? (root.inverted ? 0 : root.topPanelHeight) + root.topMarginBlur
                                    : root.topPanelHeight,
            // ENH002 - End
                              drawer.width,
                              drawer.height)
            // ENH002 - Notch/Punch hole fix
            // occluding: (drawer.width == root.width) && drawer.fullyOpen
            occluding: shell.settings.extendDrawerOverTopBar ? (drawer.width == root.width) && drawer.fullyOpen
                                                             : false
            // ENH002 - End
        }
    }

    Image {
        anchors.left: drawer.right
        anchors.top: drawer.top
        anchors.bottom: drawer.bottom
        width: units.gu(1)
        visible: !drawer.fullyClosed
        source: "../graphics/dropshadow_right@20.png"
    }

    // ENH130 - Launcher dim
    Loader {
        active: shell.settings.dimWhenLauncherShow
        asynchronous: true
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
            left: drawer.right
        }
        visible: opacity > 0
        opacity: root.fullyShown && !root.lockedVisible
                        && !panel.preventHiding 
                        && !shell.isWindowedMode ? 0.6 : 0
        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.BriskDuration } }

        sourceComponent: Rectangle {
            color: "black"
        }
    }
    // ENH130 - End

    Drawer {
        id: drawer
        objectName: "drawer"
        anchors {
            top: parent.top
            // ENH131 - Extend drawer to behind top panel
            // topMargin: root.inverted ? root.topPanelHeight : 0
            topMargin: shell.settings.extendDrawerOverTopBar ? 0 : root.inverted ? root.topPanelHeight : 0
            // ENH131 - End
            bottom: parent.bottom
            right: parent.left
        }
        // ENH131 - Extend drawer to behind top panel
        topPanelHeight: shell.settings.extendDrawerOverTopBar ? root.topPanelHeight : 0
        // ENH131 - End
        background: root.background
        width: Math.min(root.width, units.gu(81))
        panelWidth: panel.width
        allowSlidingAnimation: !dragArea.dragging && !launcherDragArea.drag.active && panel.animate
        lightMode: root.lightMode
        // ENH007 - Bottom search in drawer
        // ENH046 - Lomiri Plus Settings
        //inverted: root.inverted
        inverted: shell.settings.invertedDrawer && root.inverted
        // ENH046 - End
        // ENH007 - End
        // ENH105 - Custom app drawer
        launcherInverted: root.inverted
        // ENH105 - End

        onApplicationSelected: {
            root.launcherApplicationSelected(appId)
            root.hide();
            root.focus = false;
        }

        onHideRequested: {
            root.hide();
        }

        onOpenRequested: {
            root.toggleDrawer(false, true);
        }

        onFullyClosedChanged: {
            if (!fullyClosed)
                return

            drawer.unFocusInput()
            root.focus = false
        }
    }

    // ENH167 - Behavior changes for custom opacity/color of components
    ListItems.ThinDivider {
        visible: opacity > 0
        opacity: shell.settings.customLauncherOpacityBehavior ? 1 - panel.colorOpacity : 0
        anchors {
            left: undefined
            right: undefined
            verticalCenter: root.verticalCenter
            horizontalCenter: panel.right
        }
        width: root.height * 0.9
        rotation: 90
        Behavior on opacity { LomiriNumberAnimation {} }
    }
    // ENH167 - End
    // ENH171 - Add blur to Top Panel and Drawer
    Item {
        clip: true
        x: 0
        y: panel.y
        width: panel.width + panel.x
        height: panel.height
        visible: shell.settings.enableLauncherBlur && opacity > 0
        // Disabled in favor of hiding the Drawer behind the blur
        //opacity: root.drawerProgress > 0 ? 0 : 1

        BackgroundBlur {
            id: launcherBackgroundBlur
            x: 0
            y: 0
            width: panel.width
            height: panel.height
            visible: panel.x > -panel.width
            sourceItem: shell.settings.enableLauncherBlur ? root.blurSource : null
            // ENH002 - Notch/Punch hole fix
            // blurRect: Qt.rect(0,
            //                   root.topPanelHeight,
            blurRect: Qt.rect(0,
                              (root.inverted ? 0 : root.topPanelHeight) + root.topMarginBlur,
            // ENH002 - End
                              panel.width,
                              panel.height)
            occluding: shell.settings.extendDrawerOverTopBar ? (drawer.width == root.width) && drawer.fullyOpen
                                                             : false
        }
    }
    // ENH171 - End

    LauncherPanel {
        id: panel
        objectName: "launcherPanel"
        enabled: root.available && (root.state == "visible" || root.state == "visibleTemporary" || root.state == "drawer")
        width: root.panelWidth
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        x: -width
        visible: root.x > 0 || x > -width || dragArea.pressed
        lightMode: root.lightMode
        model: LauncherModel

        // ENH167 - Behavior changes for custom opacity/color of components
        gestureDragging: root.dragging
        drawerShown: root.drawerShown
        drawerProgress: root.drawerProgress
        drawerBGColor: drawer.drawerBGColor
        // ENH167 - End
        // ENH126 - Old school Launcher selection
        property var hoveredItem
        property bool isReadyForDirectSelect: {
            let _dragGlobalMapped = dragArea.mapToItem(shell, dragArea.touchPosition.x, dragArea.touchPosition.y)
            let _panelGlobalMapped = panel.mapToItem(shell, 0, 0)
            let _panelMappedX = root.inverted ? _panelGlobalMapped.x : panel.width

            if (dragArea.dragging && _dragGlobalMapped.x > panel.width && _dragGlobalMapped.x < _panelMappedX + panel.width + (panel.inchInPixel * 0.1)) {
                return true
            }

            return false
        }
        property bool isActuallyReady: false

        availableWidth: root.width
        availableHeight: root.height
        topPanelHeight: root.topPanelHeight
        
        onIsReadyForDirectSelectChanged: {
            delayAppSelect.setAppSelectReady(isReadyForDirectSelect)
        }

        onHoveredItemChanged: {
            if (hoveredItem) {
                delayHaptics.startDelay(hoveredItem)
                //console.log("HOVERED!!!! " + hoveredItem.name)
            }
        }
        
        Timer {
            id: delayHaptics
            
            property var plannedHoveredItem

            running: false
            interval: 100
            onTriggered: {
                if (plannedHoveredItem == panel.hoveredItem) {
                    shell.haptics.playSubtle()
                }
            }

            function startDelay(_item) {
                stop()
                plannedHoveredItem = _item
                restart()
            }
        }

        Timer {
            id: delayAppSelect

            property bool plannedIsSelectReady

            running: false
            interval: 100
            onTriggered: {
                if (panel.isReadyForDirectSelect == plannedIsSelectReady) {
                    panel.isActuallyReady = plannedIsSelectReady
                }
            }

            function setAppSelectReady(_isReady) {
                stop()
                plannedIsSelectReady = _isReady
                restart()
            }
        }

        Connections {
            target: dragArea
            enabled: shell.settings.enableDirectAppInLauncher

            function onTouchPositionChanged() {
                if (panel.isActuallyReady) {
                    // ENH216 - Right Edge gesture for Waydroid
                    // let _mappedY = root.inverted ? panel.height - target.touchPosition.y - panel.bfbHeight : target.touchPosition.y - panel.bfbHeight
                    let _adjustedForWaydroidGestures = dragArea.height !== root.height
                    let _heightAdjustment = 0
                    let _disabledAreaHeight = root.height * dragArea.heightMultiplier
                    if (_adjustedForWaydroidGestures) {
                        if (dragArea.disableTopSection) {
                            if (root.inverted) {
                                _heightAdjustment = -_disabledAreaHeight
                            } else {
                                _heightAdjustment = _disabledAreaHeight
                            }
                        } else {
                            _heightAdjustment = dragArea.y
                        }
                    }
                    let _mappedY = root.inverted ? panel.height - target.touchPosition.y - panel.bfbHeight + _heightAdjustment : target.touchPosition.y - panel.bfbHeight + _heightAdjustment - root.topPanelHeight
                    // ENH216 - End
                    // ENH169 - Launcher bottom margin for rounded corners
                    //let _hoveredItem = panel.listview.itemAt(panel.width / 2, _mappedY + panel.listview.realContentY)
                    let _hoveredItem = panel.listview.itemAt(panel.width / 2, _mappedY + panel.listview.realContentY - panel.panelBottomMargin)
                    // ENH169 - End

                    if (_hoveredItem !== panel.hoveredItem) {
                        panel.hoveredItem = _hoveredItem
                    }
                } else {
                    panel.hoveredItem = null
                }
            }

            function onDraggingChanged() {
                if (!target.dragging && panel.hoveredItem) {
                    panel.applicationSelected(panel.hoveredItem.appId)
                    panel.hoveredItem = null
                    shell.haptics.play()
                }
            }
        }
        // ENH126 - End

        property var dismissTimer: Timer { interval: 500 }
        Connections {
            target: panel.dismissTimer
            function onTriggered() {
                if (root.state !== "drawer" && root.autohideEnabled && !root.lockedVisible) {
                    if (!edgeBarrier.containsMouse && !panel.preventHiding) {
                        root.state = ""
                    } else {
                        panel.dismissTimer.restart()
                    }
                }
            }
        }

        property bool animate: true

        onApplicationSelected: {
            launcherApplicationSelected(appId);
            root.hide(ignoreHideIfMouseOverLauncher);
        }
        onShowDashHome: {
            root.hide(ignoreHideIfMouseOverLauncher);
            root.showDashHome();
        }

        onPreventHidingChanged: {
            if (panel.dismissTimer.running) {
                panel.dismissTimer.restart();
            }
        }

        onKbdNavigationCancelled: {
            panel.highlightIndex = -2;
            root.hide();
            root.focus = false;
        }

        onDraggingChanged: {
            drawer.unFocusInput()
        }

        Behavior on x {
            enabled: !dragArea.dragging && !launcherDragArea.drag.active && panel.animate;
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: LomiriAnimation.FastDuration; easing.type: Easing.OutCubic
            }
        }
    }

    EdgeBarrier {
        id: edgeBarrier
        edge: Qt.LeftEdge
        target: parent
        // ENH104 - Mouse edge push settings
        // enabled: root.available
        // ENH133 - Hot corners
        //enabled: root.available && !shell.settings.disableLeftEdgeMousePush
        enabled: root.available && !shell.settings.disableLeftEdgeMousePush
        // ENH133 - End
        // ENH104 - End
        // ENH163 - Less sensitive edge barrier
        // Allow same sensitivity in the Launcher when it autohides
        onRealProgressWhenLessSensitiveChanged: {
            if (autohideEnabled) {
                if (realProgressWhenLessSensitive > .5 && root.state != "visibleTemporary" && root.state != "drawer" && root.state != "visible") {
                    root.switchToNextState("visibleTemporary");
                }
                if (realProgressWhenLessSensitive === 1) {
                    root.toggleDrawer()
                }
            }
        }
        // ENH163 - End
        onProgressChanged: {
            if (progress > .5 && root.state != "visibleTemporary" && root.state != "drawer" && root.state != "visible") {
            // ENH163 - End
                root.switchToNextState("visibleTemporary");
            }
        }
        onPassed: {
            if (root.drawerEnabled) {
                root.toggleDrawer()
            }
        }

        material: Component {
            Item {
                Rectangle {
                    width: parent.height
                    height: parent.width
                    rotation: -90
                    anchors.centerIn: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(panel.color.r, panel.color.g, panel.color.b, .5)}
                        GradientStop { position: 1.0; color: Qt.rgba(panel.color.r,panel.color.g,panel.color.b,0)}
                    }
                }
            }
        }
    }

    SwipeArea {
        id: dragArea
        objectName: "launcherDragArea"

        direction: Direction.Rightwards
        // ENH018 - Immersive mode
        // enabled: root.available
        enabled: root.available && !shell.immersiveMode
        // ENH018 - End
        // ENH002 - Notch/Punch hole fix
        // x: -root.x // so if launcher is adjusted relative to screen, we stay put (like tutorial does when teasing)
        // width: root.dragAreaWidth
        //x: -root.x - (shell.isBuiltInScreen ? 170 : 0) // so if launcher is adjusted relative to screen, we stay put (like tutorial does when teasing)
        //width: root.dragAreaWidth + (shell.isBuiltInScreen ? 170 : 0)
        x: -root.x - (shell.isBuiltInScreen ? shell.deviceConfiguration.notchHeightMargin : 0) // so if launcher is adjusted relative to screen, we stay put (like tutorial does when teasing)
        width: root.dragAreaWidth + (shell.isBuiltInScreen ? shell.deviceConfiguration.notchHeightMargin : 0)
        // ENH002 - End
        // ENH216 - Right Edge gesture for Waydroid
        // height: root.height

        height: {
            if (disableForWaydroid && shell.foregroundAppIsWaydroid) {
                 return root.height - (root.height * heightMultiplier)
             }

             return root.height
        }
        
        y: {
            if (disableForWaydroid && shell.foregroundAppIsWaydroid && disableTopSection) {
                return root.height - height
            }

            return 0
        }

        readonly property bool disableForWaydroid: shell.settings.disableLeftEdgeForWaydroid
        readonly property real heightMultiplier: shell.settings.disableLeftEdgeForWaydroidHeight / 100
        readonly property int disableTopSection: shell.settings.disableLeftEdgeForWaydroidEdge === 0

        onHeightMultiplierChanged: if (shell.settingsShown) previewHintRec.show()

        Rectangle {
            id: previewHintRec

            color: theme.palette.normal.activity
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: {
                    if (shell.foregroundAppIsWaydroid) {
                        if (dragArea.disableTopSection) {
                            return -(root.height - dragArea.height)
                        } else {
                            return dragArea.height
                        }
                    } else {
                        if (dragArea.disableTopSection) {
                            return 0
                        } else {
                            return dragArea.height - (parent.height * dragArea.heightMultiplier)
                        }
                    }
                }
                bottomMargin: {
                    if (shell.foregroundAppIsWaydroid) {
                        if (dragArea.disableTopSection) {
                            return dragArea.height
                        } else {
                            return -(root.height - dragArea.height)
                        }
                    } else {
                        if (dragArea.disableTopSection) {
                            return dragArea.height - (parent.height * dragArea.heightMultiplier)
                        } else {
                            return 0
                        }
                    }
                }
            }
            visible: false

            function show() {
                visible = true
                timeoutTimer.restart()
            }

            function hide() {
                visible = false
            }

            Timer {
                id: timeoutTimer

                interval: 1000
                onTriggered: previewHintRec.hide()
            }
        }
        // ENH216 - End

        function easeInOutCubic(t) { return t<.5 ? 4*t*t*t : (t-1)*(2*t-2)*(2*t-2)+1 }

        property var lastDragPoints: []

        function dragDirection() {
            if (lastDragPoints.length < 5) {
                return "unknown";
            }

            var toRight = true;
            var toLeft = true;
            for (var i = lastDragPoints.length - 5; i < lastDragPoints.length; i++) {
                if (toRight && lastDragPoints[i] < lastDragPoints[i-1]) {
                    toRight = false;
                }
                if (toLeft && lastDragPoints[i] > lastDragPoints[i-1]) {
                    toLeft = false;
                }
            }
            return toRight ? "right" : toLeft ? "left" : "unknown";
        }

        onDistanceChanged: {
            if (dragging && launcher.state != "visible" && launcher.state != "drawer") {
                panel.x = -panel.width + Math.min(Math.max(0, distance), panel.width);
            }

            if (root.drawerEnabled && dragging && launcher.state != "drawer") {
                lastDragPoints.push(distance)
                // ENH167 - Behavior changes for custom opacity/color of components
                // var drawerHintDistance = panel.width + units.gu(1)
                var drawerHintDistance = shell.settings.customLauncherOpacityBehavior ? panel.width : panel.width + units.gu(1)
                // ENH167 - End
                if (distance < drawerHintDistance) {
                    drawer.anchors.rightMargin = -Math.min(Math.max(0, distance), drawer.width);
                } else {
                    var linearDrawerX = Math.min(Math.max(0, distance - drawerHintDistance), drawer.width);
                    var linearDrawerProgress = linearDrawerX / (drawer.width)
                    var easedDrawerProgress = easeInOutCubic(linearDrawerProgress);
                    drawer.anchors.rightMargin = -(drawerHintDistance + easedDrawerProgress * (drawer.width - drawerHintDistance));
                }
            }
        }

        onDraggingChanged: {
            if (!dragging) {
                if (distance > panel.width / 2) {
                    if (root.drawerEnabled && distance > panel.width * 3 && dragDirection() !== "left") {
                        root.toggleDrawer(false)
                    } else {
                        root.switchToNextState("visible");
                    }
                } else if (root.state === "") {
                    // didn't drag far enough. rollback
                    root.switchToNextState("");
                }
            }
            lastDragPoints = [];
        }

        GestureAreaSizeHint {
            anchors.fill: parent
        }
    }

    states: [
        State {
            name: "" // hidden state. Must be the default state ("") because "when:" falls back to this.
            PropertyChanges {
                target: panel
                restoreEntryValues: false
                x: -root.panelWidth
            }
            PropertyChanges {
                target: drawer
                restoreEntryValues: false
                anchors.rightMargin: 0
                focus: false
            }
        },
        State {
            name: "visible"
            PropertyChanges {
                target: panel
                restoreEntryValues: false
                x: -root.x // so we never go past panelWidth, even when teased by tutorial
                focus: true
            }
            PropertyChanges {
                target: drawer
                restoreEntryValues: false
                anchors.rightMargin: 0
                focus: false
            }
            PropertyChanges {
                target: root
                restoreEntryValues: false
                autohideEnabled: false
            }
        },
        State {
            name: "drawer"
            PropertyChanges {
                target: panel
                restoreEntryValues: false
                x: -root.x // so we never go past panelWidth, even when teased by tutorial
                focus: false
            }
            PropertyChanges {
                target: drawer
                restoreEntryValues: false
                anchors.rightMargin: -drawer.width + root.x // so we never go past panelWidth, even when teased by tutorial
                focus: true
            }
        },
        State {
            name: "visibleTemporary"
            extend: "visible"
            PropertyChanges {
                target: root
                restoreEntryValues: false
                autohideEnabled: true
            }
        },
        State {
            name: "teasing"
            when: teaseTimer.running && teaseTimer.mode == "teasing"
            PropertyChanges {
                target: panel
                restoreEntryValues: false
                x: -root.panelWidth + units.gu(2)
            }
        },
        State {
            name: "hinting"
            when: teaseTimer.running && teaseTimer.mode == "hinting"
            PropertyChanges {
                target: panel
                restoreEntryValues: false
                x: 0
            }
        }
    ]
}
