/*
 * Copyright (C) 2016 Canonical, Ltd.
 * Copyright (C) 2022 UBports Foundation
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
import QtGraphicalEffects 1.0
import Lomiri.Components 1.3

Item {
    id: root

    property Item sourceItem
    property rect blurRect: Qt.rect(0,0,0,0)
    property bool occluding: false

    readonly property int minRadius : Math.max(units.gu(4), 64)
    readonly property int blurRadius : Math.min(minRadius, 128)

    ShaderEffectSource {
        id: shaderEffectSource
        sourceItem: root.sourceItem
        hideSource: root.occluding
        sourceRect: root.blurRect
        live: true
        enabled: sourceItem != null
    }

    FastBlur {
        id: fastBlur
        anchors.fill: parent
        source: shaderEffectSource
        radius: root.blurRadius
        cached: false
        visible: sourceItem != null
        enabled: visible
    }

    // When blur is disabled
    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.background
        visible: sourceItem == null
    }
}
