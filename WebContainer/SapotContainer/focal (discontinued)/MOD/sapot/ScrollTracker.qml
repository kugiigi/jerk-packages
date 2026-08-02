/*
 * Copyright 2014 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4

Item {
    id: scrollTracker

    property var webview
    property var header

    readonly property bool nearTop: webview ? (webview.scrollPosition.y / webview.scaleFactor) < header.height : false
    readonly property bool nearBottom: webview ? ((webview.contentsSize.height - webview.scrollPosition.y) / webview.scaleFactor - webview.height) < header.height : false

    property bool active: true
    property bool scrollingUp: true

    signal scrolledUp()
    signal scrolledDown()

    onScrolledUp: scrollingUp = true
    onScrolledDown: scrollingUp = false

    enabled: false
    visible: false
    
    onWebviewChanged: {
        scrollingUp = true
        internal.previousScrollPositionY = webview ? webview.scrollPosition.y : 0
    }

    QtObject {
        id: internal

        property real previousScrollPositionY: 0.0
    }

    Connections {
        target: scrollTracker.active ? scrollTracker.webview : null
        onScrollPositionChanged: {
            if (header.moving) {
                return;
            }

            if (scrollTracker.webview.scrollPosition.y === internal.previousScrollPositionY) {
                return;
            }

            var oldScrollPosition = internal.previousScrollPositionY;
            if (Math.abs(internal.previousScrollPositionY - scrollTracker.webview.scrollPosition.y) / webview.scaleFactor > units.gu(6)) {
                internal.previousScrollPositionY = scrollTracker.webview.scrollPosition.y;
            }

            if (internal.previousScrollPositionY < oldScrollPosition) {
                 scrollTracker.scrolledUp()
            } else if (internal.previousScrollPositionY > oldScrollPosition) {
                 scrollTracker.scrolledDown()
            }
        }
    }
}
