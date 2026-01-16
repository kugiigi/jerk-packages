import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import "." as Common

SwipeArea {
    id: bottomSwipeArea
    
    enum Edge {
        Left
        , Right
    }

    // Determines if quick actions do not span the whole available height
    readonly property bool partialLength: thresholdLength == maxThresholdLength
    // Custom determining if dragging or not
    readonly property bool draggingCustom: distance >= distanceThreshold
    readonly property real thresholdLength: Math.min(availableHeight - distanceThreshold, maxThresholdLength)
    readonly property int stagesCount: model.length
    readonly property real stageWidth: thresholdLength / stagesCount
    readonly property bool fineControl: enableQuickActions && stagesCount > 0
    readonly property var highlightedItem: quickActionsLoader.item
                            ? quickActionsLoader.item.childAt(quickActionsLoader.item.width / 2
                                                              , quickActionsLoader.item.height
                                                                      - distance
                                                                      + distanceThreshold
                                                              )
                            : null

    property bool enableQuickActions: false
    property bool enableQuickActionsDelay: true

    property bool bigUIMode: false

    // Trigger the signal instead of the first visible quick action
    // when doing a quick swipe
    property bool triggerSignalOnQuickSwipe: false

    property real distanceThreshold: (Screen.pixelDensity * 25.4) * 0.2 // Max quick actions bottom margin (inch)
    readonly property real maxThresholdLength: bigUIMode ? availableHeight
                                                    : (Screen.pixelDensity * 25.4) * maxQuickActionsHeightInInch // Max height of quick actions (inch)
    property real maxQuickActionsHeightInInch: 3
    property real availableHeight: parent.height
    property real availableWidth: parent.width

    // Model for the direct actions
    property list<BaseAction> model
    property int edge: BottomSwipeArea.Edge.Left
    property var actionsParent: QQC2.ApplicationWindow.overlay

    signal triggered()

    direction: SwipeArea.Upwards
    immediateRecognition: true
    implicitHeight: units.gu(2)

    onDraggingCustomChanged: {
        if (dragging
                && ((fineControl && quickActionsLoader.visibleCount > 0)
                        || triggerSignalOnQuickSwipe
                    )
            ) {
            if (!draggingCustom) {
                Common.Haptics.playSubtle()
            }
        }
    }

    onDraggingChanged: {
        if (!dragging && draggingCustom) {
            if (fineControl) {
                if (highlightedItem && internal.triggerDirectAccess) {
                    highlightedItem.trigger(true)
                } else {
                    if (triggerSignalOnQuickSwipe) {
                        triggered()
                    } else if (quickActionsLoader.visibleCount > 1) {
                        menuComponent.createObject(menuParent).openBottom()
                        Common.Haptics.play()
                    } else {
                        quickActionsLoader.triggerFirstItem()
                    }
                }
            } else {
                triggered()
            }
        }

        if (!dragging) {
            internal.triggerDirectAccess = false
            swipeTriggerDelay.stop()
        } else {
            swipeTriggerDelay.restart()
        }
    }

    // Delay showing quick actions menu
    Timer {
        id: swipeTriggerDelay

        interval: bottomSwipeArea.enableQuickActionsDelay ? 300 : 0
        running: false
        onTriggered: internal.triggerDirectAccess = true
    }

    QtObject {
        id: internal

        property bool triggerDirectAccess: false
    }

    Rectangle {
        id: quickActionsBG

        readonly property bool show: quickActionsLoader.item && quickActionsLoader.item.actuallyVisible
        readonly property real defaultOpacity: 0.8

        z: quickActionsLoader.z - 1
        color: "#111111"
        anchors.fill: parent
        parent: bottomSwipeArea.actionsParent
        visible: opacity > 0
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: LomiriAnimation.FastDuration } }

        onShowChanged: {
            if (show) {
                delayBGShow.restart()
            } else {
                delayBGShow.stop()
                opacity = 0
            }
        }

        Timer {
            id: delayBGShow

            running: false
            interval: 500
            onTriggered: {
                if (quickActionsBG.show) {
                    quickActionsBG.opacity = quickActionsBG.defaultOpacity
                } else {
                    quickActionsBG.opacity = 0
                }
            }
        }
    }

    Loader {
        id: quickActionsLoader

        property int visibleCount: item ? item.visibleChildren.length : 0

        active: bottomSwipeArea.fineControl
        asynchronous: true
        width: bottomSwipeArea.availableWidth - anchors.leftMargin
        height: bottomSwipeArea.thresholdLength
        parent: bottomSwipeArea.actionsParent
        z: 100
        anchors {
            left: bottomSwipeArea.edge == BottomSwipeArea.Edge.Left ? parent.left : undefined
            right: bottomSwipeArea.edge == BottomSwipeArea.Edge.Right ? parent.right : undefined
            leftMargin: (Screen.pixelDensity * 25.4) * 0.5
            rightMargin: (Screen.pixelDensity * 25.4) * 0.5
            bottom: parent.bottom
            bottomMargin: bottomSwipeArea.distanceThreshold
        }

        function triggerFirstItem() {
            if (item && item.visibleChildren[0]) {
                item.visibleChildren[0].trigger(true)
                Common.Haptics.play()
            }
        }

        sourceComponent: ColumnLayout {
            id: indicatorOptions

            // Substitute to "visible" since we only use opacity to hide it
            readonly property bool actuallyVisible: opacity > 0

            layoutDirection: Qt.RightToLeft
            spacing: 0
            opacity: internal.triggerDirectAccess
                                    && bottomSwipeArea.draggingCustom ? 1 : 0

            Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }

            Repeater {
                id: indicatorSwipeRepeater

                model: bottomSwipeArea.model
                visible: false // Set to false so it doesn't count in visibleChildren

                Item {
                    id: quickActionItem

                    readonly property string itemText: modelData.text
                    readonly property string itemIcon: modelData.iconName
                    readonly property bool highlighted: bottomSwipeArea.highlightedItem == this
                                                            && indicatorOptions.actuallyVisible 

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    visible: modelData.visible
                    enabled: modelData.enabled
                    z: highlighted ? 10 : 1

                    function trigger(fromBottom) {
                        modelData.trigger(fromBottom, bottomSwipeArea)
                    }

                    onHighlightedChanged: {
                        if (highlighted) {
                            delayHaptics.restart()
                            delayShow.restart()
                        } else {
                            delayHaptics.stop()
                            itemLabel.show = false
                            delayShow.stop()
                        }
                    }

                    Timer {
                        id: delayHaptics

                        running: false
                        interval: 100
                        onTriggered: {
                            if (quickActionItem.highlighted) {
                                Common.Haptics.playSubtle()
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        layoutDirection: bottomSwipeArea.edge == BottomSwipeArea.Edge.Left ? Qt.RightToLeft : Qt.LeftToRight
                        spacing: units.gu(4)

                        QQC2.Label {
                            id: itemLabel

                            property bool show: false

                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true

                            visible: opacity > 0
                            opacity: show ? 1: 0
                            color: quickActionItem.enabled ? LomiriColors.porcelain : LomiriColors.silk
                            font.weight: Font.DemiBold
                            text: quickActionItem.itemText
                            font.pixelSize: bgRec.height * 0.4
                            horizontalAlignment: bottomSwipeArea.edge == BottomSwipeArea.Edge.Left ? Text.AlignLeft : Text.AlignRight
                            wrapMode: Text.WordWrap

                            background: Item {
                                readonly property real horizontalPadding: units.gu(2)

                                anchors {
                                    left: bottomSwipeArea.edge == BottomSwipeArea.Edge.Left ? parent.left : undefined
                                    right: bottomSwipeArea.edge == BottomSwipeArea.Edge.Right ? parent.right : undefined
                                    leftMargin: -horizontalPadding
                                    rightMargin: -horizontalPadding
                                    verticalCenter: parent.verticalCenter
                                }
                                width: itemLabel.contentWidth + horizontalPadding * 2
                                height: itemLabel.contentHeight + units.gu(1)

                                Rectangle {
                                    id: textBg

                                    radius: units.gu(2)
                                    anchors.fill: parent
                                    color: "transparent"
                                }
                            }

                            Timer {
                                id: delayShow
                                running: false
                                interval: 500
                                onTriggered: itemLabel.show = quickActionItem.highlighted
                            }

                            Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.BriskDuration } }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: !itemLabel.visible
                        }

                        Item {
                            id: quickActionIcon
                            readonly property real preferredSize: (quickActionsLoader.height / quickActionsLoader.visibleCount) - units.gu(0.5)
                            readonly property real maximumSize: bottomSwipeArea.bigUIMode ? units.gu(8) : units.gu(6)

                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: preferredSize
                            Layout.preferredHeight: preferredSize
                            Layout.maximumHeight: maximumSize
                            Layout.maximumWidth: maximumSize

                            scale: quickActionItem.highlighted ? 1.5 : 1

                            Behavior on scale { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }

                            Rectangle {
                                id: bgRec

                                color: quickActionItem.enabled ? quickActionItem.highlighted ? theme.palette.highlighted.foreground : theme.palette.normal.foreground
                                                : theme.palette.disabled.foreground
                                radius: width / 2
                                anchors.fill: parent
                                opacity: 1
                                Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
                            }

                            Icon {
                                anchors.centerIn: bgRec
                                height: bgRec.height * 0.5
                                width: height
                                name: quickActionItem.itemIcon
                                color: quickActionItem.enabled ? quickActionItem.highlighted ? theme.palette.highlighted.foregroundText : theme.palette.normal.foregroundText
                                                : theme.palette.disabled.foregroundText
                                Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
                            }
                        }
                    }
                }
            }
        }
    }

    // Dummy parent for the menu
    Item {
        id: menuParent

        width: bottomSwipeArea.availableWidth
        anchors {
            left: bottomSwipeArea.edge == BottomSwipeArea.Edge.Left ? parent.left : undefined
            right: bottomSwipeArea.edge == BottomSwipeArea.Edge.Right ? parent.right : undefined
        }
    }
    
    Component {
        id: menuComponent

        VerticalMenuActions {
            id: bottomMenu

            readonly property real edgMargin: units.gu(2)

            x: bottomSwipeArea.edge == BottomSwipeArea.Edge.Left ? edgMargin : parent.width - width - edgMargin
            transformOrigin: bottomSwipeArea.edge == BottomSwipeArea.Edge.Left ? QQC2.Menu.BottomLeft : QQC2.Menu.BottomRight
            model: bottomSwipeArea.model
        }
    }
}
