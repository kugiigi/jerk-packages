/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *      Renato Araujo Oliveira Filho <renato@canonical.com>
 *      Olivier Tilloy <olivier.tilloy@canonical.com>
 */

import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Settings.Menus 0.1 as Menus
import QMenuModel 1.0 as QMenuModel
import Utils 0.1 as Utils

Loader {
    id: messageFactoryItem
    objectName: "messageItem"
    property var menuModel: null
    property QtObject menuData: null
    property int menuIndex: -1
    // ENH148 - Option to hide notification contents in lockscreen
    property bool hideBody: false
    readonly property string hiddenContentText: "<Unlock to view>"
    // ENH148 - End

    property bool selected: false
    signal menuSelected
    signal menuDeselected

    QtObject {
        id: priv
        property var extendedData: menuData && menuData.ext || undefined
        property var actionsDescription: getExtendedProperty(extendedData, "xAyatanaMessageActions", undefined)
        property date time: new Date(getExtendedProperty(extendedData, "xAyatanaTime", 0) / 1000)
        property string timeString: i18n.relativeDateTime(time)
    }
    LiveTimer {
        frequency: LiveTimer.Relative
        relativeTime: priv.time
        onTrigger: priv.timeString = Qt.binding(function() { return i18n.relativeDateTime(priv.time); })
    }

    onMenuModelChanged: {
        loadAttributes();
    }
    onMenuIndexChanged: {
        loadAttributes();
    }

    sourceComponent: loadMessage(priv.actionsDescription)

    function loadMessage(actions)
    {
        var parameterType = ""
        for (var actIndex in actions) {
            var desc = actions[actIndex];
            if (desc["parameter-type"] !== undefined) {
                parameterType += desc["parameter-type"];
            } else {
                parameterType += "_";
            }
        }

        if (parameterType === "") {
            return simpleMessage;
        } else if (parameterType === "s") {
            return textMessage;
        } else if (parameterType === "_s") {
            return snapDecision;
        } else {
            console.debug("Unknown paramater type: " + parameterType);
        }
        return undefined;
    }

    function loadAttributes() {
        if (!menuModel || menuIndex == -1) return;
        menuModel.loadExtendedAttributes(menuIndex, {'x-ayatana-time': 'int64',
                                                     'x-ayatana-text': 'string',
                                                     'x-ayatana-message-actions': 'variant',
                                                     'icon': 'icon',
                                                     'x-ayatana-app-icon': 'icon'});
    }

    function getExtendedProperty(object, propertyName, defaultValue) {
        if (object && object.hasOwnProperty(propertyName)) {
            return object[propertyName];
        }
        return defaultValue;
    }

    Component {
        id: simpleMessage

        Menus.SimpleMessageMenu {
            id: message
            objectName: "simpleTextMessage"
            // text
            title: menuData && menuData.label || ""
            time: priv.timeString
            // ENH148 - Option to hide notification contents in lockscreen
            // body: getExtendedProperty(priv.extendedData, "xAyatanaText", "")
            body: messageFactoryItem.hideBody ? messageFactoryItem.hiddenContentText
                    : getExtendedProperty(priv.extendedData, "xAyatanaText", "")
            // ENH148 - End
            // icons
            avatar: getExtendedProperty(priv.extendedData, "icon", "image://theme/contact")
            icon: getExtendedProperty(priv.extendedData, "xAyatanaAppIcon", "image://theme/message")
            // actions
            enabled: menuData && menuData.sensitive || false
            removable: !selected
            confirmRemoval: true
            selected: messageFactoryItem.selected

            onIconActivated: {
                menuModel.activate(menuIndex, true);
            }
            onDismissed: {
                menuModel.activate(menuIndex, false);
            }
            onTriggered: {
                menuModel.activate(menuIndex, true);
            }
        }
    }

    Component {
        id: textMessage

        Menus.TextMessageMenu {
            id: message
            objectName: "textMessage"
            property var replyActionDescription: priv.actionsDescription && priv.actionsDescription.length > 0 ?
                                                     priv.actionsDescription[0] :
                                                     undefined

            property var replyAction: QMenuModel.AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(replyActionDescription, "name", "")
            }

            // text
            title: menuData && menuData.label || ""
            time: priv.timeString
            // ENH148 - Option to hide notification contents in lockscreen
            // body: getExtendedProperty(priv.extendedData, "xAyatanaText", "")
            body: messageFactoryItem.hideBody ? messageFactoryItem.hiddenContentText
                    : getExtendedProperty(priv.extendedData, "xAyatanaText", "")
            // ENH148 - End
            replyButtonText: getExtendedProperty(replyActionDescription, "label", i18n.ctr("Button: Send a reply message", "Send"))
            replyHintText: i18n.ctr("Label: Hint in message indicator line edit", "Reply")
            // icons
            avatar: getExtendedProperty(priv.extendedData, "icon", "image://theme/contact")
            icon: getExtendedProperty(priv.extendedData, "xAyatanaAppIcon", "image://theme/message")
            // actions
            replyEnabled: replyAction.valid && replyAction.enabled
            // ENH148 - Option to hide notification contents in lockscreen
                            && !messageFactoryItem.hideBody
            // ENH148 - End
            enabled: menuData && menuData.sensitive || false
            removable: !selected
            confirmRemoval: true
            selected: messageFactoryItem.selected
            highlightWhenPressed: false

            onIconActivated: {
                menuModel.activate(menuIndex, true);
            }
            onDismissed: {
                menuModel.activate(menuIndex, false);
            }
            onReplied: {
                replyAction.activate(value);
            }
            onTriggered: {
                if (selected) {
                    menuDeselected();
                } else {
                    menuSelected();
                }
            }
        }
    }

    Component {
        id: snapDecision

        Menus.SnapDecisionMenu {
            id: message
            objectName: "snapDecision"
            property var activateActionDescription: priv.actionsDescription && priv.actionsDescription.length > 0 ?
                                                        priv.actionsDescription[0] : undefined
            property var replyActionDescription: priv.actionsDescription && priv.actionsDescription.length > 1 ?
                                                     priv.actionsDescription[1] : undefined

            property var activateAction: QMenuModel.AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(activateActionDescription, "name", "")
            }
            property var replyAction: QMenuModel.AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(replyActionDescription, "name", "")
            }

            // text
            title: menuData && menuData.label || ""
            time: priv.timeString
            body: getExtendedProperty(priv.extendedData, "xAyatanaText", "")
            actionButtonText: getExtendedProperty(activateActionDescription, "label", i18n.ctr("Button: Call back on phone", "Call back"))
            replyButtonText: getExtendedProperty(replyActionDescription, "label", i18n.ctr("Button: Send a reply message", "Send"))
            // icons
            avatar: getExtendedProperty(priv.extendedData, "icon", "image://theme/contact")
            icon: getExtendedProperty(priv.extendedData, "xAyatanaAppIcon", "image://theme/missed-call")
            // actions
            actionEnabled: activateAction.valid && activateAction.enabled
            replyEnabled: replyAction.valid && replyAction.enabled
            enabled: menuData && menuData.sensitive || false
            removable: !selected
            confirmRemoval: true
            selected: messageFactoryItem.selected
            highlightWhenPressed: false

            onIconActivated: {
                menuModel.activate(menuIndex, true);
            }
            onDismissed: {
                menuModel.activate(menuIndex, false);
            }
            onActionActivated: {
                activateAction.activate();
            }
            onReplied: {
                replyAction.activate(value);
            }
            onTriggered: {
                if (selected) {
                    menuDeselected();
                } else {
                    menuSelected();
                }
            }
        }
    }
}
