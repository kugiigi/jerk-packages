// ENH105 - Custom app drawer
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12

Item {
    id: appGridIndicator

    readonly property bool currentIsFullAppGrid: fullAppGridLast ? dataModel.currentIndex === dataModel.count - 1
                                                            : dataModel.currentIndex === 0
    readonly property bool swipeSelectMode: internal.swipeSelectMode
    readonly property real storedHeightBeforeSwipeSelectMode: internal.storedHeightBeforeSwipeSelectMode
    property bool editMode: false
    property bool fullAppGridLast: false
    property int count
    property int currentIndex: -1
    property alias model: itemRepeater.model
    property var dataModel

    signal newIndexSelected(int newIndex)
    signal addNewAppGrid
    signal addAppsToCurrentGrid
    signal deleteCurrentAppGrid
    signal editCurrentAppGrid
    signal moveAppGridToLeft
    signal moveAppGridToRight

    height: mainRowLayout.height

    QtObject {
        id: internal

        property bool swipeSelectMode: false
        property real storedHeightBeforeSwipeSelectMode: mainRowLayout.height
        readonly property real highlightMargin: mainRowLayout.dotWidth + units.gu(2)
        property var highlightedItem: {
            if (swipeSelectMode) {
                let _mappedPos = Qt.point(-mainRowLayout.width, -mainRowLayout.height)

                _mappedPos = swipeHandler.mapToItem(mainRowLayout, swipeHandler.mouseX, swipeHandler.mouseY - highlightMargin)

                let _found = mainRowLayout.childAt(_mappedPos.x, _mappedPos.y)
                return _found
            }

            return null
        }
        
        onSwipeSelectModeChanged: {
            if (swipeSelectMode) {
                storedHeightBeforeSwipeSelectMode = mainRowLayout.height
            }
        }

        onHighlightedItemChanged: {
            if (highlightedItem) {
                delayShow.restart()
            } else {
                delayShow.stop()
                titleRec.show = false
            }
        }
    }

    Rectangle {
        id: bg

        color: theme.palette.normal.foreground
        opacity: 0.8
        radius: units.gu(3)
        anchors.horizontalCenter: parent.horizontalCenter

        width: mainRowLayout.width
        height: mainRowLayout.height
        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }
        Behavior on width { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }
        Behavior on height { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }

        MouseArea {
            id: swipeHandler

            anchors.fill: parent
            enabled: !appGridIndicator.editMode

            onPressed: {
                internal.swipeSelectMode = true
                shell.haptics.playSubtle()
            }
            onReleased: {
                if (internal.highlightedItem) {
                    appGridIndicator.newIndexSelected(internal.highlightedItem.itemIndex)
                    shell.haptics.play()
                }
                internal.swipeSelectMode = false
            }
        }
    }

    Rectangle {
        id: titleRec

        property bool show: false
        readonly property point mappedHighlightedItemPos: internal.highlightedItem ? internal.highlightedItem.mapToItem(appGridIndicator, 0, 0) : Qt.point(0, 0)
        readonly property real intendedX: internal.highlightedItem ? mappedHighlightedItemPos.x - (width / 2) + ((internal.highlightedItem.width * mainRowLayout.highlightScale) / 2) : 0

        z: mainRowLayout.z + 1
        x: {
            if (intendedX + appGridIndicator.anchors.leftMargin < 0) {
                return -appGridIndicator.anchors.leftMargin
            }

            if (intendedX + width + appGridIndicator.anchors.rightMargin > appGridIndicator.width) {
                return appGridIndicator.width - width - appGridIndicator.anchors.rightMargin -  + units.gu(2)
            }

            return intendedX
        }
        y: internal.highlightedItem ? mappedHighlightedItemPos.y - (height + units.gu(1)) : 0
        implicitWidth: rowLayout.width
        implicitHeight: rowLayout.height
        radius: height / 4
        color: theme.palette.highlighted.foreground
        opacity: show ? 1 : 0
        visible: opacity > 0 && x !==0 && y !== 0

        RowLayout {
            id: rowLayout

            Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.bottomMargin: units.gu(0.5)
                Layout.topMargin: units.gu(0.5)
                Layout.leftMargin: units.gu(1)
                Layout.rightMargin: units.gu(1)
                textSize: Label.Large
                color: theme.palette.highlighted.foregroundText
                text: internal.highlightedItem ? internal.highlightedItem.itemTitle : ""
            }
        }

        Timer {
            id: delayShow
            interval: 400
            onTriggered: titleRec.show = true
        }

        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.BriskDuration } }
    }

    RowLayout {
        visible: appGridIndicator.editMode && !appGridIndicator.currentIsFullAppGrid
        height: mainRowLayout.height * 0.8
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: mainRowLayout.left
            rightMargin: units.gu(1)
        }
        QQC2.ToolButton {
            id: prevButton

            readonly property real iconWidth: units.gu(2)
            readonly property real preferredWidth: units.gu(3)

            Layout.fillHeight: true
            Layout.preferredWidth: preferredWidth
            Layout.alignment: Qt.AlignLeft
            enabled: (appGridIndicator.fullAppGridLast && appGridIndicator.dataModel.currentIndex > 0)
                        || (!appGridIndicator.fullAppGridLast && appGridIndicator.dataModel.currentIndex > 1)
            focusPolicy: Qt.NoFocus
            icon {
                name: "go-previous"
                width: prevButton.iconWidth
                height: prevButton.iconWidth
            }
            onClicked: appGridIndicator.moveAppGridToLeft()
        }
        QQC2.ToolButton {
            id: deleteButton

            Layout.fillHeight: true
            Layout.preferredWidth: prevButton.preferredWidth
            Layout.alignment: Qt.AlignLeft
            focusPolicy: Qt.NoFocus
            icon {
                name: "delete"
                width: prevButton.iconWidth
                height: prevButton.iconWidth
            }
            onClicked: appGridIndicator.deleteCurrentAppGrid()
        }
        QQC2.ToolButton {
            id: addAppsButton

            Layout.fillHeight: true
            Layout.preferredWidth: prevButton.preferredWidth
            Layout.alignment: Qt.AlignLeft
            focusPolicy: Qt.NoFocus
            icon {
                name: "add"
                width: prevButton.iconWidth
                height: prevButton.iconWidth
            }
            onClicked: appGridIndicator.addAppsToCurrentGrid()
        }
        Item {
            Layout.fillWidth: true
        }
    }

    Grid {
        id: mainRowLayout

        readonly property real dotWidth: appGridIndicator.swipeSelectMode ? units.gu(5) : units.gu(2)
        readonly property int normalColumns: appGridIndicator.swipeSelectMode ? Math.ceil((Math.min(appGridIndicator.width * 0.8, units.gu(50))) / (dotWidth + spacing))
                                                    : Math.ceil((appGridIndicator.width * 0.6) / (dotWidth + spacing))
        readonly property real highlightScale: 1.5

        anchors.horizontalCenter: parent.horizontalCenter

        columns: appGridIndicator.editMode ? Math.min(normalColumns, 3) : normalColumns
        padding: units.gu(1)
        leftPadding: units.gu(2) // No rightPadding so it's properly centered
        spacing: units.gu(1)
        verticalItemAlignment: Grid.AlignVCenter
        horizontalItemAlignment: Grid.AlignHCenter

        Repeater {
            id: itemRepeater

            delegate: Rectangle {
                id: indicatorRec

                readonly property bool isCurrent: index == appGridIndicator.currentIndex
                readonly property bool isSwipeSelected: this == internal.highlightedItem
                readonly property int itemIndex: index
                readonly property string itemTitle: appGridIndicator.dataModel.currentIndex > -1 ? appGridIndicator.dataModel.itemAt(indicatorRec.itemIndex).gridName : ""

                z: appGridIndicator.swipeSelectMode ? isSwipeSelected ? 2 : 1
                                                        : indicatorRec.isCurrent ? 2 : 1
                color: isCurrent ? theme.palette.normal.baseText : theme.palette.normal.base
                radius: width / 2
                scale: appGridIndicator.swipeSelectMode ? isSwipeSelected ? mainRowLayout.highlightScale : 1
                                                        : indicatorRec.isCurrent ? mainRowLayout.highlightScale : 1
                width: mainRowLayout.dotWidth
                height: width
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
                    name: appGridIndicator.dataModel.currentIndex > -1 ? appGridIndicator.dataModel.itemAt(indicatorRec.itemIndex).iconName
                                : ""
                    width: parent.width * 0.7
                    height: width
                    anchors.centerIn: parent
                    color: appGridIndicator.swipeSelectMode && indicatorRec.isSwipeSelected ? theme.palette.normal.activity
                                                        : indicatorRec.isCurrent ? theme.palette.normal.base : theme.palette.normal.baseText
                    Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.BriskDuration } }
                    Behavior on color { ColorAnimation { duration: LomiriAnimation.BriskDuration } }
                }

                TapHandler {
                    acceptedPointerTypes: PointerDevice.Cursor | PointerDevice.Pen
                    onSingleTapped: {
                        appGridIndicator.newIndexSelected(index)
                    }
                }
            }
        }
    }

    RowLayout {
        visible: appGridIndicator.editMode && !appGridIndicator.currentIsFullAppGrid
        height: mainRowLayout.height * 0.8
        anchors {
            bottom: parent.bottom
            right: parent.right
            left: mainRowLayout.right
            leftMargin: units.gu(1)
        }
        Item {
            Layout.fillWidth: true
        }
        QQC2.ToolButton {
            id: editButton

            Layout.fillHeight: true
            Layout.preferredWidth: prevButton.preferredWidth
            focusPolicy: Qt.NoFocus
            icon {
                name: "edit"
                width: prevButton.iconWidth
                height: prevButton.iconWidth
            }
            onClicked: appGridIndicator.editCurrentAppGrid()
        }
        QQC2.ToolButton {
            id: addButton

            Layout.fillHeight: true
            Layout.preferredWidth: prevButton.preferredWidth
            focusPolicy: Qt.NoFocus
            icon {
                name: "tab-new"
                width: prevButton.iconWidth
                height: prevButton.iconWidth
            }
            onClicked: appGridIndicator.addNewAppGrid()
        }
        QQC2.ToolButton {
            id: nextButton

            Layout.fillHeight: true
            Layout.preferredWidth: prevButton.preferredWidth
            focusPolicy: Qt.NoFocus
            enabled: (appGridIndicator.fullAppGridLast && appGridIndicator.dataModel.currentIndex < appGridIndicator.dataModel.count - 2)
                        || (!appGridIndicator.fullAppGridLast && appGridIndicator.dataModel.currentIndex < appGridIndicator.dataModel.count - 1
                                        && appGridIndicator.dataModel.currentIndex > 0)
            icon {
                name: "go-next"
                width: prevButton.iconWidth
                height: prevButton.iconWidth
            }
            onClicked: appGridIndicator.moveAppGridToRight()
        }
    }
}

