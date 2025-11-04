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
// ENH175 - Stop background blur updates when locked
import Powerd 0.1
// ENH175 - End

Item {
    id: root

    property Item sourceItem
    property rect blurRect: Qt.rect(0,0,0,0)
    property bool occluding: false

    readonly property int minRadius : Math.max(units.gu(4), 64)
    // ENH138 - Blur radius settings
    // readonly property int blurRadius : Math.min(minRadius, 128)
    readonly property int defaultRadius: shell.settings.enableCustomBlurRadius ? units.gu(shell.settings.customBlurRadius) : Math.min(minRadius, 128)
    property int blurRadius : defaultRadius
    // ENH138 - End
    // ENH180 - Match window titlebar with app
    property bool surfaceUpdates: true
    // ENH180 - End

    ShaderEffectSource {
        id: shaderEffectSource
        sourceItem: root.sourceItem
        hideSource: root.occluding
        sourceRect: root.blurRect
        // ENH182 - Settings to set blur not live in windowed mode
        // Apply this now in both Staged and Windowed mode since it is now live by default
        // live: true
        // ENH180 - Match window titlebar with app
        //live: stage.mode === "windowed" && !shell.settings.useTimerForBackgroundBlurInWindowedMode
        live: !shell.settings.useTimerForBackgroundBlurInWindowedMode && root.surfaceUpdates
        // ENH180 - End
        // ENH182 - End
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

    // ENH175 - Stop background blur updates when locked
    Timer {
        interval: 48
        // ENH180 - Match window titlebar with app
        //repeat: root.visible && (sourceItem != null) && !shaderEffectSource.live && Powerd.status === Powerd.On
        repeat: root.visible && (sourceItem != null) && !shaderEffectSource.live && Powerd.status === Powerd.On && root.surfaceUpdates
        // ENH180 - End
        running: repeat
        onTriggered: shaderEffectSource.scheduleUpdate()
    }
    // ENH175 - End

    // When blur is disabled
    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.background
        visible: sourceItem == null
    }
}
