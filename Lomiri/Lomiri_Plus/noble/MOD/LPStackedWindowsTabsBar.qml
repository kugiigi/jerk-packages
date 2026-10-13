// ENH268 - Tabbed snapped windows
import QtQuick 2.15
import QtQuick.Window 2.2
import Lomiri.Components 1.3
import Lomiri.Components.Extras 0.3 as Extras

Extras.TabsBar {
    id: root

    property alias enableHover: hoverMouseArea.enabled
    property var appDelegate

    height: units.gu(3)

    actionColor: theme.palette.normal.backgroundText
    color: theme.palette.normal.base
    backgroundColor: theme.palette.normal.background
    foregroundColor: theme.palette.normal.backgroundText
    fallbackIcon: "stock_application"

    function iconSourceFromModelItem(modelData, index) {
        const _data = modelData;
        let _item = _data.appDelegate;
        if (!_item) return ""

        if (_data.isWindowsModel) {
            _item = _data.appDelegate.currentAppDelegate;
        }
        return _item && _item.application ? _item.application.icon : "";
    }

    function titleFromModelItem(modelItem) {
        const _data = modelItem;
        let _item = _data.appDelegate;
        let _prefix = "";

        if (!_item) return ""

        if (_data.isWindowsModel) {
            _item = _data.appDelegate.currentAppDelegate;
            _prefix = "[%1] ".arg(_data.appDelegate.countExceptModels);
        }

        if (_item && _item.title)
            return _prefix + _item.title

        if (_item && _item.appName)
            return _prefix + _item.appName

        return _prefix + _item.appId
    }

    // Hold show titlebar when hovered in Clean Mode
    MouseArea {
        id: hoverMouseArea

        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: enabled
        propagateComposedEvents: true
        onContainsMouseChanged: {
            if (root.appDelegate) {
                if (containsMouse) {
                    root.appDelegate.decoration.externalHovered = true;
                    root.appDelegate.decoration.hideDecorTimer.stop()
                } else if (!root.appDelegate.decoration.topIsHovered) {
                    root.appDelegate.decoration.externalHovered = false;
                    root.appDelegate.decoration.hideDecorTimer.restart()
                    root.appDelegate.decoration.showDecorTimer.stop()
                }
            }
        }
    }
}
