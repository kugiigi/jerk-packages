// ENH139 - System Direct Actions
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12

Item {
    id: itemDelegate

    readonly property real maximumSize: units.gu(6)
    readonly property bool toggleOn: toggleObj && toggleObj.checked ? true : false
    readonly property var toggleObj: { // Only for Quick Toggles
        if (type == LPDirectActions.Type.Toggle && foundData) {
            return foundData.toggleObj
        }

        return null
    }
    readonly property var foundData: {
        let _found

        switch(type) {
            case LPDirectActions.Type.Indicator:
                _found = shell.indicatorsModel.find((element) => element.identifier == itemId);
                break
            case LPDirectActions.Type.App:
                _found = !shell.appModel.refreshing ? shell.getAppData(itemId) : null;
                break
            case LPDirectActions.Type.Settings:
                _found = shell.settingsPages.find((element) => element.identifier == itemId);
                break
            case LPDirectActions.Type.Toggle:
                _found = shell.quickToggleItems.find((element) => element.identifier == itemId);
                break
            case LPDirectActions.Type.Custom:
                _found = shell.customDirectActions.find((element) => element.name == itemId);
                break

            return _found
        }
    }
    readonly property bool isSettings: type == LPDirectActions.Type.Settings
    readonly property bool isIndicator: type == LPDirectActions.Type.Indicator
    readonly property bool isApp: type == LPDirectActions.Type.App
    readonly property bool isToggle: type == LPDirectActions.Type.Toggle
    readonly property bool isCustom: type == LPDirectActions.Type.Custom

    property string itemId
    property bool highlighted: false
    property int type: LPDirectActions.Type.Indicator
    property real highlightScale: 1.3

    property string itemTitle: {
        if (foundData) {
            switch(type) {
                case LPDirectActions.Type.Indicator:
                    return foundData.name
                case LPDirectActions.Type.App:
                    return foundData.name
                case LPDirectActions.Type.Settings:
                    return foundData.name
                case LPDirectActions.Type.Toggle:
                    return foundData.text
                case LPDirectActions.Type.Custom:
                    return foundData.text
            }
        }

        return "Unknown"
    }

    property string itemIcon: {
        if (foundData) {
            switch(type) {
                case LPDirectActions.Type.Indicator:
                    return foundData.icon
                case LPDirectActions.Type.App:
                    return foundData.icon
                case LPDirectActions.Type.Settings:
                    return foundData.iconName
                case LPDirectActions.Type.Toggle:
                    return toggleOn ? foundData.iconOn : foundData.iconOff
                case LPDirectActions.Type.Custom:
                    return foundData.iconName
            }
        }

        return "dialog-question-symbolic"
    }

    enabled: {
        if (foundData) {
            switch(type) {
                case LPDirectActions.Type.Indicator:
                    return true
                case LPDirectActions.Type.App:
                    return true
                case LPDirectActions.Type.Settings:
                    return true
                case LPDirectActions.Type.Toggle:
                    return toggleObj && toggleObj.enabled ? true : false
                case LPDirectActions.Type.Custom:
                    return foundData.enabled
            }
        }

        return false
    }
    opacity: enabled ? 1 : 0.5
    z: highlighted ? 2 : 1
    scale: highlighted ? highlightScale : 1
    Behavior on scale { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }

    function trigger() {
        if (foundData) {
            switch(type) {
                case LPDirectActions.Type.Indicator:
                    shell.openIndicatorByIndex(foundData.indicatorIndex)
                    break
                case LPDirectActions.Type.App:
                    shell.startApp(itemId)
                    break
                case LPDirectActions.Type.Settings:
                    Qt.openUrlExternally("settings:///system/%1".arg(foundData.url))
                    break
                case LPDirectActions.Type.Toggle:
                    if (toggleObj) {
                        toggleObj.clicked()
                    }
                    break
                case LPDirectActions.Type.Custom:
                    return foundData.trigger()
                    break
            }
        }

        console.log("Unknown Direct Action triggered")
    }

    onHighlightedChanged: {
        if (highlighted) {
            delayHaptics.restart()
        } else {
            delayHaptics.stop()
        }
    }

    Timer {
        id: delayHaptics

        running: false
        interval: 100
        onTriggered: {
            if (itemDelegate.highlighted) {
                shell.haptics.playSubtle()
            }
        }
    }
    
    Loader {
        active: itemDelegate.isApp
        asynchronous: true

        anchors.centerIn: parent
        width: Math.min(parent.width, itemDelegate.maximumSize)
        height: 7.5 / 8 * width

        sourceComponent: LomiriShape {
            id: appIcon
            radius: "medium"
            borderSource: 'undefined'
            source: Image {
                id: sourceImage
                source: itemDelegate.itemIcon
                asynchronous: true
                sourceSize.width: appIcon.width
            }
            sourceFillMode: LomiriShape.PreserveAspectCrop

            StyledItem {
                styleName: "FocusShape"
                anchors.fill: parent
                StyleHints {
                    visible: itemDelegate.highlighted
                    radius: units.gu(2.55)
                }
            }
        }
    }

    Rectangle {
        id: bgRec

        visible: !itemDelegate.isApp
        color: {
            if (itemDelegate.toggleOn) {
                return theme.palette.normal.selection
            }

            return itemDelegate.highlighted ? theme.palette.highlighted.foreground : theme.palette.normal.foreground
        }
        radius: itemDelegate.isToggle ? width * 0.2 : width / 2
        width: Math.min(parent.width, itemDelegate.maximumSize)
        height: width
        anchors.centerIn: parent
        Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
    }

    Icon {
        id: mainIcon

        anchors {
            centerIn: bgRec
            verticalCenterOffset: itemDelegate.isIndicator ? bgRec.height * 0.15 : 0
        }

        height: {
            if (itemDelegate.isSettings) {
                return bgRec.height * 0.9
            }
            if (itemDelegate.isIndicator) {
                return bgRec.height * 0.3
            }

            return bgRec.height * 0.5
        }
        width: height
        name: {
            if (!itemDelegate.isApp) {
                switch(true) {
                    case itemDelegate.isSettings:
                        return "settings"
                    case itemDelegate.isIndicator:
                        return "dropdown-menu"
                }

                return itemDelegate.itemIcon
            }
            
            return ""
        }
        color: {
            if (itemDelegate.toggleOn) {
                return theme.palette.normal.selectionText
            }

            return itemDelegate.highlighted ? theme.palette.normal.activity : theme.palette.normal.foregroundText
        }
        Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
    }

    Rectangle {
        id: secondaryRec

        visible: itemDelegate.isSettings || itemDelegate.isIndicator
        color: itemDelegate.isIndicator ? "transparent" : bgRec.color
        radius: width / 2
        width: bgRec.height * 0.5
        height: width
        anchors {
            centerIn: bgRec
            verticalCenterOffset: itemDelegate.isIndicator ? -bgRec.height * 0.15 : 0
        }

        Icon {
            name: itemDelegate.isSettings || itemDelegate.isIndicator ? itemDelegate.itemIcon : ""
            color: mainIcon.color
            height: secondaryRec.height * 0.7
            width: height
            anchors.centerIn: secondaryRec
        }
    }
}
