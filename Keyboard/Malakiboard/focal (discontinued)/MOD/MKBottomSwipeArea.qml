// ENH089 - Quick actions
import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Controls.Suru 2.2
import "." as Common

SwipeArea {
    id: bottomSwipeArea
    
    enum Edge {
        Left
        , Right
    }

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

    // Trigger the signal instead of the first visible quick action
    // when doing a quick swipe
    property bool triggerSignalOnQuickSwipe: false

    property real distanceThreshold: (Screen.pixelDensity * 25.4) * 0.2 // 0.2 inch
    property real maxThresholdLength: (Screen.pixelDensity * 25.4) * fullScreenItem.settings.quickActionsHeight // Inches
    property real availableHeight: maxThresholdLength
    property real availableWidth: maxThresholdLength

    // Model for the direct actions
    property list<MKBaseAction> model
    property int edge: MKBottomSwipeArea.Edge.Left

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
                fullScreenItem.swipeHaptic.start()
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

    // Delay showing direct access to enable quick short swipe to always open notifications
    // and quick access to quick toggles
    Timer {
        id: swipeTriggerDelay

        // interval: 300
        interval: 1 // Remove delay since no quick swipe support anyway
        running: false
        onTriggered: internal.triggerDirectAccess = true
    }

    QtObject {
        id: internal

        property bool triggerDirectAccess: false
    }

    Loader {
        id: quickActionsLoader

        property int visibleCount: item ? item.visibleChildren.length : 0

        active: bottomSwipeArea.fineControl
        asynchronous: true
        width: bottomSwipeArea.availableWidth - anchors.leftMargin
        height: bottomSwipeArea.thresholdLength
        anchors {
            left: bottomSwipeArea.edge == MKBottomSwipeArea.Edge.Left ? parent.left : undefined
            right: bottomSwipeArea.edge == MKBottomSwipeArea.Edge.Right ? parent.right : undefined
            leftMargin: (Screen.pixelDensity * 25.4) * 0.5
            rightMargin: (Screen.pixelDensity * 25.4) * 0.5
            bottom: parent.bottom
            bottomMargin: bottomSwipeArea.distanceThreshold
        }

        function triggerFirstItem() {
            if (item && item.visibleChildren[0]) {
                item.visibleChildren[0].trigger(true)
                fullScreenItem.swipeHaptic.start()
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
                    readonly property string itemIconRotation: modelData.iconRotation
                    readonly property bool highlighted: bottomSwipeArea.highlightedItem == this
                                                            && indicatorOptions.actuallyVisible 

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    visible: modelData.visible && modelData.enabled
                    z: highlighted ? 10 : 1

                    function trigger(fromBottom) {
                        modelData.trigger(fromBottom, bottomSwipeArea)
                    }

                    onHighlightedChanged: {
                        if (highlighted) {
                            fullScreenItem.swipeHaptic.start()
                            delayShow.restart()
                        } else {
                            itemLabel.show = false
                            delayShow.stop()
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        layoutDirection: bottomSwipeArea.edge == MKBottomSwipeArea.Edge.Left ? Qt.RightToLeft : Qt.LeftToRight
                        spacing: units.gu(4)

                        QQC2.Label {
                            id: itemLabel

                            property bool show: false

                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true

                            visible: opacity > 0
                            opacity: show ? 1: 0
                            color: fullScreenItem.theme.fontColor
                            text: quickActionItem.itemText
                            font.pixelSize: bgRec.height * 0.4
                            horizontalAlignment: bottomSwipeArea.edge == MKBottomSwipeArea.Edge.Left ? Text.AlignLeft : Text.AlignRight
                            wrapMode: Text.WordWrap

                            background: Item {
                                readonly property real horizontalPadding: units.gu(2)

                                anchors {
                                    left: bottomSwipeArea.edge == MKBottomSwipeArea.Edge.Left ? parent.left : undefined
                                    right: bottomSwipeArea.edge == MKBottomSwipeArea.Edge.Right ? parent.right : undefined
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
                                    color: fullScreenItem.theme.actionKeyPressedColor
                                    border{
                                        width: fullScreenItem.theme.keyBorderEnabled ? units.gu(0.1) : 0
                                        color: fullScreenItem.theme.keyBorderEnabled ? fullScreenItem.theme.charKeyBorderColor : "transparent"
                                    }
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
                            readonly property real preferredSize: (quickActionsLoader.height / quickActionsLoader.visibleCount) - units.gu(0.5)
                            readonly property real maximumSize: units.gu(6)

                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: preferredSize
                            Layout.preferredHeight: preferredSize
                            Layout.maximumHeight: maximumSize
                            Layout.maximumWidth: maximumSize

                            scale: quickActionItem.highlighted ? 1.5 : 1

                            Behavior on scale { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }

                            Rectangle {
                                id: bgRec
                                color: quickActionItem.highlighted ? fullScreenItem.theme.actionKeyPressedColor : fullScreenItem.theme.actionKeyColor
                                radius: width / 2
                                anchors.fill: parent
                                opacity: 1
                                border{
                                    width: fullScreenItem.theme.keyBorderEnabled ? units.gu(0.1) : 0
                                    color: fullScreenItem.theme.keyBorderEnabled ? fullScreenItem.theme.charKeyBorderColor : "transparent"
                                }
                                Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
                            }

                            Icon {
                                anchors.centerIn: bgRec
                                rotation: quickActionItem.itemIconRotation
                                height: bgRec.height * 0.5
                                width: height
                                name: quickActionItem.itemIcon
                                color: fullScreenItem.theme.fontColor
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
            left: bottomSwipeArea.edge == MKBottomSwipeArea.Edge.Left ? parent.left : undefined
            right: bottomSwipeArea.edge == MKBottomSwipeArea.Edge.Right ? parent.right : undefined
        }
    }
}
// ENH089 - End
