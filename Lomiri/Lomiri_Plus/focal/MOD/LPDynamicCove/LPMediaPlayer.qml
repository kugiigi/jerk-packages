// ENH064 - Dynamic Cove
import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import QtQuick.LocalStorage 2.0
import "MediaPlayer" as MediaPlayer

LPDynamicCoveItem {
    id: mediaPlayer

    readonly property string allSongId: "dc-all"
    readonly property var mediaPlayerObj: shell.mediaPlayer
    readonly property bool playing: mediaPlayerObj && mediaPlayerObj.isPlaying
    readonly property bool aboutToTakeAction: swipeArea.dragging && swipeArea.draggingCustom
    readonly property bool noMedia: mediaPlayerObj && mediaPlayerObj.noMedia
    readonly property bool paused: mediaPlayerObj && mediaPlayerObj.isPaused
    readonly property bool stopped: mediaPlayerObj && mediaPlayerObj.isStopped
    readonly property bool noQueue: noMedia || stopped
    readonly property string currentPlaylist: mediaPlayerObj ? mediaPlayerObj.currentPlaylist : ""

    property bool playlistPending: false
    property int pendingPlaylistTrackCount: -1

    swipeAreaDirection: SwipeArea.Horizontal
    enableMouseArea: false

    function clearQueue() {
        mediaPlayerObj.clear()
    }

    function continuePlayback() {
        mediaPlayerObj.play()
    }

    function shuffle() {
        let playlistId = playlists.currentItem.itemId
        if (playlistId == allSongId) {
            console.log("Shuffle all songs")
            mediaPlayerObj.currentPlaylist = "All songs"
            mediaPlayerObj.playRandomSong()
        } else {
            console.log("Shuffle " + playlistId)
            playlistPending = true
            pendingPlaylistTrackCount = playlists.currentItem.itemCount
            mediaPlayerObj.currentPlaylist = playlistId
            playlistTracksModel.filterPlaylistTracks(playlistId)
        }

        playFallbackTimer.restart()
    }

    function playPendingPlaylist() {
        playlistPending = false
        mediaPlayerObj.playRandomSong(playlistTracksModel)
    }

    // Reload media player object when loaded and no playlist is on queue
    // This might solve issue when playing a playlist doesn't work until reloaded
    Component.onCompleted: {
        if (shell.mediaPlayerLoaderObj.active && (!mediaPlayerObj || mediaPlayer.noQueue)) {
            shell.mediaPlayerLoaderObj.reloadSource()
        }
    }

    Connections {
        target: swipeArea
        onTriggered: {
            if (target.goingNegative) {
                mediaPlayer.clearQueue()
            } else if (target.goingPositive) {
                if (!mediaPlayer.playing) {
                    if (mediaPlayer.paused) {
                        mediaPlayer.continuePlayback()
                    } else {
                        mediaPlayer.shuffle()
                    }
                }
            }
        }
    }

    // WORKAROUND: For playlist not playing immediately
    Timer {
        id: playFallbackTimer

        running: false
        interval: 500
        onTriggered: {
            if (!mediaPlayer.noQueue && !mediaPlayer.playing) {
                console.log("Fallback play used")
                mediaPlayer.continuePlayback()
            }
        }
    }
    
    // event eater
    // Nothing should leak to items behind the mouseArea
    MouseArea {
        anchors.centerIn: parent
        width: mediaPlayer.mouseArea.width
        height: width
        hoverEnabled: true
    }

    Item {
        id: container

        anchors.fill: parent
        visible: mediaPlayerObj.isReady
        
        Component.onCompleted: playlistsModel.filterPlaylists()

        Rectangle {
            id: bg

            color: theme.palette.normal.foreground
            opacity: 0.3
            anchors.centerIn: parent
            width: units.gu(5)
            height: width
            radius: width / 2
            Component.onCompleted: delayOpenAnimation.restart()

            Behavior on width { LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration } }

            // WORKAROUND: Delay to avoid the issue where the animation
            // doesn't seem to execute upong locking the device
            Timer {
                id: delayOpenAnimation

                running: false
                interval: 1
                onTriggered: bg.width = bg.parent.width
            }
        }

        Item {
            id: contents
            
            anchors.fill: parent
            opacity: bg.width == bg.parent.width ? 1 : 0
            Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration } }

            Label {
                text: {
                    if (mediaPlayer.swipeArea.goingPositive) {
                        if (mediaPlayer.paused) {
                            return "Continue playback"
                        } else {
                            if (mediaPlayer.playing) {
                                return "Already playing"
                            } else {
                                return "Shuffle"
                            }
                        }
                    }
                    if (mediaPlayer.swipeArea.goingNegative) {
                        if (mediaPlayer.noQueue) {
                            return "Nothing to clear"
                        } else {
                            return "Clear queue"
                        }
                    }

                    return ""
                }
                color: mediaPlayer.swipeArea.goingNegative ? theme.palette.normal.negative : theme.palette.normal.positive
                anchors.centerIn: parent
                textSize: Label.Medium
                opacity: mediaPlayer.aboutToTakeAction ? 1 : 0
                Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration } }
                Behavior on color { ColorAnimation { duration: LomiriAnimation.SnapDuration } }
            }
            
            RowLayout {
                anchors{
                    fill: parent
                    margins: parent.width * 0.2
                }

                opacity: mediaPlayer.aboutToTakeAction ? 0 : 1
                Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SlowDuration } }

                Label {
                    Layout.alignment: Qt.AlignVCenter
                    text: "《"
                    color: theme.palette.normal.negative
                }
                
                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true

                    visible: !playlists.visible
                    spacing: 0

                    Label {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignCenter

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: mediaPlayer.playing ? "Currently playing:" : "Playlist in queue:"
                        textSize: Label.XSmall
                        color: theme.palette.normal.backgroundSecondaryText
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignCenter

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: mediaPlayer.currentPlaylist
                        color: theme.palette.normal.foregroundText
                    }
                }

                MediaPlayer.LPTumbler {
                    id: playlists

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    visibleItemCount: 3
                    currentIndex: 0
                    model: playlistsModel.model
                    visible: mediaPlayer.noQueue
                    delegate: QQC2.AbstractButton {
                        id: tumblerDelegate
                        
                        property bool highlighted: Math.abs(QQC2.Tumbler.displacement) < 0.1
                        property string itemText: index == 0 ? model.name : "%1 (%2)".arg(model.name).arg(model.count)
                        property string itemId: index == 0 ? mediaPlayer.allSongId : model.name
                        property string itemCount: index == 0 ? -1 : model.count
                        
                        focusPolicy: Qt.NoFocus
                        opacity: 1 - ((1.6 * Math.abs(QQC2.Tumbler.displacement)) / (QQC2.Tumbler.tumbler.visibleItemCount - 1))
                        width: parent.width
                        // Needed otherwise height will be zero when only 1 item and you reload the component or switch dynamic cove item
                        height: playlists.availableHeight / playlists.visibleItemCount

                        onClicked: QQC2.Tumbler.tumbler.currentIndex = index

                        Label {
                            id: mainText
                            
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            anchors.fill: parent
                            color: theme.palette.normal.backgroundText
                            scale: highlighted ? 1.0 : 0.8
                            text: itemText
                            Behavior on scale { LomiriNumberAnimation { duration: LomiriAnimation.BriskDuration } }
                        }
                        
                    }

                    onCurrentIndexChanged: {
                        shell.haptics.playSubtle()
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignVCenter
                    text: "》"
                    color: theme.palette.normal.positive
                }
            }
        }
        
        MediaPlayer.LPPlaylistsModel {
            id: playlistsModel
            syncFactor: 1
        }
        MediaPlayer.LPPlaylistsModel {
            id: playlistTracksModel

            onRowCountChanged: {
                if (rowCount == mediaPlayer.pendingPlaylistTrackCount && mediaPlayer.playlistPending) {
                    console.log("LoadComplete!!!! " + rowCount + " - " + mediaPlayer.pendingPlaylistTrackCount)
                    mediaPlayer.playPendingPlaylist()
                }
            }
        }
    }
}
