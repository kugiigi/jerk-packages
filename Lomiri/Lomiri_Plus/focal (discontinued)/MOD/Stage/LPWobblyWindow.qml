// ENH155 - Wobbly Windows
import QtQuick 2.12
import Lomiri.Components 1.3

Item {
    id: wobblyItem

    property var appItem
    property alias active: wobblyEffectLoader.active

    ShaderEffectSource {
        id: shaderEffectSource

        readonly property real outsideMargin: units.gu(20)
        readonly property bool liveSurface: true

        sourceItem: appItem && appItem.dragging ? appItem : null
        hideSource: enabled
        sourceRect: enabled ? Qt.rect(-outsideMargin, -outsideMargin
                                      , sourceItem.width + outsideMargin * 2, sourceItem.height + outsideMargin * 2) : Qt.rect(0,0,0,0)
        live: liveSurface
        enabled: sourceItem != null && wobblyEffectLoader.active

        Timer {
            interval: 48
            repeat: shaderEffectSource.enabled && !shaderEffectSource.liveSurface
            running: repeat
            onTriggered: shaderEffectSource.scheduleUpdate()
        }
    }
    Loader {
        id: wobblyEffectLoader
        asynchronous: true
        sourceComponent: wobblyShaderEffectComponent
        z: Number.MAX_VALUE
        anchors.fill: parent
        anchors.margins: -shaderEffectSource.outsideMargin
        visible: shaderEffectSource.enabled
    }

    Component {
        id: wobblyShaderEffectComponent

        ShaderEffect {
            id: shaderEffect

            enabled: shaderEffectSource.enabled
            onEnabledChanged: {
                if (enabled) {
                    delayShaderStop.stop()
                    delayShaderStart.restart()
                } else {
                    delayShaderStart.stop()
                    delayShaderStop.restart()
                }
            }

            QtObject {
                id: internal
                property var buf: []
                property point lag
                property point point

                function push(value) {
                    buf.push(value);
                    if (buf.length < 10) {
                        return;
                    }

                    let _point = Qt.point(0,0)
                    if (shaderEffectSource.sourceItem && shaderEffectSource.sourceItem.touchDragging) {
                        _point = shaderEffectSource.sourceItem.touchPoint
                    } else {
                        _point.x = cursor.x
                        _point.y = cursor.y
                    }

                    internal.point = Qt.point(_point.x / shaderEffect.width, _point.y / shaderEffect.height);
                    const last = buf.shift();
                    internal.lag = Qt.point((wobblyItem.x - last.x) / shaderEffect.width, (wobblyItem.y - last.y) / shaderEffect.height)
                }
            }

            Timer {
                id: shaderTimer
                interval: 16
                running: false
                // running: shaderEffect.enabled
                repeat: true

                onTriggered: internal.push(Qt.point(wobblyItem.x, wobblyItem.y))
            }

            // Avoid jumping at the start of a drag
            Timer {
                id: delayShaderStart
                interval: 100
                onTriggered: shaderTimer.restart()
            }
            Timer {
                id: delayShaderStop
                interval: 1000
                onTriggered: shaderTimer.stop()
            }

            property variant src: shaderEffectSource
            property point lag: internal.lag
            property point point: internal.point

            property bool useHighPrecision: true
            readonly property string lowPVertexShader: "
                uniform lowp mat4 qt_Matrix;
                attribute lowp vec4 qt_Vertex;
                attribute lowp vec2 qt_MultiTexCoord0;
                varying lowp vec2 coord;
                void main() {
                    coord = qt_MultiTexCoord0;
                    gl_Position = qt_Matrix * qt_Vertex;
                }"

            readonly property string lowPFragmentShader: "
                varying lowp vec2 coord;
                uniform sampler2D src;
                uniform lowp float qt_Opacity;
                uniform lowp vec2 lag;
                uniform lowp vec2 point;
                void main() {
                    lowp vec2 distVector = point - coord;
                    lowp float dist = dot(distVector, distVector);
                    lowp vec2 distort = pow(0.5, dist) * lag;
                    lowp vec4 tex = texture2D(src, coord + distort);
                    gl_FragColor = tex;
                }"
            readonly property string highPVertexShader: "
                uniform highp mat4 qt_Matrix;
                attribute highp vec4 qt_Vertex;
                attribute highp vec2 qt_MultiTexCoord0;
                varying highp vec2 coord;
                void main() {
                    coord = qt_MultiTexCoord0;
                    gl_Position = qt_Matrix * qt_Vertex;
                }"

            readonly property string highPFragmentShader: "
                varying highp vec2 coord;
                uniform sampler2D src;
                uniform lowp float qt_Opacity;
                uniform highp vec2 lag;
                uniform highp vec2 point;
                void main() {
                    highp vec2 distVector = point - coord;
                    highp float dist = dot(distVector, distVector);
                    highp vec2 distort = pow(0.5, dist) * lag;
                    lowp vec4 tex = texture2D(src, coord + distort);
                    gl_FragColor = tex;
                }"

            vertexShader: useHighPrecision ? highPVertexShader : lowPVertexShader
            fragmentShader: useHighPrecision ? highPFragmentShader :lowPFragmentShader
        }
    }
}
