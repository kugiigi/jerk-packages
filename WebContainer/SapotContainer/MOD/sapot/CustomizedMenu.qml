import QtQuick 2.9
import QtQuick.Controls 2.5 as QQC2
import Lomiri.Components 1.3

QQC2.Menu {
    id: customMenu

    readonly property real defaultWidth: Math.max(minimumWidth, Math.min(preferredWidth, maximumWidth))
    property real availWidth: parent.width
    property real availHeight: parent.height
    property string iconName
    property real minimumWidth: showShortcuts ? units.gu(40) : units.gu(32)
    property real maximumWidth: showShortcuts ? units.gu(50) : units.gu(42)
    property real preferredWidth: parent.width * 0.25

    property bool showShortcuts: false

    width: defaultWidth
    margins: units.gu(2)
    currentIndex: -1
    delegate: CustomizedMenuItem{}
    onAboutToShow: currentIndex = -1
}
