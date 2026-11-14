// ENH082 - Custom theme
import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
import Lomiri.Components 1.3
import QtQuick.Controls.Suru 2.2

MKBasePage {
    id: customThemesPage

    property bool selectMode
    property alias model: customThemesListView.model
    property int count: model.length

    signal modelDataChanged(var newModelData)

    showBackButton: !cancelAction.visible
    headerLeftActions: [ cancelAction ]
    headerRightActions: [ addAction, deleteAction, selectAllAction, selectModeAction ]

    MKBaseAction {
        id: cancelAction

        text: i18n.tr("Exit mode")
        tooltipText: i18n.tr("Exit selection mode")
        iconName: "close"
        visible: customThemesPage.selectMode

        onTrigger: {
            customThemesPage.selectMode = false
        }
    }

    MKBaseAction {
        id: selectAllAction

        text: customThemesListView.allItemsSelected ? i18n.tr("Deselect all") : i18n.tr("Select all")
        tooltipText: customThemesListView.allItemsSelected ? i18n.tr("Deselect all items") : i18n.tr("Select all items")
        iconName: customThemesListView.allItemsSelected ? "select-none" : "select"
        visible: customThemesPage.selectMode

        onTrigger: {
            if (customThemesListView.allItemsSelected) {
                customThemesListView.ViewItems.selectedIndices = []
            } else {
                var indices = []
                for (var i = 0; i < customThemesListView.count; ++i) {
                    indices.push(i)
                }
                customThemesListView.ViewItems.selectedIndices = indices
            }
        }
    }

    MKBaseAction {
        id: deleteAction

        text: i18n.tr("Delete items")
        tooltipText: i18n.tr("Delete selected items")
        iconName: "delete"
        visible: customThemesPage.selectMode && customThemesListView.ViewItems.selectedIndices.length > 0

        onTrigger: {
            internal.removeItemsFromModel(customThemesListView.ViewItems.selectedIndices)
            customThemesListView.ViewItems.selectedIndices = []
            customThemesPage.selectMode = false
        }
    }

    MKBaseAction {
        id: selectModeAction

        text: i18n.tr("Selection mode")
        tooltipText: i18n.tr("Enter selection mode")
        iconName: "edit"
        visible: !customThemesPage.selectMode && customThemesListView.count > 0

        onTrigger: customThemesPage.selectMode = true
    }

    MKBaseAction {
        id: addAction

        text: i18n.tr("Add action")
        tooltipText: i18n.tr("Add new custom theme")
        iconName: "add"
        visible: !customThemesPage.selectMode

        onTrigger: {
            var addDialog = promptDialogComponent.createObject(customThemesPage)
            if (customThemesPage.displayedInFullWidthPanel) {
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

            title: i18n.tr("Select the base theme")
            anchorToKeyboard: true
            contentSpacing: 0

            function accept(itemData) {
                let _name = i18n.tr("Custom theme ") + (customThemesPage.count + 1)
                let _obj = itemData
                _obj.name = _name
                settingsLoader.item.stack.push(configPage, { "title": i18n.tr("New custom theme"), "itemData": _obj })
                promptDialog.close();
            }

            Repeater {
                Layout.fillWidth: true

                model: [
                    { "name": i18n.tr("Ambiance"), "data": customThemesPage.themeAmbianceData }
                    , { "name": i18n.tr("Suru Dark"), "data": customThemesPage.themeSuruDarkData }
                    , { "name": i18n.tr("Suru Black"), "data": customThemesPage.themeSuruBlackData }
                    , { "name": i18n.tr("Bordered Black"), "data": customThemesPage.themeBorderedBlackData }
                    , { "name": i18n.tr("Bordered Grey"), "data": customThemesPage.themeBorderedGreyData }
                    , { "name": i18n.tr("Bordered White"), "data": customThemesPage.themeBorderedWhiteData }
                    , { "name": i18n.tr("Just Black"), "data": customThemesPage.themeJustBlackData }
                    , { "name": i18n.tr("Just Grey"), "data": customThemesPage.themeJustGreyData }
                    , { "name": i18n.tr("Just White"), "data": customThemesPage.themeJustWhiteData }
                ]

                delegate: ListItem {
                    Layout.fillWidth: true
                    Layout.preferredHeight: units.gu(6)

                    SlotsLayout {
                        padding.top: units.gu(1.5)
                        padding.bottom: units.gu(1.5)
                        mainSlot: QQC2.Label {
                            text: modelData.name
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    onClicked: accept(modelData.data)
                }
            }
        }
    }
    
    Component {
        id: configPage

        MKCustomThemeConfigurationPage {
            onSave: {
                let _arr = customThemesPage.model.slice()
                let _newName = fullScreenItem.customThemeCode + modelData.name
                let _exists = fullScreenItem.findFromArray(_arr, "name", _newName)

                if (_exists) {
                    _newName += "_DUP"
                }
                modelData.name = _newName
                _arr.push(modelData)
                customThemesPage.modelDataChanged(_arr)
            }
            onEdit: {
                let _arr = customThemesPage.model.slice()
                let _oldName = fullScreenItem.customThemeCode + oldName
                let _newName = fullScreenItem.customThemeCode + modelData.name
                let _count = fullScreenItem.countFromArray(_arr, "name", _newName)

                if ((nameChanged && _count === 1) || (!nameChanged && _count > 1)) {
                    _newName += "_DUP"
                }

                // Update name if they the them was set to any settings
                if (nameChanged) {
                    if (fullScreenItem.settings.lightTheme === _oldName) {
                        fullScreenItem.settings.lightTheme = _newName
                    }
                    if (fullScreenItem.settings.darkTheme === _oldName) {
                        fullScreenItem.settings.darkTheme = _newName
                    }
                    if (fullScreenItem.settings.customTheme === _oldName) {
                        fullScreenItem.settings.customTheme = _newName
                    }
                }

                modelData.name = _newName
                _arr[itemIndex] = modelData
                customThemesPage.modelDataChanged(_arr)
            }
        }
    }

    ScrollView {
        id: mainScrollView

        anchors.fill: parent

        ListView {
            id: customThemesListView

            property bool allItemsSelected: ViewItems.selectedIndices.length === count

            anchors.fill: parent
            focus: true

            ViewItems.selectMode: customThemesPage.selectMode

            delegate: ListItem {
                height: layout.height + (divider.visible ? divider.height : 0)
                color: "transparent"

                ListItemLayout {
                    id: layout
                    title.text: modelData.name.replace(fullScreenItem.customThemeCode, "")
                }

                onClicked: {
                    if (customThemesListView.ViewItems.selectMode) {
                        selected = !selected
                    }
                }

                trailingActions: rightActionList
                leadingActions: deleteActionList

                ListItemActions {
                    id: rightActionList
                    actions: [
                        Action {
                            iconName: "edit"
                            enabled: true
                            onTriggered: {
                                let _obj = modelData
                                _obj.name = _obj.name.replace(fullScreenItem.customThemeCode, "")
                                settingsLoader.item.stack.push(configPage, { "title": i18n.tr("Edit custom theme")
                                                , "itemData": _obj
                                                , "isEditMode": true
                                                , "itemIndex": index })
                            }
                        }
                    ]
                }
                ListItemActions {
                    id: deleteActionList
                    actions: [
                        Action {
                            objectName: "leadingAction.delete"
                            iconName: "delete"
                            enabled: true
                            onTriggered: internal.removeItemFromModel(modelData.name)
                        }
                    ]
                }
            }
        }
    }

    Label {
        id: emptyLabel
        anchors.centerIn: parent
        visible: customThemesListView.count == 0
        wrapMode: Text.Wrap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: i18n.tr("No custom theme yet")
    }

    QtObject {
        id: internal

        function findFromArray(arr, itemName) {
            return arr.find(item => item.name == itemName)
        }

        function addItemToModel(item) {
            let arrNewValues = customThemesPage.model.slice()
            arrNewValues.push(item)
            customThemesPage.modelDataChanged(arrNewValues)
        }

        function removeItemFromModel(itemName) {
            let arrNewValues = customThemesPage.model.slice()
            arrNewValues.splice(arrNewValues.indexOf(findFromArray(arrNewValues, itemName)), 1)
            customThemesPage.modelDataChanged(arrNewValues)
        }

        function removeItemsFromModel(indexList) {
            let arrCurrentValues = customThemesPage.model.slice()
            let arrNewValues = customThemesPage.model.slice()

            for (var i = 0; i < indexList.length; i++) {
                let index = indexList[i]
                let itemName = arrCurrentValues[index] ? arrCurrentValues[index].name : ""

                if (itemName !== "") {
                    arrNewValues.splice(arrNewValues.indexOf(findFromArray(arrNewValues, itemName)), 1)
                }
            }

            customThemesPage.modelDataChanged(arrNewValues)
        }
    }

    readonly property var themeAmbianceData: {
        "name": "Custom theme",
        "fontColor": "#333333",
        "selectionColor": "#19B6EE",
        "backgroundColor": "#f7f7f7",
        "dividerColor": "#cdcdcd",
        "annotationFontColor": "#333333",
        "charKeyColor": "white",
        "charKeyPressedColor": "#d9d9d9",
        "actionKeyColor": "#cdcdcd",
        "actionKeyPressedColor": "#aeaeae",
        "toolkitTheme": "Lomiri.Components.Themes.Ambiance",
        "popupBorderColor": "#888888",
        "keyBorderEnabled": false,
        "charKeyBorderColor": "white",
        "actionKeyBorderColor": "white"
    }
    readonly property var themeSuruBlackData: {
        "name": "Custom theme",
        "fontColor": "#CDCDCD",
        "selectionColor": "#19B6EE",
        "backgroundColor": "#3B3B3B",
        "dividerColor": "#666666",
        "annotationFontColor": "#F7F7F7",
        "charKeyColor": "#111111",
        "charKeyPressedColor": "#5D5D5D",
        "actionKeyColor": "#5D5D5D",
        "actionKeyPressedColor": "#888888",
        "toolkitTheme": "Lomiri.Components.Themes.SuruDark",
        "popupBorderColor": "#888888",
        "keyBorderEnabled": false,
        "charKeyBorderColor": "#111111",
        "actionKeyBorderColor": "#5D5D5D"
    }
    readonly property var themeSuruDarkData: {
        "name": "Custom theme",
        "fontColor": "#CDCDCD",
        "selectionColor": "#19B6EE",
        "backgroundColor": "#111111",
        "dividerColor": "#666666",
        "annotationFontColor": "#F7F7F7",
        "charKeyColor": "#3B3B3B",
        "charKeyPressedColor": "#5D5D5D",
        "actionKeyColor": "#666666",
        "actionKeyPressedColor": "#888888",
        "toolkitTheme": "Lomiri.Components.Themes.SuruDark",
        "popupBorderColor": "#888888",
        "keyBorderEnabled": false,
        "charKeyBorderColor": "#3B3B3B",
        "actionKeyBorderColor": "#3B3B3B"
    }
    readonly property var themeBorderedBlackData: {
        "name": "Custom theme",
        "fontColor": "white",
        "selectionColor": "#19B6EE",
        "backgroundColor": "#111111",
        "dividerColor": "#666666",
        "annotationFontColor": "#F7F7F7",
        "charKeyColor": "#111111",
        "charKeyPressedColor": "#5D5D5D",
        "actionKeyColor": "#5D5D5D",
        "actionKeyPressedColor": "#888888",
        "toolkitTheme": "Lomiri.Components.Themes.SuruDark" ,
        "popupBorderColor": "#888888",
        "keyBorderEnabled": true,
        "charKeyBorderColor": "#888888",
        "actionKeyBorderColor": "#888888"
    }
    readonly property var themeBorderedGreyData: {
        "name": "Custom theme",
        "fontColor": "white",
        "selectionColor": "#19B6EE",
        "backgroundColor": "#3B3B3B",
        "dividerColor": "#666666",
        "annotationFontColor": "#F7F7F7",
        "charKeyColor": "#3B3B3B",
        "charKeyPressedColor": "#5D5D5D",
        "actionKeyColor": "#666666",
        "actionKeyPressedColor": "#888888",
        "toolkitTheme": "Lomiri.Components.Themes.SuruDark",
        "popupBorderColor": "#888888",
        "keyBorderEnabled": true,
        "charKeyBorderColor": "#888888",
        "actionKeyBorderColor": "#888888"
    }
    readonly property var themeBorderedWhiteData: {
        "name": "Custom theme",
        "fontColor": "#333333",
        "selectionColor": "#19B6EE",
        "backgroundColor": "white",
        "dividerColor": "#cdcdcd",
        "annotationFontColor": "#333333",
        "charKeyColor": "white",
        "charKeyPressedColor": "#d9d9d9",
        "actionKeyColor": "#cdcdcd",
        "actionKeyPressedColor": "#aeaeae",
        "toolkitTheme": "Lomiri.Components.Themes.Ambiance" ,
        "popupBorderColor": "#888888",
        "keyBorderEnabled": true,
        "charKeyBorderColor": "#888888",
        "actionKeyBorderColor": "#888888"
    }
    readonly property var themeJustBlackData: {
        "name": "Custom theme",
        "fontColor": "white",
        "selectionColor": "#19B6EE",
        "backgroundColor": "#111111",
        "dividerColor": "#666666",
        "annotationFontColor": "#F7F7F7",
        "charKeyColor": "#111111",
        "charKeyPressedColor": "#5D5D5D",
        "actionKeyColor": "#111111",
        "actionKeyPressedColor": "#5D5D5D",
        "toolkitTheme": "Lomiri.Components.Themes.SuruDark" ,
        "popupBorderColor": "#888888",
        "keyBorderEnabled": false,
        "charKeyBorderColor": "transparent",
        "actionKeyBorderColor": "transparent"
    }
    readonly property var themeJustGreyData: {
        "name": "Custom theme",
        "fontColor": "white",
        "selectionColor": "#19B6EE",
        "backgroundColor": "#3B3B3B",
        "dividerColor": "#666666",
        "annotationFontColor": "#F7F7F7",
        "charKeyColor": "#3B3B3B",
        "charKeyPressedColor": "#5D5D5D",
        "actionKeyColor": "#3B3B3B",
        "actionKeyPressedColor": "#888888",
        "toolkitTheme": "Lomiri.Components.Themes.SuruDark",
        "popupBorderColor": "#888888",
        "keyBorderEnabled": false,
        "charKeyBorderColor": "transparent",
        "actionKeyBorderColor": "transparent"
    }
    readonly property var themeJustWhiteData: {
        "name": "Custom theme",
        "fontColor": "#333333",
        "selectionColor": "#19B6EE",
        "backgroundColor": "white",
        "dividerColor": "#cdcdcd",
        "annotationFontColor": "#333333",
        "charKeyColor": "white",
        "charKeyPressedColor": "#d9d9d9",
        "actionKeyColor": "white",
        "actionKeyPressedColor": "#d9d9d9",
        "toolkitTheme": "Lomiri.Components.Themes.Ambiance" ,
        "popupBorderColor": "#888888",
        "keyBorderEnabled": false,
        "charKeyBorderColor": "transparent",
        "actionKeyBorderColor": "transparent"
    }
}
