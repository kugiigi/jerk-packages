// ENH120 - Saved Texts
import QtQuick 2.12
import Lomiri.Components 1.3

Loader {
    id: savedTextsArea

    property bool isAscending: true

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
        color: fullScreenItem.theme.charKeyPressedColor
        clip: true

        Label {
            color: fullScreenItem.theme.fontColor
            visible: savedTextListView.count === 0
            text: i18n.tr("No saved texts")
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textSize: Label.Large
            wrapMode: Text.WordWrap
            anchors {
                fill: parent
                margins: units.gu(1)
            }
        }

        ListView {
            id: savedTextListView

            anchors.fill: parent
            model: savedTextsArea.isAscending ? fullScreenItem.sortArray(fullScreenItem.settings.savedTexts, "text", true)
                        : fullScreenItem.sortArray(fullScreenItem.settings.savedTexts, "text", false)
            currentIndex: -1
            delegate: MKSavedTextsDelegate {
                text: modelData.text
                descr: modelData.descr

                onDeleteItem: savedTextsObj.deleteItem(text)
                onClicked: {
                    event_handler.onKeyReleased(text, "");
                    fullScreenItem.commitPreedit()
                }
            }
        }
    }
}
