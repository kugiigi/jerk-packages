/*
 * Copyright (C) 2013-2016 Canonical, Ltd.
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

import QtQuick 2.12
import QtGraphicalEffects 1.12
import Ubuntu.Components 1.3
import Ubuntu.Gestures 0.1
import "../Components"
// ENH032 - Infographics Outer Wilds
import "../OuterWilds"
// ENH032 - End

Showable {
    id: root

    property real dragHandleLeftMargin
    property real launcherOffset
    // ENH034 - Separate wallpaper lockscreen and desktop
    property alias fallbackBackground: greeterBackground.fallbackSource
    property bool useCoverPageWallpaper: false
    // ENH034 - End
    property alias background: greeterBackground.source
    property alias backgroundSourceSize: greeterBackground.sourceSize
    property alias hasCustomBackground: backgroundShade.visible
    property alias backgroundShadeOpacity: backgroundShade.opacity
    property real panelHeight
    property var infographicModel
    property bool draggable: true

    property bool showInfographic: false
    property real infographicsLeftMargin: 0
    property real infographicsTopMargin: 0
    property real infographicsRightMargin: 0
    property real infographicsBottomMargin: 0

    readonly property real showProgress: MathUtils.clamp((width - Math.abs(x + launcherOffset)) / width, 0, 1)

    signal tease()
    signal clicked()
    
    // ENH032 - Infographics Outer Wilds
    property bool enableOW: false
    property bool alternateOW: false
    property bool solarOW: false
    property bool dlcOW: false
    property bool owWallpaper: false
    property bool owAlternateWallpaper: false
    property bool owDLCWallpaper: false
    property bool fastModeOW: false
    signal fastModeToggle
    signal owToggle
    // ENH032 - End
    // ENH064 - Dynamic Cove
    property bool dynamicCoveClock: infographicsLoader.item && infographicsLoader.item.dynamicCoveClock
    // ENH064 - End

    function hideRight() {
        d.forceRightOnNextHideAnimation = true;
        hide();
    }

    function showErrorMessage(msg) {
        d.errorMessage = msg;
        showLabelAnimation.start();
        errorMessageAnimation.start();
    }

    QtObject {
        id: d
        property bool forceRightOnNextHideAnimation: false
        property string errorMessage
    }

    prepareToHide: function () {
        hideTranslation.from = root.x + translation.x
        hideTranslation.to = root.x > 0 || d.forceRightOnNextHideAnimation ? root.width : -root.width;
        d.forceRightOnNextHideAnimation = false;
    }

    // We don't directly bind "x" because that's owned by the DragHandle. So
    // instead, we can get a little extra horizontal push by using transforms.
    transform: Translate { id: translation; x: root.draggable ? launcherOffset : 0 }

    // Eat events elsewhere on the coverpage, except mouse clicks which we pass
    // up (they are used in the NarrowView to hide the cover page)
    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()

        MultiPointTouchArea {
            anchors.fill: parent
            mouseEnabled: false
        }
    }

    Rectangle {
        // In case background fails to load
        id: backgroundBackup
        anchors.fill: parent
        color: "black"
    }

    Wallpaper {
        id: greeterBackground
        objectName: "greeterBackground"
        // ENH032 - Infographics Outer Wilds
        // anchors {
        //     fill: parent
        // }

        states: [
            State {
                name: "normal"
                when: !alternateOWLoader.active

                AnchorChanges {
                    target: greeterBackground
                    anchors.top: root.top
                    anchors.bottom: root.bottom
                    anchors.left: root.left
                    anchors.right: root.right
                }
            }
            , State {
                name: "alternateOW"
                when: alternateOWLoader.active
                AnchorChanges {
                    target: greeterBackground
                    anchors.top: undefined
                    anchors.bottom: undefined
                    anchors.left: undefined
                    anchors.right: undefined
                }
                PropertyChanges {
                    target: greeterBackground
                    x: 0
                    y: root.height - greeterBackground.height
                    height: root.height * 1.2
                    width: root.width * 1.2
                }
            }
        ]
        SequentialAnimation {
            id: bgMoveAnimation

            running: alternateOWLoader.item && alternateOWLoader.item.playing
            paused: alternateOWLoader.item && alternateOWLoader.item.paused
            loops: Animation.Infinite
            PropertyAction {
                target: greeterBackground
                property: "x"
                value: 0
            }
            PropertyAction {
                target: greeterBackground
                property: "y"
                value: -(root.height * 0.2)
            }
            ParallelAnimation {
                UbuntuNumberAnimation {
                    target: greeterBackground
                    property: "opacity"
                    duration: 1000
                    from: 0
                    to: 1
                }
                NumberAnimation {
                    target: greeterBackground
                    property: "x"
                    duration: 30000
                    easing.type: Easing.Linear
                    from: 0
                    to: -(root.width * 0.2)
                }
                NumberAnimation {
                    target: greeterBackground
                    property: "y"
                    duration: 30000
                    easing.type: Easing.Linear
                    from: -(root.height * 0.2)
                    to: 0
                }
                SequentialAnimation {
                    PauseAnimation { duration: 29000 }
                    UbuntuNumberAnimation {
                        target: greeterBackground
                        property: "opacity"
                        duration: 1000
                        from: 1
                        to: 0
                    }
                }
            }
        }
        // ENH032 - End
        // ENH034 - Separate wallpaper lockscreen and desktop
        //source: "file:///home/phablet/Pictures/lomiri_wallpapers/lockscreen"
        // ENH032 - Infographics Outer Wilds
        source: {
            if (root.owWallpaper && root.owAlternateWallpaper) {
                return "../OuterWilds/graphics/loading_screen.png"
            }
            if (root.enableOW && root.dlcOW) {
                return "../OuterWilds/graphics/OWVault.png"
            }
            if (root.enableOW || root.owWallpaper) {
                return "../OuterWilds/graphics/lockscreen.png"
            }
            if (shell.settings.useCustomLockscreen) {
                if (root.useCoverPageWallpaper) {
                    return "file:///home/phablet/Pictures/lomiriplus/coverpage"
                }
                return "file:///home/phablet/Pictures/lomiriplus/lockscreen"
            }

            return fallbackSource
       }
        // ENH032 - End
        // ENH034 - End
    }

    // Darkens wallpaper so that we can read text on it and see infographic
    Rectangle {
        id: backgroundShade
        objectName: "backgroundShade"
        anchors.fill: parent
        color: "black"
        visible: false
    }

    // ENH032 - Infographics Outer Wilds
    Loader {
        id: solarSystemLoader
        property bool fastMode: false

        active: root.enableOW && root.solarOW
        asynchronous: true
        anchors.fill: infographicsArea
        sourceComponent: solarSystemComp
    }
    Component {
        id: solarSystemComp
        SolarSystem {
            id: solarSystem
            fastMode: root.fastModeOW
        }
    }
    MouseArea {
        anchors.fill: infographicsArea
        enabled: solarSystemLoader.item ? true : false

        //onDoubleClicked: {
        onPressAndHold: {
            root.fastModeToggle()
            solarSystemLoader.active = false
            solarSystemLoader.active = Qt.binding( function() { return root.enableOW } )
        }
    }
    Loader {
        id: alternateOWLoader

        active: root.enableOW && root.alternateOW
        asynchronous: true
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        height: parent.height > parent.width ? Math.min(parent.height / 2, parent.width) : Math.min(parent.width / 2, parent.height - root.panelHeight)
        width: height
        sourceComponent: mainMenuComponent
    }
    Component {
        id: mainMenuComponent
        OWMainMenu {
            id: mainMenu
        }
    }

    Loader {
        id: dlcOWLoader

        active: root.enableOW && root.dlcOW
        asynchronous: true
        anchors.fill: greeterBackground
        sourceComponent: dlcComponent
    }
    Component {
        id: dlcComponent
        OWVaultFire {}
    }

    // ENH032 - End

    Item {
        id: infographicsArea

        anchors {
            leftMargin: root.infographicsLeftMargin
            topMargin: root.infographicsTopMargin ? root.infographicsTopMargin : root.panelHeight
            rightMargin: root.infographicsRightMargin
            bottomMargin: root.infographicsBottomMargin
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
    }

    Loader {
        id: infographicsLoader
        objectName: "infographicsLoader"
        active: root.showInfographic && infographicsArea.width > units.gu(32)
        anchors.fill: infographicsArea
        // ENH064 - Dynamic Cove
        z: dragHandle.z + 1
        // ENH064 - End

        sourceComponent:Infographics {
            id: infographics
            objectName: "infographics"
            model: root.infographicModel
            // ENH032 - Infographics Outer Wilds
            // clip: true // clip large data bubbles
            enableOW: false
            showInfographics: shell.settings.showInfographics
            // ENH032 - End
        }
        
        // ENH032 - Infographics Outer Wilds
        Binding {
            target: infographicsLoader.item
            property: "enableOW"
            value: root.enableOW
        }
        // ENH032 - End
    }

    Label {
        id: swipeHint
        objectName: "swipeHint"
        property real baseOpacity: 0.5
        opacity: 0.0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(5)
        text: "《    " + (d.errorMessage ? d.errorMessage : i18n.tr("Unlock")) + "    》"
        color: "white"
        font.weight: Font.Light

        readonly property var opacityAnimation: showLabelAnimation // for testing

        SequentialAnimation on opacity {
            id: showLabelAnimation
            running: false
            loops: 2

            StandardAnimation {
                from: 0.0
                to: swipeHint.baseOpacity
                duration: UbuntuAnimation.SleepyDuration
            }
            PauseAnimation { duration: UbuntuAnimation.BriskDuration }
            StandardAnimation {
                from: swipeHint.baseOpacity
                to: 0.0
                duration: UbuntuAnimation.SleepyDuration
            }

            onRunningChanged: {
                if (!running)
                    d.errorMessage = "";
            }
        }
    }

    WrongPasswordAnimation {
        id: errorMessageAnimation
        objectName: "errorMessageAnimation"
        target: swipeHint
    }

    DragHandle {
        id: dragHandle
        objectName: "coverPageDragHandle"
        anchors.fill: parent
        anchors.leftMargin: root.dragHandleLeftMargin
        enabled: root.draggable
        direction: Direction.Horizontal

        onPressedChanged: {
            if (pressed) {
                root.tease();
                showLabelAnimation.start();
            }
        }
    }

    // right side shadow
    Image {
        anchors.left: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        fillMode: Image.Tile
        source: "../graphics/dropshadow_right.png"
    }

    // left side shadow
    Image {
        anchors.right: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        fillMode: Image.Tile
        source: "../graphics/dropshadow_left.png"
    }

    Binding {
        id: positionLock

        property bool enabled: false
        onEnabledChanged: {
            if (enabled === __enabled) {
                return;
            }

            if (enabled) {
                if (root.x > 0) {
                    value = Qt.binding(function() { return root.width; })
                } else {
                    value = Qt.binding(function() { return -root.width; })
                }
            }

            __enabled = enabled;
        }

        property bool __enabled: false

        target: root
        when: __enabled
        property: "x"
    }

    hideAnimation: SequentialAnimation {
        id: hideAnimation
        objectName: "hideAnimation"
        property var target // unused, here to silence Showable warning
        StandardAnimation {
            id: hideTranslation
            property: "x"
            target: root
        }
        PropertyAction { target: root; property: "visible"; value: false }
        PropertyAction { target: positionLock; property: "enabled"; value: true }
    }

    showAnimation: SequentialAnimation {
        id: showAnimation
        objectName: "showAnimation"
        property var target // unused, here to silence Showable warning
        PropertyAction { target: root; property: "visible"; value: true }
        PropertyAction { target: positionLock; property: "enabled"; value: false }
        StandardAnimation {
            property: "x"
            target: root
            to: 0
            duration: UbuntuAnimation.FastDuration
        }
    }

    // ENH046 - Lomiri Plus Settings
    Rectangle {
        color: theme.palette.normal.foreground
        radius: width / 2
        height: units.gu(6)
        width: height
        visible: opacity > 0
        opacity: bottomSwipeArea.dragging && bottomSwipeArea.longSwipe ? 1 : 0
        Behavior on opacity { UbuntuNumberAnimation {} }
        anchors {
            bottom: bottomSwipeArea.top
            bottomMargin: bottomSwipeArea.longSwipeThreshold + height + units.gu(2)
            horizontalCenter: bottomSwipeArea.horizontalCenter
        }
        Icon {
            anchors.centerIn: parent
            width: units.gu(3)
            height: width
            name: "settings"
            color: theme.palette.normal.foregroundText
        }
    }
    SwipeArea {
        id: bottomSwipeArea
        readonly property real longSwipeThreshold: units.gu(20)
        readonly property real shortSwipeThreshold: units.gu(5)
        readonly property bool longSwipe: distance > longSwipeThreshold && (!shell.settings.onlyShowLomiriSettingsWhenUnlocked || !shell.showingGreeter)
        readonly property bool shortSwipe: distance > shortSwipeThreshold

        direction: SwipeArea.Upwards
        height: units.gu(2)
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        onLongSwipeChanged: {
            if (longSwipe) {
                shell.haptics.playSubtle()
            }
        }
        onShortSwipeChanged: {
            if (shortSwipe) {
                shell.haptics.playSubtle()
            }
        }
        onDraggingChanged: {
            if (!dragging) {
                if (longSwipe) {
                    shell.showSettings()
                    shell.haptics.play()
                } else if (shortSwipe) {
                    if (infographicsLoader.item) {
                        shell.settings.showInfographics = !shell.settings.showInfographics
                        shell.haptics.play()
                    }
                }
            }
        }
    }
    // ENH046 - End
}
