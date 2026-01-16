import QtQuick 2.15
import Lomiri.Components 1.3
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Controls.Suru 2.2
import QtQuick.Layouts 1.12

QQC2.ItemDelegate {
    id: customizedButton

    readonly property LPIconGroupedProperties secondaryIcon: LPIconGroupedProperties {
        width: units.gu(2)
        height: units.gu(2)
        color: theme.palette.normal.backgroundText
    }

    property real radius: units.gu(1)
    property bool transparentBackground: false
    property color backgroundColor: theme.palette.normal.foreground
    property color textColor: theme.palette.normal.backgroundText
    property color borderColor: theme.palette.normal.foregroundText
    property real highlightedBorderWidth: units.gu(0.8)
    property real defaultBorderWidth: units.gu(0.6)
    property color highlightedBackgroundColor: theme.palette.highlighted.foreground
    property color highlightedBorderColor: theme.palette.selected.foregroundText
    property string tooltipText
    property int alignment: Qt.AlignCenter
    property real backgroundOpacity: 1
    property int iconRotation: 0
    property bool showEnterOverlay: false

    property alias label: mainLabel // Main label
    
    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             contentItem.implicitHeight + topPadding + bottomPadding)

    display: QQC2.AbstractButton.TextBesideIcon
    icon {
        width: units.gu(2)
        height: units.gu(2)
        color: theme.palette.normal.backgroundText
    }
    focusPolicy: Qt.TabFocus
    leftPadding: units.gu(1)
    rightPadding: leftPadding
    topPadding: units.gu(0.5)
    bottomPadding: topPadding
    highlighted: activeFocus

    Keys.onEnterPressed: clicked()
    Keys.onReturnPressed: clicked()

    onClicked: shell.haptics.play()

    Component {
        id: iconComponent

        Icon {
            anchors.fill: parent
            name: customizedButton.icon.name
            color: customizedButton.icon.color
            rotation: customizedButton.iconRotation
        }
    }

    Component {
        id: secondaryIconComponent

        Icon {
            name: customizedButton.secondaryIcon.name
            color: customizedButton.secondaryIcon.color
            width: customizedButton.secondaryIcon.width
            height: customizedButton.secondaryIcon.height
        }
    }

    QtObject {
        id: internal
        
        readonly property bool centerContents: customizedButton.display == QQC2.AbstractButton.IconOnly
                                            || customizedButton.display == QQC2.AbstractButton.TextOnly
                                            || customizedButton.alignment == Qt.AlignCenter
    }

    contentItem: Item {
        implicitHeight: layout.height
        implicitWidth: layout.width

        RowLayout {
            id: layout

            spacing: units.gu(1)
            anchors.centerIn: parent

            Loader {
                id: leftIconLoader

                Layout.preferredWidth: customizedButton.icon.width
                Layout.preferredHeight: customizedButton.icon.height
                Layout.alignment: internal.centerContents ? Qt.AlignCenter : Qt.AlignVCenter

                visible: item ? true : false
                asynchronous: true
                sourceComponent: {
                    switch (customizedButton.display) {
                        case QQC2.AbstractButton.IconOnly:
                        case QQC2.AbstractButton.TextBesideIcon:
                            return iconComponent
                        default:
                            return null
                    }
                }
            }

            Label {
                id: mainLabel

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: customizedButton.text
                color: customizedButton.textColor
                visible: opacity > 0
                opacity: {
                    switch (customizedButton.display) {
                        case QQC2.AbstractButton.TextOnly:
                        case QQC2.AbstractButton.TextBesideIcon:
                        case QQC2.AbstractButton.TextUnderIcon:
                            return 1
                        default:
                            return 0
                    }
                }
                Behavior on opacity { LomiriNumberAnimation {} }
            }

            Loader {
                id: rightIconLoader

                Layout.preferredWidth: customizedButton.icon.width
                Layout.preferredHeight: customizedButton.icon.height
                Layout.alignment: Qt.AlignVCenter

                asynchronous: true
                visible: item ? true : false
                sourceComponent: {
                    switch (customizedButton.display) {
                        case QQC2.AbstractButton.TextUnderIcon:
                            return iconComponent
                        default:
                            if (customizedButton.secondaryIcon.name) {
                                return secondaryIconComponent
                            } else {
                                return null
                            }
                    }
                }
            }
        }
    }

    background: Rectangle {
        id: backgroundRec

        color: customizedButton.transparentBackground ? "transparent"
                                        : customizedButton.highlighted ? customizedButton.highlightedBackgroundColor : customizedButton.backgroundColor
        border.width: customizedButton.highlighted ? customizedButton.highlightedBorderWidth : customizedButton.defaultBorderWidth
        border.color: customizedButton.transparentBackground ? "transparent"
                                        : customizedButton.highlighted ? customizedButton.highlightedBorderColor : customizedButton.borderColor
        radius: customizedButton.radius
        opacity: customizedButton.backgroundOpacity

        Behavior on border.width {
            LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
        }
        Behavior on color {
            ColorAnimation {
                duration: Suru.animations.FastDuration
                easing: Suru.animations.EasingIn
            }
        }
        
        Rectangle {
            id: highlightRect

            anchors.fill: parent

            visible: customizedButton.down || customizedButton.hovered
            border.width: background.border.width
            border.color: "transparent"
            radius: background.radius
            color: {
                return customizedButton.down ? Qt.darker(backgroundRec.color, 1.2) : Qt.darker(backgroundRec.color, 1.1)
            }

            Behavior on color {
                ColorAnimation {
                    duration: Suru.animations.FastDuration
                    easing: Suru.animations.EasingIn
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Suru.animations.FastDuration
                    easing: Suru.animations.EasingIn
                }
            }
        }
    }
    Rectangle {
        visible: customizedButton.showEnterOverlay
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        radius: width / 2
        width: units.gu(3)
        height: width
        color: theme.palette.normal.foreground
        border {
            color: theme.palette.normal.activity
            width: units.dp(1)
        }

        Icon {
            anchors.centerIn: parent
            name: "keyboard-enter"
            color: theme.palette.normal.foregroundText
            width: parent.width * 0.6
            height: width
        }
    }

    /*
    QQC2.ToolTip.delay: 1000
    QQC2.ToolTip.visible: hovered && customizedButton.tooltipText !== ""
    QQC2.ToolTip.text: customizedButton.tooltipText
    */
}

