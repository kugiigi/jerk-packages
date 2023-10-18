import QtQuick 2.12

ShaderEffect {
    property color color: Qt.rgba(Theme.palette.normal.background.r, Theme.palette.normal.background.g, Theme.palette.normal.background.b, 0.77)
    property real borderWidth: 10
    property color borderColorTop: "#6E6E6E"
    property color borderColorBottom: "#00000000"
    property real borderOpacity: 1.0
    property real borderGradientPosition: 0.5

    property real _texturePixel: 1/width
    property real _borderWidthTex: borderWidth/width
    property real _gradientEdge1: borderGradientPosition <= 0.5 ? borderGradientPosition : 0.0
    property real _gradientEdge2: borderGradientPosition <= 0.5 ? 1.0 : borderGradientPosition

    height: width

    fragmentShader: "
        varying mediump vec2 qt_TexCoord0;
        uniform lowp float qt_Opacity;
        uniform lowp vec4 color;
        uniform lowp vec4 borderColorTop;
        uniform lowp vec4 borderColorBottom;
        uniform lowp float borderOpacity;
        uniform lowp float borderGradientPosition;
        uniform lowp float _gradientEdge1;
        uniform lowp float _gradientEdge2;
        uniform lowp float _texturePixel;
        uniform lowp float _borderWidthTex;

        void main() {
            mediump float radius = 0.5;
            mediump float radiusBorder = radius-_borderWidthTex;
            mediump vec2 center = vec2(radius);

            mediump float circleX = (qt_TexCoord0.x - center.x);
            mediump float circleY = (qt_TexCoord0.y - center.y);

            mediump float edge = circleX*circleX + circleY*circleY;
            lowp vec4 borderColor = mix(borderColorTop, borderColorBottom, smoothstep(_gradientEdge1, _gradientEdge2, qt_TexCoord0.y)) * borderOpacity;
            lowp vec4 fillColor = mix(vec4(0),
                                      mix(borderColor, color, smoothstep(edge-_texturePixel, edge+_texturePixel, radiusBorder*radiusBorder)),
                                      smoothstep(edge-_texturePixel, edge+_texturePixel, radius*radius));
            gl_FragColor = fillColor * qt_Opacity;
        }
    "
}

