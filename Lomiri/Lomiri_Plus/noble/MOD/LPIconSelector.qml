import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2

Rectangle {
    id: iconMenu

    readonly property string selectedIcon: iconGridView.model[iconGridView.currentIndex]
    property string currentIcon
    property alias model: iconGridView.model

    signal iconSelected(string iconName)

    anchors.centerIn: parent
    width: Math.min(parent.width * 0.7, units.gu(60))
    height: Math.min(parent.height * 0.8, units.gu(90))
    z: 1000
    visible: false
    color: theme.palette.normal.base
    radius: units.gu(3)

    function show() {
        visible = true
    }

    function hide() {
        visible = false
        destroy()
    }

    onSelectedIconChanged: iconSelected(selectedIcon)

    Component.onCompleted: {
        if (currentIcon) {
            let _foundIndex = iconGridView.model.indexOf(currentIcon)
            if (_foundIndex > -1) {
                iconGridView.currentIndex = _foundIndex
            }
        }
    }

    InverseMouseArea {
       anchors.fill: parent
       acceptedButtons: Qt.LeftButton
       onPressed: iconMenu.hide()
    }

    GridView {
        id: iconGridView

        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }
        clip: true
        height: iconMenu.contentHeight
        cellWidth: width / 6
        cellHeight: cellWidth
        snapMode: GridView.SnapToRow

        delegate: QQC2.ToolButton {
            width: iconGridView.cellWidth
            height: width
            highlighted: iconGridView.currentIndex === index
            icon {
                name: modelData
                width: units.gu(3)
                height: units.gu(3)
            }
            onClicked: {
                iconGridView.currentIndex = index
                iconMenu.hide()
            }
        }
    }
}
