import QtQuick 2.9
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.3
import "keys/"

ColumnLayout {
    id: floatingActions

    RowLayout {
        Layout.fillWidth: true
        
        FloatingActionKey {
            id: startLineButton
            
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: units.gu(5)
            Layout.preferredHeight: units.gu(5)
            action: Action {
                    iconName: "go-first"
                    onTriggered: {
                        if (cursorSwipeArea.selectionMode) {
                            fullScreenItem.selectStartOfLine();
                        } else {
                            fullScreenItem.moveToStartOfLine();
                        }
                    }
                }
        }
        
        FloatingActionKey {
            id: startDocButton
            
            iconRotation: 90
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: units.gu(5)
            Layout.preferredHeight: units.gu(5)
            action: Action {
                    iconName: "go-first"
                    onTriggered: {
                        if (cursorSwipeArea.selectionMode) {
                            fullScreenItem.selectStartOfDocument();
                        } else {
                            fullScreenItem.moveToStartOfDocument();
                        }
                    }
                }
        }
        
        FloatingActionKey {
            id: doneButton
            
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.minimumWidth: units.gu(5)
            Layout.preferredHeight: units.gu(5)
            keyFeedback: false
            action: Action {
                    text: i18n.tr("Done")
                    iconName: "ok"
                    onTriggered: {
                        fullScreenItem.exitSwipeMode()
                    }
                }
        }
            
            
            
        FloatingActionKey {
            id: endDocButton
            
            iconRotation: 90
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: units.gu(5)
            Layout.preferredHeight: units.gu(5)
            action: Action {
                    iconName: "go-last"
                    onTriggered: {
                        if (cursorSwipeArea.selectionMode) {
                            fullScreenItem.selectEndOfDocument();
                        } else {
                            fullScreenItem.moveToEndOfDocument();
                        }
                    }
                }
        }
        
        FloatingActionKey {
            id: endLineButton
            
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: units.gu(5)
            Layout.preferredHeight: units.gu(5)
            action: Action {
                    iconName: "go-last"
                    onTriggered: {
                        if (cursorSwipeArea.selectionMode) {
                            fullScreenItem.selectEndOfLine();
                        } else {
                            fullScreenItem.moveToEndOfLine();
                        }
                    }
                }
        }
    }
    
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        
        ColumnLayout {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.preferredHeight: parent.height * 0.8

            FloatingActionKey {
                id: moveLeftButton
                
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: units.gu(5)
                Layout.fillHeight: true
                visible: floatingActions.height >= units.gu(20)
                action: Action {
                        iconName: "previous"
                        onTriggered: {
                            if (cursorSwipeArea.selectionMode) {
                                fullScreenItem.selectLeft();
                            } else {
                                fullScreenItem.sendLeftKey();
                            }
                        }
                    }
            }

            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: units.gu(5)
                Layout.preferredHeight: keypad.keyHeight - units.gu(1) //backSpaceLeft.height - units.gu(1)
                BackspaceKey {
                    id: backSpaceLeft
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(-0.25)
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: units.gu(8)
                    //normalColor: fullScreenItem.theme.actionKeyPressedColor
                    //pressedColor: fullScreenItem.theme.actionKeyColor
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: units.gu(5)
                Layout.preferredHeight: keypad.keyHeight - units.gu(1) //returnKeyLeft.height - units.gu(1)
                ReturnKey {
                    id: returnKeyLeft
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(-0.25)
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: units.gu(8)
                    //normalColor: fullScreenItem.theme.actionKeyPressedColor
                    //pressedColor: fullScreenItem.theme.actionKeyColor
                }
            }
        }

        Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: cursorSwipeArea.selectionMode ? UbuntuColors.porcelain : fullScreenItem.theme.fontColor
            wrapMode: Text.WordWrap

            text: cursorSwipeArea.selectionMode ? i18n.tr("Swipe to move selection") + "\n\n" + i18n.tr("Double-tap to exit selection mode")
                        : i18n.tr("Swipe to move cursor") + "\n\n" + i18n.tr("Double-tap to enter selection mode")
                        + "\n" + i18n.tr("(Position mid word to select word)")
        }
        
        ColumnLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.preferredHeight: parent.height * 0.8
            FloatingActionKey {
                id: moveRightButton

                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: units.gu(5)
                Layout.fillHeight: true
                visible: floatingActions.height >= units.gu(20)
                action: Action {
                        iconName: "next"
                        onTriggered: {
                            if (cursorSwipeArea.selectionMode) {
                                fullScreenItem.selectRight();
                            } else {
                                fullScreenItem.sendRightKey();
                            }
                        }
                    }
            }

            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: units.gu(5)
                Layout.preferredHeight: keypad.keyHeight - units.gu(1) //backSpace.height - units.gu(1)
                BackspaceKey {
                    id: backSpace
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(-0.25)
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: units.gu(8)
                    //normalColor: fullScreenItem.theme.actionKeyPressedColor
                    //pressedColor: fullScreenItem.theme.actionKeyColor
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: units.gu(5)
                Layout.preferredHeight: keypad.keyHeight - units.gu(1) //units.gu(5)//returnKey.height - units.gu(1)
                ReturnKey {
                    id: returnKey
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(-0.25)
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: units.gu(8)
                    //normalColor: fullScreenItem.theme.actionKeyPressedColor
                    //pressedColor: fullScreenItem.theme.actionKeyColor
                }
            }
        }
    }
}
