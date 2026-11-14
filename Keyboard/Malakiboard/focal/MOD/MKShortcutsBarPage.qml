import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
import Lomiri.Components 1.3
import QtQuick.Controls.Suru 2.2

MKBasePage {
    id: root

    property bool selectMode
    property bool dragMode
    property alias model: shortcutActionsListView.model

    signal modelDataChanged(var newModelData)

    showBackButton: !cancelAction.visible
    headerLeftActions: [ cancelAction ]
    headerRightActions: [ addAction, deleteAction, selectAllAction, selectModeAction, dragModeAction ]

    onSelectModeChanged: if (selectMode) dragMode = false
    onDragModeChanged: if (dragMode) selectMode = false

    MKBaseAction {
        id: cancelAction

        text: i18n.tr("Exit mode")
        tooltipText: root.selectMode ? i18n.tr("Exit selection mode") : i18n.tr("Exit sort mode")
        iconName: "close"
        visible: root.selectMode || root.dragMode

        onTrigger: {
            root.selectMode = false
            root.dragMode = false
        }
    }

    MKBaseAction {
        id: selectAllAction

        text: shortcutActionsListView.allItemsSelected ? i18n.tr("Deselect all") : i18n.tr("Select all")
        tooltipText: shortcutActionsListView.allItemsSelected ? i18n.tr("Deselect all items") : i18n.tr("Select all items")
        iconName: shortcutActionsListView.allItemsSelected ? "select-none" : "select"
        visible: root.selectMode

        onTrigger: {
            if (shortcutActionsListView.allItemsSelected) {
                shortcutActionsListView.ViewItems.selectedIndices = []
            } else {
                var indices = []
                for (var i = 0; i < shortcutActionsListView.count; ++i) {
                    indices.push(i)
                }
                shortcutActionsListView.ViewItems.selectedIndices = indices
            }
        }
    }

    MKBaseAction {
        id: deleteAction

        text: i18n.tr("Delete items")
        tooltipText: i18n.tr("Delete selected items")
        iconName: "delete"
        visible: root.selectMode && shortcutActionsListView.ViewItems.selectedIndices.length > 0

        onTrigger: {
            internal.removeItemsFromModel(shortcutActionsListView.ViewItems.selectedIndices)
            shortcutActionsListView.ViewItems.selectedIndices = []
            root.selectMode = false
        }
    }

    MKBaseAction {
        id: selectModeAction

        text: i18n.tr("Selection mode")
        tooltipText: i18n.tr("Enter selection mode")
        iconName: "edit"
        visible: !root.selectMode && shortcutActionsListView.count > 0

        onTrigger: root.selectMode = true
    }

    MKBaseAction {
        id: dragModeAction

        text: i18n.tr("Sort mode")
        tooltipText: i18n.tr("Enter sort moode")
        iconName: "sort-listitem"
        visible: !root.dragMode && shortcutActionsListView.count > 0

        onTrigger: root.dragMode = true
    }

    MKBaseAction {
        id: addAction

        text: i18n.tr("Add action")
        tooltipText: i18n.tr("Add an action to the list")
        iconName: "add"
        visible: !root.selectMode

        onTrigger: {
            var addDialog = promptDialogComponent.createObject(root)
            if (root.displayedInFullWidthPanel) {
                addDialog.openBottom();
            } else {
                addDialog.openNormal();
            }
        }
    }

    Component {
        id: promptDialogComponent

        MKDialogWithContents {
            id: promptDialog

            title: i18n.tr("Add an action")
            anchorToKeyboard: true

            onAboutToShow: {
                // Only show items that haven't been added yet
                comboBox.model = fullScreenItem.allQuickActions.filter( action => !root.model.find(item => item.id == action.id) )
            }

            function accept(selectedIndex) {
                if (selectedIndex > -1) {
                    internal.addItemToModel(comboBox.model[selectedIndex].id)
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

            ColumnLayout {
                spacing: units.gu(2)
                Layout.fillWidth: true

                Button {
                    id: saveButton

                    Layout.fillWidth: true
                    text: i18n.tr("Add")
                    color: theme.palette.normal.positive

                    onClicked: promptDialog.accept(comboBox.currentIndex)
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
            id: shortcutActionsListView

            property bool allItemsSelected: ViewItems.selectedIndices.length === count

            anchors.fill: parent
            focus: true

            ViewItems.selectMode: root.selectMode
            ViewItems.dragMode: root.dragMode
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
                    root.modelDataChanged(list);
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
                    if (shortcutActionsListView.ViewItems.selectMode) {
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
        visible: shortcutActionsListView.count == 0
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
            return findFromArray(fullScreenItem.allQuickActions, itemId).title
        }

        function addItemToModel(item) {
            let arrNewValues = root.model.slice()
            arrNewValues.push({ "id": item })
            root.modelDataChanged(arrNewValues)
        }

        function removeItemFromModel(itemId) {
            let arrNewValues = root.model.slice()
            arrNewValues.splice(arrNewValues.indexOf(findFromArray(arrNewValues, itemId)), 1)
            root.modelDataChanged(arrNewValues)
        }

        function removeItemsFromModel(indexList) {
            let arrCurrentValues = root.model.slice()
            let arrNewValues = root.model.slice()

            for (var i = 0; i < indexList.length; i++) {
                let index = indexList[i]
                let itemId = arrCurrentValues[index] ? arrCurrentValues[index].id : ""

                if (itemId !== "") {
                    arrNewValues.splice(arrNewValues.indexOf(findFromArray(arrNewValues, itemId)), 1)
                }
            }

            root.modelDataChanged(arrNewValues)
        }
    }

}
