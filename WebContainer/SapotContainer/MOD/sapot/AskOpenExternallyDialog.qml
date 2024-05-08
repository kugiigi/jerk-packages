import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Controls 2.12 as QQC2
import QtWebEngine 1.5
import QtQuick.Layouts 1.12
import "TextUtils.js" as TextUtils

DialogWithContents {
    id: openExternallyDialog

    property url url
    
    readonly property string elidedUrl: TextUtils.elideText(url, 200)

    signal confirm

    modal: true
    dim: true

    onConfirm: close()

    title: i18n.tr("External Link")

    QQC2.Label {
        Layout.fillWidth: true

        text: i18n.tr("You are trying to open an external link. Open link outside this app?")
        wrapMode: Text.WordWrap
    }

    QQC2.Label {
        Layout.fillWidth: true

        text: openExternallyDialog.elidedUrl
        verticalAlignment: Label.AlignVCenter
        horizontalAlignment: Label.AlignHCenter
        wrapMode: Text.WordWrap
    }

    ColumnLayout {
        spacing: units.gu(2)
        Layout.fillWidth: true

        Button {

            Layout.fillWidth: true
            text: i18n.tr("Allow")
            color: theme.palette.normal.positive

            onClicked: openExternallyDialog.confirm()
        }

        Button {
            Layout.fillWidth: true

            text: i18n.tr("Deny")
            color: theme.palette.normal.negative
            onClicked: openExternallyDialog.close();
        }
    }
}
