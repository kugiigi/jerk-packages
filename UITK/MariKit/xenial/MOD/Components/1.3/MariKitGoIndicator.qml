import QtQuick 2.9
import Ubuntu.Components 1.3
import QtGraphicalEffects 1.12

Item {
    id: goIndicator
    
    property real defaultWidth: units.gu(5)
    property real defaultScale: 1
    property real maxScale: 2

    property alias iconName: iconItem.name
    property real swipeProgress
    property bool enabled: true
    property bool heldState: false
    property color defaultColor: theme.palette.normal.foreground
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

    Behavior on scale {
        UbuntuNumberAnimation { duration: UbuntuAnimation.BriskDuration}
    }

    Behavior on opacity {
        UbuntuNumberAnimation {
            duration: UbuntuAnimation.BriskDuration
        }
    }

    DropShadow {

        readonly property color shadowColor: goIndicator.shadowColor
        
        anchors.fill: source
        cached: true
        horizontalOffset: 3
        verticalOffset: 3
        radius: 8.0
        samples: 16
        color: Qt.hsla(shadowColor.hslHue, shadowColor.hslSaturation, shadowColor.hslLightness, 0.5)
        source: bg
    }

    Rectangle {
        id: bg
        
        anchors.fill: parent
        radius: width / 2
        color: heldState ? heldColor : defaultColor

        Behavior on color {
            ColorAnimation {
                duration: UbuntuAnimation.FastDuration
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
