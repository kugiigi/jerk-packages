/*
 * Copyright (C) 2013, 2016
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

// LEGACY Helper for the playlists database
function getPlaylistsDatabase() {
    return LocalStorage.openDatabaseSync("music-app-playlists", "",
                                         "StorageDatabase", 1000000)
}

// CURRENT database for individual playlists - the one witht the actual tracks in
function getPlaylistDatabase() {
    return LocalStorage.openDatabaseSync("music-app-playlist", "",
                                         "StorageDatabase", 1000000)
}

function getPlaylists() {
    // returns playlists with count and 4 covers
    var db = getPlaylistDatabase()
    var res = []

	// Add item for all songs
	res.push({"name": "All songs", "count": 0});

    try {
        db.readTransaction(function (tx) {
            var rs = tx.executeSql('SELECT * FROM playlist ORDER BY name COLLATE NOCASE;')

            for (var i = 0; i < rs.rows.length; i++) {
                var dbItem = rs.rows.item(i)
                var itemCount = getPlaylistCount(dbItem.name, tx)

				// Exclude playlists with no tracks
				if (itemCount > 0) {
					res.push({
								 name: dbItem.name,
								 count: itemCount
							 })
				}
            }
        })
    } catch (e) {
        return res
    }

    return res
}

function decodeFileURI(filename)
{
	var newFilename = "";
	try {
		newFilename = decodeURIComponent(filename);
	} catch (e) {
		newFilename = filename;
		console.log("Unicode decoding error:", filename, e.message)
	}

	return newFilename;
}

function getPlaylistTracks(playlist) {
    var db = getPlaylistDatabase()
    var j
    var res = []

    var erroneousTracks = [];

    try {
        db.readTransaction(function (tx) {
            var rs = tx.executeSql('SELECT * FROM track WHERE playlist=?;',
                                   [playlist])
		    console.log("Length: " + rs.rows.length)
            for (j = 0; j < rs.rows.length; j++) {
                var dbItem = rs.rows.item(j)

                // ms2 doesn't expect the URI scheme so strip file://
                if (dbItem.filename.indexOf("file://") === 0) {
                    dbItem.filename = dbItem.filename.substr(7);
                }

                if (mediaPlayerObj.musicStore.lookup(decodeFileURI(dbItem.filename)) === null) {
                    erroneousTracks.push(dbItem.i);
                } else {
                    res.push({
                                 i: dbItem.i,
                                 filename: dbItem.filename,
                                 title: dbItem.title,
                                 author: dbItem.author,
                                 album: dbItem.album,
                                 art: mediaPlayerObj.musicStore.lookup(decodeFileURI(dbItem.filename)).art
                             })
                }
            }
        })
    } catch (e) {
        return []
    }

    if (erroneousTracks.length > 0) {  // reget data as indexes are out of sync
        res = getPlaylistTracks(playlist)
    }

    return res
}

function getPlaylistCount(playlist, tx) {
    var rs = 0;

    if (tx === undefined) {
        var db = getPlaylistDatabase()

        db.readTransaction(function (tx) {
            rs = getPlaylistCount(playlist, tx)
        });
    }
    else {
        try {
            rs = tx.executeSql('SELECT * FROM track WHERE playlist=?;',
                                [playlist]).rows.length
        } catch (e) {
            return rs
        }
    }

    return rs
}

function getPlaylistCovers(playlist, max) {
    var db = getPlaylistDatabase()
    var res = []

    // Get a list of unique covers for the playlist
    try {
        db.readTransaction(function (tx) {
            var rs = tx.executeSql("SELECT * FROM track WHERE playlist=?;",
                                   [playlist])

            for (var i = 0; i < rs.rows.length
                 && i < (max || rs.rows.length); i++) {
                if (mediaPlayerObj.musicStore.lookup(decodeFileURI(rs.rows.item(i).filename)) !== null) {
                    var row = {
                        author: rs.rows.item(i).author,
                        album: rs.rows.item(i).album,
                        art: mediaPlayerObj.musicStore.lookup(decodeFileURI(rs.rows.item(i).filename)).art
                    }

                    if (find(res, row) === null) {
                        res.push(row)
                    }
                }
            }
        })
    } catch (e) {
        return []
    }

    return res
}

function find(arraytosearch, object) {

    for (var i = 0; i < arraytosearch.length; i++) {

        if (arraytosearch[i]["author"] == object["author"] &&
            arraytosearch[i]["album"] == object["album"]) {
            return i;
        }
    }
    return null;
}
