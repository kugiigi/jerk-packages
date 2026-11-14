// ENH156 - Advanced snapping keyboard shortcuts
import QtQuick 2.12
import Lomiri.Components 1.3

Item {
    id: root

    readonly property alias active: d.active
    property bool advancedSnapping: false
    property var target // FakeMaximizeDelegate
    property var focusedAppDelegate
    property bool initialShow: true
    property bool enableTopBottom: false

    visible: active

    function showRestore() {
        show();
        target.restore(d.pushValue, true)
    }
    function showMinimize() {
        show();
        target.minimize(d.pushValue, true)
    }
    function showMaximize() {
        show();
        target.maximize(d.pushValue, true);
    }
    function showMaximizeTop() {
        show();
        target.maximizeTop(d.pushValue, true);
    }
    function showMaximizeBottom() {
        show();
        target.maximizeBottom(d.pushValue, true);
    }
    function showMaximizeLeft() {
        show();
        target.maximizeLeft(d.pushValue, true);
    }
    function showMaximizeRight() {
        show();
        target.maximizeRight(d.pushValue, true);
    }
    function showMaximizeTopLeft() {
        show();
        target.maximizeTopLeft(d.pushValue, true);
    }
    function showMaximizeTopRight() {
        show();
        target.maximizeTopRight(d.pushValue, true);
    }
    function showMaximizeBottomLeft() {
        show();
        target.maximizeBottomLeft(d.pushValue, true);
    }
    function showMaximizeBottomRight() {
        show();
        target.maximizeBottomRight(d.pushValue, true);
    }

    function show() {
        d.metaPressed = true;
        d.ctrlPressed = true;
        d.active = true;
        d.shown = true;
        focus = true;
    }

    QtObject {
        id: d

        readonly property real pushValue: 1
        property bool active: false
        property bool shown: false
        property bool metaPressed: false
        property bool ctrlPressed: false

        function snapToLeft() {
            root.initialShow = false
            let _willBeMaximizedTopLeft = root.enableTopBottom
                                                ? root.focusedAppDelegate && root.target.maximizedTop && root.focusedAppDelegate.canBeCornerMaximized
                                                : root.focusedAppDelegate && root.target.maximizedTopRight && root.focusedAppDelegate.canBeCornerMaximized
            let _willBeMaximizedBottomLeft = root.enableTopBottom
                                                ? root.focusedAppDelegate && root.target.maximizedBottom && root.focusedAppDelegate.canBeCornerMaximized
                                                : root.focusedAppDelegate && root.target.maximizedBottomRight && root.focusedAppDelegate.canBeCornerMaximized
            let _willBeMaximizedLeft = root.focusedAppDelegate && (root.target.maximized || !root.target.anyMaximized)
                                                            && root.focusedAppDelegate.canBeMaximizedLeftRight
            let _willBeMaximizedTop = root.enableTopBottom
                                            && root.focusedAppDelegate && root.focusedAppDelegate.canBeMaximizedHorizontally
                                            && root.target.maximizedTopRight
            let _willBeMaximizedBottom = root.enableTopBottom
                                            && root.focusedAppDelegate && root.focusedAppDelegate.canBeMaximizedHorizontally
                                            && root.target.maximizedBottomRight
            let _willBeRestored = root.focusedAppDelegate && root.target.maximizedRight

            if (root.advancedSnapping) {
                if (_willBeMaximizedTop) {
                    root.target.maximizeTop(d.pushValue, true)
                } else if (_willBeMaximizedBottom) {
                    root.target.maximizeBottom(d.pushValue, true)
                } else if (_willBeMaximizedTopLeft) {
                    root.target.maximizeTopLeft(d.pushValue, true)
                } else if (_willBeMaximizedBottomLeft) {
                    root.target.maximizeBottomLeft(d.pushValue, true)
                } else if (_willBeMaximizedLeft) {
                    root.target.maximizeLeft(d.pushValue, true)
                } else if (_willBeRestored) {
                    root.target.restore(d.pushValue, true)
                }
            } else {
                root.target.maximizeLeft(d.pushValue, true)
            }
        }
        function snapToRight() {
            root.initialShow = false
            let _willBeMaximizedTopRight = root.enableTopBottom
                                                ? root.focusedAppDelegate && root.target.maximizedTop && root.focusedAppDelegate.canBeCornerMaximized
                                                : root.focusedAppDelegate && root.target.maximizedTopLeft && root.focusedAppDelegate.canBeCornerMaximized
            let _willBeMaximizedBottomRight = root.enableTopBottom
                                                ? root.focusedAppDelegate && root.target.maximizedBottom && root.focusedAppDelegate.canBeCornerMaximized
                                                : root.focusedAppDelegate && root.target.maximizedBottomLeft && root.focusedAppDelegate.canBeCornerMaximized
            let _willBeMaximizedRight = root.focusedAppDelegate && (root.target.maximized || !root.target.anyMaximized)
                                                            && root.focusedAppDelegate.canBeMaximizedLeftRight
            let _willBeMaximizedTop = root.enableTopBottom
                                        && root.focusedAppDelegate && root.focusedAppDelegate.canBeMaximizedHorizontally
                                        && root.target.maximizedTopLeft
            let _willBeMaximizedBottom = root.enableTopBottom
                                            && root.focusedAppDelegate && root.focusedAppDelegate.canBeMaximizedHorizontally
                                            && root.target.maximizedBottomLeft
            let _willBeRestored = root.focusedAppDelegate && root.target.maximizedLeft

            if (root.advancedSnapping) {
                if (_willBeMaximizedTop) {
                    root.target.maximizeTop(d.pushValue, true)
                } else if (_willBeMaximizedBottom) {
                    root.target.maximizeBottom(d.pushValue, true)
                } else if (_willBeMaximizedTopRight) {
                    root.target.maximizeTopRight(d.pushValue, true)
                } else if (_willBeMaximizedBottomRight) {
                    root.target.maximizeBottomRight(d.pushValue, true)
                } else if (_willBeMaximizedRight) {
                    root.target.maximizeRight(d.pushValue, true)
                } else if (_willBeRestored) {
                    root.target.restore(d.pushValue, true)
                }
            } else {
                root.target.maximizeRight(d.pushValue, true)
            }
        }
        function snapToTop() {
            root.initialShow = false
            let _willBeMaximized = root.focusedAppDelegate && root.focusedAppDelegate.canBeMaximized
            let _willBeRestored = root.enableTopBottom
                                    ? root.focusedAppDelegate && (root.target.maximizedBottom
                                                                    || root.target.minimized)
                                    : root.focusedAppDelegate && root.target.minimized
            let _willBeMaximizedTopRight = root.focusedAppDelegate && root.target.maximizedRight && root.focusedAppDelegate.canBeCornerMaximized
            let _willBeMaximizedTopLeft = root.focusedAppDelegate && root.target.maximizedLeft && root.focusedAppDelegate.canBeCornerMaximized
            let _willBeMaximizedRight = root.focusedAppDelegate && root.target.maximizedBottomRight && root.focusedAppDelegate.canBeMaximizedLeftRight
            let _willBeMaximizedLeft = root.focusedAppDelegate && root.target.maximizedBottomLeft && root.focusedAppDelegate.canBeMaximizedLeftRight
            let _willBeMaximizedTop = root.enableTopBottom && root.focusedAppDelegate && root.focusedAppDelegate.canBeMaximizedHorizontally
                                            && !root.target.anyMaximized && !root.target.minimized

            if (root.advancedSnapping) {
                if (_willBeMaximizedTopRight) {
                    root.target.maximizeTopRight(d.pushValue, true)
                } else if (_willBeMaximizedTopLeft) {
                    root.target.maximizeTopLeft(d.pushValue, true)
                } else if (_willBeMaximizedRight) {
                    root.target.maximizeRight(d.pushValue, true)
                } else if (_willBeMaximizedLeft) {
                    root.target.maximizeLeft(d.pushValue, true)
                } else if (_willBeMaximizedTop) {
                    root.target.maximizeTop(d.pushValue, true)
                } else if (_willBeRestored) {
                    root.target.restore(d.pushValue, true)
                } else {
                    root.target.maximize(d.pushValue, true)
                }
            } else {
                root.target.maximize(d.pushValue, true)
            }
        }
        function snapToBottom() {
            root.initialShow = false
            let _willBeRestored = root.enableTopBottom
                                    ? root.focusedAppDelegate && (root.target.maximizedTop
                                                                    || root.target.maximizedBottomRight
                                                                    || root.target.maximizedBottomLeft)
                                    : root.focusedAppDelegate
                                        && (root.target.maximized || root.target.maximizedBottomRight || root.target.maximizedBottomLeft)
            let _willBeMinimized = root.enableTopBottom
                                    ? root.focusedAppDelegate && (root.target.maximizedBottom
                                                                    || !root.target.anyMaximized)
                                    : root.focusedAppDelegate && !root.target.anyMaximized
            let _willBeMaximizedBottomRight = root.focusedAppDelegate && root.target.maximizedRight && root.focusedAppDelegate.canBeCornerMaximized
            let _willBeMaximizedBottomLeft = root.focusedAppDelegate && root.target.maximizedLeft && root.focusedAppDelegate.canBeCornerMaximized
            let _willBeMaximizedRight = root.focusedAppDelegate && root.target.maximizedTopRight && root.focusedAppDelegate.canBeMaximizedLeftRight
            let _willBeMaximizedLeft = root.focusedAppDelegate && root.target.maximizedTopLeft && root.focusedAppDelegate.canBeMaximizedLeftRight
            let _willBeMaximizedTop = root.enableTopBottom
                                        && root.focusedAppDelegate && root.focusedAppDelegate.canBeMaximizedHorizontally
                                        && root.target.maximized
            let _willBeMaximizedBottom = root.enableTopBottom
                                            && root.focusedAppDelegate && root.focusedAppDelegate.canBeMaximizedHorizontally
                                            && !root.target.anyMaximized

            if (root.advancedSnapping) {
                if (_willBeMaximizedTop) {
                    root.target.maximizeTop(d.pushValue, true)
                } else if (_willBeMaximizedBottom) {
                    root.target.maximizeBottom(d.pushValue, true)
                } else if (_willBeMaximizedBottomRight) {
                    root.target.maximizeBottomRight(d.pushValue, true)
                } else if (_willBeMaximizedBottomLeft) {
                    root.target.maximizeBottomLeft(d.pushValue, true)
                } else if (_willBeMaximizedRight) {
                    root.target.maximizeRight(d.pushValue, true)
                } else if (_willBeMaximizedLeft) {
                    root.target.maximizeLeft(d.pushValue, true)
                } else if (_willBeRestored) {
                    root.target.restore(d.pushValue, true)
                } else if (_willBeMinimized) {
                    root.target.minimize(d.pushValue, true)
                }
            } else {
                if (root.target.anyMaximized) {
                    root.target.restore(d.pushValue, true)
                } else {
                    root.target.minimize(d.pushValue, true)
                }
            }
        }
    }

    Keys.onPressed: {
        switch (event.key) {
        case Qt.Key_Left:
            d.snapToLeft();
            break;
        case Qt.Key_Right:
            d.snapToRight()
            break;
        case Qt.Key_Up:
            d.snapToTop();
            break;
        case Qt.Key_Down:
            d.snapToBottom();
        }
    }
    Keys.onReleased: {
        switch (event.key) {
        case Qt.Key_Meta:
        case Qt.Key_Super_R:
        case Qt.Key_Super_L:
            d.metaPressed = false;
            break;
        case Qt.Key_Control:
            d.ctrlPressed = false;
            break;
        }

        if (!d.metaPressed && !d.ctrlPressed) {
            d.active = false;
            focus = false;
            d.shown = false;
            root.target.commit()
            root.initialShow = true
        }
    }
}
