import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
import Lomiri.Components 1.3
import "." as Sapot
import "../.." as Common

Common.BrowserPage {
    id: quickActionsSettingsPage

    property bool selectMode
    property bool dragMode
    property alias model: quickActionsListView.model

    signal modelDataChanged(var newModelData)

    title: i18n.tr("Quick actions")
    showBackAction: !selectMode && !dragMode

    onBack: quickActionsSettingsPage.destroy()
    onSelectModeChanged: if (selectMode) dragMode = false
    onDragModeChanged: if (dragMode) selectMode = false

    leadingActions: [ cancelAction ]
    trailingActions: [ addAction, deleteAction, selectAllAction, selectModeAction, dragModeAction ]

    Action {
        id: cancelAction

        text: i18n.tr("Exit mode")
        iconName: "cancel"
        visible: quickActionsSettingsPage.selectMode || quickActionsSettingsPage.dragMode

        onTriggered: {
            quickActionsSettingsPage.selectMode = false
            quickActionsSettingsPage.dragMode = false
        }
    }

    Action {
        id: selectAllAction

        text: quickActionsListView.allItemsSelected ? i18n.tr("Deselect all") : i18n.tr("Select all")
        iconName: quickActionsListView.allItemsSelected ? "select-none" : "select"
        visible: quickActionsSettingsPage.selectMode

        onTriggered: {
            if (quickActionsListView.allItemsSelected) {
                quickActionsListView.ViewItems.selectedIndices = []
            } else {
                var indices = []
                for (var i = 0; i < quickActionsListView.count; ++i) {
                    indices.push(i)
                }
                quickActionsListView.ViewItems.selectedIndices = indices
            }
        }
    }

    Action {
        id: deleteAction

        text: i18n.tr("Delete items")
        iconName: "delete"
        visible: quickActionsSettingsPage.selectMode && quickActionsListView.ViewItems.selectedIndices.length > 0

        onTriggered: {
            internal.removeItemsFromModel(quickActionsListView.ViewItems.selectedIndices)
            quickActionsListView.ViewItems.selectedIndices = []
            quickActionsSettingsPage.selectMode = false
        }
    }

    Action {
        id: selectModeAction

        text: i18n.tr("Selection mode")
        iconName: "edit"
        visible: !quickActionsSettingsPage.selectMode && quickActionsListView.count > 0

        onTriggered: quickActionsSettingsPage.selectMode = true
    }

    Action {
        id: dragModeAction

        text: i18n.tr("Sort mode")
        iconName: "sort-listitem"
        visible: !quickActionsSettingsPage.dragMode && quickActionsListView.count > 0

        onTriggered: quickActionsSettingsPage.dragMode = true
    }

    Action {
        id: addAction

        text: i18n.tr("Add action")
        iconName: "add"
        visible: !quickActionsSettingsPage.selectMode

        onTriggered: {
            var addDialog = promptDialogComponent.createObject(quickActionsSettingsPage)
            if (quickActionsSettingsPage.displayedInFullWidthPanel) {
                addDialog.openBottom();
            } else {
                addDialog.openNormal();
            }
        }
    }

    Component {
        id: promptDialogComponent

        Sapot.DialogWithContents {
            id: promptDialog

            parent: quickActionsSettingsPage
            title: i18n.tr("Add an action")
            anchorToKeyboard: true

            onAboutToShow: {
                // Only show items that haven't been added yet
                comboBox.model = webapp.allQuickActions.filter( action => !quickActionsSettingsPage.model.find(item => item.id == action.id) )
            }

            function accept(selectedIndex, customUrlSelectedIndex) {
                if (selectedIndex > -1) {
                    let _itemId = ""
                    if (customUrlSelectedIndex === -1) {
                        _itemId = comboBox.model[selectedIndex].id
                    } else {
                        _itemId = comboBox.model[selectedIndex].id + "_" + comboBoxCustomUrl.model[customUrlSelectedIndex].name
                    }
                    internal.addItemToModel(_itemId)
                    promptDialog.close();
                }
            }
            
            QQC2.Label {
                Layout.fillWidth: true

                text: i18n.tr("Select and add from the available quick actions")
                verticalAlignment: Label.AlignVCenter
                horizontalAlignment: Label.AlignHCenter
                wrapMode: Text.WordWrap
            }

            QQC2.ComboBox {
                id: comboBox

                Layout.fillWidth: true
                textRole: "title"
            }

            QQC2.ComboBox {
                id: comboBoxCustomUrl

                visible: comboBox.model ? comboBox.model[comboBox.currentIndex].id === "customUrl" : false
                Layout.fillWidth: true
                textRole: "name"
                model: webapp.settings.customURLActions
            }

            ColumnLayout {
                spacing: units.gu(2)
                Layout.fillWidth: true

                Button {
                    id: saveButton

                    Layout.fillWidth: true
                    text: i18n.tr("Add")
                    color: theme.palette.normal.positive

                    onClicked: promptDialog.accept(comboBox.currentIndex, comboBoxCustomUrl.visible ? comboBoxCustomUrl.currentIndex : -1)
                }

                Button {
                    Layout.fillWidth: true

                    text: i18n.tr("Cancel")
                    onClicked: promptDialog.close();
                }
            }
        }
    }

    ScrollView {
        id: mainScrollView

        anchors.fill: parent

        ListView {
            id: quickActionsListView

            property bool allItemsSelected: ViewItems.selectedIndices.length === count

            anchors.fill: parent
            focus: true

            ViewItems.selectMode: quickActionsSettingsPage.selectMode
            ViewItems.dragMode: quickActionsSettingsPage.dragMode
            ViewItems.onDragUpdated: {
                if (event.status == ListItemDrag.Started) {
                    if (model[event.from] == "Immutable")
                        event.accept = false;
                    return;
                }
                if (model[event.to] == "Immutable") {
                    event.accept = false;
                    return;
                }
                // No instantaneous updates
                if (event.status == ListItemDrag.Moving) {
                    event.accept = false;
                    return;
                }
                if (event.status == ListItemDrag.Dropped) {
                    var fromItem = model[event.from];
                    var list = model;
                    list.splice(event.from, 1);
                    list.splice(event.to, 0, fromItem);
                    quickActionsSettingsPage.modelDataChanged(list);
                }
            }

            delegate: ListItem {
                height: layout.height + (divider.visible ? divider.height : 0)
                color: dragging ? theme.palette.selected.base : "transparent"

                ListItemLayout {
                    id: layout
                    title.text: internal.getTitle(modelData.id)
                }

                onClicked: {
                    if (quickActionsListView.ViewItems.selectMode) {
                        selected = !selected
                    }
                }

                leadingActions: deleteActionList

                ListItemActions {
                    id: deleteActionList
                    actions: [
                        Action {
                            objectName: "leadingAction.delete"
                            iconName: "delete"
                            enabled: true
                            onTriggered: internal.removeItemFromModel(modelData.id)
                        }
                    ]
                }
            }
        }
    }

    Label {
        id: emptyLabel
        anchors.centerIn: parent
        visible: quickActionsListView.count == 0
        wrapMode: Text.Wrap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: i18n.tr("No actions added")
    }

    QtObject {
        id: internal

        function findFromArray(arr, itemId) {
            return arr.find(item => item.id == itemId)
        }

        function getTitle(itemId) {
            let _isCustomUrlAction = itemId.startsWith("customUrl_")
            if (_isCustomUrlAction) {
                return itemId.split("_")[1]
            } else {
                return findFromArray(webapp.allQuickActions, itemId).title
            }
        }

        function addItemToModel(item) {
            let arrNewValues = quickActionsSettingsPage.model.slice()
            arrNewValues.push({ "id": item })
            quickActionsSettingsPage.modelDataChanged(arrNewValues)
        }

        function removeItemFromModel(itemId) {
            let arrNewValues = quickActionsSettingsPage.model.slice()
            arrNewValues.splice(arrNewValues.indexOf(findFromArray(arrNewValues, itemId)), 1)
            quickActionsSettingsPage.modelDataChanged(arrNewValues)
        }

        function removeItemsFromModel(indexList) {
            let arrCurrentValues = quickActionsSettingsPage.model.slice()
            let arrNewValues = quickActionsSettingsPage.model.slice()

            for (var i = 0; i < indexList.length; i++) {
                let index = indexList[i]
                let itemId = arrCurrentValues[index] ? arrCurrentValues[index].id : ""

                if (itemId !== "") {
                    arrNewValues.splice(arrNewValues.indexOf(findFromArray(arrNewValues, itemId)), 1)
                }
            }

            quickActionsSettingsPage.modelDataChanged(arrNewValues)
        }
    }
}

