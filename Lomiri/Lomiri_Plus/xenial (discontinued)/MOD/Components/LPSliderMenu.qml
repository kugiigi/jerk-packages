import QtQuick 2.12
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.12

LPQuickToggleButton {
	id: slideMenu

	property var sliderObj
    readonly property var minIcon: sliderObj ? sliderObj.minIcon : ""
    readonly property var maxIcon: sliderObj ? sliderObj.maxIcon : ""

    checkedColor: editMode ? theme.palette.normal.foreground : "transparent"
    checkedDisabledColor: editMode ? theme.palette.disabled.foreground : "transparent"
    bgOpacity: 1
    iconSource: maxIcon
    noIcon: !editMode
    noClick: !slideMenu.editMode

    RowLayout {
        visible: !slideMenu.editMode
        anchors {
            fill: parent
            leftMargin: units.gu(1)
            rightMargin: anchors.leftMargin
        }
        Icon {
            id: leftButton
            source: slideMenu.minIcon
            visible: source !== ""
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: units.gu(3)
            width: height
            color: theme.palette.normal.foregroundText

            AbstractButton {
                anchors.fill: parent
                onClicked: slider.value = slider.minimumValue
            }
        }

        Slider {
            id: slider

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            minimumValue: slideMenu.sliderObj ? slideMenu.sliderObj.minimumValue : 0
            maximumValue: slideMenu.sliderObj ? slideMenu.sliderObj.maximumValue : 100
            live: true

            // FIXME - to be deprecated in Lomiri.Components.
            // Use this to disable the label, since there is not way to do it on the component.
            function formatValue(v) {
                return "";
            }

            Component.onCompleted: {
                value = slideMenu.sliderObj ? slideMenu.sliderObj.value : 0
            }


            onValueChanged: {
                if (slideMenu.sliderObj) {
                    slideMenu.sliderObj.value = value
                }
            }

            Connections {
                target: slideMenu.sliderObj ? slideMenu.sliderObj: null
                onValueChanged: {
                    slider.value = target.value
                }
            }
        }
        Icon {
            id: rightButton
            source: slideMenu.maxIcon
            visible: source !== ""
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: units.gu(3)
            width: height
            color: theme.palette.normal.foregroundText

            AbstractButton {
                anchors.fill: parent
                onClicked: slider.value = slider.maximumValue
            }
        }
    }
}
