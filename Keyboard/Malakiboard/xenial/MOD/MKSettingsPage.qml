// ENH070 - Keyboard settings
import QtQuick 2.12
import QtQuick.Layouts 1.3

MKBasePage {
    id: settingsPage

    default property alias data: contentColumn.data

	Flickable {
		id: flickable

		anchors.fill: parent
		contentHeight: contentColumn.implicitHeight + (contentColumn.anchors.margins * 2)
		boundsBehavior: Flickable.DragOverBounds
		clip: true

		ColumnLayout {
			id: contentColumn

            spacing: 0

			anchors{
				top: parent.top
				left: parent.left
				right: parent.right
			}
		}
	}
}
// ENH070 - End
