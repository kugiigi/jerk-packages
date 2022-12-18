// ENH046 - Lomiri Plus Settings
import QtQuick 2.12
import QtQuick.Layouts 1.3

Item {
    id: settingsPage

    property list<QtObject> settingsItems
	property string title

	Flickable {
		id: flickable

		anchors.fill: parent
		contentHeight: contentColumn.implicitHeight + (contentColumn.anchors.margins * 2)
		boundsBehavior: Flickable.DragOverBounds
		clip: true

		ColumnLayout {
			id: contentColumn

            spacing: 0

            children: settingsPage.settingsItems

			anchors{
				top: parent.top
				left: parent.left
				right: parent.right
			}
		}
	}
}
// ENH046 - End
