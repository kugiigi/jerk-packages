import QtQuick 2.12
import Ubuntu.Components 1.3

AbstractButton {
    id: customButton

    property alias radius: bg.radius
    property alias color: bg._normalColor
    property alias border: bg.border
    property bool highlighted: false
    property bool checked: false
    property bool editMode: false
    property var toggleObj

    focus: false
    
    onClicked: shell.haptics.play()

    Item {
        id: contentContainer

        anchors.fill: parent

        Rectangle {
          id: bg

              property color _normalColor: {
                  if (customButton.checked) {
                      if (customButton.enabled) {
                          if (customButton.editMode) {
                              theme.palette.normal.positive
                          } else {
                              theme.palette.normal.selection
                          }
                      } else {
                          theme.palette.disabled.selection
                      }
                  } else {
                      if (customButton.enabled) {
                          theme.palette.normal.foreground
                      } else {
                          theme.palette.disabled.foreground
                      }
                  }
              }

              anchors.fill: parent
              radius: units.gu(2)
              opacity: customButton.editMode ? 0.3 : 0.7

              color: customButton.hovered || customButton.pressed ? _normalColor.hslLightness > 0.1 ? Qt.darker(_normalColor, 1.2)
                                              : Qt.lighter(_normalColor, 2.0)
                      : _normalColor

              Behavior on color {
                  ColorAnimation {
                      duration: UbuntuAnimation.SnapDuration
                  }
              }
        }

        Icon {
          name: customButton.iconName
          source: customButton.iconSource
          height: units.gu(3)
          width: height
          color: theme.palette.normal.foregroundText
          anchors.centerIn: parent
        }
    }
    
    SequentialAnimation {
        running: customButton.editMode
        loops: Animation.Infinite

        RotationAnimation {
            target: customButton
            duration: UbuntuAnimation.FastDuration
            to: 10
            direction: RotationAnimation.Clockwise
        }
        RotationAnimation {
            target: customButton
            duration: UbuntuAnimation.FastDuration
            to: -10
            direction: RotationAnimation.Counterclockwise
        }
    }

    RotationAnimation {
        running: !customButton.editMode
        target: customButton
        duration: UbuntuAnimation.SnapDuration
        to: 0
        direction: RotationAnimation.Shortest
    }
}
