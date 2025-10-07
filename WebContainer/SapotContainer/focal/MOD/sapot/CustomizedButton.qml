import QtQuick 2.4
import Lomiri.Components 1.3
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Controls.Suru 2.2
import QtQuick.Layouts 1.12

QQC2.ItemDelegate {
    id: customizedButton

    readonly property IconGroupedProperties secondaryIcon: IconGroupedProperties{
        width: units.gu(2)
        height: units.gu(2)
        color: theme.palette.normal.backgroundText
    }

    property real radius: units.gu(1)
    property bool transparentBackground: false
    property color backgroundColor: Suru.backgroundColor
    property color borderColor: Suru.backgroundColor
    property color highlightedBorderColor: Suru.highlightColor
    property string tooltipText
    property int alignment: Qt.AlignCenter

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

    Component {
        id: iconComponent

        Icon {
            anchors.fill: parent
            name: customizedButton.icon.name
            color: customizedButton.icon.color
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

            anchors.verticalCenter: parent.verticalCenter

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

            QQC2.Label {
                id: mainLabel

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: customizedButton.text
                Suru.textLevel: customizedButton.Suru.textLevel
                color: theme.palette.normal.backgroundText
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

        color: customizedButton.transparentBackground ? "transparent" : customizedButton.backgroundColor
        border.width: customizedButton.highlighted ? units.gu(0.8) : units.gu(0.6)
        border.color: customizedButton.transparentBackground ? "transparent"
                                        : customizedButton.highlighted ? customizedButton.highlightedBorderColor : customizedButton.borderColor
        radius: customizedButton.radius
        Behavior on border.width {
            LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
        }
        
        Rectangle {
            id: highlightRect

            anchors.fill: parent

            visible: customizedButton.down || customizedButton.hovered || customizedButton.highlighted
            opacity: customizedButton.highlighted ? 0.1 : 1.0
            border.width: background.border.width
            border.color: "transparent"
            radius: background.radius
            color: {
                if (customizedButton.highlighted)
                    return Suru.highlightColor

                return customizedButton.down ? Qt.darker(Suru.backgroundColor, 1.2) : Qt.darker(Suru.backgroundColor, 1.1)
            }

            Behavior on color {
                enabled: !customizedButton.highlighted
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

    QQC2.ToolTip.delay: 1000
    QQC2.ToolTip.visible: hovered && customizedButton.tooltipText !== ""
    QQC2.ToolTip.text: customizedButton.tooltipText
}
