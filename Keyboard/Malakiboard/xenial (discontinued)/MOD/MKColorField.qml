import QtQuick 2.12
import Ubuntu.Components 1.3
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
import QtQuick.Controls.Suru 2.2

RowLayout {
    property alias text: colorField.text
    property alias title: label.text

    signal colorPicker

    Label {
        id: label
        Layout.alignment: Qt.AlignLeft
    }

	QQC2.TextField {
		id: colorField

		Layout.fillWidth: true
	}
	QQC2.Button {
		Layout.preferredWidth: units.gu(4)
		implicitHeight: width
		indicator: Icon {
			name: "edit-copy"
			width: units.gu(2)
			height: width
			color: Suru.foregroundColor
			anchors.centerIn: parent
		}
		onClicked: {
            colorField.selectAll()
            colorField.copy()
            fullScreenItem.settings.textClipboard = colorField.text
        }
	}
	QQC2.Button {
		Layout.preferredWidth: units.gu(4)
		implicitHeight: width
		indicator: Icon {
			name: "edit-paste"
			width: units.gu(2)
			height: width
			color: Suru.foregroundColor
			anchors.centerIn: parent
		}
		onClicked: {
            colorField.selectAll()
            colorField.paste()
            if (colorField.text == "" && fullScreenItem.settings.textClipboard !== "") {
                colorField.text = fullScreenItem.settings.textClipboard
            }
        }
	}
	QQC2.Button {
		Layout.preferredWidth: units.gu(4)
		implicitHeight: width
		indicator: Icon {
			name: "edit"
			width: units.gu(2)
			height: width
			color: Suru.foregroundColor
			anchors.centerIn: parent
		}
		onClicked: colorPicker()
	}
}
