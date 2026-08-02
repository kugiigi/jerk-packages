import QtQuick 2.9
import QtQuick.Controls 2.5 as QQC2
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12

MKBaseDialog {
    id: dialogWithContents

    default property alias data: contentColumn.data
    readonly property real preferredHeight: contentColumn.height + units.gu(12)

    property alias contentSpacing: contentColumn.spacing
    property real contentHorizontalMargin: units.gu(2)
    property bool destroyOnClose: false

    topPadding: units.gu(2)
    bottomPadding: units.gu(2)
    leftPadding: units.gu(2) + contentHorizontalMargin
    rightPadding: units.gu(2) + contentHorizontalMargin
    standardButtons: QQC2.Dialog.NoButton
    height: Math.min(availableVerticalSpace, preferredHeight, parent.height)

    onClosed: if (destroyOnClose) destroy()

    Flickable {
        clip: true
        anchors.fill: parent
        contentHeight: contentColumn.height
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentColumn

            spacing: units.gu(3)
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
        }
    }
}
