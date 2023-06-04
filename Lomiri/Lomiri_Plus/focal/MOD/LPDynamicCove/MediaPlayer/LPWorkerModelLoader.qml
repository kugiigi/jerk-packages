/*
 * Copyright (C) 2014, 2015
 *      Andrew Hayzen <ahayzen@gmail.com>
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


WorkerScript {
     id: worker
     source: "worker-library-loader.js"

     property bool canLoad: true
     property bool completed: false
     property int i: 0
     property var list
     property var model
     property bool preLoadComplete: false
     property int processing: 0
     property int syncFactor: 5

     onCanLoadChanged: {
         /* If canLoad has been set back to true then check if there are any
           remaining items to load in the model */
         if (canLoad && list !== undefined && !completed) {
             process();
         }

         if (!canLoad && i !== 0) {  // sync any pending changes when canLoad changes
             sync()
         }
     }

     onListChanged: {
         reset();
         clear();
     }

     onMessage: {
         if (messageObject.sync === true) {
             if (list !== undefined && i >= list.length) {  // if synced check if list now complete
                 completed = true
             }

             processing--;

             return;  // do not continue from a sync 'pong' only from a process/clear
         }

         if (i === 0) {
             preLoadComplete = true;
         }

         if (canLoad && i % syncFactor === 0 && i !== 0) {
             sync();
         }

         if (canLoad) {  // pause if the model is not allowed to load
             process();
         }

         if (i === 1) {  // sync after the first item to prevent empty states
             sync()
         }

         processing--;  // minus at end to cause count to go 1->2->1 not 1->0->1
     }

     function clear() {
         if (list !== undefined) {
             processing++
             sendMessage({'clear': true, 'model': model})
         }
     }

     // Add the next item in the list to the model otherwise set complete
     function process()
     {
         if (i < list.length) {
             processing++;
             sendMessage({'add': list[i], 'model': model});
             i++;
         } else {
             sync()
         }
     }

     function reset()
     {
         i = 0;
         completed = false;
     }

     function sync()
     {
         processing++;
         sendMessage({'sync': true, 'model': model});
     }
}
