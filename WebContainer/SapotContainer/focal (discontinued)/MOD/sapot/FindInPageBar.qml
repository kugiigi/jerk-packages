import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Layouts 1.12
import "." as Common

Common.BaseToolbar {
    id: findInPageBar

    readonly property alias text: findField.text
    property bool wide: false
    property bool shown: false
    property var findController

    property string shortcutFindNextText
    property string shortcutFindPreviousText

    signal fieldFocused
    signal hide

    leftPadding: 0
    rightPadding: 0
    radius: 0

    onFieldFocusedChanged: if (fieldFocused) forceActiveFocus()

    function focusField() {
        findField.forceActiveFocus()
        findField.selectAll()
    }

    onWideChanged: optionsMenu.close()
    onShownChanged: optionsMenu.close()

    Binding {
        target: findController
        property: "searchText"
        value: shown && findController ? text : ""
    }

    RowLayout {
        id: mainLayout

        spacing: units.gu(1)
        anchors {
            fill: parent
            margins: units.gu(1)
        }

        Common.ToolbarButton {
            Layout.preferredHeight: Layout.preferredWidth
            Layout.preferredWidth: units.gu(4)

            tooltipText: i18n.tr("Close")
            icon.name: "close"

            onClicked: findInPageBar.hide()
        }

        Common.CustomizedTextField {
            id: findField
            
            Layout.fillWidth: true
            Layout.maximumWidth: units.gu(50)

            leftIcon.name: "find"
            placeholderText: i18n.tr("Find in page")
            inputMethodHints: Qt.ImhNoPredictiveText

            onActiveFocusChanged: if (activeFocus) findInPageBar.fieldFocused()

            rightComponent: Component {
                QQC2.Label {
                    id: matchesLabel

                    text: findField.text !== "" && findInPageBar.findController
                                ? i18n.tr("%1 / %2").arg(findInPageBar.findController.activeMatch).arg(findInPageBar.findController.numberOfMatches)
                                : ""
                    horizontalAlignment: Label.AlignRight
                }
            }

            Keys.onReturnPressed: {
                if (event.modifiers & Qt.ShiftModifier) {
                    findInPageBar.findController.previous()
                } else {
                    findInPageBar.findController.next()
                }
            }
        }

        Common.ToolbarButton {
            Layout.preferredHeight: Layout.preferredWidth
            Layout.preferredWidth: units.gu(4)

            tooltipText: i18n.tr("%1 (%2)").arg(i18n.tr("Find the previous result")).arg(findInPageBar.shortcutFindPreviousText)
            icon.name: "go-up"
            enabled: findField.text !== ""

            onClicked: findInPageBar.findController.previous()
        }

        Common.ToolbarButton {
            Layout.preferredHeight: Layout.preferredWidth
            Layout.preferredWidth: units.gu(4)

            tooltipText: i18n.tr("%1 (%2)").arg(i18n.tr("Find the next result")).arg(findInPageBar.shortcutFindNextText)
            icon.name: "go-down"
            enabled: findField.text !== ""

            onClicked: findInPageBar.findController.next()
        }

        Common.ToolbarButton {
            id: moreOptionsButton

            Layout.preferredHeight: Layout.preferredWidth
            Layout.preferredWidth: units.gu(4)

            visible: !findInPageBar.wide
            tooltipText: i18n.tr("More options")
            icon.name: "contextual-menu"

            onClicked: optionsMenu.show("", moreOptionsButton)
        }

        RowLayout {
            id: optionsLayout

            visible: findInPageBar.wide
            spacing: mainLayout.spacing

            Common.CheckBox {
                id: caseSensitiveCheckBox

                tooltipText: i18n.tr("Find with case sensitivity")
                text: i18n.tr("Case sensitive")
                onCheckedChanged: findInPageBar.findController.isCaseSensitive = !findInPageBar.findController.isCaseSensitive
                Binding {
                    target: caseSensitiveCheckBox
                    property: "checked"
                    value: findInPageBar.findController.isCaseSensitive
                }
            }
        }

        Item {
            Layout.fillWidth: true
            visible: findInPageBar.wide
        }
    }

    Common.AdvancedMenu {
        id: optionsMenu

        focus: false
        type: Common.AdvancedMenu.Type.BottomAttached
        
        ColumnLayout {

            anchors {
                left: parent.left
                right: parent.right
                leftMargin: units.gu(1)
                rightMargin: anchors.leftMargin
            }

            Common.CheckBox {
                id: caseSensitiveCheckBox2

                Layout.fillWidth: true
                Layout.preferredHeight: units.gu(6)
                tooltipText: caseSensitiveCheckBox.tooltipText
                text: caseSensitiveCheckBox.text
                onCheckedChanged: caseSensitiveCheckBox.checked = checked
                Binding {
                    target: caseSensitiveCheckBox2
                    property: "checked"
                    value: findInPageBar.findController.isCaseSensitive
                }
            }
        }
    }
}

