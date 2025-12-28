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

    property alias appModel: filteredAppModel.source
    property alias appDelegateHeight: appsResultsLayout.delegateHeight
    property alias appDelegateWidth: appsResultsLayout.delegateWidth
    property alias appDelegateSizeMultiplier: appsResultsLayout.delegateSizeMultiplier
    property alias appContextMenuItem: appsResultsLayout.contextMenuItem
    property alias launcherInverted: appsResultsLayout.launcherInverted
    property alias searchField: searchField
    property alias searchText: searchField.displayText

    readonly property var searchTypesModel:  [
        { name: "all", title: "All", placeholderText: "Search...", iconName: "find" }
        , { name: "web", title: "Web", placeholderText: "Search the web...", iconName: "stock_website" }
        , { name: "apps", title: "Apps", placeholderText: "Search apps...", iconName: "stock_application" }
        //, { name: "media", title: "Media", placeholderText: "Search media...", iconName: "gallery-app-symbolic" }
        //, { name: "music", title: "Music", placeholderText: "Search music...", iconName: "stock_music" }
    ]

    readonly property bool enableQuickResult: shell.settings.customDrawerSearchQuickWebResults
    readonly property bool enableOpenStoreResult: shell.settings.customDrawerSearchOpenStore
    readonly property bool forceEnablePredictiveText: shell.settings.customDrawerSearchForcePredictiveText
    readonly property bool expandHeaderOSKHide: shell.settings.customDrawerSearchExpandHeaderHideOSK
    readonly property bool exitWhenEmptyOSKhide: shell.settings.customDrawerSearchExpandHeaderHideOSK
    readonly property bool enabledBackSpaceToggle: shell.settings.customDrawerSearchEnableBackspaceSearchType

    readonly property alias searchType: internal.searchType
    readonly property alias searchTypeName: searchField.searchTypeName
    readonly property bool isAllSearch: searchTypeName === "all" || searchTypeName === ""
    readonly property bool isWebSearch: searchTypeName === "web"
    readonly property bool isAppSearch: searchTypeName === "apps"

    signal applicationSelected(string appId)
    signal applicationContextMenu(string appId, var caller)
    signal textFieldFocusChanged(bool focusValue)
    signal exit

    onVisibleChanged: {
        if (visible) {
            searchField.forceActiveFocus()
        } else {
            reset()
        }
    }

    function reset() {
        searchField.text = ""
        internal.searchType = 0
        webResultsLayout.reset()
        collapseHeader()
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

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
    }

    LPDrawerSearchTextField {
        id: searchField
        objectName: "searchField"

        anchors {
            top: labelHeader.bottom
            left: parent.left
            right: parent.right
            margins: units.gu(2)
        }

        forceEnablePredictiveText: root.forceEnablePredictiveText
        enabledBackSpaceToggle: root.enabledBackSpaceToggle
        model: root.searchTypesModel
        height: units.gu(5)
        placeholderText: i18n.tr("Search…")
        font.pixelSize: height * 0.5
        KeyNavigation.down: resultsLayout.firstItemToFocus

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
                        webResultsLayout.searchWeb()
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
        visible: root.height >= units.gu(60)
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
            } else if (!internal.searchTextIsEmpty && root.expandHeaderOSKHide) {
                root.expandHeader()
            } else if (internal.searchTextIsEmpty && root.exitWhenEmptyOSKhide) {
                root.exit()
            }
        }
    }
}
