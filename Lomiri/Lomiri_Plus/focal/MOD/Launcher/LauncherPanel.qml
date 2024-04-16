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
import QtQml.StateMachine 1.0 as DSM
import Lomiri.Components 1.3
import Lomiri.Launcher 0.1
import Lomiri.Components.Popups 1.3
import Utils 0.1
import "../Components"

// ENH126 - Old school Launcher selection
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
import QtQuick.Window 2.2
// ENH126 - End

Rectangle {
    id: root
    color: "#F2111111"
    // ENH021 - BFB Design Changes
    //radius: units.gu(2)
    // ENH021 - End

    rotation: inverted ? 180 : 0

    property var model
    property bool inverted: false
    property bool privateMode: false
    property bool moving: launcherListView.moving || launcherListView.flicking
    property bool preventHiding: moving || dndArea.draggedIndex >= 0 || quickList.state === "open" || dndArea.pressed
                                 || dndArea.containsMouse || dashItem.hovered
    property int highlightIndex: -2
    property bool shortcutHintsShown: false
    readonly property bool quickListOpen: quickList.state === "open"
    readonly property bool dragging: launcherListView.dragging || dndArea.dragging

    // ENH126 - Old school Launcher selection
    readonly property real inchInPixel: Screen.pixelDensity * 25.4
    readonly property alias listview: launcherListView
    property real availableWidth: 0
    property real availableHeight: 0
    property real topPanelHeight: 0
    property real bfbHeight: bfb.height
    // ENH126 - End

    signal applicationSelected(string appId)
    signal showDashHome()
    signal kbdNavigationCancelled()

    onXChanged: {
        if (quickList.state === "open") {
            quickList.state = ""
        }
    }

    function highlightNext() {
        highlightIndex++;
        if (highlightIndex >= launcherListView.count) {
            highlightIndex = -1;
        }
        launcherListView.moveToIndex(Math.max(highlightIndex, 0));
    }
    function highlightPrevious() {
        highlightIndex--;
        if (highlightIndex <= -2) {
            highlightIndex = launcherListView.count - 1;
        }
        launcherListView.moveToIndex(Math.max(highlightIndex, 0));
    }
    function openQuicklist(index) {
        quickList.open(index);
        quickList.selectedIndex = 0;
        quickList.focus = true;
    }

    MouseArea {
        id: mouseEventEater
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onWheel: wheel.accepted = true;
    }

    Column {
        id: mainColumn
        anchors {
            fill: parent
        }

        Rectangle {
            id: bfb
            objectName: "buttonShowDashHome"
            width: parent.width
            // ENH022 - New ubuntu logo fun
            // ENH147 - Option to hide BFB
            visible: !shell.settings.hideBFB
            //height: width * .9
            height: visible ? width * .9 : 0
            // ENH147 - End
            //height: width * 1.3
            // ENH022 - End
            // ENH021 - BFB Design Changes
            // ENH046 - Lomiri Plus Settings
            // color: LomiriColors.orange
            // ENH032 - Infographics Outer Wilds
            color: shell.settings.useCustomBFBColor ? shell.settings.customBFBColor
                                                    : shell.settings.ow_bfbLogo > 0 ? "#4d4e46"
                                                                                    : LomiriColors.orange

            border {
                color: shell.settings.ow_bfbLogo > 0 ? "#6c5776" : "transparent"
                width: units.gu(0.5)
            }
            // ENH032 - End
            // ENH046 - End
            //color: LomiriColors.blue
            //radius: units.gu(2)
            // ENH021 - End
            // ENH050 - Rounded BFB
            radius: shell.settings.roundedBFB ? units.gu(1) : 0
            // ENH050 - End
            readonly property bool highlighted: root.highlightIndex == -1;
            // ENH149 - Clicking animations
            scale: dashItem.pressed ? 0.9 : 1
            Behavior on scale {
                SpringAnimation { spring: 2; damping: 0.2 }
            }
            // ENH149 - End

            Icon {
                objectName: "dashItem"
                // ENH022 - New ubuntu logo fun
                // ENH023 - Kugi logo fun
                // width: parent.width * .6
                //width: parent.width * .9
                // ENH046 - Lomiri Plus Settings
                //width: parent.width * .8
                // ENH032 - Infographics Outer Wilds
                //width: shell.settings.useCustomLogo ? parent.width * (shell.settings.customLogoScale / 100)
                //                                    : shell.settings.useLomiriLogo ? parent.width * .8
                //                                                                   : parent.width * .6
                width: {
                    if (shell.settings.useCustomLogo) {
                        return parent.width * (shell.settings.customLogoScale / 100)
                    }
                    if (shell.settings.ow_bfbLogo > 0) {
                        if (shell.settings.ow_bfbLogo == 5 || shell.settings.ow_bfbLogo == 7) {
                            return parent.width * .8
                        } else {
                            return parent.width * .6
                        }
                    }
                    if (shell.settings.useLomiriLogo) {
                        return parent.width * .8
                    }

                    return parent.width * .6
               }
               // ENH032 - End
               // ENH046 - End
                // ENH023 - End
                height: width
                anchors.centerIn: parent
                //anchors.bottom: root.inverted ? undefined : parent.bottom
                //anchors.top: root.inverted ? parent.top : undefined
                //anchors.horizontalCenter: parent.horizontalCenter
                // ENH023 - Kugi logo fun
                // source: "graphics/home.svg"
                //source: "graphics/home_new.svg"
                //source: "graphics/kugi.svg"
                // ENH046 - Lomiri Plus Settings
                //source: "graphics/lomiri.svg"
                // ENH032 - Infographics Outer Wilds
                //source: shell.settings.useCustomLogo ? "file:///home/phablet/Pictures/lomiriplus/bfb.svg"
                //                                     : shell.settings.useLomiriLogo ? "graphics/lomiri.svg"
                //                                                                    : shell.settings.useNewLogo ? "graphics/home_new.svg"
                //                                                                                               : "graphics/home.svg"
                source: {
                    if (shell.settings.useCustomLogo) {
                        return "file:///home/phablet/Pictures/lomiriplus/bfb.svg"
                    }
                    if (shell.settings.ow_bfbLogo > 0) {
                        switch (shell.settings.ow_bfbLogo) {
                            case 1:
                                return "../OuterWilds/graphics/launcher/brittle_hollow.svg"
                            case 2:
                                return "../OuterWilds/graphics/launcher/dark_bramble.svg"
                            case 3:
                                return "../OuterWilds/graphics/launcher/hourglass_twins.svg"
                            case 4:
                                return "../OuterWilds/graphics/launcher/interloper.svg"
                            case 5:
                                return "../OuterWilds/graphics/launcher/nomai_Eye.svg"
                            case 6:
                                return "../OuterWilds/graphics/launcher/quantum_moon.svg"
                            case 7:
                                return "../OuterWilds/graphics/launcher/stranger_eye.svg"
                            case 8:
                                return "../OuterWilds/graphics/launcher/sun.svg"
                            case 9:
                                return "../OuterWilds/graphics/launcher/timberhearth_white.svg"
                        }
                    }
                    if (shell.settings.useLomiriLogo) {
                        return "graphics/lomiri.svg"
                    }
                    if (shell.settings.useNewLogo) {
                        return "graphics/home_new.svg"
                    }

                    return "graphics/home.svg"
                }
                // ENH032 - End
                 // ENH046 - End
                // ENH023 - End
                // ENH022 - End
                // ENH046 - Lomiri Plus Settings
                // color: "white"
                // ENH032 - Infographics Outer Wilds
                //color: shell.settings.useCustomLogo ? shell.settings.customLogoColor : "white"
                color: shell.settings.useCustomLogo ? shell.settings.customLogoColor
                                                    : shell.settings.ow_bfbLogo > 0 ? "#6d75e4" // "#879ffc"
                                                                                    : "white"
                // ENH032 - End
                keyColor: "#ffffff"
                // ENH046 - End
                rotation: root.rotation
            }

            AbstractButton {
                id: dashItem
                anchors.fill: parent
                activeFocusOnPress: false
                onClicked: root.showDashHome()
            }

            StyledItem {
                styleName: "FocusShape"
                anchors.fill: parent
                anchors.margins: units.gu(.5)
                StyleHints {
                    visible: bfb.highlighted
                    radius: 0
                }
            }
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height - dashItem.height - parent.spacing*2

            Item {
                id: launcherListViewItem
                anchors.fill: parent
                clip: true

                ListView {
                    id: launcherListView
                    objectName: "launcherListView"
                    anchors {
                        fill: parent
                        topMargin: -extensionSize + width * .15
                        bottomMargin: -extensionSize + width * .15
                    }
                    topMargin: extensionSize
                    bottomMargin: extensionSize
                    height: parent.height - dashItem.height - parent.spacing*2
                    model: root.model
                    cacheBuffer: itemHeight * 3
                    snapMode: interactive ? ListView.SnapToItem : ListView.NoSnap
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: (height - itemHeight) / 2
                    preferredHighlightEnd: (height + itemHeight) / 2

                    // for the single peeking icon, when alert-state is set on delegate
                    property int peekingIndex: -1

                    // The size of the area the ListView is extended to make sure items are not
                    // destroyed when dragging them outside the list. This needs to be at least
                    // itemHeight to prevent folded items from disappearing and DragArea limits
                    // need to be smaller than this size to avoid breakage.
                    property int extensionSize: itemHeight * 3

                    // Workaround: The snap settings in the launcher, will always try to
                    // snap to what we told it to do. However, we want the initial position
                    // of the launcher to not be centered, but instead start with the topmost
                    // item unfolded completely. Lets wait for the ListView to settle after
                    // creation and then reposition it to 0.
                    // https://bugreports.qt-project.org/browse/QTBUG-32251
                    Component.onCompleted: {
                        initTimer.start();
                    }
                    Timer {
                        id: initTimer
                        interval: 1
                        onTriggered: {
                            launcherListView.moveToIndex(0)
                        }
                    }

                    // The height of the area where icons start getting folded
                    property int foldingStartHeight: itemHeight
                    // The height of the area where the items reach the final folding angle
                    property int foldingStopHeight: foldingStartHeight - itemHeight - spacing
                    property int itemWidth: width * .75
                    property int itemHeight: itemWidth * 15 / 16 + units.gu(1)
                    property int clickFlickSpeed: units.gu(60)
                    property int draggedIndex: dndArea.draggedIndex
                    property real realContentY: contentY - originY + topMargin
                    property int realItemHeight: itemHeight + spacing

                    // In case the start dragging transition is running, we need to delay the
                    // move because the displaced transition would clash with it and cause items
                    // to be moved to wrong places
                    property bool draggingTransitionRunning: false
                    property int scheduledMoveTo: -1

                    LomiriNumberAnimation {
                        id: snapToBottomAnimation
                        target: launcherListView
                        property: "contentY"
                        to: launcherListView.originY + launcherListView.topMargin
                    }

                    LomiriNumberAnimation {
                        id: snapToTopAnimation
                        target: launcherListView
                        property: "contentY"
                        to: launcherListView.contentHeight - launcherListView.height + launcherListView.originY - launcherListView.topMargin
                    }

                    LomiriNumberAnimation {
                        id: moveAnimation
                        objectName: "moveAnimation"
                        target: launcherListView
                        property: "contentY"
                        function moveTo(contentY) {
                            from = launcherListView.contentY;
                            to = contentY;
                            restart();
                        }
                    }
                    function moveToIndex(index) {
                        var totalItemHeight = launcherListView.itemHeight + launcherListView.spacing
                        var itemPosition = index * totalItemHeight;
                        var height = launcherListView.height - launcherListView.topMargin - launcherListView.bottomMargin
                        var distanceToEnd = index == 0 || index == launcherListView.count - 1 ? 0 : totalItemHeight
                        if (itemPosition + totalItemHeight + distanceToEnd > launcherListView.contentY + launcherListView.originY + launcherListView.topMargin + height) {
                            moveAnimation.moveTo(itemPosition + launcherListView.itemHeight - launcherListView.topMargin - height + distanceToEnd - launcherListView.originY);
                        } else if (itemPosition - distanceToEnd < launcherListView.contentY - launcherListView.originY + launcherListView.topMargin) {
                            moveAnimation.moveTo(itemPosition - distanceToEnd - launcherListView.topMargin + launcherListView.originY);
                        }
                    }

                    displaced: Transition {
                        NumberAnimation { properties: "x,y"; duration: LomiriAnimation.FastDuration; easing: LomiriAnimation.StandardEasing }
                    }

                    delegate: FoldingLauncherDelegate {
                        id: launcherDelegate
                        objectName: "launcherDelegate" + index
                        // We need the appId in the delegate in order to find
                        // the right app when running autopilot tests for
                        // multiple apps.
                        readonly property string appId: model.appId
                        name: model.name
                        itemIndex: index
                        itemHeight: launcherListView.itemHeight
                        itemWidth: launcherListView.itemWidth
                        width: parent.width
                        height: itemHeight
                        iconName: model.icon
                        count: model.count
                        countVisible: model.countVisible
                        progress: model.progress
                        itemRunning: model.running
                        itemFocused: model.focused
                        inverted: root.inverted
                        alerting: model.alerting
                        highlighted: root.highlightIndex == index
                        shortcutHintShown: root.shortcutHintsShown && index <= 9
                        surfaceCount: model.surfaceCount
                        z: -Math.abs(offset)
                        maxAngle: 55
                        property bool dragging: false
                        // ENH149 - Clicking animations
                        scale: dndArea.selectedItem == this && dndArea.pressed ? 0.8 : 1
                        Behavior on scale {
                            SpringAnimation { spring: 2; damping: 0.2 }
                        }
                        // ENH149 - End

                        SequentialAnimation {
                            id: peekingAnimation
                            objectName: "peekingAnimation" + index

                            // revealing
                            PropertyAction { target: root; property: "visible"; value: (launcher.visibleWidth === 0) ? 1 : 0 }
                            PropertyAction { target: launcherListViewItem; property: "clip"; value: 0 }

                            LomiriNumberAnimation {
                                target: launcherDelegate
                                alwaysRunToEnd: true
                                loops: 1
                                properties: "x"
                                to: (units.gu(.5) + launcherListView.width * .5) * (root.inverted ? -1 : 1)
                                duration: LomiriAnimation.BriskDuration
                            }

                            // hiding
                            LomiriNumberAnimation {
                                target: launcherDelegate
                                alwaysRunToEnd: true
                                loops: 1
                                properties: "x"
                                to: 0
                                duration: LomiriAnimation.BriskDuration
                            }

                            PropertyAction { target: launcherListViewItem; property: "clip"; value: 1 }
                            PropertyAction { target: root; property: "visible"; value: (launcher.visibleWidth === 0) ? 1 : 0 }
                            PropertyAction { target: launcherListView; property: "peekingIndex"; value: -1 }
                        }

                        onAlertingChanged: {
                            if(alerting) {
                                if (!dragging && (launcherListView.peekingIndex === -1 || launcher.visibleWidth > 0)) {
                                    launcherListView.moveToIndex(index)
                                    if (!dragging && launcher.state !== "visible" && launcher.state !== "drawer") {
                                        peekingAnimation.start()
                                    }
                                }

                                if (launcherListView.peekingIndex === -1) {
                                    launcherListView.peekingIndex = index
                                }
                            } else {
                                if (launcherListView.peekingIndex === index) {
                                    launcherListView.peekingIndex = -1
                                }
                            }
                        }

                        Image {
                            id: dropIndicator
                            objectName: "dropIndicator"
                            anchors.centerIn: parent
                            height: visible ? units.dp(2) : 0
                            width: parent.width + mainColumn.anchors.leftMargin + mainColumn.anchors.rightMargin
                            opacity: 0
                            source: "graphics/divider-line.png"
                        }

                        states: [
                            State {
                                name: "selected"
                                when: dndArea.selectedItem === launcherDelegate && fakeDragItem.visible && !dragging
                                PropertyChanges {
                                    target: launcherDelegate
                                    itemOpacity: 0
                                }
                            },
                            State {
                                name: "dragging"
                                when: dragging
                                PropertyChanges {
                                    target: launcherDelegate
                                    height: units.gu(1)
                                    itemOpacity: 0
                                }
                                PropertyChanges {
                                    target: dropIndicator
                                    opacity: 1
                                }
                            },
                            State {
                                name: "expanded"
                                when: dndArea.draggedIndex >= 0 && (dndArea.preDragging || dndArea.dragging || dndArea.postDragging) && dndArea.draggedIndex != index
                                PropertyChanges {
                                    target: launcherDelegate
                                    angle: 0
                                    offset: 0
                                    itemOpacity: 0.6
                                }
                            }
                        ]

                        transitions: [
                            Transition {
                                from: ""
                                to: "selected"
                                NumberAnimation { properties: "itemOpacity"; duration: LomiriAnimation.FastDuration }
                            },
                            Transition {
                                from: "*"
                                to: "expanded"
                                NumberAnimation { properties: "itemOpacity"; duration: LomiriAnimation.FastDuration }
                                LomiriNumberAnimation { properties: "angle,offset" }
                            },
                            Transition {
                                from: "expanded"
                                to: ""
                                NumberAnimation { properties: "itemOpacity"; duration: LomiriAnimation.BriskDuration }
                                LomiriNumberAnimation { properties: "angle,offset" }
                            },
                            Transition {
                                id: draggingTransition
                                from: "selected"
                                to: "dragging"
                                SequentialAnimation {
                                    PropertyAction { target: launcherListView; property: "draggingTransitionRunning"; value: true }
                                    ParallelAnimation {
                                        LomiriNumberAnimation { properties: "height" }
                                        NumberAnimation { target: dropIndicator; properties: "opacity"; duration: LomiriAnimation.FastDuration }
                                    }
                                    ScriptAction {
                                        script: {
                                            if (launcherListView.scheduledMoveTo > -1) {
                                                launcherListView.model.move(dndArea.draggedIndex, launcherListView.scheduledMoveTo)
                                                dndArea.draggedIndex = launcherListView.scheduledMoveTo
                                                launcherListView.scheduledMoveTo = -1
                                            }
                                        }
                                    }
                                    PropertyAction { target: launcherListView; property: "draggingTransitionRunning"; value: false }
                                }
                            },
                            Transition {
                                from: "dragging"
                                to: "*"
                                NumberAnimation { target: dropIndicator; properties: "opacity"; duration: LomiriAnimation.SnapDuration }
                                NumberAnimation { properties: "itemOpacity"; duration: LomiriAnimation.BriskDuration }
                                SequentialAnimation {
                                    ScriptAction { script: if (index == launcherListView.count-1) launcherListView.flick(0, -launcherListView.clickFlickSpeed); }
                                    LomiriNumberAnimation { properties: "height" }
                                    ScriptAction { script: if (index == launcherListView.count-1) launcherListView.flick(0, -launcherListView.clickFlickSpeed); }
                                    PropertyAction { target: dndArea; property: "postDragging"; value: false }
                                    PropertyAction { target: dndArea; property: "draggedIndex"; value: -1 }
                                }
                            }
                        ]
                    }

                    MouseArea {
                        id: dndArea
                        objectName: "dndArea"
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        anchors {
                            fill: parent
                            topMargin: launcherListView.topMargin
                            bottomMargin: launcherListView.bottomMargin
                        }
                        drag.minimumY: -launcherListView.topMargin
                        drag.maximumY: height + launcherListView.bottomMargin

                        property int draggedIndex: -1
                        property var selectedItem
                        property bool preDragging: false
                        property bool dragging: !!selectedItem && selectedItem.dragging
                        property bool postDragging: false
                        property int startX
                        property int startY

                        // This is a workaround for some issue in the QML ListView:
                        // When calling moveToItem(0), the listview visually positions itself
                        // correctly to display the first item expanded. However, some internal
                        // state seems to not be valid, and the next time the user clicks on it,
                        // it snaps back to the snap boundries before executing the onClicked handler.
                        // This can cause the listview getting stuck in a snapped position where you can't
                        // launch things without first dragging the launcher manually. So lets read the item
                        // angle before that happens and use that angle instead of the one we get in onClicked.
                        property real pressedStartAngle: 0
                        onPressed: {
                            var clickedItem = launcherListView.itemAt(mouseX, mouseY + launcherListView.realContentY)
                            pressedStartAngle = clickedItem.angle;
                            processPress(mouse);
                        }

                        function processPress(mouse) {
                            selectedItem = launcherListView.itemAt(mouse.x, mouse.y + launcherListView.realContentY)
                        }

                        onClicked: {
                            var index = Math.floor((mouseY + launcherListView.realContentY) / launcherListView.realItemHeight);
                            var clickedItem = launcherListView.itemAt(mouseX, mouseY + launcherListView.realContentY)

                            // Check if we actually clicked an item or only at the spacing in between
                            if (clickedItem === null) {
                                return;
                            }

                            if (mouse.button & Qt.RightButton) { // context menu
                                // Opening QuickList
                                quickList.open(index);
                                return;
                            }

                            Haptics.play();

                            // First/last item do the scrolling at more than 12 degrees
                            if (index == 0 || index == launcherListView.count - 1) {
                                launcherListView.moveToIndex(index);
                                if (pressedStartAngle <= 12 && pressedStartAngle >= -12) {
                                    root.applicationSelected(LauncherModel.get(index).appId);
                                }
                                return;
                            }

                            // the rest launches apps up to an angle of 30 degrees
                            if (clickedItem.angle > 30 || clickedItem.angle < -30) {
                                launcherListView.moveToIndex(index);
                            } else {
                                root.applicationSelected(LauncherModel.get(index).appId);
                            }
                        }

                        onCanceled: {
                            endDrag(drag);
                        }

                        onReleased: {
                            endDrag(drag);
                        }

                        function endDrag(dragItem) {
                            var droppedIndex = draggedIndex;
                            if (dragging) {
                                postDragging = true;
                            } else {
                                draggedIndex = -1;
                            }

                            if (!selectedItem) {
                                return;
                            }

                            selectedItem.dragging = false;
                            selectedItem = undefined;
                            preDragging = false;

                            dragItem.target = undefined

                            progressiveScrollingTimer.stop();
                            launcherListView.interactive = true;
                            if (droppedIndex >= launcherListView.count - 2 && postDragging) {
                                snapToBottomAnimation.start();
                            } else if (droppedIndex < 2 && postDragging) {
                                snapToTopAnimation.start();
                            }
                        }

                        onPressAndHold: {
                            processPressAndHold(mouse, drag);
                        }

                        function processPressAndHold(mouse, dragItem) {
                            if (Math.abs(selectedItem.angle) > 30) {
                                return;
                            }

                            Haptics.play();

                            draggedIndex = Math.floor((mouse.y + launcherListView.realContentY) / launcherListView.realItemHeight);

                            quickList.open(draggedIndex)

                            launcherListView.interactive = false

                            var yOffset = draggedIndex > 0 ? (mouse.y + launcherListView.realContentY) % (draggedIndex * launcherListView.realItemHeight) : mouse.y + launcherListView.realContentY

                            fakeDragItem.iconName = launcherListView.model.get(draggedIndex).icon
                            fakeDragItem.x = units.gu(0.5)
                            fakeDragItem.y = mouse.y - yOffset + launcherListView.anchors.topMargin + launcherListView.topMargin
                            fakeDragItem.angle = selectedItem.angle * (root.inverted ? -1 : 1)
                            fakeDragItem.offset = selectedItem.offset * (root.inverted ? -1 : 1)
                            fakeDragItem.count = LauncherModel.get(draggedIndex).count
                            fakeDragItem.progress = LauncherModel.get(draggedIndex).progress
                            fakeDragItem.flatten()
                            dragItem.target = fakeDragItem

                            startX = mouse.x
                            startY = mouse.y
                        }

                        onPositionChanged: {
                            processPositionChanged(mouse)
                        }

                        function processPositionChanged(mouse) {
                            if (draggedIndex >= 0) {
                                if (selectedItem && !selectedItem.dragging) {
                                    var distance = Math.max(Math.abs(mouse.x - startX), Math.abs(mouse.y - startY))
                                    if (!preDragging && distance > units.gu(1.5)) {
                                        preDragging = true;
                                        quickList.state = "";
                                    }
                                    if (distance > launcherListView.itemHeight) {
                                        selectedItem.dragging = true
                                        preDragging = false;
                                    }
                                    return
                                }

                                var itemCenterY = fakeDragItem.y + fakeDragItem.height / 2

                                // Move it down by the the missing size to compensate index calculation with only expanded items
                                itemCenterY += (launcherListView.itemHeight - selectedItem.height) / 2

                                if (mouseY > launcherListView.height - launcherListView.topMargin - launcherListView.bottomMargin - launcherListView.realItemHeight) {
                                    progressiveScrollingTimer.downwards = false
                                    progressiveScrollingTimer.start()
                                } else if (mouseY < launcherListView.realItemHeight) {
                                    progressiveScrollingTimer.downwards = true
                                    progressiveScrollingTimer.start()
                                } else {
                                    progressiveScrollingTimer.stop()
                                }

                                var newIndex = (itemCenterY + launcherListView.realContentY) / launcherListView.realItemHeight

                                if (newIndex > draggedIndex + 1) {
                                    newIndex = draggedIndex + 1
                                } else if (newIndex < draggedIndex) {
                                    newIndex = draggedIndex -1
                                } else {
                                    return
                                }

                                if (newIndex >= 0 && newIndex < launcherListView.count) {
                                    if (launcherListView.draggingTransitionRunning) {
                                        launcherListView.scheduledMoveTo = newIndex
                                    } else {
                                        launcherListView.model.move(draggedIndex, newIndex)
                                        draggedIndex = newIndex
                                    }
                                }
                            }
                        }
                    }
                    Timer {
                        id: progressiveScrollingTimer
                        interval: 2
                        repeat: true
                        running: false
                        property bool downwards: true
                        onTriggered: {
                            if (downwards) {
                                var minY =  -launcherListView.topMargin
                                if (launcherListView.contentY > minY) {
                                    launcherListView.contentY = Math.max(launcherListView.contentY - units.dp(2), minY)
                                }
                            } else {
                                var maxY = launcherListView.contentHeight - launcherListView.height + launcherListView.topMargin + launcherListView.originY
                                if (launcherListView.contentY < maxY) {
                                    launcherListView.contentY = Math.min(launcherListView.contentY + units.dp(2), maxY)
                                }
                            }
                        }
                    }
                }
            }

            LauncherDelegate {
                id: fakeDragItem
                objectName: "fakeDragItem"
                visible: dndArea.draggedIndex >= 0 && !dndArea.postDragging
                itemWidth: launcherListView.itemWidth
                itemHeight: launcherListView.itemHeight
                height: itemHeight
                width: itemWidth
                rotation: root.rotation
                itemOpacity: 0.9
                onVisibleChanged: if (!visible) iconName = "";

                function flatten() {
                    fakeDragItemAnimation.start();
                }

                LomiriNumberAnimation {
                    id: fakeDragItemAnimation
                    target: fakeDragItem;
                    properties: "angle,offset";
                    to: 0
                }
            }
        }
    }

    LomiriShape {
        id: quickListShape
        objectName: "quickListShape"
        anchors.fill: quickList
        opacity: quickList.state === "open" ? 0.95 : 0
        visible: opacity > 0
        rotation: root.rotation
        aspect: LomiriShape.Flat

        // Denotes that the shape is not animating, to prevent race conditions during testing
        readonly property bool ready: (visible && (!quickListShapeOpacityFade.running))

        Behavior on opacity {
            LomiriNumberAnimation {
                id: quickListShapeOpacityFade
            }
        }

        source: ShaderEffectSource {
            sourceItem: quickList
            hideSource: true
        }

        Image {
            anchors {
                right: parent.left
                rightMargin: -units.dp(4)
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: -quickList.offset * (root.inverted ? -1 : 1)
            }
            height: units.gu(1)
            width: units.gu(2)
            source: "graphics/quicklist_tooltip.png"
            rotation: 90
        }
    }

    InverseMouseArea {
        anchors.fill: quickListShape
        enabled: quickList.state == "open" || pressed
        hoverEnabled: enabled
        visible: enabled

        onClicked: {
            quickList.state = "";
            quickList.focus = false;
            root.kbdNavigationCancelled();
        }

        // Forward for dragging to work when quickList is open

        onPressed: {
            var m = mapToItem(dndArea, mouseX, mouseY)
            dndArea.processPress(m)
        }

        onPressAndHold: {
            var m = mapToItem(dndArea, mouseX, mouseY)
            dndArea.processPressAndHold(m, drag)
        }

        onPositionChanged: {
            var m = mapToItem(dndArea, mouseX, mouseY)
            dndArea.processPositionChanged(m)
        }

        onCanceled: {
            dndArea.endDrag(drag);
        }

        onReleased: {
            dndArea.endDrag(drag);
        }
    }

    Rectangle {
        id: quickList
        objectName: "quickList"
        color: theme.palette.normal.background
        // Because we're setting left/right anchors depending on orientation, it will break the
        // width setting after rotating twice. This makes sure we also re-apply width on rotation
        width: root.inverted ? units.gu(30) : units.gu(30)
        height: quickListColumn.height
        visible: quickListShape.visible
        anchors {
            left: root.inverted ? undefined : parent.right
            right: root.inverted ? parent.left : undefined
            margins: units.gu(1)
        }
        y: itemCenter - (height / 2) + offset
        rotation: root.rotation

        property var model
        property string appId
        property var item
        property int selectedIndex: -1

        Keys.onPressed: {
            switch (event.key) {
            case Qt.Key_Down:
                var prevIndex = selectedIndex;
                selectedIndex = (selectedIndex + 1 < popoverRepeater.count) ? selectedIndex + 1 : 0;
                while (!popoverRepeater.itemAt(selectedIndex).clickable && selectedIndex != prevIndex) {
                    selectedIndex = (selectedIndex + 1 < popoverRepeater.count) ? selectedIndex + 1 : 0;
                }
                event.accepted = true;
                break;
            case Qt.Key_Up:
                var prevIndex = selectedIndex;
                selectedIndex = (selectedIndex > 0) ? selectedIndex - 1 : popoverRepeater.count - 1;
                while (!popoverRepeater.itemAt(selectedIndex).clickable && selectedIndex != prevIndex) {
                    selectedIndex = (selectedIndex > 0) ? selectedIndex - 1 : popoverRepeater.count - 1;
                }
                event.accepted = true;
                break;
            case Qt.Key_Left:
            case Qt.Key_Escape:
                quickList.selectedIndex = -1;
                quickList.focus = false;
                quickList.state = ""
                event.accepted = true;
                break;
            case Qt.Key_Enter:
            case Qt.Key_Return:
            case Qt.Key_Space:
                if (quickList.selectedIndex >= 0) {
                    LauncherModel.quickListActionInvoked(quickList.appId, quickList.selectedIndex)
                }
                quickList.selectedIndex = -1;
                quickList.focus = false;
                quickList.state = ""
                root.kbdNavigationCancelled();
                event.accepted = true;
                break;
            }
        }

        // internal
        property int itemCenter: item ? root.mapFromItem(quickList.item, 0, 0).y + (item.height / 2) + quickList.item.offset : units.gu(1)
        property int offset: itemCenter + (height/2) + units.gu(1) > parent.height ? -itemCenter - (height/2) - units.gu(1) + parent.height :
                             itemCenter - (height/2) < units.gu(1) ? (height/2) - itemCenter + units.gu(1) : 0

        function open(index) {
            var itemPosition = index * launcherListView.itemHeight;
            var height = launcherListView.height - launcherListView.topMargin - launcherListView.bottomMargin
            item = launcherListView.itemAt(launcherListView.width / 2, itemPosition + launcherListView.itemHeight / 2);
            quickList.model = launcherListView.model.get(index).quickList;
            quickList.appId = launcherListView.model.get(index).appId;
            quickList.state = "open";
            root.highlightIndex = index;
            quickList.forceActiveFocus();
        }

        Item {
            width: parent.width
            height: quickListColumn.height

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: {
                    var item = quickListColumn.childAt(mouseX, mouseY);
                    if (item.clickable) {
                        quickList.selectedIndex = item.index;
                    } else {
                        quickList.selectedIndex = -1;
                    }
                }
            }

            Column {
                id: quickListColumn
                width: parent.width
                height: childrenRect.height

                Repeater {
                    id: popoverRepeater
                    objectName: "popoverRepeater"
                    model: QuickListProxyModel {
                        source: quickList.model ? quickList.model : null
                        privateMode: root.privateMode
                    }

                    ListItem {
                        readonly property bool clickable: model.clickable
                        readonly property int index: model.index

                        objectName: "quickListEntry" + index
                        selected: index === quickList.selectedIndex
                        height: label.implicitHeight + label.anchors.topMargin + label.anchors.bottomMargin
                        color: model.clickable ? (selected ? theme.palette.highlighted.background : "transparent") : theme.palette.disabled.background
                        highlightColor: !model.clickable ? quickList.color : undefined // make disabled items visually unclickable
                        divider.colorFrom: LomiriColors.inkstone
                        divider.colorTo: LomiriColors.inkstone
                        divider.visible: model.hasSeparator

                        Label {
                            id: label
                            anchors.fill: parent
                            anchors.leftMargin: units.gu(3) // 2 GU for checkmark, 3 GU total
                            anchors.rightMargin: units.gu(2)
                            anchors.topMargin: units.gu(2)
                            anchors.bottomMargin: units.gu(2)
                            verticalAlignment: Label.AlignVCenter
                            text: model.label
                            fontSize: index == 0 ? "medium" : "small"
                            font.weight: index == 0 ? Font.Medium : Font.Light
                            color: model.clickable ? theme.palette.normal.backgroundText : theme.palette.disabled.backgroundText
                            elide: Text.ElideRight
                        }

                        onClicked: {
                            if (!model.clickable) {
                                return;
                            }
                            Haptics.play();
                            quickList.state = "";
                            // Unsetting model to prevent showing changing entries during fading out
                            // that may happen because of triggering an action.
                            LauncherModel.quickListActionInvoked(quickList.appId, index);
                            quickList.focus = false;
                            root.kbdNavigationCancelled();
                            quickList.model = undefined;
                        }
                    }
                }
            }
        }
    }

    // ENH126 - Old school Launcher selection
    Rectangle {
        id: selectHoverTooltip

        readonly property int itemCenter: !root.hoveredItem ? 0 : root.mapFromItem(root.hoveredItem, 0, 0).y + (root.hoveredItem.height / 2) + root.hoveredItem.offset
        readonly property real invertedYLimit: root.availableHeight - height - root.topPanelHeight
        readonly property real normalYLimit: 0

        visible: opacity > 0
        opacity: root.hoveredItem ? 1 : 0
        y: {
            let _newY = root.inverted ? itemCenter + (height * 0.5) : itemCenter - (height * 1.5)
            if (root.inverted) {
                return _newY + root.topPanelHeight > invertedYLimit ? invertedYLimit : _newY
            } else {
                return _newY < normalYLimit ? normalYLimit : _newY
            }
        }

        rotation: root.rotation
        color: theme.palette.normal.foreground
        radius: height / 4
        implicitHeight: columnLayout.height
        implicitWidth: columnLayout.width

        anchors {
            margins: units.gu(1)
            leftMargin: units.gu(3)
            rightMargin: anchors.leftMargin
        }
        
        states: [
            State {
                name: "normal"
                when: !root.inverted
                AnchorChanges {
                    target: selectHoverTooltip
                    anchors.left: parent.right
                    anchors.right: undefined
                }
            }
            , State {
                name: "inverted"
                when: root.inverted
                AnchorChanges {
                    target: selectHoverTooltip
                    anchors.left: undefined
                    anchors.right: parent.left
                }
            }
        ]

        Behavior on y {
            enabled: selectHoverTooltip.visible
            LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
        }

        ColumnLayout {
            id: columnLayout

            RowLayout {
                id: rowLayout

                Layout.preferredWidth: root.availableWidth - root.width - Layout.margins - selectHoverTooltip.anchors.leftMargin - units.gu(3)
                Layout.margins: units.gu(1)
                Layout.maximumWidth: units.gu(40)
                Layout.fillHeight: false
                Layout.fillWidth: false

                Label {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    Layout.leftMargin: root.inchInPixel * 0.3

                    text: root.hoveredItem ? root.hoveredItem.name : ""
                    wrapMode: Text.WordWrap
                    color: theme.palette.normal.foregroundText
                    textSize: Label.Large
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                }

                ProportionalShape {
                    id: selectorIconShape

                    Layout.alignment: Qt.AlignVCenter

                    implicitWidth: units.gu(6)
                    implicitHeight: implicitWidth

                    aspect: LomiriShape.DropShadow
                    source: Image {
                        sourceSize.width: selectorIconShape.width
                        sourceSize.height: selectorIconShape.height
                        source: root.hoveredItem ? root.hoveredItem.iconName : ""
                        cache: false // see lpbug#1543290 why no cache
                    }
                }
            }
        }
    }
    // ENH126 - End

    Tooltip {
        id: tooltipShape
        objectName: "tooltipShape"

        // ENH126 - Old school Launcher selection
        // visible: tooltipShownState.active
        visible: false
        // ENH126 - End
        rotation: root.rotation
        y: itemCenter - (height / 2)

        anchors {
            left: root.inverted ? undefined : parent.right
            right: root.inverted ? parent.left : undefined
            margins: units.gu(1)
        }

        readonly property var hoveredItem: dndArea.containsMouse ? launcherListView.itemAt(dndArea.mouseX, dndArea.mouseY + launcherListView.realContentY) : null
        readonly property int itemCenter: !hoveredItem ? 0 : root.mapFromItem(hoveredItem, 0, 0).y + (hoveredItem.height / 2) + hoveredItem.offset

        text: !hoveredItem ? "" : hoveredItem.name
    }

    DSM.StateMachine {
        id: tooltipStateMachine
        initialState: tooltipHiddenState
        running: true

        DSM.State {
            id: tooltipHiddenState

            DSM.SignalTransition {
                targetState: tooltipShownState
                signal: tooltipShape.hoveredItemChanged
                // !dndArea.pressed allows us to filter out touch input events
                guard: tooltipShape.hoveredItem !== null && !dndArea.pressed && !root.moving
            }
        }

        DSM.State {
            id: tooltipShownState

            DSM.SignalTransition {
                targetState: tooltipHiddenState
                signal: tooltipShape.hoveredItemChanged
                guard: tooltipShape.hoveredItem === null
            }

            DSM.SignalTransition {
                targetState: tooltipDismissedState
                signal: dndArea.onPressed
            }

            DSM.SignalTransition {
                targetState: tooltipDismissedState
                signal: quickList.stateChanged
                guard: quickList.state === "open"
            }
        }

        DSM.State {
            id: tooltipDismissedState

            DSM.SignalTransition {
                targetState: tooltipHiddenState
                signal: dndArea.positionChanged
                guard: quickList.state != "open" && !dndArea.pressed && !dndArea.moving
            }

            DSM.SignalTransition {
                targetState: tooltipHiddenState
                signal: dndArea.exited
                guard: quickList.state != "open"
            }
        }
    }
}
