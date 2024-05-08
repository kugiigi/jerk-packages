import QtQuick 2.9
import QtQuick.Controls 2.2 as QQC2
import Lomiri.Components 1.3
import QtWebEngine 1.10
import "." as Sapot

QQC2.RoundButton {
    id: root

    readonly property int timeout: 1000
    property var target
    property string mode: "Up"
    property bool hidden: true
    property bool forceHide: false

    width: units.gu(8)
    height: width
    visible: opacity != 0
    opacity: hidden || forceHide ? 0 : 1
    background.opacity: 0.5

    function hide(delayed) {
        if (delayed) {
            timer.restart()
        } else {
            root.hidden = true
        }
    }

    onHoveredChanged: {
        if (hovered) {
            timer.stop()
        } else {
            timer.restart()
        }
    }

    Behavior on opacity {
        LomiriNumberAnimation {
            duration: LomiriAnimation.BriskDuration
        }
    }

    Connections {
        target: root.target

        ignoreUnknownSignals: true
        
        onScrollPositionChanged: {
            root.hidden = false
            timer.restart()
        }
        
        onVerticalVelocityChanged: {
            if (target.verticalVelocity === 0) {
                timer.start()
            } else {
                timer.stop()
                root.hidden = false
                if (target.verticalVelocity < 0) {
                    root.mode = "Up"
                } else {
                    root.mode = "Down"
                }
            }
        }
    }

    Icon {
        id: icon

        anchors.centerIn: root
        height: root.height / 2
        width: height
        name: "go-first"
        rotation: mode === "Up" ? 90 : mode === "Down" ? 270 : 90
        color: theme.palette.normal.backgroundText
        Behavior on rotation { RotationAnimation { duration: LomiriAnimation.SnapDuration; direction: RotationAnimation.Shortest } }
    }

    onClicked: {
        timer.restart()
        
        if (root.target instanceof WebEngineView) {
            if (mode === "Up") {
                root.target.scrollToTop();
            } else {
                root.target.scrollToBottom();
            }
        } else if (root.target instanceof ListView || root.target instanceof GridView) {
            if (mode === "Up") {
                root.target.positionViewAtBeginning()
            } else {
                root.target.positionViewAtEnd()
            }
        } else if (root.target instanceof Flickable) {
            if (mode === "Up") {
                root.target.contentY = 0
            } else {
                root.target.contentY = root.target.contentHeight - (root.target.height * 1)
            }
        }

        Sapot.Haptics.playSubtle()
    }

    Timer {
        id: timer

        interval: timeout
        running: true

        onTriggered: {
            if (!root.hovered) {
                root.hidden = true
            }
        }
    }
}
