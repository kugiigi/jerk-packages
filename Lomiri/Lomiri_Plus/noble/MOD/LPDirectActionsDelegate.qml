// ENH139 - System Direct Actions
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import Qt.labs.platform 1.0 as LabsPlatform
import QtGraphicalEffects 1.12

Item {
    id: itemDelegate

    readonly property string defaultIconName: "image://theme/dialog-question-symbolic"
    property real maximumSize: units.gu(6)
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
            case LPDirectActions.Type.CustomURI:
                _found = shell.settings.directActionsCustomURIs.find((element) => element.name == itemId);
                break

            return _found
        }
    }
    readonly property bool isSettings: type == LPDirectActions.Type.Settings
    readonly property bool isIndicator: type == LPDirectActions.Type.Indicator
    readonly property bool isApp: type == LPDirectActions.Type.App
    readonly property bool isToggle: type == LPDirectActions.Type.Toggle
    readonly property bool isCustom: type == LPDirectActions.Type.Custom
    readonly property bool isCustomURI: type == LPDirectActions.Type.CustomURI
    readonly property bool isCustomURIWithAppIcon: isCustomURI && itemAppId !== ""
    readonly property bool isHovered: hoverHandler.hovered
    readonly property bool shouldBeHighlighted: highlighted || isHovered
    readonly property bool useIconForDisplay: displayType !== LPDirectActions.DisplayType.Default && itemIconName !== ""
    readonly property bool isCustomIconDisplay: displayType === LPDirectActions.DisplayType.CustomIcon
    readonly property bool displayAppIcon: (isApp && !useIconForDisplay) || isCustomURIWithAppIcon
    property alias mouseHoverEnabled: hoverHandler.enabled

    property string itemId
    property bool highlighted: false
    property int type: LPDirectActions.Type.Indicator
    property int displayType: LPDirectActions.DisplayType.Default
    property string itemIconName
    property string itemCustomTitle
    property real highlightScale: 1.3
    property bool displayedTop: false
    property bool displayedLeft: false
    property bool editMode: false
    property bool enableHaptics: false

    property int displayStyle: 0
    /*
     * 0 - Default
     * 1 - Circular
     * 2 - Rounded Square
    */
    readonly property bool isCustomStyle: displayStyle > 0
    readonly property bool isCircularStyle: displayStyle === 1
    readonly property bool isRoundedSquareStyle: displayStyle === 2

    property string itemTitle: {
        if (itemCustomTitle.trim() !== "")
            return itemCustomTitle

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
                case LPDirectActions.Type.CustomURI:
                    return foundData.name
            }
        }

        return "Unknown"
    }

    property string itemIcon: {
        if (useIconForDisplay)
            return itemIconName

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
                case LPDirectActions.Type.CustomURI:
                    return foundData.iconName
            }
        }

        return defaultIconName
    }

    property bool useCustomIconURL: {
        if (foundData) {
            switch(type) {
                case LPDirectActions.Type.CustomURI:
                    return foundData.iconType === "custom"
            }
        }

        return false
    }
    property string itemAppId: {
        if (foundData) {
            switch(type) {
                case LPDirectActions.Type.CustomURI:
                    return foundData.appId
            }
        }

        return ""
    }
    property string itemAppIdIcon: {
        if (itemAppId) {
            let _appData = !shell.appModel.refreshing ? shell.getAppData(itemAppId) : null
            return _appData !== null ? _appData.icon : ""
        }

        return ""
    }

    signal trigger
    signal enterEditMode
    signal exitEditMode

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
                case LPDirectActions.Type.CustomURI:
                    return true
            }
        }

        return false
    }
    opacity: enabled ? 1 : 0.5
    z: shouldBeHighlighted ? 2 : 1
    scale: (shouldBeHighlighted ? highlightScale : 1) * (tapHandler.pressed ? 0.8 : 1)
    Behavior on scale { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }

    onTrigger: {
        if (foundData) {
            switch(type) {
                case LPDirectActions.Type.Indicator:
                    shell.openIndicatorByIndex(foundData.indicatorIndex, !itemDelegate.displayedTop)
                    return
                    break
                case LPDirectActions.Type.App:
                    shell.startApp(itemId)
                    return
                    break
                case LPDirectActions.Type.Settings:
                    Qt.openUrlExternally("settings:///system/%1".arg(foundData.url))
                    return
                    break
                case LPDirectActions.Type.Toggle:
                    if (toggleObj && toggleObj.enabled) {
                        toggleObj.clicked()
                    }
                    return
                    break
                case LPDirectActions.Type.Custom:
                    return foundData.trigger()
                    break
                case LPDirectActions.Type.CustomURI:
                    let _uri = foundData.uri
                    if (_uri) Qt.openUrlExternally(foundData.uri)
                    return
                    break
            }
        }

        console.log("Unknown Quick Action triggered")
    }

    onShouldBeHighlightedChanged: {
        if (enableHaptics) {
            if (shouldBeHighlighted) {
                delayHaptics.restart()
            } else {
                delayHaptics.stop()
            }
        }
    }

    Timer {
        id: delayHaptics

        running: false
        interval: 100
        onTriggered: {
            if (itemDelegate.shouldBeHighlighted) {
                shell.haptics.playSubtle()
            }
        }
    }
    
    Loader {
        id: appIconLoader

        active: !itemDelegate.isCustomStyle && itemDelegate.displayAppIcon
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
                source: itemDelegate.isCustomURIWithAppIcon ? itemDelegate.itemAppIdIcon : itemDelegate.itemIcon
                asynchronous: true
                sourceSize.width: appIcon.width
            }
            sourceFillMode: LomiriShape.PreserveAspectCrop

            StyledItem {
                styleName: "FocusShape"
                anchors.fill: parent
                StyleHints {
                    visible: itemDelegate.shouldBeHighlighted
                    radius: units.gu(2.55)
                }
            }
        }
    }

    Loader {
        id: customAppIconLoader

        active: itemDelegate.isCustomStyle && itemDelegate.displayAppIcon
        asynchronous: true
        anchors.centerIn: parent
        width: Math.min(parent.width, itemDelegate.maximumSize)
        height: 7.5 / 8 * width

        sourceComponent: Image {
            id: customAppIcon

            source: itemDelegate.isCustomURIWithAppIcon ? itemDelegate.itemAppIdIcon : itemDelegate.itemIcon
            asynchronous: true
            sourceSize {
                width: width
                height: height
            }
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Item {
                    width: customAppIcon.width
                    height: customAppIcon.height
                    Rectangle {
                        anchors.centerIn: parent
                        width: customAppIcon.width
                        height: customAppIcon.height
                        radius: itemDelegate.isCircularStyle ? width / 2 : width * 0.3
                    }
                }
            }
        }
    }

    Rectangle {
        anchors {
            fill: customAppIconLoader
            margins: -units.gu(0.46)
        }
        visible: customAppIconLoader.active && itemDelegate.shouldBeHighlighted
        radius: itemDelegate.isCircularStyle ? width / 2 : width * 0.3
        color: "transparent"
        border {
            color: theme.palette.normal.focus
            width: units.dp(2)
        }
    }

    Rectangle {
        id: bgRec

        state: "background"
        states: [
            State {
                name: "background"
                when: !itemDelegate.isCustomURIWithAppIcon
                PropertyChanges {
                    target: bgRec
                    anchors.centerIn: parent
                    anchors.fill: undefined
                    width: Math.min(parent.width, itemDelegate.maximumSize)
                    opacity: 1
                    radius: {
                        if (!itemDelegate.isCustomStyle && itemDelegate.isToggle)
                            return width * 0.2

                        if (itemDelegate.isCircularStyle)
                            return  width / 2

                        if (itemDelegate.isRoundedSquareStyle)
                            return  width * 0.3

                        return width / 2
                    }
                }
            }
            , State {
                name: "foreground"
                when: itemDelegate.isCustomURIWithAppIcon
                PropertyChanges {
                    target: bgRec
                    anchors.centerIn: undefined
                    anchors.fill: itemDelegate.isCustomStyle ? appIconLoader : customAppIconLoader
                    opacity: 0.5
                    radius: {
                        if (!itemDelegate.isCustomStyle)
                            return units.gu(1.45)

                        if (itemDelegate.isCircularStyle)
                            return  width / 2

                        if (itemDelegate.isRoundedSquareStyle)
                            return  width * 0.3

                        return 0
                    }
                }
            }
        ]

        visible: !(itemDelegate.isApp && !itemDelegate.useIconForDisplay) && !(itemDelegate.isCustomURIWithAppIcon && itemDelegate.itemIcon === "")
        color: {
            if (itemDelegate.toggleOn) {
                return theme.palette.normal.selection
            }

            return itemDelegate.shouldBeHighlighted ? theme.palette.highlighted.foreground : theme.palette.normal.foreground
        }

        radius: itemDelegate.isToggle && !itemDelegate.useIconForDisplay ? width * 0.2 : width / 2
        height: width
        Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
    }

    Item {
        id: dummyHoverItem

        anchors.fill: bgRec.visible ? bgRec : appIconLoader

        HoverHandler {
            id: hoverHandler
            target: bgRec
            acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Cursor | PointerDevice.Pen
        }
    }

    Icon {
        id: mainIcon

        anchors {
            centerIn: bgRec
            verticalCenterOffset: itemDelegate.isIndicator ? bgRec.height * 0.15 : 0
        }
        asynchronous: true

        height: {
            if (itemDelegate.useIconForDisplay)
                return bgRec.height * 0.5

            if (itemDelegate.isSettings) {
                return bgRec.height * 0.9
            }
            if (itemDelegate.isIndicator) {
                return bgRec.height * 0.3
            }
            if (itemDelegate.useCustomIconURL)
                return bgRec.height * 0.7

            return bgRec.height * 0.5
        }
        width: height
        name: {
            if (itemDelegate.useIconForDisplay)
                return itemDelegate.itemIcon

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
        source: {
            if (name !== "") {
                if (itemDelegate.useCustomIconURL || itemDelegate.isCustomIconDisplay) {
                    return LabsPlatform.StandardPaths.writableLocation(LabsPlatform.StandardPaths.HomeLocation).toString() + "/Pictures/lomiriplus/" + name
                } else {
                    return "image://theme/" + name
                }
            }

            return ""
        }

        keyColor: itemDelegate.useCustomIconURL || itemDelegate.isCustomIconDisplay ? "#ffffff" : "#808080"
        color: {
            if (itemDelegate.toggleOn) {
                return theme.palette.normal.selectionText
            }

            return itemDelegate.shouldBeHighlighted && !itemDelegate.isCustomURIWithAppIcon ? theme.palette.normal.activity : theme.palette.normal.foregroundText
        }
        Behavior on color { ColorAnimation { duration: LomiriAnimation.FastDuration } }
    }

    Rectangle {
        id: secondaryRec

        visible: !itemDelegate.useIconForDisplay && (itemDelegate.isSettings || itemDelegate.isIndicator)
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
            asynchronous: true
        }
    }

    TapHandler {
        id: tapHandler
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onSingleTapped: {
            if (eventPoint.event.button == Qt.RightButton) {
                itemDelegate.enterEditMode()
            } else {
                if (itemDelegate.editMode) {
                     itemDelegate.exitEditMode()
                } else {
                    itemDelegate.trigger()
                }
            }
        }
        onLongPressed: {
            if (!itemDelegate.editMode) {
                itemDelegate.enterEditMode()
            }
        }
    }

    SequentialAnimation {
        running: itemDelegate.editMode
        loops: Animation.Infinite

        RotationAnimation {
            target: itemDelegate
            duration: LomiriAnimation.FastDuration
            to: itemDelegate.width < units.gu(10) ? 10 : 2
            direction: RotationAnimation.Clockwise
        }
        RotationAnimation {
            target: itemDelegate
            duration: LomiriAnimation.FastDuration
            to: itemDelegate.width < units.gu(10) ? -10 : -2
            direction: RotationAnimation.Counterclockwise
        }
    }

    RotationAnimation {
        running: !itemDelegate.editMode
        target: itemDelegate
        duration: LomiriAnimation.SnapDuration
        to: 0
        direction: RotationAnimation.Shortest
    }
}
