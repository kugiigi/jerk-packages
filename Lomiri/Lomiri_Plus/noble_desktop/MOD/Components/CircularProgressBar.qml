// ENH036 - Use punchole as battery indicator
import QtQuick 2.12
import Lomiri.Components 1.3

Rectangle {
    id: circle

    property color circleColor: "transparent"
    property color borderColor: "red"
    property color blackSpaceColor: "transparent"
    property int borderWidth: units.gu(1)
    property bool finished: progress == 100
    property int progress: 0

    width: units.gu(30)
    height: width
    color: blackSpaceColor
    radius: width / 2
    border {
        width: borderWidth
        color: blackSpaceColor == "transparent" ? blackSpaceColor : "black"
    }
    Row {
        anchors.fill: parent

        Item {
            width: parent.width / 2
            height: parent.height
            clip: true

            Item {
                id: part1
                property real rotationVal: circle.progress >= 50 ? ((circle.progress - 50) / 50) * 180 : 0
                width: parent.width
                height: parent.height
                clip: true
                rotation: 180 + rotationVal
                transformOrigin: Item.Right

                Rectangle {
                    width: circle.width - (borderWidth * 2)
                    height: circle.height - (borderWidth * 2)
                    radius: width / 2
                    x:borderWidth
                    y:borderWidth
                    color: circleColor
                    border.color: borderColor
                    border.width: borderWidth
                    smooth: true
                }
            }
        }

        Item {
            width: parent.width / 2
            height: parent.height
            clip: true

            Item {
                id: part2
                property real rotationVal: circle.progress <= 50 ? (circle.progress / 50) * 180 : 180
                width: parent.width
                height: parent.height
                clip: true

                rotation: 180 + rotationVal
                transformOrigin: Item.Left

                Rectangle {
                    width: circle.width - (borderWidth * 2)
                    height: circle.height - (borderWidth * 2)
                    radius: width / 2
                    x: -width / 2
                    y: borderWidth
                    color: circleColor
                    border.color: borderColor
                    border.width: borderWidth
                    smooth: true
                }
            }
        }
    }
}
// ENH036 - End
