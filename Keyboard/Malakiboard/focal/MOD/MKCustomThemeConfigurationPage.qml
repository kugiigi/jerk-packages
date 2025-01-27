// ENH082 - Custom theme
import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
import Lomiri.Components 1.3
import QtQuick.Controls.Suru 2.2

MKSettingsPage {
    id: root

    property bool isEditMode: false
    property var itemData
    property int itemIndex: -1
    property string oldName

    headerRightActions: [ saveAction ]

    signal save(var modelData)
    signal edit(var modelData, int itemIndex, bool nameChanged, string oldName)

    Component.onCompleted: {
        oldName = itemData.name
    }

    MKBaseAction {
        id: saveAction

        text: i18n.tr("Save")
        tooltipText: i18n.tr("Save custom theme")
        iconName: "save"

        onTrigger: {
            if (isEditMode) {
                let _nameChanged = root.oldName !== root.itemData.name
                root.edit(root.itemData, root.itemIndex, _nameChanged, oldName)
            } else {
                root.save(root.itemData)
            }
            settingsLoader.item.stack.pop()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.margins: units.gu(2)

        Label {
            id: nameLabel

            Layout.fillWidth: true
            textSize: Label.Large

            onTextChanged: {
                let temp = root.itemData
                temp.name = text
                root.itemData = temp
            }

            Binding {
                target: nameLabel
                property: "text"
                value: root.itemData.name
            }
        }

        QQC2.Button {
            Layout.preferredWidth: units.gu(4)
            implicitHeight: width
            indicator: Icon {
                name: "edit-paste"
                width: units.gu(2)
                height: width
                color: Suru.foregroundColor
                anchors.centerIn: parent
            }
            onClicked: {
                let _text = (input_method.surroundingLeft + input_method.surroundingRight).trim()
                if (_text !== "") {
                    nameLabel.text = _text
                } else {
                    tooltip.display(i18n.tr("This copies the current text field text as theme name"))
                }
            }
        }
    }

    OptionSelector {
        Layout.fillWidth: true
        Layout.margins: units.gu(2)

        text: i18n.tr("Base Theme")
        model: [
            "Lomiri.Components.Themes.Ambiance"
            , "Lomiri.Components.Themes.SuruDark"
        ]
        containerHeight: itemHeight * 6
        selectedIndex: model.indexOf(root.itemData.toolkitTheme)
        onSelectedIndexChanged: {
            let temp = root.itemData
            temp.toolkitTheme = model[selectedIndex]
            root.itemData = temp
        }
    }
    MKColorField {
        id: fontColor
        Layout.fillWidth: true
        Layout.margins: units.gu(2)
        title: "Font color"
        onTextChanged: {
            let temp = root.itemData
            temp.fontColor = text
            root.itemData = temp
        }
        onColorPicker: colorPickerLoader.open(fontColor)
        Binding {
            target: fontColor
            property: "text"
            value: root.itemData.fontColor
        }
    }
    MKColorField {
        id: selectionColor
        Layout.fillWidth: true
        Layout.margins: units.gu(2)
        title: "Selection color"
        onTextChanged: {
            let temp = root.itemData
            temp.selectionColor = text
            root.itemData = temp
        }
        onColorPicker: colorPickerLoader.open(selectionColor)
        Binding {
            target: selectionColor
            property: "text"
            value: root.itemData.selectionColor
        }
    }
    MKColorField {
        id: backgroundColor
        Layout.fillWidth: true
        Layout.margins: units.gu(2)
        title: "Background color"
        onTextChanged: {
            let temp = root.itemData
            temp.backgroundColor = text
            root.itemData = temp
        }
        onColorPicker: colorPickerLoader.open(backgroundColor)
        Binding {
            target: backgroundColor
            property: "text"
            value: root.itemData.backgroundColor
        }
    }
    MKColorField {
        id: dividerColor
        Layout.fillWidth: true
        Layout.margins: units.gu(2)
        title: "Divider color"
        onTextChanged: {
            let temp = root.itemData
            temp.dividerColor = text
            root.itemData = temp
        }
        onColorPicker: colorPickerLoader.open(dividerColor)
        Binding {
            target: dividerColor
            property: "text"
            value: root.itemData.dividerColor
        }
    }
    MKColorField {
        id: annotationFontColor
        Layout.fillWidth: true
        Layout.margins: units.gu(2)
        title: "Annotation font color"
        onTextChanged: {
            let temp = root.itemData
            temp.annotationFontColor = text
            root.itemData = temp
        }
        onColorPicker: colorPickerLoader.open(annotationFontColor)
        Binding {
            target: annotationFontColor
            property: "text"
            value: root.itemData.annotationFontColor
        }
    }
    MKColorField {
        id: charKeyColor
        Layout.fillWidth: true
        Layout.margins: units.gu(2)
        title: "Character keys color"
        onTextChanged: {
            let temp = root.itemData
            temp.charKeyColor = text
            root.itemData = temp
        }
        onColorPicker: colorPickerLoader.open(charKeyColor)
        Binding {
            target: charKeyColor
            property: "text"
            value: root.itemData.charKeyColor
        }
    }
    MKColorField {
        id: charKeyPressedColor
        Layout.fillWidth: true
        Layout.margins: units.gu(2)
        title: "Character keys pressed color"
        onTextChanged: {
            let temp = root.itemData
            temp.charKeyPressedColor = text
            root.itemData = temp
        }
        onColorPicker: colorPickerLoader.open(charKeyPressedColor)
        Binding {
            target: charKeyPressedColor
            property: "text"
            value: root.itemData.charKeyPressedColor
        }
    }
    MKColorField {
        id: actionKeyColor
        Layout.fillWidth: true
        Layout.margins: units.gu(2)
        title: "Action keys color"
        onTextChanged: {
            let temp = root.itemData
            temp.actionKeyColor = text
            root.itemData = temp
        }
        onColorPicker: colorPickerLoader.open(actionKeyColor)
        Binding {
            target: actionKeyColor
            property: "text"
            value: root.itemData.actionKeyColor
        }
    }
    MKColorField {
        id: actionKeyPressedColor
        Layout.fillWidth: true
        Layout.margins: units.gu(2)
        title: "Action keys pressed color"
        onTextChanged: {
            let temp = root.itemData
            temp.actionKeyPressedColor = text
            root.itemData = temp
        }
        onColorPicker: colorPickerLoader.open(actionKeyPressedColor)
        Binding {
            target: actionKeyPressedColor
            property: "text"
            value: root.itemData.actionKeyPressedColor
        }
    }
    MKColorField {
        id: popupBorderColor
        Layout.fillWidth: true
        Layout.margins: units.gu(2)
        title: "Key popup border color"
        onTextChanged: {
            let temp = root.itemData
            temp.popupBorderColor = text
            root.itemData = temp
        }
        onColorPicker: colorPickerLoader.open(popupBorderColor)
        Binding {
            target: popupBorderColor
            property: "text"
            value: root.itemData.popupBorderColor
        }
    }
    QQC2.CheckDelegate {
        id: keyBorderEnabled
        Layout.fillWidth: true
        text: "Enable key borders"
        onCheckedChanged: {
            let temp = root.itemData
            temp.keyBorderEnabled = checked
            root.itemData = temp
        }
        Binding {
            target: keyBorderEnabled
            property: "checked"
            value: root.itemData.keyBorderEnabled
        }
    }
    MKColorField {
        id: charKeyBorderColor
        Layout.fillWidth: true
        Layout.margins: units.gu(2)
        title: "Character keys border color"
        onTextChanged: {
            let temp = root.itemData
            temp.charKeyBorderColor = text
            root.itemData = temp
        }
        onColorPicker: colorPickerLoader.open(charKeyBorderColor)
        Binding {
            target: charKeyBorderColor
            property: "text"
            value: root.itemData.charKeyBorderColor
        }
    }
    MKColorField {
        id: actionKeyBorderColor
        Layout.fillWidth: true
        Layout.margins: units.gu(2)
        title: "Action keys border color"
        onTextChanged: {
            let temp = root.itemData
            temp.actionKeyBorderColor = text
            root.itemData = temp
        }
        onColorPicker: colorPickerLoader.open(actionKeyBorderColor)
        Binding {
            target: actionKeyBorderColor
            property: "text"
            value: root.itemData.actionKeyBorderColor
        }
    }
}
