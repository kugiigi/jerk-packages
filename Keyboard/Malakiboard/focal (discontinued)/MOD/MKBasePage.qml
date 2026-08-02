import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import Lomiri.Components 1.3
import "." as Common

QQC2.Page {
    id: basePage

    property var headerLeftActions: []
    property var headerRightActions: []
    property Flickable flickable
    property bool wide: false
    property bool showBackButton: true

    focus: true

    Component.onCompleted: forceActiveFocus()
}
