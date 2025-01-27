// ENH064 - Dynamic Cove
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.12

LPDynamicCoveItem {
    id: cdPlayer

    readonly property var mediaPlayerObj: shell.mediaPlayerIndicator
    readonly property var playBackObj: shell.playbackItemIndicator
    readonly property bool playing: playBackObj && playBackObj.playing ? true : false
    readonly property alias spinAnimation: spinAnimation

    property bool isSimpleMode: true
    property real cdPlayerOpacity: 1

    Connections {
        target: mouseArea
        onClicked: {
            if (playBackObj && visible) {
                playBackObj.play(!playBackObj.playing)
                shell.haptics.play()
            }
        }

        onPressAndHold: {
            shell.settings.enableCDPlayerDisco = !shell.settings.enableCDPlayerDisco
            shell.haptics.playSubtle()
        }
    }

    Connections {
        target: swipeArea
        onTriggered: {
            if (cdPlayer.playBackObj) {
                if (target.goingNegative) {
                    cdPlayer.playBackObj.previous()
                } else if (target.goingPositive) {
                    cdPlayer.playBackObj.next()
                }
            }
        }
    }

    Component.onCompleted: delayOpenAnimation.restart()

    // WORKAROUND: Delay to avoid the issue where the animation
    // doesn't seem to execute upong locking the device
    Timer {
        id: delayOpenAnimation

        running: false
        interval: 1
        onTriggered: openAnimationRec.width = openAnimationRec.parent.width
    }

    Rectangle {
        id: openAnimationRec

        radius: width / 2
        anchors.centerIn: parent
        width: units.gu(5)
        height: width
        color: theme.palette.normal.foreground
        opacity: 0.3
        visible: width !== parent.width || !cdRec.visible
        Behavior on width { LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration } }
    }

    Label {
        visible: !cdRec.visible
        text: "No media playing"
        anchors.centerIn: parent
    }

    Loader {
        id: ambientLoader

        readonly property real normalOpacity: 0.6

        active: shell.settings.enableAmbientModeInCDPlayer
        asynchronous: true
        sourceComponent: ambientComponent
        opacity: normalOpacity
        anchors {
            fill: parent
            margins: -cdRec.width
        }

        SequentialAnimation {
            id: ambientChangeAnimation

            LomiriNumberAnimation {
                running: false
                target: ambientLoader
                property: "opacity"
                duration: LomiriAnimation.SlowDuration
                from: ambientLoader.normalOpacity
                to: 0
            }

            LomiriNumberAnimation {
                running: false
                target: ambientLoader
                property: "opacity"
                duration: LomiriAnimation.SleepyDuration
                from: 0
                to: ambientLoader.normalOpacity
            }
        }

        Connections {
            target: img
            onNextAlbumArtChanged: {
                ambientChangeAnimation.restart()
            }
        }
    }

    Component {
        id: ambientComponent

        Item {
            RadialGradient {
                id: radialGradient

                anchors.fill: parent
                visible: false
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "white" }
                    GradientStop { position: 0.1; color: "white" }
                    GradientStop { position: 0.5; color: "transparent" }
                }
            }

            OpacityMask {
                anchors.fill: parent
                source: shaderEffectSource.enabled ? shaderEffectSource : img
                maskSource: radialGradient
            }
        }
    }

    Rectangle {
        id: cdRec

        readonly property real minimumDragOpacity: 0.2
        readonly property real currentDragOpacity: cdPlayer.swipeArea.dragging ? 1 + minimumDragOpacity - Math.abs(cdPlayer.swipeArea.distance) / nextPrevSwipe.threshold : -1

        visible: opacity > 0
        x: 0
        y: {
            if (cdPlayer.swipeArea.dragging) {
                if (cdPlayer.swipeArea.goingPositive && cdPlayer.playBackObj.canGoNext) {
                    return Math.min(cdPlayer.swipeArea.distance, cdPlayer.swipeArea.threshold)
                }
                if (cdPlayer.swipeArea.goingNegative && cdPlayer.playBackObj.canGoPrevious) {
                    return Math.max(cdPlayer.swipeArea.distance, -cdPlayer.swipeArea.threshold)
                }
            }

            return 0
        }
        width: parent.width
        height: parent.height
        radius: width / 2
        color: {
            if (cdPlayer.isSimpleMode) {
                return cdPlayer.playBackObj && cdPlayer.playBackObj.playing ? "#716e6d" : "#080301"
            }
            
            return img.noAlbumArt ? "#716e6d" : "transparent"
        }

        opacity: !playBackObj || (playBackObj && !playBackObj.canPlay) || (shell.settings.hideCDPlayerWhenScreenOff && cdPlayer.screenIsOff) || openAnimationRec.width !== openAnimationRec.parent.width ? 0
                        : cdPlayer.swipeArea.dragging ? Math.max(currentDragOpacity, minimumDragOpacity) : cdPlayer.cdPlayerOpacity

        Behavior on color { ColorAnimation { duration: LomiriAnimation.SlowDuration } }
        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration } }
        Behavior on y { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }

        Image {
            id: img
            property bool rounded: !shaderEffectSource.enabled
            property bool noAlbumArt: source == "file:///usr/share/icons/suru/apps/scalable/music-app-symbolic.svg"
            property string nextAlbumArt: {
                if (cdPlayer.mediaPlayerObj && !cdPlayer.isSimpleMode) {
                    if (cdPlayer.mediaPlayerObj.albumArt == "file:///usr/share/icons/suru/apps/scalable/music-app-symbolic.svg") {
                        return Qt.resolvedUrl("../LPGraphics/music-app.svg")
                    } else {
                        return cdPlayer.mediaPlayerObj.albumArt
                    }
                }
                return ""
            }

            cache: false
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(width, height)
            anchors.fill: parent

            layer.enabled: rounded
            layer.effect: OpacityMask {
                maskSource: Item {
                    width: img.width
                    height: img.height
                    Rectangle {
                        anchors.centerIn: parent
                        width: img.width
                        height: img.height
                        radius: Math.min(width, height)
                    }
                }
            }

            onNextAlbumArtChanged: {
                albumHideAnimiation.restart()
            }

            NumberAnimation {
                id: albumHideAnimiation

                running: false
                target: img
                property: "opacity"
                duration: LomiriAnimation.SnapDuration
                from: 1
                to: 0
                onFinished: {
                    img.source = img.nextAlbumArt
                    albumShowAnimation.restart()
                }
            }
            NumberAnimation {
                id: albumShowAnimation

                running: false
                target: img
                property: "opacity"
                duration: LomiriAnimation.SleepyDuration
                from: 0
                to: 1
            }
        }

        ShaderEffectSource {
            id: shaderEffectSource
            sourceItem: shell.settings.dcBlurredAlbumArt ? img : null
            hideSource: true
            sourceRect: Qt.rect(0,0,0,0)
            live: !cdPlayer.screenIsOff
            enabled: sourceItem != null
        }

        FastBlur {
            id: fastBlur
            anchors.fill: parent
            source: shaderEffectSource
            radius: units.gu(2)
            cached: false
            visible: shaderEffectSource.sourceItem != null
            enabled: visible
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Item {
                        width: fastBlur.width
                        height: fastBlur.height
                        Rectangle {
                                anchors.centerIn: parent
                                width: fastBlur.width
                                height: fastBlur.height
                                radius: Math.min(width, height)
                        }
                }
            }
        }
        
        Rectangle {
            id: cdHole
            color: "black"
            anchors.centerIn: parent
            height: units.gu(6)
            width: height
            radius: width / 2
            border {
                width: units.gu(1)
                color: "#9E000000"
            }
        }

        Rectangle {
            readonly property color _normalColor: theme.palette.normal.background
            anchors.fill: parent
            anchors.margins: units.gu(1)
            radius: width / 2
            opacity: 0.3
            color: mouseArea.pressed ? _normalColor.hslLightness > 0.1 ? Qt.darker(_normalColor, 1.2)
                                                                             : Qt.lighter(_normalColor, 3.0)
                                           : _normalColor
                                           
            Behavior on color {
                ColorAnimation {
                  duration: LomiriAnimation.SnapDuration
                }
            }
        }
    }
    
    RotationAnimation {
        id: spinAnimation

        readonly property int defaultDuration: 10000
        readonly property int minDuration: 100

        loops: Animation.Infinite
        running: true
        paused: cdRec.visible && cdPlayer.playBackObj && !cdPlayer.swipeArea.dragging
                        && !cdPlayer.screenIsOff
                        && !cdPlayer.isSimpleMode ? !cdPlayer.playBackObj.playing : true
        target: cdRec
        duration: defaultDuration
        from: 0
        to: 360
        alwaysRunToEnd: false
        direction: RotationAnimation.Clockwise
    }

    ColumnLayout {
        id: textContainer

        property bool toTransition: cdPlayer.swipeArea.dragging && cdPlayer.swipeArea.draggingCustom

        visible: cdRec.visible
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: units.gu(4)
        }

        Behavior on opacity {
            LomiriNumberAnimation { duration: LomiriAnimation.SleepyDuration }
        }

        NumberAnimation {
            id: hideAnimiation

            running: false
            target: textContainer
            property: "opacity"
            duration: LomiriAnimation.SnapDuration
            from: 1
            to: 0
            onFinished: {
                songTitle.text = songTitle.nextText
                showAnimation.restart()
            }
        }
        NumberAnimation {
            id: showAnimation

            running: false
            target: textContainer
            property: "opacity"
            duration: nextPrevSwipe.dragging ? LomiriAnimation.FastDuration : LomiriAnimation.SleepyDuration
            from: 0
            to: 1
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "》"
            rotation: -90
            color: theme.palette.normal.backgroundSecondaryText
            opacity: cdPlayer.playBackObj && cdPlayer.playBackObj.canGoNext && !textContainer.toTransition ? 1 : 0
            Layout.preferredHeight: !textContainer.toTransition ? contentHeight: 0 
            Behavior on Layout.preferredHeight {
                LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration }
            }
            Behavior on opacity {
                LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration }
            }
        }

        ColumnLayout {
            spacing: units.gu(0.2)

            Label {
                id: songTitle

                property string nextText: {
                    if (textContainer.toTransition) {
                        if (cdPlayer.swipeArea.goingNegative) {
                            if (cdPlayer.playBackObj.canGoPrevious) {
                                return "Play previous song"
                            } else {
                                return "No previous song"
                            }
                        }
                        if (cdPlayer.swipeArea.goingPositive) {
                            if (cdPlayer.playBackObj.canGoNext) {
                                return "Play next song"
                            } else {
                                return "No next song"
                            }
                        }
                    } else {
                        if (cdPlayer.mediaPlayerObj) {
                            return cdPlayer.mediaPlayerObj.song ? cdPlayer.mediaPlayerObj.song
                                                                : cdPlayer.mediaPlayerObj.albumArt && cdPlayer.mediaPlayerObj.albumArt.toString().search("thumbnailer") > -1
                                                                                ? shell.getFilename(cdPlayer.mediaPlayerObj.albumArt.toString())
                                                                                                   : "No Title"
                        }
                    }

                    return ""
                }

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                textSize: Label.Large
                color: textContainer.toTransition ? theme.palette.normal.activity : "white"
                font.weight: textContainer.toTransition ? Font.Normal : Font.Medium

                onNextTextChanged: {
                    hideAnimiation.restart()
                }
            }

            Label {
                id: artistName
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom

                visible: text !== ""
                opacity: text.trim().length > 0 && !textContainer.toTransition ? 1 : 0
                text: cdPlayer.mediaPlayerObj ? cdPlayer.mediaPlayerObj.artist : ""
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                textSize: Label.Small
                color: theme.palette.normal.backgroundText
                Behavior on opacity {
                    LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration }
                }
                Layout.preferredHeight: text.trim().length > 0 && !textContainer.toTransition ? contentHeight: 0 
                Behavior on Layout.preferredHeight {
                    LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration }
                }
            }

            Label {
                id: albumTitle
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom

                visible: text !== ""
                opacity: text.trim().length > 0 && !textContainer.toTransition ? 1 : 0
                text: cdPlayer.mediaPlayerObj ? cdPlayer.mediaPlayerObj.album : ""
                textSize: Label.XSmall
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                color: theme.palette.normal.backgroundText
                Behavior on opacity {
                    LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration }
                }
                Layout.preferredHeight: text.trim().length > 0 && !textContainer.toTransition ? contentHeight: 0 
                Behavior on Layout.preferredHeight {
                    LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration }
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "》"
            rotation: 90
            color: theme.palette.normal.backgroundSecondaryText
            opacity: cdPlayer.playBackObj && cdPlayer.playBackObj.canGoPrevious && !textContainer.toTransition ? 1 : 0
            Layout.preferredHeight: !textContainer.toTransition ? contentHeight: 0 
            Behavior on Layout.preferredHeight {
                LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration }
            }
            Behavior on opacity {
                LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration }
            }
        }
    }
}
