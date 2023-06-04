import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12

LPQuickToggleButton {
	id: mediaPlayer

	property var mediaPlayerObj
	property var playBackObj

    readonly property real margins: units.gu(1.5)
    readonly property bool canGoNext: playBackObj && playBackObj.canGoNext ? true : false
    readonly property bool canGoPrevious: playBackObj && playBackObj.canGoPrevious ? true : false
    readonly property bool playing: playBackObj && playBackObj.playing ? true : false
    readonly property bool canPlay: playBackObj && playBackObj.canPlay ? true : false
    readonly property string song: mediaPlayerObj ? mediaPlayerObj.song ? mediaPlayerObj.song : "No Title" : ""
    readonly property string artist: mediaPlayerObj ? mediaPlayerObj.artist : ""
    readonly property string album: mediaPlayerObj ? mediaPlayerObj.album : ""
    readonly property var albumArt: mediaPlayerObj ? mediaPlayerObj.albumArt : ""
	
    checkedColor: theme.palette.normal.foreground
    bgOpacity: 0.3
    iconName: "stock_music"
    noIcon: !editMode

    function playPause() {
        if (mediaPlayer.playBackObj) {
            mediaPlayer.playBackObj.play(!playing)
        }
    }

    function next() {
        if (mediaPlayer.playBackObj) {
            mediaPlayer.playBackObj.next()
        }
    }

    function previous() {
        if (mediaPlayer.playBackObj) {
            mediaPlayer.playBackObj.previous()
        }
    }
    
	NumberAnimation {
		id: hideAnimiation

		running: false
		targets: [textContainer, albumArtShape]
		property: "opacity"
		duration: LomiriAnimation.BriskDuration
		from: 1
		to: 0
		onFinished: {
			songTitle.text = songTitle.nextText
			artistName.text = artistName.nextText
			albumTitle.text = albumTitle.nextText
            albumArtShape.source = albumArtShape.nextAlbumArt
			showAnimation.restart()
		}
	}
	NumberAnimation {
		id: showAnimation

		running: false
		targets: [textContainer, albumArtShape]
		property: "opacity"
		duration: LomiriAnimation.BriskDuration
		from: 0
		to: 1
	}
	
	RowLayout {
        id: mainLayout
        
        readonly property bool narrowWidth: width < units.gu(40)

        visible: !mediaPlayer.editMode
        opacity: nextPrevSwipe.dragging ? Math.max(nextPrevSwipe.hideOpacity, nextPrevSwipe.minimumDragOpacity) : 1
        anchors {
            fill: parent
            leftMargin: mediaPlayer.margins
            rightMargin: anchors.leftMargin
        }
        
        Behavior on opacity {
            LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration }
        }

		LomiriShape {
            id: albumArtShape

			Layout.preferredWidth: units.gu(5)
			Layout.preferredHeight: units.gu(5)
			Layout.alignment: Qt.AlignVCenter
            
            property alias source: albumArtImage.source
            property string nextAlbumArt: mediaPlayer.albumArt

			visible: !mainLayout.narrowWidth || shell.settings.gestureMediaControls
			image: Image {
				id: albumArtImage
				fillMode: Image.PreserveAspectFit
				sourceSize: Qt.size(width, height)
				anchors.fill: parent
			}
		}

		ColumnLayout {
			id: textContainer

			Layout.fillWidth: true
			Layout.alignment: Qt.AlignVCenter
			spacing: 0

			Label {
				id: songTitle

				property string nextText: mediaPlayer.song

				Layout.fillWidth: true
				Layout.alignment: Qt.AlignVCenter
				verticalAlignment: Text.AlignVCenter
				textSize: Label.Medium
				color: "white"
				elide: Text.ElideRight
                maximumLineCount: 3
                wrapMode: mainLayout.narrowWidth ? Text.WordWrap : Text.NoWrap

				onNextTextChanged: {
					hideAnimiation.restart()
				}
			}

			Label {
				id: artistName
				Layout.fillWidth: true

                property string nextText: mediaPlayer.artist

                visible: !mainLayout.narrowWidth
				opacity: text.trim().length > 0 ? 1 : 0
				textSize: Label.Small
				color: theme.palette.normal.backgroundText
				elide: Text.ElideRight
				Behavior on opacity {
					LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration }
				}
				Layout.preferredHeight: text.trim().length > 0 ? contentHeight: 0 
				Behavior on Layout.preferredHeight {
					LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration }
				}
			}

			Label {
				id: albumTitle
				Layout.fillWidth: true

                property string nextText: mediaPlayer.album

                visible: !mainLayout.narrowWidth
				opacity: text.trim().length > 0 ? 1 : 0
				textSize: Label.XSmall
				color: theme.palette.normal.backgroundText
				elide: Text.ElideRight
				Behavior on opacity {
					LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration }
				}
				Layout.preferredHeight: text.trim().length > 0 ? contentHeight: 0 
				Behavior on Layout.preferredHeight {
					LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration }
				}
			}
		}

		RowLayout {
			Layout.alignment: Qt.AlignVCenter

            visible: !shell.settings.gestureMediaControls

			LPQuickToggleButton {
				Layout.preferredHeight: quickToggles.toggleHeight
				Layout.preferredWidth: height

				enabled: mediaPlayer.canGoPrevious
				iconName: "media-skip-backward"
				onClicked: mediaPlayer.previous()
			}
            LPQuickToggleButton {
				Layout.preferredHeight: quickToggles.toggleHeight
				Layout.preferredWidth: height

				enabled: mediaPlayer.canGoNext
				iconName: "media-skip-forward"
				onClicked: mediaPlayer.next()
			}
			LPQuickToggleButton {
				Layout.preferredHeight: quickToggles.toggleHeight
				Layout.preferredWidth: height

				enabled: mediaPlayer.canPlay
				iconName: mediaPlayer.playing ? "media-playback-pause" : "media-playback-start"
				onClicked: mediaPlayer.playPause()
			}
		}
        
        Icon {
            Layout.preferredHeight: units.gu(3)
            Layout.preferredWidth: height
            name: mediaPlayer.playing ? "media-playback-pause" : "media-playback-start"
            visible: shell.settings.gestureMediaControls
            color: theme.palette.normal.foregroundText
        }
	}
    

    LPSwipeIndicator {
        id: goForwardIcon

        iconName: "media-skip-forward"
        dragDistance: nextPrevSwipe.distance
        enabled: mediaPlayer.canGoNext
        color: theme.palette.normal.activity
        anchors {
            right: parent.right
            margins: units.gu(2)
            verticalCenter: parent.verticalCenter
        }
    }

    LPSwipeIndicator {
        id: goBackIcon

        iconName: "media-skip-backward"
        dragDistance: nextPrevSwipe.distance
        enabled: mediaPlayer.canGoPrevious
        color: theme.palette.normal.activity
        anchors {
            left: parent.left
            margins: units.gu(2)
            verticalCenter: parent.verticalCenter
        }
    }
    
    SwipeArea {
        id: nextPrevSwipe

        // draggingCustom is used for implementing trigger delay
        readonly property real threshold: units.gu(5)
        readonly property bool goingNext: distance < 0
        readonly property bool goingPrev: distance > 0
        readonly property bool toTrigger: nextPrevSwipe.dragging && nextPrevSwipe.draggingCustom
        readonly property real minimumDragOpacity: 0.2
        readonly property real hideOpacity: dragging ? 1 + minimumDragOpacity - Math.abs(distance) / threshold : 0
        readonly property real showOpacity: dragging ? Math.abs(distance) / threshold : 0
        property bool draggingCustom: Math.abs(distance) >=  threshold

        signal triggered

        anchors.fill: parent
        enabled: !mediaPlayer.editMode && shell.settings.gestureMediaControls
        direction: SwipeArea.Horizontal

        onDraggingChanged: {
            if (!dragging) {
                if (draggingCustom) {
                    triggered()
                }
                goForwardIcon.hide()
                goBackIcon.hide()
            }
        }

        onDraggingCustomChanged: {
            if (draggingCustom) {
                if (goingNext) {
                    goForwardIcon.show()
                }
                if (goingPrev) {
                    goBackIcon.show()
                }
                shell.haptics.play()
            } else {
                goForwardIcon.hide()
                goBackIcon.hide()
                shell.haptics.playSubtle()
            }
        }
        
        onTriggered: {
            if (goingPrev) {
                mediaPlayer.previous()
            } else if (goingNext) {
                mediaPlayer.next()
            }
        }
    }
}
