import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12 as QQC2

Rectangle {
    id: rootRec

    readonly property int startDelay: 2000
    property bool dismissEnabled: true

    readonly property var sequence: [
        { text: i18n.tr("CNXSoft init script entered"), interval: 400 }
        , { text: i18n.tr("\nDHCP[    5.365558@3] netdev_open"), interval: 50 }
        , { text: i18n.tr("\n[    5.365579@3] Ethernet reset"), interval: 200 }
        , { text: i18n.tr("\n[    5.368408@3] NET MDA descpter start addr=ec953000"), interval: 60 }
        , { text: i18n.tr("\n[    5.373472@3] aml_phy_init:  trying to attach to 0:00 "), interval: 1200 }
        , { text: i18n.tr("\n[    5.378528@3] --1--write mac add to:ed1e4f08: 6e 36 3d 06 44 bb |n6=.D.|     \n \
[    5.384880@3] name=nand_key nand_key                                         \n \
[    5.388864@3] register_aes_algorithm:488,new way                             \n \
[    5.393174@3] unkown current key-name,key_read_show:1442                     \n \
[    5.398314@3] ret = -22                                                      \n \
[    5.398314@3] print_buff=                                                    \n \
[    5.403347@3] --2--write mac add to:ed1e4f08: 6e 36 3d 06 44 bb |n6=.D.|     \n \
[    5.410015@3] write mac add to:ed1e4f08: 6e 36 3d 06 44 bb |n6=.D.|          \n \
[    5.416258@3] Current DMA mode=0, set mode=621c100"), interval: 400 }
        , { text: i18n.tr("\n[    5.421170@3] ether leave promiscuous mode"), interval: 200 }
        , { text: i18n.tr("\n[    5.425098@3] ether leave all muticast mode                                  \n \
[    5.429263@3] changed the Multicast,mcount=1                                 \n \
[    5.433509@3] add mac address:33:33:00:00:00:01,bit=1                        \n \
[    5.438534@3] set hash low=2,high=0                                          \n \
[    5.442005@3] changed the filter setting to :4                               \n \
[    5.446426@3] changed the Multicast,mcount=1                                 \n \
[    5.450674@3] add mac address:33:33:00:00:00:01,bit=1                        \n \
[    5.455845@3] changed the Multicast,mcount=2                                 \n \
[    5.459950@3] add mac address:33:33:00:00:00:01,bit=1                        \n \
[    5.464973@3] add mac address:01:00:5e:00:00:01,bit=32                       \n \
[    5.470089@3] set hash low=2,high=1                                          \n \
[    5.473553@3] changed the filter setting to :4                               \n \
[    5.477981@3] IPv6: ADDRCONF(NETDEV_UP): eth0: link is not ready"), interval: 60 }
        , { text: i18n.tr("\n...                                                                             \n\
udhcpc (v1.19.4) started                                                        \n\
Sending discover..."), interval: 500 }
        , { text: i18n.tr("\n[    5.899068@3] aml audio hp unpluged                                          \n \
[    6.102494@0] switch_vpu_mem_pd: viu_vd1 OFF                                 \n \
[    6.102518@0] switch_vpu_mem_pd: di_post OFF                                 \n \
[    6.105369@0] switch_vpu_mem_pd: viu_vd2 OFF                                 \n \
[    6.109617@0] switch_vpu_mem_pd: pic_rot2 OFF                                \n \
[    6.113951@0] switch_vpu_mem_pd: pic_rot3 OFF                                \n \
[    6.289300@3] ========  temp=29                                              \n \
[    6.462106@3] [RN5T618]battery vol change: 0->0                              \n \
[    7.289179@3] ========  temp=30                                              \n \
[    8.289180@3] ========  temp=30                                              \n \
Sending discover...                                                             \n \
[    9.289299@3] ========  temp=30                                              \n \
[    9.369188@3] libphy: 0:00 - Link is Up - 100/Full                           \n \
[    9.369221@3] IPv6: ADDRCONF(NETDEV_CHANGE): eth0: link becomes ready        \n \
[    9.374788@3] changed the Multicast,mcount=3                                 \n \
[    9.378999@3] add mac address:33:33:00:00:00:01,bit=1                        \n \
[    9.384032@3] add mac address:01:00:5e:00:00:01,bit=32                       \n \
[    9.389144@3] add mac address:33:33:ff:06:44:bb,bit=3                        \n \
[    9.394166@3] set hash low=a,high=1                                          \n \
[    9.397634@3] changed the filter setting to :4                               \n \
[   10.289182@3] ========  temp=30                                              \n \
[   11.289178@3] ========  temp=31                                              \n \
Sending discover...                                                             \n \
[   12.289180@3] ========  temp=31                                              \n \
Sending select for 192.168.0.106...                                             \n \
Lease of 192.168.0.106 obtained, lease time 7200                                \n \
[   12.961997@0] changed the Multicast,mcount=3                                 \n \
[   12.962078@0] add mac address:33:33:00:00:00:01,bit=1                        \n \
[   12.967125@0] add mac address:01:00:5e:00:00:01,bit=32                       \n \
[   12.972241@0] add mac address:33:33:ff:06:44:bb,bit=3                        \n \
deleting routers                                                                \n \
route: SIOCDELRT: No such process                                               \n \
adding dns 192.168.0.1                                                          \n \
 \n \
Mounting NFS rootfs...                                                          \n \
Switching root...                                                               \n \
[   13.289196@3] ========  temp=31                                              \n \
[   14.289202@3] ========  temp=31                                              \n \
[   14.344976@1] udevd[134]: starting version 182                               \n \
[   15.186849@0] FAT-fs (sda1): Volume was not properly unmounted. Some data ma.\n \
[   15.289325@3] ========  temp=33                                              \n \
[   16.289202@3] ========  temp=32"), interval: 60 }
        //, { text: i18n.tr("\n"), interval: 60 }
    ]


    signal close

    color: "black"

    // Eat mouse events when taphandler is disabled
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onWheel: wheel.accepted = true;
    }
    
    Component.onCompleted: {
        startDelayTimer.restart()
    }

    Timer {
        id: startDelayTimer
        interval: rootRec.startDelay
        onTriggered: textDelayTimer.processText()
    }

    Timer {
        id: endDelayTimer
        interval: 1000
        onTriggered:  { /* Do nothing for now */ }
    }

    Timer {
        id: textDelayTimer

        property string textToAdd: ""
        property int textCount: 0

        function processText() {
            let _obj = rootRec.sequence[textCount]
            textToAdd = _obj.text
            textCount += 1
            interval = _obj.interval
            restart()
        }

        onTriggered: {
            textArea.text += textToAdd
            if (textCount < rootRec.sequence.length) {
                textDelayTimer.processText()
            } else {
                textToAdd = ""
                textCount = 0
                endDelayTimer.restart()
            }
        }
    }

    Flickable {
        id: flickable

        anchors.fill: parent
        anchors.margins: units.gu(2)
        contentHeight: textArea.height
        contentY: contentHeight > height ? contentHeight - height : 0
        interactive: false

        QQC2.TextArea {
            id: textArea

            // For quick testing only
            property int size: 3
            /*
             * 0 - Small
             * 1 - Medium
             * 2 - Large
             */

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            inputMethodHints: Qt.ImhNoPredictiveText
            font.pixelSize: {
                switch(textArea.size) {
                    case 0:
                        return units.gu(1.5)
                    case 1:
                        return units.gu(2)
                    case 2:
                        return units.gu(2.5)
                    default:
                        return units.gu(1.7)
                }
            }
            focus: false
            readOnly: true
            cursorVisible: true
            cursorPosition: text.length
            hoverEnabled: false
            background: Item{}
            verticalAlignment: Text.AlignTop
            font.family: "Ubuntu Mono"
            wrapMode: TextEdit.WordWrap

            Rectangle {
                id: cursor

                property bool show: true
                visible: opacity > 0
                opacity: show ? 1 : 0
                color: "white"
                width: {
                    switch(textArea.size) {
                        case 0:
                            return units.gu(1.2)
                        case 1:
                            return units.gu(1.6)
                        case 2:
                            return units.gu(2)
                        default:
                            return units.gu(1.4)
                    }
                }
                height: textArea.cursorRectangle.height * 0.15
                x: textArea.cursorRectangle.x + units.dp(2)
                y: textArea.cursorRectangle.y + (textArea.cursorRectangle.height - height)

                Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration } }

                Timer {
                    interval: 500
                    running: true
                    repeat: true
                    onTriggered: {
                        cursor.show = !cursor.show
                    }
                }
            }

            TapHandler {
                enabled: rootRec.dismissEnabled
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onLongPressed: {
                    rootRec.close()
                    Haptics.play()
                }

                onSingleTapped: {
                    if ((eventPoint.event.device.pointerType === PointerDevice.Cursor || eventPoint.event.device.pointerType == PointerDevice.GenericPointer)
                            && eventPoint.event.button === Qt.RightButton) {
                        rootRec.close()
                    }
                }
            }
        }
    }
}
