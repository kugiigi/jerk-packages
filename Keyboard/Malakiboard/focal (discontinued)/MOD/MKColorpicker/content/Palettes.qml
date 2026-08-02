import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.12
import Lomiri.Components 1.3

Item {
    id: item
    property color paletts_color : "transparent"
    property color saved_palette_color : "transparent"

    function setColor(clr) {
        _export.target_color = clr
        _export.checked=false
        _export.checked=true
    }
    
    function selectColor(newColor, savedColor) {
        paletts_color = newColor
        if (savedColor) {
            saved_palette_color = savedColor
        } else {
            saved_palette_color = "transparent"
        }
    }

    ButtonGroup {
        id: group
    }

    Flickable {
        anchors {
            fill: parent
            margins: units.gu(1)
            rightMargin: 0
        }
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: grid.height

        GridLayout {
            id: grid

            property real itemHeight: units.gu(6)
            columns: Math.floor((width - (anchors.margins * 2)) / (itemHeight))
            columnSpacing: 0
            rowSpacing: 0
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            
            GridLayout {
                id: savedGrid

                Layout.columnSpan: grid.columns > 0 ? grid.columns : 1
                Layout.fillWidth: true
                columns: grid.columns
                columnSpacing: 0
                rowSpacing: 0

                Label {
                    Layout.columnSpan: savedGrid.columns > 0 ? savedGrid.columns : 1
                    text: "Saved Palettes:"
                    visible: fullScreenItem.settings.savedPalettes.length > 0
                    verticalAlignment: Text.AlignVCenter
                    Layout.preferredHeight: units.gu(6)
                    Layout.leftMargin: units.gu(1)
                }

                Repeater {
                    model: fullScreenItem.settings.savedPalettes

                    Palette {
                        Layout.preferredHeight: grid.itemHeight
                        Layout.preferredWidth: grid.itemHeight
                        Layout.columnSpan: 1
                        Layout.rowSpan: 1
                        ButtonGroup.group: group
                        target_color: modelData
                        onCheckedChanged: {
                            if(checked) {
                                item.selectColor(target_color, target_color)
                            }
                        }
                    }
                }
            }

            GridLayout {
                id: ubuntuGrid

                Layout.columnSpan: grid.columns > 0 ? grid.columns : 1
                Layout.fillWidth: true
                columns: grid.columns
                columnSpacing: 0
                rowSpacing: 0

                Label {
                    Layout.columnSpan: ubuntuGrid.columns > 0 ? ubuntuGrid.columns : 1
                    text: "Suru Palettes:"
                    verticalAlignment: Text.AlignVCenter
                    Layout.preferredHeight: units.gu(6)
                    Layout.leftMargin: units.gu(1)
                }

                Repeater {
                    model: [
                        LomiriColors.ash
                        , LomiriColors.blue
                        , LomiriColors.graphite
                        , LomiriColors.green
                        , LomiriColors.inkstone
                        , LomiriColors.jet
                        , LomiriColors.orange
                        , LomiriColors.porcelain
                        , LomiriColors.purple
                        , LomiriColors.red
                        , LomiriColors.silk
                        , LomiriColors.slate
                    ]

                    Palette {
                        Layout.preferredHeight: grid.itemHeight
                        Layout.preferredWidth: grid.itemHeight
                        Layout.columnSpan: 1
                        Layout.rowSpan: 1
                        ButtonGroup.group: group
                        target_color: modelData
                        onCheckedChanged: {
                            if(checked) {
                                item.selectColor(target_color)
                            }
                        }
                    }
                }
            }
            
            Label {
                Layout.columnSpan: grid.columns > 0 ? grid.columns : 1
                text: "Other Palettes:"
                verticalAlignment: Text.AlignVCenter
                Layout.preferredHeight: units.gu(6)
                Layout.leftMargin: units.gu(1)
            }
            
            Palette {
                id: _export

                Layout.preferredHeight: grid.itemHeight
                Layout.preferredWidth: grid.itemHeight
                Layout.columnSpan: 1
                Layout.rowSpan: 1
                visible: target_color ? true : false
                ButtonGroup.group: group
                onCheckedChanged: {
                    if(checked) {
                        item.selectColor(target_color)
                    }
                }
            }

            Repeater {
                model: [
                    "black", "#705958", "red", "#c90002", "#9d0000", "#b20093", "#c978b8", "#750161", "gray", "#8366b4"
                    , "purple", "#51127c", "#400061", "#5361b5", "#1b3d9f", "#152c81", "#061967", "darkgray", "#5188ca"
                    , "blue", "#004d90", "#003d75", "#02afae", "#008c8a", "#017071", "#36c590", "lightgray", "#56c222"
                    , "green", "#018944", "#006f35", "#fcf471", "yellow", "#cdc101", "#a39700"
                    , "white", "#fdc667", "#fea200", "#cb8001", "#a66400", "#ffa566", "#ff7c00", "#cf6402", "#a54b00"
                ]

                Palette {
                    Layout.preferredHeight: grid.itemHeight
                    Layout.preferredWidth: grid.itemHeight
                    Layout.columnSpan: 1
                    Layout.rowSpan: 1
                    ButtonGroup.group: group
                    target_color: modelData
                    onCheckedChanged: {
                        if(checked) {
                            item.selectColor(target_color)
                        }
                    }
                }
            }
        }
    }
}
