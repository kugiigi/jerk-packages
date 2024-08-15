/*
 * Copyright 2016 Canonical Ltd.
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

import QtQuick 2.4
import Lomiri.Components 1.3
// ENH192 - Swipe gesture in the header
import Qt.labs.settings 1.0
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.12
// ENH192 - End

/*!
    \qmltype PageHeader
    \inqmlmodule Lomiri.Components
    \ingroup lomiri
    \brief The PageHeader shows a title with a leading and a trailing
        \l ActionBar that add action buttons to the header.

    The colors for foreground, background and the divider are configured
    in the style, so they may be set using \l StyleHints:
    \qml
        PageHeader {
            title: "Colors"
            StyleHints {
                foregroundColor: LomiriColors.orange
                backgroundColor: "black"
                dividerColor: LomiriColors.slate
            }
        }
    \endqml

    See \l Header properties that are inherited by PageHeader to control
    the visibility of the header.
*/
Header {
    id: header
    anchors {
        left: parent ? parent.left : undefined
        right: parent ? parent.right : undefined
    }

    /*!
      The title to display in the header.
      Note that the title will be hidden if the \l contents Item is set.
     */
    property string title

    /*!
      Displayed under the title.
      Hidden when the \l contents Item is set.
     */
    property string subtitle

    /*!
      The contents item to display in the header. By default the contents is
      undefined, and setting it will disable showing of the title and subtitle.

      Example:
      \qml
      PageHeader {
          id: header
          title: "Welcome"
          contents: Rectangle {
              anchors.fill: parent
              color: LomiriColors.red
              Label {
                  anchors.centerIn: parent
                  text: header.title
                  color: "white"
              }
          }
      }
      \endqml
     */
    property Item contents

    Component.onCompleted: contentsHolder.updateContents()
    onContentsChanged: contentsHolder.updateContents()
    onSubtitleChanged: contentsHolder.updateContents()

    Item {
        id: contentsHolder
        anchors {
            left: leading.right
            right: trailing.left
            top: parent.top
            leftMargin: leading.visible ? 0 : units.gu(1)
            rightMargin: trailing.visible ? 0 : units.gu(1)
        }
        height: __styleInstance.contentHeight
        Loader {
            id: titleLoader
            anchors.fill: parent
        }
        Loader {
            id: subtitleLoader
            anchors.fill: parent
        }

        property Item previousContents: null
        property Item previousContentsParent: null

        function updateContents() {
            if (!__styleInstance) return; // the style needs to be loaded first
            if (previousContents) {
                previousContents.parent = previousContentsParent;
            }
            if (header.contents) {
                titleLoader.sourceComponent = null;
                previousContents = header.contents;
                previousContentsParent = header.contents.parent;
                header.contents.parent = contentsHolder;
            } else {
                previousContents = null;
                previousContentsParent = null;
                titleLoader.sourceComponent = __styleInstance.titleComponent;
                if (!subtitle) {
                    subtitleLoader.sourceComponent = null;
                } else {
                    subtitleLoader.sourceComponent = __styleInstance.subtitleComponent;
                }
            }
        }

        // When the style changes, make sure that the titleLoader loads
        //  the new titleComponent.
        property Item styleInstance: __styleInstance
        onStyleInstanceChanged: updateContents()
    }

    /*!
      The actions to be shown in the leading action bar.
      This property is automatically set by the
      \l AdaptivePageLayout and other navigation components to configure the
      back action for the \l Page.
      Application developers should not set this property, because the
      value may be overridden by Lomiri components that have navigation.
      Instead, set \l leadingActionBar's actions property.
     */
    property list<Action> navigationActions

    /*!
      \qmlproperty ActionBar leadingActionBar
      The \l ActionBar for the leading navigation actions.
      Example:
      \qml
      PageHeader {
          leadingActionBar.actions: [
              Action {
                  iconName: "back"
                  text: "Back"
              }
          ]
      }
      \endqml
      The default value of \l leadingActionBar actions is
      \l navigationActions, but that value can be changed to show
      different actions in front of the title.
      The leading action bar has only one slot.
      See \l ActionBar.
     */
    readonly property alias leadingActionBar: leading
    ActionBar {
        id: leading
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: units.gu(1)
        }
        height: header.__styleInstance.contentHeight
        numberOfSlots: 1
        delegate: header.__styleInstance.defaultActionDelegate
        actions: header.navigationActions
        visible: leading.width > 0 // at least 1 visible action
        StyleHints {
            ignoreUnknownProperties: false
            overflowIconName: "navigation-menu"
            backgroundColor: header.__styleInstance.backgroundColor
        }
        // ENH192 - Swipe gesture in the header
        opacity: goBackIcon.visible ? 0.2 : 1
        Behavior on opacity { LomiriNumberAnimation {} }
        // ENH192 - End
    }

    /*!
      \qmlproperty ActionBar trailingActionBar
      The \l ActionBar with trailing actions.
      Example:
      \qml
      PageHeader {
          trailingActionBar {
              actions: [
                  Action {
                      iconName: "settings"
                      text: "first"
                  },
                  Action {
                      iconName: "info"
                      text: "second"
                  },
                  Action {
                      iconName: "toolkit_input-search"
                      text: "third"
                  }
             ]
             numberOfSlots: 2
          }
      }
      \endqml
      By default the trailing action bar automatically adapts
      its number of slots to the available space in the range
      from 3 to 6.
      See \l ActionBar.
      */
    readonly property alias trailingActionBar: trailing
    ActionBar {
        id: trailing
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: units.gu(1)
        }
        height: header.__styleInstance.contentHeight
        numberOfSlots: MathUtils.clamp(0.3*header.width/units.gu(4), 3, 6)
        delegate: header.__styleInstance.defaultActionDelegate
        visible: trailing.width > 0 // at least 1 visible action
        StyleHints {
            ignoreUnknownProperties: false
            backgroundColor: header.__styleInstance.backgroundColor
        }
        // ENH192 - Swipe gesture in the header
        opacity: goForwardIcon.visible ? 0.2 : 1
        Behavior on opacity { LomiriNumberAnimation {} }
        // ENH192 - End
    }

    /*!
      Item shown at the bottom of the header.
      The extension can be any Item, but it must have a height so that
      the PageHeader correctly adjusts its height for the extension to fit.
      The extension Item should anchor to the left, right and bottom of
      its parent so that it will be automatically positioned above the
      header divider. This property replaces the sections property. Sections
      can now be added to the header as follows:
      \qml
        PageHeader {
            title: "Header with sections"
            extension: Sections {
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    bottom: parent.bottom
                }
                model: ["one", "two", "three"]
            }
        }
      \endqml
      See \l Toolbar and \l Sections.
    */
    property Item extension

    onExtensionChanged: extensionHolder.updateExtension()
    Item {
        id: extensionHolder
        anchors {
            left: parent.left
            right: parent.right
            top: contentsHolder.bottom
        }
        height: header.extension ? header.extension.height : 0

        property Item previousExtension: header.extension
        property Item previousExtensionParent: null

        function updateExtension() {
            if (previousExtension) {
                previousExtension.parent = previousExtensionParent;
            }
            if (header.extension) {
                previousExtension = header.extension;
                previousExtensionParent = header.extension.parent;
                header.extension.parent = extensionHolder;
            } else {
                previousExtension = null;
                previousExtensionParent = null;
            }
        }
    }

    /*!
      \qmlproperty Sections sections
      Sections shown at the bottom of the header. By default,
      the sections will only be visible if its actions or model
      is set. See \l Sections.
      \deprecated Use \l extension instead.
     */
    readonly property alias sections: sectionsItem
    Sections {
        id: sectionsItem
        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            top: contentsHolder.bottom
        }
        visible: model && model.length > 0 && !header.extension
        height: visible ? implicitHeight : 0
    }

    styleName: "PageHeaderStyle"
    // ENH192 - Swipe gesture in the header
    Settings {
        id: settingsItem
        category: "marikit"
        fileName: "/home/phablet/.config/lomiri-ui-toolkit/marikit.conf"
        property bool enableHeaderSwipeGesture: true
    }
    readonly property real headerTrailingActionWidth: header ? header.trailingActionBar.children[0].children[1].children[0].width : units.gu(4)
    readonly property real headerLeadingActionWidth: header ? header.leadingActionBar.children[0].children[1].children[0].width : units.gu(4)
    property int leadingActionsVisibleCount: 0
    property int trailingActionsVisibleCount: 0
    property var leadingActionVisible
    property var trailingActionVisible

    MariKitHorizontalSwipeHandle {
        id: bottomBackForwardHandle

        enabled: settingsItem.enableHeaderSwipeGesture
        leftAction: goBackIcon
        rightAction: goForwardIcon
        immediateRecognition: false
        usePhysicalUnit: true
        swipeHoldDuration: 700
        anchors {
            fill: parent
            bottomMargin: header.extension ? header.extension.height : 0
        }

        rightSwipeHoldEnabled: false
        leftSwipeHoldEnabled: false

        onRightSwipe: {
            if (header.leadingActionsVisibleCount == 1) {
                leadingActionVisible.trigger()
            } else if (header.leadingActionsVisibleCount > 1) {
                if (header.leadingActionBar.__styleInstance.overFlowAction) {
                    header.leadingActionBar.__styleInstance.overFlowAction.trigger()
                }
            }
        }
        onLeftSwipe: {
            if (header.trailingActionsVisibleCount == 1) {
                trailingActionVisible.trigger()
            } else if (header.trailingActionsVisibleCount > 1) {
                PopupUtils.open(rightActionsPopoverComponent, rightPopoverPlaceHolder)
            }
        }

        onPressedChanged: {
            if (pressed) {
                if (header.parent instanceof Page) {
                    // Maybe animate too?
                }
                header.leadingActionsVisibleCount = 0
                header.trailingActionsVisibleCount = 0

                let leadingActionBarActions = header.leadingActionBar.actions

                if (leadingActionBarActions.length > 0) {
                    for (let i = 0; i < leadingActionBarActions.length; i++) {
                        if (leadingActionBarActions[i].visible
                                && leadingActionBarActions[i].enabled) {
                            header.leadingActionsVisibleCount += 1
                            header.leadingActionVisible = leadingActionBarActions[i]
                        }
                    }
                }
                if (header.leadingActionsVisibleCount == 1) {
                    goBackIcon.iconName = header.leadingActionVisible.iconName
                } else if (header.leadingActionsVisibleCount > 1) {
                    goBackIcon.iconName = "navigation-menu"
                } else {
                    goBackIcon.iconName = "go-previous"
                }
                
                let trailingActionBarActions = header.trailingActionBar.actions

                if (trailingActionBarActions.length > 0) {
                    for (let i = 0; i < trailingActionBarActions.length; i++) {

                        if (trailingActionBarActions[i].visible
                                && trailingActionBarActions[i].enabled) {
                            header.trailingActionsVisibleCount += 1
                            header.trailingActionVisible = trailingActionBarActions[i]
                        }
                    }
                }
                if (header.trailingActionsVisibleCount == 1) {
                    goForwardIcon.iconName = header.trailingActionVisible.iconName
                } else if (header.trailingActionsVisibleCount > 1) {
                    goForwardIcon.iconName = "navigation-menu"
                } else {
                    goForwardIcon.iconName = "go-next"
                }
            }
        }
    }

    Item {
        anchors.fill: bottomBackForwardHandle

        MariKitGoIndicator {
            id: goForwardIcon

            iconName: "go-next"
            enabled: header.trailingActionBar.width > 0
            swipeProgress: bottomBackForwardHandle.swipeProgress
            defaultWidth: units.gu(2.8)
            anchors {
                right: parent.right
                rightMargin: units.gu(1.5)
                verticalCenter: parent.verticalCenter
            }
        }

        MariKitGoIndicator {
            id: goBackIcon

            iconName: "go-previous"
            enabled: header.leadingActionBar.width > 0
            swipeProgress: bottomBackForwardHandle.swipeProgress
            defaultWidth: units.gu(2.8)
            anchors {
                left: parent.left
                leftMargin: units.gu(1.5)
                verticalCenter: parent.verticalCenter
            }
        }
    }

    Item {
        id: leftPopoverPlaceHolder
        height: units.gu(2)
        width: height
        anchors {
            top: bottomBackForwardHandle.bottom
            left: bottomBackForwardHandle.left
        }
    }

    Item {
        id: rightPopoverPlaceHolder
        height: units.gu(2)
        width: height
        anchors {
            top: bottomBackForwardHandle.bottom
            right: bottomBackForwardHandle.right
        }
    }

    Component {
        id: leftActionsPopoverComponent

        ActionSelectionPopover {
            id: leftActionsPopover

            actions: header.leadingActionBar.actions
            borderEnabled: true
            delegate: ListItem {
                visible: action.visible && action.enabled
                height: visible ? implicitHeight : 0

                RowLayout {
                    anchors.fill: parent
                    spacing: units.gu(2)
                    Icon {
                        id: iconItem2
                        Layout.leftMargin: units.gu(2)
                        implicitWidth: units.gu(2)
                        implicitHeight: implicitWidth
                        visible: name !== ""
                        name: action.iconName
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.rightMargin: units.gu(2)
                        text: action.text
                        horizontalAlignment: iconItem2.visible ? Text.AlignLeft : Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
                onClicked: PopupUtils.close(leftActionsPopover);
            }
        }
    }

    Component {
        id: rightActionsPopoverComponent

        ActionSelectionPopover {
            id: rightActionsPopover

            actions: header.trailingActionBar.actions
            borderEnabled: true
            delegate: ListItem {
                visible: action.visible && action.enabled
                height: visible ? implicitHeight : 0

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: units.gu(2)
                        rightMargin: units.gu(2)
                    }
                    spacing: units.gu(2)
                    Icon {
                        id: iconItem
                        Layout.alignment: Qt.AlignHCenter
                        color: theme.palette.normal.overlayText
                        implicitWidth: units.gu(2)
                        implicitHeight: implicitWidth
                        visible: name !== ""
                        name: action.iconName
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        text: action.text
                        visible: text !== ""
                        horizontalAlignment: iconItem.visible ? Text.AlignLeft : Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
                onClicked: PopupUtils.close(rightActionsPopover);
            }
        }
    }
    // ENH192 - End
}
