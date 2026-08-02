import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Controls 2.12

Rectangle {
    id: indicatorRec

    property real highlightScale: 1.5
    property bool isCurrent: false
    property bool isSwipeSelected: false
    property bool isExtraHighlighted: false
    property bool swipeSelectMode: false
    property bool isMouseHovered: false

    property color backgroundColor: theme.palette.normal.base
    property color currentItemBackgroundColor: theme.palette.normal.baseText
    property color highlightColor: theme.palette.normal.activity

    readonly property color foregroundColor: {
        if (isSwipeSelected)
            return highlightColor

        if (color.hslLightness > 0.5) {
            return "black"
        } else {
            return "white"
        }
    }

    property int itemIndex: -1
    property string itemTitle
    property string itemIconName
    property url itemIconSource
    property string itemText
    

    signal selected

    color: {
        if (isCurrent)
            return currentItemBackgroundColor

        if (isExtraHighlighted) {
            if (backgroundColor.hslLightness > 0.5) {
                return Qt.darker(backgroundColor, 1.2)
            } else {
                return Qt.lighter(backgroundColor, 1.5)
            }
        }

        return backgroundColor
    }

    radius: isExtraHighlighted ? width * 0.2 : width / 2
    height: width
    z: swipeSelectMode || isMouseHovered ? isSwipeSelected ? 2 : 1
                                        : isCurrent ? 2 : 1
    scale: swipeSelectMode || isMouseHovered ? isSwipeSelected ? highlightScale : 1
                                : isCurrent ? highlightScale : 1
    Behavior on scale { LomiriNumberAnimation { duration: LomiriAnimation.BriskDuration } }
    Behavior on color { ColorAnimation { duration: LomiriAnimation.BriskDuration } }

    onIsSwipeSelectedChanged: {
        if (isSwipeSelected) {
            delayHaptics.restart()
        } else {
            delayHaptics.stop()
        }
    }

    Timer {
        id: delayHaptics

        running: false
        interval: 100
        onTriggered: {
            if (indicatorRec.isSwipeSelected) {
                shell.haptics.playSubtle()
            }
        }
    }

    Icon {
        visible: source.toString() !== ""
        source: indicatorRec.itemIconSource.toString() !== "" ? indicatorRec.itemIconSource : "image://theme/%1".arg(indicatorRec.itemIconName)
        width: parent.width * 0.7
        height: width
        anchors.centerIn: parent
        color: indicatorRec.foregroundColor
    }

    Label {
        visible: indicatorRec.itemText && indicatorRec.itemText.trim() !== ""
        text: indicatorRec.itemText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: parent.width * 0.5
        anchors.centerIn: parent
        color: indicatorRec.foregroundColor
    }

    TapHandler {
        acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Cursor | PointerDevice.Pen
        onSingleTapped: {
            indicatorRec.selected()
        }
    }
}
