/****************************************************************************
**
** Copyright (C) 2017, 2018 Stefano Verzegnassi <stefano@ubports.com>
** Copyright (C) 2017 The Qt Company Ltd.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPLv3 included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: https://www.gnu.org/licenses/lgpl.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2.0 or later as published by the Free
** Software Foundation and appearing in the file LICENSE.GPL included in
** the packaging of this file. Please review the following information to
** ensure the GNU General Public License version 2.0 requirements will be
** met: http://www.gnu.org/licenses/gpl-2.0.html.
**
****************************************************************************/

import QtQuick 2.9
import QtQuick.Templates 2.2 as T
import QtQuick.Controls.Suru 2.2
import QtQuick.Controls 2.2
import QtQuick.Controls.impl 2.2

T.Tumbler {
    id: control

    implicitWidth: control.Suru.units.gu(8)
    implicitHeight: control.Suru.units.gu(24)

    opacity: control.enabled ? 1.0 : 0.5

    delegate: Text {
        text: modelData
        font: control.font
        color: control.Suru.foregroundColor
        opacity: (1.0 - Math.abs(Tumbler.displacement) / (visibleItemCount / 2)) * (control.enabled ? 1 : 0.6)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    contentItem: TumblerView {
        id: tumblerView
        model: control.model
        delegate: control.delegate
        path: Path {
            startX: tumblerView.width / 2
            startY: -tumblerView.delegateHeight / 2
            PathLine {
                x: tumblerView.width / 2
                y: (control.visibleItemCount + 1) * tumblerView.delegateHeight - tumblerView.delegateHeight / 2
            }
        }

        property real delegateHeight: control.availableHeight / control.visibleItemCount
    }

    MouseArea {
        z: 9999
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onWheel: {
            const _deltaY = wheel.angleDelta.y
            if (_deltaY >= 120) {
                if (control.currentIndex === 0) {
                    control.currentIndex = control.count - 1
                } else {
                    control.currentIndex -= 1
                }
            } else if (_deltaY <= -120) {
                if (control.currentIndex === control.count - 1) {
                    control.currentIndex = 0
                } else {
                    control.currentIndex += 1
                }
            }
            wheel.accepted = true;
        }
    }
}
