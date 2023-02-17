/*
 * Copyright (C) 2013, 2014, 2015
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Daniel Holm <d.holmen@gmail.com>
 *      Victor Thompson <victor.thompson@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtQuick.LocalStorage 2.0
import "playlists.js" as Playlists

Item {
    id: libraryListModelItem
    property alias count: libraryModel.count
    property ListModel model : ListModel {
        id: libraryModel
        property var linkLibraryListModel: libraryListModelItem
    }
    property var param: null
    property var query: null
    /* Pretent to be like a mediascanner2 listmodel */
    property alias rowCount: libraryModel.count

    property alias canLoad: worker.canLoad
    property alias preLoadComplete: worker.preLoadComplete
    property alias syncFactor: worker.syncFactor
    property alias workerComplete: worker.completed
    property alias workerList: worker.list

    function get(index, role) {
        return model.get(index);
    }

    LPWorkerModelLoader {
        id: worker
        model: libraryListModelItem.model
    }

    function indexOf(file)
    {
        file = file.toString();

        if (file.indexOf("file://") == 0)
        {
            file = file.slice(7, file.length)
        }

        for (var i=0; i < model.count; i++)
        {
            if (model.get(i).file == file)
            {
                return i;
            }
        }

        return -1;
    }

    function filterPlaylists() {
        // Save query for queue
        query = Playlists.getPlaylists
        param = null

        // Set syncFactor to the default and set the list to populate
        worker.syncFactor = 5
        worker.list = Playlists.getPlaylists();
    }

    function filterPlaylistTracks(playlist) {
        // Save query for queue
        query = Playlists.getPlaylistTracks
        param = playlist

        // Set syncFactor to 500 to get the worker to fetch many items at once and
        // set the list to populate
        worker.syncFactor = 500
        worker.list = Playlists.getPlaylistTracks(playlist);
    }
}
