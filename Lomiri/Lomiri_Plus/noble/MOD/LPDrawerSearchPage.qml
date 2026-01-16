// ENH236 - Custom drawer search
import QtQuick 2.15
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
import Lomiri.Launcher 0.1
import Utils 0.1
import "Components" as Components

Item {
    id: root

    property var defaultAppList
    property alias appModel: filteredAppModel.source
    property alias appDelegateHeight: appsResultsLayout.delegateHeight
    property alias appDelegateWidth: appsResultsLayout.delegateWidth
    property alias appDelegateSizeMultiplier: appsResultsLayout.delegateSizeMultiplier
    property alias appContextMenuItem: appsResultsLayout.contextMenuItem
    property alias launcherInverted: appsResultsLayout.launcherInverted
    property alias searchField: searchField
    property alias searchText: searchField.displayText
    property alias showCloseButton: searchField.showCloseButton

    readonly property var searchTypesModel:  [
        { name: "all", title: "All", placeholderText: "Search...", iconName: "find" }
        , { name: "web", title: "Web", placeholderText: "Search the web...", iconName: "stock_website" }
        , { name: "apps", title: "Apps", placeholderText: "Search apps...", iconName: "stock_application" }
        //, { name: "media", title: "Media", placeholderText: "Search media...", iconName: "gallery-app-symbolic" }
        //, { name: "music", title: "Music", placeholderText: "Search music...", iconName: "stock_music" }
    ]

    readonly property real searchFieldBottomY: searchField.y + searchField.height
    readonly property bool enableQuickResult: shell.settings.customDrawerSearchQuickWebResults
    readonly property bool enableOpenStoreResult: shell.settings.customDrawerSearchOpenStore
    readonly property bool forceEnablePredictiveText: shell.settings.customDrawerSearchForcePredictiveText
    readonly property bool expandHeaderOSKHide: shell.settings.customDrawerSearchExpandHeaderHideOSK
    readonly property bool exitWhenEmptyOSKhide: shell.settings.customDrawerSearchExitHideOSK
    readonly property bool enabledBackSpaceToggle: shell.settings.customDrawerSearchEnableBackspaceSearchType

    readonly property alias searchType: internal.searchType
    readonly property alias searchTypeName: searchField.searchTypeName
    readonly property alias searchTextIsEmpty: internal.searchTextIsEmpty
    readonly property bool isAllSearch: searchTypeName === "all" || searchTypeName === ""
    readonly property bool isWebSearch: searchTypeName === "web"
    readonly property bool isAppSearch: searchTypeName === "apps"

    signal applicationSelected(string appId)
    signal applicationContextMenu(string appId, var caller)
    signal textFieldFocusChanged(bool focusValue)
    signal exit

    function focusInput() {
        searchField.forceActiveFocus()
    }

    function reset() {
        searchField.text = ""
        internal.searchType = 0
        webResultsLayout.reset()
        collapseHeader()
        if (searchField.contextMenuItem) {
            searchField.contextMenuItem.closePopup()
        }
    }

    function expandHeader() {
        labelHeader.expand()
    }

    function collapseHeader() {
        labelHeader.collapse()
    }

    function setSearchType(_name) {
        const _arr = searchField.model.slice()
        const _type = _arr.findIndex(element => element.name === _name)
        internal.searchType = _type > -1 ? _type : 0
    }

    function searchTypeForward() {
        searchField.searchTypeForward()
    }

    function searchTypeBackward() {
        searchField.searchTypeBackward()
    }

    function focusFirstItem() {
        if (resultsLayout.firstItemToFocus) {
            resultsLayout.firstItemToFocus.focus = true
        }
    }

    QtObject {
        id: internal

        property alias searchType: searchField.searchType
        property alias appList: appsResultsLayout.appList

        readonly property alias delayedSearchText: searchField.delayedSearchText
        readonly property bool searchTextIsEmpty: root.searchText.trim() === ""
        readonly property alias appsListIsEmpty: appsResultsLayout.appsListIsEmpty

        readonly property bool displayQuickWebResult: root.enableQuickResult && (root.isAllSearch || root.isWebSearch)
        readonly property bool displayOpenStoreResults: root.enableOpenStoreResult && (root.isAllSearch || root.isAppSearch)

        function processDelayedSearch(_searchText) {
            if (displayQuickWebResult) {
                processQuickWebResult(_searchText)
            }
            if (displayOpenStoreResults) {
                processOpenStoreResults(_searchText)
            }
        }

        function processQuickWebResult(_searchText) {
            if (_searchText.trim() === "") {
                webResultsLayout.reset()
                return
            }

            webResultsLayout.showQuickResult()
        }
        
        function processOpenStoreResults(_searchText) {
            if (_searchText.trim() === "") {
                appsResultsLayout.reset()
                return
            }

            appsResultsLayout.openStoreResult()
        }

        onDelayedSearchTextChanged: processDelayedSearch(delayedSearchText)
        onDisplayQuickWebResultChanged: processQuickWebResult(root.searchText)
        onDisplayOpenStoreResultsChanged: processOpenStoreResults(root.searchText)
    }

    AppDrawerProxyModel {
        id: filteredAppModel

        filterString: root.isAppSearch || root.isAllSearch ? root.searchText : "<><><<>" // random text to show no apps
        sortBy: AppDrawerProxyModel.SortByAToZ
    }

    Components.LPTitleHeader {
        id: labelHeader

        containerItem: root
        text: i18n.tr("Search")
        iconName: "search"
        showDivider: root.launcherInverted
        dividerLeftMargin: units.gu(1)

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
    }

    LPDrawerSearchTextField {
        id: searchField
        objectName: "searchField"

        readonly property var nextItem: resultsLayout.firstItemToFocus ? resultsLayout.firstItemToFocus : root.defaultAppList

        anchors {
            top: labelHeader.bottom
            left: parent.left
            right: parent.right
            margins: units.gu(2)
            topMargin: root.launcherInverted ? units.gu(2) : 0
        }

        forceEnablePredictiveText: root.forceEnablePredictiveText
        enabledBackSpaceToggle: root.enabledBackSpaceToggle
        showCloseButton: !bottomRowLayout.visible
        model: root.searchTypesModel
        height: units.gu(5)
        placeholderText: i18n.tr("Search…")
        font.pixelSize: height * 0.5

        KeyNavigation.up: null
        KeyNavigation.down: nextItem
        KeyNavigation.right: cursorPosition >= length ? nextItem : null

        onExitSearch: root.exit()
        onActiveFocusChanged: root.textFieldFocusChanged(activeFocus)

        onAccepted: {
            if (root.searchText != "") {
                switch(true) {
                    case !internal.appsListIsEmpty:
                        // In case there is no currentItem (it might have been filtered away) lets reset it to the first item
                        if (!internal.appList.currentItem) {
                            internal.appList.currentIndex = 0;
                        }
                        root.applicationSelected(internal.appList.getFirstAppId());
                        break
                    case root.isWebSearch:
                        const _item = webResultsLayout.firstItemToFocus
                        if (_item && _item instanceof LPDrawerSearchButton) {
                            _item.clicked()
                        }
                        break
                }
            }
        }
    }

    Components.LPFlickable {
        id: flickable

        anchors {
            bottom: bottomRowLayout.top
            bottomMargin: units.gu(1)
            left: parent.left
            right: parent.right
            top: searchField.bottom
        }
        topMargin: units.gu(2)
        pageHeader: labelHeader
        interactive: !labelHeader.expanded
        focus: true
        contentHeight: columnLayout.implicitHeight
        maximumFlickVelocity: shell.settings.fasterFlickDrawer ? units.gu(600) : units.gu(312.5)
        visible: opacity > 0
        opacity: root.searchTextIsEmpty ? 0 : 1
        Behavior on opacity { LomiriNumberAnimation {} }

        clip: true

        ColumnLayout {
            id: columnLayout

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            ColumnLayout {
                id: resultsLayout

                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property var firstItemToFocus: {
                    if (appsResultsLayout.hasVisibleChildren) return appsResultsLayout.firstItemToFocus
                    if (webResultsLayout.hasVisibleChildren) return webResultsLayout.firstItemToFocus

                    return null
                }

                spacing: units.gu(2)

                LPDrawerSearchApps {
                    id: appsResultsLayout

                    Layout.fillWidth: true

                    visible: root.isAllSearch || root.isAppSearch
                    searchField: root.searchField
                    searchText: root.searchText
                    appModel: root.appModel
                    firstResultsInPage: true
                    searchTextIsEmpty: internal.searchTextIsEmpty
                    nextItemToFocusAfterLast: webResultsLayout.firstItemToFocus

                    onApplicationSelected: root.applicationSelected(appId)
                    onApplicationContextMenu: root.applicationContextMenu(appId, caller)
                    onScrollToItem: flickable.scrollToItem(item)
                }

                Components.LPThinDivider {
                    Layout.fillWidth: true
                    Layout.leftMargin: units.gu(2)
                    Layout.rightMargin: units.gu(2)
                    visible: appsResultsLayout.hasVisibleChildren && webResultsLayout.hasVisibleChildren
                }

                LPDrawerSearchWebResults {
                    id: webResultsLayout

                    Layout.fillWidth: true

                    visible: root.isAllSearch || root.isWebSearch
                    firstResultsInPage: root.isWebSearch && visible
                    searchField: root.searchField
                    searchText: root.searchText
                    searchTextIsEmpty: internal.searchTextIsEmpty
                    previousItemToFocusAfterLast: appsResultsLayout.lastItemToFocus

                    onScrollToItem: flickable.scrollToItem(item)
                }
            }
        }
    }

    Components.LPCollapseHeaderSwipeArea {
        pageHeader: labelHeader
        enabled: pageHeader.expandable && pageHeader.expanded
        anchors.fill: parent
    }

    RowLayout {
        id: bottomRowLayout

        anchors {
            bottom: parent.bottom
            bottomMargin: units.gu(3)
            left: parent.left
            right: parent.right
        }
        visible: root.height >= units.gu(60) && root.launcherInverted // Hide in Windowed mode
        height: visible ? units.gu(6) : 0

        // Spacer for now
        Item {
            Layout.preferredWidth: units.gu(6)
            Layout.alignment: Qt.AlignCenter
        }
        LPDrawerSearchButton {
            Layout.preferredHeight: units.gu(6)
            Layout.alignment: Qt.AlignCenter

            text: i18n.tr("Close Search")
            display: QQC2.AbstractButton.TextOnly
            backgroundOpacity: 1
            onClicked: root.exit()
        }

        LPDrawerSearchButton {
            Layout.preferredHeight: units.gu(6)
            Layout.alignment: Qt.AlignCenter

            icon.name: "find"
            display: QQC2.AbstractButton.IconOnly
            backgroundOpacity: 1
            focusPolicy: Qt.NoFocus
            onClicked: {
                // I don't know why just searchField.forceActiveFocus doesn't work
                forceActiveFocus()
                root.searchField.forceActiveFocus()
            }
        }
    }

    Connections {
        enabled: root.visible
        target: shell.osk
        function onVisibleChanged() {
            if (target.visible) {
                root.collapseHeader()
                // Workaround when hiding the OSK then refocusing won't retrigger activeFocusChanged
                if (searchField.activeFocus) {
                    root.textFieldFocusChanged(true)
                }
            } else if (searchField.contextMenuItem === null) {
                if (!internal.searchTextIsEmpty && root.expandHeaderOSKHide) {
                    root.expandHeader()
                } else if (internal.searchTextIsEmpty && root.exitWhenEmptyOSKhide) {
                    root.exit()
                }
            }
        }
    }
}
