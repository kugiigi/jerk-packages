// ENH070 - Keyboard settings
import QtQuick 2.15
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2

QQC2.ToolButton {
    icon.width: units.gu(2)
    icon.height: units.gu(2)
    onPressed: shell.haptics.playSubtle()
}
