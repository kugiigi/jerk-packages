import QtQuick 2.15
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12

Item {
    id: root

    default property alias data: contentsItem.data

    property alias title: titleLabel.text
    property Component headerSourceComponent
    property real initialX: width / 2 - floatingRec.width / 2
    property real initialY: height / 2 - floatingRec.height / 2
    property real maximumWidth: units.gu(80)
    property real preferredWidth: parent.width * 0.9
    property real maximumHeight: units.gu(50)
    property real preferredHeight: units.gu(50)

    property alias headerItem: headerLoader.item
    property alias floatingItem: floatingRec

    signal close

    opacity: dragButton.dragActive ? 0.4 : 1
    Behavior on opacity { LomiriNumberAnimation {} }

    Rectangle {
        id: floatingRec

        x: root.initialX
        y: root.initialY
        width: Math.min(root.preferredWidth, root.maximumWidth)
        height: Math.min(root.preferredHeight, root.maximumHeight)
        radius: units.gu(2)
        color: theme.palette.normal.background
        clip: true

        // Eater mouse events
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onWheel: wheel.accepted = true;
        }

        ColumnLayout {
            spacing: 0
            anchors.fill: parent

            QQC2.ToolBar {
                Layout.fillWidth: true
                Layout.bottomMargin: units.dp(1)
                // Make this over the content to avoid the need for clipping
                z: 1

                background: Rectangle {
                    radius: units.gu(2)
                    color: theme.palette.normal.background
                }

                RowLayout {
                    anchors.fill: parent

                    QQC2.ToolButton {
                        Layout.fillHeight: true
                        Layout.preferredWidth: units.gu(4)

                        icon.width: units.gu(2)
                        icon.height: units.gu(2)
                        action: QQC2.Action {
                            icon.name:  "close"
                            shortcut: StandardKey.Cancel
                            onTriggered: root.close()
                        }
                    }

                    Label {
                        id: titleLabel
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        verticalAlignment: Text.AlignVCenter
                        textSize: Label.Large
                        elide: Text.ElideRight
                        visible: headerLoader.item === null
                    }

                    Loader {
                        id: headerLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        sourceComponent: root.headerSourceComponent
                    }

                    MouseArea {
                        id: dragButton

                        readonly property bool dragActive: drag.active

                        Layout.fillHeight: true
                        Layout.preferredWidth: units.gu(6)
                        Layout.preferredHeight: width
                        Layout.alignment: Qt.AlignRight

                        drag.target: floatingRec
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: 0
                        drag.maximumX: root.width - floatingRec.width
                        drag.minimumY: 0
                        drag.maximumY: root.height - floatingRec.height

                        Rectangle {
                            anchors.fill: parent
                            color: dragButton.pressed ? theme.palette.selected.background : theme.palette.normal.background
                            radius: units.gu(2)

                            Behavior on color {
                                ColorAnimation { duration: LomiriAnimation.FastDuration }
                            }

                            Icon {
                                id: icon

                                implicitWidth: dragButton.width * 0.60
                                implicitHeight: implicitWidth
                                name: "grip-large"
                                anchors.centerIn: parent
                                color: theme.palette.normal.overlayText
                            }
                        }
                    }
                }
            }

            Item {
                id: contentsItem

                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
