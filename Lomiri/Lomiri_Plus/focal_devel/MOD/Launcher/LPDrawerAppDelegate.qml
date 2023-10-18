// ENH105 - Custom app drawer
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12

MouseArea {
    id: drawerDelegate

    property bool focused: false
    property real delegateWidth
    property string appId
    property bool editMode: false
    property alias iconSource: sourceImage.source
    property alias appName: label.text
    property bool hideLabel: false
    // ENH132 - App drawer icon size settings
    property real delegateSizeMultiplier: 1
    // ENH132 - End

    signal applicationSelected(string appId)
    signal applicationContextMenu(string appId)

    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: {
        if (mouse.button == Qt.LeftButton) {
            applicationSelected(appId)
            mouse.accepted = true
        } else {
            applicationContextMenu(appId)
            mouse.accepted = true
        }
    }
    onPressAndHold: applicationContextMenu(appId)

    Keys.onPressed: {
        switch(event.key) {
            case Qt.Key_Enter:
            case Qt.Key_Return:
                applicationSelected(appId)
            break
            case Qt.Key_Control:
            case Qt.Key_Menu:
                applicationContextMenu(appId)
            break
        }
    }

    z: loader.active ? 1 : 0

    ColumnLayout {
        anchors {
            fill: parent
            topMargin: drawerDelegate.hideLabel ? units.gu(0.5) : units.gu(0.3)
            bottomMargin: anchors.topMargin
            leftMargin: units.gu(0.5)
            rightMargin: anchors.leftMargin
        }

        spacing: units.gu(1)

        LomiriShape {
            id: appIcon

            Layout.alignment: Qt.AlignCenter
            // ENH132 - App drawer icon size settings
            Layout.preferredWidth: units.gu(6) * root.delegateSizeMultiplier
            // ENH132 - End
            Layout.preferredHeight: 7.5 / 8 * width

            radius: "medium"
            borderSource: 'undefined'
            source: Image {
                id: sourceImage
                asynchronous: true
                sourceSize.width: appIcon.width
            }
            sourceFillMode: LomiriShape.PreserveAspectCrop

            StyledItem {
                styleName: "FocusShape"
                anchors.fill: parent
                StyleHints {
                    visible: drawerDelegate.focused
                    radius: units.gu(2.55)
                }
            }
        }

        Label {
            id: label
            Layout.fillWidth: true
            Layout.fillHeight: true

            horizontalAlignment: Text.AlignHCenter
            fontSize: "small"
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            visible: !drawerDelegate.hideLabel

            Loader {
                id: loader
                x: {
                    var aux = 0;
                    if (item) {
                        aux = label.width / 2 - item.width / 2;
                        var containerXMap = mapToItem(contentContainer, aux, 0).x
                        if (containerXMap < 0) {
                            aux = aux - containerXMap;
                            containerXMap = 0;
                        }
                        if (containerXMap + item.width > contentContainer.width) {
                            aux = aux - (containerXMap + item.width - contentContainer.width);
                        }
                    }
                    return aux;
                }
                y: -units.gu(0.5)
                active: label.truncated && (drawerDelegate.hovered || drawerDelegate.focused)
                sourceComponent: Rectangle {
                    color: LomiriColors.jet
                    width: fullLabel.contentWidth + units.gu(1)
                    height: fullLabel.height + units.gu(1)
                    radius: units.dp(4)
                    Label {
                        id: fullLabel
                        width: Math.min(drawerDelegate.delegateWidth * 2, implicitWidth)
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        anchors.centerIn: parent
                        text: drawerDelegate.appName
                        fontSize: "small"
                    }
                }
            }
        }
    }

    SequentialAnimation {
        running: drawerDelegate.editMode
        loops: Animation.Infinite

        RotationAnimation {
            target: appIcon
            duration: LomiriAnimation.FastDuration
            to: appIcon.width < units.gu(10) ? 10 : 2
            direction: RotationAnimation.Clockwise
        }
        RotationAnimation {
            target: appIcon
            duration: LomiriAnimation.FastDuration
            to: appIcon.width < units.gu(10) ? -10 : -2
            direction: RotationAnimation.Counterclockwise
        }
    }

    RotationAnimation {
        running: !drawerDelegate.editMode
        target: appIcon
        duration: LomiriAnimation.SnapDuration
        to: 0
        direction: RotationAnimation.Shortest
    }
}
