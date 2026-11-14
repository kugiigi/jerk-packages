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
import Ubuntu.Components 1.3
import QtGraphicalEffects 1.0

/*
  Clock Circle with the shadows and background color set depending on the
  position of the circle.
 */
LPCircle {
    id: _innerCircle

    readonly property real defaultgradientOpacity: 0.3
    property bool isFoldVisible: true
    property alias gradientOpacity: gradientRec.opacity

    color: "transparent"
    borderWidth: units.dp(1)
    borderColorTop: "#00000000"
    borderColorBottom: "#6E6E6E"
    borderOpacity: 0.65
    borderGradientPosition: 0.2

    Rectangle {
        id: gradientRec

        visible: isFoldVisible
        anchors.fill: parent
        anchors.margins: borderWidth
        radius: height / 2
        opacity: _innerCircle.defaultgradientOpacity
        Behavior on opacity { UbuntuNumberAnimation { duration: UbuntuAnimation.SlowDuration } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.palette.normal.foreground }
            GradientStop { position: 0.5; color: Theme.palette.normal.foreground }
            GradientStop { position: 0.5; color: Theme.name == "Ubuntu.Components.Themes.Ambiance" ? "#FDFDFD":"#424242" }
            GradientStop { position: 1.0; color: Theme.name == "Ubuntu.Components.Themes.Ambiance" ? "#FDFDFD":"#424242" }
            GradientStop { position: 0.5; color: Theme.name == "Ubuntu.Components.Themes.Ambiance" ? "#FDFDFD":"#424242" }
            GradientStop { position: 1.0; color: Theme.name == "Ubuntu.Components.Themes.Ambiance" ? "#FDFDFD":"#424242" }
        }
    }
}
