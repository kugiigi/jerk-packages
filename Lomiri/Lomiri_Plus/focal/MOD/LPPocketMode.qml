// ENH198 - Pocket Mode
import QtQuick 2.12
import Lomiri.Components 1.3

Item {
    id: root

    readonly property bool isReadyToActivate: dragObj.dragRadius >= dragLimitItem.radius

    signal activated

    onIsReadyToActivateChanged: if (isReadyToActivate) shell.haptics.playSubtle()

    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.background
        opacity: 0.8
    }

    MouseArea {
        // Eat all inputs
        anchors.fill: parent
    }
    
    Item {
        id: dragLimitItem

        readonly property real radius: width / 2

        anchors.centerIn: parent
        width: Math.min(units.gu(40), root.width - units.gu(4))
        height: width

        Label {
            font.pixelSize: dragRectangle.height * 0.3
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: -((dragRectangle.height / 2 + units.gu(2)) + height)
            }
            color: theme.palette.normal.backgroundText
            text: i18n.tr("Pocket Mode is active\nSwipe to manually disable it")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            opacity: dragMouseArea.dragIsActive ? 0 : 1

            Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }
        }

        Rectangle {
            id: dragRectangle
     
            color: {
                if (root.isReadyToActivate) return theme.palette.normal.positive
                if (dragMouseArea.pressed)  return theme.palette.normal.backgroundText

                return "transparent"
            }
            border {
                color: root.isReadyToActivate ? theme.palette.normal.positive : theme.palette.normal.backgroundText
                width: units.dp(1)
            }
            width: shell.convertFromInch(0.4)
            height: width
            radius: width / 2

            Icon {
                anchors.centerIn: parent
                width: parent.width * 0.8
                height: width
                name: "gestures"
                asynchronous: true
                color: {
                    if (root.isReadyToActivate) return theme.palette.normal.backgroundText
                    if (dragMouseArea.pressed)  return "transparent"

                    return theme.palette.normal.backgroundText
                }

                Behavior on color { ColorAnimation { duration: LomiriAnimation.SnapDuration } }
            }

            Behavior on color { ColorAnimation { duration: LomiriAnimation.SnapDuration } }
            Behavior on border.color { ColorAnimation { duration: LomiriAnimation.SnapDuration } }
            Behavior on x {
                enabled: !dragMouseArea.dragIsActive
                LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
            }
            Behavior on y {
                enabled: !dragMouseArea.dragIsActive
                LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
            }

            x: dragMouseArea.dragIsActive ? (dragObj.dragRadius <= dragLimitItem.radius ? dragObj.x
                                                                                  : dragLimitItem.radius + ((dragObj.x - dragLimitItem.radius)
                                                                                            * (dragLimitItem.radius / dragObj.dragRadius))) - (width / 2)
                                    : parent.width / 2 - width / 2
            y: dragMouseArea.dragIsActive ? (dragObj.dragRadius <= dragLimitItem.radius ? dragObj.y
                                                                                  : dragLimitItem.radius + ((dragObj.y - dragLimitItem.radius)
                                                                                            * (dragLimitItem.radius / dragObj.dragRadius))) - (height / 2)
                                    : parent.height / 2 - height / 2

            MouseArea {
                id: dragMouseArea
                
                readonly property bool dragIsActive: drag.active

                anchors.fill: parent
                drag.target: dragObj

                onPressed: {
                    dragObj.x = dragRectangle.x + (width / 2)
                    dragObj.y = dragRectangle.y + (height / 2)
                    shell.haptics.playSubtle()
                }

                onReleased: {
                    if (isReadyToActivate) {
                        root.activated()
                        shell.haptics.play()
                    }
                }
            }
        }

        Item {
            id: dragObj

            readonly property real dragRadius: dragMouseArea.dragIsActive ? Math.sqrt(Math.pow(x - dragLimitItem.radius, 2) + Math.pow(y - dragLimitItem.radius, 2))
                                                    : 0

            x: dragLimitItem.radius
            y: dragLimitItem.radius
        }
    }
}
