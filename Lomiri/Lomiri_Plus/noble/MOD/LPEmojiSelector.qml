// ENH235 - Emoji selector popup
import QtQuick 2.15
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
import "Components"
import "Components/LPEmoji.js" as Emoji

LPFloatingPopup {
    id: root

    property var model: Emoji.getModel()
    property string searchText: headerItem ? headerItem.searchText : ""

    title: "Emojis"
    anchors.fill: parent

    headerSourceComponent: headerComponent

    function search() {
        let _resultArr = []
        const _arrLength = model.length

        for (let i = 0; i < _arrLength; i++) {
            const _regEx = new RegExp(searchText, "i");
            let _curArr = model[i].emojis
            const _filteredArr = _curArr.filter(item => _regEx.test(item.name) === true)
            if (_filteredArr.length > 0) {
                _resultArr.push(..._filteredArr)
            }
        }

        return _resultArr
    }

    Component {
        id: headerComponent

        RowLayout {
            id: headerLayout

            property string searchText: searchField.text

            TextField {
                id: searchField

                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: units.gu(4)
                Layout.preferredWidth: parent.width * 0.8

                inputMethodHints: Qt.ImhNoPredictiveText
                placeholderText: i18n.tr("Search emojis…")
                font.pixelSize: parent.height * 0.4

                onTextChanged: {
                    delayTextChange.restart()
                }

                Timer {
                    id: delayTextChange
                    interval: 100
                    onTriggered: headerLayout.searchText = searchField.text
                }
            }
        }
    }

    GridView {
        id: gridView
        
        readonly property var currentModel: root.model[groupListView.currentIndex].emojis

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: bottomRow.top
        }

        model: root.searchText.trim() !== "" ? root.search() : currentModel
        currentIndex: -1
        snapMode: GridView.SnapToRow
        cellWidth: root.floatingItem.width / Math.floor(root.floatingItem.width / units.gu(6))
        cellHeight: cellWidth
        cacheBuffer: units.gu(30)
        delegate: Loader {
            // Don't load asynchronously if the user is flicking through the
            // grid, otherwise loading looks messy
            asynchronous: !gridView.movingHorizontally

            width: gridView.cellWidth
            height: width

            sourceComponent: Button {
                id: itemButton

                 color: "transparent"
                 scale: ListView.isCurrentItem ? 1.2 : 1
                 onClicked: {
                    const _mimeData = Clipboard.newData();
                    _mimeData.text = text;
                    Clipboard.push(_mimeData);
                    overlayRec.show(text)
                 }

                 Label {
                     anchors.centerIn: parent
                     text: itemButton.text
                     textSize: Label.XLarge
                     color: theme.palette.normal.backgroundText
                 }
            }

            onLoaded: item.text = modelData.emoji
        }
    }

    Rectangle {
        color: theme.palette.normal.foregroundText
        height: units.dp(1)
        anchors {
            left: parent.left
            right: parent.right
            bottom: bottomRow.top
        }
    }

    Rectangle {
        color: theme.palette.normal.background
        anchors.fill: bottomRow
        radius: units.gu(2)
    }

    RowLayout {
        id: bottomRow

        height: units.gu(8)
        spacing: 0
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        ListView {
            id: groupListView

            Layout.fillWidth: true
            Layout.fillHeight: true

            model: root.model
            currentIndex: 0
            orientation: ListView.Horizontal
            snapMode: ListView.SnapToItem
            delegate: Button {
                readonly property bool highlight: ListView.isCurrentItem
                width: units.gu(6)
                height: width
                anchors.verticalCenter: parent.verticalCenter
                color: "transparent"
                scale: highlight ? 1.2 : 1
                onClicked: groupListView.currentIndex = index

                layer.enabled: !highlight
                layer.effect: ShaderEffect {
                    fragmentShader: "
                        uniform lowp sampler2D source; // this item
                        uniform lowp float qt_Opacity; // inherited opacity of this item
                        varying highp vec2 qt_TexCoord0;
                        void main() {
                            lowp vec4 p = texture2D(source, qt_TexCoord0);
                            lowp float g = dot(p.xyz, vec3(0.344, 0.5, 0.156));
                            gl_FragColor = vec4(g, g, g, p.a) * qt_Opacity;
                        }"
                }

                Label {
                    anchors.centerIn: parent
                    text: modelData.icon
                    textSize: Label.Large
                    color: theme.palette.normal.backgroundText
                }
            }
        }
    }

    Rectangle {
        id: overlayRec

        property string text

        visible: opacity > 0
        opacity: 0
        anchors.fill: parent
        color: theme.palette.normal.foreground
        Behavior on opacity { LomiriNumberAnimation {} }

        function show(_text) {
            text = _text
            opacity = 1
            closeTimer.restart()
        }

        function hide() {
            opacity = 0
        }

        onOpacityChanged: {
            if (opacity === 0) {
                root.close()
            }
        }

        ColumnLayout {
            anchors.fill: parent

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            Label {
                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: units.gu(10)
                text: overlayRec.text
                color: theme.palette.normal.foregroundText
            }
            Label {
                id: overlayText

                Layout.fillWidth: true
                Layout.margins: units.gu(2)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                textSize: Label.XLarge
                text: i18n.tr("copied to clipboard")
                color: theme.palette.normal.foregroundText
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        Timer {
            id: closeTimer
            interval: 800
            onTriggered: overlayRec.hide()
        }
    }
}
