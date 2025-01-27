/*
 * Copyright 2024 UBports Foundation
 *
 * This file is part of lomiri-dialer-app.
 *
 * lomiri-dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * lomiri-dialer-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.3 as ListItems
import QtContacts 5.0
import Lomiri.Contacts 0.1

GridView {
    id: favoritesGridView

    signal contactSelected(var contact)

    cellWidth: width / (Math.floor(width / units.gu(20)))
    cellHeight: units.gu(10)
    snapMode: GridView.SnapToRow
    clip: true

    header: Item {
        width: parent ? parent.width : undefined
        height: childrenRect.height

        Column {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: units.gu(2)
                rightMargin: units.gu(2)
            }

            Label {
                text: i18n.tr("Favorites")
                height: units.gu(4)
                textSize: Label.Medium
                verticalAlignment: Text.AlignVCenter
            }

            ListItems.ThinDivider {}
        }
    }

    model: ContactListModel {
        id: contactsModel

        onlyFavorites: true
        manager: ContactManager.manager()
        sortOrders: [
            SortOrder {
                detail: ContactDetail.Tag
                field: Tag.Tag
                direction: Qt.AscendingOrder
                blankPolicy: SortOrder.BlanksLast
                caseSensitivity: Qt.CaseInsensitive
            },
            // empty tags will be sorted by display Label
            SortOrder {
                detail: ContactDetail.DisplayLabel
                field: DisplayLabel.Label
                direction: Qt.AscendingOrder
                blankPolicy: SortOrder.BlanksLast
                caseSensitivity: Qt.CaseInsensitive
            }
        ]

        fetchHint: FetchHint {
            detailTypesHint: [
                ContactDetail.DisplayLabel,
                ContactDetail.PhoneNumber,
                ContactDetail.Email,
                ContactDetail.Name,
                ContactDetail.Avatar,
                ContactDetail.Tag
            ]
        }
    }

    delegate: Item {
        width: GridView.view.cellWidth
        height: GridView.view.cellHeight

        ContactDelegate {
            id: contactDelegate

            flicking: favoritesGridView.flicking
            anchors.fill: parent
            defaultAvatarUrl: "image://theme/contact"
            isCurrentItem: ListView.isCurrentItem

            onClicked: {
                favoritesGridView.contactSelected(contact)
            }
        }
    }
}
