/*
 * Copyright 2013-2016 Canonical Ltd.
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
 */

import QtQuick 2.12
import QtQuick.Window 2.2
import Lomiri.Settings.Menus 0.1 as Menus
import Lomiri.Settings.Components 0.1
import QMenuModel 1.0
import Utils 0.1 as Utils
import Lomiri.Components.ListItems 1.3 as ListItems
import Lomiri.Components 1.3
import Lomiri.Session 0.1
import Lomiri.Platform 1.0

Item {
    id: menuFactory

    property string indicator
    property var rootModel: null
    property var menuModel: null

    property var _userMap: null
    readonly property var _typeToComponent: {
        "default": {
            "lomiri.widgets.systemsettings.tablet.volumecontrol" : sliderMenu,
            "lomiri.widgets.systemsettings.tablet.switch"        : switchMenu,

            "com.canonical.indicator.button"         : buttonMenu,
            "com.canonical.indicator.div"            : separatorMenu,
            "com.canonical.indicator.section"        : sectionMenu,
            "com.canonical.indicator.progress"       : progressMenu,
            "com.canonical.indicator.slider"         : sliderMenu,
            "com.canonical.indicator.switch"         : switchMenu,
            "com.canonical.indicator.alarm"          : alarmMenu,
            "com.canonical.indicator.appointment"    : appointmentMenu,
            "com.canonical.indicator.transfer"       : transferMenu,
            "com.canonical.indicator.button-section" : buttonSectionMenu,
            "com.canonical.indicator.link"           : linkMenu,

            "com.canonical.indicator.messages.messageitem"  : messageItem,
            "com.canonical.indicator.messages.sourceitem"   : groupedMessage,

            "com.canonical.lomiri.slider"    : sliderMenu,
            "com.canonical.lomiri.switch"    : switchMenu,

            "com.canonical.lomiri.media-player"    : mediaPayerMenu,
            "com.canonical.lomiri.playback-item"   : playbackItemMenu,

            "lomiri.widgets.systemsettings.tablet.wifisection" : wifiSection,
            "lomiri.widgets.systemsettings.tablet.accesspoint" : accessPoint,
            "com.lomiri.indicator.network.modeminfoitem" : modeminfoitem,

            "com.canonical.indicator.calendar": calendarMenu,
            "com.canonical.indicator.location": timezoneMenu,

            "com.lomiri.indicator.transfer"       : transferMenu,

            "org.ayatana.indicator.button"         : buttonMenu,
            "org.ayatana.indicator.div"            : separatorMenu,
            "org.ayatana.indicator.section"        : sectionMenu,
            "org.ayatana.indicator.progress"       : progressMenu,
            "org.ayatana.indicator.slider"         : sliderMenu,
            "org.ayatana.indicator.switch"         : switchMenu,
            "org.ayatana.indicator.alarm"          : alarmMenu,
            "org.ayatana.indicator.appointment"    : appointmentMenu,
            "org.ayatana.indicator.transfer"       : transferMenu,
            "org.ayatana.indicator.button-section" : buttonSectionMenu,
            "org.ayatana.indicator.link"           : linkMenu,

            "org.ayatana.indicator.messages.messageitem"  : messageItem,
            "org.ayatana.indicator.messages.sourceitem"   : groupedMessage,

            "org.ayatana.indicator.slider"    : sliderMenu,
            "org.ayatana.indicator.switch"    : switchMenu,

            "org.ayatana.indicator.media-player"    : mediaPayerMenu,
            "org.ayatana.indicator.playback-item"   : playbackItemMenu,

            "org.ayatana.indicator.network.modeminfoitem" : modeminfoitem,

            "org.ayatana.indicator.calendar": calendarMenu,
            "org.ayatana.indicator.location": timezoneMenu,
            "org.ayatana.indicator.level"   : levelMenu,
        },
        "indicator-session": {
            "indicator.user-menu-item": Platform.isPC ? userMenuItem : null,
            "indicator.guest-menu-item": Platform.isPC ? userMenuItem : null,
            "com.canonical.indicator.switch": Math.min(Screen.width, Screen.height) > units.gu(60) ? switchMenu : null // Desktop mode switch
        },
        "indicator-messages": {
            "com.canonical.indicator.button": messagesButtonMenu
        },
        "ayatana-indicator-session": {
            "org.ayatana.indicator.user-menu-item": Platform.isPC ? userMenuItem : null,
            "org.ayatana.indicator.guest-menu-item": Platform.isPC ? userMenuItem : null,
            "org.ayatana.indicator.switch": Math.min(Screen.width, Screen.height) > units.gu(60) ? switchMenu : null // Desktop mode switch
        },
        "ayatana-indicator-messages": {
            "org.ayatana.indicator.button": messagesButtonMenu
        }
    }

    readonly property var _action_filter_map: {
        "indicator-session": {
            "indicator.logout": Platform.isPC ? undefined : null,
            "indicator.suspend": Platform.isPC ? undefined : null,
            "indicator.hibernate": Platform.isPC ? undefined : null,
            "indicator.reboot": Platform.isPC ? undefined : null
        },
        "indicator-keyboard": {
            "indicator.map": null,
            "indicator.chart": null
        },
        "ayatana-indicator-session": {
            "indicator.logout": Platform.isPC ? undefined : null,
            "indicator.suspend": Platform.isPC ? undefined : null,
            "indicator.hibernate": Platform.isPC ? undefined : null,
            "indicator.reboot": Platform.isPC ? undefined : null
        },
        "ayatana-indicator-keyboard": {
            "indicator.map": null,
            "indicator.chart": null
        }
    }

    function getComponentForIndicatorEntryType(type) {
        var component = undefined;
        var map = _userMap || _typeToComponent
        var indicatorComponents = map[indicator];

        if (type === undefined || type === "") {
            return component
        }

        if (indicatorComponents !== undefined) {
            component = indicatorComponents[type];
        }

        if (component === undefined) {
            component = map["default"][type];
        }

        if (component === undefined) {
            console.debug("Don't know how to make " + type + " for " + indicator);
        }

        return component
    }

    function getComponentForIndicatorEntryAction(action) {
        var component = undefined;
        var indicatorFilter = _action_filter_map[indicator]

        if (action === undefined || action === "") {
            return component
        }

        if (indicatorFilter !== undefined) {
            component = indicatorFilter[action];
        }
        return component
    }

    function getExtendedProperty(object, propertyName, defaultValue) {
        if (object && object.hasOwnProperty(propertyName)) {
            return object[propertyName];
        }
        return defaultValue;
    }

    Component {
        id: separatorMenu;

        Menus.SeparatorMenu {
            objectName: "separatorMenu"
        }
    }

    Component {
        id: sliderMenu;

        Menus.SliderMenu {
            id: sliderItem
            objectName: "sliderMenu"
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1
            property var extendedData: menuData && menuData.ext || undefined
            property var serverValue: getExtendedProperty(menuData, "actionState", undefined)

            text: menuData && menuData.label || ""
            minIcon: getExtendedProperty(extendedData, "minIcon", "")
            maxIcon: getExtendedProperty(extendedData, "maxIcon", "")

            minimumValue: getExtendedProperty(extendedData, "minValue", 0.0)
            maximumValue: {
                var maximum = getExtendedProperty(extendedData, "maxValue", 1.0);
                if (maximum <= minimumValue) {
                    return minimumValue + 1;
                }
                return maximum;
            }
            enabled: menuData && menuData.sensitive || false
            highlightWhenPressed: false

            onMenuModelChanged: {
                loadAttributes();
            }
            onMenuIndexChanged: {
                loadAttributes();
            }

            function loadAttributes() {
                if (!menuModel || menuIndex == -1) return;
                menuModel.loadExtendedAttributes(menuIndex, {'min-value': 'double',
                                                             'max-value': 'double',
                                                             'min-icon': 'icon',
                                                             'max-icon': 'icon',
                                                             'x-ayatana-sync-action': 'string'});
            }

            ServerPropertySynchroniser {
                id: sliderPropertySync
                objectName: "sync"
                syncTimeout: Utils.Constants.indicatorValueTimeout
                bufferedSyncTimeout: true
                maximumWaitBufferInterval: 16

                serverTarget: sliderItem
                serverProperty: "serverValue"
                userTarget: sliderItem
                userProperty: "value"

                onSyncTriggered: menuModel.changeState(menuIndex, value)
            }

            AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(extendedData, "xAyatanaSyncAction", "")
                onStateChanged: {
                    sliderPropertySync.reset();
                    sliderPropertySync.updateUserValue();
                }
            }
        }
    }

    Component {
        id: buttonMenu;

        Menus.ButtonMenu {
            objectName: "buttonMenu"
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1

            buttonText: menuData && menuData.label || ""
            enabled: menuData && menuData.sensitive || false
            highlightWhenPressed: false

            onTriggered: {
                menuModel.activate(menuIndex);
            }
        }
    }

    Component {
        id: messagesButtonMenu;

        Menus.BaseLayoutMenu {
            objectName: "messagesButtonMenu"
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1

            highlightWhenPressed: false
            enabled: menuData && menuData.sensitive || false
            text: menuData && menuData.label || ""
            title.color: theme.palette.selected.backgroundText
            title.horizontalAlignment: Text.AlignHCenter
            title.font.bold: true

            onClicked: menuModel.activate(menuIndex);
        }
    }

    Component {
        id: sectionMenu;

        Menus.SectionMenu {
            objectName: "sectionMenu"
            property QtObject menuData: null
            property var menuIndex: undefined

            text: menuData && menuData.label || ""
            busy: false
        }
    }

    Component {
        id: progressMenu;

        Menus.ProgressValueMenu {
            objectName: "progressMenu"
            property QtObject menuData: null
            property int menuIndex: -1

            text: menuData && menuData.label || ""
            iconSource: menuData && menuData.icon || ""
            value : menuData && menuData.actionState || 0.0
            enabled: menuData && menuData.sensitive || false
        }
    }

    Component {
        id: levelMenu;

        /* Use the same UI as progressMenu for now. */
        Menus.ProgressValueMenu {
            objectName: "levelMenu"
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1
            property var extendedData: menuData && menuData.ext || undefined

            text: menuData && menuData.label || ""
            iconSource: menuData && menuData.icon || ""
            value : extendedData && extendedData.xAyatanaLevel || 0.0
            enabled: menuData && menuData.sensitive || false

            onMenuModelChanged: {
                loadAttributes();
            }
            onMenuIndexChanged: {
                loadAttributes();
            }

            function loadAttributes() {
                if (!menuModel || menuIndex == -1) return;
                menuModel.loadExtendedAttributes(menuIndex, {'x-ayatana-level': 'uint16'});
            }
        }
    }

    Component {
        id: standardMenu;

        Menus.StandardMenu {
            objectName: "standardMenu"
            property QtObject menuData: null
            property int menuIndex: -1

            text: menuData && menuData.label || ""
            iconSource: menuData && menuData.icon || ""
            enabled: menuData && menuData.sensitive || false
            highlightWhenPressed: false

            onTriggered: {
                menuModel.activate(menuIndex);
            }
        }
    }

    Component {
        id: linkMenu;

        Menus.BaseLayoutMenu {
            objectName: "linkMenu"
            property QtObject menuData: null
            property int menuIndex: -1

            text: menuData && menuData.label || ""
            enabled: menuData && menuData.sensitive || false
            backColor: Qt.rgba(1,1,1,0.07)
            highlightWhenPressed: false

            onTriggered: {
                menuModel.activate(menuIndex);
            }

            slots: Icon {
                source: {
                    if (menuData) {
                        if (menuData.icon && menuData.icon != "") {
                            return menuData.icon
                        } else if (menuData.action.indexOf("settings") > -1) {
                            return "image://theme/settings"
                        }
                    }
                    return ""
                }
                height: units.gu(3)
                width: height
                color: theme.palette.normal.backgroundText
                SlotsLayout.position: SlotsLayout.Trailing
            }
        }
    }

    Component {
        id: checkableMenu;

        Menus.CheckableMenu {
            id: checkItem
            objectName: "checkableMenu"
            property QtObject menuData: null
            property int menuIndex: -1
            property bool serverChecked: menuData && menuData.isToggled || false

            text: menuData && menuData.label || ""
            enabled: menuData && menuData.sensitive || false
            checked: serverChecked
            highlightWhenPressed: false

            ServerPropertySynchroniser {
                objectName: "sync"
                syncTimeout: Utils.Constants.indicatorValueTimeout

                serverTarget: checkItem
                serverProperty: "serverChecked"
                userTarget: checkItem
                userProperty: "checked"

                onSyncTriggered: menuModel.activate(checkItem.menuIndex)
            }
        }
    }

    Component {
        id: radioMenu;

        Menus.RadioMenu {
            id: radioItem
            objectName: "radioMenu"
            property QtObject menuData: null
            property int menuIndex: -1
            property bool serverChecked: menuData && menuData.isToggled || false

            text: menuData && menuData.label || ""
            enabled: menuData && menuData.sensitive || false
            checked: serverChecked
            highlightWhenPressed: false

            ServerPropertySynchroniser {
                objectName: "sync"
                syncTimeout: Utils.Constants.indicatorValueTimeout

                serverTarget: radioItem
                serverProperty: "serverChecked"
                userTarget: radioItem
                userProperty: "checked"

                onSyncTriggered: menuModel.activate(radioItem.menuIndex)
            }
        }
    }

    Component {
        id: switchMenu;

        Menus.SwitchMenu {
            id: switchItem
            objectName: "switchMenu"
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1
            property var extendedData: menuData && menuData.ext || undefined
            property bool serverChecked: menuData && menuData.isToggled || false

            text: menuData && menuData.label || ""
            iconSource: menuData && menuData.icon || ""
            enabled: menuData && menuData.sensitive || false
            checked: serverChecked
            highlightWhenPressed: false

            property var subtitleAction: AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(extendedData, "xAyatanaSubtitleAction", "")
            }
            subtitle.text: subtitleAction.valid ? subtitleAction.state : ""

            onMenuModelChanged: {
                loadAttributes();
            }
            onMenuIndexChanged: {
                loadAttributes();
            }

            function loadAttributes() {
                if (!menuModel || menuIndex == -1) return;
                menuModel.loadExtendedAttributes(menuIndex, {
                    'x-ayatana-subtitle-action': 'string',
                    'target': 'bool',
                });
            }

            ServerPropertySynchroniser {
                objectName: "sync"
                syncTimeout: Utils.Constants.indicatorValueTimeout

                serverTarget: switchItem
                serverProperty: "serverChecked"
                userTarget: switchItem
                userProperty: "checked"

                onSyncTriggered: {
                    /* Figures out if the action's activate() requires a
                     * parameter or not. Works with:
                     * - com.canonical.indicator.switch
                     * - org.ayatana.indicator.switch (with fix)
                     * - com.canonical.indicator.switch mis-labled as
                     *   org.ayatana.indicator.switch
                     *   https://gitlab.com/ubports/development/core/lomiri-indicator-network/-/issues/87#note_1206883970
                     *
                     * If activate() requires a parameter but menu doesn't
                     * specify a target, the menu will be broken in a different
                     * way anyway.
                     */
                    if (extendedData.hasOwnProperty('target')) {
                        menuModel.activate(switchItem.menuIndex, switchItem.checked);
                    } else {
                        menuModel.activate(switchItem.menuIndex);
                    }
                }
            }
        }
    }

    Component {
        id: alarmMenu;

        Menus.EventMenu {
            id: alarmItem
            objectName: "alarmMenu"
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1
            property var extendedData: menuData && menuData.ext || undefined

            readonly property date serverTime: new Date(getExtendedProperty(extendedData, "xAyatanaTime", 0) * 1000)
            LiveTimer {
                frequency: LiveTimer.Relative
                relativeTime: alarmItem.serverTime
                onTrigger: alarmItem.time = i18n.relativeDateTime(alarmItem.serverTime)
            }

            text: menuData && menuData.label || ""
            iconSource: menuData && menuData.icon || "image://theme/alarm-clock"
            time: i18n.relativeDateTime(serverTime)
            enabled: menuData && menuData.sensitive || false
            highlightWhenPressed: false

            onMenuModelChanged: {
                loadAttributes();
            }
            onMenuIndexChanged: {
                loadAttributes();
            }
            onTriggered: {
                menuModel.activate(menuIndex);
            }

            function loadAttributes() {
                if (!menuModel || menuIndex == -1) return;
                menuModel.loadExtendedAttributes(menuIndex, {'x-ayatana-time': 'int64'});
            }
        }
    }

    Component {
        id: appointmentMenu;

        Menus.EventMenu {
            id: appointmentItem
            objectName: "appointmentMenu"
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1
            property var extendedData: menuData && menuData.ext || undefined

            readonly property date serverTime: new Date(getExtendedProperty(extendedData, "xAyatanaTime", 0) * 1000)

            LiveTimer {
                frequency: LiveTimer.Relative
                relativeTime: appointmentItem.serverTime
                onTrigger: appointmentItem.time = i18n.relativeDateTime(appointmentItem.serverTime)
            }

            text: menuData && menuData.label || ""
            iconSource: menuData && menuData.icon || "image://theme/calendar"
            time: i18n.relativeDateTime(serverTime)
            eventColor: getExtendedProperty(extendedData, "xAyatanaColor", Qt.rgba(0.0, 0.0, 0.0, 0.0))
            enabled: menuData && menuData.sensitive || false
            highlightWhenPressed: false

            onMenuModelChanged: {
                loadAttributes();
            }
            onMenuIndexChanged: {
                loadAttributes();
            }
            onTriggered: {
                menuModel.activate(menuIndex);
            }

            function loadAttributes() {
                if (!menuModel || menuIndex == -1) return;
                menuModel.loadExtendedAttributes(menuIndex, {'x-ayatana-color': 'string',
                                                             'x-ayatana-time': 'int64'});
            }
        }
    }

    Component {
        id: userMenuItem

        Menus.UserSessionMenu {
            objectName: "userSessionMenu"
            highlightWhenPressed: false

            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1

            name: menuData && menuData.label || "" // label is the user's real name
            iconSource: menuData && menuData.icon || ""

            // would be better to compare with the logname but sadly the indicator doesn't expose that
            active: DBusLomiriSessionService.RealName() !== "" ? DBusLomiriSessionService.RealName() == name
                                                              : DBusLomiriSessionService.UserName() == name

            onTriggered: {
                menuModel.activate(menuIndex);
            }
        }
    }

    Component {
        id: calendarMenu

        Menus.CalendarMenu {
            id: calendarItem
            objectName: "calendarMenu"
            focus: true

            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property var actionState: menuData && menuData.actionState || null
            property real calendarDay: getExtendedProperty(actionState, "calendar-day", 0)
            property int menuIndex: -1

            showWeekNumbers: getExtendedProperty(actionState, "show-week-numbers", false)
            eventDays: getExtendedProperty(actionState, "appointment-days", [])

            onCalendarDayChanged: {
                if (calendarDay > 0) {
                    // This would trigger a selectionDateChanged signal, thus
                    // we've to avoid that the subsequent model activation
                    // would cause an infinite loop
                    modelUpdateConnections.enabled = false
                    currentDate = new Date(calendarDay * 1000)
                    modelUpdateConnections.enabled = true
                }
            }

            Connections {
                id: modelUpdateConnections
                property bool enabled: true
                target: (enabled && calendarItem.visible) ? calendarItem : null

                onSelectedDateChanged: {
                    menuModel.activate(menuIndex, selectedDate.getTime() / 1000 | 0)
                }
            }
        }
    }

    Component {
        id: timezoneMenu

        Menus.TimeZoneMenu {
            id: tzMenuItem
            objectName: "timezoneMenu"

            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1
            property var extendedData: menuData && menuData.ext || undefined
            readonly property string tz: getExtendedProperty(extendedData, "xAyatanaTimezone", "UTC")
            property var updateTimer: Timer {
                repeat: true
                running: tzMenuItem.visible // only run when we're open
                onTriggered: tzMenuItem.time = Utils.TimezoneFormatter.currentTimeInTimezone(tzMenuItem.tz)
            }

            city: menuData && menuData.label || ""
            time: Utils.TimezoneFormatter.currentTimeInTimezone(tz)
            enabled: menuData && menuData.sensitive || false

            onMenuModelChanged: {
                loadAttributes();
            }
            onMenuIndexChanged: {
                loadAttributes();
            }
            onTriggered: {
                tzActionGroup.setLocation.activate(tz);
            }

            QDBusActionGroup {
                id: tzActionGroup
                busType: DBus.SessionBus
                busName: "org.ayatana.indicator.datetime"
                objectPath: "/org/ayatana/indicator/datetime"

                property variant setLocation: action("set-location")

                Component.onCompleted: tzActionGroup.start()
            }

            function loadAttributes() {
                if (!menuModel || menuIndex == -1) return;
                menuModel.loadExtendedAttributes(menuIndex, {'x-ayatana-timezone': 'string'});
            }
        }
    }

    Component {
        id: wifiSection;

        Menus.SectionMenu {
            objectName: "wifiSection"
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1
            property var extendedData: menuData && menuData.ext || undefined

            text: menuData && menuData.label || ""
            busy: getExtendedProperty(extendedData, "xCanonicalBusyAction", false)

            onMenuModelChanged: {
                loadAttributes();
            }
            onMenuIndexChanged: {
                loadAttributes();
            }

            function loadAttributes() {
                if (!menuModel || menuIndex == -1) return;
                menuModel.loadExtendedAttributes(menuIndex, {'x-canonical-busy-action': 'bool'})
            }
        }
    }

    Component {
        id: accessPoint;

        Menus.AccessPointMenu {
            id: apItem
            objectName: "accessPoint"
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1
            property var extendedData: menuData && menuData.ext || undefined
            property bool serverChecked: menuData && menuData.isToggled || false

            property var strengthAction: AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(extendedData, "xAyatanaWifiApStrengthAction", "")
            }

            text: menuData && menuData.label || ""
            enabled: menuData && menuData.sensitive || false
            active: serverChecked
            secure: getExtendedProperty(extendedData, "xAyatanaWifiApIsSecure", false)
            adHoc: getExtendedProperty(extendedData, "xAyatanaWifiApIsAdhoc", false)
            signalStrength: {
                if (strengthAction.valid) {
                    var state = strengthAction.state; // handle both int and uchar
                    // FIXME remove the special casing when we switch to indicator-network completely
                    if (typeof state == "string") {
                        return state.charCodeAt();
                    }
                    return state;
                }
                return 0;
            }
            highlightWhenPressed: false

            onMenuModelChanged: {
                loadAttributes();
            }
            onMenuIndexChanged: {
                loadAttributes();
            }

            function loadAttributes() {
                if (!menuModel || menuIndex == -1) return;
                menuModel.loadExtendedAttributes(menuIndex, {'x-ayatana-wifi-ap-is-adhoc': 'bool',
                                                             'x-ayatana-wifi-ap-is-secure': 'bool',
                                                             'x-ayatana-wifi-ap-strength-action': 'string'});
            }

            ServerPropertySynchroniser {
                objectName: "sync"
                syncTimeout: Utils.Constants.indicatorValueTimeout

                serverTarget: apItem
                serverProperty: "serverChecked"
                userTarget: apItem
                userProperty: "active"
                userTrigger: "onTriggered"

                onSyncTriggered: menuModel.activate(apItem.menuIndex)
            }
        }
    }

    Component {
        id: modeminfoitem;
        Menus.ModemInfoItem {
            objectName: "modemInfoItem"
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1
            property var extendedData: menuData && menuData.ext || undefined
            highlightWhenPressed: false

            property var statusLabelAction: AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(extendedData, "xLomiriModemStatusLabelAction", "")
            }
            statusText: statusLabelAction.valid ? statusLabelAction.state : ""

            property var statusIconAction: AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(extendedData, "xLomiriModemStatusIconAction", "")
            }
            statusIcon: statusIconAction.valid ? statusIconAction.state : ""

            property var connectivityIconAction: AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(extendedData, "xLomiriModemConnectivityIconAction", "")
            }
            connectivityIcon: connectivityIconAction.valid ? connectivityIconAction.state : ""

            property var simIdentifierLabelAction: AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(extendedData, "xLomiriModemSimIdentifierLabelAction", "")
            }
            simIdentifierText: simIdentifierLabelAction.valid ? simIdentifierLabelAction.state : ""

            property var roamingAction: AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(extendedData, "xLomiriModemRoamingAction", "")
            }
            roaming: roamingAction.valid ? roamingAction.state : false

            property var unlockAction: AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(extendedData, "xLomiriModemLockedAction", "")
            }
            onUnlock: {
                unlockAction.activate();
            }
            locked: unlockAction.valid ? unlockAction.state : false

            property var imsIconAction: AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(extendedData, "xLomiriModemImsIconAction", "")
            }
            imsIcon: imsIconAction.valid ? imsIconAction.state : ""

            onMenuModelChanged: {
                loadAttributes();
            }
            onMenuIndexChanged: {
                loadAttributes();
            }

            function loadAttributes() {
                if (!menuModel || menuIndex == -1) return;
                menuModel.loadExtendedAttributes(menuIndex, {'x-lomiri-modem-status-label-action': 'string',
                                                             'x-lomiri-modem-status-icon-action': 'string',
                                                             'x-lomiri-modem-connectivity-icon-action': 'string',
                                                             'x-lomiri-modem-sim-identifier-label-action': 'string',
                                                             'x-lomiri-modem-roaming-action': 'string',
                                                             'x-lomiri-modem-locked-action': 'string',
                                                             'x-lomiri-modem-ims-icon-action': 'string'});
            }
        }
    }

    Component {
        id: messageItem

        MessageMenuItemFactory {
            objectName: "messageItem"
            menuModel: menuFactory.menuModel
        }
    }

    Component {
        id: groupedMessage

        Menus.GroupedMessageMenu {
            objectName: "groupedMessage"
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1
            property var extendedData: menuData && menuData.ext || undefined

            text: menuData && menuData.label || ""
            iconSource: getExtendedProperty(extendedData, "icon", "image://theme/message")
            count: menuData && menuData.actionState.length > 0 ? menuData.actionState[0] : "0"
            enabled: menuData && menuData.sensitive || false
            highlightWhenPressed: false
            removable: true

            onMenuModelChanged: {
                loadAttributes();
            }
            onMenuIndexChanged: {
                loadAttributes();
            }
            onClicked: {
                menuModel.activate(menuIndex, true);
            }
            onDismissed: {
                menuModel.activate(menuIndex, false);
            }

            function loadAttributes() {
                if (!menuModel || menuIndex == -1) return;
                menuModel.loadExtendedAttributes(modelIndex, {'icon': 'icon'});
            }
        }
    }

    Component {
        id: mediaPayerMenu;

        Menus.MediaPlayerMenu {
            objectName: "mediaPayerMenu"
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1
            property var actionState: menuData && menuData.actionState || undefined
            property bool running: getExtendedProperty(actionState, "running", false)

            playerIcon: menuData && menuData.icon || "image://theme/stock_music"
            playerName: menuData && menuData.label || i18n.tr("Nothing is playing")

            albumArt: getExtendedProperty(actionState, "art-url", "image://theme/stock_music")
            song: getExtendedProperty(actionState, "title", "")
            artist: getExtendedProperty(actionState, "artist", "")
            album: getExtendedProperty(actionState, "album", "")
            showTrack: running && (state == "Playing" || state == "Paused")
            state: getExtendedProperty(actionState, "state", "")
            enabled: menuData && menuData.sensitive || false
            highlightWhenPressed: false

            onTriggered: {
                model.activate(modelIndex);
            }
        }
    }

    Component {
        id: playbackItemMenu;

        Menus.PlaybackItemMenu {
            objectName: "playbackItemMenu"
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1
            property var extendedData: menuData && menuData.ext || undefined

            property var playAction: AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(extendedData, "xAyatanaPlayAction", "")
            }
            property var nextAction: AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(extendedData, "xAyatanaNextAction", "")
            }
            property var previousAction: AyatanaMenuAction {
                model: menuModel
                index: menuIndex
                name: getExtendedProperty(extendedData, "xAyatanaPreviousAction", "")
            }

            playing: playAction.state === "Playing"
            canPlay: playAction.valid
            canGoNext: nextAction.valid
            canGoPrevious: previousAction.valid
            enabled: menuData && menuData.sensitive || false
            highlightWhenPressed: false

            onPlay: {
                playAction.activate();
            }
            onNext: {
                nextAction.activate();
            }
            onPrevious: {
                previousAction.activate();
            }
            onMenuModelChanged: {
                loadAttributes();
            }
            onMenuIndexChanged: {
                loadAttributes();
            }

            function loadAttributes() {
                if (!menuModel || menuIndex == -1) return;
                menuModel.loadExtendedAttributes(modelIndex, {'x-ayatana-play-action': 'string',
                                                              'x-ayatana-next-action': 'string',
                                                              'x-ayatana-previous-action': 'string'});
            }
        }
    }

    Component {
        id: transferMenu

        Menus.TransferMenu {
            objectName: "transferMenu"
            id: transfer
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1
            property var extendedData: menuData && menuData.ext || undefined
            property var uid: getExtendedProperty(extendedData, "xAyatanaUid", undefined)

            text: menuData && menuData.label || ""
            iconSource: menuData && menuData.icon || "image://theme/transfer-none"
            maximum: 1.0
            enabled: menuData && menuData.sensitive || false
            highlightWhenPressed: false
            removable: true
            confirmRemoval: true

            QDBusActionGroup {
                id: actionGroup
                busType: 1
                busName: menuFactory.rootModel.busName
                objectPath: menuFactory.rootModel.actions["indicator"]

                property var activateAction: action("activate-transfer")
                property var cancelAction: action("cancel-transfer")
                property var transferStateAction: uid !== undefined ? action("transfer-state."+uid) : null

                Component.onCompleted: actionGroup.start()
            }

            property var transferState: {
                if (actionGroup.transferStateAction === null) return undefined;
                return actionGroup.transferStateAction.valid ? actionGroup.transferStateAction.state : undefined
            }

            property var runningState : transferState !== undefined ? transferState["state"] : undefined
            property var secondsLeft : transferState !== undefined ? transferState["seconds-left"] : undefined

            active: runningState !== undefined && runningState !== Menus.TransferState.Finished
            progress: transferState !== undefined ? transferState["percent"] : 0.0

            // TODO - Should be in the SDK
            property var timeRemaining: {
                if (secondsLeft === undefined) return undefined;

                var remaining = "";
                var hours = Math.floor(secondsLeft / (60 * 60));
                var minutes = Math.floor(secondsLeft / 60) % 60;
                var seconds = secondsLeft % 60;
                if (hours > 0) {
                    remaining += i18n.tr("%1 hour", "%1 hours", hours).arg(hours)
                }
                if (minutes > 0) {
                    if (remaining != "") remaining += ", ";
                    remaining += i18n.tr("%1 minute", "%1 minutes", minutes).arg(minutes)
                }
                // don't include seconds if hours > 0
                if (hours == 0 && minutes < 5 && seconds > 0) {
                    if (remaining != "") remaining += ", ";
                    remaining += i18n.tr("%1 second", "%1 seconds", seconds).arg(seconds)
                }
                if (remaining == "")
                    remaining = i18n.tr("0 seconds");
                // Translators: String like "1 hour, 2 minutes, 3 seconds remaining"
                return i18n.tr("%1 remaining").arg(remaining);
            }

            stateText: {
                switch (runningState) {
                    case Menus.TransferState.Queued:
                        return i18n.tr("In queue…");
                    case Menus.TransferState.Hashing:
                    case Menus.TransferState.Processing:
                    case Menus.TransferState.Running:
                        return timeRemaining === undefined ? i18n.tr("Downloading") : timeRemaining;
                    case Menus.TransferState.Paused:
                        return i18n.tr("Paused, tap to resume");
                    case Menus.TransferState.Canceled:
                        return i18n.tr("Canceled");
                    case Menus.TransferState.Finished:
                        return i18n.tr("Finished");
                    case Menus.TransferState.Error:
                        return i18n.tr("Failed, tap to retry");
                }
                return "";
            }

            onMenuModelChanged: {
                loadAttributes();
            }
            onMenuIndexChanged: {
                loadAttributes();
            }
            onTriggered: {
                actionGroup.activateAction.activate(uid);
            }
            onItemRemoved: {
                actionGroup.cancelAction.activate(uid);
            }

            function loadAttributes() {
                if (!menuModel || menuIndex == -1) return;
                menuModel.loadExtendedAttributes(menuIndex, {'x-ayatana-uid': 'string'});
            }
        }
    }

    Component {
        id: buttonSectionMenu;

        Menus.ButtonMenu {
            objectName: "buttonSectionMenu"
            property QtObject menuData: null
            property var menuModel: menuFactory.menuModel
            property int menuIndex: -1
            property var extendedData: menuData && menuData.ext || undefined

            iconSource: menuData && menuData.icon || ""
            enabled: menuData && menuData.sensitive || false
            highlightWhenPressed: false
            text: menuData && menuData.label || ""
            foregroundColor: theme.palette.normal.backgroundText
            buttonText: getExtendedProperty(extendedData, "xAyatanaExtraLabel", "")

            onMenuModelChanged: {
                loadAttributes();
            }
            onMenuIndexChanged: {
                loadAttributes();
            }
            function loadAttributes() {
                if (!menuModel || menuIndex == -1) return;
                menuModel.loadExtendedAttributes(menuIndex, {'x-ayatana-extra-label': 'string'});
            }

            onButtonClicked: menuModel.activate(menuIndex);
        }
    }

    function load(modelData) {
        var component = getComponentForIndicatorEntryAction(modelData.action)
        if (component !== undefined) {
            return component
        }

        component = getComponentForIndicatorEntryType(modelData.type)
        if (component !== undefined) {
            return component;
        }

        if (modelData.isCheck) {
            return checkableMenu;
        }
        if (modelData.isRadio) {
            return radioMenu;
        }
        if (modelData.isSeparator) {
            return separatorMenu;
        }
        if (modelData.action !== undefined && modelData.action.indexOf("settings") > -1) {
            // FIXME : At the moment, the indicators aren't using
            // org.ayatana.indicators.link for settings menu. Need to fudge it.
            return linkMenu;
        }
        return standardMenu;
    }
}
