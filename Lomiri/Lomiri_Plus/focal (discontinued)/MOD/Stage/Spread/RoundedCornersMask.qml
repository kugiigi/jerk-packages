/*
 * Copyright (C) 2016 Canonical, Ltd.
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
// ENH006 - Rounded app spread
import QtQuick 2.12

Loader {
    id: loader
    
    property var sourceItem: null
    property real cornerRadius: 0
    property real borderWidth: units.gu(5)
    
    active: sourceItem !== null
    asynchronous: true
    anchors.fill: sourceItem
    sourceComponent: Component {
        Item {
            id: root

            Item {
                id: opacityMask
                anchors.fill: parent

                Rectangle {
                    id: clipRect

                    color: "transparent"
                    radius: loader.cornerRadius
                    border {
                        color: "black"
                        width: loader.borderWidth
                    }

                    anchors.fill: parent
                    anchors.margins: -loader.borderWidth
                }
            }

            ShaderEffect {
                id: opacityEffect
                anchors.fill: parent

                property variant source: ShaderEffectSource {
                    id: shaderEffectSource
                    sourceItem: loader.sourceItem
                    sourceRect: loader.sourceItem ? Qt.rect(sourceItem.x,
                                                        sourceItem.y,
                                                        sourceItem.width,
                                                        sourceItem.height)
                                                : Qt.rect(0,0,0,0)
                    hideSource: true
                }

                property var mask: ShaderEffectSource {
                    sourceItem: opacityMask
                    hideSource: true
                }

                fragmentShader: "
                    varying highp vec2 qt_TexCoord0;
                    uniform sampler2D source;
                    uniform sampler2D mask;
                    void main(void)
                    {
                        highp vec4 sourceColor = texture2D(source, qt_TexCoord0);
                        highp vec4 maskColor = texture2D(mask, qt_TexCoord0);

                        sourceColor *= 1.0 - maskColor.a;

                        gl_FragColor = sourceColor;
                    }"
            }
        }
    }
}
// ENH006 - End
