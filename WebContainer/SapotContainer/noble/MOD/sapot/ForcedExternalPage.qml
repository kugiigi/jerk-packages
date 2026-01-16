import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
import Lomiri.Components 1.3
import "." as Sapot
import "../.." as Common

Common.BrowserPage {
    id: root

    property alias model: listView.model

    title: i18n.tr("URL forced as external")

    onBack: root.destroy()

    trailingActions: [ addAction ]

    Action {
        id: addAction

        text: i18n.tr("Add action")
        iconName: "add"

        onTriggered: {
            let _addDialog = addEditComponent.createObject(root)
            _addDialog.add.connect(function(_url) {
                    let _arrNewValues = webapp.settings.internalDomainsAsExternal.slice()
                    _arrNewValues.push(_url)
                    webapp.settings.internalDomainsAsExternal = _arrNewValues
                }
            )
            if (webapp.wide) {
                _addDialog.openNormal();
            } else {
                _addDialog.openBottom();
            }
        }
    }

    Component {
        id: addEditComponent

        DialogWithContents {
            id: dialogue

            readonly property bool customUrlIsValid: customUrlTextField.text.trim() !== ""
                                                    && (
                                                            (!editMode && webapp.findFromArray(webapp.settings.internalDomainsAsExternal, "", currentCustomUrl) == undefined)
                                                            ||
                                                            (editMode && customUrlHasChanged && webapp.countFromArray(webapp.settings.internalDomainsAsExternal, "", currentCustomUrl) === 0)
                                                            ||
                                                            (editMode && !customUrlHasChanged && webapp.countFromArray(webapp.settings.internalDomainsAsExternal, "", currentCustomUrl) < 2)
                                                        )
            readonly property bool customUrlHasChanged: editMode && customUrl !== currentCustomUrl
            property bool editMode: false
            property int customURLIndex
            property string customUrl: ""
            property string currentCustomUrl: ""

            signal add(url customUrl)
            signal edit(int customURLIndex, url customUrl)

            onAdd: close()
            onEdit: close()

            title: editMode ? "Edit URL" : "New URL"
            anchorToKeyboard: true

            closePolicy: QQC2.Popup.CloseOnEscape

            Component.onCompleted: {
                if (customUrl) {
                    customUrlTextField.text = customUrl
                }
                if (editMode) {
                    currentCustomUrl = customUrl
                }

                customUrlTextField.forceActiveFocus()
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

            ColumnLayout {
                spacing: units.gu(2)
                Layout.fillWidth: true

                Button {
                    Layout.fillWidth: true

                    text: dialogue.editMode ? "Save" : "Add"
                    color: theme.palette.normal.positive
                    enabled: dialogue.customUrlIsValid
                    onClicked: {
                        let _customUrl = dialogue.currentCustomUrl

                        if (dialogue.editMode) {
                            dialogue.edit(dialogue.customURLIndex, _customUrl)
                        } else {
                            dialogue.add(_customUrl)
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true

                    text: "Cancel"
                    onClicked: dialogue.close()
                }
            }
        }

    }

    ScrollView {
        id: mainScrollView

        anchors.fill: parent

        ListView {
            id: listView

            property bool allItemsSelected: ViewItems.selectedIndices.length === count

            anchors.fill: parent
            focus: true

            delegate: ListItem {
                height: layout.height + (divider.visible ? divider.height : 0)
                color: dragging ? theme.palette.selected.base : "transparent"

                ListItemLayout {
                    id: layout
                    title.text: modelData
                }

                trailingActions: trailingActionList

                ListItemActions {
                    id: trailingActionList
                    actions: [
                        Action {
                            id: editAction

                            text: i18n.tr("Edit action")
                            iconName: "edit"

                            onTriggered: {
                                let _properties = { "editMode": true, "customUrl": modelData, "customURLIndex": index }
                                let _editDialog = addEditComponent.createObject(root, _properties)
                                _editDialog.edit.connect(function(customURLIndex, customUrl) {
                                        webapp.customURLActions.editCustomURLAction(customURLIndex, customUrl)
                                        let _tempArr = webapp.settings.internalDomainsAsExternal.slice()
                                        _tempArr[customURLIndex] = customUrl
                                        webapp.settings.internalDomainsAsExternal = _tempArr.slice()
                                    }
                                )
                                if (webapp.wide) {
                                    _editDialog.openNormal();
                                } else {
                                    _editDialog.openBottom();
                                }
                            }
                        }
                    ]
                }

                leadingActions: deleteActionList

                ListItemActions {
                    id: deleteActionList
                    actions: [
                        Action {
                            objectName: "leadingAction.delete"
                            iconName: "delete"
                            enabled: true
                            onTriggered: {
                                let _arrNewValues = webapp.settings.internalDomainsAsExternal.slice()
                                _arrNewValues.splice(index, 1)
                                webapp.settings.internalDomainsAsExternal = _arrNewValues
                            }
                        }
                    ]
                }
            }
        }
    }

    Label {
        id: emptyLabel
        anchors.centerIn: parent
        visible: listView.count == 0
        wrapMode: Text.Wrap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: i18n.tr("List is empty")
    }
}

