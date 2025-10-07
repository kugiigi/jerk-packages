import QtQuick 2.9
import Lomiri.Components 1.3
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Controls.Suru 2.2
import QtQuick.Layouts 1.12
import "../.." as Common

QQC2.MenuItem {
    id: customMenuItem

    property var rightDisplay
    property alias rightDisplayItem: rightComponentLoader.item
    property string type
    property string iconName
    property string favicon: "undefined"
    property string tooltipText

    QQC2.ToolTip.delay: 1000
    QQC2.ToolTip.visible: tooltipText ? hovered : false
    QQC2.ToolTip.text: tooltipText

    height: visible ? implicitHeight : 0

    topPadding: Suru.units.gu(1) - Suru.units.dp(1)
    bottomPadding: Suru.units.gu(1) + Suru.units.dp(1)

    onEnabledChanged: {
        if ((menu && menu.visible) || (subMenu && subMenu.visible)) {
            // Postpone visibility changes to when the menu/submenu closes
            // to avoid user visible changes in the menu when clicking menuitems
            internal.visibleWasPostponed = true
            return
        }

        visible = enabled
    }

    Connections {
        target: menu
        onVisibleChanged: {
            if (!target.visible && internal.visibleWasPostponed) {
                customMenuItem.visible = customMenuItem.enabled
            }
            internal.visibleWasPostponed = false
        }
    }

    Connections {
        target: subMenu
        onVisibleChanged: {
            if (!target.visible && internal.visibleWasPostponed) {
                customMenuItem.visible = customMenuItem.enabled
            }
            internal.visibleWasPostponed = false
        }
    }

    QtObject {
        id: internal

        property bool visibleWasPostponed: false
    }

    contentItem: RowLayout {
        spacing: units.gu(2)

        Icon {
            id: iconMenu

            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            implicitWidth: units.gu(2)
            implicitHeight: implicitWidth
            name: customMenuItem.subMenu ? customMenuItem.subMenu.iconName : customMenuItem.iconName
            color: theme.palette.normal.backgroundText
            visible: name ? true : false
        }

        Common.Favicon {
            id: favicon
            
            source: customMenuItem.favicon
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            visible: customMenuItem.favicon == "undefined" ? false : true

            implicitHeight: implicitWidth
            implicitWidth: units.gu(2)
        }

        QQC2.Label {
            visible: customMenuItem.text ? true : false
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.fillWidth: true
            horizontalAlignment:  Text.AlignLeft
            text: customMenuItem.text
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: 2
            Suru.textLevel: Suru.Paragraph
        }

        Loader {
            id: rightComponentLoader

            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            sourceComponent: {
                if (customMenuItem.subMenu) {
                    return iconComponent
                } else if (customMenuItem.rightDisplay) {
                    // Keyboard shortcut texts
                    if (typeof customMenuItem.rightDisplay === 'string' || customMenuItem.rightDisplay instanceof String) {
                        if (customMenuItem.menu.showShortcuts) {
                            return textComponent
                        } else {
                            return null
                        }
                    // Custom component
                    } else {
                        return customMenuItem.rightDisplay
                    }
                } else {
                    return null
                }
            }

            Component {
                id: iconComponent

                Icon {
                    name: "toolkit_chevron-ltr_3gu"
                    implicitHeight: units.gu(2)
                    color: theme.palette.normal.backgroundText
                }
            }
            
            Component {
                id: textComponent

                QQC2.Label {
                    horizontalAlignment:  Text.AlignRight
                    text: customMenuItem.rightDisplay
                    Suru.textLevel: Suru.Small
                }
            }
        }
    }
}
