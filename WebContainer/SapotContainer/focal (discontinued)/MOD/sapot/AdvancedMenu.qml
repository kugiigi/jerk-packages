import QtQuick 2.9
import QtQuick.Controls 2.5 as QQC2
import Lomiri.Components 1.3
import QtQuick.Controls.Suru 2.2
import QtQuick.Layouts 1.12
import "../.." as Common

CustomizedMenu {
    id: advancedMenu

    enum Type {
        ContextMenu
        , BottomAttached
        , ItemAttached
    }

    enum TitleSize {
        Standard
        , Small
        , Large
    }

    readonly property alias isBottom: internal.isBottom // Used when type is AdvancedMenu.Type.ItemAttached and opened from the bottom

    property int type: AdvancedMenu.Type.ContextMenu
    property var caller // Used in AdvancedMenu.Type.BottomAttached && ItemAttached
    property bool showAsCenteredModal: false
    property bool destroyOnClose: false
    property bool incognito: false
    property alias menuActions: instantiator.model
    property bool doNotOverlapCaller: false // Used in AdvancedMenu.Type.ItemAttached

    // Title Header
    property string headerTitle
    property bool multilineTitle: false
    property int maximumLineCount: 2
    property string iconName
    property int titleSize: AdvancedMenu.TitleSize.Standard
    property bool useFavicon: false
    property url faviconSource

    modal: type == AdvancedMenu.Type.ContextMenu ? true : false
    dim: showAsCenteredModal
    transformOrigin: QQC2.Menu.TopLeft // Mainly used for AdvancedMenu.Type.ItemAttached

    onClosed: if (destroyOnClose) destroy()
    
    function popupWithTitle(itemTitle, itemIcon) {
        headerTitle = itemTitle
        if (itemIcon) {
            if (useFavicon) {
                faviconSource = itemIcon
            } else {
                iconName = itemIcon
            }
        }

        // Reset to remove binding
        x = 0
        y = 0

        popup()
    }

    function show(itemTitle, callerItem, openInBottom) {
        if (callerItem) caller = callerItem
        if (itemTitle) headerTitle = itemTitle

        switch (true) {
            case type == AdvancedMenu.Type.BottomAttached:
                x = Qt.binding( function() { let mappedPos = parent.mapFromItem(caller, 0, 0); return mappedPos.x - width + caller.width } )
                y = Qt.binding ( function() { let mappedPos = parent.mapFromItem(caller, 0, 0); return mappedPos.y - height } )
                break
            case type == AdvancedMenu.Type.ContextMenu && advancedMenu.showAsCenteredModal:
                x = Qt.binding( function () { return (parent.width / 2) - (width / 2) } )
                y = Qt.binding( function () { return (parent.height / 2) - (height / 2) } )
                break
            case type == AdvancedMenu.Type.ItemAttached:
                switch (advancedMenu.transformOrigin) {
                    case QQC2.Menu.TopLeft:
                        x = Qt.binding( function() { let mappedPos = parent.mapFromItem(caller, 0, 0); return mappedPos && caller ? mappedPos.x : 0 } )
                        break
                    case QQC2.Menu.TopRight:
                        x = Qt.binding( function() { let mappedPos = parent.mapFromItem(caller, 0, 0); return mappedPos && caller ? mappedPos.x - width + caller.width : 0 } )
                        break
                }

                if (openInBottom) {
                    internal.isBottom = true
                    y = parent.height - height
                } else {
                    internal.isBottom = false
                    if (advancedMenu.doNotOverlapCaller) {
                        y = Qt.binding( function() { let mappedPos = parent.mapFromItem(caller, 0, 0); return mappedPos && caller ? mappedPos.y + caller.height : 0 } )
                    } else {
                        y = Qt.binding( function() { let mappedPos = parent.mapFromItem(caller, 0, 0); return mappedPos && caller ? mappedPos.y : 0 } )
                    }
                }
                break
        }

        open()
    }

    // Header
    Loader {
        active: advancedMenu.headerTitle ? true : false
        asynchronous: true
        sourceComponent: headerComponent
    }
    
    Component {
        id: headerComponent
         RowLayout {
            Icon {
                Layout.topMargin: units.gu(1)
                Layout.bottomMargin: units.gu(1)
                Layout.leftMargin: units.gu(2)
                implicitWidth: switch(advancedMenu.titleSize) {
                    case AdvancedMenu.TitleSize.Small:
                        return units.gu(2)
                        break
                    case AdvancedMenu.TitleSize.Large:
                        return units.gu(3)
                        break
                    default: 
                        return units.gu(2.5)
                        break
                }
                implicitHeight: implicitWidth
                name: advancedMenu.iconName
                color: Suru.foregroundColor
                visible: name && !advancedMenu.useFavicon ? true : false
            }

            Common.Favicon {
                id: favicon

                Layout.topMargin: units.gu(1)
                Layout.bottomMargin: units.gu(1)
                Layout.leftMargin: units.gu(2)
                implicitWidth: switch(advancedMenu.titleSize) {
                    case AdvancedMenu.TitleSize.Small:
                        return units.gu(2)
                        break
                    case AdvancedMenu.TitleSize.Large:
                        return units.gu(3)
                        break
                    default: 
                        return units.gu(2.5)
                        break
                }
                implicitHeight: implicitWidth
                source: advancedMenu.faviconSource
                shouldCache: !advancedMenu.incognito
                visible: advancedMenu.useFavicon
            }

            QQC2.Label {
                Layout.fillWidth: true
                Layout.topMargin: units.gu(1)
                Layout.bottomMargin: units.gu(1)
                Layout.leftMargin: units.gu(1)
                Layout.rightMargin: units.gu(2)
                text: advancedMenu.headerTitle
                elide: Label.ElideRight
                verticalAlignment: Label.AlignVCenter
                wrapMode: advancedMenu.multilineTitle ? Text.WrapAnywhere : Text.NoWrap
                maximumLineCount: advancedMenu.maximumLineCount

                Suru.textLevel: {
                    switch(advancedMenu.titleSize) {
                        case AdvancedMenu.TitleSize.Small:
                            return Suru.Paragraph
                            break
                        case AdvancedMenu.TitleSize.Large:
                            return Suru.HeadingTwo
                            break
                        default: 
                            return advancedMenu.multilineTitle ? Suru.Small : Suru.HeadingThree
                            break
                    }
                }
            }
        }
    }

    Loader {
        active: advancedMenu.headerTitle ? true : false
        asynchronous: true
        sourceComponent: CustomizedMenuSeparator {}
    }

    Instantiator {
        id: instantiator

        CustomizedMenuItem {
            id: menuItem

            text: modelData ? modelData.text : ""
            tooltipText: modelData ? modelData.tooltipText : ""
            enabled: modelData && modelData.enabled
            visible: modelData && modelData.visible
            iconName: modelData ? modelData.iconName : ""
            onTriggered: modelData.trigger(advancedMenu.isBottom, menuItem)
        }
        onObjectAdded: advancedMenu.insertItem(index, object)
        onObjectRemoved: advancedMenu.removeItem(object)
    }

    QtObject {
        id: internal

        property bool isBottom: false
    }
}
