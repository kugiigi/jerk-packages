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
    property alias sourceSize: gif.sourceSize

    AnimatedImage {
        id: gif
        source: "graphics/OWVaultFire.gif"
        cache: false
        fillMode: Image.PreserveAspectCrop
        autoTransform: true
        asynchronous: true
        anchors.fill: parent
        paused: Powerd.status === Powerd.Off // try to reduce battery drain?
    }
}
// ENH032 - End
