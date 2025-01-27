// ENH195 - Battery graph in indicator
import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.SystemSettings.Battery 1.0
import Lomiri.Settings.Menus 0.1 as Menus
import QtQuick.Layouts 1.12
import Powerd 0.1

Item {
    id: root

    property alias primaryBattery: batteryBackend.primaryBattery
    readonly property real lastFullChargeTimeDifference: now - shell.batteryTracking.lastFullChargeDatetime
    readonly property string lastFullChargeFromTrackingLabel: shell.batteryTracking.lastFullChargeDatetime > 0 && lastFullChargeTimeDifference > 0
                                                                    ? shell.batteryTracking.msToTime(lastFullChargeTimeDifference) + " ago"
                                                                    : ""
    property real now: 0

    implicitHeight: layout.height

    function timeDeltaString(timeDelta) {
        var sec = timeDelta,
            min = Math.round (timeDelta / 60),
            hr = Math.round (timeDelta / 3600);
        if (sec < 60)
            // TRANSLATORS: %1 is the number of seconds
            return i18n.tr("%1 second ago", "%1 seconds ago", sec).arg(sec)
        else if (min < 60)
            // TRANSLATORS: %1 is the number of minutes
            return i18n.tr("%1 minute ago", "%1 minutes ago", min).arg(min)
        else
            // TRANSLATORS: %1 is the number of hours
            return i18n.tr("%1 hour ago", "%1 hours ago", hr).arg(hr)
    }

    LomiriBatteryPanel {
        id: batteryBackend
    }

    LiveTimer {
        frequency: Powerd.status === Powerd.On ? LiveTimer.Minute : LiveTimer.Disabled
        onTrigger: {
            canvas.requestPaint()
            root.now = new Date().getTime()
        }
    }

    Connections {
        id: powerConnection
        target: Powerd

        onStatusChanged: {
            if (Powerd.status === Powerd.On) {
                canvas.requestPaint()
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors {
            top: parent.top
            
            left: parent.left
            right: parent.right
        }

        Canvas {
            id: canvas
            
            Layout.fillWidth: true
            Layout.topMargin: units.gu(2)
            Layout.leftMargin: units.gu(2)
            Layout.rightMargin: units.gu(2)
            Layout.preferredHeight: units.gu(23)

            /* Setting that property makes text not correct aliased for
               some reasons, which happens with the value being false or
               true, toolkit bug? see https://launchpad.net/bugs/1354363
            antialiasing: true */

            function drawAxes(ctx, axisWidth, axisHeight, bottomMargin, rightMargin) {

                var currentHour = Qt.formatDateTime(new Date(), "h")
                var currentMinutes = Qt.formatDateTime(new Date(), "m")
                var displayHour
                var labelWidth
                var zeroMark

                ctx.save()
                ctx.beginPath()
                ctx.strokeStyle = theme.palette.normal.foregroundText
                ctx.fillStyle = theme.palette.normal.foregroundText

                ctx.lineWidth = units.dp(2)

                var fontHeight = FontUtils.sizeToPixels("small")
                ctx.font="%1px Ubuntu".arg(fontHeight)

                ctx.translate(0, 1)

                // 11 ticks with 0, 5, 10 being big
                for (var i = 0; i <= 10; i++) {
                    var x = (i % 5 == 0) ? 0 : Math.floor(axisWidth / 2)
                    var y = (i / 10) * (height - axisHeight - bottomMargin - ctx.lineWidth)
                    ctx.moveTo(x, y)
                    ctx.lineTo(axisWidth, y)
                }

                ctx.translate(axisWidth + ctx.lineWidth / 2,
                              height - axisHeight - bottomMargin - ctx.lineWidth / 2)

                ctx.moveTo(0, 0)
                ctx.lineTo(0, -ctx.lineWidth)

                // 24 ticks with 6, 12, 18, 24 being big
                for (i = 0; i <= 24; i++) {
                    /* the marks need to be shifted on the hours */
                    x = ((i - currentMinutes / 60) / 24) * (width - axisWidth - ctx.lineWidth - rightMargin)
                    if (x < 0)
                        continue
                    y = (i % 6 == 0) ? axisHeight : axisHeight -
                                        Math.floor(axisHeight / 2)
                    ctx.moveTo(x, 0)
                    ctx.lineTo(x, y)

                    /* Determine the hour to display */
                    displayHour = (currentHour - (24-i))
                    if (displayHour < 0)
                        displayHour = displayHour + 24
                    /* Store the x for the day change line */
                    if (displayHour === 0)
                        zeroMark = x

                    /* Write the x-axis legend */
                    if (i % 6 == 0) {
                        labelWidth = context.measureText("%1".arg(displayHour)).width;
                        ctx.fillText("%1".arg(displayHour),
                                     x - labelWidth/2,
                                     axisHeight + units.dp(1) + fontHeight)
                    }
                }

                labelWidth = context.measureText(i18n.tr("Yesterday")).width;
                if(labelWidth < zeroMark)
                    ctx.fillText(i18n.tr("Yesterday"),
                                 (zeroMark - labelWidth)/2,
                                 axisHeight + units.dp(6) + 2*fontHeight)

                ctx.fillText("|", zeroMark, axisHeight + units.dp(6) + 2*fontHeight)

                labelWidth = context.measureText(i18n.tr("Today")).width;
                if(labelWidth < (width - zeroMark - rightMargin - axisWidth - ctx.lineWidth))
                    ctx.fillText(i18n.tr("Today"),
                                 zeroMark + (width - zeroMark - labelWidth)/2,
                                 axisHeight + units.dp(6) + 2*fontHeight)

                ctx.stroke()
                ctx.restore()
            }

            onPaint:{
                var ctx = canvas.getContext('2d');
                ctx.save();

                /* Use reset rather than clearRect due to QTBUG-36761 */
                ctx.reset(0, 0, canvas.width, canvas.height)

                var axisWidth = units.gu(1)
                var axisHeight = units.gu(1)

                /* Space to write the legend */
                var bottomMargin = units.gu(6)
                var rightMargin = units.gu(1)

                drawAxes(ctx, axisWidth, axisHeight, bottomMargin, rightMargin)

                /* Display the charge history */
                ctx.beginPath();

                ctx.lineWidth = units.dp(2)

                /* Needed to avoid rendering glitches with point with the same x value
                   (#1461624/QTBUG-34339) */
                ctx.lineJoin = "round"

                ctx.translate(0, height)
                // Invert the y axis so we draw from the bottom left
                ctx.scale(1, -1)
                // Move the origin to just above the axes
                ctx.translate(axisWidth, axisHeight + bottomMargin)
                // Scale to avoid the axes so we can draw as if they aren't
                // there
                ctx.scale(1 - ((axisWidth + rightMargin) / width),
                          1 - (axisHeight + bottomMargin) / height)

                var gradient = ctx.createLinearGradient(0, 0, 0, height);
                gradient.addColorStop(1, "green");
                gradient.addColorStop(0.5, "yellow");
                gradient.addColorStop(0, "red");
                ctx.strokeStyle = gradient

                /* Get infos from battery0, on a day (60*24*24=86400 seconds), with 150 points on the graph.
                 * To ensure we get a valid starting point, we query the values up to two days ago */
                var chargeDatas = primaryBattery.getHistory(86400 * 2, 150)

                /* time is the offset in seconds compared to the current time (negative value)
                   we display the charge on a day, which is 86400 seconds, the value is the % */
                ctx.moveTo((86400 - chargeDatas[0].time) / 86400 * width,
                           (chargeDatas[0].value / 100) * height)
                for (var i = 1; i < chargeDatas.length; i++) {
                    ctx.lineTo((86400-chargeDatas[i].time) / 86400 * width,
                               (chargeDatas[i].value / 100) * height)
                }
                ctx.stroke()
                ctx.restore();
            }
        }

        Menus.EventMenu {
            Layout.fillWidth: true

            highlightWhenPressed: false
            text: {
                if (!primaryBattery)
                    return "";

                if (primaryBattery.state === Battery.Charging)
                    return i18n.tr("Charging now")
                else if (primaryBattery.state === Battery.Discharging)
                    return i18n.tr("Last full charge")
                else if (primaryBattery.state === Battery.FullyCharged)
                    return i18n.tr("Fully charged")
                else
                    return ""
            }
            time: {
                if (primaryBattery && primaryBattery.state === Battery.Discharging) {
                    if (root.lastFullChargeFromTrackingLabel !== "" && shell.settings.enableBatteryStatsIndicator) {
                        return root.lastFullChargeFromTrackingLabel
                    }
                    if (primaryBattery.lastFullCharge)
                        return timeDeltaString(primaryBattery.lastFullCharge)
                    else
                        return i18n.tr("N/A")
                }
                else
                    return ""
            }
            iconSource: {
                if (!primaryBattery)
                    return "";

                if (primaryBattery.state === Battery.Charging)
                    return "image://theme/weather-chance-of-storm"
                else if (primaryBattery.state === Battery.Discharging)
                    return "image://theme/history"
                else if (primaryBattery.state === Battery.FullyCharged)
                    return "image://theme/gpm-battery-charged"
                else
                    return ""
            }

        }
    }
}
