/*
 * Copyright 2020 UBports Foundation
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtWebEngine 1.5
import Morph.Web 0.1
import ".." as Common
import "sapot" as Sapot

FocusScope {
    id: settingsItem

    property QtObject settingsObject

    signal clearCache()
    signal clearAllCookies()
    signal done()
    signal showDownloadsPage()

    Common.BrowserPage {
        title: i18n.tr("WebappContainer Settings")

        anchors.fill: parent
        focus: true

        onBack: settingsItem.done()

        Flickable {
            anchors.fill: parent
            contentHeight: settingsCol.height
            clip: true

            Column {
                id: settingsCol

                width: parent.width

                Label {
                    text: i18n.tr("Browsing")
                    textSize: Label.XLarge
                    verticalAlignment: Label.AlignVCenter
                    height: units.gu(6)
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        right: parent.right
                        rightMargin: units.gu(2)
                    }
                }

                ListItem {
                    objectName: "restorePreviousURL"

                    ListItemLayout {
                        title.text: i18n.tr("Restore previous session's URL")
                        CheckBox {
                            id: restorePreviousURL
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.restorePreviousURL = checked
                        }
                    }

                    Binding {
                        target: restorePreviousURL
                        property: "checked"
                        value: settingsObject.restorePreviousURL
                    }
                }

                ListItem {
                    objectName: "autoDeskMobSwitch"

                    ListItemLayout {
                        title.text: i18n.tr("Auto switch requested site")
                        subtitle.text: i18n.tr("Automatically switch between Desktop and Mobile version of sites based on web view's width")
                        CheckBox {
                            id: autoDeskMobSwitch
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.autoDeskMobSwitch = checked
                        }
                    }

                    Binding {
                        target: autoDeskMobSwitch
                        property: "checked"
                        value: settingsObject.autoDeskMobSwitch
                    }
                }

                ListItem {
                    objectName: "autoDeskMobSwitchReload"

                    ListItemLayout {
                        title.text: i18n.tr("Reload when site version changed")
                        subtitle.text: i18n.tr("Automatically reload page when the requested site version was changed")
                        CheckBox {
                            id: autoDeskMobSwitchReload
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.autoDeskMobSwitchReload = checked
                        }
                    }

                    Binding {
                        target: autoDeskMobSwitchReload
                        property: "checked"
                        value: settingsObject.autoDeskMobSwitchReload
                    }
                }

                ListItem {
                    objectName: "setDesktopMode"
                    visible: webapp.currentWebview && webapp.currentWebview.context.__ua.calcScreenSize() == "small"

                    ListItemLayout {
                        title.text: i18n.tr("Force desktop site")
                        subtitle.text: i18n.tr("Request desktop version of sites as default")

                        CheckBox {
                            id: setDesktopMode
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.setDesktopMode = checked
                        }
                    }

                    Binding {
                        target: setDesktopMode
                        property: "checked"
                        value: settingsObject.setDesktopMode
                    }
                }

                ListItem {
                    objectName: "forceMobileSite"
                    visible: webapp.currentWebview && webapp.currentWebview.context.__ua.calcScreenSize() !== "small"

                    ListItemLayout {
                        title.text: i18n.tr("Force mobile site")
                        subtitle.text: i18n.tr("Request mobile version of sites as default")
                        CheckBox {
                            id: forceMobileSite
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.forceMobileSite = checked
                        }
                    }

                    Binding {
                        target: forceMobileSite
                        property: "checked"
                        value: settingsObject.forceMobileSite
                    }
                }

                Sapot.ComboBoxItem {
                    id: defaultSearchEngine

                    property int settingIndex: -1

                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        right: parent.right
                        rightMargin: units.gu(2)
                    }

                    height: units.gu(7)
                    text: i18n.tr("Search engine")
                    model: webapp.searchEngines
                    currentIndex: settingIndex
                    textRole: "name"

                    onCurrentIndexChanged: {
                        settingsObject.defaultSearchEngine = currentIndex
                    }

                    Binding {
                        target: defaultSearchEngine
                        property: "settingIndex"
                        value: settingsObject.defaultSearchEngine
                    }
                }

                ListItem {
                    objectName: "incognitoOverlay"

                    ListItemLayout {
                        title.text: i18n.tr("Incognito Overlay (External links)")
                        subtitle.text: i18n.tr("External links opened in the overlay will be in incognito mode")
                        CheckBox {
                            id: incognitoOverlay
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.incognitoOverlay = checked
                        }
                    }

                    Binding {
                        target: incognitoOverlay
                        property: "checked"
                        value: settingsObject.incognitoOverlay
                    }
                }

                Sapot.ComboBoxItem {
                    id: externalUrlHandling

                    property int settingIndex: -1

                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        right: parent.right
                        rightMargin: units.gu(2)
                    }

                    height: units.gu(7)
                    text: i18n.tr("External URL Handling")
                    model: [
                        i18n.tr("Block all")
                        ,i18n.tr("Open in overlay")
                        ,i18n.tr("Open externally")
                        ,i18n.tr("Always ask")
                    ]
                    currentIndex: settingIndex

                    onCurrentIndexChanged: {
                        settingsObject.externalUrlHandling = currentIndex
                    }

                    Binding {
                        target: externalUrlHandling
                        property: "settingIndex"
                        value: settingsObject.externalUrlHandling
                    }
                }

                ListItem {
                    objectName: "askWhenOpeningLinkOutside"

                    ListItemLayout {
                        title.text: i18n.tr("Ask before opening links externally")
                        CheckBox {
                            id: askWhenOpeningLinkOutside
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.askWhenOpeningLinkOutside = checked
                        }
                    }

                    Binding {
                        target: askWhenOpeningLinkOutside
                        property: "checked"
                        value: settingsObject.askWhenOpeningLinkOutside
                    }
                }

                ListItem {
                    objectName: "autoFitToWidthEnabled"

                    ListItemLayout {
                        title.text: i18n.tr("Automatic fit to width")
                        subtitle.text: i18n.tr("Adjusts the width of the website to the window")
                        CheckBox {
                            id: autoFitToWidthEnabledCheckbox
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.autoFitToWidthEnabled = checked
                        }
                    }

                    Binding {
                        target: autoFitToWidthEnabledCheckbox
                        property: "checked"
                        value: settingsObject.autoFitToWidthEnabled
                    }
                }

                ListItem {
                    objectName: "defaultZoomFactor"

                    ListItemLayout {
                        title.text: i18n.tr("Default Zoom")
                        SpinBox {
                          id: defaultZoomFactorSelector
                          value: Math.round(settingsObject.zoomFactor * 100 * stepSize) / stepSize
                          from: 25
                          to: 500
                          stepSize: 5
                          textFromValue: function(value, locale) {
                            return value + "%";
                          }
                          onValueModified: {
                            settingsObject.zoomFactor = (Math.round(value / stepSize) * stepSize) / 100
                          }
                        }
                        Icon {
                            id: resetZoom
                            name: "reset"

                            height: units.gu(2)
                            width: height
                            opacity: (settingsObject.zoomFactor === 1.0) ? 0.5 : 1

                            MouseArea {
                                anchors.fill: parent
                                onClicked: settingsObject.zoomFactor = 1.0
                            }

                            anchors {
                                leftMargin: units.gu(1)
                                topMargin: units.gu(2)
                            }
                        }
                    }
                }
                
                ListItem {
                    objectName: "loadImages"

                    ListItemLayout {
                        title.text: i18n.tr("Load Images")
                        subtitle.text: i18n.tr("Automatically load images on web pages")
                        CheckBox {
                            id: loadImagesCheckbox
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.loadImages = checked
                        }
                    }

                    Binding {
                        target: loadImagesCheckbox
                        property: "checked"
                        value: settingsObject.loadImages
                    }
                }

                ListItem {
                    objectName: "downloads"

                    ListItemLayout {
                        title.text: i18n.tr("Downloads")
                        ProgressionSlot {}
                    }

                    onClicked: {
                        showDownloadsPage();
                        done();
                    }
                }

                Label {
                    text: i18n.tr("Accessibility")
                    textSize: Label.XLarge
                    verticalAlignment: Label.AlignVCenter
                    height: units.gu(6)
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        right: parent.right
                        rightMargin: units.gu(2)
                    }
                }

                ListItem {
                    objectName: "enableHaptics"

                    ListItemLayout {
                        title.text: i18n.tr("Enable haptics")
                        subtitle.text: i18n.tr("Haptic feedback when pressing or using swipe gestures")
                        CheckBox {
                            id: enableHaptics
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.enableHaptics = checked
                        }
                    }

                    Binding {
                        target: enableHaptics
                        property: "checked"
                        value: settingsObject.enableHaptics
                    }
                }

                ListItem {
                    objectName: "appWideScrollPositioner"

                    ListItemLayout {
                        title.text: i18n.tr("Enable scroll positioner")
                        subtitle.text: i18n.tr("Floating button that scroll to the top or bottom of web pages")
                        CheckBox {
                            id: appWideScrollPositioner
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.appWideScrollPositioner = checked
                        }
                    }

                    Binding {
                        target: appWideScrollPositioner
                        property: "checked"
                        value: settingsObject.appWideScrollPositioner
                    }
                }

                Sapot.ComboBoxItem {
                    id: scrollPositionerPosition

                    property int settingIndex: -1

                    anchors {
                        left: parent.left
                        leftMargin: units.gu(3)
                        right: parent.right
                        rightMargin: units.gu(2)
                    }
                    visible: settingsObject.appWideScrollPositioner

                    height: units.gu(7)
                    text: i18n.tr("Position")
                    model: [
                        i18n.tr("Right")
                        ,i18n.tr("Left")
                        ,i18n.tr("Middle")
                    ]
                    currentIndex: settingIndex

                    onCurrentIndexChanged: {
                        settingsObject.scrollPositionerPosition = currentIndex
                    }

                    Binding {
                        target: scrollPositionerPosition
                        property: "settingIndex"
                        value: settingsObject.scrollPositionerPosition
                    }
                }

                Sapot.ComboBoxItem {
                    id: scrollPositionerPositionWide

                    property int settingIndex: -1

                    anchors {
                        left: parent.left
                        leftMargin: units.gu(3)
                        right: parent.right
                        rightMargin: units.gu(2)
                    }
                    visible: settingsObject.appWideScrollPositioner

                    height: units.gu(7)
                    text: i18n.tr("Position (wide layout)")
                    model: [
                        i18n.tr("Right")
                        ,i18n.tr("Left")
                        ,i18n.tr("Middle")
                    ]
                    currentIndex: settingIndex

                    onCurrentIndexChanged: {
                        settingsObject.scrollPositionerPositionWide = currentIndex
                    }

                    Binding {
                        target: scrollPositionerPositionWide
                        property: "settingIndex"
                        value: settingsObject.scrollPositionerPositionWide
                    }
                }

                ListItem {
                    objectName: "scrollPositionerSize"

                    visible: settingsObject.appWideScrollPositioner

                    ListItemLayout {
                        title.text: i18n.tr("Button size")
                        padding.leading: units.gu(2)

                        SpinBox {
                          id: scrollPositionerSize
                          value: settingsObject.scrollPositionerSize
                          from: 2
                          to: 10
                          stepSize: 1
                          onValueModified: {
                            settingsObject.scrollPositionerSize = value
                          }
                        }
                        Icon {
                            id: resetScrollPositionerSize
                            name: "reset"

                            height: units.gu(2)
                            width: height
                            opacity: (settingsObject.scrollPositionerSize === 8) ? 0.5 : 1

                            MouseArea {
                                anchors.fill: parent
                                onClicked: settingsObject.scrollPositionerSize = 8
                            }

                            anchors {
                                leftMargin: units.gu(1)
                                topMargin: units.gu(2)
                            }
                        }
                    }
                }

                ListItem {
                    objectName: "enableFloatingScrollButton"

                    ListItemLayout {
                        title.text: i18n.tr("Enable floating scroll button")
                        subtitle.text: i18n.tr("Floating button that can be dragged to scroll the web page")
                        CheckBox {
                            id: enableFloatingScrollButton
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.enableFloatingScrollButton = checked
                        }
                    }

                    Binding {
                        target: enableFloatingScrollButton
                        property: "checked"
                        value: settingsObject.enableFloatingScrollButton
                    }
                }

                ListItem {
                    objectName: "enableFloatingScrollButtonAsPositioner"

                    visible: settingsObject.enableFloatingScrollButton

                    ListItemLayout {
                        title.text: i18n.tr("Use as scroll positioner")
                        subtitle.text: i18n.tr("Floating button can be used to scroll to top and bottom")
                        padding.leading: units.gu(2)

                        CheckBox {
                            id: enableFloatingScrollButtonAsPositioner
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.enableFloatingScrollButtonAsPositioner = checked
                        }
                    }

                    Binding {
                        target: enableFloatingScrollButtonAsPositioner
                        property: "checked"
                        value: settingsObject.enableFloatingScrollButtonAsPositioner
                    }
                }

                ListItem {
                    objectName: "floatingScrollButtonSize"

                    visible: settingsObject.enableFloatingScrollButton
                    ListItemLayout {
                        title.text: i18n.tr("Button size")
                        padding.leading: units.gu(2)

                        SpinBox {
                          id: floatingScrollButtonSize
                          value: settingsObject.floatingScrollButtonSize
                          from: 2
                          to: 10
                          stepSize: 1
                          onValueModified: {
                            settingsObject.floatingScrollButtonSize = value
                          }
                        }
                        Icon {
                            id: resetFloatingScrollButtonSize
                            name: "reset"

                            height: units.gu(2)
                            width: height
                            opacity: (settingsObject.floatingScrollButtonSize === 6) ? 0.5 : 1

                            MouseArea {
                                anchors.fill: parent
                                onClicked: settingsObject.floatingScrollButtonSize = 6
                            }

                            anchors {
                                leftMargin: units.gu(1)
                                topMargin: units.gu(2)
                            }
                        }
                    }
                }
                ListItem {
                    objectName: "floatingScrollButtonSideMargin"

                    visible: settingsObject.enableFloatingScrollButton

                    ListItemLayout {
                        title.text: i18n.tr("Side margin")
                        padding.leading: units.gu(2)

                        SpinBox {
                          id: floatingScrollButtonSideMargin
                          value: settingsObject.floatingScrollButtonSideMargin
                          from: 0
                          to: 6
                          stepSize: 1
                          onValueModified: {
                            settingsObject.floatingScrollButtonSideMargin = value
                          }
                        }
                        Icon {
                            id: resetFloatingScrollButtonSideMargin
                            name: "reset"

                            height: units.gu(2)
                            width: height
                            opacity: (settingsObject.floatingScrollButtonSideMargin === 2) ? 0.5 : 1

                            MouseArea {
                                anchors.fill: parent
                                onClicked: settingsObject.floatingScrollButtonSideMargin = 2
                            }

                            anchors {
                                leftMargin: units.gu(1)
                                topMargin: units.gu(2)
                            }
                        }
                    }
                }

                ListItem {
                    objectName: "floatingScrollButtonVerticalMargin"

                    visible: settingsObject.enableFloatingScrollButton

                    ListItemLayout {
                        title.text: i18n.tr("Vertical margin")
                        padding.leading: units.gu(2)

                        SpinBox {
                          id: floatingScrollButtonVerticalMargin
                          value: settingsObject.floatingScrollButtonVerticalMargin
                          from: 0
                          to: 20
                          stepSize: 1
                          onValueModified: {
                            settingsObject.floatingScrollButtonVerticalMargin = value
                          }
                        }
                        Icon {
                            id: resetfloatingScrollButtonVerticalMargin
                            name: "reset"

                            height: units.gu(2)
                            width: height
                            opacity: (settingsObject.floatingScrollButtonVerticalMargin === 2) ? 0.5 : 1

                            MouseArea {
                                anchors.fill: parent
                                onClicked: settingsObject.floatingScrollButtonVerticalMargin = 2
                            }

                            anchors {
                                leftMargin: units.gu(1)
                                topMargin: units.gu(2)
                            }
                        }
                    }
                }

                Sapot.ComboBoxItem {
                    id: headerHideSettings

                    property int settingIndex: -1

                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        right: parent.right
                        rightMargin: units.gu(2)
                    }

                    height: units.gu(7)
                    text: i18n.tr("Auto hide title bar")
                    model: [
                        i18n.tr("Disabled")
                        ,i18n.tr("On scroll")
                        ,i18n.tr("Times out")
                        ,i18n.tr("Always hide")
                    ]
                    currentIndex: settingIndex

                    onCurrentIndexChanged: {
                        settingsObject.headerHide = currentIndex
                    }

                    Binding {
                        target: headerHideSettings
                        property: "settingIndex"
                        value: settingsObject.headerHide
                    }
                }

                Label {
                    id: autoHideNote

                    text: i18n.tr("** %1").arg(settingsObject.headerHide == 2 ? i18n.tr("Bottom gestures and hovering at the top shows the title bar")
                                                                    : i18n.tr("Hover at the top to show the title bar"))
                    visible: settingsObject.headerHide >= 2
                    verticalAlignment: Label.AlignVCenter
                    horizontalAlignment: Label.AlignRight
                    wrapMode: Text.WordWrap
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        right: parent.right
                        rightMargin: units.gu(2)
                    }
                }

                Label {
                    text: i18n.tr("Gestures")
                    textSize: Label.XLarge
                    verticalAlignment: Label.AlignVCenter
                    height: units.gu(6)
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        right: parent.right
                        rightMargin: units.gu(2)
                    }
                }

                ListItem {
                    objectName: "physicalForGestures"

                    ListItemLayout {
                        title.text: i18n.tr("Physical unit-based gestures")
                        subtitle.text: i18n.tr("Dimensions and threshold of gestures will be in physical unit (inch)")
                        CheckBox {
                            id: physicalForGestures
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.physicalForGestures = checked
                        }
                    }

                    Binding {
                        target: physicalForGestures
                        property: "checked"
                        value: settingsObject.physicalForGestures
                    }
                }

                ListItem {
                    objectName: "enableWebviewPullDownGestures"

                    ListItemLayout {
                        title.text: i18n.tr("Webview Pull Down")
                        subtitle.text: i18n.tr("Swipe down/up on the left/right edge to pull down/up the webview")
                        CheckBox {
                            id: enableWebviewPullDownGestures
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.enableWebviewPullDownGestures = checked
                        }
                    }

                    Binding {
                        target: enableWebviewPullDownGestures
                        property: "checked"
                        value: settingsObject.enableWebviewPullDownGestures
                    }
                }

                ListItem {
                    objectName: "hideBottomHint"

                    ListItemLayout {
                        title.text: i18n.tr("Hide bottom gesture hint")
                        subtitle.text: i18n.tr("Bottom getsure visual hint")
                        CheckBox {
                            id: hideBottomHint
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.hideBottomHint = checked
                        }
                    }

                    Binding {
                        target: hideBottomHint
                        property: "checked"
                        value: settingsObject.hideBottomHint
                    }
                }

                ListItem {
                    objectName: "bottomGesturesAreaHeight"

                    ListItemLayout {
                        title.text: i18n.tr("Gestures Area Height")
                        SpinBox {
                          id: bottomGesturesAreaHeight
                          value: settingsObject.bottomGesturesAreaHeight
                          from: 1
                          to: 10
                          stepSize: 1
                          onValueModified: {
                            settingsObject.bottomGesturesAreaHeight = value
                          }
                        }
                        Icon {
                            name: "reset"

                            height: units.gu(2)
                            width: height
                            opacity: (settingsObject.bottomGesturesAreaHeight === 2) ? 0.5 : 1

                            MouseArea {
                                anchors.fill: parent
                                onClicked: settingsObject.bottomGesturesAreaHeight = 2
                            }

                            anchors {
                                leftMargin: units.gu(1)
                                topMargin: units.gu(2)
                            }
                        }
                    }
                }

                ListItem {
                    objectName: "webviewEnableQuickActions"

                    ListItemLayout {
                        title.text: i18n.tr("Enable Quick Actions")
                        subtitle.text: i18n.tr("Actions accessible by swiping up from the left or right bottom")
                        CheckBox {
                            id: webviewEnableQuickActions
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.webviewEnableQuickActions = checked
                        }
                    }

                    Binding {
                        target: webviewEnableQuickActions
                        property: "checked"
                        value: settingsObject.webviewEnableQuickActions
                    }
                }

                ListItem {
                    objectName: "webviewQuickActionEnableDelay"

                    visible: settingsObject.webviewEnableQuickActions

                    ListItemLayout {
                        title.text: i18n.tr("Trigger Delay")
                        subtitle.text: i18n.tr("Add short delay when opening Quick Actions menu")
                        padding.leading: units.gu(2)

                        CheckBox {
                            id: webviewQuickActionEnableDelay
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.webviewQuickActionEnableDelay = checked
                        }
                    }

                    Binding {
                        target: webviewQuickActionEnableDelay
                        property: "checked"
                        value: settingsObject.webviewQuickActionEnableDelay
                    }
                }

                ListItem {
                    objectName: "webviewQuickActionsHeight"

                    visible: settingsObject.webviewEnableQuickActions

                    ListItemLayout {
                        title.text: i18n.tr("Height (inch)")
                        padding.leading: units.gu(2)

                        SpinBox {
                          id: webviewQuickActionsHeight
                          value: settingsObject.webviewQuickActionsHeight * 4
                          from: 4
                          to: 20
                          stepSize: 1
                          textFromValue: function(value, locale) {
                            return value / 4;
                          }
                          onValueModified: {
                            settingsObject.webviewQuickActionsHeight = value / 4
                          }
                        }
                        Icon {
                            name: "reset"

                            height: units.gu(2)
                            width: height
                            opacity: (settingsObject.webviewQuickActionsHeight === 3) ? 0.5 : 1

                            MouseArea {
                                anchors.fill: parent
                                onClicked: settingsObject.webviewQuickActionsHeight = 3
                            }

                            anchors {
                                leftMargin: units.gu(1)
                                topMargin: units.gu(2)
                            }
                        }
                    }
                }

                ListItem {
                    objectName: "webviewQuickActionsLeft"

                    visible: settingsObject.webviewEnableQuickActions

                    ListItemLayout {
                        title.text: i18n.tr("Quick Actions (Left)")
                        padding.leading: units.gu(2)
                        ProgressionSlot {}
                    }

                    onClicked: leftQuickActionsComponent.createObject(subpageContainer)
                }

                ListItem {
                    objectName: "webviewQuickActionsRight"

                    visible: settingsObject.webviewEnableQuickActions

                    ListItemLayout {
                        title.text: i18n.tr("Quick Actions (Right)")
                        padding.leading: units.gu(2)
                        ProgressionSlot {}
                    }

                    onClicked: rightQuickActionsComponent.createObject(subpageContainer)
                }

                ListItem {
                    objectName: "customUrlActions"

                    visible: settingsObject.webviewEnableQuickActions

                    ListItemLayout {
                        title.text: i18n.tr("Custom URL Actions")
                        padding.leading: units.gu(2)
                        ProgressionSlot {}
                    }

                    onClicked: customUrlActionsComponent.createObject(subpageContainer)
                }

                Label {
                    text: i18n.tr("Miscellaneous")
                    textSize: Label.XLarge
                    verticalAlignment: Label.AlignVCenter
                    height: units.gu(6)
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        right: parent.right
                        rightMargin: units.gu(2)
                    }
                }

                ListItem {
                    objectName: "privacy"

                    ListItemLayout {
                        title.text: i18n.tr("Privacy & permissions")
                        ProgressionSlot {}
                    }

                    onClicked: privacyComponent.createObject(subpageContainer)

                }

                ListItem {
                    objectName: "reset"

                    ListItemLayout {
                        title.text: i18n.tr("Reset settings")
                    }

                    onClicked: {
                        let _confirmDialog = confirmDialogComponent.createObject(settingsItem, { "title": i18n.tr("Reset All Settings")
                                                                            , "text": i18n.tr("Are you sure you want to reset all of this webapp's settings?") })
                        _confirmDialog.confirm.connect(function() {
                                settingsObject.restoreDefaults();
                                settingsObject.resetDomainPermissions();
                                settingsObject.resetDomainSettings();
                                webapp.showTooltip(i18n.tr("All settings have been reset"), "BOTTOM", 3000)
                            }
                        )
                        if (webapp.wide) {
                            _confirmDialog.openNormal();
                        } else {
                            _confirmDialog.openBottom();
                        }
                    }
                }
            }
        }
    }

    Component {
        id: confirmDialogComponent
        
        Sapot.ConfirmDialog {}
    }

    Item {
        id: subpageContainer

        visible: children.length > 0
        anchors.fill: parent

        Component {
            id: leftQuickActionsComponent

            Sapot.QuickActionsSettingsPage {
                title: i18n.tr("Quick actions (Left)")
                model: settingsObject.webviewQuickActions[0]
                anchors.fill: parent
                onModelDataChanged: {
                    settingsObject.webviewQuickActions = [ newModelData, settingsObject.webviewQuickActions[1] ]
                }
            }
        }

        Component {
            id: rightQuickActionsComponent

            Sapot.QuickActionsSettingsPage {
                title: i18n.tr("Quick actions (Right)")
                model: settingsObject.webviewQuickActions[1]
                anchors.fill: parent
                onModelDataChanged: {
                    settingsObject.webviewQuickActions = [ settingsObject.webviewQuickActions[0], newModelData ]
                }
            }
        }

        Component {
            id: customUrlActionsComponent

            Sapot.CustomUrlActionsPage {
                title: i18n.tr("Custom URL Actions")
                model: settingsObject.customURLActions
                anchors.fill: parent
            }
        }

        Component {
            id: privacyComponent

            Common.BrowserPage {
                id: privacyItem
                objectName: "privacySettings"

                anchors.fill: parent

                onBack: privacyItem.destroy()
                title: i18n.tr("Privacy & permissions")

                Flickable {
                    anchors.fill: parent
                    contentHeight: privacyCol.height

                    Column {
                        id: privacyCol
                        width: parent.width

                        ListItem {
                            objectName: "setDomainWhiteListMode"

                            ListItemLayout {
                                title.text: i18n.tr("Only allow browsing to whitelisted websites")
                                CheckBox {
                                    id: setDomainWhiteListModeCheckbox
                                    SlotsLayout.position: SlotsLayout.Trailing
                                    onTriggered: settingsObject.domainWhiteListMode = checked
                                }
                            }

                            Binding {
                                target: setDomainWhiteListModeCheckbox
                                property: "checked"
                                value: settingsObject.domainWhiteListMode
                            }
                        }

                        ListItem {
                            objectName: "DomainPermissions"

                            ListItemLayout {
                                title.text: "Domain blacklist/whitelist"
                                ProgressionSlot {}
                            }

                            onClicked: domainPermissionsViewLoader.active = true
                        }

                        ListItem {
                            objectName: "DomainSettings"

                            ListItemLayout {
                                title.text: "Domain specific settings"
                                ProgressionSlot {}
                            }

                            onClicked: domainSettingsViewLoader.active = true
                        }


                        ListItem {
                            objectName: "privacy.clearCache"
                            ListItemLayout {
                                title.text: i18n.tr("Clear cache")
                            }
                            onClicked: {
                                var dialog = PopupUtils.open(privacyConfirmDialogComponent, privacyItem, {"title": i18n.tr("Clear cache?")});
                                dialog.confirmed.connect(clearCache);
                            }
                        }

                        ListItem {
                            objectName: "privacy.clearAllCookies"
                            ListItemLayout {
                                title.text: i18n.tr("Clear all cookies")
                            }
                            onClicked: {
                                var dialog = PopupUtils.open(privacyConfirmDialogComponent, privacyItem, {"title": i18n.tr("Clear all Cookies?")});
                                dialog.confirmed.connect(clearAllCookies);
                            }
                        }
                    }
                }

                Component {
                    id: privacyConfirmDialogComponent

                    Dialog {
                        id: privacyConfirmDialog
                        objectName: "privacyConfirmDialog"
                        signal confirmed()

                        Row {
                            spacing: units.gu(2)
                            anchors {
                                left: parent.left
                                right: parent.right
                            }

                            Button {
                                objectName: "privacyConfirmDialog.cancelButton"
                                width: (parent.width - parent.spacing) / 2
                                text: i18n.tr("Cancel")
                                onClicked: PopupUtils.close(privacyConfirmDialog)
                            }

                            Button {
                                objectName: "privacyConfirmDialog.confirmButton"
                                width: (parent.width - parent.spacing) / 2
                                text: i18n.tr("Clear")
                                color: theme.palette.normal.positive
                                onClicked: {
                                    confirmed()
                                    PopupUtils.close(privacyConfirmDialog)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: domainSettingsViewLoader

        anchors.fill: parent
        active: false
        asynchronous: true
        Component.onCompleted: {
            setSource("../DomainSettingsPage.qml")
        }

        Connections {
            target: domainSettingsViewLoader.item
            onDone: domainSettingsViewLoader.active = false
            onReload: {
                domainSettingsViewLoader.active = false
                domainSettingsViewLoader.active = true

                if (selectedDomain) {
                    domainSettingsViewLoader.item.setDomainAsCurrentItem(selectedDomain)
                }
            }
        }
    }

    Loader {
        id: domainPermissionsViewLoader

        anchors.fill: parent
        active: false
        asynchronous: true
        Component.onCompleted: {
            setSource("../DomainPermissionsPage.qml")
        }

        Connections {
            target: domainPermissionsViewLoader.item
            onDone: domainPermissionsViewLoader.active = false
            onReload: {
                domainPermissionsViewLoader.active = false
                domainPermissionsViewLoader.active = true

                if (selectedDomain) {
                  domainPermissionsViewLoader.item.setDomainAsCurrentItem(selectedDomain)
                }
            }
        }
    }
}
