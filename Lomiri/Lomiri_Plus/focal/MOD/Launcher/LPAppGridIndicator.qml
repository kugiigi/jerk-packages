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
    // WORKAROUND: !swipeHandler.pressed is a workaround for touch since it's still triggering hover when long pressing
    readonly property bool isHovered: bgHoverHandler.hovered && !swipeHandler.pressed

    property bool editMode: false
    property bool mouseHoverEnabled: true
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

    onIsHoveredChanged: {
        if (isHovered) {
            internal.swipeSelectMode = true
        } else {
            internal.swipeSelectMode = false
        }
    }

    QtObject {
        id: internal

        readonly property real initialSwipeThreshold: units.gu(1)
        property bool allowSelection: false
        property point startPoint: Qt.point(0, 0)
        // Allow immediately when hovering with mouse
        property real initialSwipeDistance: appGridIndicator.isHovered ? initialSwipeThreshold : startPoint.x > 0 ? Math.abs(swipeHandler.mouseX - startPoint.x) : 0
        property bool swipeSelectMode: false
        property real storedHeightBeforeSwipeSelectMode: mainRowLayout.height
        readonly property real highlightMargin: mainRowLayout.dotWidth + units.gu(2)
        property var highlightedItem: {
            if (swipeSelectMode && (allowSelection || mainRowLayout.rowCount > 1)) {
                let _targetItem = bgHoverHandler.hovered ? bgHoverHandler : swipeHandler
                let _isMouse = _targetItem === bgHoverHandler
                let _highlightMargin = _isMouse ? 0 : highlightMargin
                let _mappedPos = mainRowLayout.mapFromItem(bg, _targetItem.mouseX, _targetItem.mouseY - _highlightMargin)

                let _found = null
                if (mainRowLayout.rowCount == 1) {
                    let _mappedX = _mappedPos.x
                    if (_mappedX < mainRowLayout.leftPadding) {
                        _mappedX = mainRowLayout.leftPadding
                    } else if (_mappedX > mainRowLayout.width - mainRowLayout.leftPadding) {
                        _mappedX = mainRowLayout.width - mainRowLayout.leftPadding
                    }
                    _found = mainRowLayout.childAt(_mappedX, mainRowLayout.height / 2)
                } else {
                    _found = mainRowLayout.childAt(_mappedPos.x, _mappedPos.y)
                }
                return _found
            }

            return null
        }

        onInitialSwipeDistanceChanged: {
            if (!allowSelection && initialSwipeDistance >= initialSwipeThreshold) {
                allowSelection = true
            }
        }

        onSwipeSelectModeChanged: {
            if (swipeSelectMode) {
                storedHeightBeforeSwipeSelectMode = mainRowLayout.height
                startPoint = Qt.point(swipeHandler.point.scenePressPosition.x, swipeHandler.point.scenePressPosition.y)
            } else {
                startPoint = Qt.point(0, 0)
                allowSelection = false
                titleRec.hide()
            }
        }

        onHighlightedItemChanged: {
            if (highlightedItem) {
                titleRec.show()
            }
        }
    }

    Rectangle {
        id: bg

        readonly property color customColor: shell.settings.customDrawerColor
        color: shell.settings.useCustomDrawerColor ? customColor.hslLightness > 0.1 ? Qt.darker(customColor, 1.2)
                                                                                    : Qt.lighter(customColor, 2.0)
                    : theme.palette.normal.foreground
        opacity: 0.8
        radius: units.gu(3)
        anchors.horizontalCenter: parent.horizontalCenter

        width: mainRowLayout.width
        height: mainRowLayout.height
        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }
    }

    Rectangle {
        id: titleRec

        readonly property var targetItem: internal.highlightedItem
        property bool shown: false
        readonly property point mappedHighlightedItemPos: targetItem ? targetItem.mapToItem(appGridIndicator, 0, 0) : Qt.point(0, 0)
        readonly property real intendedX: targetItem ? mappedHighlightedItemPos.x - (width / 2) + ((targetItem.width * mainRowLayout.highlightScale) / 2) : 0
        readonly property Timer delayTimer: Timer {
            running: false
            interval: 400
            onTriggered: titleRec.shown = true
        }

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

        y: targetItem ? mappedHighlightedItemPos.y - (height + units.gu(2)) : 0
        implicitWidth: rowLayout.width
        implicitHeight: rowLayout.height
        radius: height / 4
        color: theme.palette.highlighted.foreground
        opacity: shown ? 1 : 0
        visible: opacity > 0 && x !==0 && y !== 0

        function show(_delayed=true) {
            if (_delayed) {
                delayTimer.restart()
            } else {
                shown = true
            }
        }

        function hide() {
            delayTimer.stop()
            shown = false
        }

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
                text: titleRec.targetItem ? titleRec.targetItem.itemTitle : ""
            }
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

        property real dotWidth: appGridIndicator.swipeSelectMode ? units.gu(5) : units.gu(2)
        readonly property int normalColumns: Math.ceil((Math.min(appGridIndicator.width * 0.8, units.gu(50))) / (dotWidth + spacing))
        readonly property real highlightScale: 1.5
        readonly property int rowCount: Math.ceil(itemRepeater.count / columns)

        anchors.horizontalCenter: parent.horizontalCenter

        columns: appGridIndicator.editMode ? Math.min(normalColumns, 3) : normalColumns
        padding: units.gu(1)
        leftPadding: units.gu(2) // No rightPadding so it's properly centered
        spacing: units.gu(1)
        verticalItemAlignment: Grid.AlignVCenter
        horizontalItemAlignment: Grid.AlignHCenter

        Behavior on dotWidth { LomiriNumberAnimation {} }

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
                    acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Cursor | PointerDevice.Pen
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

    // Input handlers
    Item {
        anchors.fill: bg

        TapHandler {
            id: swipeHandler

            // Already mapped to global
            readonly property real mouseX: point.position.x
            readonly property real mouseY: point.position.y

            acceptedPointerTypes: PointerDevice.Finger
            margin: units.gu(2)
            enabled: !appGridIndicator.editMode
            gesturePolicy: TapHandler.ReleaseWithinBounds

            onPressedChanged: {
                if (pressed) {
                    internal.swipeSelectMode = true
                    shell.haptics.playSubtle()
                } else {
                    if (internal.highlightedItem) {
                        appGridIndicator.newIndexSelected(internal.highlightedItem.itemIndex)
                        shell.haptics.play()
                    }
                    internal.swipeSelectMode = false
                }
            }
        }

        HoverHandler {
            id: bgHoverHandler

            // Already mapped to global
            readonly property real mouseX: point.position.x
            readonly property real mouseY: point.position.y

            enabled: appGridIndicator.mouseHoverEnabled && !swipeHandler.pressed
            acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Cursor | PointerDevice.Pen
            margin: units.gu(2)
        }
    }
}

