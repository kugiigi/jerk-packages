// ENH032 - Infographics Outer Wilds
import QtQuick 2.12
import Ubuntu.Components 1.3

Image {
	id: scout
	
	readonly property real startScale: 1
	readonly property real endScale: 3
    property real wallpaperWidth
    property real wallpaperHeight
	
	asynchronous: true
	source: "graphics/scout.png"
	width: units.gu(1)
	height: width
	fillMode: Image.PreserveAspectFit
    sourceSize: Qt.size(units.gu(3), units.gu(3))
	
	PathAnimation {
		id: flyByAnim
		running: scout.visible
		target: scout
		duration: 6000
		loops: Animation.Infinite
		anchorPoint: Qt.point(scout.width / 2, scout.height / 2)
		path: Path {
			startX: (wallpaperWidth * 0.7) + units.gu(15)
			startY: -scout.height - units.gu(10)

			PathLine {
			   x: -scout.width
			   y: wallpaperHeight / 2
			}
		}
	}
	
	NumberAnimation {
		id: sizeAnim
		running: scout.visible
		loops: Animation.Infinite
		target: scout
		property: "scale"
		from: scout.startScale
		to: scout.endScale
		duration: flyByAnim.duration
	}
	
	RotationAnimation {
		id: rotateAnim
		running: scout.visible
		loops: Animation.Infinite
		target: scout
		property: "rotation"
		from: 0
		to: 360
		duration: 2000
	}
}
// ENH032 - End
