import QtQuick 2.4
import Lomiri.Components 1.3
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.12

QQC2.ToolBar {
    id: toolbar

    default property alias data: defaultContent.data
    property list<ToolbarAction> leftActions
    property list<ToolbarAction> rightActions
    
    property color backgroundColor: theme.palette.normal.foreground
    property real radius: units.gu(0.5)

    background: Rectangle {
        color: toolbar.backgroundColor
        radius: toolbar.radius
    }

    Image {
        id: tabShadow
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.top
        }
        source: "../../webbrowser/assets/toolbar-dropshadow.png"
        fillMode: Image.TileHorizontally
        asynchronous: true
    }

    RowLayout {
        spacing: 0
        anchors.fill: parent
        
        ToolbarActions {
            id: leftActionsRow

            Layout.alignment: Qt.AlignLeft
            model: toolbar.leftActions
        }
        Item {
            id: defaultContent
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        ToolbarActions {
            id: rightActionsRow

            Layout.alignment: Qt.AlignRight
            model: toolbar.rightActions
        }
    }
}
