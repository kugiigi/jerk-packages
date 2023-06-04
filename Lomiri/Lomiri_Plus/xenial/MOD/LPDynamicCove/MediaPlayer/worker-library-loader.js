/*
 * Copyright (C) 2013, 2014
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


WorkerScript.onMessage = function(msg) {
    if (msg.clear === true) {
        msg.model.clear();
        msg.model.sync();
        WorkerScript.sendMessage({});
    } else if (msg.sync === true) {
        msg.model.sync();   // updates the changes to the list
        WorkerScript.sendMessage({"sync": true});
    } else {
        msg.model.append(msg.add);
        WorkerScript.sendMessage({});
    }
}
