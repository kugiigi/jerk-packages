/*
 * Copyright (C) 2016 Canonical Ltd.
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
import QtQuick.Layouts 1.1
import Lomiri.Components 1.3
import Lomiri.Gestures 0.1
import "../Components"
// ENH019 - Side stage floating mode
import QtQuick.Controls 2.12 as QQC2
// ENH019 - End

Showable {
    id: root
    property bool showHint: true
    // ENH020 - Side stage new width logic
    // property int panelWidth: units.gu(40)
    readonly property real minimumWidth : units.gu(42)
    property int panelWidth: {
        var baseWidth
        var parentWidth = parent.width > parent.height ? parent.width : parent.height

        if (parentWidth / 2 <= minimumWidth) {
            baseWidth = parentWidth / 2
        } else {
            if (parentWidth / 3 < minimumWidth) {
                baseWidth = minimumWidth
            } else {
                baseWidth = parentWidth / 3
            }
        }
        
        return baseWidth - (handleWidth / 2)
    }
    // ENH020 - End
    // ENH019 - Side stage floating mode
    property bool floating: false
    onShownChanged: floatButton.shown = true
    // ENH019 - End
    // ENH172 - Shorten Side Stage Handle
    property real availableDesktopAreaHeight: 0
    // ENH172 - End
    // ENH212 - Side-stage focus indicator
    property bool isFocused: false
    // ENH212 - End
    readonly property alias dragging: hideSideStageDragArea.dragging
    readonly property real progress: width / panelWidth
    readonly property real handleWidth: units.gu(2)

    width: 0
    shown: false

    Handle {
        id: sideStageDragHandle

        opacity: root.shown ? 1 : 0
        Behavior on opacity { LomiriNumberAnimation {} }

        anchors {
            right: root.left
            // ENH172 - Shorten Side Stage Handle
            // top: root.top
            // ENH172 - End
            bottom: root.bottom
        }
        // ENH172 - Shorten Side Stage Handle
        height: root.availableDesktopAreaHeight
        // ENH172 - End
        // ENH212 - Side-stage focus indicator
        color: root.isFocused ? theme.palette.highlighted.foreground : theme.palette.normal.foreground
        // ENH212 - End
        width: root.handleWidth
        active: hideSideStageDragArea.pressed

        Image {
            z: -1
            anchors.centerIn: parent
            width: hideSideStageDragArea.pressed ? parent.width * 3 : parent.width * 2
            height: parent.height
            source: "graphics/sidestage_handle@20.png"
            Behavior on width { LomiriNumberAnimation {} }
        }
        // ENH019 - Side stage floating mode
        QQC2.RoundButton {
            id: floatButton
            property bool shown: false
            flat: true
            height: units.gu(6)
            width: height
            opacity: shown ? 1 : 0
            visible: opacity > 0
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
            }
            onClicked: root.floating = !root.floating
            onShownChanged: {
                if (shown) floatButtonTimer.restart();
            }
            icon.name: root.floating ? "lock" : "lock-broken"
            icon.width: units.gu(3)
            icon.height: units.gu(3)

            Behavior on opacity { LomiriNumberAnimation {} }
        }
        Timer {
            id: floatButtonTimer
            running: false
            interval: 3000
            onTriggered: floatButton.shown = false
        }
        // ENH019 - End
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0,0,0,0.95)
        visible: showHint || hideAnimation.running
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        width: panelWidth - units.gu(6)
        x: panelWidth/2 - width/2
        spacing: units.gu(3)
        opacity: 0.8
        visible: showHint && !hideAnimation.running

        Icon {
            width: units.gu(30)
            anchors.horizontalCenter: parent.horizontalCenter
            source: "graphics/sidestage_drag.svg"
            color: enabled ? Qt.rgba(1,1,1,1) : Qt.rgba(1,0,0,1)
            keyColor: Qt.rgba(1,1,1,1)
        }

        Label {
            text: i18n.tr("Drag using 3 fingers any application from one window to the other")
            width: parent.width
            wrapMode: Text.WordWrap
            color: enabled ? Qt.rgba(1,1,1,1) : Qt.rgba(1,0,0,1)
        }
    }

    showAnimation: NumberAnimation {
        property: "width"
        to: panelWidth
        duration: LomiriAnimation.BriskDuration
        easing.type: Easing.OutCubic
    }

    hideAnimation: NumberAnimation {
        property: "width"
        to: 0
        duration: LomiriAnimation.BriskDuration
        easing.type: Easing.OutCubic
    }

    DragHandle {
        id: hideSideStageDragArea
        objectName: "hideSideStageDragArea"

        direction: Direction.Rightwards
        enabled: root.shown
        anchors.right: root.left
        width: sideStageDragHandle.width
        height: root.height
        stretch: true

        immediateRecognition: true
        maxTotalDragDistance: panelWidth
        autoCompleteDragThreshold: panelWidth / 2
        // ENH019 - Side stage floating mode
        onPressedChanged: {
            if (pressed) floatButton.shown = true
        }
        // ENH019 - End
    }

    // SideStage mouse event eater
    MouseArea {
        anchors.fill: parent
    }
}
