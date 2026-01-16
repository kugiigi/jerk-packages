// ENH236 - Custom drawer search
import QtQuick 2.15
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.15 as QQC2
import "Launcher" as Launcher
import "Components" as Components
import Utils 0.1

ColumnLayout {
    id: root

    property var searchField
    property string searchText
    property bool searchTextIsEmpty
    property var appModel
    property real delegateWidth
    property real delegateHeight
    property real delegateSizeMultiplier
    property bool launcherInverted
    property var contextMenuItem: appList.contextMenuItem
    property alias appListIsExpanded: appList.isExpanded
    property bool firstResultsInPage: false

    readonly property alias appList: appList
    readonly property bool appsListIsEmpty: filteredAppModel.count === 0
    readonly property int columns: Math.floor(width / delegateWidth)
    readonly property bool hasVisibleChildren: visibleChildren.length > 0
    readonly property var firstItemToFocus: {
        if (!appsListIsEmpty) return appList
        if (openStoreGridView.count > 0) return viewAllButton
        if (searchOpenStoreButton.visible) return searchOpenStoreButton

        return null 
    }
    readonly property var lastItemToFocus: {
        if (searchOpenStoreButton.visible) return searchOpenStoreButton
        if (openStoreGridView.count > 0) return openStoreGridView
        if (!appsListIsEmpty) return appList

        return null 
    }

    property var nextItemToFocusAfterLast

    signal applicationSelected(string appId)
    signal applicationContextMenu(string appId, var caller)
    signal scrollToItem(var item)

    spacing: units.gu(3)

    onSearchTextChanged: appList.collapse()
    onSearchTextIsEmptyChanged: {
        if (searchTextIsEmpty) {
            cancelOpenStoreRequest()
        }
    }

    function searchOpenStore() {
        const _url = "https://open-store.io/?sort=relevance&search=%1".arg(encodeURIComponent(root.searchText))
        internal.openUrlExternally(_url)
    }

    function openStoreResult() {
        if (internal.currentQuickResultSearchText !== searchText) {
            reset()
            if (!searchTextIsEmpty) {
                let _returnFunc = function(_response) {
                    try {
                        const _parsedData = JSON.parse(_response.content)

                        if (_parsedData && _parsedData.success === true) {
                            // Remove apps that are already installed
                            let _appList = internal.removeExistingFromOpenStore(_parsedData.data.packages)
                            _appList = _appList.slice(0,8) // Limit results to max number
                            internal.openStoreAppList = _appList
                        }
                    } catch (e) {
                        console.log("OpenStore search error: %1".arg(e))
                    }

                    internal.openStoreRequest = null
                    internal.currentQuickResultSearchText = root.searchText
                }
                const _url = "https://open-store.io/api/v4/apps?limit=20&skip=0&search=%1&sort=relevance&type=&category=&channel=noble".arg(root.searchText)
                cancelOpenStoreRequest()
                internal.openStoreRequest = shell.fetch(_url, _returnFunc)
            }
        }
    }

    function cancelOpenStoreRequest() {
        if (internal.openStoreRequest) {
            internal.openStoreRequest.abort()
            internal.openStoreRequest = null
        }
    }

    function reset() {
        cancelOpenStoreRequest()
        internal.openStoreAppList = []
        internal.currentQuickResultSearchText = ""
    }

    QtObject {
        id: internal

        property var openStoreAppList // JS Array
        property var openStoreRequest
        property string currentQuickResultSearchText

        function convertAppIdFromModelToOpenStore(_appId) {
            const _splitAppId = _appId.split("_")
            return _appId.replace("_" + _splitAppId[_splitAppId.length - 1 ], "")
        }

        function removeExistingFromOpenStore(_array) {
            if (_array.length > 0) {
                let _filteredArray = _array.slice()
                for (let i = 0; i < root.appModel.rowCount(); ++i) {
                    const _modelIndex = root.appModel.index(i, 0)
                    const _currentAppId = convertAppIdFromModelToOpenStore(root.appModel.data(_modelIndex, 0))
                    const _foundIndex = _filteredArray.findIndex((element) => element.id === _currentAppId)
                    if (_foundIndex > -1) {
                        _filteredArray.splice(_foundIndex, 1)
                    }
                }

                return _filteredArray
            }

            return _array
        }

        function openAppInOpenStore(_appId) {
            const _url = "https://open-store.io/app/%1".arg(_appId)
            openUrlExternally(_url)
        }

        function openUrlExternally(_url) {
            // WORKAROUND: For some reason, called app
            // won't go to foreground when there are multiple open apps
            // most likely a timing issue with focus
            shell.launcher.hide()
            Qt.openUrlExternally(_url)
        }
    }

    ColumnLayout {
        id: installedAppsLayout

        // Workaround to avoid clipping icons when in focus and bouncing
        Layout.topMargin: units.gu(-2)

        Launcher.DrawerGridView {
            id: appList
            objectName: "drawerAppList"

            readonly property real collapsedHeight: Math.min(rows, collapsedRows) * delegateHeight + units.gu(2)
            readonly property real expandedHeight: rows * delegateHeight + units.gu(2) // Add more for apps with 2-line name
            readonly property real assessedHeight: isExpanded ? expandedHeight : collapsedHeight

            property bool showAnimation: false

            Layout.fillWidth: true
            Layout.preferredHeight: assessedHeight

            Behavior on Layout.preferredHeight {
                enabled: appList.showAnimation
                LomiriNumberAnimation {}
            }

            // Only allow animation when the button was clicked
            onIsExpandedChanged: showAnimation = true
            onRowsChanged: appList.showAnimation = false

            readonly property int collapsedRows: 4
            readonly property bool isExpandable: appList.rows > appList.collapsedRows
            property bool isExpanded: true

            function expand() {
                isExpanded = true
            }

            function collapse() {
                isExpanded = false
            }

            function toggleExpanded() {
                isExpanded = !isExpanded
            }

            visible: !root.appsListIsEmpty
            model: root.searchText !== "" ? filteredAppModel : null
            //verticalLayoutDirection: contentContainer.state == "Inverted" ? GridView.BottomToTop : GridView.TopToBottom
            rawModel: root.appModel
            flickableInteractive: false
            launcherInverted: root.launcherInverted
            delegateWidth: root.delegateWidth
            delegateHeight: root.delegateHeight
            delegateSizeMultiplier: root.delegateSizeMultiplier
            viewMargin: units.gu(2)
            clip: true

            KeyNavigation.down: openStoreGridView.visible ? viewAllButton : root.nextItemToFocusAfterLast
            KeyNavigation.up: root.searchField

            delegate: Launcher.LPDrawerAppDelegate {
                objectName: "drawerItem_" + model.appId
                focused: (index === GridView.view.currentIndex && GridView.view.activeFocus)
                                    || (root.contextMenuItem && root.contextMenuItem.appId == model.appId && !root.contextMenuItem.fromDocked)
                showEnterOverlay: (index === 0 && root.firstResultsInPage && root.searchField.activeFocus) // Show visual hint it's be selected when entering
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight
                delegateWidth: root.delegateWidth
                delegateSizeMultiplier: root.delegateSizeMultiplier
                appId: model.appId
                appName: model.name
                iconSource: model.icon
                hideLabel: false

                GridView.onIsCurrentItemChanged: root.scrollToItem(this)
                onActiveFocusChanged: {
                    if (activeFocus) {
                        root.scrollToItem(this)

                        const _collapsedMaxItems = (appList.collapsedRows * appList.columns)
                        if (!appList.isExpanded && index >= _collapsedMaxItems) {
                            appList.expand()
                        }
                    }
                }

                onApplicationSelected: root.applicationSelected(appId)
                onApplicationContextMenu: root.applicationContextMenu(appId, this)
            }
            showDock: false
            enableCustomAppGrids: false

            onDraggingVerticallyChanged: {
                if (draggingVertically) {
                    unFocusInput();
                }
            }

            refreshing: root.appModel.refreshing
            onRefresh: {
                root.appModel.refresh();
            }
        }

        LPDrawerSearchButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: units.gu(5)

            text: appList.isExpanded ? i18n.tr("Show less") : i18n.tr("Show all matching apps")
            visible: !root.appsListIsEmpty && appList.isExpandable
            display: QQC2.AbstractButton.TextBesideIcon
            icon.name: appList.isExpanded ? "go-up" : "go-down"
            onClicked: appList.toggleExpanded()
        }
    }

    ColumnLayout {
        id: openStoreLayout

        Layout.alignment: Qt.AlignHCenter

        RowLayout {
            Layout.leftMargin: units.gu(1)
            Layout.rightMargin: units.gu(1)
            Layout.bottomMargin: units.gu(2)

            visible: openStoreGridView.visible

            Label {
                Layout.fillWidth: true
                Layout.fillHeight: true

                wrapMode: Text.WordWrap
                color: theme.palette.normal.backgroundText
                text: i18n.tr("OpenStore")
                textSize: Label.Large
                verticalAlignment: Text.AlignVCenter
            }

            LPDrawerSearchButton {
                id: viewAllButton

                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.preferredHeight: units.gu(5)

                text: i18n.tr("View all")
                display: QQC2.AbstractButton.TextBesideIcon
                secondaryIcon.name: "go-next"
                KeyNavigation.down: openStoreGridView
                KeyNavigation.up: appList.visible ? appList : root.searchField

                onActiveFocusChanged: if (activeFocus) root.scrollToItem(this)
                onClicked: root.searchOpenStore()
            }
        }

        GridView {
            id: openStoreGridView

            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight

            readonly property int overflow: width - (root.columns * root.delegateWidth)
            readonly property real spacing: Math.floor(overflow / root.columns)

            model: internal.openStoreAppList
            visible: count > 0
            focus: true
            interactive: false
            keyNavigationEnabled: true
            cellWidth: root.delegateWidth + spacing
            cellHeight: root.delegateHeight
            KeyNavigation.down: root.nextItemToFocusAfterLast

            Behavior on height {
                LomiriNumberAnimation {}
            }

            delegate: Launcher.LPDrawerAppDelegate {
                focused: (index === GridView.view.currentIndex && GridView.view.activeFocus)
                                    || (root.contextMenuItem && root.contextMenuItem.appId == modelData.id && !root.contextMenuItem.fromDocked)
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight
                delegateWidth: root.delegateWidth
                appId: modelData.id
                appName: modelData.name
                iconSource: modelData.icon
                delegateSizeMultiplier: root.delegateSizeMultiplier

                onApplicationSelected: internal.openAppInOpenStore(appId)
                // TODO: Not implemented yet. View publisher or author?
                //onApplicationContextMenu: appList.applicationContextMenu(appId, this, false, false)

                GridView.onIsCurrentItemChanged: root.scrollToItem(this)
                onActiveFocusChanged: if (activeFocus) root.scrollToItem(this)
            }
        }

        LPDrawerSearchButton {
            id: searchOpenStoreButton

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.leftMargin: units.gu(1)
            Layout.rightMargin: units.gu(1)
            Layout.preferredHeight: units.gu(5)

            text: i18n.tr("Search on the OpenStore")
            visible: !root.searchTextIsEmpty && !openStoreGridView.visible
            display: QQC2.AbstractButton.TextBesideIcon
            secondaryIcon.name: "go-next"
            KeyNavigation.down: root.nextItemToFocusAfterLast

            onActiveFocusChanged: if (activeFocus) root.scrollToItem(this)
            onClicked: root.searchOpenStore()
        }
    }
}
