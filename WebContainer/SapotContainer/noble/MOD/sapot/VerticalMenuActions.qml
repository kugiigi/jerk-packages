import QtQuick 2.9
import QtQuick.Controls 2.2 as QQC2
import Lomiri.Components 1.3

QQC2.Menu {
    id: menuActions

    property alias model: instantiator.model
    property bool isBottom: false

    function openBottom() {
        y = Qt.binding( function() { return parent ? parent.height - height : 0 } )
        isBottom = true
        open()
    }

    function openTop() {
        y = 0
        isBottom = false
        open()
    }

    Instantiator {
        id: instantiator

        QQC2.MenuItem {
            text: modelData ? modelData.text : ""
            visible: modelData && modelData.enabled && modelData.visible
            onTriggered: {
                menuActions.close()
                modelData.trigger(isBottom, this)
            }

            height: visible ? units.gu(6) : 0
            icon.name: modelData ? modelData.iconName : ""
            icon.color: theme.palette.normal.foregroundText
            icon.width: units.gu(2)
            icon.height: units.gu(2)
        }
        onObjectAdded: menuActions.insertItem(index, object)
        onObjectRemoved: menuActions.removeItem(object)
    }
}
