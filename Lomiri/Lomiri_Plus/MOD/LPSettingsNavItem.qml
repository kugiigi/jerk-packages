// ENH046 - Lomiri Plus Settings
import QtQuick 2.8
import Ubuntu.Components 1.3
import QtQuick.Controls 2.12 as QQC2

QQC2.ItemDelegate {
	indicator: Icon {
		name: "next"
        width: units.gu(2)
        height: width
        anchors {
            right: parent.right
            rightMargin: units.gu(2)
            verticalCenter: parent.verticalCenter
        }
	}
}
// ENH046 - End
