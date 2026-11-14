import QtQuick 2.4
import Lomiri.Components 2.0
import QtQuick.Controls 2.2 as QQC2
//~ import QtQuick.Controls.Suru 2.2
import QtQuick.Layouts 1.12

QQC2.ItemDelegate {
    id: customizedButton

    readonly property IconGroupedProperties secondaryIcon: IconGroupedProperties{
        width: units.gu(2)
        height: units.gu(2)
        color: theme.palette.normal.backgroundText
    }
//~     Suru.textLevel
    property string textLevel

    property real radius: units.gu(1)
    property bool transparentBackground: false
//~     property color backgroundColor: Suru.backgroundColor
    property color backgroundColor: theme.palette.normal.background
//~     property color borderColor: Suru.backgroundColor
    property color borderColor: theme.palette.normal.background
//~     property color highlightedBorderColor: Suru.highlightColor
    property color highlightedBorderColor: theme.palette.highlighted.background
    property string tooltipText
    property int alignment: Qt.AlignCenter
    property url imageSource

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
        id: imageComponent

        Image {
            asynchronous: true
            anchors.fill: parent
            source: customizedButton.imageSource
            fillMode: Image.PreserveAspectFit
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
                    if (customizedButton.icon.name) {
                        switch (customizedButton.display) {
                            case QQC2.AbstractButton.IconOnly:
                            case QQC2.AbstractButton.TextBesideIcon:
                                return iconComponent
                            default:
                                return null
                        }
                    }

                    return null
                }
            }
            Loader {
                id: leftImageLoader

                Layout.preferredWidth: customizedButton.icon.width
                Layout.preferredHeight: customizedButton.icon.height
                Layout.alignment: internal.centerContents ? Qt.AlignCenter : Qt.AlignVCenter

                visible: item ? true : false
                asynchronous: true
                sourceComponent: {
                    if (customizedButton.imageSource.toString() != "" ) {
                        switch (customizedButton.display) {
                            case QQC2.AbstractButton.IconOnly:
                            case QQC2.AbstractButton.TextBesideIcon:
                                return imageComponent
                            default:
                                return null
                        }
                    }

                    return null
                }
            }

            QQC2.Label {
                id: mainLabel

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: customizedButton.text
//~                 Suru.textLevel: customizedButton.Suru.textLevel
                readonly property real font_size_multiplier: 0.875
                property string textLevel: customizedButton.textLevel
                font.pixelSize: {
                    let _value = 0
                    switch (textLevel) {
                        case "Small":
                            _value = units.dp(14)
                            break
                        case "HeadingOne":
                            _value = units.dp(32)
                            break
                        case "HeadingTwo":
                            _value = units.dp(24)
                            break
                        case "HeadingThree":
                            _value = units.dp(22)
                            break
                        case "Caption":
                            _value = units.dp(14)
                            break
                        case "Paragraph":
                            _value = units.dp(16)
                            break
                        case "CodeBlock":
                            _value = units.dp(16)
                            break
                        default:
                            _value = units.dp(16)
                    }

                    return _value * font_size_multiplier
                }
                font.weight: {
                    switch (textLevel) {
                        case "Small":
                        case "HeadingOne":
                        case "HeadingTwo":
                        case "HeadingThree":
                        case "Caption":
                        case "Paragraph":
                        case "CodeBlock":
                            return Font.Light
                        default:
                            return Font.Normal
                    }
                }
                font.family: {
                    switch (textLevel) {
                        case "CodeBlock":
                            return "Ubuntu Mono"
                        case "Small":
                        case "HeadingOne":
                        case "HeadingTwo":
                        case "HeadingThree":
                        case "Caption":
                        case "Paragraph":
                        default:
                            return "Ubuntu"
                    }
                }
                font.italic: textLevel === "Caption"
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

                Layout.preferredWidth: customizedButton.secondaryIcon.width
                Layout.preferredHeight: customizedButton.secondaryIcon.height
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
//~                     return Suru.highlightColor
                    return theme.palette.highlighted.background

//~                 return customizedButton.down ? Qt.darker(Suru.backgroundColor, 1.2) : Qt.darker(Suru.backgroundColor, 1.1)
                return customizedButton.down ? Qt.darker(theme.palette.normal.background, 1.2) : Qt.darker(theme.palette.normal.background, 1.1)
            }

            Behavior on color {
                enabled: !customizedButton.highlighted
                ColorAnimation {
//~                     duration: Suru.animations.FastDuration
                    duration: LomiriAnimation.FastDuration
//~                     easing: Suru.animations.EasingIn
                }
            }

            Behavior on opacity {
                NumberAnimation {
//~                     duration: Suru.animations.FastDuration
                    duration: LomiriAnimation.FastDuration
//~                     easing: Suru.animations.EasingIn
                }
            }
        }
    }

    QQC2.ToolTip.delay: 1000
    QQC2.ToolTip.visible: hovered && customizedButton.tooltipText !== ""
    QQC2.ToolTip.text: customizedButton.tooltipText
}
