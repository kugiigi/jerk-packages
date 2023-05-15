//  A toy QML colorpicker control, by Ruslan Shestopalyuk
import QtQuick 2.11
import Ubuntu.Components 1.3 as UITK
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.4
import QtQuick.Controls.Suru 2.2
import "content"

Rectangle {
    id: colorPicker
    property color colorValue: "transparent"
    property bool enableAlphaChannel: true
    property bool enableDetails: true
    property int colorHandleRadius : units.gu(1)
    property bool paletteMode : false
    property bool enablePaletteMode : false
    property string switchToColorPickerString: "Palette..."
    property string switchToPalleteString: "Color Picker..."
    property bool readOnly:true
    property alias hexValue: hexTextInput.text
    property bool savedPaletteIsSelected: paletteMode && ! Qt.colorEqual(savedPaletteColor, "transparent")
    property alias savedPaletteColor: paletts.saved_palette_color

    property color _changingColorValue : paletteMode ?
                                   _rgb(paletts.paletts_color, alphaSlider.value) :
                                   _hsla(hueSlider.value, sbPicker.saturation,
                                    sbPicker.brightness, alphaSlider.value)
    on_ChangingColorValueChanged: {
        colorValue = _changingColorValue
    }

    signal colorChanged(color changedColor)

    implicitWidth: picker.implicitWidth
    implicitHeight: palette_switch.implicitHeight + picker.implicitHeight
    color: Suru.backgroundColor
    clip: true

    Text {
        id: palette_switch
        textFormat: Text.StyledText
        text: paletteMode ?
                  "<a href=\".\">" + switchToColorPickerString + "</a>" :
                  "<a href=\".\">" + switchToPalleteString + "</a>"
        visible: enablePaletteMode
        onLinkActivated: {
            paletteMode = !paletteMode
        }
        anchors.right: parent.right
        anchors.rightMargin: colorHandleRadius
        linkColor: "white"
    }

    RowLayout {
        id: picker
        anchors.top: enablePaletteMode　? palette_switch.bottom : parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: colorHandleRadius
        anchors.bottom: parent.bottom
        spacing: 0

        SwipeView {
            id: swipe
            clip: true
            interactive: false
            currentIndex: paletteMode ? 1 : 0

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: paletts.implicitWidth
            Layout.minimumHeight: paletts.implicitHeight

            SBPicker {
                id: sbPicker

                hueColor: {
                    var v = 1.0-hueSlider.value

                    if(0.0 <= v && v < 0.16) {
                        return Qt.rgba(1.0, 0.0, v/0.16, 1.0)
                    } else if(0.16 <= v && v < 0.33) {
                        return Qt.rgba(1.0 - (v-0.16)/0.17, 0.0, 1.0, 1.0)
                    } else if(0.33 <= v && v < 0.5) {
                        return Qt.rgba(0.0, ((v-0.33)/0.17), 1.0, 1.0)
                    } else if(0.5 <= v && v < 0.76) {
                        return Qt.rgba(0.0, 1.0, 1.0 - (v-0.5)/0.26, 1.0)
                    } else if(0.76 <= v && v < 0.85) {
                        return Qt.rgba((v-0.76)/0.09, 1.0, 0.0, 1.0)
                    } else if(0.85 <= v && v <= 1.0) {
                        return Qt.rgba(1.0, 1.0 - (v-0.85)/0.15, 0.0, 1.0)
                    } else {
                        console.log("hue value is outside of expected boundaries of [0, 1]")
                        return "red"
                    }
                }
            }

            Palettes {
                id: paletts
                
                onPaletts_colorChanged : {
                    alphaSlider.setValue(paletts_color.a)
                }
            }
        }

        // hue picking slider
        Item {
            id: huePicker
            visible: !paletteMode
            width: units.gu(3)
            Layout.fillHeight: true
            Layout.topMargin: colorHandleRadius
            Layout.bottomMargin: colorHandleRadius

            Rectangle {
                anchors.fill: parent
                id: colorBar
                gradient: Gradient {
                    GradientStop { position: 1.0;  color: "#FF0000" }
                    GradientStop { position: 0.85; color: "#FFFF00" }
                    GradientStop { position: 0.76; color: "#00FF00" }
                    GradientStop { position: 0.5;  color: "#00FFFF" }
                    GradientStop { position: 0.33; color: "#0000FF" }
                    GradientStop { position: 0.16; color: "#FF00FF" }
                    GradientStop { position: 0.0;  color: "#FF0000" }
                }
            }
            ColorSlider {
                id: hueSlider; anchors.fill: parent
            }
        }

        // alpha (transparency) picking slider
        Item {
            id: alphaPicker
            visible: enableAlphaChannel
            width: units.gu(3)
            Layout.leftMargin: units.gu(2)
            Layout.fillHeight: true
            Layout.topMargin: colorHandleRadius
            Layout.bottomMargin: colorHandleRadius
            Checkerboard { cellSide: 4 }
            //  alpha intensity gradient background
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#FF000000" }
                    GradientStop { position: 1.0; color: "#00000000" }
                }
            }
            ColorSlider {
                id: alphaSlider; anchors.fill: parent
            }
        }

        // details column
        Column {
            id: detailColumn
            Layout.leftMargin: units.gu(2)
            Layout.fillHeight: true
            Layout.topMargin: colorHandleRadius
            Layout.bottomMargin: colorHandleRadius
            Layout.alignment: Qt.AlignRight
            visible: enableDetails

            // current color/alpha display rectangle
            PanelBorder {
                width: parent.width
                height: units.gu(10)
                visible: enableAlphaChannel
                Checkerboard { cellSide: 5 }
                Rectangle {
                    width: parent.width; height: units.gu(10)
                    border.width: units.dp(1); border.color: "black"
                    color: colorPicker.colorValue
                }
            }

            // "#XXXXXXXX" color value box
            PanelBorder {
                id: colorEditBox
                height: units.gu(5); width: parent.width
                TextInput {
                    id: hexTextInput
                    anchors.fill: parent
                    color: "#AAAAAA"
                    selectionColor: "#FF7777AA"
                    font.pixelSize: 11
                    maximumLength: 9
                    focus: false
                    text: _fullColorString(colorPicker.colorValue)
                    selectByMouse: true
                    readOnly: colorPicker.readOnly
                    onEditingFinished: {
                        setColorValue(text);
                    }
                }
            }

            // H, S, B color values boxes
            Column {
                visible: !paletteMode
                width: parent.width
                NumberBox {
                    id: _h
                    caption: "H:";
                    value: hueSlider.value.toFixed(2);
                    readOnly: colorPicker.readOnly
                    onTextChanged: {
                        var c=colorPicker.colorValue
                        var newValue=Qt.hsla(_h.value,c.hslSaturation,
                                             c.hslLightness,c.a)
                        setColorValue(newValue)
                    }
                }
                NumberBox {
                    id: _s
                    caption: "S:";
                    value: sbPicker.saturation.toFixed(2);
                    readOnly: colorPicker.readOnly
                    onTextChanged: {
                        var newValue=_hsla(hueSlider.value, _s.value,
                                           sbPicker.brightness, alphaSlider.value)
                        setColorValue(newValue)
                    }
                }
                NumberBox {
                    id: _b
                    caption: "B:";
                    value: sbPicker.brightness.toFixed(2);
                    readOnly: colorPicker.readOnly
                    onTextChanged: {
                        var newValue=_hsla(hueSlider.value, sbPicker.saturation,
                                           _b.value, alphaSlider.value)
                       setColorValue(newValue)
                    }
                }
            }

            // filler rectangle
            Rectangle {
                width: parent.width; height: units.gu(2)
                color: "transparent"
            }

            // R, G, B color values boxes
            Column {
                width: parent.width
                NumberBox {
                    id: _r
                    caption: "R:"
                    value: Math.ceil(colorPicker.colorValue.r*255)
                    min: 0; max: 255
                    readOnly: colorPicker.readOnly
                    onTextChanged: {
                        var c= colorPicker.colorValue
                        var newValue=Qt.rgba(_r.value/255.0,c.g,c.b,c.a)
                        setColorValue(newValue)
                    }
                }
                NumberBox {
                    id:_g
                    caption: "G:"
                    value: Math.ceil(colorPicker.colorValue.g*255)
                    min: 0; max: 255
                    readOnly: colorPicker.readOnly
                    onTextChanged: {
                        var c= colorPicker.colorValue
                        var newValue=Qt.rgba(c.r,_g.value/255.0,c.b,c.a)
                        setColorValue(newValue)
                    }
                }
                NumberBox {
                    id: _b1
                    caption: "B:"
                    value: Math.ceil(colorPicker.colorValue.b*255)
                    min: 0; max: 255
                    readOnly: colorPicker.readOnly
                    onTextChanged: {
                        var c= colorPicker.colorValue
                        var newValue=Qt.rgba(c.r,c.g,_b1.value/255.0,c.a)
                        setColorValue(newValue)
                    }
                }
            }

            // alpha value box
            NumberBox {
                id:_a
                visible: enableAlphaChannel
                caption: "A:";
                value: Math.ceil(alphaSlider.value*255)
                min: 0; max: 255
                readOnly: colorPicker.readOnly
                onTextChanged: {
                    var c= colorPicker.colorValue
                    var newValue=Qt.rgba(c.r,c.g,c.b,_a.value/255.0)
                    setColorValue(newValue)
                }
            }
        }
    }

    //  creates color value from hue, saturation, brightness, alpha
    function _hsla(h, s, b, a) {
        var lightness = (2 - s)*b
        var satHSL = s*b/((lightness <= 1) ? lightness : 2 - lightness)
        lightness /= 2

        var c = Qt.hsla(h, satHSL, lightness, a)

        colorChanged(c)

        return c
    }

    // create rgb value
    function _rgb(rgb, a) {

        var c = Qt.rgba(rgb.r, rgb.g, rgb.b, a)

        colorChanged(c)

        return c
    }

    //  creates a full color string from color value and alpha[0..1], e.g. "#FF00FF00"
    function _fullColorString(clr) {
        return "#" + ((Math.ceil(clr.a*255)+256).toString(16).substr(1, 2).toUpperCase() +
                      (Math.ceil(clr.r*255)+256).toString(16).substr(1, 2).toUpperCase() +
                      (Math.ceil(clr.g*255)+256).toString(16).substr(1, 2).toUpperCase() +
                      (Math.ceil(clr.b*255)+256).toString(16).substr(1, 2).toUpperCase());
    }

    //  extracts integer color channel value [0..255] from color value
        // return color value from string #XXXXXXXX
    function _getColorFromStr(clr) {
        if (clr.length == 7) {
            clr = clr.slice(0, 1) + "ff" + clr.slice(1, 7);
        }
        var a = parseInt(clr.toString().substr(1, 2), 16)/255.0;
        var r=parseInt(clr.toString().substr(3, 2), 16)/255.0;
        var g=parseInt(clr.toString().substr(5, 2), 16)/255.0;
        var b=parseInt(clr.toString().substr(7, 2), 16)/255.0;
        return Qt.rgba(r,g,b,a);
    }
    //Set colorValue from string #XXXXXXXX
    function setColorValue(clr)
    {
        var c = _getColorFromStr(clr);
        paletts.setColor(c);
        hueSlider.setValue(c.hslHue)
        alphaSlider.setValue(c.a)
        var light=c.hslLightness*2;
        var y,x
        if(light<=1)
        {
            y=c.hslLightness*(c.hslSaturation+1)
            x=c.hslSaturation*light/y;
        }
        else
        {
            y=c.hslLightness*(1-c.hslSaturation)+c.hslSaturation
            x=2*c.hslSaturation*(1-c.hslLightness)/y
        }
        sbPicker.setSaturation(x);
        sbPicker.setBrightness(y);
    }

    // set color from outside
    function setColor(color) {

        // color object
        var c = Qt.tint(color, "transparent")

        // set alpha
        alphaSlider.setValue(c.a)

        // set rgb. Now it's insufficient to update hue related component.
        colorPicker.colorValue = c
    }
}
