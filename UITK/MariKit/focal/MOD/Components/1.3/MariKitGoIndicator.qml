import QtQuick 2.9
import Lomiri.Components 1.3
// import QtGraphicalEffects 1.12

Item {
    id: goIndicator

     readonly property bool readyToTrigger: scale >= maxScale
    property real defaultWidth: units.gu(5)
    property real defaultScale: 1
    property real maxScale: 1.5
    property real pulseScale: 2

    property string iconName
    property real swipeProgress
    property bool enabled: true
    property bool heldState: false
    property color defaultColor: theme.palette.normal.foreground
    property color highlightedColor: theme.palette.highlighted.foreground
    property color iconColor: theme.palette.normal.foregroundText
    property color shadowColor: theme.palette.normal.foregroundText
    property color heldColor: theme.palette.normal.activity

    visible: opacity > 0
    opacity: 0
    width: defaultWidth
    height: width
    scale: defaultScale

    function show() {
        opacity = enabled ? 1 : 0.2
        scale = Qt.binding( function() { return defaultScale + ((maxScale - defaultScale) * swipeProgress) } )
    }

    function hide() {
        opacity = 0
        scale = defaultScale
        heldState = false
    }

    function delayedHide() {
        scale = pulseScale
        delayedHideTimer.restart()
    }
    onVisibleChanged: {
        // Update icon if it changed
        if (!visible && iconItem.name !== iconName) {
            iconItem.name = iconName
        }
    }
    onIconNameChanged: {
        if (!visible) {
            // Delay changing of icon to after it's hidden
            iconItem.name = iconName
        }
    }
    Timer {
        id: delayedHideTimer
        running: false
        interval: 400
        onTriggered: goIndicator.hide()
    }

    Behavior on scale {
        LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration}
    }

    Behavior on opacity {
        LomiriNumberAnimation {
            duration: LomiriAnimation.BriskDuration
        }
    }

    Rectangle {
        id: bg
        
        anchors.fill: parent
        radius: width / 2
        color: heldState ? heldColor : readyToTrigger ? highlightedColor : defaultColor
        border {
            width: units.dp(2)
            color: goIndicator.readyToTrigger ? theme.palette.normal.activity : theme.palette.normal.base
        }

        Behavior on border.color {
            ColorAnimation {
                duration: LomiriAnimation.FastDuration
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: LomiriAnimation.FastDuration
            }
        }
    }

    Icon {
        id: iconItem

        anchors.centerIn: parent
        height: parent.height * 0.5
        width: height
        color: goIndicator.iconColor
    }
}
