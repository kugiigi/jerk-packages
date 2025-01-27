/*
 * Copyright 2012-2013 Canonical Ltd.
 * Copyright 2024 UBports Foundation
 *
 * This file is part of dialer-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * dialer-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
 
import QtQuick 2.4
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.ListItems 1.3 as ListItems

Dialog {
   id: dialog

   property var contact
   signal selectedPhoneNumber(string number)

   ListItems.ItemSelector {
       id: phoneNumberList
       anchors {
           left: parent.left
           right: parent.right
       }
       activeFocusOnPress: false
       expanded: true
       text: contact.displayLabel.label
       model: contact.phoneNumbers
       selectedIndex: -1
       delegate: OptionSelectorDelegate {
           highlightWhenPressed: true
           text: modelData.number
           subText: phoneTypeModel.get(phoneTypeModel.getTypeIndex(modelData)).label
           activeFocusOnPress: false
       }
       onDelegateClicked: selectedPhoneNumber(contact.phoneNumbers[index].number)
   }

   Connections {
       target: __eventGrabber
       onPressed: PopupUtils.close(dialog)
   }
}
