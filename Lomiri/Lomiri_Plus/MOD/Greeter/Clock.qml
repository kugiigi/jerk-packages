/*
 * Copyright (C) 2013 Canonical, Ltd.
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

import QtQuick 2.12
// ENH032 - Infographics Outer Wilds
import QtGraphicalEffects 1.12
// ENH032 - End
import Ubuntu.Components 1.3
import "../Panel/Indicators"
import Unity.Indicators 0.1 as Indicators

Item {
    id: clock

    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height

    // Allows to set the current Date. Will be overwritten if visible
    property date currentDate
    // ENH032 - Infographics Outer Wilds
    property bool owThemed: root.enableOW || shell.settings.ow_ColoredClock
    property bool largeMode: false
    property bool gradientTimeText: false
    // ENH032 - End

    Component.onCompleted: {
        if (visible) {
            currentDate = new Date()
        }
    }

    Connections {
        target: i18n
        onLanguageChanged: {
            if (visible) {
                timeLabel.text = Qt.formatTime(clock.currentDate); // kicks time
                clock.currentDate = new Date(); // kicks date
            }
        }
    }

    Indicators.SharedUnityMenuModel {
        id: timeModel
        objectName: "timeModel"

        busName: "com.canonical.indicator.datetime"
        actions: { "indicator": "/com/canonical/indicator/datetime" }
        menuObjectPath: clock.visible ? "/com/canonical/indicator/datetime/phone" : ""
    }

    Indicators.ModelActionRootState {
        menu: timeModel.model
        onUpdated: {
            if (timeLabel.text != rightLabel) {
                if (rightLabel != "") timeLabel.text = rightLabel;
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

            Label {
                id: timeLabel
                objectName: "timeLabel"

                property bool solidColor: !clock.gradientTimeText

                // font.pixelSize: units.gu(7.5)
                font.pixelSize: clock.owThemed ? clock.largeMode ? units.gu(10)
                                                                 : units.gu(8.5)
                                               : units.gu(7.5)
                // color: "white"
                color: clock.owThemed && solidColor ? "#f17f44" : "white"
                visible: !clock.owThemed || solidColor
                font.family: clock.owThemed ? "Likhan" : "Ubuntu"
                text: Qt.formatTime(clock.currentDate)
                font.weight: Font.Light
            }
            Loader {
                active: clock.owThemed && !timeLabel.solidColor
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
            height: dateLabel.contentHeight
            anchors.horizontalCenter: parent.horizontalCenter

            Label {
                id: dateLabel
                objectName: "dateLabel"

                // fontSize: "medium"
                color: "white"
                visible: !clock.owThemed
                fontSize: clock.owThemed ? clock.largeMode ? "x-large" : "large"
                                         : "medium"
                font.family: clock.owThemed ? "Likhan" : "Ubuntu"
                text: Qt.formatDate(clock.currentDate, Qt.DefaultLocaleLongDate)
                font.weight: Font.Light
            }
            Loader {
                active: clock.owThemed
                asynchronous: true
                anchors.fill: dateLabel
                sourceComponent: Component {
                    LinearGradient  {
                        source: dateLabel
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#0e0e18" }
                            GradientStop { position: 1.0; color: "#2cfefd" }
                        }
                    }
                }
            }
        }
        // ENH032 - End
    }
}
