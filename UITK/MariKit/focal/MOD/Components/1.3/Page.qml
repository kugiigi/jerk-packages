/*
 * Copyright 2015 Canonical Ltd.
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
import "pageUtils.js" as Utils
// ENH094 - Bottom gesture in UITK
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0
// ENH094 - End

/*!
    \qmltype Page
    \inqmlmodule Lomiri.Components
    \inherits StyledItem
    \ingroup lomiri
    \brief A page is the basic Item that represents a single view in
        an Lomiri application. It is recommended to use the Page inside
        the \l MainView or \l AdaptivePageLayout.

        \l MainView provides a header for Pages it includes if no
        \l header property was set. However, the application header is deprecated
        and it is recommended to set the \l header property instead.

        Anchors and height of a Page are automatically determined to align with
        the header of the \l MainView, but can be overridden.
        Page contents does not automatically leave space for the Page \l header,
        so this must be taken into account when anchoring the contents of the Page.

        Example:
        \qml
            import QtQuick 2.4
            import Lomiri.Components 1.3

            MainView {
                width: units.gu(48)
                height: units.gu(60)

                Page {
                    header: PageHeader {
                        id: pageHeader
                        title: i18n.tr("Example page")

                        trailingActionBar.actions: [
                            Action {
                                iconName: "toolkit_input-search"
                                text: i18n.tr("Search")
                            }
                        ]
                    }

                    Label {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            top: pageHeader.bottom
                            topMargin: units.gu(5)
                        }
                        text: i18n.tr("Hello world!")
                    }
                }
            }
        \endqml
*/
PageTreeNode {
    id: page
    anchors {
        left: parent ? parent.left : undefined
        bottom: parent ? parent.bottom : undefined
    }
    // Set width and height so that a parent Loader can be automatically resized
    // to the size of the loaded Page.
    width: parentNode ? parentNode.width - page.x : undefined
    // FIXME: We no longer need to take the internal header height into account
    //  when we remove MainView's AppHeader.
    height: parentNode ? page.flickable ? parentNode.height : parentNode.height - internal.headerHeight : undefined

    /*!
      \qmlproperty ActrionContext Page::actionContext
      \readonly
      \since Lomiri.Components 1.3
      The action context of the page.
      */
    readonly property alias actionContext: localContext
    ActionContext {
        id: localContext
        active: page.active
        objectName: page.objectName + "Context"
    }

    /*!
      \since Lomiri.Components 1.3
      The header property for this page. Setting this property will reparent the
      header to the page and disable the \l MainView's application header.
      \qml
        Page {
            id: page
            header: PageHeader {
                title: "Page with header"
                trailingActionBar.actions: [
                    Action { iconName: "settings" },
                    Action { iconName: "info" }
                ]
                flickable: myFlickable
            }
        }
      \endqml
      To avoid Page content being occluded by the header, the contents of the Page
      should anchor to the bottom of the header. When the Page contents is flickable,
      the contents does not need to be anchored to the header, but it is recommended
      to use a \l PageHeader or \l Header component as the Page header, and set its
      \l Header::flickable property so that the Flickable gets a top-margin that
      leaves enough space for the header.
      \sa PageHeader, Header
     */
    property Item header
    onHeaderChanged: internal.updateHeader()
    Component.onCompleted: internal.updateHeader()

    /*! \internal */
    isLeaf: true

    /*! \deprecated */
    property string title: parentNode && parentNode.hasOwnProperty("title") ? parentNode.title : ""
    /*! \deprecated */
    property Flickable flickable: Utils.getFlickableChild(page)
    /*! \deprecated */
    readonly property alias head: headerConfig
    PageHeadConfiguration {
        id: headerConfig
        title: page.title
        flickable: page.flickable
        onFlickableChanged: internal.printDeprecationWarning()
        onTitleChanged: internal.printDeprecationWarning()
        onActionsChanged: internal.printDeprecationWarning()
        onBackActionChanged: internal.printDeprecationWarning()
    }

    Item {
        id: internal

        property bool showDeprecationWarning: true
        function printDeprecationWarning() {
            if (internal.showDeprecationWarning) {
                var titleStr = page;
                if (page.title) {
                    titleStr += "\"" + page.title + "\"";
                }
                titleStr += ": "
                print(titleStr + "In Lomiri.Components 1.3, the use of Page.title, Page.flickable and" +
                      " Page.head is deprecated. Use Page.header and the PageHeader component instead.");
                internal.showDeprecationWarning = false;
            }
        }

        property Item previousHeader: null
        function updateHeader() {
            internal.showDeprecationWarning = false;
            if (internal.previousHeader) {
                internal.previousHeader.parent = null;
            }
            if (page.header) {
                internal.previousHeader = page.header;
                page.header.parent = page;
            } else {
                internal.previousHeader = null;
            }
        }

        ///////////////////////////////
        // old header handling below //
        ///////////////////////////////
        property AppHeader header: page.__propagated && page.__propagated.header ? page.__propagated.header : null
        // Used to position the Page when there is no flickable.
        // When there is a flickable, the header will automatically position it.
        property real headerHeight: internal.header && internal.header.visible ?
                                        internal.header.height + internal.header.y : 0

        // Note: The bindings below need to check whether headerConfig.contents
        // is valid in the "value", even when that is required in the Binding's "when"
        // property, to avoid TypeErrors while/after a page becomes (in)active.
        //
        // Note 2: contents.parent binding is made by PageHeadStyle.
        property bool hasParent: headerConfig.contents &&
                                 headerConfig.contents.parent

        Binding {
            target: headerConfig.contents
            property: "visible"
            value: page.active
            when: headerConfig.contents
        }
        Binding {
            target: headerConfig.contents
            property: "anchors.verticalCenter"
            value: internal.hasParent ? headerConfig.contents.parent.verticalCenter :
                                        undefined
            when: headerConfig.contents
        }
        Binding {
            target: headerConfig.contents
            property: "anchors.left"
            value: internal.hasParent ? headerConfig.contents.parent.left : undefined
            when: headerConfig.contents
        }
    }
    // ENH094 - Bottom gesture in UITK
    Settings {
        id: settingsItem
        category: "marikit"
        fileName: "/home/phablet/.config/lomiri-ui-toolkit/marikit.conf"
        property bool showBottomGestureHint: false
        property bool enableBottomSwipeGesture: true
        property bool enableBackAnimation: false
        property bool enableDelayedBackAnimation: false
    }
    
    Rectangle {
        visible: opacity > 0
        opacity: (page.leftActionIsBackAction && bottomBackForwardHandle.swipeProgress > 0.8) ? bottomBackForwardHandle.swipeProgress * 0.6
                                : page.backWasTriggered ? 0.6 : 0
        color: "black"
        anchors.fill: parent
        z: Number.MAX_VALUE
        Behavior on opacity { LomiriNumberAnimation {} }
    }

    Rectangle {
        visible: page.leftActionIsBackAction
        color: theme.palette.normal.base
        width: pageTranslate.x
        anchors {
            right: parent.left
            top: parent.top
            bottom: parent.bottom
        }
    }

    transform: Translate {
        id: pageTranslate
        x: {
            if (!page.leftActionIsBackAction)
                return page.backWasTriggered ? page.width : 0

            if (bottomBackForwardHandle.swipeProgress < 1)
                return bottomBackForwardHandle.distance

            return bottomBackForwardHandle.getStagePixelValue(bottomBackForwardHandle.physicalStageTrigger - 1)
        }
        Behavior on x {
            LomiriNumberAnimation {
                duration: bottomBackForwardHandle.dragging ? LomiriAnimation.SnapDuration : page.animationDuration
            }
        }
    }

    readonly property real headerTrailingActionWidth: page.header ? page.header.trailingActionBar.children[0].children[1].children[0].width : units.gu(4)
    readonly property real headerLeadingActionWidth: page.header ? page.header.leadingActionBar.children[0].children[1].children[0].width : units.gu(4)
    readonly property bool leftActionIsBackAction: settingsItem.enableBackAnimation
                                                        && bottomBackForwardHandle.dragging
                                                        && bottomBackForwardHandle.distance >= 0
                                                        && goBackIcon.enabled
                                                        && (leadingActionVisible.objectName == "pagestack_back_action"
                                                            || leadingActionVisible.iconName === "back"
                                                            || leadingActionVisible.iconName === "go-previous"
                                                            || leadingActionVisible.iconName === "previous"
                                                            )
    property int leadingActionsVisibleCount: 0
    property int trailingActionsVisibleCount: 0
    property var leadingActionVisible
    property var trailingActionVisible
    property bool backWasTriggered: false
    property int animationDuration: LomiriAnimation.BriskDuration

    MariKitGoIndicator {
        id: goForwardIcon

        z: bottomGestures.z
        iconName: "go-next"
        enabled: page.header && page.header.trailingActionBar.width > 0
        swipeProgress: bottomBackForwardHandle.swipeProgress
        anchors {
            right: parent.right
            rightMargin: units.gu(3)
            verticalCenter: parent.verticalCenter
        }
    }

    MariKitGoIndicator {
        id: goBackIcon

        z: bottomGestures.z
        iconName: "go-previous"
        enabled: page.header && page.header.leadingActionBar.width > 0
        swipeProgress: bottomBackForwardHandle.swipeProgress
        anchors {
            left: parent.left
            leftMargin: page.leftActionIsBackAction ? -pageTranslate.x + units.gu(3) : units.gu(3)
            verticalCenter: parent.verticalCenter
        }
    }
    
    Item {
        id: bottomGestures

        z: 999999
        width: Math.min(units.gu(40), page.width * 0.4)
        height: units.gu(2)
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

        onVisibleChanged: if (visible) page.backWasTriggered = false

        states: [
            State {
                when: page.leftActionIsBackAction
                PropertyChanges {
                    target: page
                    clip: false
                }
            }
        ]

        Rectangle {
            id: recVisual

            visible: settingsItem.showBottomGestureHint && bottomBackForwardHandle.enabled
            color: theme.palette.normal.base
            radius: height / 2
            height: units.gu(0.5)
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
            }
        }

        MariKitHorizontalSwipeHandle {
            id: bottomBackForwardHandle

            readonly property Timer delayLeadingTriggerTimer: Timer {
                interval: page.animationDuration
                onTriggered: leadingActionVisible.trigger()
            }
            enabled: page.header && settingsItem.enableBottomSwipeGesture
            // Sometimes header is hidden but should still work
            // && ((page.header.leadingActionBar && page.header.leadingActionBar.visible)
            //                                 || (page.header.trailingActionBar && page.header.trailingActionBar.visible))
            leftAction: goBackIcon
            rightAction: goForwardIcon
            immediateRecognition: false
            usePhysicalUnit: true
            height: units.gu(2)
            swipeHoldDuration: 700
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            rightSwipeHoldEnabled: false
            leftSwipeHoldEnabled: false

            onRightSwipe: {
                if (page.leadingActionsVisibleCount == 1) {
                    if (page.leftActionIsBackAction && settingsItem.enableDelayedBackAnimation) {
                        page.backWasTriggered = true
                        delayLeadingTriggerTimer.restart()
                    } else {
                        leadingActionVisible.trigger()
                    }
                } else if (page.leadingActionsVisibleCount > 1) {
                    PopupUtils.open(leftActionsPopoverComponent, leftPopoverPlaceHolder)
                }
            }
            onLeftSwipe: {
                if (page.trailingActionsVisibleCount == 1) {
                    trailingActionVisible.trigger()
                } else if (page.trailingActionsVisibleCount > 1) {
                    PopupUtils.open(rightActionsPopoverComponent, rightPopoverPlaceHolder)
                }
            }

            onPressedChanged: {
                if (pressed && page.header) {
                    page.leadingActionsVisibleCount = 0
                    page.trailingActionsVisibleCount = 0

                    let leadingActionBarActions = page.header.leadingActionBar.actions

                    if (leadingActionBarActions.length > 0) {
                        for (let i = 0; i < leadingActionBarActions.length; i++) {

                            if (leadingActionBarActions[i].visible
                                    && leadingActionBarActions[i].enabled) {
                                page.leadingActionsVisibleCount += 1
                                page.leadingActionVisible = leadingActionBarActions[i]
                            }
                        }
                    }
                    if (page.leadingActionsVisibleCount == 1) {
                        goBackIcon.iconName = page.leadingActionVisible.iconName
                    } else if (page.leadingActionsVisibleCount > 1) {
                        goBackIcon.iconName = "navigation-menu"
                    } else {
                        goBackIcon.iconName = "go-previous"
                    }
                    
                    let trailingActionBarActions = page.header.trailingActionBar.actions

                    if (trailingActionBarActions.length > 0) {
                        for (let i = 0; i < trailingActionBarActions.length; i++) {

                            if (trailingActionBarActions[i].visible
                                    && trailingActionBarActions[i].enabled) {
                                page.trailingActionsVisibleCount += 1
                                page.trailingActionVisible = trailingActionBarActions[i]
                            }
                        }
                    }
                    if (page.trailingActionsVisibleCount == 1) {
                        goForwardIcon.iconName = page.trailingActionVisible.iconName
                    } else if (page.trailingActionsVisibleCount > 1) {
                        goForwardIcon.iconName = "navigation-menu"
                    } else {
                        goForwardIcon.iconName = "go-next"
                    }
                }
            }
        }
    }

    Item {
        id: leftPopoverPlaceHolder
        height: units.gu(2)
        width: height
        anchors {
            bottom: parent.bottom
            left: parent.left
        }
    }

    Item {
        id: rightPopoverPlaceHolder
        height: units.gu(2)
        width: height
        anchors {
            bottom: parent.bottom
            right: parent.right
        }
    }

    Component {
        id: leftActionsPopoverComponent

        ActionSelectionPopover {
            id: leftActionsPopover

            actions: page.header ? page.header.leadingActionBar.actions : []
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

            actions: page.header ? page.header.trailingActionBar.actions : []
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

    /*
    Label {
        id: labelText

        z: bottomGestures.z
        text: page.header ? page.header.leadingActionBar.visible + " - " + page.header.trailingActionBar.visible : ""
        height: units.gu(5)
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        horizontalAlignment: Text.AlignHCenter
    }
    */
    // ENH094 - End
}
