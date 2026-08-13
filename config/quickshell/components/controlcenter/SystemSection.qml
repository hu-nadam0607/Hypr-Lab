import QtQuick
import Quickshell.Io

Item {
    id: root

    property string cpu: "--"
    property string ram: "--"
    property string uptime: "--"
    property bool active: true
    implicitHeight: 58

    function refresh() {
        if (!statsProc.running)
            statsProc.running = true
    }

    Process {
        id: statsProc
        command: [
            "sh", "-c",
            "read _ u1 n1 s1 i1 w1 irq1 sirq1 st1 _ < /proc/stat; " +
            "t1=$((u1+n1+s1+i1+w1+irq1+sirq1+st1)); id1=$((i1+w1)); " +
            "sleep 0.20; " +
            "read _ u2 n2 s2 i2 w2 irq2 sirq2 st2 _ < /proc/stat; " +
            "t2=$((u2+n2+s2+i2+w2+irq2+sirq2+st2)); id2=$((i2+w2)); " +
            "dt=$((t2-t1)); did=$((id2-id1)); " +
            "if [ $dt -gt 0 ]; then cpu=$((100*(dt-did)/dt)); else cpu=0; fi; " +
            "ram=$(awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2} END {if(t>0) printf \"%.0f\",100*(t-a)/t; else print 0}' /proc/meminfo); " +
            "up=$(awk '{s=int($1); h=int(s/3600); m=int((s%3600)/60); if(h>0) printf \"%dh %02dm\",h,m; else printf \"%dm\",m}' /proc/uptime); " +
            "printf '%s|%s|%s\\n' \"$cpu\" \"$ram\" \"$up\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|")
                if (parts.length >= 3) {
                    root.cpu = parts[0] + "%"
                    root.ram = parts[1] + "%"
                    root.uptime = parts[2]
                }
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Column {
        anchors.fill: parent
        spacing: 8

        Text {
            text: "SYSTEM"
            color: Qt.rgba(190/255, 205/255, 210/255, 0.52)
            font.family: "Inter"
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 1.6
        }

        Row {
            width: parent.width
            spacing: 8

            Repeater {
                model: [
                    { icon: "󰍛", name: "CPU", value: root.cpu },
                    { icon: "󰘚", name: "RAM", value: root.ram },
                    { icon: "󰔏", name: "UP", value: root.uptime }
                ]

                Rectangle {
                    required property var modelData
                    width: (parent.width - 16) / 3
                    height: 32
                    radius: 16
                    color: Qt.rgba(1,1,1,0.035)
                    border.width: 1
                    border.color: Qt.rgba(1,1,1,0.05)

                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: modelData.icon
                            color: "#37f5eb"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                        }
                        Text {
                            text: modelData.name + "  " + modelData.value
                            color: Qt.rgba(1,1,1,0.66)
                            font.family: "Inter"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }
            }
        }
    }
}
