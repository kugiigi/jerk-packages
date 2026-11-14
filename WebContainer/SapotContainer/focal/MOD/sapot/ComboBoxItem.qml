import QtQuick 2.9
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Layouts 1.3

RowLayout {
	id: comboBoxItem

	property string text
	property alias currentIndex: comboBox.currentIndex
	property alias model: comboBox.model
	property alias currentText: comboBox.currentText
	property alias textRole: comboBox.textRole

	spacing: units.gu(5)

	anchors {
		left: parent.left
		right: parent.right
	}

    function find(text, flags) {
        var result = comboBox.find(text, flags)
        return result
    }

	QQC2.Label {
		id: label

		Layout.preferredWidth: units.gu(10)
		Layout.alignment: Qt.AlignVCenter
		text: comboBoxItem.text + ":"
	}

	QQC2.ComboBox {
		id: comboBox

		Layout.maximumWidth: units.gu(20)
		Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
	}
}
