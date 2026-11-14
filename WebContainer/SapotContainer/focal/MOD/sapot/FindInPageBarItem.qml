import QtQuick 2.12
import Lomiri.Components 1.3

Loader {
    id: findLoader

    property real findInPageMargin: 0
    property string shortcutFindNextText: ""
    property string shortcutFindPreviousText: ""
    property bool wide: false
    property var findController

    signal hidden

    z: 1
    active: false
    asynchronous: true
    height: units.gu(6)
    visible: item && item.shown
    anchors {
        left: parent.left
        right: parent.right
        bottom: parent.bottom
        bottomMargin: -height + findInPageMargin
    }
    
    function show() {
        showAnimation.start()
    }

    function hide() {
        hideAnimation.start()
    }

    NumberAnimation {
        id: showAnimation

        target: findLoader.anchors
        duration: LomiriAnimation.BriskDuration
        easing: LomiriAnimation.StandardEasing
        property: "bottomMargin"
        to: findLoader.findInPageMargin
        onFinished: {
            findLoader.anchors.bottomMargin = Qt.binding( function() { return findLoader.findInPageMargin } )
            if (findLoader.item) {
                findLoader.item.shown = true
                findLoader.item.focusField()
            }
        }
    }

    NumberAnimation {
        id: hideAnimation

        target: findLoader.anchors
        duration: LomiriAnimation.BriskDuration
        easing: LomiriAnimation.StandardEasing
        property: "bottomMargin"
        to: -findLoader.height
        onFinished: {
            findLoader.anchors.bottomMargin = Qt.binding( function() { return -findLoader.height + findLoader.findInPageMargin } )
            if (findLoader.item) {
                findLoader.item.shown = false

                if (findLoader.item.text == "") {
                    findLoader.active = false
                }
            }
        }
    }
    onLoaded: show()

    sourceComponent: FindInPageBar {
        shortcutFindNextText: findLoader.shortcutFindNextText
        shortcutFindPreviousText: findLoader.shortcutFindPreviousText
        wide: findLoader.wide
        findController: findLoader.findController
        onHide: findLoader.hidden()
        Keys.onEscapePressed: findLoader.hidden()
    }
}
