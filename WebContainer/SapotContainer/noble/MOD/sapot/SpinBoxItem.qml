import QtQuick 2.9
//~ import QtQuick.Controls 2.2 as QQC2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material as QQC2
import Lomiri.Components

RowLayout {
    id: root

    property real currentValue // Current value of the settings or property being controlled
    property real resetValue
    readonly property bool isResetValue: currentValue === resetValue

    property alias textFromValue: spinBox.textFromValue
    property alias stepSize: spinBox.stepSize
    property alias value: spinBox.value
    property alias from: spinBox.from
    property alias to: spinBox.to

    readonly property bool isDarkMode: Theme.name == "Lomiri.Components.Themes.SuruDark"
    QQC2.Material.theme: isDarkMode ? QQC2.Material.Dark : QQC2.Material.Light
    QQC2.Material.background: theme.palette.normal.background
    QQC2.Material.accent: theme.palette.normal.activity

    signal valueModified(real value)
    signal reset

    spacing: units.gu(2)

    QQC2.SpinBox {
        id: spinBox

        Layout.preferredHeight: units.gu(5)
        from: 25
        to: 500
        stepSize: 5
        onValueModified: root.valueModified(value);
    }
    Icon {
        name: "reset"
        color: theme.palette.normal.backgroundText
        height: units.gu(2)
        width: height
        opacity: root.isResetValue ? 0.5 : 1

        MouseArea {
            anchors.fill: parent
            onClicked: root.reset();
        }

        anchors {
            leftMargin: units.gu(1)
            topMargin: units.gu(2)
        }
    }
}
