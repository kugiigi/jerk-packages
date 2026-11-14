import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2
import QtWebEngine 1.5
import QtQuick.Layouts 1.12
import "TextUtils.js" as TextUtils

DialogWithContents {
    id: confirmDialog

    property string text: i18n.tr("Are you sure you want to proceed?")

    signal confirm

    modal: true
    dim: true

    onConfirm: close()

    QQC2.Label {
        Layout.fillWidth: true

        text: confirmDialog.text
        wrapMode: Text.WordWrap
    }

    ColumnLayout {
        spacing: units.gu(2)
        Layout.fillWidth: true

        Button {

            Layout.fillWidth: true
            text: i18n.tr("Confirm")
            color: theme.palette.normal.positive

            onClicked: confirmDialog.confirm()
        }

        Button {
            Layout.fillWidth: true

            text: i18n.tr("Cancel")
            onClicked: confirmDialog.close();
        }
    }
}
