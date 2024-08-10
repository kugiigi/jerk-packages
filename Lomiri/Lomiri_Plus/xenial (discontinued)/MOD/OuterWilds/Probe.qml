// ENH032 - Infographics Outer Wilds
import QtQuick 2.12
import Ubuntu.Components 1.3
import QtGraphicalEffects 1.12

Rectangle {
	id: probe

	readonly property real startWidth: units.gu(0.2)
	readonly property real endWidth: units.gu(1.5)
	readonly property point startPos: Qt.point(isLandscape ? (wallpaperWidth / 2) - units.gu(5) : (wallpaperWidth / 2) - units.gu(20), wallpaperHeight / 2)
	property point endPos: Qt.point(0,0)
    readonly property bool isLandscape: wallpaperWidth > wallpaperHeight
    property real wallpaperWidth
    property real wallpaperHeight

	width: startWidth
	height: width
	color: "#5b63de"
	radius: width / 2
    opacity: 0

    function randomInRange(min, max) { //for floating
      return Math.random() < 0.5 ? ((1-Math.random()) * (max-min) + min) : (Math.random() * (max-min) + min);
    }

    function randomize(start, end) {
        return Math.floor((Math.random() * end) + start)
    }
    
    function resetAnimation() {
        var goUp = probe.randomize(1, 2) == 1
        var goRight = probe.randomize(1, 2) == 1

        probe.endPos = Qt.point(goRight ? randomInRange(wallpaperWidth, wallpaperWidth + units.gu(50)): -randomInRange(width, width + units.gu(50))
        // Include mid x
        // probe.endPos = Qt.point(goRight ? randomInRange(wallpaperWidth / 2, wallpaperWidth + units.gu(50)): randomInRange(width - units.gu(50), wallpaperWidth / 2 )
                                            , goUp ? randomInRange(height - units.gu(50),  wallpaperHeight / 2) : randomInRange(wallpaperHeight / 2, wallpaperHeight + units.gu(50)))
        flyByAnim.duration = 10 * Math.sqrt(Math.pow(endPos.x - startPos.x, 2) + Math.pow(endPos.y - startPos.y, 2))
        flyByAnim.restart()
        sizeAnim.restart()
    }
    
    Component.onCompleted: {
        resetAnimation()
    }

	RectangularGlow {
        id: glow

        anchors.fill: probe
        glowRadius: units.gu(1)
        spread: 0.2
        color: probe.color
        cornerRadius: units.gu(1)
    }

	PathAnimation {
		id: flyByAnim

		running: false
		target: probe
		anchorPoint: Qt.point(probe.width / 2, probe.height / 2)
		path: Path {
			startX: probe.startPos.x
			startY: probe.startPos.y

			PathLine {
			   x: probe.endPos.x
			   y: probe.endPos.y
			}
		}
        onStarted: showAnimation.restart()
	}
	
	NumberAnimation {
		id: sizeAnim

		running: false
		target: probe
		property: "width"
		from: probe.startWidth
		to: probe.endWidth
		duration: flyByAnim.duration
	}

    UbuntuNumberAnimation {
        id: showAnimation
        running: false
        target: probe
        property: "opacity"
        from: 0
        to: 1
        duration: 500
    }
}
// ENH032 - End
