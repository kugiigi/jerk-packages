import QtQuick 2.9
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import "keys/"

// ENH215 - Shortcuts bar
// Rectangle{
MKActionsToolbar {
// ENH215 - End
    id: actionsToolbar

    // ENH215 - Shortcuts bar
    leadingActions: [		
        MKBaseAction { text: i18n.tr("Select All"); iconName: "edit-select-all"; onTrigger: fullScreenItem.selectAll(); },
        MKBaseAction { text: i18n.tr("Undo"); iconName: "undo"; onTrigger: fullScreenItem.undo();},
        MKBaseAction { text: i18n.tr("Redo"); iconName: "redo"; onTrigger: fullScreenItem.redo();}
    ]
    trailingActions: [
        MKBaseAction { text: i18n.tr("Paste"); iconName: "edit-paste"; onTrigger: fullScreenItem.paste(); },
        MKBaseAction { text: i18n.tr("Copy"); iconName: "edit-copy"; /*visible: input_method.hasSelection; */ onTrigger: {fullScreenItem.copy(); fullScreenItem.sendLeftKey();} },
        MKBaseAction { text: i18n.tr("Cut"); iconName: "edit-cut"; /*visible: input_method.hasSelection; */ onTrigger: fullScreenItem.cut(); }
    ]
	
    // color: fullScreenItem.theme.backgroundColor
    // ENH215 - End
    anchors {
        left: parent.left
        right: parent.right
    }

    states: [
        State {
            name: "wordribbon"
        
            AnchorChanges {
                target: actionsToolbar
                anchors.top: undefined
                anchors.bottom: keyboardComp.top
            }
        },
        State {
            name: "top"

            AnchorChanges {
                target: actionsToolbar
                anchors.top: parent.top
                anchors.bottom: undefined
            }
         }
    ]

    // ENH215 - Shortcuts bar
    /*
    // Disable clicking behind the toolbar
    MouseArea {
        anchors.fill: parent
        z: -1
    }
    RowLayout {
        anchors.fill: parent
        
        ActionBar {
            id: leadingActionBar
            
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.fillHeight: true

            numberOfSlots: 4
            delegate: ActionsToolbarButton { fullLayout: keyboardSurface.width > units.gu(80) }
            actions: [		
                Action { text: i18n.tr("Select All"); iconName: "edit-select-all"; onTriggered: fullScreenItem.selectAll(); },
                Action { text: i18n.tr("Redo"); iconName: "redo"; onTriggered: fullScreenItem.redo();},
                Action { text: i18n.tr("Undo"); iconName: "undo"; onTriggered: fullScreenItem.undo();}
            ]
        }
        
        ActionBar {
            id: trailingActionBar
            
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            delegate: ActionsToolbarButton { fullLayout: keyboardSurface.width > units.gu(80) }
            
            // TODO: Disabled dynamic visibility of copy and cut buttons until input_method.hasSelection is working properly in QtWebEngine
            // ubports/ubuntu-touch#1157 <https://github.com/ubports/ubuntu-touch/issues/1157>
            actions: [
                Action { text: i18n.tr("Paste"); iconName: "edit-paste"; onTriggered: fullScreenItem.paste(); },*/
    //            Action { text: i18n.tr("Copy"); iconName: "edit-copy"; /*visible: input_method.hasSelection; */ onTriggered: {fullScreenItem.copy(); fullScreenItem.sendLeftKey();} },
    //            Action { text: i18n.tr("Cut"); iconName: "edit-cut"; /*visible: input_method.hasSelection; */ onTriggered: fullScreenItem.cut(); }
    //        ]
    //    }
    //}
    
    // ENH215 - End
}
