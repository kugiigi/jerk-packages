/*
 * Copyright (C) 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.15
// ENH032 - Infographics Outer Wilds
import QtGraphicalEffects 1.12
// ENH032 - End
import Lomiri.Components 1.3
import "../Panel/Indicators"
import Lomiri.Indicators 0.1 as Indicators

Item {
    id: clock

    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height

    // Allows to set the current Date. Will be overwritten if visible
    property date currentDate
    // ENH032 - Infographics Outer Wilds
    property bool owThemed: root.enableOW || shell.settings.ow_ColoredClock
    property bool owDLCThemed: false
    property bool largeMode: false
    property bool gradientTimeText: false
    property bool gradientDateText: false
    // ENH032 - End
    // ENH064 - Dynamic Cove
    property bool dateOnly: false
    // ENH064 - End

    Component.onCompleted: {
        if (visible) {
            currentDate = new Date()
        }
    }

    Connections {
        target: i18n
        function onLanguageChanged() {
            if (visible) {
                timeLabel.text = Qt.formatTime(clock.currentDate); // kicks time
                clock.currentDate = new Date(); // kicks date
            }
        }
    }

    Indicators.SharedLomiriMenuModel {
        id: timeModel
        objectName: "timeModel"

        busName: "org.ayatana.indicator.datetime"
        actions: { "indicator": "/org/ayatana/indicator/datetime" }
        menuObjectPath: clock.visible ? "/org/ayatana/indicator/datetime/phone" : ""
    }

    Indicators.ModelActionRootState {
        menu: timeModel.model
        onUpdated: {
            if (timeLabel.text != rightLabel) {
                if (rightLabel != "") timeLabel.text = rightLabel.trim();
                clock.currentDate = new Date();
            }
        }
    }

    Column {
        // ENH032 - Infographics Outer Wilds
        // spacing: units.gu(0.5)
        spacing: clock.owThemed ? 0 : units.gu(0.5)
        /*
        Label {
            id: timeLabel
            objectName: "timeLabel"

            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: units.gu(7.5)
            color: "white"
            text: Qt.formatTime(clock.currentDate)
            font.weight: Font.Light
        }

        Label {
            id: dateLabel
            objectName: "dateLabel"

            anchors.horizontalCenter: parent.horizontalCenter
            fontSize: "medium"
            color: "white"
            text: Qt.formatDate(clock.currentDate, Qt.DefaultLocaleLongDate)
            font.weight: Font.Light
        }
        */
        Item {
            width: timeLabel.width
            height: timeLabel.contentHeight
            anchors.horizontalCenter: parent.horizontalCenter
            // ENH064 - Dynamic Cove
            visible: !clock.dateOnly
            // ENH064 - End

            Label {
                id: timeLabel
                objectName: "timeLabel"

                property bool solidColor: !clock.gradientTimeText

                // font.pixelSize: units.gu(7.5)
                font.pixelSize: clock.owThemed ? clock.largeMode ? units.gu(10)
                                                                 : units.gu(8.5)
                                               : units.gu(7.5)
                // color: "white"
                // ENH067 - Custom Lockscreen Clock Color
                //color: clock.owThemed && solidColor ? "#f17f44" : "white"
                color: {
                    if (clock.owThemed && solidColor) {
                        if (clock.owDLCThemed) {
                            return "#52f7bd"
                        } else {
                            return "#f17f44"
                        }
                    } else if (shell.settings.useCustomLSClockColor) {
                        return shell.settings.customLSClockColor
                    }

                    return "white"
                }
                // ENH067 - End
                visible: !timeGradientLoader.active || timeDLCGradientLoader.active
                // ENH068 - Custom Lockscreen Clock Font
                //font.family: clock.owThemed ? "Likhan" : "Ubuntu"
                font.family: clock.owThemed ? "Likhan"
                                            : shell.settings.useCustomLSClockFont
                                                    && shell.settings.customLSClockFont ? shell.settings.customLSClockFont
                                                                                        : "Ubuntu"
                style: shell.settings.lockScreenClockStyle
                styleColor: shell.settings.lockScreenClockStyleColor
                // ENH068 - End
                text: Qt.formatTime(clock.currentDate)
                font.weight: Font.Light
            }

            Loader {
                id: timeDLCGradientLoader

                active: clock.owDLCThemed
                asynchronous: true
                anchors.fill: timeLabel
                opacity: 0.3
                sourceComponent: Component {
                    RadialGradient {
                        source: timeLabel
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#F0F0F0"; }
                            GradientStop { position: 0.5; color: "#000000"; }
                            GradientStop { position: 1.0; color: "#FFFFFF"; }
                        }
                    }
                }
            }

            Loader {
                id: timeGradientLoader

                active: clock.owThemed && !timeLabel.solidColor && !timeDLCGradientLoader.active
                asynchronous: true
                anchors.fill: timeLabel
                sourceComponent: Component {
                    LinearGradient  {
                        source: timeLabel
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#a74915" }
                            GradientStop { position: 1.0; color: "#faba36" }
                        }
                    }
                }
            }
        }

        Item {
            width: dateLabel.width
            // ENH064 - Dynamic Cove
            // height: dateLabel.contentHeight
            height: clock.dateOnly ? units.gu(15) : dateLabel.contentHeight
            // ENH064 - End
            anchors.horizontalCenter: parent.horizontalCenter

            Label {
                id: dateLabel
                objectName: "dateLabel"

                property bool solidColor: !clock.gradientDateText
                // fontSize: "medium"
                // ENH067 - Custom Lockscreen Clock Color
                // color: "white"
                color: {
                    if (clock.owThemed && solidColor) {
                        return "#30eadf"
                    } else if (shell.settings.useCustomLSClockColor) {
                        if (shell.settings.useCustomLSDateColor) {
                            return shell.settings.customLSDateColor
                        } else {
                            return shell.settings.customLSClockColor
                        }
                    }

                    return "white"
                }
                // ENH067 - End
                visible: !dateGradientLoader.active || dateDLCGradientLoader.active
                // ENH064 - Dynamic Cove
                //fontSize: clock.owThemed ? clock.largeMode ? "x-large" : "large"
                //                         : "medium"
                fontSize: {
                    if (clock.dateOnly) {
                        return "large"
                    } else {
                        if (clock.owThemed) {
                            if (clock.largeMode) {
                                return  "x-large"
                            } else {
                                return "large"
                            }
                        }
                    }
                    return "medium"
                }
                // ENH064 - End
                // ENH068 - Custom Lockscreen Clock Font
                //font.family: clock.owThemed ? "Likhan" : "Ubuntu"
                font.family: clock.owThemed ? "Likhan"
                                            : shell.settings.useCustomLSClockFont
                                                    && shell.settings.customLSClockFont ? shell.settings.customLSClockFont
                                                                                        : "Ubuntu"
                style: shell.settings.lockScreenDateStyle
                styleColor: shell.settings.lockScreenDateStyleColor
                // ENH068 - End
                text: Qt.formatDate(clock.currentDate, Qt.DefaultLocaleLongDate)
                font.weight: Font.Light
                // ENH064 - Dynamic Cove
                anchors.verticalCenter: parent.verticalCenter
                // ENH064 - End
            }

            Loader {
                id: dateGradientLoader
                active: clock.owThemed && !dateLabel.solidColor && !dateDLCGradientLoader.active
                asynchronous: true
                anchors.fill: dateLabel
                sourceComponent: Component {
                    LinearGradient  {
                        source: dateLabel
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#11a38c" }
                            GradientStop { position: 0.2; color: "#14b9a8" }
                            GradientStop { position: 1.0; color: "#30eadf" }
                        }
                    }
                }
            }

            Loader {
                id: dateDLCGradientLoader
                active: clock.owDLCThemed
                asynchronous: true
                anchors.fill: dateLabel
                opacity: 0.3
                sourceComponent: Component {
                    RadialGradient {
                        source: dateLabel
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#F0F0F0"; }
                            GradientStop { position: 0.5; color: "#000000"; }
                            GradientStop { position: 1.0; color: "#FFFFFF"; }
                        }
                    }
                }
            }
        }
        // ENH032 - End
    }
}
