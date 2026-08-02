/*
 * Copyright (C) 2014-2016 Canonical Ltd.
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
import QtQuick.Layouts 1.1
import Lomiri.Components 1.3
import QtMir.Application 0.1
import "../Components"
import "../Components/PanelState"
import "../ApplicationMenus"
// ENH180 - Match window titlebar with app
import "Spread"
// ENH180 - End

MouseArea {
    id: root

    property alias closeButtonVisible: buttons.closeButtonShown
    property alias title: titleLabel.text
    property alias maximizeButtonShown: buttons.maximizeButtonShown
    property alias minimizeButtonVisible: buttons.minimizeButtonVisible
    property bool active: false
    property alias overlayShown: buttons.overlayShown
    property var menu: undefined
    property bool enableMenus: true
    property bool windowMoving: false
    property alias windowControlButtonsVisible: buttons.visible
    property PanelState panelState
    // ENH180 - Match window titlebar with app
    property var blurSource: null
    property alias blurUpdates: bgBlur.surfaceUpdates
    // ENH180 - End

    readonly property real buttonsWidth: buttons.width + row.spacing

    acceptedButtons: Qt.AllButtons // prevent leaking unhandled mouse events
    hoverEnabled: true

    signal closeClicked()
    signal minimizeClicked()
    signal maximizeClicked()
    signal maximizeHorizontallyClicked()
    signal maximizeVerticallyClicked()

    signal pressedChangedEx(bool pressed, var pressedButtons, real mouseX, real mouseY)

    onDoubleClicked: {
        if (mouse.button == Qt.LeftButton) {
            root.maximizeClicked();
        }
    }

    // do not let unhandled wheel event pass thru the decoration
    onWheel: wheel.accepted = true;

    QtObject {
        id: priv
        property var menuBar: menuBarLoader.item

        property bool shouldShowMenus: root.enableMenus &&
                                       menuBar &&
                                       menuBar.valid &&
                                       (menuBar.showRequested || root.containsMouse)
    }
    // ENH180 - Match window titlebar with app
    /*
    Rectangle {
        id: background
        anchors.fill: parent
        radius: units.gu(.5)
        color: theme.palette.normal.background
    }

    Rectangle {
        anchors {
            bottom: background.bottom
            left: parent.left
            right: parent.right
        }
        height: background.radius
        color: theme.palette.normal.background
    }
    */
    Rectangle {
        color: "transparent"
        radius: background.radius
        visible: bgBlur.sourceItem !== null
        anchors.fill: bgItem

        BackgroundBlur {
            id: bgBlur
            anchors.fill: parent
            sourceItem: shell.settings.enableTitlebarMatchAppTopColor ? root.blurSource : null
            blurRect: shell.settings.titlebarMatchAppBehavior === 0 ? Qt.rect(units.dp(2), units.gu(1), units.dp(1), units.dp(1))
                                : Qt.rect(0, 0, width, units.dp(1))
            occluding: false 
        }

        RoundedCornersMask {
            id: roundedCornerEffect
            sourceItem: shell.settings.retainRoundedWindowWhileMatching ? bgBlur : null
            cornerRadius: units.gu(6)
        }
    }

    Rectangle {
        id: bgItem

        color: "transparent"
        radius: background.radius
        opacity: bgBlur.visible ? 0.0 : 1
        anchors.fill: parent
        // Hide a bit of the rounded corners in Gnome apps
        anchors.bottomMargin: bgBlur.visible ? units.gu(-2) : 0
        layer.enabled: true

        Rectangle {
            id: background
            anchors.fill: parent
            // No rounded corners when matching since we can't clip the background blur
            radius: bgBlur.visible ? 0 : units.gu(.5)
            color: theme.palette.normal.background
        }

        Rectangle {
            anchors {
                bottom: background.bottom
                left: parent.left
                right: parent.right
            }
            height: background.radius
            color: theme.palette.normal.background
        }
    }
    // ENH180 - End

    RowLayout {
        id: row
        anchors {
            fill: parent
            // ENH161 - Bigger window buttons when resize UI displayed
            // leftMargin: overlayShown ? units.gu(5) : units.gu(1)
            leftMargin: buttons.enlargeButtons ? units.gu(1) : overlayShown ? units.gu(5) : units.gu(1)
            // ENH161 - End
            rightMargin: units.gu(1)
        }
        Behavior on anchors.leftMargin {
            LomiriNumberAnimation {}
        }

        spacing: units.gu(3)

        WindowControlButtons {
            // ENH161 - Bigger window buttons when resize UI displayed
            // Layout.fillHeight: true
            Layout.fillHeight: enlargeButtonEnabled ? false : true
            Layout.preferredHeight: overlayShown ? parent.height * 1.3 : parent.height - units.gu(1)
            Layout.alignment: Qt.AlignVCenter
            Behavior on Layout.preferredHeight {
                LomiriNumberAnimation {}
            }
            // ENH161 - End
            Layout.fillWidth: false
            // ENH161 - Bigger window buttons when resize UI displayed
            // Layout.topMargin: units.gu(0.5)
            Layout.topMargin: enlargeButtons ? -units.gu(11) - units.gu(0.5) : units.gu(0.5)
            Behavior on Layout.topMargin {
                LomiriNumberAnimation {}
            }
            // ENH161 - End
            Layout.bottomMargin: units.gu(0.5)

            id: buttons
            active: root.active
            // ENH180 - Match window titlebar with app
            forceHighlightButtons: bgBlur.visible
            // ENH180 - End
            onCloseClicked: root.closeClicked();
            onMinimizeClicked: root.minimizeClicked();
            onMaximizeClicked: root.maximizeClicked();
            onMaximizeHorizontallyClicked: root.maximizeHorizontallyClicked();
            onMaximizeVerticallyClicked: root.maximizeVerticallyClicked();
        }

        Item {
            Layout.preferredHeight: parent.height
            Layout.fillWidth: true

            // ENH180 - Match window titlebar with app
            /*
            Rectangle {
                anchors {
                    left: titleLabel.left
                    verticalCenter: titleLabel.verticalCenter
                    leftMargin: units.gu(-0.5)
                }
                height: titleLabel.contentHeight + units.gu(0.1)
                width: titleLabel.contentWidth + units.gu(1)
                radius: units.gu(1)
                opacity: 0.3
                color: "black"
            }
            */
            // ENH180 - End

            Label {
                id: titleLabel
                objectName: "windowDecorationTitle"
                // ENH180 - Match window titlebar with app
                // color: root.active ? "white" : LomiriColors.slate
                color: bgBlur.visible ? LomiriColors.slate : root.active ? "white" : LomiriColors.slate
                // ENH180 - End
                height: parent.height
                width: parent.width
                verticalAlignment: Text.AlignVCenter
                fontSize: "medium"
                // ENH180 - Match window titlebar with app
                // font.weight: root.active ? Font.Light : Font.Medium
                font.weight: bgBlur.visible ? root.active ? Font.Medium : Font.Light
                                            : root.active ? Font.Light : Font.Medium
                // ENH180 - End
                elide: Text.ElideRight
                opacity: overlayShown || menuBarLoader.visible ? 0 : 1
                visible: opacity != 0
                Behavior on opacity { LomiriNumberAnimation {} }
            }

            Loader {
                id: menuBarLoader
                objectName: "menuBarLoader"
                anchors.bottom: parent.bottom
                height: parent.height
                width: parent.width
                active: root.menu !== undefined

                sourceComponent: MenuBar {
                    id: menuBar
                    height: menuBarLoader.height
                    enableKeyFilter: valid && root.active && root.enableMenus
                    lomiriMenuModel: root.menu
                    windowMoving: root.windowMoving
                    panelState: root.panelState

                    onPressed: root.onPressed(mouse)
                    onPressedChangedEx: root.pressedChangedEx(pressed, pressedButtons, mouseX, mouseY)
                    onPositionChanged: root.onPositionChanged(mouse)
                    onReleased: root.onReleased(mouse)
                    onDoubleClicked: root.onDoubleClicked(mouse)
                }

                opacity: (!overlayShown && priv.shouldShowMenus) || (active && priv.menuBar.valid && root.windowMoving) ? 1 : 0
                visible: opacity == 1
                Behavior on opacity { LomiriNumberAnimation {} }
            }
        }
    }
}
