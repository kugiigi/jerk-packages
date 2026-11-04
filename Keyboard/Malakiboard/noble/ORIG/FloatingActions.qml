import QtQuick 2.9
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import "keys/"

RowLayout {
    id: root

    readonly property bool isWide: width > units.gu(60)

    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: units.gu(1)
        topMargin: toolbar.height + units.gu(1)
    }

    FloatingActionKey {
        id: startLineButton

        Layout.alignment: Qt.AlignLeft
        Layout.preferredWidth: units.gu(5)
        Layout.preferredHeight: units.gu(5)
        action: Action {
            iconName: "go-first"
            onTriggered: {
                if (cursorSwipeArea.selectionMode) {
                    fullScreenItem.selectStartOfLine();
                } else {
                    fullScreenItem.moveToStartOfLine();
                }
            }
        }
    }

    FloatingActionKey {
        id: startDocButton

        iconRotation: 90
        Layout.alignment: Qt.AlignLeft
        Layout.preferredWidth: units.gu(5)
        Layout.preferredHeight: units.gu(5)
        action: Action {
            iconName: "go-first"
            onTriggered: {
                if (cursorSwipeArea.selectionMode) {
                    fullScreenItem.selectStartOfDocument();
                } else {
                    fullScreenItem.moveToStartOfDocument();
                }
            }
        }
    }

    FloatingActionKey {
        id: doneButton

        Layout.alignment: root.isWide ? Qt.AlignLeft : Qt.AlignHCenter
        Layout.fillWidth: root.isWide ? false : true
        Layout.minimumWidth: units.gu(5)
        Layout.preferredWidth: units.gu(7)
        Layout.preferredHeight: units.gu(5)
        keyFeedback: false
        action: Action {
            iconName: "input-keyboard-symbolic"
            onTriggered: {
                fullScreenItem.exitSwipeMode()
            }
        }
    }

    // Spacer
    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        visible: root.isWide
    }

    FloatingActionKey {
        id: rightDoneButton

        Layout.alignment: Qt.AlignRight
        Layout.minimumWidth: units.gu(5)
        Layout.preferredWidth: units.gu(7)
        Layout.preferredHeight: units.gu(5)
        visible: root.isWide
        keyFeedback: false
        action: Action {
            iconName: "input-keyboard-symbolic"
            onTriggered: {
                fullScreenItem.exitSwipeMode()
            }
        }
    }

    FloatingActionKey {
        id: endDocButton

        iconRotation: 90
        Layout.alignment: Qt.AlignRight
        Layout.preferredWidth: units.gu(5)
        Layout.preferredHeight: units.gu(5)
        action: Action {
            iconName: "go-last"
            onTriggered: {
                if (cursorSwipeArea.selectionMode) {
                    fullScreenItem.selectEndOfDocument();
                } else {
                    fullScreenItem.moveToEndOfDocument();
                }
            }
        }
    }

    FloatingActionKey {
        id: endLineButton

        Layout.alignment: Qt.AlignRight
        Layout.preferredWidth: units.gu(5)
        Layout.preferredHeight: units.gu(5)
        action: Action {
            iconName: "go-last"
            onTriggered: {
                if (cursorSwipeArea.selectionMode) {
                    fullScreenItem.selectEndOfLine();
                } else {
                    fullScreenItem.moveToEndOfLine();
                }
            }
        }
    }
}
