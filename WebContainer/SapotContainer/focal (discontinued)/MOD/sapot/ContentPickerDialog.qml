/*
 * Copyright 2014-2016 Canonical Ltd.
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
import Lomiri.Components 1.3
import Lomiri.Content 1.3
import "MimeTypeMapper.js" as MimeTypeMapper
import "."

BaseContentDialog {
    id: contentPickerDialog

    objectName: "contentPickerDialog"

    property var activeTransfer
    property bool allowMultipleFiles
    property bool accepted: false
    property var contentRequest

    signal accept(var files)

    onOpened: accepted = false
    onAccept: {
        contentRequest.dialogAccept(files)
        close()
    }
    onClosed: {
        if (!accepted) {
            contentRequest.dialogReject()
        }
    }

    headerTitle: i18n.tr("Upload from...")

    function openDialog(_allowMultipleFiles, _request) {
        console.log("Mimetype: " + _request.acceptedMimeTypes)
        let _acceptedMimeTypes = _request.acceptedMimeTypes
        allowMultipleFiles = _allowMultipleFiles
        contentRequest = _request
        if (_acceptedMimeTypes.length === 1) {
            var contentType = MimeTypeMapper.mimeTypeToContentType(_acceptedMimeTypes[0])
            if (contentType == ContentType.Unknown) {
                // If we don't recognise the type, allow uploads from any app
                contentType = ContentType.All
            }
            peerPicker.contentType = contentType
        } else {
            peerPicker.contentType = ContentType.All
        }
        headerSubtitle = i18n.tr("Content type: %1").arg(MimeTypeMapper.mimeTypeListToTypeList(_acceptedMimeTypes, allowMultipleFiles))
        open()
        return this
    }

    QQC2ContentTransferHint {
        anchors.fill: parent
        activeTransfer: contentPickerDialog.activeTransfer
    }

    ContentPeerPicker {
        id: peerPicker

        focus: visible
        contentType: ContentType.All
        handler: ContentHandler.Source
        showTitle: false

        onPeerSelected: {
            if (allowMultipleFiles) {
                peer.selectionType = ContentTransfer.Multiple
            } else {
                peer.selectionType = ContentTransfer.Single
            }
            contentPickerDialog.activeTransfer = peer.request()
            stateChangeConnection.target = contentPickerDialog.activeTransfer
        }

        onCancelPressed: contentPickerDialog.close()
        Keys.onEscapePressed: contentPickerDialog.close()
    }

    Connections {
        id: stateChangeConnection
        target: null
        onStateChanged: {
            if (contentPickerDialog.activeTransfer.state === ContentTransfer.Charged) {
                var selectedItems = []
                for(var i in contentPickerDialog.activeTransfer.items) {
                    
                    // ContentTransfer.Single seems not to be handled properly, e.g. selected items with file manager
                    // -> only select the first item
                    if ((i > 0) && ! allowMultipleFiles)
                    {
                        break;
                    }
                    
                    selectedItems.push(String(contentPickerDialog.activeTransfer.items[i].url).replace("file://", ""))
                }
                contentPickerDialog.accepted = true
                contentPickerDialog.accept(selectedItems)
            }
        }
    }
}
