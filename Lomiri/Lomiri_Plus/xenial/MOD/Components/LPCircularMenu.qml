// ENH064 - Dynamic Cove
import QtQuick 2.12
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.3
import "../Greeter" as Greeter

Item {
	id: circularMenu

    property var currentItem: null
	property var currentAngle: angle(mouseArea.mouseX, mouseArea.mouseY)
	property int currentIndex: currentItem ? currentItem.index : -1 //item underneath cursor
    property alias model: circleMenuRepeater.model
    property int currentSelectedIndex: -1
    property MouseArea mouseArea
    
    signal selected(int selectedIndex)

    // From Stackoverflow LOL
    function angle(ex, ey) {
        var dy = ey - mouseArea.height / 2;
        var dx = ex - mouseArea.width / 2;
        var theta = Math.atan2(dy, dx); // range (-PI, PI]
        theta *= 180 / Math.PI; // rads to degs, range (-180, 180]
        if (theta < 0) theta = 360 + theta; // range [0, 360)
        return theta;
    }

    Connections {
        target: mouseArea
        onClicked: mouse.accepted = true

        onDelayedPressedChanged: {
            if (target.delayedPressed) {
                shell.haptics.playSubtle()
            }
        }

        onReleased: {
            if (circularMenu.currentItem) {
                circularMenu.selected(circularMenu.currentIndex)
                circularMenu.currentItem = null
            }
        }
    }

	Item {
		id: menuCircle

		anchors.fill: parent
		visible: opacity > 0
        opacity: circularMenu.mouseArea.delayedPressed ? 1: 0
        
        Behavior on opacity {
            UbuntuNumberAnimation { duration: UbuntuAnimation.BriskDuration }
        }
		
		Repeater {
			id: circleMenuRepeater

            readonly property real angleRange: 360 / circleMenuRepeater.count

			delegate: Greeter.ObjectPositioner {
                id: delegateContainer

                // Offset by 90 since repeater starts at the top while the angle calculator starts from the right
                readonly property real angleStart: (circleMenuRepeater.angleRange * index) - (circleMenuRepeater.angleRange / 2) - 90
                readonly property real angleEnd: angleStart + circleMenuRepeater.angleRange - 1

				property alias unlockAnimation: dotUnlockAnim
				property alias changeAnimation: dotChangeAnim
				property bool highlighted: {
                    if (circularMenu.mouseArea.delayedPressed) {
                        let _start = angleStart < 0 ? angleStart + 360
                                                    : angleStart > 360 ? angleStart - 360
                                                                       : angleStart
                        let _end = angleEnd < 0 ? angleEnd + 360
                                                : angleEnd > 360 ? angleEnd - 360
                                                                 : angleEnd
                        
                        if (circularMenu.currentAngle > _start && circularMenu.currentAngle < _end) {
                            return true
                        }
                    }

                    return false
                }
				property bool selected: circularMenu.currentSelectedIndex == index

				property int currentDay: 2
				property var text: modelData.label
				property var iconName: modelData.iconName

				index: model.index
				count: circleMenuRepeater.count
				radius: menuCircle.width / 2
				halfSize: menuItem.width / 2
				posOffset: circularMenu.mouseArea.delayedPressed ? radius / menuItem.width / 3 : 3
                rotation: circularMenu.mouseArea.delayedPressed ? 0 : 180
                
                Behavior on posOffset { SpringAnimation { spring: 2; damping: 0.2 } }
                Behavior on rotation { SpringAnimation { spring: 2; damping: 0.2 } }
				
				onHighlightedChanged: {
                    if (highlighted) {
                        circularMenu.currentItem = this

                        if (!selected) {
                            shell.haptics.playSubtle()
                        }
                    }
				}

				Rectangle {
					id: menuItemBg

					width: units.gu(8)
					height: width
                    opacity: 0.8
					color: delegateContainer.selected ? UbuntuColors.orange
                                                      : delegateContainer.highlighted ? theme.palette.highlighted.foreground
                                                                                      : theme.palette.normal.foreground
					radius: width / 2
                    Behavior on color { ColorAnimation { duration: UbuntuAnimation.FastDuration } }
                }
                Item {
					id: menuItem

                    anchors.fill: menuItemBg

					Icon {
                        anchors.centerIn: parent
                        name: delegateContainer.iconName
                        width: units.gu(4)
                        height: width
                        color: delegateContainer.highlighted ? theme.palette.highlighted.activity : theme.palette.normal.foregroundText
                        Behavior on color { ColorAnimation { duration: UbuntuAnimation.FastDuration } }
                    }

					PropertyAnimation {
						id: dotUnlockAnim

						target: menuItem
						property: "opacity"
						to: menuItem.baseOpacity
						duration: dotShowAnimTimer.interval
					}

					PropertyAnimation {
						id: dotChangeAnim

						target: menuItem
						property: "opacity"
						to: 0.0
						duration: dotHideAnimTimer.interval
					}
				}
			}
		}
	}
}
// ENH064 - End
