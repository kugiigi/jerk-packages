/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// ENH215 - Shortcuts bar
// import QtQuick 2.4
import QtQuick 2.15
import QtGraphicalEffects 1.15
// ENH215 - End
import Lomiri.Components 1.3
import "keys/key_constants.js" as UI
// ENH120 - Saved Texts
import "keys" as Keys
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12
// ENH120 - End

Rectangle {

    id: wordRibbonCanvas
    objectName: "wordRibbenCanvas"
    state: "NORMAL"

    // ENH215 - Shortcuts bar
    property bool enableShortcutsToolbar: false
    property var leadingActions
    property var trailingActions

    function showTempActionsInToolbar(_leadingActions, _trailingActions) {
        shortcutsToolbarLoader.showTempActions(_leadingActions, _trailingActions)
    }

    function resetToolbarActions() {
        shortcutsToolbarLoader.resetActions()
    }
    // ENH215 - End

    Rectangle {
        anchors.fill: parent
        color: fullScreenItem.theme.backgroundColor
    }

    // TODO: Check again why visible count gets binding loop when loader is used
    MKActionsToolbar {
        id: shortcutsToolbarLoader

        visible: wordRibbonCanvas.enableShortcutsToolbar
        anchors.fill: parent

        function showTempActions(_leadingActions, _trailingActions) {
            leadingActions = _leadingActions
            trailingActions = _trailingActions
        }

        function resetActions() {
            leadingActions = Qt.binding( function() { return  wordRibbonCanvas.leadingActions } )
            trailingActions = Qt.binding( function() { return  [ toggleSuggestionsAction, ...wordRibbonCanvas.trailingActions ] } )
        }

        leadingActions: wordRibbonCanvas.leadingActions
        trailingActions: [ toggleSuggestionsAction, ...wordRibbonCanvas.trailingActions ]
    }

    // Background for the word suggestions
    Rectangle {
        anchors.fill: listView
        color: fullScreenItem.theme.backgroundColor
        // For some reason count is always 1 even when empty after initial typing
        // 42 is the width when empty
        visible: listView.visible
    }
    MKBaseAction {
        id: toggleSuggestionsAction

        visible: shortcutsToolbarLoader.visible && listView.hasWords
        text: i18n.tr("Show word suggestions")
        iconName: "wechat-symbolic"
        onTrigger: listView.expanded = true;
    }
    // ENH215 - End

    ListView {
        id: listView
        objectName: "wordListView"
        // ENH215 - Shortcuts bar
        // For some reason count is always 1 even when empty after initial typing
        // 48 is the width when empty
        readonly property bool hasWords: contentWidth > 48
        property bool expanded: hasWords
        property real leftOffset: expanded && hasWords ? 0 : width

        boundsBehavior: Flickable.DragOverBounds
        // anchors.fill: parent
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            leftMargin: shortcutsToolbarLoader.visible ? leftOffset : 0
        }
        width: shortcutsToolbarLoader.visible ? parent.width - hideSuggestionsButton.width : parent.width
        opacity: shortcutsToolbarLoader.visible ? (expanded ? 1 : 0)  : 1
        visible: opacity > 0

        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }
        Behavior on leftOffset {
            enabled: listView.hasWords // Do not animate when no expanding/collapsing
            LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
        }

        onHasWordsChanged: {
            expanded = hasWords;
        }
        // ENH215 - End
        clip: true

        model: maliit_wordribbon

        orientation: ListView.Horizontal
        delegate: wordCandidateDelegate
    }
    // ENH215 - Shortcuts bar
    Keys.ActionsToolbarButton {
        id: hideSuggestionsButton

        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        width: units.gu(5)
        opacity: shortcutsToolbarLoader.visible && listView.hasWords && listView.leftOffset < listView.width ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }

        customAction: MKBaseAction {
            text: i18n.tr("Hide word suggestions")
            iconName: "go-next"
            onTrigger: listView.expanded = false;
        }
    }

    // Side fade
    Item {
        visible: hideSuggestionsButton.visible
                    && listView.contentWidth > listView.width
                    && !listView.atXEnd
        width: units.gu(5)
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: hideSuggestionsButton.left
        }

        Rectangle {
            id: content

            anchors.fill: parent
            color: fullScreenItem.theme.backgroundColor
            visible: false
        }

        LinearGradient {
            id: mask
            anchors.fill: parent
            start: Qt.point(0, 0)
            end: Qt.point(width, 0)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "white" }
            }
            visible: false
        }

        OpacityMask {
            anchors.fill: mask
            source: content
            maskSource: mask
        }
    }
    // ENH215 - End

    Component {
        id: wordCandidateDelegate
        Item {
            id: wordCandidateItem
            width: wordItem.width + units.gu(2)
            height: wordRibbonCanvas.height
            anchors.margins: 0
            property alias word_text: wordItem // For testing in Autopilot
            property bool textBold: isPrimaryCandidate || listView.count == 1 // Exposed for autopilot

            Item {
                anchors.fill: parent
                anchors.margins: {
                    top: units.gu(0)
                    bottom: units.gu(0)
                    left: units.gu(2)
                    right: units.gu(2)
                }

                Label {
                    id: wordItem
                    // ENH072 - Custom ribbon height
                    // font.pixelSize: units.dp(fullScreenItem.tablet ? UI.tabletWordRibbonFontSize : UI.phoneWordRibbonFontSize)
                    font.pixelSize: {
                        if (fullScreenItem.settings.useCustomRibbonHeight) {
                            return units.dp(fullScreenItem.settings.customRibbonFontSize)
                        } else {
                            if (fullScreenItem.tablet) {
                                return units.dp(UI.tabletWordRibbonFontSize)
                            } else {
                                return units.dp(UI.phoneWordRibbonFontSize)
                            }
                        }
                    }
                    // ENH072 - End
                    // ENH091 - Font settings
                    // font.family: UI.fontFamily
                    font.family: fullScreenItem.settings.useCustomFont
                            && fullScreenItem.settings.customFont ? fullScreenItem.settings.customFont
                                                                  : UI.fontFamily
                    // ENH091 - End
                    font.weight: textBold ? Font.Bold : Font.Light
                    text: word;
                    anchors.centerIn: parent
                    // ENH092 - Word ribbon font color
                    color: fullScreenItem.theme.fontColor
                    // ENH092 - End
                }
            }

            MouseArea {
                anchors.fill: wordCandidateItem
                onPressed: {
                    fullScreenItem.keyFeedback();
                    
                    wordRibbonCanvas.state = "SELECTED"
                    event_handler.onWordCandidatePressed(wordItem.text, isUserInput)
                }
                onReleased: {
                    wordRibbonCanvas.state = "NORMAL"
                    event_handler.onWordCandidateReleased(wordItem.text, isUserInput)
                }
            }
        }
    }

    states: [
        State {
            name: "NORMAL"
            PropertyChanges {
                target: wordRibbonCanvas
                color: "transparent"
            }
        },
        State {
            name: "SELECTED"
            PropertyChanges {
                target: wordRibbonCanvas
                color: "#e4e4e4"
            }
        }
    ]

}

