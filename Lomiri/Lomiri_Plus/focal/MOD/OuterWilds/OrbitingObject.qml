
// ENH032 - Infographics Outer Wilds
import QtQuick 2.12
import QtGraphicalEffects 1.12
import Lomiri.Components 1.3

Item {
    id: orbit

    readonly property int fastModeMult: 300
    readonly property int normalModeMult: 1000
    property bool hasQuantumMoon: false
    property int quantumMoonLoc: 1

    property bool fastMode: false
    
    property int startVisibility: 0
    property int endVisibility: 22
    readonly property int visibilityDuration: endVisibility - startVisibility
    property int zSystem: 1

    visible: loopTimer.currentTimer >= startVisibility && loopTimer.currentTimer <= endVisibility
    
    // Orbit properties
    property Item bodyToOrbit
    property real horizontalOrbitOffset: 0
    property real verticalOrbitOffset: 0
    property bool displayOrbitLine: false
    property int orbitDuration: 120 // in seconds
    property int orbitDurationOverride: 0 // custom calculation of duration
    property int orbitDirection: 0 // 0 = Clockwise, 1= Counterclockwise
    property int orbitTilt: 4 // the higher the value, the higher the tilt
    property int startingPosition: 0 // 0 = Right
                                     // 1 = Left
                                     // 2 = Top
                                     // 3 = Bottom
     readonly property var startPosValues: orbitDirection == 0 ? [
        { "angle": 0, "sizes": [1.5, 1 ,0.5, 1] }
        ,{ "angle": 180, "sizes": [0.5, 1 , 1.5, 1] }
        ,{ "angle": 270, "sizes": [1, 0.5 , 1, 1.5] }
        ,{ "angle": 90, "sizes": [1, 1.5 , 1, 0.5] }
     ]
     : [
        { "angle": 0, "sizes": [0.5, 1 ,1.5, 1] }
        ,{ "angle": 180, "sizes": [1.5, 1 , 0.5, 1] }
        ,{ "angle": 270, "sizes": [1, 1.5 , 1, 0.5] }
        ,{ "angle": 90, "sizes": [1, 0.5 , 1, 1.5] }
     ]
     
     readonly property var currentPosValues: startingPosition > -1 ? startPosValues[startingPosition] : []

    // Orbiting objects properties
    property Item orbitingObject: customDelegateUsed ? customObject : object
    property Component customDelegate: null
    property alias customObject: delegateLoader.item
    readonly property bool customDelegateUsed: customDelegate ? true : false
    property alias source: object.source
    property real objectWidth: units.gu(2)
    property int rotationDuration: 0 // if rotate on its own axis
    property int rotationDurationOverride: 0 // custom calculation of duration
    property int rotationDirection: 0 // 0 = Clockwise, 1= Counterclockwise
    
    property alias pathRotation: orbitPathAnim.endRotation
    property alias pathOrientation: orbitPathAnim.orientation
    property alias pathEntryDuration: orbitPathAnim.orientationEntryDuration
    property alias pathExitDuration: orbitPathAnim.orientationExitDuration
    
    
    anchors {
        horizontalCenter: bodyToOrbit.horizontalCenter
        verticalCenter: bodyToOrbit.verticalCenter
        horizontalCenterOffset: horizontalOrbitOffset
        verticalCenterOffset: verticalOrbitOffset
    }

    z: orbitingObject ? orbitingObject.width < objectWidth ? -zSystem
                                            : zSystem
                : 0
    height: width
    
    onVisibleChanged: {
        if (visible) {
            restart()
        } else {
            stop()
        }
    }
    
    function restart() {
        orbitPathAnim.restart()
        sizeAnim.restart()
        if (orbit.rotationDuration > 0) {
            rotateAnim.restart()
        }
    }
    
    function stop() {
        orbitPathAnim.stop()
        sizeAnim.stop()
        if (orbit.rotationDuration > 0) {
            rotateAnim.stop()
        }
        orbitingObject.width = orbit.objectWidth * (orbit.currentPosValues ? orbit.currentPosValues.sizes[3] : 1)
        orbitingObject.rotation = 0
    }
        
    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        visible: orbit.displayOrbitLine

        onPaint: {
            var context = canvas.getContext("2d")
            context.clearRect(0, 0, width, height)
            context.strokeStyle = "white"
            context.path = orbitPathAnim.path
            context.stroke()
        }
    }
    
    SequentialAnimation {
        id: sizeAnim
        running: true
        loops: Animation.Infinite

        NumberAnimation {
            target: orbitingObject
            property: "width"
            to: orbit.objectWidth * orbit.currentPosValues.sizes[0]
            duration: orbitPathAnim.duration / 4
        }
        NumberAnimation {
            target: orbitingObject
            property: "width"
            to: orbit.objectWidth * orbit.currentPosValues.sizes[1]
            duration: orbitPathAnim.duration / 4
        }
        NumberAnimation {
            target: orbitingObject
            property: "width"
            to: orbit.objectWidth * orbit.currentPosValues.sizes[2]
            duration: orbitPathAnim.duration / 4
        }
        NumberAnimation {
            target: orbitingObject
            property: "width"
            to: orbit.objectWidth * orbit.currentPosValues.sizes[3]
            duration: orbitPathAnim.duration / 4
        }
    }
    
    PathAnimation {
        id: orbitPathAnim
        running: true
        target: orbit.orbitingObject
        loops: Animation.Infinite
        duration: orbit.orbitDurationOverride > 0 ? orbit.orbitDurationOverride
                                : orbit.orbitDuration  * (orbit.fastMode ? orbit.fastModeMult : orbit.normalModeMult)
        anchorPoint: Qt.point(orbitingObject.width / 2, orbitingObject.height / 2)
        path: Path {
            startX: 0
            startY: 0

            PathAngleArc {
                startAngle: orbit.startPosValues[orbit.startingPosition].angle
                sweepAngle: orbit.orbitDirection == 0 ? 360 : -360
                centerX: orbit.width / 2
                centerY: orbit.height / 2
                radiusX: orbit.width / 2; radiusY: orbit.height / orbit.orbitTilt
            }
        }
    }
    
    
    Loader {
        id: delegateLoader
        sourceComponent: orbit.customDelegate
        active: orbit.customDelegate ? true : false
        asynchronous: true
        width: orbit.objectWidth * orbit.currentPosValues.sizes[3]
        height: width
        onLoaded: {
            orbitPathAnim.target = item
            orbitPathAnim.restart()
            sizeAnim.restart()
        }
    }

    Image {
        id: object
        
        asynchronous: true
        width: orbit.objectWidth * orbit.currentPosValues.sizes[3]
        height: width
        fillMode: Image.PreserveAspectFit

        Rectangle {
            id: quantumMoon
            property real orbitMargin: units.gu(1.5)

            visible: orbit.hasQuantumMoon
            color: "#5b5e6a"
            radius: width / 2
            width: units.gu(0.8)
            height: width
            states: [
                State {
                    when: orbit.quantumMoonLoc == 1
                    AnchorChanges { target: quantumMoon; anchors.left: object.right; }
                    PropertyChanges { target: quantumMoon; anchors.leftMargin: quantumMoon.orbitMargin }
                }
                , State {
                    when: orbit.quantumMoonLoc == 2
                    AnchorChanges { target: quantumMoon; anchors.right: object.left; }
                    PropertyChanges { target: quantumMoon; anchors.rightMargin: quantumMoon.orbitMargin }
                }
                , State {
                    when: orbit.quantumMoonLoc == 3
                    AnchorChanges { target: quantumMoon; anchors.top: object.bottom; }
                    PropertyChanges { target: quantumMoon; anchors.topMargin: quantumMoon.orbitMargin }
                }
            ]
        }
    }
    
    RotationAnimation {
        id: rotateAnim

        running: true
        loops: Animation.Infinite
        target: orbitingObject
        property: "rotation"
        from: orbit.rotationDirection == 0 ? 0 : 360
        to: orbit.rotationDirection == 0 ? 360 : 0
        duration: orbit.rotationDurationOverride > 0 ? orbit.rotationDurationOverride
                                    : orbit.rotationDuration  * (orbit.fastMode ? orbit.fastModeMult : orbit.normalModeMult)
    }
}
// ENH032 - End
