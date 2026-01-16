// ENH236 - Custom drawer search
import QtQuick 2.15
import Lomiri.Components 1.3
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.12
import "Components" as Components

ColumnLayout {
    id: root

    property var searchField
    property string searchText
    property bool searchTextIsEmpty
    property bool firstResultsInPage: false

    readonly property bool hasVisibleChildren: visibleChildren.length > 0
    readonly property bool useSaliksik: shell.settings.customDrawerSearchSaliksikExists
    readonly property bool useSaliksikCustomSearchEngine: shell.settings.customDrawerSearchSaliksikSetSearchEngine
    readonly property string currentSearchEngine: shell.settings.customDrawerSearchWebSearchEngine
    readonly property int quickResultSource: shell.settings.customDrawerSearchQuickWebResultsSource
    readonly property bool quickResultIsWikipedia: quickResultSource === 0
    readonly property bool quickResultIsDDG: quickResultSource === 1
    readonly property var otherSearchEngineButtons: shell.settings.customDrawerSearchSearchEngineActions
    readonly property var firstItemToFocus: {
        if (openBrowserButton.visible) return openBrowserButton
        if (searchWebButton.visible) return searchWebButton
        if (otherSearchEnginesView.visible) return otherSearchEnginesView
        if (readMoreButton.visible) return readMoreButton

        return null 
    }

    property var previousItemToFocusAfterLast

    signal scrollToItem(var item)

    onSearchTextIsEmptyChanged: {
        if (searchTextIsEmpty) {
            cancelOnlineRequests()
        }
    }

    function showQuickResult() {
        if (internal.currentQuickResultSearchText !== searchText) {
            reset()
            if (!root.searchTextIsEmpty) {
                if (root.quickResultSource === 1) {
                    ddgQuickResult()
                } else {
                    wikipediaQuickResult()
                }
            }
        }
    }

    function ddgQuickResult() {
        let _returnFunc = function(_response) {
            const _parsedData = JSON.parse(_response.content)

            quickResult.summaryText = _parsedData.AbstractText
            quickResult.sourceText = _parsedData.AbstractSource
            quickResult.sourceUrl = _parsedData.AbstractURL

            internal.ddgRequest = null
            internal.currentQuickResultSearchText = root.searchText
        }
        const _url = "http://api.duckduckgo.com/?q=%1&format=json".arg(root.searchText)
        internal.cancelDDGRequest()
        internal.ddgRequest = shell.fetch(_url, _returnFunc)
    }

    function wikipediaQuickResult() {
        let _returnFunc = function(_response) {
            let _returnFunc2 = function(_response2) {
                try {
                    const _parsedData = JSON.parse(_response2.content)
                    const _pages = _parsedData.query.pages
                    let _text = _pages[Object.keys(_pages)[0]].extract

                    // Trying to remove extra new lines in some results
                    //const _regex = new RegExp('<p class=\\"mw-empty-elt\\">.*\\n*<\/p>.*\\n', "gm")
                    //_text = _text.replace(_regex, "")
                    _text = _text.replace(/\n/g, "")
                    quickResult.summaryText = _text
                } catch (e) {
                    console.log("Wikipedia extract error: %1".arg(e + " \n" + _response2.content))
                }

                internal.wikiExtractRequest = null
                internal.currentQuickResultSearchText = root.searchText
            }

            try {
                const _data = JSON.parse(_response.content)
                const _title = _data[1][0]
                const _url = _data[3][0]

                if (_url && _url.trim() !== "") {
                    quickResult.sourceUrl = _url
                }
                if (_title && _title.trim() !== "") {
                    const _url = "https://en.wikipedia.org/w/api.php?action=query&prop=extracts&exintro&titles=%1&format=json".arg(_title)
                    internal.cancelWikiExtractRequest()
                    internal.wikiExtractRequest = shell.fetch(_url, _returnFunc2)
                }
            } catch (e) {
                console.log("Wikipedia search error: %1".arg(e + "\n" + _response.content))
            }

            internal.wikiResultsRequest = null
        }

        const _url = "https://en.wikipedia.org/w/api.php?action=opensearch&search=%1&limit=1&namespace=0&format=json".arg(root.searchText)
        internal.cancelWikiResultsRequest()
        internal.wikiResultsRequest = shell.fetch(_url, _returnFunc)
    }

    function searchWeb(_searchEngineOverride = "") {
        let _url

        if (useSaliksik) {
            if (useSaliksikCustomSearchEngine) {
                const _searchEngineToUse = _searchEngineOverride ? _searchEngineOverride : currentSearchEngine
                _url = "search://%1/%2".arg(_searchEngineToUse).arg(encodeURIComponent(root.searchText))
            } else {
                _url = "search:///" + encodeURIComponent(root.searchText)
            }
        } else {
            const _searchEngine = _searchEngineOverride ? _searchEngineOverride
                                            : shell.searchEngines.find(element => element.id === currentSearchEngine)

            if (_searchEngine) {
                _url = shell.buildSearchUrl(root.searchText, _searchEngine.url)
            } else {
                _url = shell.buildSearchUrl(root.searchText, shell.searchEngines[0].url)
            }
        }

        // WORKAROUND: For some reason, called app
        // won't go to foreground when there are multiple open apps
        // most likely a timing issue with focus
        shell.launcher.hide()
        Qt.openUrlExternally(_url)
    }

    function openAsUrl() {
        let _url = internal.fixUrl(searchText)
        shell.launcher.hide()
        Qt.openUrlExternally(_url)
    }

    function cancelOnlineRequests() {
        internal.cancelWikiResultsRequest()
        internal.cancelWikiExtractRequest()
        internal.cancelDDGRequest()
    }

    function reset() {
        quickResult.reset()
        cancelOnlineRequests()
        internal.currentQuickResultSearchText = false
    }

    QtObject {
        id: internal

        readonly property bool looksLikeAUrl: !root.searchTextIsEmpty ? checkIfUrl(root.searchText) : false
        property var wikiResultsRequest
        property var wikiExtractRequest
        property var ddgRequest

        // The search text used for the current quick result
        property string currentQuickResultSearchText

        function cancelWikiResultsRequest() {
            if (wikiResultsRequest) {
                wikiResultsRequest.abort()
                wikiResultsRequest = null
            }
        }

        function cancelWikiExtractRequest() {
            if (wikiExtractRequest) {
                wikiExtractRequest.abort()
                wikiExtractRequest = null
            }
        }

        function cancelDDGRequest() {
            if (ddgRequest) {
                ddgRequest.abort()
                ddgRequest = null
            }
        }
        
        function checkIfUrl(address) {
            if (address.match(/^data:/i)) {
                return true;
            }
            if (address.match(/^file:/i)) {
                return true;
            }
            if (address.match(/^view-source:/i)) {
                return true;
            }
            if (address.match(/^chrome-extension:/i)) {
                return true;
            }
            var terms = address.split(/\s/);
            if (terms.length > 1) {
                return false;
            }
            if (address.toLowerCase() === "about:blank") {
                return true;
            }
            if (address.substr(0, 1) === "/") {
                return true;
            }
            if (address.match(/^https?:\/\//i) ||
                address.match(/^file:\/\//i) ||
                address.match(/^[a-z]+:\/\//i)) {
                return true;
            }
            if (address.split('/', 1)[0].match(/\.[a-zA-Z]{2,}$/)) {
                return true;
            }
            if (address.split('/', 1)[0].match(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}/)) {
                return true;
            }
            return false;
        }

        function fixUrl(address) {
            var url = address;
            if (address.toLowerCase() === "about:blank") {
                return address.toLowerCase();
            } else if (address.match(/^data:/i)) {
                return "data:" + address.substr(5);
            } else if (address.substr(0, 1) === "/") {
                url = "file://" + address;
            } else if (address.indexOf("://") === -1) {
                url = "http://" + address;
            }
            return url;
        }
    }

    LPDrawerSearchButton {
        id: openBrowserButton

        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        Layout.leftMargin: units.gu(1)
        Layout.rightMargin: units.gu(1)
        Layout.bottomMargin: units.gu(1)
        Layout.preferredHeight: units.gu(5)

        text: i18n.tr("Open in a browser")
        visible: internal.looksLikeAUrl
        display: QQC2.AbstractButton.TextBesideIcon
        secondaryIcon.name: "go-next"
        highlighted: activeFocus
        showEnterOverlay: this === root.firstItemToFocus && root.firstResultsInPage && root.searchField.activeFocus

        KeyNavigation.down: searchWebButton
        KeyNavigation.up: previousItemToFocusAfterLast ? previousItemToFocusAfterLast : root.searchField

        onActiveFocusChanged: if (activeFocus) root.scrollToItem(this)
        onClicked: root.openAsUrl()
    }

    LPDrawerSearchButton {
        id: searchWebButton

        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        Layout.leftMargin: units.gu(1)
        Layout.rightMargin: units.gu(1)
        Layout.preferredHeight: units.gu(5)

        text: i18n.tr("Search on the web")
        visible: !root.searchTextIsEmpty
        display: QQC2.AbstractButton.TextBesideIcon
        secondaryIcon.name: "go-next"
        highlighted: activeFocus
        showEnterOverlay: this === root.firstItemToFocus && root.firstResultsInPage && root.searchField.activeFocus

        KeyNavigation.down: otherSearchEnginesView.visible ? otherSearchEnginesView
                                    : readMoreButton.visible ? readMoreButton
                                                             : null
        KeyNavigation.up: openBrowserButton.visible ? openBrowserButton
                                : previousItemToFocusAfterLast ? previousItemToFocusAfterLast : root.searchField

        onActiveFocusChanged: if (activeFocus) root.scrollToItem(this)
        onClicked: root.searchWeb()
    }

    GridView {
        id: otherSearchEnginesView

        Layout.preferredHeight: contentHeight
        Layout.fillWidth: true
        Layout.leftMargin: units.gu(0.5)
        Layout.rightMargin: units.gu(0.5)

        model: root.otherSearchEngineButtons
        visible: !root.searchTextIsEmpty && count > 0 && shell.settings.customDrawerSearchShowSearchEngineActions
        focus: true
        interactive: false
        keyNavigationEnabled: true
        cellWidth: width / 2
        cellHeight: units.gu(6)
        KeyNavigation.down: readMoreButton.visible ? readMoreButton : null
        KeyNavigation.up: searchWebButton

        delegate: Item {
            id: gridDelagate

            readonly property bool isCurrentItem: GridView.isCurrentItem

            width: GridView.view.cellWidth
            height: GridView.view.cellHeight
            focus: false

            Keys.onEnterPressed: searchButtonDelegate.clicked()
            Keys.onReturnPressed: searchButtonDelegate.clicked()
            Keys.onSpacePressed: searchButtonDelegate.clicked()

            GridView.onIsCurrentItemChanged: root.scrollToItem(this)
            onActiveFocusChanged: if (activeFocus) root.scrollToItem(this)

            LPDrawerSearchButton {
                id: searchButtonDelegate

                readonly property var itemData: shell.searchEngines.find(element => element.id === modelData)

                anchors {
                    fill: parent
                    margins: units.gu(0.5)
                }
                highlighted: gridDelagate.isCurrentItem && gridDelagate.activeFocus
                text: modelData === "main" ? i18n.tr("Search on the web") : itemData ? itemData.name : "Unknown"
                display: QQC2.AbstractButton.TextBesideIcon
                secondaryIcon.name: "go-next"

                onClicked: modelData === "main" ? root.searchWeb() : root.searchWeb(modelData)
            }
        }
    }

    ColumnLayout {
        id: quickResult

        readonly property bool isEmpty: summaryText.trim() === ""

        property string summaryText
        property string sourceText
        property url sourceUrl

        Layout.topMargin: units.gu(1)

        visible: !isEmpty
        spacing: 0

        function reset() {
            summaryText = ""
            sourceText = ""
            sourceUrl = ""
            summaryLabel.isExpanded = false
        }

        RowLayout {
            Layout.leftMargin: units.gu(1)
            Layout.rightMargin: units.gu(1)
            Layout.bottomMargin: units.gu(2)

            Label {
                Layout.fillWidth: true
                Layout.fillHeight: true

                wrapMode: Text.WordWrap
                color: theme.palette.normal.backgroundText
                text: root.quickResultIsWikipedia ? "Wikipedia" : "DuckDuckGo"
                textSize: Label.Large
                verticalAlignment: Text.AlignVCenter
            }

            LPDrawerSearchButton {
                id: readMoreButton

                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.preferredHeight: units.gu(5)

                text: i18n.tr("Read more")
                visible: quickResult.sourceUrl.toString().trim() !== ""
                display: QQC2.AbstractButton.TextBesideIcon
                secondaryIcon.name: "go-next"
                KeyNavigation.down: null

                onActiveFocusChanged: if (activeFocus) root.scrollToItem(quickResult)
                onClicked: Qt.openUrlExternally(quickResult.sourceUrl)
            }
        }

        Label {
            id: sourceLabel

            Layout.fillWidth: true
            Layout.topMargin: units.gu(1)
            Layout.leftMargin: units.gu(2)
            Layout.rightMargin: units.gu(2)

            visible: quickResult.sourceText.trim() !== ""
            color: theme.palette.normal.backgroundText
            wrapMode: Text.WordWrap
            textSize: Label.Small
            text: i18n.tr("Source: %1").arg(quickResult.sourceText)
        }

        Label {
            id: summaryLabel

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: units.gu(2)
            Layout.rightMargin: units.gu(2)

            property bool isExpanded: false

            text: quickResult.summaryText
            color: theme.palette.normal.backgroundText
            wrapMode: Text.WordWrap
            maximumLineCount: isExpanded ? 30 : 10
            elide: Text.ElideRight

            MouseArea {
                anchors.fill: parent
                onClicked: summaryLabel.isExpanded = !summaryLabel.isExpanded
            }
        }
    }
}
