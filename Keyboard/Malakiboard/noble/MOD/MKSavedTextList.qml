// ENH120 - Saved Texts
import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import Lomiri.Components 1.3

Loader {
    id: savedTextsArea

    property bool isAscending: true
    property bool isFavorites: item && item.isFavorites

    z: floatingActions.z
    active: fullScreenItem.settings.enableSavedTexts
    asynchronous: true
    visible: opacity > 0
    opacity: 0

    function show() {
        opacity = 1
    }

    function hide() {
        opacity = 0
    }

    function toggle() {
        if (opacity > 0) {
            opacity = 0
        } else {
            opacity = 1
        }
    }

    function toggleSort() {
        isAscending = !isAscending
    }

    Behavior on opacity { LomiriNumberAnimation {} }

    sourceComponent: Rectangle {
        id: savedTextsRec

        readonly property bool isFavorites: tabsBar.currentIndex === 0

        color: fullScreenItem.theme.charKeyPressedColor
        clip: true

        Label {
            color: fullScreenItem.theme.fontColor
            visible: savedTextListView.count === 0
            text: savedTextsRec.isFavorites ? i18n.tr("No Favorites") : i18n.tr("Custom clipboard is empty")
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textSize: Label.Large
            wrapMode: Text.WordWrap
            anchors {
                fill: parent
                margins: units.gu(1)
                topMargin: tabsBar.height
            }
        }

        QQC2.TabBar {
            id: tabsBar

            width: parent.width // anchors has binding loop for some reason
            anchors.top: parent.top

            QQC2.TabButton {
                text: "Favorites"
                width: tabsBar.width / 2
            }
            QQC2.TabButton {
                text: "Clipboard"
                width: tabsBar.width / 2
            }
        }

        ListView {
            id: savedTextListView

            anchors {
                top: tabsBar.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            clip: true

            model: {
                if (savedTextsRec.isFavorites) {
                    if (savedTextsArea.isAscending) {
                        return fullScreenItem.sortArray(fullScreenItem.settings.savedTexts, "text", true)
                    } else {
                        return fullScreenItem.sortArray(fullScreenItem.settings.savedTexts, "text", false)
                    }
                } else {
                    fullScreenItem.settings.customClipboard
                }
            }
            currentIndex: -1
            delegate: MKSavedTextsDelegate {
                text: savedTextsRec.isFavorites ? modelData.text : modelData
                descr: savedTextsRec.isFavorites ? modelData.descr : ""

                onDeleteItem: {
                    if (savedTextsRec.isFavorites) {
                        fullScreenItem.savedTexts.deleteItem(text)
                    } else {
                        fullScreenItem.savedTexts.deleteClipboardItem(text)
                    }
                }
                onClicked: {
                    event_handler.onKeyReleased(text, "");
                    fullScreenItem.commitPreedit()
                }
            }
        }
    }
}
