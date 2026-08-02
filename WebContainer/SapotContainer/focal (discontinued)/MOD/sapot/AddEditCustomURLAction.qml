import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12

DialogWithContents {
    id: dialogue

    readonly property bool nameIsValid: customURLNameTextField.text.trim() !== ""
                                            && (
                                                    (!editMode && webapp.findFromArray(webapp.settings.customURLActions, "name", currentName) == undefined)
                                                    ||
                                                    (editMode && nameHasChanged && webapp.countFromArray(webapp.settings.customURLActions, "name", currentName) === 0)
                                                    ||
                                                    (editMode && !nameHasChanged && webapp.countFromArray(webapp.settings.customURLActions, "name", currentName) < 2)
                                                )
    readonly property bool nameHasChanged: editMode && customURLName !== currentName
    readonly property bool customUrlIsValid: customUrlTextField.text.trim() !== ""
                                            && (
                                                    (!editMode && webapp.findFromArray(webapp.settings.customURLActions, "url", currentCustomUrl) == undefined)
                                                    ||
                                                    (editMode && customUrlHasChanged && webapp.countFromArray(webapp.settings.customURLActions, "url", currentCustomUrl) === 0)
                                                    ||
                                                    (editMode && !customUrlHasChanged && webapp.countFromArray(webapp.settings.customURLActions, "url", currentCustomUrl) < 2)
                                                )
    readonly property bool customUrlHasChanged: editMode && customUrl !== currentCustomUrl
    property bool editMode: false
    property int customURLIndex
    property url customUrl
    property string customURLName
    property string customURLIcon
    property url currentCustomUrl
    property string currentName
    property string currentIcon: "other-actions"

    signal add(url customUrl, string customURLName, string customURLIcon)
    signal edit(int customURLIndex, url customUrl, string customURLName, string customURLIcon)

    onAdd: close()
    onEdit: close()

    title: editMode ? 'Edit "%1"'.arg(customURLName) : "New Custom URL Action"
    anchorToKeyboard: true

    closePolicy: QQC2.Popup.CloseOnEscape

    Component.onCompleted: {
        if (customUrl) {
            customUrlTextField.text = customUrl
        }
        if (editMode) {
            customURLNameTextField.text = customURLName
            currentName = customURLName
            currentIcon = customURLIcon
            currentCustomUrl = customUrl
        }
    }

    TextField {
        id: customURLNameTextField

        Layout.fillWidth: true
        placeholderText: "Name of the Custom Action"
        inputMethodHints: Qt.ImhNoPredictiveText
        onTextChanged: dialogue.currentName = text
    }

    Label {
        id: errorNameLabel

        Layout.fillWidth: true
        visible: customURLNameTextField.text.trim() !== "" && !dialogue.nameIsValid
        text: "Name already exists"
        color: theme.palette.normal.negative
    }

    TextField {
        id: customUrlTextField

        Layout.fillWidth: true
        placeholderText: "Enter the URL"
        inputMethodHints: Qt.ImhNoPredictiveText
        onTextChanged: dialogue.currentCustomUrl = text
    }

    Label {
        id: errorLabel

        Layout.fillWidth: true
        visible: customUrlTextField.text.trim() !== "" && !dialogue.customUrlIsValid
        text: "URL already exists"
        color: theme.palette.normal.negative
    }

    RowLayout {
        height: units.gu(6)

        Button {
            id: iconButton

            Layout.alignment: Qt.AlignVCenter

            text: "Pick Icon"
            onClicked: {
                let _iconMenu = iconMenuComponent.createObject(QQC2.Overlay.overlay, { caller: iconButton, currentIcon: customURLIconLabel.text } );

                let _iconSelect = function (_iconName) {
                    dialogue.currentIcon = _iconName
                }

                _iconMenu.iconSelected.connect(_iconSelect)
                
                if (webapp.wide) {
                    _iconMenu.openNormal();
                } else {
                    _iconMenu.openBottom();
                }
            }
        }
        Icon {
            id: customURLIconItem
            Layout.preferredWidth: units.gu(3)
            Layout.preferredHeight: units.gu(3)
            name: dialogue.currentIcon
            color: theme.palette.normal.backgroundText
        }
        Label {
            id: customURLIconLabel

            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
            text: dialogue.currentIcon
            wrapMode: Text.WordWrap
        }
    }

    ColumnLayout {
        spacing: units.gu(2)
        Layout.fillWidth: true

        Button {
            Layout.fillWidth: true

            text: dialogue.editMode ? "Save" : "Add"
            color: theme.palette.normal.positive
            enabled: dialogue.nameIsValid && dialogue.customUrlIsValid
            onClicked: {
                let _customURLName = dialogue.currentName
                let _customUrl = dialogue.currentCustomUrl
                let _customURLIcon = dialogue.currentIcon
                if (dialogue.editMode) {
                    dialogue.edit(dialogue.customURLIndex, _customUrl, _customURLName, _customURLIcon)
                } else {
                    dialogue.add(_customUrl, _customURLName, _customURLIcon)
                }
            }
        }

        Button {
            Layout.fillWidth: true

            text: "Cancel"
            onClicked: dialogue.close()
        }
    }

    Component {
        id: iconMenuComponent
        IconSelectorMenu {}
    }
}
