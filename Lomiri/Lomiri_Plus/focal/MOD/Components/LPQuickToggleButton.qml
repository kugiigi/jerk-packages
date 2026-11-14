import QtQuick 2.12
import Lomiri.Components 1.3

Item {
    id: customButton

    property alias radius: bg.radius
    property alias defaultColor: bg.defaultColor
    property alias defaultDisabledColor: bg.defaultDisabledColor
    property alias checkedColor: bg.checkedColor
    property alias checkedDisabledColor: bg.checkedDisabledColor
    property real bgOpacity: 0.7
    property alias border: bg.border
    property int controlIndex: -1
    property var controlData
    property bool highlighted: false
    property bool checked: false
    property bool editMode: false
    property var toggleObj
    property bool noIcon: false
    property bool noClick: false

    focus: false

    property string iconName: ""
    property url iconSource: ""
    property alias pressed: tapHandler.pressed
    property alias hovered: hoverHandler.hovered

    signal clicked
    signal pressAndHold
    
    TapHandler {
        id: tapHandler

        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onLongPressed: customButton.pressAndHold()

        onSingleTapped: {
            if ((eventPoint.event.device.pointerType === PointerDevice.Cursor || eventPoint.event.device.pointerType == PointerDevice.GenericPointer)
                    && eventPoint.event.button === Qt.RightButton) {
                customButton.pressAndHold()
            } else {
                customButton.clicked()
            }
        }
    }

    HoverHandler {
        id: hoverHandler

        acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Cursor | PointerDevice.Pen
    }
    
    onClicked: {
        if (!noClick) {
            if (editMode) {
                let arrNewValues = shell.settings.quickToggles.slice()
                arrNewValues[controlIndex].enabled = !checked
                shell.settings.quickToggles = arrNewValues.slice()
            }
            shell.haptics.play()
        }
    }
    
    onPressAndHold: {
        if (!customButton.editMode) {
            switch (controlData.holdActionType) {
                case "external":
                    Qt.openUrlExternally(controlData.holdActionUrl)
                    break
                default:
                    bar.setCurrentItemIndex(toggleObj.parentMenuIndex)
                    break
            }
            shell.haptics.play()
        }
    }

    Item {
        id: contentContainer

        anchors.fill: parent

        Rectangle {
            id: bg

            property color defaultColor: theme.palette.normal.foreground
            property color defaultDisabledColor: theme.palette.disabled.foreground
            property color checkedColor: theme.palette.normal.selection
            property color checkedDisabledColor: theme.palette.disabled.selection
            property color _normalColor: {
              if (customButton.checked) {
                  if (customButton.enabled) {
                      if (customButton.editMode) {
                          theme.palette.normal.positive
                      } else {
                          checkedColor
                      }
                  } else {
                      checkedDisabledColor
                  }
              } else {
                  if (customButton.enabled) {
                      defaultColor
                  } else {
                      defaultDisabledColor
                  }
              }
            }

            anchors.fill: parent
            radius: units.gu(2)
            opacity: customButton.editMode ? 0.3 : customButton.bgOpacity
            color: !customButton.noClick && customButton.hovered || customButton.pressed? _normalColor.hslLightness > 0.1 ? Qt.darker(_normalColor, 1.2)
                                          : Qt.lighter(_normalColor, 2.0)
                  : _normalColor

            Behavior on color {
              ColorAnimation {
                  duration: LomiriAnimation.SnapDuration
              }
            }
        }

        Icon {
            source: customButton.iconSource.toString() !== "" ? customButton.iconSource
                                                              : customButton.iconName ? "image://theme/%1".arg(customButton.iconName)
                                                                                      : ""
            height: units.gu(3)
            width: height
            visible: !customButton.noIcon
            asynchronous: true
            color: {
                if (customButton.enabled) {
                    theme.palette.normal.foregroundText
                } else {
                    theme.palette.disabled.foregroundText
                }
            }
            anchors.centerIn: parent
        }
    }
    
    SequentialAnimation {
        running: customButton.editMode
        loops: Animation.Infinite

        RotationAnimation {
            target: customButton
            duration: LomiriAnimation.FastDuration
            to: customButton.width < units.gu(10) ? 10 : 2
            direction: RotationAnimation.Clockwise
        }
        RotationAnimation {
            target: customButton
            duration: LomiriAnimation.FastDuration
            to: customButton.width < units.gu(10) ? -10 : -2
            direction: RotationAnimation.Counterclockwise
        }
    }

    RotationAnimation {
        running: !customButton.editMode
        target: customButton
        duration: LomiriAnimation.SnapDuration
        to: 0
        direction: RotationAnimation.Shortest
    }
}
