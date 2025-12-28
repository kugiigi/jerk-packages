import QtQuick 2.15
import Lomiri.Components 1.3

Action {
    id: root

    property int iconRotation: 0
    property bool enableDoubleClick: false // Avoids delay for single click
    property real iconSize: units.gu(4)

    signal singleClick
    signal doubleClick
}
