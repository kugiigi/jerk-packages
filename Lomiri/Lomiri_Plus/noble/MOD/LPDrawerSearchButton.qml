import QtQuick 2.15
import Lomiri.Components 1.3
import QtQuick.Controls 2.15 as QQC2
import "Components" as Components

Components.LPButton {
    borderColor: "transparent"
    backgroundColor: theme.palette.normal.base
    highlightedBackgroundColor: theme.palette.highlighted.base
    highlightedBorderColor: theme.palette.normal.focus
    highlightedBorderWidth: units.dp(2)
    defaultBorderWidth: units.dp(2)
    radius: width / 2
    // TODO: Implement proper centering when there's only right icon and a text
    leftPadding: display === QQC2.AbstractButton.TextBesideIcon && secondaryIcon.name !== "" ? units.gu(1.5) : units.gu(2)
    rightPadding: display === QQC2.AbstractButton.TextBesideIcon && secondaryIcon.name !== "" ? leftPadding * 2 : leftPadding
    backgroundOpacity: 0.6
}
