// ENH064 - Dynamic Cove
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import "../Greeter" as Greeter

Item {
	id: circularMenu

    //property var currentItem: menuCircle.childAt(mouseArea.mouseX, mouseArea.mouseY - units.gu(6)) // with offset
	property var currentItem: menuCircle.childAt(mouseArea.mouseX, mouseArea.mouseY) //item underneath cursor
	property int currentIndex: currentItem ? currentItem.index : -1 //item underneath cursor
    property alias model: circleMenuRepeater.model
    property int currentSelectedIndex: -1
    property MouseArea mouseArea
    
    signal selected(int selectedIndex)

    Connections {
        target: mouseArea
        onClicked: mouse.accepted = true

        onPressed: {
            shell.haptics.playSubtle()
        }

        onReleased: {
            if (circularMenu.currentItem) {
                circularMenu.selected(circularMenu.currentIndex)
            }
        }
    }

	Item {
		id: menuCircle

		anchors.fill: parent
		visible: opacity > 0
        opacity: circularMenu.mouseArea.delayedPressed ? 1: 0
        
        Behavior on opacity {
            LomiriNumberAnimation { duration: LomiriAnimation.BriskDuration }
        }
		
		Repeater {
			id: circleMenuRepeater

			delegate: Greeter.ObjectPositioner {
                id: delegateContainer

				property alias unlockAnimation: dotUnlockAnim
				property alias changeAnimation: dotChangeAnim
				property bool highlighted: circularMenu.currentIndex == index
				property bool selected: circularMenu.currentSelectedIndex == index

				property int currentDay: 2
				property var text: modelData.label
				property var iconName: modelData.iconName

				index: model.index
				count: circleMenuRepeater.count
				radius: menuCircle.width / 2
				halfSize: menuItem.width / 2
				posOffset: circularMenu.mouseArea.pressed ? radius / menuItem.width / 3 : 3
                rotation: circularMenu.mouseArea.pressed ? 0 : 180
                
                Behavior on posOffset { SpringAnimation { spring: 2; damping: 0.2 } }
                Behavior on rotation { SpringAnimation { spring: 2; damping: 0.2 } }
				
				onHighlightedChanged: {
					if (highlighted && !selected) shell.haptics.playSubtle()
				}

				Rectangle {
					id: menuItemBg

					width: units.gu(8)
					height: width
                    opacity: 0.8
					color: delegateContainer.selected ? LomiriColors.orange
                                                      : delegateContainer.highlighted ? theme.palette.highlighted.foreground
                                                                                      : theme.palette.normal.foreground
					radius: width / 2
                    Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
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
                        Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
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
