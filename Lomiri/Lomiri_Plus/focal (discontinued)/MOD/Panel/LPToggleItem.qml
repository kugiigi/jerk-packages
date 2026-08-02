// ENH056 - Quick toggles
import QtQuick 2.12
import Lomiri.Components 1.3

Item {
    id: toggleItem

    property bool checked: false
    property bool enabled: !(shell.showingGreeter && disableOnLockscreen)
    property string parentMenuIndex: ""
    // ENH201 - Disable toggles in lockscreen
    readonly property bool disableOnLockscreen: {
        switch (disableOnLockscreenWhen) {
            case 0:
                return true
            case 1:
                return checked
            case 2:
                return !checked
            default:
                return false
        }
    }
    property int disableOnLockscreenWhen: -1
    /*
     * -1 - Never
     *  0 - Always
     *  1 - When turned on
     *  2 - When turned off
    */
    // ENH201 - End

    signal clicked
}
