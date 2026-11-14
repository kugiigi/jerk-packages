
// ENH032 - Infographics Outer Wilds
import QtQuick 2.12
import QtGraphicalEffects 1.12
import Lomiri.Components 1.3

Rectangle {
    id: orbit

    readonly property int fastModeMult: 300
    readonly property int normalModeMult: 1000

    property bool fastMode: false
    
    property int startVisibility: 0
    property int endVisibility: 21
    readonly property int visibilityDuration: endVisibility - startVisibility

    visible: loopTimer.currentTimer >= startVisibility && loopTimer.currentTimer <= endVisibility
    
    // Orbit properties
    property Item bodyToOrbit
    property real horizontalOrbitOffset: 0
    property real verticalOrbitOffset: 0
    property bool displayOrbitLine: false
    property int orbitDuration: 120 // in seconds
    property int orbitDirection: 0 // 0 = Clockwise, 1= Counterclockwise
    property int orbitTilt: -140

    // Orbiting objects properties
    property alias source: object.source
    property alias objectWidth: object.width
    property int rotationDuration: 0 // if rotate on its own axis
    property int rotationDirection: 0 // 0 = Clockwise, 1= Counterclockwise
    

    z: rotation >= 180 ? bodyToOrbit.z - 1 : bodyToOrbit.z + 1
    color: "transparent"
    border {
        width: displayOrbitLine ? units.gu(0.1) : 0
        color: "white"
    }
    radius: width / 2
    height: width
    anchors {
        centerIn: bodyToOrbit
//~         horizontalCenter: bodyToOrbit.horizontalCenter
//~         verticalCenter: bodyToOrbit.verticalCenter
        horizontalCenterOffset: horizontalOrbitOffset
        verticalCenterOffset: verticalOrbitOffset
    }
    onVisibleChanged: {
        if (visible) {
            orbitAnim.restart()
            if (orbit.rotationDuration > 0) {
                rotateAnim.restart()
            }
        } else {
            orbitAnim.stop()
            if (orbit.rotationDuration > 0) {
                rotateAnim.stop()
            }
        }
    }
    
    transform: Rotation {
        angle: orbit.orbitTilt
        axis {
            x: 1
            y: 0
            z: 0
        }
        origin {
            x: orbit.width / 2
            y: orbit.height / 2
        }
    }
    
    RotationAnimation {
        id: orbitAnim

        alwaysRunToEnd: true
        running: true
        loops: Animation.Infinite
        target: orbit
        property: "rotation"
        from: orbit.orbitDirection == 0 ? 360 : 0
        to: orbit.orbitDirection == 0 ? 0 : 360
        duration: orbit.orbitDuration  * (orbit.fastMode ? orbit.fastModeMult : orbit.normalModeMult)
    }
    
    Image {
        id: object

        asynchronous: true
        cache: true
        height: width
        fillMode: Image.PreserveAspectFit
        
        anchors {
            bottom: orbit.top
//~             verticalCenter: orbit.bottom
        }
        
        RotationAnimation {
            id: rotateAnim

            alwaysRunToEnd: true
            running: true
            loops: Animation.Infinite
            target: object
            property: "rotation"
            from: orbit.rotationDirection == 0 ? 360 : 0
            to: orbit.rotationDirection == 0 ? 0 : 360
            duration: orbit.rotationDuration  * (orbit.fastMode ? orbit.fastModeMult : orbit.normalModeMult)
        }
    }
}

// ENH032 - End
