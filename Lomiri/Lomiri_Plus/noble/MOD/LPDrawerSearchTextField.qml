// ENH236 - Custom drawer search
import QtQuick 2.15
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
import Lomiri.Components.Popups 1.3

TextField {
    id: root

    readonly property var currentSearchType: model[searchType]
    readonly property int searchTypeCount: model.length
    readonly property string searchTypeName: currentSearchType ? currentSearchType.name : ""
    readonly property alias delayedSearchText: internal.searchText
    readonly property alias contextMenuItem: internal.contextMenuItem

    property bool showCloseButton: false
    property bool forceEnablePredictiveText: false
    property bool enabledBackSpaceToggle: false

    property int searchType: 0

    property var model

    signal exitSearch

    hasClearButton: false

    function searchTypeForward() {
        let _newType = searchType + 1
        if (_newType === searchTypeCount) {
            _newType = 0
        }
        searchType = _newType
    }

    function searchTypeBackward() {
        let _newType = searchType - 1
        if (_newType < 0) {
            _newType = searchTypeCount - 1
        }
        searchType = _newType
    }

    QtObject {
        id: internal

        property string searchText: ""
        property var contextMenuItem: null
    }

    primaryItem: Button {
        width: rowLayout.width + units.gu(1)
        height: root.height
        color: "transparent"
        strokeColor: "transparent"

        onClicked: {
            const _arr = root.model.slice()
            _arr.splice(root.searchType, 1)
            internal.contextMenuItem = contextMenuComponent.createObject(shell.popupParent, { "caller": this, "currentSearchType": root.searchType, "model": _arr });
            internal.contextMenuItem.z = Number.MAX_VALUE
            internal.contextMenuItem.show()
        }

        RowLayout {
            id: rowLayout

            spacing: units.gu(1)
            anchors {
                top: parent.top
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }

            Item {
                id: searchTypeIndicator

                Layout.fillHeight: true
                Layout.preferredWidth: searchTypeContent.width

                RowLayout {
                    id: searchTypeContent

                    anchors.verticalCenter: parent.verticalCenter
                    spacing: units.gu(1)

                    Icon {
                        implicitWidth: units.gu(2)
                        implicitHeight: implicitWidth
                        
                        color: theme.palette.normal.activity
                        name: root.currentSearchType ? root.currentSearchType.iconName : ""
                    }

                    Label {
                        Layout.fillWidth: true
                        color: theme.palette.normal.activity
                        font.weight: Font.DemiBold
                        font.pixelSize: root.font.pixelSize * 0.8
                        text: root.currentSearchType ? root.currentSearchType.title : ""
                    }
                    
                    Rectangle {
                        Layout.fillHeight: true
                        implicitWidth: units.dp(1)
                        color: theme.palette.normal.backgroundTertiaryText
                    }
                }
            }
        }
    }

    secondaryItem: LPDrawerSearchButton {
        implicitWidth: visible ? units.gu(6) : 0
        visible: root.showCloseButton
        icon.name: "cancel"
        display: QQC2.AbstractButton.IconOnly
        focusPolicy: Qt.NoFocus
        onClicked: root.exitSearch()
    }

    inputMethodHints: root.forceEnablePredictiveText || root.searchTypeName === "web" ? Qt.ImhNone : Qt.ImhNoPredictiveText

    placeholderText: root.currentSearchType ? root.currentSearchType.placeholderText : i18n.tr("Search...")

    Keys.onPressed: {
        if (text === "") {
            switch (event.key) {
                case Qt.Key_Backspace:
                    if (root.enabledBackSpaceToggle) {
                        root.searchTypeBackward()
                        event.accepted = true
                        break
                    }
                default:
                    event.accepted = false
                    break
            }
        }
        event.accepted = false
    }
    
    onTextChanged: {
        // Change focused search type when text is empty and the user pressed/entered space
        if (text === " ") {
            root.searchTypeForward()
            text = ""
        } else {
            if (text.charAt(text.length - 1) == " ") { // Trailing single space
                searchDelay.triggered()
            } else {
                searchDelay.restart()
            }
        }
    }

    Timer {
        id: searchDelay
        interval: 300
        onTriggered: {
            const _trimmedText = root.text.trim()
            internal.searchText = _trimmedText
        }
    }

    Component {
        id: contextMenuComponent

        ActionSelectionPopover {
            id: contextMenu

            property int currentSearchType
            property var model

            contentWidth: units.gu(30)
            edgeMargins: units.gu(10)
            grabDismissAreaEvents: true
            automaticOrientation: false
            actions: actionList
            delegate: ListItem {
                onClicked: PopupUtils.close(contextMenu)
                ListItemLayout {
                   title.text: action.text
                   Icon {
                        name: action.iconName
                        SlotsLayout.position: SlotsLayout.Leading;
                        width: units.gu(3)
                        color: theme.palette.normal.foregroundText
                    }
               }
            }

            function closePopup() {
                hide()
                destroy()
                internal.contextMenuItem = null
            }

            onVisibleChanged: {
                if (!visible) {
                    contextMenu.closePopup()
                }
            }

            ActionList {
                id: actionList
            }

            Instantiator {
                model: contextMenu.model
                asynchronous: true
                delegate: Action {
                    text: modelData.title
                    iconName: modelData.iconName ? modelData.iconName : ""
                    onTriggered: {
                        let _newType = index
                        if (index >= root.searchType) {
                            _newType += 1
                        }
                        root.searchType = _newType
                    }
                }

                onObjectAdded: {
                    // For some reason an empty action is added
                    if (object.text.trim() !== "") {
                        actionList.addAction(object)
                    }
                }
            }
        }
    }
}

