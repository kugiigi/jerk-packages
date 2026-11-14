/*
 * Copyright (C) 2014-2016 Canonical Ltd
 *
 * This file is part of Ubuntu Clock App
 *
 * Ubuntu Clock App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * Ubuntu Clock App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import Lomiri.Components 1.3

Flipable {
    id: digitalShadow

    // Properties to set the size of the digital shadow
    property int shadowWidth
    property int shadowTimeFontSize
    property int shadowPeriodFontSize

    // Property to disable the seconds hand
    property alias showSeconds: _analogMode.showSeconds

    // Property to switch between digital and analog mode
    property bool isAnalog: false

    width: shadowWidth
    height: width/2
    clip: true

    front: LPDigitalMode {
        id: _digitalMode

        width: shadowWidth
        timeFontSize: shadowTimeFontSize
        timePeriodFontSize: shadowPeriodFontSize

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }

    back: LPAnalogMode {
        id: _analogMode

        width: shadowWidth
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }

    transform: Rotation {
        id: rotation
        origin.x: digitalShadow.width/2
        origin.y: 0
        axis.x: 1; axis.y: 0; axis.z: 0
        angle: 0
    }

    states: State {
        name: "Digital"
        when: digitalShadow.isAnalog
        PropertyChanges {
            target: rotation
            angle: -180
        }
    }

    transitions: Transition {
        LomiriNumberAnimation {
            target: rotation
            property: "angle"
            duration: 333
        }
    }
}
