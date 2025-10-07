import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
import Lomiri.Components 1.3
import "." as Sapot
import "../.." as Common

Common.BrowserPage {
    id: customUrlActionsPage

    property alias model: customUrlActionsListView.model

    title: i18n.tr("Custom URL Actions")

    onBack: customUrlActionsPage.destroy()

    trailingActions: [ addAction ]

    Action {
        id: addAction

        text: i18n.tr("Add action")
        iconName: "add"

        onTriggered: {
            let _addDialog = addEditCustomURLActionComponent.createObject(customUrlActionsPage)
            _addDialog.add.connect(function(customUrl, customURLName, customURLIcon) {
                    webapp.customURLActions.addToCustomURLActions(customUrl, customURLName, customURLIcon)
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
        id: addEditCustomURLActionComponent

        Sapot.AddEditCustomURLAction {}
    }

    ScrollView {
        id: mainScrollView

        anchors.fill: parent

        ListView {
            id: customUrlActionsListView

            property bool allItemsSelected: ViewItems.selectedIndices.length === count

            anchors.fill: parent
            focus: true

            delegate: ListItem {
                height: layout.height + (divider.visible ? divider.height : 0)
                color: dragging ? theme.palette.selected.base : "transparent"

                ListItemLayout {
                    id: layout
                    title.text: modelData.name
                    
                    Icon {
                        name: modelData.icon
                        SlotsLayout.position: SlotsLayout.Leading;
                        width: units.gu(2)
                        color: theme.palette.normal.backgroundText
                    }
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
                                let _properties = { "editMode": true, "customUrl": modelData.url, "customURLIndex": index, "customURLName": modelData.name, "customURLIcon": modelData.icon }
                                let _editDialog = addEditCustomURLActionComponent.createObject(customUrlActionsPage, _properties)
                                _editDialog.edit.connect(function(customURLIndex, customUrl, customURLName, customURLIcon) {
                                        webapp.customURLActions.editCustomURLAction(customURLIndex, customUrl, customURLName, customURLIcon)
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
                            onTriggered: webapp.customURLActions.deleteFromCustomURLActions(modelData.name)
                        }
                    ]
                }
            }
        }
    }

    Label {
        id: emptyLabel
        anchors.centerIn: parent
        visible: customUrlActionsListView.count == 0
        wrapMode: Text.Wrap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: i18n.tr("No actions added")
    }
}

