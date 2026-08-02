// ENH215 - Shortcuts bar
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.3
import "keys"

RowLayout {
    id: root

    readonly property int visibleCount: visibleChildren.length - 2 // Deduct the row layout of the overflow button and spacer item
    property real buttonMinimumWidth: units.gu(4)

    property list<MKBaseAction> actions
    property bool isOverflow: {
        let _minimumPossibleWidth = visibleCount * buttonMinimumWidth
        let _width = width

        return _minimumPossibleWidth > _width
    }
    property int overflowIndex: {
        if (!isOverflow) return -1

        return Math.floor(width / buttonMinimumWidth) - 1
    }

    spacing: 0

    onVisibleChanged: if (!visible) overflowMenuLoader.close()

    Loader {
        id: overflowMenuLoader

        active: false
        asynchronous: true

        function open() {
            active = true
        }

        function close() {
            if (item) {
                item.close()
            } else {
                active = false
            }
        }

        onLoaded: item.open()

        sourceComponent: QQC2.Popup {
            id: popup

            padding: 0
            background: Rectangle {
                color: fullScreenItem.theme.backgroundColor
            }
            width: root.width
            height: gridLayout.height
            closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnReleaseOutside
            transformOrigin: Item.Top
            enter: Transition {
                LomiriNumberAnimation { property: "opacity"; from: 0; to: 1 }
                LomiriNumberAnimation { property: "y"; from: 0; to: root.height }
            }
            exit: Transition {
                LomiriNumberAnimation { property: "opacity"; from: 1; to: 0 }
                LomiriNumberAnimation { property: "y"; from: root.height; to: 0 }
            }

            onClosed: overflowMenuLoader.active = false

            GridLayout {
                id: gridLayout

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                layoutDirection: root.layoutDirection
                columns: Math.floor(width / root.buttonMinimumWidth)
                columnSpacing: 0
                rowSpacing: 0

                Repeater {
                    visible: false // So it won't be included in visible count
                    model: root.actions
                    delegate: ActionsToolbarButton {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: preferredWidth
                        Layout.minimumWidth: minimumWidth
                        Layout.maximumWidth: maximumWidth
                        Layout.preferredHeight: forceHide ? 0 : root.height
                        Layout.maximumHeight: root.height
                        Layout.fillWidth: true

                        customAction: modelData
                        forceHide: root.isOverflow && index < root.overflowIndex
                        minimumWidth: root.buttonMinimumWidth
                    }
                }

                // Spacer
                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }

    Repeater {
        visible: false // So it won't be included in visible count
        model: root.actions
        delegate: ActionsToolbarButton {
            Layout.preferredWidth: preferredWidth
            Layout.minimumWidth: minimumWidth
            Layout.maximumWidth: maximumWidth
            Layout.fillHeight: true
            Layout.fillWidth: true

            customAction: modelData
            forceHide: root.isOverflow && index >= root.overflowIndex
            minimumWidth: root.buttonMinimumWidth
        }
    }

    RowLayout {
        ActionsToolbarButton {
            id: overflowButton

            Layout.preferredWidth: preferredWidth
            Layout.minimumWidth: minimumWidth
            Layout.maximumWidth: maximumWidth
            Layout.fillHeight: true
            Layout.fillWidth: true

            visible: root.isOverflow
            minimumWidth: root.buttonMinimumWidth
            customAction: MKBaseAction {
                id: overflowAction

                visible: root.isOverflow
                text: i18n.tr("More")
                iconName: "contextual-menu"
                checked: overflowMenuLoader.item && overflowMenuLoader.item.opened // ? true : false
                checkable: true
                onTrigger: {
                    if (!overflowMenuLoader.active || (overflowMenuLoader.item && !overflowMenuLoader.item.opened)) {
                        overflowMenuLoader.open()
                    } else {
                        overflowMenuLoader.close()
                    }
                }
            }
        }
    }

    // Spacer
    Item {
        Layout.fillWidth: true
    }
}
