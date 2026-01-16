import QtQuick 2.9
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Controls.Suru 2.2

QQC2.Dialog {
    id: baseDialog

    // Space available for the actual dialog
    readonly property real availableVerticalSpace: anchorToKeyboard ? parent.height - keyboardRectangle.height - bottomMargin
                                                                    : parent.height

    property real maximumWidth: units.gu(40)
    property real preferredWidth: parent.width * 0.80
    property bool anchorToKeyboard: false
    property alias keyboardRectangle: osk

    bottomMargin: units.gu(2)
    width: Math.min(preferredWidth, maximumWidth)

    x: (parent.width - width) / 2
    parent: QQC2.ApplicationWindow.overlay

    modal: true
    focus: true

    standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel

    function openBottom() {
        y = Qt.binding(function(){ return (parent.height - height - bottomMargin) - (baseDialog.anchorToKeyboard ? osk.height : 0) })
        open()
    }

    function openNormal() {
        y = Qt.binding(function(){ return ((parent.height - height) / 2) - (baseDialog.anchorToKeyboard ? osk.height : 0) })
        open()
    }

    header: QQC2.Label {
        text: baseDialog.title
        visible: baseDialog.title
        elide: QQC2.Label.ElideRight
        horizontalAlignment: Text.AlignHCenter
        topPadding: units.gu(3)
        leftPadding: units.gu(2)
        rightPadding: Suru.units.gu(2)

        Suru.textLevel: Suru.HeadingThree
        Suru.textStyle: Suru.PrimaryText
    }

    Item {
        id: osk

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        opacity: 1

        // We need to get the values of kayboardRectangle without HIDPI applied
        // To do this we take gridUnit and devide by DEFAULT_GRID_UNIT_PX (8)
        height: Qt.inputMethod.visible ?
                Qt.inputMethod.keyboardRectangle.height / (units.gridUnit / 8) : 0

        Behavior on height {
            LomiriNumberAnimation {}
        }

        states: [
            State {
                name: "hidden"
                when: osk.height == 0
            },
            State {
                name: "shown"
                when: osk.height == Qt.inputMethod.keyboardRectangle.height / (units.gridUnit / 8)
            }
        ]

        function recursiveFindFocusedItem(parent) {
            if (parent.activeFocus) {
                return parent;
            }

            for (var i in parent.children) {
                var child = parent.children[i];
                if (child.activeFocus) {
                    return child;
                }

                var item = recursiveFindFocusedItem(child);

                if (item != null) {
                    return item;
                }
            }

            return null;
        }

        Connections {
            target: Qt.inputMethod

            onVisibleChanged: {
                if (!Qt.inputMethod.visible) {
                    var focusedItem = recursiveFindFocusedItem(osk.parent);
                    if (focusedItem != null) {
                        focusedItem.focus = false;
                    }
                }
            }
        }
    }

}
