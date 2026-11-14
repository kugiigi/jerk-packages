 // ENH032 - Infographics Outer Wilds
import QtQuick 2.12
import QtQuick.Particles 2.0
import QtGraphicalEffects 1.12
import Ubuntu.Components 1.3
    
Item {
    id: solarSystem

    property bool showCounterLabel: false
    property bool fastMode: false
    
    property int quamtumMoonLocation: solarSystem.randomize(1, 6)
    
    function randomize(start, end) {
        return Math.floor((Math.random() * end) + start)
    }
    
    function randomInRange(min, max) { //for floating
        return Math.random() < 0.5 ? ((1-Math.random()) * (max-min) + min) : (Math.random() * (max-min) + min);
    }
    
    Timer {
        running: true
        repeat: true
        interval: loopTimer.interval * (solarSystem.fastMode ? 5 : 2)
        onTriggered: solarSystem.quamtumMoonLocation = solarSystem.randomize(1, 6)
    }

    Timer {
        id: loopTimer

        readonly property int timerLimit: 21
        property bool fastMode: solarSystem.fastMode
        property int currentTimer: 0

        running: true
        repeat: true
        interval: solarSystem.visible ? fastMode ? 1000
                                                : 60000
                                : 0

        function reset() {
            brittlePiecesModel.clear()
            currentTimer = 0
            restart()
        }

        onTriggered: {
            if (currentTimer == timerLimit) {
                stop()
                supernovaDelay.restart()
            } else {
                currentTimer += 1
            }
        }
    }
    
    
    Timer {
        id: supernovaDelay
        running: false
        interval: 2000
        onTriggered: supernova.restart()
    }

    Rectangle {
        id: sun
        property real divisor: minDivisor
        readonly property real maxDivisor: units.gu(20)
        readonly property real minDivisor: units.gu(10)
        readonly property real supernovaDivisor: units.gu(5)
        readonly property real lateSupernovaDivisor: units.gu(0.2)
        readonly property real explisionJerkDivisor: units.gu(5)
        readonly property real explosionDivisor: units.gu(150)
        readonly property real endExplosionDivisor: units.gu(250)
        
        readonly property color fromColor: "#fcbd30"
        readonly property color toColor: "#fc1f02"
        readonly property color collapseColor: "#fcfe40"
        readonly property color lateCollapseColor: "white"
        readonly property color explodeColor: "#9bf3ff"
        readonly property color endColor: "white"

        visible: false
        anchors.centerIn: parent
        width: divisor
        height: width
        color: fromColor
        radius: width / 2

        function reset() {
            color = fromColor
            colorChange.restart()
            divisor = minDivisor
            sunGlow.reset()
            divisorChange.restart()
        }
        
        PropertyAnimation on divisor {
            id: divisorChange
            to: sun.maxDivisor
            duration: loopTimer.timerLimit * (loopTimer.fastMode ? 1000 : 60000)
        }
        
        ColorAnimation on color {
            id: colorChange
            to: sun.toColor
            duration: loopTimer.timerLimit * (loopTimer.fastMode ? 1000 : 60000)
        }
        
        Timer {
            id: restartDelay
            interval: 1500
            onTriggered: {
                loopTimer.reset()
                sun.reset()
            }
        }
        
        SequentialAnimation {
            id: supernova
            running: false

            readonly property int earlySupernovaDuration: 5000
            readonly property int lateSupernovaDuration: 2500
            readonly property int explosionDuration: 8000
            readonly property int endExplosionDuration: 3000

            onFinished: {
                restartDelay.restart()
            }
            
            // Collapse
            ParallelAnimation {
                ColorAnimation {
                    target: sun
                    property: "color"
                    to: sun.collapseColor
                    duration: supernova.earlySupernovaDuration
                }
                
                NumberAnimation {
                    target: sun
                    property: "divisor"
                    to: sun.supernovaDivisor
                    duration: supernova.earlySupernovaDuration
                }
            }
            
            // Late collapse transitioning to explosion
            ParallelAnimation {
                ColorAnimation {
                    target: sun
                    property: "color"
                    to: sun.lateCollapseColor
                    duration: supernova.lateSupernovaDuration
                }
                
                NumberAnimation {
                    target: sun
                    property: "divisor"
                    to: sun.lateSupernovaDivisor
                    duration: supernova.lateSupernovaDuration
                }
                
                NumberAnimation {
                    target: sunGlow
                    property: "glowRadius"
                    to: sunGlow.supernovaGlowRadius
                    duration: supernova.lateSupernovaDuration
                }
            }
            
            // Delay explosion
            PauseAnimation { duration: 1000 }
            
            // About to explode
            ColorAnimation {
                target: sun
                property: "color"
                to: sun.explodeColor
                duration: 300
            }
            
            // Explosion jerk
            PropertyAction { target: particleSystem; property: "run"; value: true }
            PropertyAction { target: sunGlow; property: "z"; value: 100 }
            ParallelAnimation {
                NumberAnimation {
                    target: sunGlow
                    property: "spread"
                    to: 0.4
                    duration: supernova.explosionDuration
                }
                NumberAnimation {
                    target: sun
                    property: "divisor"
                    to: sun.explosionDivisor
                    duration: supernova.explosionDuration
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: sunGlow
                    property: "glowRadius"
                    to: sunGlow.defaultGlowRadius
                    duration: 1000
                }
            }
            
            // Explosion reaches Hatchling
            ParallelAnimation {
                ColorAnimation {
                    target: sun
                    property: "color"
                    to: sun.endColor
                    duration: supernova.endExplosionDuration
                }
                NumberAnimation {
                    target: sun
                    property: "divisor"
                    to: sun.endExplosionDivisor
                    duration: supernova.endExplosionDuration
                    easing.type: Easing.InCubic
                }
            }
            PropertyAction { target: particleSystem; property: "run"; value: false }
            
        }
    }
    
    // Supernova explosion particles
    ParticleSystem {
        id: particleSystem
        property bool run: false
        running: false
        onRunChanged: {
            if (run) {
                restart()
            } else {
                reset()
                stop()
            }
        }
    }

    ImageParticle {
        system: particleSystem
        source: "graphics/particle.png"
        alpha: 0.7
        color: "#9bf3ff"
        blueVariation: 0.1
        entryEffect: ImageParticle.Fade
    }

    Emitter {
        id: particles

        anchors.centerIn: sun
        width: sun.width
        height: width
        system: particleSystem
        emitRate: 200
        lifeSpan: 2000
        lifeSpanVariation: 200
        startTime: 0
        size: units.gu(0.4)
        sizeVariation: units.gu(0.6)
        velocity: AngleDirection {
            angle: 360
            angleVariation: 360
            magnitude: units.gu(5)
        }
        velocityFromMovement: units.gu(1)
    }

    RectangularGlow {
        id: sunGlow
        
        readonly property real defaultGlowRadius: units.gu(2)
        readonly property real supernovaGlowRadius: units.gu(0.2)
        
        readonly property real defaulSpread: 0.8
        anchors.fill: sun
        glowRadius: defaultGlowRadius
        spread: defaulSpread
        color: sun.color
        cornerRadius: sun.radius + glowRadius
        
        function reset() {
            spread = defaulSpread
            glowRadius = defaultGlowRadius
            z = 0
        }
    }
    
    Label {
        id: countLabel
        visible: solarSystem.showCounterLabel
        anchors.centerIn: parent
        text: loopTimer.currentTimer
        color: "white"
    }
    
    OrbitingObject {
        id: sunStation
        
        zSystem: 2
        startVisibility: 0
        endVisibility: 10
        fastMode: loopTimer.fastMode
        bodyToOrbit: sunGlow
        orbitDuration: 35
        orbitDirection: 1
        width: units.gu(15)
        objectWidth: units.gu(0.5)
        startingPosition: 1
        customDelegate: Component {
            Rectangle {
                color: "#af6020"
                radius: width / 2
                height: width
            }
        }
    }
    
    QuantumLocObj {
        id: hourglassTwins
        
        zSystem: 3
        fastMode: loopTimer.fastMode
        bodyToOrbit: sunGlow
        orbitDuration: 150
        orbitDirection: 1
        width: units.gu(30)
        source: "graphics/twins.png"
        objectWidth: units.gu(3)
        startingPosition: 3
        rotationDuration: 55
        rotationDirection: 0
        
        hasQuantumMoon: solarSystem.quamtumMoonLocation == 1
        quantumMoonLoc: solarSystem.randomize(1,3)
    }
    
    QuantumLocObj {
        id: timberHearth
        
        zSystem: 4
        fastMode: loopTimer.fastMode
        bodyToOrbit: sunGlow
        orbitDuration: 250
        orbitDirection: 1
        width: units.gu(45)
        source: "graphics/timber_hearth.png"
        objectWidth: units.gu(3.5)
        startingPosition: 0
        
        hasQuantumMoon: solarSystem.quamtumMoonLocation == 2
        quantumMoonLoc: solarSystem.randomize(1,3)
        
        OrbitingObject {
            id: attlerock
            
            fastMode: loopTimer.fastMode
    
            bodyToOrbit: timberHearth.orbitingObject
            orbitDuration: 105
            orbitDirection: 1
            width: timberHearth.objectWidth * 1.2
            objectWidth: units.gu(0.5)
            customDelegate: Component {
                Rectangle {
                    color: "gray"
                    radius: width / 2
                    height: width
                }
            }
        }
    }
    
    OrbitingObject {
        id: interloper
        
        zSystem: 5
        fastMode: loopTimer.fastMode
        startVisibility: 0
        endVisibility: 20
        bodyToOrbit: sunGlow
        horizontalOrbitOffset: -units.gu(27)
        orbitDurationOverride: (visibilityDuration * loopTimer.interval) / (fastMode ? 2 : 4) // Around 4 loops before supernova
        orbitDirection: 0
        width: darkBramble.width * 0.7
        pathOrientation: PathAnimation.TopFirst
        pathExitDuration: orbitDurationOverride
        orbitTilt: 8
        source: "graphics/interloper.png"
        objectWidth: units.gu(2)
    }
    
    Rectangle {
        id: whiteHole
        color: "white"
        width: units.gu(0.2)
        height: width
        radius: width / 2
        visible: false
        anchors {
            left: interloper.left
            leftMargin: units.gu(4)
            verticalCenter: interloper.verticalCenter
        }
    }

    RectangularGlow {
        id: whiteHoleGlow

        anchors.fill: whiteHole
        glowRadius: units.gu(0.3)
        spread: 0.7
        color: whiteHole.color
        cornerRadius: whiteHole.radius + glowRadius
    }

    Repeater {
        id: brittlePieces
        model: brittlePiecesModel
        delegate: Rectangle {
            color: model.color == 1 ? "#17263d" : "#994737"
            width: model.width
            height: width
            anchors {
                centerIn: whiteHole
                horizontalCenterOffset: model.horizontalCenterOffset
                verticalCenterOffset: model.verticalCenterOffset
            }
            
        }
    }

    ListModel {
        id: brittlePiecesModel
    }

    Timer {
        running: true
        repeat: true
        interval: solarSystem.fastMode ? 2000 : 120000
        onTriggered: brittlePiecesModel.append({
                            "width": solarSystem.randomInRange(units.gu(0.1), units.gu(0.4))
                            , "horizontalCenterOffset": solarSystem.randomInRange(units.gu(-2), units.gu(2))
                            , "verticalCenterOffset": solarSystem.randomInRange(units.gu(-2), units.gu(2))
                            , "color": solarSystem.randomize(1, 2)
                        })
    }

    QuantumLocObj {
        id: brittleHollow
        
        zSystem: 6
        fastMode: loopTimer.fastMode
        bodyToOrbit: sunGlow
        orbitDuration: 400
        orbitDirection: 1
        width: units.gu(60)
        source: "graphics/brittle_hollow.png"
        objectWidth: units.gu(4)
        startingPosition: 0
        
        hasQuantumMoon: solarSystem.quamtumMoonLocation == 3
        quantumMoonLoc: solarSystem.randomize(1,3)
        
        OrbitingObject {
            id: hollowLantern
            
            fastMode: loopTimer.fastMode
            bodyToOrbit: brittleHollow.orbitingObject
            orbitDuration: 105
            orbitDirection: 1
            width: brittleHollow.objectWidth * 1.2
            objectWidth: units.gu(0.5)
            customDelegate: Component {
                Rectangle {
                    id: lantern
                    readonly property real startRange: -units.gu(1)
                    readonly property real endRange: units.gu(1)
                    color: "#fe6251"
                    radius: width / 2
                    height: width
                    Repeater {
                        model: solarSystem.randomize(2,4)
                        delegate: Rectangle {
                            width: units.gu(0.1)
                            height: width
                            color: "#ff774e"
                            radius: width / 2
                            anchors {
                                centerIn: parent
                                horizontalCenterOffset: solarSystem.randomize(lantern.startRange, lantern.endRange)
                                verticalCenterOffset:  solarSystem.randomize(lantern.startRange, lantern.endRange)
                            }
                        }
                    }
                }
            }
        }
    }
    
    QuantumLocObj {
        id: giantsDeep
        
        zSystem: 7
        fastMode: loopTimer.fastMode
        bodyToOrbit: sunGlow
        orbitDuration: 650
        orbitDirection: 1
        width: units.gu(85)
        source: "graphics/giants_deep.png"
        objectWidth: units.gu(6)
        startingPosition: 3
        
        hasQuantumMoon: solarSystem.quamtumMoonLocation == 4
        quantumMoonLoc: solarSystem.randomize(1,3)
    }
    
    QuantumLocObj {
        id: darkBramble
        
        zSystem: 8
        fastMode: loopTimer.fastMode
        bodyToOrbit: sunGlow
        orbitDuration: 900
        orbitDirection: 1
        width: units.gu(110)

        source: "graphics/dark_bramble.png"
        objectWidth: units.gu(7)
        startingPosition: 2
        
        hasQuantumMoon: solarSystem.quamtumMoonLocation == 5
        quantumMoonLoc: solarSystem.randomize(1,3)
    }
    
    RectangularGlow {
        id: strangerGlow
        
        z: sunStation.zSystem + 1
        anchors.fill: stranger
        visible: loopTimer.currentTimer >= stranger.startVisibility && loopTimer.currentTimer <= stranger.endVisibility
        glowRadius: units.gu(1)
        spread: 0.9
        color: stranger.color
        cornerRadius: stranger.radius + glowRadius
        
        onVisibleChanged: {
            if (visible) {
                stranger.startMovement()
            } else {
                stranger.reset()
            }
        }
    }
    
    Rectangle {
        id: stranger

        readonly property point startPos: Qt.point((parent.width / 2) + width, (parent.height / 2) - units.gu(15))
        readonly property point endPos: Qt.point((parent.width / 2) - (width * 2), (parent.height / 2) + units.gu(5))
        readonly property int startVisibility: 4
        readonly property int endVisibility: loopTimer.fastMode ? 9 : 5
        readonly property int visibilityDuration: endVisibility - startVisibility
        readonly property real defaultWidth: sun.width * 0.7
        readonly property real defaultHeight: sun.height * 0.7

        visible: false
        radius: width / 2
        color: "black"
        
        function startMovement() {
            width = defaultWidth
            height = defaultHeight
            x = startPos.x
            y = startPos.y
            moveAnim.start()
        }
        function reset() {
            x = startPos.x
            y = startPos.y
        }
        
        ParallelAnimation {
            id: moveAnim
            readonly property int animDuration: (stranger.visibilityDuration + 1) * (loopTimer.fastMode ? 1000 : 60000)
            running: false
            NumberAnimation { target: stranger; property: "x"; to: stranger.endPos.x; duration: moveAnim.animDuration }
            NumberAnimation { target: stranger; property: "y"; to: stranger.endPos.y; duration: moveAnim.animDuration }
        }
    }
}
// ENH032 - End
