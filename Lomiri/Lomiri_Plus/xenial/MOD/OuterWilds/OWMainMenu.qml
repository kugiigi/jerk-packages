// ENH032 - Infographics Outer Wilds
import QtQuick 2.12
import Ubuntu.Components 1.3
import Powerd 0.1

Item {
    readonly property bool nearEnd: gif.currentFrame == gif.frameCount - 10 //1 second before end in 10 fps
    readonly property alias currentFrame: gif.currentFrame
    readonly property alias frameCount: gif.frameCount
    readonly property alias playing: gif.playing
    readonly property alias paused: gif.paused

    AnimatedImage {
        id: gif
        source: "graphics/OWMainMenu.gif"
        cache: false
        asynchronous: true
        opacity: 0
        anchors.fill: parent
        paused: Powerd.status === Powerd.Off // try to reduce battery drain?
    }
    Component.onCompleted: showAnimation.start()

    onNearEndChanged: {
        if (nearEnd) {
            hideAnimation.restart()
        }
    }
    
    UbuntuNumberAnimation {
        id: showAnimation
        target: gif
        property: "opacity"
        to: 1
        duration: 1000
    }
    UbuntuNumberAnimation {
        id: hideAnimation
        target: gif
        property: "opacity"
        to: 0
        duration: 1000
        onStopped: showAnimation.restart()
    }
}
// ENH032 - End
