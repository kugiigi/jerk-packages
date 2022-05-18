// ENH032 - Infographics Outer Wilds
import QtQuick 2.12
import Ubuntu.Components 1.3

OrbitingObject {
	id: quantumLocObj
	
	QuantumMoon {
		visible: quantumLocObj.hasQuantumMoon
		startingPosition: quantumLocObj.quantumMoonLoc
	}
}

// ENH032 - End
