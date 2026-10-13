// ENH268 - Tabbed snapped windows
import QtQuick 2.15
import Lomiri.Components 1.3

ListModel {
    property int selectedIndex: getCurrentIndex()

    // Check count so currentItem updates when items are removed
    // and selectedIndex don't change
    readonly property var currentItem: {
        if (count === 0 || selectedIndex < 0) return null

        const _item = get(selectedIndex);

        if (_item === null) return null;

        return _item.itemdata;
    }

    readonly property Item currentAppDelegate: currentItem && !currentItem.isWindowsModel ? currentItem.appDelegate : null
    readonly property int countExceptModels: {
        if (count === 0) return 0;

        let _count = 0;
        for (let i = 0; i < count; ++i) {
            if (!get(i).itemdata.isWindowsModel) {
                _count += 1;
            }
        }

        return _count;
    }

    function getCurrentIndex() {
        if (this.count === 0)
            return -1

        let _index = 0;
        let _highest = -1;

        if (!this.get(0).itemdata.isWindowsModel) {
            _highest = this.get(0).itemdata.appDelegate.z;
        }

        for (let i = _index + 1; i < this.count; ++i) {
            if (this.get(i).itemdata.isWindowsModel) continue;

            const _z = this.get(i).itemdata.appDelegate.z
            if (_z > _highest) {
                _highest = _z;
                _index = i;
            }
        }

        return _index
    }

    function updateSelectedIndex() {
        selectedIndex = Qt.binding( function() { return getCurrentIndex() } );
    }

    function moveWindowsModelsToLast() {
        if (count > 0) {
            for (let i = count - 1; i >= 0; i--) {
                if (get(i).itemdata.isWindowsModel) {
                    move(i, count - 1, 1)
                }
            }
        }

        updateSelectedIndex();
    }

    function addItem(_appDelegate) {
        for (let i = 0; i < count; ++i) {
            if (get(i).itemdata.appDelegate === _appDelegate)
                return;
        }
        const _isModel = _appDelegate instanceof LPStackedWindowsModel;

        // WORKAROUND: TabsBar passes the actual model when there are multiple properties
        // titleFromModelItem() doesn't pass the index so there's no way to get the data
        // So put all properties into a single 1st level property
        append( { "itemdata": { "appDelegate": _appDelegate, "isWindowsModel": _isModel } } );

        moveWindowsModelsToLast();
    }

    function removeItem(_appDelegate) {
        for (let i = 0; i < count; ++i) {
            if (get(i).itemdata.appDelegate === _appDelegate) {
                remove(i)
                break
            }
        }

        // Check if all remaining items are windows models
        // and delete all if they are
        if (count > 0) {
            for (let i = 0; i < count; ++i) {
                if (!get(i).itemdata.isWindowsModel) return
            }
            clear();
        }
    }

    function selectTab(index) {
        const _item = this.get(index).itemdata;
        if (_item.isWindowsModel) {
            _item.appDelegate.currentAppDelegate.activate();
        } else {
            _item.appDelegate.activate();
        }
    }

    function removeTab(index) {
        const _item = this.get(index).itemdata;
        if (_item.isWindowsModel) {
            _item.appDelegate.currentAppDelegate.close();
        } else {
            _item.appDelegate.close();
        }
    }

    function moveTab(from, to) {
        if (from === to
            || from < 0 || from >= count
            || to < 0 || to >= count) {
            return;
        }

        move(from, to, 1);

        updateSelectedIndex();
    }
}
