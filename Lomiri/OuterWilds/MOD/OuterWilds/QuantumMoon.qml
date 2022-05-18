// ENH032 - Infographics Outer Wilds
import QtQuick 2.12
import Ubuntu.Components 1.3

OrbitingObject {
	id: quantumMoon

	fastMode: loopTimer.fastMode
    bodyToOrbit: parent.orbitingObject
//~     displayOrbitLine: true
    orbitDuration: 105
    orbitDirection: 1
    width: parent.objectWidth + units.gu(2) // * 1.5
    objectWidth: units.gu(0.8)
    customDelegate: Component {
        Rectangle {
            color: "#5b5e6a"
            radius: width / 2
            height: width
        }
    }
}
// ENH032 - End
